using System;using System.ComponentModel;
namespace Gunt.ControlCenter.Models {
 public sealed class SettingField:INotifyPropertyChanged {
  public string Config,Key,Kind;public string Label{get;set;}public string Help{get;set;}public string[] Options{get;set;}public string Original;object value;
  public object Value{get{return value;}set{this.value=value;if(PropertyChanged!=null)PropertyChanged(this,new PropertyChangedEventArgs("Value"));}}
  public event PropertyChangedEventHandler PropertyChanged;
 }
}
