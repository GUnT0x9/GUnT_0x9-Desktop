using System;using System.Collections.Generic;
namespace Gunt.ControlCenter.Models {
 public sealed class ChoiceOption {public string Key{get;set;}public string Value{get;set;}public ChoiceOption(string key,string value){Key=key;Value=value;}public override string ToString(){return Value;}}

 public sealed class ProjectEntry {public string Id{get;set;}public string Name{get;set;}public string Directory{get;set;}public string Ide{get;set;}public string Terminal{get;set;}public string RepositoryUrl{get;set;}public bool Pinned{get;set;}public int Order{get;set;}public List<string> Commands{get;set;}public override string ToString(){return (Pinned?"고정 · ":"")+Name+"\n"+Directory;}}
 public sealed class ProjectStore {public int SchemaVersion{get;set;}public List<ProjectEntry> Projects{get;set;}}
 public sealed class HealthEntry {public string Id,Name,Status,Detail,ActionLabel,Action;public DateTimeOffset Checked=DateTimeOffset.Now;}
 public sealed class ProfileEntry {public string Id,Name,Path;public bool Builtin;public Dictionary<string,object> Data;public override string ToString(){return Name+(Builtin?" · 기본":" · 사용자");}}
 public sealed class WallpaperEntry {public string Path,Title,Thumbnail,Type,Assigned;public bool Favorite,Customizable;public override string ToString(){return (!String.IsNullOrEmpty(Assigned)?"적용 중 · ":"")+(Favorite?"즐겨찾기 · ":"")+Title+" · "+Type+(String.IsNullOrEmpty(Assigned)?"":" · "+Assigned);}}
 public sealed class DisplayEntry {public string Id,Device,Label;public int Index;public override string ToString(){return Label;}}
}
