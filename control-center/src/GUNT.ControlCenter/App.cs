using System;using System.IO;using System.Threading;using System.Runtime.InteropServices;using System.Windows;using Gunt.ControlCenter.Views;
[assembly:System.Reflection.AssemblyTitle("GUnT_0x9 Desktop")]
[assembly:System.Reflection.AssemblyProduct("GUnT_0x9 Desktop")]
[assembly:System.Runtime.Versioning.TargetFramework(".NETFramework,Version=v4.8")]
namespace Gunt.ControlCenter {public static class App {
 [DllImport("user32.dll",CharSet=CharSet.Unicode)]static extern IntPtr FindWindow(string c,string t);[DllImport("user32.dll")]static extern bool PostMessage(IntPtr h,uint m,IntPtr wp,IntPtr lp);[DllImport("user32.dll")]static extern bool SetForegroundWindow(IntPtr h);[DllImport("user32.dll")]static extern bool ShowWindow(IntPtr h,int c);[DllImport("user32.dll")]static extern bool SetProcessDpiAwarenessContext(IntPtr c);
 [STAThread]public static void Main(string[] args){string root=args.Length>0?args[0]:Directory.GetParent(AppDomain.CurrentDomain.BaseDirectory.TrimEnd('\\')).FullName;string page=args.Length>1?args[1]:"overview";bool created;using(var mutex=new Mutex(true,"Local\\GUNTControlCenterV24",out created)){
  if(!created){var h=FindWindow(null,"GUnT_0x9 Desktop");if(h==IntPtr.Zero)h=FindWindow(null,"GUNT 제어 센터");GuntConfiguration.Atomic(root,Path.Combine(root,"state","control-center-open.json"),new System.Web.Script.Serialization.JavaScriptSerializer().Serialize(new {page=page}),false);ShowWindow(h,9);SetForegroundWindow(h);PostMessage(h,0x8004,IntPtr.Zero,IntPtr.Zero);return;}
  SetProcessDpiAwarenessContext(new IntPtr(-4));AppContext.SetSwitch("Switch.System.Windows.DoNotScaleForDpiChanges",false);AppContext.SetSwitch("Switch.System.Windows.DoNotUsePresentationDpiCapabilityTier2OrGreater",false);
  var app=new Application();app.DispatcherUnhandledException+=delegate(object sender,System.Windows.Threading.DispatcherUnhandledExceptionEventArgs e){File.AppendAllText(Path.Combine(root,"logs","control-center-errors.log"),DateTimeOffset.Now+" "+e.Exception+Environment.NewLine);MessageBox.Show("제어 센터 처리 중 오류가 발생했습니다.\n"+e.Exception.Message,"GUnT_0x9 Desktop");e.Handled=true;};app.Run(new MainWindow(root,page));
 }}
}}
