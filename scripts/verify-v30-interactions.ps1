param([ValidatePattern('^[a-z0-9.-]+$')][string]$ResultLabel='dev2')
# Real WPF controls on Windows; all saves go to a unique ignored fixture directory.
. "$PSScriptRoot\enhancement-ui-common.ps1"
Add-Type -AssemblyName PresentationFramework,PresentationCore,WindowsBase,System.Xaml
$bin=Join-Path $Root 'bin';$framework=Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319';$wpf=Join-Path $framework 'WPF'
$refs=@('System.dll','System.Core.dll','System.Xaml.dll','System.Web.Extensions.dll')|ForEach-Object {Join-Path $framework $_}
$refs+=@('PresentationFramework.dll','PresentationCore.dll','WindowsBase.dll')|ForEach-Object {Join-Path $wpf $_}
$refs+=@('GUNT.ControlCenter.exe','Gunt.Configuration.dll','Gunt.Sensors.dll')|ForEach-Object {$path=Join-Path $bin $_;$null=[Reflection.Assembly]::LoadFrom($path);$path}
$code=@'
using System;using System.IO;using System.Linq;using System.Collections;using System.Collections.Generic;using System.Reflection;using System.Windows;using System.Windows.Controls;using System.Windows.Controls.Primitives;using System.Windows.Media;using System.Windows.Threading;using System.Windows.Automation;using System.Windows.Input;
using Gunt.ControlCenter.Views;using Gunt.ControlCenter.Models;using Gunt.ControlCenter.Services;using Gunt.ControlCenter.ViewModels;
public static class V30Interactions {
 static Exception dispatcherError;static string report;static int count;static readonly List<string> checks=new List<string>();
 static void Assert(bool value,string name){File.AppendAllText(report,(value?"PASS ":"FAIL ")+name+Environment.NewLine);if(!value)throw new Exception(name);count++;checks.Add(name);}
 static object Field(object obj,string name){return obj.GetType().GetField(name,BindingFlags.Instance|BindingFlags.NonPublic).GetValue(obj);}
 static object Call(object obj,string name,params object[] args){return obj.GetType().GetMethod(name,BindingFlags.Instance|BindingFlags.NonPublic).Invoke(obj,args);}
 static void Pump(int ms){var frame=new DispatcherFrame();var timer=new DispatcherTimer{Interval=TimeSpan.FromMilliseconds(ms)};timer.Tick+=delegate{timer.Stop();frame.Continue=false;};timer.Start();Dispatcher.PushFrame(frame);if(dispatcherError!=null)throw new Exception("WPF dispatcher error",dispatcherError);}
 static IEnumerable<T> Visuals<T>(DependencyObject root)where T:DependencyObject {for(int i=0;i<VisualTreeHelper.GetChildrenCount(root);i++){var child=VisualTreeHelper.GetChild(root,i);if(child is T)yield return (T)child;foreach(var nested in Visuals<T>(child))yield return nested;}}
 static Button Button(DependencyObject root,string text){return Visuals<Button>(root).First(b=>Convert.ToString(b.Content)==text||AutomationProperties.GetName(b)==text);}
 static void Click(ButtonBase button){button.RaiseEvent(new RoutedEventArgs(ButtonBase.ClickEvent));Pump(120);}
 static void Ready(Func<bool> condition){for(int i=0;i<100&&!condition();i++)Pump(30);Assert(condition(),"background request completed");}
 public static string[] Run(string productRoot,string fixture,string label){
  report=Path.Combine(productRoot,"logs","v30-"+label+"-interaction-trace.txt");File.WriteAllText(report,"");
  Directory.CreateDirectory(Path.Combine(fixture,"assets"));Directory.CreateDirectory(Path.Combine(fixture,"state"));Directory.CreateDirectory(Path.Combine(fixture,"logs"));
  var service=new DesktopService(fixture);var entries=new List<ProjectEntry>();
  for(int i=0;i<500;i++){string folder=Path.Combine(fixture,"projects",i.ToString("000"));Directory.CreateDirectory(folder);File.WriteAllText(Path.Combine(folder,"package.json"),"{}");entries.Add(new ProjectEntry{Id="qa-"+i,Name="검증 프로젝트 "+i.ToString("000"),Directory=folder,Commands=new List<string>(),Ide="vscode",Terminal="powershell"});}
  File.WriteAllText(Path.Combine(fixture,"config","projects.json"),service.Json.Serialize(new ProjectStore{SchemaVersion=2,Projects=entries}));
  var developer=service.Developer();developer.SelectedProjectId=entries[0].Id;developer.Tools.Add(new DeveloperTool{Id="qa-tool",Name="검증 도구",Executable=Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.Windows),"notepad.exe")});service.SaveDeveloper(developer);
  File.WriteAllText(Path.Combine(fixture,"config","development-sessions.json"),service.Json.Serialize(new SessionStore{Presets=new List<DevelopmentSession>{new DevelopmentSession{Id="ai-coding",Name="검증 세션",Builtin=true,Actions=new List<SessionAction>{new SessionAction{Kind="ide"},new SessionAction{Kind="ai"}}}}}));
  var app=Application.Current??new Application();app.ShutdownMode=ShutdownMode.OnExplicitShutdown;app.DispatcherUnhandledException+=delegate(object sender,DispatcherUnhandledExceptionEventArgs args){dispatcherError=args.Exception;File.AppendAllText(report,"DISPATCHER "+args.Exception.ToString());args.Handled=true;};System.Threading.SynchronizationContext.SetSynchronizationContext(new DispatcherSynchronizationContext(app.Dispatcher));var win=new MainWindow(fixture,"developer-setup");
  try{int launchAttempts=0;var model=(MainViewModel)Field(win,"vm");model.Service.LaunchOverride=delegate{launchAttempts++;throw new InvalidOperationException("검증에서는 외부 실행을 차단합니다.");};win.Show();Pump(800);var projects=(ListBox)Field(win,"developerProjects");
   Assert(projects.Items.Count==500,"500 project records loaded");
   Assert(Visuals<ListBoxItem>(projects).Count()>0&&Visuals<ListBoxItem>(projects).Count()<24,"project containers virtualized");
   var search=(TextBox)Field(win,"developerSearch");search.Text="499";Pump(300);Assert(projects.Items.Count==1,"project search filters actual rows");projects.SelectedIndex=0;Pump(350);
   var row=(ProjectRowState)projects.SelectedItem;Ready(()=>row.Info!=null);Assert(row.Metadata.Contains("Node.js"),"actual project type shown");Assert(row.Git.Contains("확인 불가"),"non-repository is not shown as clean");
   var favorite=Visuals<CheckBox>(projects).First();bool prior=row.Pinned;Click(favorite);Ready(()=>!(bool)Field(win,"busy"));Assert(service.Projects().First(p=>p.Id==row.Entry.Id).Pinned!=prior,"inline favorite persisted to fixture database");
   projects.RaiseEvent(new MouseButtonEventArgs(Mouse.PrimaryDevice,Environment.TickCount,MouseButton.Left){RoutedEvent=Control.MouseDoubleClickEvent,Source=favorite});Pump(120);Assert(launchAttempts==0,"favorite double click does not launch a project");
   foreach(double width in new[]{780.0,1180.0,1500.0}){win.Width=width;win.Height=800;Pump(200);var browser=(Grid)Field(win,"developerBrowser");var inspector=(StackPanel)Field(win,"developerInspector");Assert(Grid.GetRow(inspector)==(width==780?1:0),"inspector reflow "+width);if(width==1500)Assert(((StackPanel)Field(win,"developerRoots")).Parent==browser,"wide root column visible");}
   search.Text="";Pump(100);projects.SelectedIndex=1;string chosen=((ProjectRowState)projects.SelectedItem).Entry.Id;Call(win,"SelectPage","development-sessions");Ready(()=>(string)Field(win,"page")=="development-sessions");Assert(service.ActiveProject().Id==chosen,"navigation retains the newly selected project context");Pump(300);var draft=(DevelopmentSession)Field(win,"sessionDraft");string first=draft.Actions[0].Id;var originalViews=(IDictionary)Field(win,"sessionStepViews");object originalView=originalViews[first];Click(Button(win,"1단계 아래로"));draft=(DevelopmentSession)Field(win,"sessionDraft");Assert(draft.Actions[1].Id==first,"step reorder uses actual draft");Assert(Object.ReferenceEquals(originalView,((IDictionary)Field(win,"sessionStepViews"))[first]),"reordering reuses the existing step view");
   win.Width=780;win.Height=560;Pump(200);Assert(((ListBox)Field(win,"sessionList")).Visibility==Visibility.Collapsed,"compact session preset uses a selector");var save=Button(win,"변경 저장");var savePoint=save.TranslatePoint(new Point(),win);Assert(savePoint.Y>=0&&savePoint.Y+save.ActualHeight<win.ActualHeight,"session save action visible at minimum size");win.Width=1180;win.Height=800;Pump(150);
   var enabled=Visuals<CheckBox>(win).First(c=>AutomationProperties.GetName(c)=="1단계 사용");enabled.IsChecked=false;Click(enabled);Assert(!draft.Actions[0].Enabled,"step disabled in draft");
   var step=Visuals<Expander>(win).First(e=>e.Header is StackPanel);Assert(step.Content==null,"collapsed step properties deferred");step.IsExpanded=true;Pump(150);Assert(step.Content!=null,"expanded step properties rendered");var properties=step.Content;Call(win,"RenderSessionSteps");Assert(Object.ReferenceEquals(properties,step.Content),"unrelated step refresh retains parameter controls");step.Content=null;Call(win,"RenderSessionSteps");Assert(step.Content!=null,"expanded properties restored after preferences invalidation");Pump(150);
   var kind=Visuals<ComboBox>(step).First(c=>AutomationProperties.GetName(c)=="실행 동작");kind.SelectedValue="tool";Pump(200);var tool=Visuals<ComboBox>(win).First(c=>AutomationProperties.GetName(c)=="실행할 등록 도구");tool.SelectedValue="qa-tool";var mode=Visuals<ComboBox>(win).First(c=>AutomationProperties.GetName(c)=="실행 방식");mode.SelectedValue="independent";Click(Button(win,"변경 저장"));var saved=service.Sessions().Presets.First();Assert(saved.Mode=="independent"&&saved.Actions[0].Kind=="tool"&&saved.Actions[0].Value=="qa-tool"&&!saved.Actions[0].Enabled,"step target and enabled state saved without engine changes");
   string stable=File.ReadAllText(Path.Combine(fixture,"config","development-sessions.json"));Click(Button(win,"단계 추가"));Assert(((DevelopmentSession)Field(win,"sessionDraft")).Actions.Count==3,"step added inline");
   var timer=new DispatcherTimer{Interval=TimeSpan.FromMilliseconds(100)};timer.Tick+=delegate{var dialog=app.Windows.Cast<Window>().FirstOrDefault(w=>w.Title=="미저장 세션");if(dialog!=null){timer.Stop();Click(Button(dialog,"계속 편집"));}};timer.Start();Call(win,"SelectPage","overview");Pump(150);Assert((string)Field(win,"page")=="development-sessions","unsaved navigation cancellation preserved");
   Click(Button(win,"세션 변경 버리기"));Assert(File.ReadAllText(Path.Combine(fixture,"config","development-sessions.json"))==stable,"discard does not write session configuration");
   Call(win,"SelectPage","wallpaper");Pump(1000);var wallpaperType=typeof(MainWindow).Assembly.GetType("Gunt.ControlCenter.Models.WallpaperEntry");var gallery=new WallpaperEntry[500];string logo=Path.Combine(fixture,"assets","branding","full","gunt-logo-full-240.png");
   for(int i=0;i<gallery.Length;i++)gallery[i]=new WallpaperEntry{Path="fixture-"+i,Title="검증 배경 "+i.ToString("000"),Type="검증",Thumbnail=logo,Assigned=i==0?"검증 화면":""};
   win.GetType().GetField("galleryEntries",BindingFlags.Instance|BindingFlags.NonPublic).SetValue(win,gallery);Call(win,"FilterGallery");Pump(500);var list=(ListBox)Field(win,"wallpaperList");Assert(((ScrollViewer)Field(win,"pageScroll")).VerticalScrollBarVisibility==ScrollBarVisibility.Disabled,"gallery uses a single main scroll region");Assert(list.Items.Count>50,"adaptive gallery bands generated");Assert(Visuals<ListBoxItem>(list).Count()>0&&Visuals<ListBoxItem>(list).Count()<16,"gallery bands virtualized");Assert(Visuals<Image>(list).Count()>0&&Visuals<Image>(list).Count()<80,"offscreen wallpaper images not constructed");
   list.ScrollIntoView(list.Items[list.Items.Count-1]);Pump(400);Assert(Visuals<ListBoxItem>(list).Count()>0&&Visuals<ListBoxItem>(list).Count()<16,"gallery recycling after scroll");
   for(int i=0;i<70;i++){string image=Path.Combine(fixture,"state","thumb-"+i+".png");File.Copy(logo,image,true);Call(win,"Thumbnail",new WallpaperEntry{Thumbnail=image});}var cache=(IDictionary)Field(win,"thumbnailCache");Assert(cache.Count<=64,"thumbnail cache bounded at 64");
   var gallerySearch=(TextBox)Field(win,"gallerySearch");gallerySearch.Text="없는 배경";Pump(150);Assert(list.Items.Count==0&&((TextBlock)Field(win,"galleryEmpty")).Visibility==Visibility.Visible,"gallery empty state visible");
   Call(win,"SelectPage","sensors");Pump(700);Ready(()=>((ComboBox)Field(win,"sensorPicker")).IsEnabled);Call(win,"SelectPage","overview");Pump(200);Assert(dispatcherError==null,"asynchronous sensor read and page departure do not fault");
   var nested=new StackPanel();var rowPanel=new Grid();var input=new TextBox{Text="before"};rowPanel.Children.Add(input);nested.Children.Add(rowPanel);var values=typeof(MainWindow).GetMethod("EditorValues",BindingFlags.Static|BindingFlags.NonPublic);string before=String.Join("|",(IEnumerable<string>)values.Invoke(null,new object[]{nested}));input.Text="after";Assert(before!=String.Join("|",(IEnumerable<string>)values.Invoke(null,new object[]{nested})),"nested editor values participate in unsaved detection");
   return checks.ToArray();
  }catch(Exception error){File.AppendAllText(report,error.ToString());throw;}finally{win.GetType().GetField("allowClose",BindingFlags.Instance|BindingFlags.NonPublic).SetValue(win,true);win.Close();Pump(100);}
 }
}
'@
$compile=Join-Path $Root ('tests\v30-check-assembly-'+[guid]::NewGuid().ToString('N'));New-Item -ItemType Directory -Force $compile|Out-Null
$source=Join-Path $compile 'Interactions.cs';$assembly=Join-Path $compile 'Interactions.dll';[IO.File]::WriteAllText($source,$code,$Utf8)
$arguments=@('/nologo','/target:library',('/out:'+$assembly))+@($refs|ForEach-Object {'/reference:'+$_})+@($source)
& (Join-Path $framework 'csc.exe') @arguments
if($LASTEXITCODE -ne 0){throw '상호작용 검사 도우미 컴파일 실패'}
$null=[Reflection.Assembly]::LoadFrom($assembly)
$fixture=Join-Path ([IO.Path]::GetTempPath()) ('gunt-v30-dev2-fixture-'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force $fixture|Out-Null
Copy-Item (Join-Path $Root 'config') $fixture -Recurse
New-Item -ItemType Directory -Force (Join-Path $fixture 'assets')|Out-Null
Copy-Item (Join-Path $Root 'assets\branding') (Join-Path $fixture 'assets') -Recurse
$checks=[V30Interactions]::Run($Root,$fixture,$ResultLabel)
Write-Json @{Status='passed';Checks=$checks;Count=$checks.Count;Scope='실제 WPF 컨트롤, 저장은 격리된 검증 폴더만 사용. 외부 CLI/배경 적용 실행 안 함.'} (Join-Path $Root ('logs\v30-'+$ResultLabel+'-interactions.json'))
Write-Output ('WPF 상호작용 검사 '+$checks.Count+'개 통과')
