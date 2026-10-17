using System;using System.Collections.Generic;
namespace Gunt.ControlCenter.Models {
 public sealed class DeveloperPreferences {
  public string TerminalHost{get;set;}public string WslDistribution{get;set;}public string DefaultAiCli{get;set;}public string Editor{get;set;}public string SessionPreset{get;set;}public string WorkspaceProfile{get;set;}public string CodexExecutable{get;set;}public string OpenCodeExecutable{get;set;}
 }
 public sealed class DeveloperStore {public int SchemaVersion=1;public List<string> Roots=new List<string>();public int ScanDepth=1;public bool ShowHidden;public DeveloperPreferences Defaults=new DeveloperPreferences{TerminalHost="windows-terminal",DefaultAiCli="codex",Editor="vscode",SessionPreset="ai-coding",CodexExecutable="codex",OpenCodeExecutable="opencode"};public string SelectedProjectId;public List<DeveloperTool> Tools=new List<DeveloperTool>();}
 public sealed class DeveloperTool {public string Id,Name,Executable;public override string ToString(){return Name;}}
 public sealed class ProjectInfo {public string Type,Branch,Repository,Error;public int Modified,Untracked;public DateTimeOffset Refreshed;}
 public sealed class WslTool {public string Name,Executable,Version,Error;public bool Available;public override string ToString(){return Name+": "+(Available?Version:"사용 불가 · "+Error);}}
 public sealed class LaunchResult {public string Action,Status,Detail;public override string ToString(){return Action+" · "+Status+" · "+Detail;}}
 public sealed class SessionAction {public string Id=Guid.NewGuid().ToString("N"),Kind,Value;public bool Enabled=true;public override string ToString(){return (Enabled?"사용":"제외")+" · "+Kind+(String.IsNullOrEmpty(Value)?"":" · "+Value);}}
 public sealed class DevelopmentSession {public string Id,Name,Mode="sequential",TerminalHost,WorkspaceProfile;public bool Builtin,AllowAutomation;public List<SessionAction> Actions=new List<SessionAction>();public override string ToString(){return Name;}}
 public sealed class SessionStore {public int SchemaVersion=1;public List<DevelopmentSession> Presets=new List<DevelopmentSession>();}
 public sealed class SessionRun {public string Id,ProjectId,PresetId,Started,Ended,Result;public bool Active;public List<LaunchResult> Actions=new List<LaunchResult>();}
 public sealed class CommandEntry {public string Id,Name,Aliases,ProjectId,Action,Value;public bool Favorite;public override string ToString(){return (Favorite?"★ ":"")+Name;}}
 public sealed class CommandStore {public int SchemaVersion=1;public Dictionary<string,string> Aliases=new Dictionary<string,string>();public List<string> Favorites=new List<string>();public List<string> Recent=new List<string>();}
 public sealed class AutomationRule {public string Id=Guid.NewGuid().ToString("N"),Name,Trigger="session-started",TriggerValue,Action="monitor-hide",Value,Power="any";public List<string> Exceptions=new List<string>();public bool Enabled;public int Priority=50,CooldownSeconds=60;public override string ToString(){return (Enabled?"사용":"중지")+" · "+Name;}}
 public sealed class AutomationStore {public int SchemaVersion=1;public List<AutomationRule> Rules=new List<AutomationRule>();}
}
