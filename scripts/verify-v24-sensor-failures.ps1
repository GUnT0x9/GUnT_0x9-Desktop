. "$PSScriptRoot\common.ps1"
Add-Type -Path (Join-Path $Root 'bin\Gunt.Sensors.dll')
$fixture=Join-Path $Root ('tests\work\sensor-identity-'+[guid]::NewGuid().ToString('N'));New-Item -ItemType Directory -Force (Join-Path $fixture 'config')|Out-Null
Copy-Item (Join-Path $Root 'config\sensors.json') (Join-Path $fixture 'config\sensors.json')
Add-Type @'
using System;using System.IO;using System.Collections;using System.Collections.Generic;using System.Linq;using System.Web.Script.Serialization;
public static class SensorFailureTest24{
 public static object Test(string root){var json=new JavaScriptSerializer();var current=new GuntHwinfoTelemetry(root).Read();foreach(string k in new[]{"CpuTemperatureC","GpuTemperatureC","SsdTemperatureC"})if(current[k]==null)throw new Exception("실제 연결 값 누락: "+k);
 var stale=new GuntHwinfoTelemetry(root,()=>DateTime.UtcNow.AddSeconds(120)).Read();if(Convert.ToString(stale["TemperatureQuality"])!="stale"||stale["CpuTemperatureC"]!=null||stale["GpuTemperatureC"]!=null||stale["SsdTemperatureC"]!=null)throw new Exception("공급자 갱신 지연 시 결측 처리가 되지 않았습니다.");
 string path=Path.Combine(root,"config","sensors.json");var config=json.Deserialize<Dictionary<string,object>>(File.ReadAllText(path));foreach(var x in (IEnumerable)config["mappings"])((Dictionary<string,object>)x)["index"]=999;File.WriteAllText(path,json.Serialize(config));var reindexed=new GuntHwinfoTelemetry(root).Read();if(reindexed["CpuTemperatureC"]==null||reindexed["GpuTemperatureC"]==null||reindexed["SsdTemperatureC"]==null)throw new Exception("레지스트리 인덱스와 센서 정체성을 혼동했습니다.");
 foreach(var x in (IEnumerable)config["mappings"])((Dictionary<string,object>)x)["fingerprint"]="unknown-sensor";File.WriteAllText(path,json.Serialize(config));var missing=new GuntHwinfoTelemetry(root).Read();if(missing["CpuTemperatureC"]!=null||missing["GpuTemperatureC"]!=null||missing["SsdTemperatureC"]!=null)throw new Exception("다른 센서로 대체했습니다.");
 return new {Status="passed",RealReadingsPresent=true,StaleValuesBecomeNull=true,IndexIndependentIdentity=true,WrongIdentityNotSubstituted=true,WindowsClockChanged=false,LiveSettingsChanged=false};
 }
}
'@ -ReferencedAssemblies System.Core,System.Web.Extensions,(Join-Path $Root 'bin\Gunt.Sensors.dll')
$result=[SensorFailureTest24]::Test($fixture);Write-Json $result (Join-Path $Root 'logs\v24-sensor-failure-verification.json');Write-Log 'sensor-failure-test' 'passed' '실제 레지스트리를 읽는 분리된 시험에서 오래된 값·인덱스 변경·다른 센서 대체 차단을 확인했습니다.'
