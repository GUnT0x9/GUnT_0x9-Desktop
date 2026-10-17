using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
using System.Web.Script.Serialization;
using Microsoft.Win32;

public sealed class GuntSensorSampler : IDisposable {
 [StructLayout(LayoutKind.Explicit,Size=16)] struct CounterValue { [FieldOffset(0)] public uint Status; [FieldOffset(8)] public double Value; }
 [StructLayout(LayoutKind.Sequential)] struct CounterItem {public IntPtr Name;public CounterValue Value;}
 [DllImport("pdh.dll",CharSet=CharSet.Unicode)]static extern uint PdhOpenQuery(string source,UIntPtr data,out IntPtr query);
 [DllImport("pdh.dll",CharSet=CharSet.Unicode)]static extern uint PdhAddEnglishCounter(IntPtr query,string path,UIntPtr data,out IntPtr counter);
 [DllImport("pdh.dll")]static extern uint PdhCollectQueryData(IntPtr query);
 [DllImport("pdh.dll")]static extern uint PdhCloseQuery(IntPtr query);
 [DllImport("pdh.dll",CharSet=CharSet.Unicode)]static extern uint PdhGetFormattedCounterArray(IntPtr counter,uint format,ref uint bytes,out uint count,IntPtr buffer);
 [DllImport("pdh.dll")]static extern uint PdhGetFormattedCounterValue(IntPtr counter,uint format,out uint type,out CounterValue value);
 [StructLayout(LayoutKind.Sequential)]struct LUID {public uint Low;public int High;}
 [StructLayout(LayoutKind.Sequential,CharSet=CharSet.Unicode)]struct AdapterDesc {
  [MarshalAs(UnmanagedType.ByValTStr,SizeConst=128)]public string Description;
  public uint Vendor,Device,Subsystem,Revision;public UIntPtr DedicatedVideo,DedicatedSystem,Shared;public LUID Luid;public uint Flags;
 }
 [DllImport("dxgi.dll")]static extern int CreateDXGIFactory1(ref Guid id,out IntPtr factory);
 [UnmanagedFunctionPointer(CallingConvention.StdCall)]delegate int EnumAdapter(IntPtr self,uint index,out IntPtr adapter);
 [UnmanagedFunctionPointer(CallingConvention.StdCall)]delegate int GetDesc(IntPtr self,out AdapterDesc desc);
 [StructLayout(LayoutKind.Sequential)]struct Power {public byte AC,Flags,Percent,Saver;public int Remaining,Full;}
 [DllImport("kernel32.dll")]static extern bool GetSystemPowerStatus(out Power power);
 [DllImport("kernel32.dll")]static extern bool GetLogicalProcessorInformationEx(int relation,IntPtr buffer,ref uint length);
 readonly string root;readonly Func<bool> enabled;readonly object gate=new object();
 readonly Dictionary<string,IntPtr> counters=new Dictionary<string,IntPtr>();
 readonly List<Dictionary<string,object>> adapters=new List<Dictionary<string,object>>();
 readonly Dictionary<string,int> temperatureIndexes=new Dictionary<string,int>();
 readonly JavaScriptSerializer json=new JavaScriptSerializer();
 IntPtr query;Timer timer;bool stopped;int samples;string providerError="",temperatureHive="";
 readonly GuntHwinfoTelemetry hwinfo;readonly string cpuModel;readonly int cores;readonly GuntAdditionalTelemetry additional=new GuntAdditionalTelemetry();int intervalMs=2000;
 public GuntSensorSampler(string directory,Func<bool> shouldSample){
  root=directory;enabled=shouldSample;hwinfo=new GuntHwinfoTelemetry(root);
  using(var key=Registry.LocalMachine.OpenSubKey(@"HARDWARE\DESCRIPTION\System\CentralProcessor\0")){cpuModel=key==null?"CPU":Convert.ToString(key.GetValue("ProcessorNameString")).Trim();}
  cores=PhysicalCores();
  try{
   DiscoverAdapters();
   if(PdhOpenQuery(null,UIntPtr.Zero,out query)!=0)throw new Exception("PDH 쿼리를 열 수 없습니다.");
   Add("gpu",@"\GPU Engine(*)\Utilization Percentage");Add("dedicated",@"\GPU Adapter Memory(*)\Dedicated Usage");Add("shared",@"\GPU Adapter Memory(*)\Shared Usage");
   Add("frequency",@"\Processor Information(_Total)\Processor Frequency");Add("diskRead",@"\PhysicalDisk(_Total)\Disk Read Bytes/sec");Add("diskWrite",@"\PhysicalDisk(_Total)\Disk Write Bytes/sec");
   Add("commit",@"\Memory\Committed Bytes");Add("commitLimit",@"\Memory\Commit Limit");Add("cache",@"\Memory\Cache Bytes");
  }catch(Exception e){providerError=e.Message;}
  timer=new Timer(Sample,null,100,2000);
 }
 static int PhysicalCores(){uint length=0;GetLogicalProcessorInformationEx(0,IntPtr.Zero,ref length);if(length==0)return 0;IntPtr p=Marshal.AllocHGlobal((int)length);try{if(!GetLogicalProcessorInformationEx(0,p,ref length))return 0;int result=0;for(int n=0;n<length;){int size=Marshal.ReadInt32(p,n+4);if(size<=0)break;result++;n+=size;}return result;}finally{Marshal.FreeHGlobal(p);}}
 void Add(string name,string path){IntPtr counter;if(PdhAddEnglishCounter(query,path,UIntPtr.Zero,out counter)==0)counters[name]=counter;}
 static string Key(uint high,uint low){return "0x"+high.ToString("x8")+"_0x"+low.ToString("x8");}
 static string InstanceKey(string instance){var m=Regex.Match(instance,@"luid_0x([0-9a-f]+)_0x([0-9a-f]+)",RegexOptions.IgnoreCase);return m.Success?Key(uint.Parse(m.Groups[1].Value,NumberStyles.HexNumber),uint.Parse(m.Groups[2].Value,NumberStyles.HexNumber)):null;}
 void DiscoverAdapters(){
  IntPtr factory;var guid=new Guid("770aae78-f26f-4dba-a829-253c83d1b387");if(CreateDXGIFactory1(ref guid,out factory)!=0)return;
  try{var enumerate=(EnumAdapter)Marshal.GetDelegateForFunctionPointer(Marshal.ReadIntPtr(Marshal.ReadIntPtr(factory),12*IntPtr.Size),typeof(EnumAdapter));
   for(uint i=0;i<16;i++){IntPtr adapter;if(enumerate(factory,i,out adapter)!=0)break;
    try{var get=(GetDesc)Marshal.GetDelegateForFunctionPointer(Marshal.ReadIntPtr(Marshal.ReadIntPtr(adapter),10*IntPtr.Size),typeof(GetDesc));AdapterDesc d;if(get(adapter,out d)!=0||(d.Flags&2)!=0)continue;
     adapters.Add(new Dictionary<string,object>{{"Model",d.Description},{"Luid",Key((uint)d.Luid.High,d.Luid.Low)},{"DedicatedCapacityBytes",d.DedicatedVideo.ToUInt64()},{"SharedMaximumBytes",d.Shared.ToUInt64()}});
    }finally{Marshal.Release(adapter);}
   }
  }finally{Marshal.Release(factory);}
 }
 Dictionary<string,double> Array(string name){
  var values=new Dictionary<string,double>();IntPtr counter;if(!counters.TryGetValue(name,out counter))return values;
  uint bytes=0,count;PdhGetFormattedCounterArray(counter,0x8200,ref bytes,out count,IntPtr.Zero);if(bytes==0||bytes>16*1024*1024)return values;
  IntPtr buffer=Marshal.AllocHGlobal((int)bytes);
  try{if(PdhGetFormattedCounterArray(counter,0x8200,ref bytes,out count,buffer)!=0)return values;int size=Marshal.SizeOf(typeof(CounterItem));
   for(int i=0;i<count;i++){var item=(CounterItem)Marshal.PtrToStructure(IntPtr.Add(buffer,i*size),typeof(CounterItem));if(item.Value.Status<=1&&item.Name!=IntPtr.Zero&&!double.IsNaN(item.Value.Value))values[Marshal.PtrToStringUni(item.Name)]=item.Value.Value;}
  }finally{Marshal.FreeHGlobal(buffer);}return values;
 }
 double? Single(string name){IntPtr counter;CounterValue value;uint type;if(!counters.TryGetValue(name,out counter)||PdhGetFormattedCounterValue(counter,0x8200,out type,out value)!=0||value.Status>1||double.IsNaN(value.Value))return null;return value.Value;}
 void DiscoverTemperatures(){
  temperatureIndexes.Clear();temperatureHive="";
  foreach(var entry in new[]{Registry.CurrentUser,Registry.LocalMachine})using(var key=entry.OpenSubKey(@"SOFTWARE\HWiNFO64\VSB")){
   if(key==null)continue;temperatureHive=entry.Name;
   foreach(var name in key.GetValueNames())if(Regex.IsMatch(name,@"^Label[0-9]+$")){
    string label=Convert.ToString(key.GetValue(name)),unit=Convert.ToString(key.GetValue("Value"+name.Substring(5)));
    if(!(unit.Contains("°C")||unit.Contains("℃")))continue;
    int index=int.Parse(name.Substring(5));
    if(label.IndexOf("CPU Package",StringComparison.OrdinalIgnoreCase)>=0)temperatureIndexes["CpuTemperatureC"]=index;
    if(adapters.Count==1&&label.IndexOf("GPU Temperature",StringComparison.OrdinalIgnoreCase)>=0)temperatureIndexes["GpuTemperatureC"]=index;
   }
   break;
  }
 }
 double? Temperature(string name){int index;if(!temperatureIndexes.TryGetValue(name,out index))return null;var hive=temperatureHive==Registry.LocalMachine.Name?Registry.LocalMachine:Registry.CurrentUser;using(var key=hive.OpenSubKey(@"SOFTWARE\HWiNFO64\VSB")){if(key==null)return null;double n;if(double.TryParse(Convert.ToString(key.GetValue("ValueRaw"+index)),NumberStyles.Float,CultureInfo.InvariantCulture,out n)&&n>0&&n<150)return n;}return null;}
 void Sample(object state){
  if(stopped||!Monitor.TryEnter(gate))return;
  try{
   if(!enabled())return;
   try{var c=json.Deserialize<Dictionary<string,object>>(File.ReadAllText(Path.Combine(root,"config","monitor.json")));int requested=c.ContainsKey("updateMs")?Convert.ToInt32(c["updateMs"]):2000;if(requested!=intervalMs&&(requested==1000||requested==2000||requested==5000)){intervalMs=requested;timer.Change(intervalMs,intervalMs);}}catch{}
   if(query!=IntPtr.Zero)PdhCollectQueryData(query);
   samples++;if(samples==1||samples%30==0)DiscoverTemperatures();
   var gpuEngines=Array("gpu");var engineTotals=new Dictionary<string,double>();
   foreach(var item in gpuEngines){string key=InstanceKey(item.Key);var match=Regex.Match(item.Key,@"_phys_([0-9]+)_eng_([0-9]+)");if(key==null||!match.Success)continue;string engine=key+"/"+match.Value;double n;engineTotals.TryGetValue(engine,out n);engineTotals[engine]=n+item.Value;}
   var dedicated=Array("dedicated");var shared=Array("shared");var gpus=new List<Dictionary<string,object>>();
   foreach(var adapter in adapters){var gpu=new Dictionary<string,object>(adapter);string key=(string)gpu["Luid"];
    var engines=engineTotals.Where(x=>x.Key.StartsWith(key+"/",StringComparison.Ordinal)).Select(x=>x.Value).ToArray();
    gpu["UtilizationPercent"]=engines.Length==0?(object)null:Math.Round(Math.Max(0,Math.Min(100,engines.Max())),2);
    var d=dedicated.Where(x=>InstanceKey(x.Key)==key).Select(x=>x.Value).ToArray();var sh=shared.Where(x=>InstanceKey(x.Key)==key).Select(x=>x.Value).ToArray();
    gpu["DedicatedUsedBytes"]=d.Length==0?(object)null:d.Sum();gpu["SharedUsedBytes"]=sh.Length==0?(object)null:sh.Sum();gpu["UtilizationDefinition"]="어댑터별 동일 엔진의 프로세스 값을 합산한 뒤 가장 바쁜 엔진을 사용";gpus.Add(gpu);
   }
   Power power;GetSystemPowerStatus(out power);
   var snapshot=new Dictionary<string,object>{{"SampleEpoch",(long)(DateTime.UtcNow-new DateTime(1970,1,1)).TotalSeconds},{"BatteryPercent",power.Percent==255?(object)null:power.Percent},{"ACConnected",power.AC==1},{"BatteryCharging",(power.Flags&8)!=0},{"BatterySaver",power.Saver==1},{"Timestamp",DateTimeOffset.Now.ToString("o")},{"Provider","Windows PDH + DXGI"},{"CpuModel",cpuModel},{"PhysicalCores",cores},{"LogicalProcessors",Environment.ProcessorCount},{"CpuFrequencyMHz",Single("frequency")},{"CpuTemperatureC",Temperature("CpuTemperatureC")},{"GpuTemperatureC",Temperature("GpuTemperatureC")},{"Gpus",gpus},{"DiskReadBytesPerSecond",Single("diskRead")},{"DiskWriteBytesPerSecond",Single("diskWrite")},{"CommittedBytes",Single("commit")},{"CommitLimitBytes",Single("commitLimit")},{"SystemCacheBytes",Single("cache")},{"TemperatureProvider",temperatureIndexes.Count>0?"HWiNFO Registry":"사용 가능한 온도 제공자 없음"},{"Error",providerError},{"Sample",samples}};
   foreach(var pair in additional.Collect())snapshot[pair.Key]=pair.Value;
   foreach(var pair in hwinfo.Read())snapshot[pair.Key]=pair.Value;
   Atomic(Path.Combine(root,"state","sensors.json"),json.Serialize(snapshot));
   var ini=new StringBuilder("[Sensors]\r\n");
   foreach(var pair in snapshot)if(pair.Value==null||pair.Value is string||pair.Value is bool||pair.Value is ValueType)Append(ini,pair.Key,pair.Value);
   int selected=0;try{var settings=json.Deserialize<Dictionary<string,object>>(File.ReadAllText(Path.Combine(root,"config","monitor.json")));if(settings.ContainsKey("gpuAdapterIndex"))selected=Convert.ToInt32(settings["gpuAdapterIndex"]);}catch{}if(selected<0||selected>=gpus.Count)selected=0;
   if(gpus.Count>0){var gpu=gpus[selected];Append(ini,"GpuModel",gpu["Model"]);foreach(var name in new[]{"UtilizationPercent","DedicatedUsedBytes","SharedUsedBytes","DedicatedCapacityBytes","SharedMaximumBytes"})Append(ini,"Gpu"+name,gpu[name]);}
   using(var key=Registry.CurrentUser.CreateSubKey(@"Software\GuntDesktop\Sensors")){
    foreach(string line in ini.ToString().Split(new[]{"\r\n"},StringSplitOptions.RemoveEmptyEntries)){int equals=line.IndexOf('=');if(equals>0)key.SetValue(line.Substring(0,equals),line.Substring(equals+1),RegistryValueKind.String);}
    key.SetValue("HasGpu",gpus.Count>0&&gpus[selected]["UtilizationPercent"]!=null?1:0,RegistryValueKind.DWord);
    key.SetValue("HasSsdTemperature",snapshot.ContainsKey("SsdTemperatureC")&&snapshot["SsdTemperatureC"]!=null?1:0,RegistryValueKind.DWord);
    key.SetValue("HasCpuTemperature",snapshot["CpuTemperatureC"]!=null?1:0,RegistryValueKind.DWord);key.SetValue("HasGpuTemperature",snapshot["GpuTemperatureC"]!=null?1:0,RegistryValueKind.DWord);
   }
  }catch(Exception e){try{File.AppendAllText(Path.Combine(root,"logs","sensors-errors.log"),DateTimeOffset.Now+" "+e.Message+Environment.NewLine);}catch{}}
  finally{Monitor.Exit(gate);}
 }
 static void Append(StringBuilder b,string name,object value){b.Append(name).Append('=').Append(value==null?"":Convert.ToString(value,CultureInfo.InvariantCulture).Replace("\r","").Replace("\n"," ")).Append("\r\n");}
 static void Atomic(string path,string text){string temp=path+".tmp";File.WriteAllText(temp,text,new UTF8Encoding(false));for(int i=0;i<3;i++){try{if(File.Exists(path))File.Replace(temp,path,null);else File.Move(temp,path);return;}catch(IOException){Thread.Sleep(10);}}}
 public void Dispose(){stopped=true;if(timer!=null)timer.Dispose();lock(gate){if(query!=IntPtr.Zero){PdhCloseQuery(query);query=IntPtr.Zero;}}}
}
