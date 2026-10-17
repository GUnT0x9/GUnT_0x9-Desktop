using System;using System.Windows.Input;
namespace Gunt.ControlCenter.Infrastructure {public sealed class RelayCommand:ICommand{readonly Action action;public RelayCommand(Action a){action=a;}public bool CanExecute(object p){return true;}public void Execute(object p){action();}public event EventHandler CanExecuteChanged{add{}remove{}}}}
