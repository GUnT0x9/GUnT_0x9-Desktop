using System;using System.Collections.Generic;
namespace Gunt.ControlCenter.Models {
 public static class DeveloperText {
  public static string Action(string value){var names=new Dictionary<string,string>{{"ai","기본 AI CLI"},{"project-terminal","프로젝트 터미널"},{"ide","VS Code"},{"codex","Codex"},{"opencode","OpenCode"},{"wsl","WSL 셸"},{"cmd","CMD"},{"powershell","PowerShell"},{"terminal","Windows Terminal"},{"folder","폴더 열기"},{"repository","GitHub 저장소"},{"command","프로젝트 명령"},{"tool","등록한 도구"},{"profile","작업공간 프로필"},{"restore-owned","이전 소유 상태 복원"},{"monitor-show","모니터 표시"},{"monitor-hide","모니터 숨김"},{"wallpaper-pause","배경 일시정지"},{"wallpaper-play","배경 재생"},{"open-project","프로젝트 폴더 열기"},{"session","개발 세션 시작"}};return value!=null&&names.ContainsKey(value)?names[value]:value??"";}
  public static string Trigger(string value){var names=new Dictionary<string,string>{{"session-started","개발 세션 시작"},{"session-ended","개발 세션 종료 기록"},{"application-running","설정한 앱 실행"},{"ac-connected","AC 전원 연결"},{"battery","배터리로 전환"},{"monitor-changed","화면 구성 변경"}};return names.ContainsKey(value)?names[value]:value;}
 }
 public sealed class DeveloperPreferences {
  public string TerminalHost{get;set;}public string WslDistribution{get;set;}public string WslUser{get;set;}public string DefaultAiCli{get;set;}public string Editor{get;set;}public string SessionPreset{get;set;}public string WorkspaceProfile{get;set;}public string CodexExecutable{get;set;}public string OpenCodeExecutable{get;set;}
 }
 public sealed class DeveloperStore {public int SchemaVersion=1;public List<string> Roots=new List<string>();public int ScanDepth=1;public bool ShowHidden;public DeveloperPreferences Defaults=new DeveloperPreferences{TerminalHost="windows-terminal",DefaultAiCli="codex",Editor="vscode",SessionPreset="ai-coding",CodexExecutable="codex",OpenCodeExecutable="opencode"};public string SelectedProjectId;public List<DeveloperTool> Tools=new List<DeveloperTool>();}
 public sealed class DeveloperTool {public string Id,Name,Executable;public override string ToString(){return Name;}}
 public sealed class ProjectInfo {public string Type,Branch,Repository,Error;public int Modified,Untracked;public DateTimeOffset Refreshed;}
 public sealed class WslTool {public string Name,Executable,Version,Error;public bool Available;public override string ToString(){return Name+": "+(Available?Version:"사용 불가 · "+Error);}}
 public sealed class LaunchResult {public string Action,Status,Detail;public override string ToString(){return DeveloperText.Action(Action)+" · "+Status+" · "+Detail;}}
 public sealed class SessionAction {public string Id=Guid.NewGuid().ToString("N"),Kind,Value;public bool Enabled=true;public override string ToString(){return (Enabled?"사용":"제외")+" · "+DeveloperText.Action(Kind)+(String.IsNullOrEmpty(Value)?"":" · "+Value);}}
 public sealed class DevelopmentSession {public string Id,Name,Mode="sequential",TerminalHost,WorkspaceProfile;public bool Builtin,AllowAutomation;public List<SessionAction> Actions=new List<SessionAction>();[System.Web.Script.Serialization.ScriptIgnore]public string Summary{get{return Actions.Count+"개 단계 · "+(Builtin?"기본":"사용자");}}public override string ToString(){return Name;}}
 public sealed class SessionStore {public int SchemaVersion=1;public List<DevelopmentSession> Presets=new List<DevelopmentSession>();}
 public sealed class SessionRun {public string Id,ProjectId,PresetId,Started,Ended,Result;public bool Active;public List<LaunchResult> Actions=new List<LaunchResult>();}
 public sealed class CommandEntry {public string Id,Name,Aliases,ProjectId,Action,Value;public bool Favorite;public override string ToString(){return (Favorite?"★ ":"")+Name;}}
 public sealed class CommandStore {public int SchemaVersion=1;public Dictionary<string,string> Aliases=new Dictionary<string,string>();public List<string> Favorites=new List<string>();public List<string> Recent=new List<string>();}
 public sealed class AutomationRule {public string Id=Guid.NewGuid().ToString("N"),Name,Trigger="session-started",TriggerValue,Action="monitor-hide",Value,Power="any";public List<string> Exceptions=new List<string>();public bool Enabled;public int Priority=50,CooldownSeconds=60;public override string ToString(){return (Enabled?"사용":"중지")+" · "+Name;}}
 public sealed class AutomationStore {public int SchemaVersion=1;public List<AutomationRule> Rules=new List<AutomationRule>();}
}
