using System;using System.IO;using System.Linq;using System.Diagnostics;using System.Collections.Generic;using System.Globalization;using System.Runtime.InteropServices;using System.Text;using System.Text.RegularExpressions;using System.Web.Script.Serialization;using Gunt.ControlCenter.Models;
namespace Gunt.ControlCenter.Services {
 public sealed partial class DesktopService{
  public readonly string Root;public readonly JavaScriptSerializer Json=new JavaScriptSerializer();
  [DllImport("user32.dll",CharSet=CharSet.Unicode)]static extern IntPtr FindWindow(string c,string t);[DllImport("user32.dll")]static extern bool PostMessage(IntPtr h,uint m,IntPtr w,IntPtr l);
  public Func<string,string,string> ScriptOverride;public DesktopService(string root){Root=root;}
  public WindhawkEntry[] WindhawkMods(){
   var result=new List<WindhawkEntry>();var directory=Path.Combine(Root,"apps","Windhawk","AppData","Engine","Mods");
   Dictionary<string,Dictionary<string,object>> status=null;var statusPath=Path.Combine(Root,"windhawk","enhancement-status.json");if(File.Exists(statusPath))status=Json.Deserialize<Dictionary<string,Dictionary<string,object>>>(File.ReadAllText(statusPath));
   foreach(var file in Directory.GetFiles(directory,"*.ini").OrderBy(x=>x,StringComparer.OrdinalIgnoreCase)){
    var id=Path.GetFileNameWithoutExtension(file);if(!Regex.IsMatch(id,@"^[a-z0-9-]+$"))continue;var text=File.ReadAllText(file);Func<string,string> value=key=>Regex.Match(text,@"(?m)^"+Regex.Escape(key)+@"=(.*)$").Groups[1].Value.Trim();
    var item=new WindhawkEntry{Id=id,Name=id,Version=value("Version"),Enabled=value("Disabled")=="0",Targets=value("IncludeCustom"),Compatibility="검증 기록 없음",Notes="실제 INI를 읽은 상태입니다. 모드 변경은 Windhawk 창에서 수행하세요."};
    var source=Path.Combine(Root,"apps","Windhawk","AppData","ModsSource",id+".wh.cpp");if(File.Exists(source)){var name=Regex.Match(File.ReadAllText(source),@"(?m)^// @name\s+(.+)$");if(name.Success)item.Name=name.Groups[1].Value.Trim();}
    Dictionary<string,object> record;if(status!=null&&status.TryGetValue(id,out record)){if(record.ContainsKey("compatibility"))item.Compatibility=Convert.ToString(record["compatibility"]);if(record.ContainsKey("notes"))item.Notes=Convert.ToString(record["notes"]);}
    result.Add(item);
   }return result.ToArray();
  }
  public string RecentWindhawkErrors(){
   var path=Path.Combine(Root,"logs","changes.jsonl");var lines=new List<string>();if(File.Exists(path))foreach(var line in File.ReadLines(path).Reverse().Take(400)){try{var row=Json.Deserialize<Dictionary<string,object>>(line);string action=Convert.ToString(row["action"]),state=Convert.ToString(row["status"]);if((action.Contains("mod")||action.Contains("windhawk"))&&(state=="failed"||state=="error"))lines.Add(Convert.ToString(row["time"])+"  "+action+"\n"+Convert.ToString(row["detail"]));}catch{}}
   var health=Path.Combine(Root,"logs","windhawk-enhancement-health.json");if(File.Exists(health)){var data=Json.Deserialize<Dictionary<string,object>>(File.ReadAllText(health));if(data.ContainsKey("Time"))lines.Insert(0,"최근 셸 검사  "+Convert.ToString(data["Time"])+"\n자세한 이벤트와 보존 검사는 logs/windhawk-enhancement-health.json을 확인하세요.");}
   return lines.Count>0?String.Join("\n\n",lines):"최근 프로젝트 로그 400행에서 Windhawk 실패 기록을 찾지 못했습니다. Windows 전체 오류가 없다는 의미는 아닙니다.";
  }
  public Dictionary<string,object> Read(string name){return GuntConfiguration.Read(Root,name);}
  public Dictionary<string,object> State(string name){var p=Path.Combine(Root,"state",name+".json");return File.Exists(p)?Json.Deserialize<Dictionary<string,object>>(GuntConfiguration.ReadShared(p)):new Dictionary<string,object>();}
  public void Open(string path){Process.Start(new ProcessStartInfo(path){UseShellExecute=true});}
  public string Script(string name,string args){if(ScriptOverride!=null)return ScriptOverride(name,args);using(var p=new Process()){p.StartInfo=new ProcessStartInfo("powershell.exe","-NoProfile -NonInteractive -OutputFormat Text -ExecutionPolicy Bypass -File \""+Path.Combine(Root,"scripts",name+".ps1")+"\" "+args){UseShellExecute=false,CreateNoWindow=true,RedirectStandardOutput=true,RedirectStandardError=true,StandardOutputEncoding=Encoding.UTF8,StandardErrorEncoding=Encoding.UTF8};p.Start();var output=p.StandardOutput.ReadToEndAsync();var error=p.StandardError.ReadToEndAsync();if(!p.WaitForExit(180000))throw new TimeoutException("작업 응답이 지연됩니다. 구성 요소를 강제 종료하지 않았습니다.");if(p.ExitCode!=0)throw new InvalidOperationException(output.Result+error.Result);return output.Result;}}
  public void Action(string action,string value=""){if(!Regex.IsMatch(action??"",@"^[a-z0-9-]+$")||value.IndexOfAny(new[]{'\0','\r','\n'})>=0)throw new ArgumentException("데스크톱 동작 인수를 확인하세요.");Script("desktop-actions","-Action "+action+(value.Length>0?" -Value "+Quote(value):""));}
  public void ReloadBar(){var h=FindWindow(null,"GUNT Desktop \u2014 Midnight Purple");if(h==IntPtr.Zero||!PostMessage(h,0x8002,IntPtr.Zero,IntPtr.Zero))throw new InvalidOperationException("상단 바 창에 새로고침 요청을 전달하지 못했습니다.");}
  public string Apply(IEnumerable<SettingField> fields){
   var changed=fields.Where(f=>f.IsDirty).ToArray();if(changed.Any(f=>f.Config=="dock")&&File.Exists(Path.Combine(Root,"state","dock-live-apply-hold.json")))throw new InvalidOperationException("Dock 적용 시험 뒤 Explorer 교체가 관찰되어 자동 적용을 보류했습니다. 기존 Dock은 유지됩니다. Windhawk 창에서 확인하세요.");if(changed.Length==0)return "변경된 설정이 없습니다.";
   var originals=new Dictionary<string,Dictionary<string,object>>();var revisions=new Dictionary<string,string>();var pending=new Dictionary<string,Dictionary<string,object>>();
   foreach(var group in changed.GroupBy(x=>x.Config)){
    var data=Read(group.Key);originals[group.Key]=Json.Deserialize<Dictionary<string,object>>(Json.Serialize(data));
    foreach(var f in group){object current=Get(data,f.Key);if(Json.Serialize(current)!=f.Original)throw new InvalidOperationException(f.Label+" 설정이 외부에서 변경됐습니다. 페이지를 다시 열어 주세요.");object value=Normalize(f);Set(data,f.Key,value);}
    GuntConfiguration.Validate(group.Key,data);pending[group.Key]=data;
   }
   var undo=changed.Select(f=>new SettingField{Config=f.Config,Key=f.Key,Kind=f.Kind,Label=f.Label,Original=Json.Serialize(Normalize(f)),Value=f.Kind=="volumes"?String.Join(", ",((System.Collections.IEnumerable)Json.DeserializeObject(f.Original)).Cast<object>().Select(x=>Convert.ToString(x))):Json.DeserializeObject(f.Original)}).ToArray();
   try{
    foreach(var pair in pending)revisions[pair.Key]=GuntConfiguration.Save(Root,pair.Key,pair.Value);
    Script("apply-v24-settings","-Components \""+String.Join(",",pending.Keys)+"\"");
    foreach(var pair in pending)if(Json.Serialize(Read(pair.Key))!=Json.Serialize(pair.Value))throw new IOException("저장된 설정이 요청과 일치하지 않습니다: "+pair.Key);
    foreach(var f in changed){f.Original=Json.Serialize(Get(Read(f.Config),f.Key));var loaded=Get(Read(f.Config),f.Key);f.Value=f.Kind=="volumes"?String.Join(", ",((System.Collections.IEnumerable)loaded).Cast<object>().Select(x=>Convert.ToString(x))):loaded;}
    lastUndo=undo;return "저장·설정 내보내기 확인: "+String.Join(" · ",pending.Keys.Select(n=>n=="monitor"?"시스템 모니터":n=="topbar"?"상단 바":n=="theme"?"외관":n=="sensors"?"센서":n=="startup"?"시작 복원":n=="ux"?"명령 단축키":n))+". 화면 반영 상태는 각 구성 요소에서 확인하세요.";
   }catch(Exception e){var notes=new List<string>();foreach(var group in changed.GroupBy(f=>f.Config)){try{var current=Read(group.Key);foreach(var f in group){if(Json.Serialize(Get(current,f.Key))==Json.Serialize(Normalize(f)))Set(current,f.Key,Get(originals[group.Key],f.Key));else notes.Add(f.Label+": 외부 변경 유지·수동 확인 필요");}GuntConfiguration.Save(Root,group.Key,current);}catch(Exception r){notes.Add(group.Key+": 복구 실패 "+r.Message);}}try{Script("apply-v24-settings","-Components \""+String.Join(",",originals.Keys)+"\"");}catch(Exception r){notes.Add("구성 요소 복구 확인 필요: "+r.Message);}throw new InvalidOperationException("설정 적용 실패: "+e.Message+"\n"+(notes.Count==0?"변경한 설정 키를 이전 값으로 복원하고 구성 요소에 다시 내보냈습니다.":String.Join("\n",notes)));}
  }
  SettingField[] lastUndo;public bool CanUndo{get{return lastUndo!=null;}}
  public string Undo(){if(lastUndo==null)throw new InvalidOperationException("실행 취소할 적용 내역이 없습니다.");var snapshot=lastUndo;var result=Apply(snapshot);lastUndo=null;return "직전 변경을 실행 취소했습니다. "+result;}
  public string Summary(IEnumerable<SettingField> fields){return String.Join("\n",fields.Where(f=>f.IsDirty).Select(f=>f.Label+": "+f.Original+" → "+Json.Serialize(Normalize(f))));}
  static object Normalize(SettingField f){return f.Normalized();}

  public static object Get(Dictionary<string,object> data,string key){var keys=key.Split('.');object current=data;foreach(var k in keys){var d=current as Dictionary<string,object>;if(d==null||!d.TryGetValue(k,out current))return null;}return current;}
  static void Set(Dictionary<string,object> data,string key,object value){var keys=key.Split('.');var target=data;for(int i=0;i<keys.Length-1;i++){if(!target.ContainsKey(keys[i])||!(target[keys[i]] is Dictionary<string,object>))target[keys[i]]=new Dictionary<string,object>();target=(Dictionary<string,object>)target[keys[i]];}target[keys[keys.Length-1]]=value;}
 }
}
