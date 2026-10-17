using System;
namespace Gunt.ControlCenter.Models {
 public sealed class WindhawkEntry {
  public string Id{get;set;} public string Name{get;set;} public string Version{get;set;} public bool Enabled{get;set;} public string Targets{get;set;} public string Compatibility{get;set;} public string Notes{get;set;}
  public string Display {get{return (Enabled?"활성":"비활성")+"  ·  "+Name+"  "+Version;}}
  public override string ToString(){return Display;}
  public string OfficialUrl{get{return "https://windhawk.net/mods/"+Id;}}
  public string Details{get{return Name+"\nID  "+Id+"\n버전  "+Version+" · "+(Enabled?"활성":"비활성")+"\n대상  "+Targets+"\n호환성  "+Compatibility+"\n"+Notes+"\n"+OfficialUrl;}}
 }
}
