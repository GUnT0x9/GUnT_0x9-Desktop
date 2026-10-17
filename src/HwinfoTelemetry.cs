using System;using System.IO;using System.Text;using System.Collections;using System.Collections.Generic;using System.Diagnostics;using System.Globalization;using System.Linq;using System.Runtime.InteropServices;using System.Security.Cryptography;using System.Web.Script.Serialization;using Microsoft.Win32;
public sealed class GuntHwinfoTelemetry {
 [DllImport("advapi32.dll",CharSet=CharSet.Unicode)]static extern int RegQueryInfoKey(IntPtr key,StringBuilder cls,IntPtr length,IntPtr reserved,IntPtr subkeys,IntPtr maxsubkey,IntPtr maxclass,IntPtr values,IntPtr maxname,IntPtr maxvalue,IntPtr security,out long lastWrite);
 readonly string root;readonly Func<DateTime> utcNow;readonly JavaScriptSerializer json=new JavaScriptSerializer();
 public GuntHwinfoTelemetry(string directory):this(directory,()=>DateTime.UtcNow){}
 public GuntHwinfoTelemetry(string directory,Func<DateTime> clock){root=directory;utcNow=clock;}
 static string Fingerprint(string hive,string sensor,string label,string unit){using(var sha=SHA256.Create())return BitConverter.ToString(sha.ComputeHash(Encoding.UTF8.GetBytes("HWiNFO|"+sensor+"|"+label+"|"+unit))).Replace("-","");}
 public Dictionary<string,object> Read(){
  var result=new Dictionary<string,object>{{"CpuTemperatureC",null},{"GpuTemperatureC",null},{"SsdTemperatureC",null},{"CpuPackagePowerW",null},{"HasSsdTemperature",false},{"TemperatureQuality","unavailable"},{"TemperatureProvider","HWiNFO 가젯 연결 대기"}};
  var all=new List<Dictionary<string,object>>();result["TemperatureReadings"]=all;var mapped=new List<string>();
  Dictionary<string,object> config=null;try{config=json.Deserialize<Dictionary<string,object>>(File.ReadAllText(Path.Combine(root,"config","sensors.json")));}catch{}
  if(config!=null&&config.ContainsKey("provider")&&Convert.ToString(config["provider"])=="none")return result;
  bool running=Process.GetProcessesByName("HWiNFO64").Length>0;int stale=10;if(config!=null&&config.ContainsKey("staleSeconds"))stale=Math.Max(5,Math.Min(60,Convert.ToInt32(config["staleSeconds"])));
  foreach(var baseKey in new[]{Registry.CurrentUser,Registry.LocalMachine}){
   using(var key=baseKey.OpenSubKey(@"SOFTWARE\HWiNFO64\VSB")){
    if(key==null)continue;long fileTime;bool timeKnown=RegQueryInfoKey(key.Handle.DangerousGetHandle(), null,IntPtr.Zero,IntPtr.Zero,IntPtr.Zero,IntPtr.Zero,IntPtr.Zero,IntPtr.Zero,IntPtr.Zero,IntPtr.Zero,IntPtr.Zero,out fileTime)==0;
    DateTime updated=timeKnown?DateTime.FromFileTimeUtc(fileTime):DateTime.MinValue;double age=(utcNow()-updated).TotalSeconds;bool fresh=running&&timeKnown&&age>=-5&&age<=stale;
    foreach(var name in key.GetValueNames().Where(x=>System.Text.RegularExpressions.Regex.IsMatch(x,@"^Label\d+$"))){
     int index=Int32.Parse(name.Substring(5));string label=Convert.ToString(key.GetValue(name)),sensor=Convert.ToString(key.GetValue("Sensor"+index)),formatted=Convert.ToString(key.GetValue("Value"+index));
     string unit=formatted.Contains("°C")||formatted.Contains("℃")?"°C":System.Text.RegularExpressions.Regex.IsMatch(formatted,@"\bW\b")?"W":"";
     double raw;bool parsed=Double.TryParse(Convert.ToString(key.GetValue("ValueRaw"+index)),NumberStyles.Float,CultureInfo.InvariantCulture,out raw);bool valid=fresh&&parsed&&!Double.IsNaN(raw)&&!Double.IsInfinity(raw);
     if(unit=="°C")valid&=raw>=-30&&raw<=150;else if(unit=="W")valid&=raw>=0&&raw<=500;else valid=false;
     var record=new Dictionary<string,object>{{"Hive",baseKey.Name},{"Index",index},{"Sensor",sensor},{"Label",label},{"Unit",unit},{"Formatted",formatted},{"Value",valid?(object)raw:null},{"Quality",!fresh?"stale":valid?"valid":"unsupported-unit"},{"ProviderUpdatedUtc",timeKnown?updated.ToString("o"):null},{"AgeSeconds",timeKnown?(object)Math.Round(age,2):null},{"Fingerprint",Fingerprint(baseKey.Name,sensor,label,unit)}};all.Add(record);
    }
   }
  }
  // HWiNFO mirrors the same sensors to HKCU/HKLM. Prefer a fresh copy and expose one identity.
  all=all.GroupBy(x=>Convert.ToString(x["Fingerprint"])).Select(g=>g.OrderByDescending(x=>Convert.ToString(x["Quality"])=="valid").ThenByDescending(x=>Convert.ToString(x["Hive"])=="HKEY_CURRENT_USER").First()).ToList();result["TemperatureReadings"]=all;
  if(config!=null&&config.ContainsKey("mappings"))foreach(var entry in (IEnumerable)config["mappings"]){var m=entry as Dictionary<string,object>;if(m==null||!m.ContainsKey("metric")||!m.ContainsKey("fingerprint"))continue;string metric=Convert.ToString(m["metric"]);if(!result.ContainsKey(metric)||!(metric.EndsWith("TemperatureC")||metric=="CpuPackagePowerW"))continue;var matches=all.Where(x=>Convert.ToString(x["Fingerprint"])==Convert.ToString(m["fingerprint"])&&x["Value"]!=null&&Convert.ToString(x["Unit"])==(metric=="CpuPackagePowerW"?"W":"°C")).ToArray();if(matches.Length==1){result[metric]=matches[0]["Value"];mapped.Add(metric);matches[0]["MappedMetric"]=metric;}}
  foreach(string metric in new[]{"CpuTemperatureC","GpuTemperatureC","CpuPackagePowerW"}){
   if(result[metric]!=null)continue;
   string pattern=metric=="CpuTemperatureC"?@"^(CPU Package|CPU 패키지)$":metric=="GpuTemperatureC"?@"^(GPU Temperature|GPU 온도)$":@"^(CPU Package Power|CPU 패키지 전력)$";
   var matches=all.Where(x=>x["Value"]!=null&&System.Text.RegularExpressions.Regex.IsMatch(Convert.ToString(x["Label"]),pattern,System.Text.RegularExpressions.RegexOptions.IgnoreCase)&&Convert.ToString(x["Unit"])==(metric=="CpuPackagePowerW"?"W":"°C")).ToArray();
   if(matches.Length==1){result[metric]=matches[0]["Value"];matches[0]["MappedMetric"]=metric;mapped.Add(metric);}
  }
  var cpuReading=all.FirstOrDefault(x=>x.ContainsKey("MappedMetric")&&Convert.ToString(x["MappedMetric"])=="CpuTemperatureC");
  result["CpuTemperatureKind"]=cpuReading!=null&&(Convert.ToString(cpuReading["Label"]).IndexOf("코어",StringComparison.OrdinalIgnoreCase)>=0||Convert.ToString(cpuReading["Label"]).IndexOf("Core",StringComparison.OrdinalIgnoreCase)>=0)?"core":cpuReading!=null?"package":"unavailable";
  result["HasSsdTemperature"]=result["SsdTemperatureC"]!=null;result["TemperatureQuality"]=mapped.Count>0?"valid":all.Any(x=>Convert.ToString(x["Quality"])=="valid")?"mapping-required":all.Count>0?"stale":"unavailable";
  if(mapped.Count>0)result["TemperatureProvider"]="HWiNFO Registry";return result;
 }
}
