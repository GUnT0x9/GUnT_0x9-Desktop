using System;using System.ComponentModel;using System.Globalization;using System.Linq;using System.Web.Script.Serialization;
namespace Gunt.ControlCenter.Models {
 public sealed class SettingField:INotifyPropertyChanged {
  public string Config,Key,Kind;public string Label{get;set;}public string Help{get;set;}public string[] Options{get;set;}string original;object value;
  public string Original{get{return original;}set{original=value;Changed("Original");Changed("IsDirty");}}
  public object Value{get{return value;}set{if(Object.Equals(this.value,value))return;this.value=value;Changed("Value");Changed("IsDirty");}}
  public object Normalized(){if(Kind=="int"||Kind=="int-choice")return Int32.Parse(Convert.ToString(Value),CultureInfo.InvariantCulture);if(Kind=="bool")return Convert.ToBoolean(Value);if(Kind=="volumes"){var a=Convert.ToString(Value).Split(',').Select(x=>x.Trim().ToUpperInvariant()).Where(x=>x.Length>0).ToArray();if(a.Any(x=>x!="C:"&&x!="D:"))throw new ArgumentException("현재 볼륨 선택은 C:, D:를 지원합니다.");return a;}return Value;}
  public bool IsDirty{get{try{return new JavaScriptSerializer().Serialize(Normalized())!=Original;}catch{return true;}}}
  public void Discard(){var v=new JavaScriptSerializer().DeserializeObject(Original);Value=Kind=="volumes"?String.Join(", ",((System.Collections.IEnumerable)v).Cast<object>().Select(x=>Convert.ToString(x))):v;}
  void Changed(string name){if(PropertyChanged!=null)PropertyChanged(this,new PropertyChangedEventArgs(name));}
  public event PropertyChangedEventHandler PropertyChanged;
 }
}
