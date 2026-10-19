param([Parameter(Mandatory=$true)][string]$Executable,[Parameter(Mandatory=$true)][ValidatePattern('^[a-z0-9.-]+$')][string]$Label,[ValidateRange(10,100)][int]$Samples=20)
. "$PSScriptRoot\enhancement-ui-common.ps1"
if(Get-Process GUNT.ControlCenter -ErrorAction SilentlyContinue){throw '기존 제어 센터를 먼저 닫으세요.'}
Add-Type -AssemblyName PresentationFramework,PresentationCore,WindowsBase,System.Xaml
$bin=Split-Path (Resolve-Path $Executable).Path -Parent;$framework=Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319';$wpf=Join-Path $framework 'WPF'
$refs=@('System.dll','System.Core.dll','System.Xaml.dll','System.Web.Extensions.dll')|ForEach-Object {Join-Path $framework $_}
$refs+=@('PresentationFramework.dll','PresentationCore.dll','WindowsBase.dll')|ForEach-Object {Join-Path $wpf $_}
$refs+=@('GUNT.ControlCenter.exe','Gunt.Configuration.dll','Gunt.Sensors.dll')|ForEach-Object {$path=Join-Path $bin $_;$null=[Reflection.Assembly]::LoadFrom($path);$path}
$code=@'
using System;using System.IO;using System.Linq;using System.Collections.Generic;using System.Diagnostics;using System.Reflection;using System.Windows;using System.Windows.Controls;using System.Windows.Media;using System.Windows.Threading;
using Gunt.ControlCenter.Views;using Gunt.ControlCenter.Models;using Gunt.ControlCenter.Services;
public static class SessionMeasure {
 static object Field(object value,string name){return value.GetType().GetField(name,BindingFlags.Instance|BindingFlags.NonPublic).GetValue(value);}
 static object Call(object value,string name,params object[] args){return value.GetType().GetMethod(name,BindingFlags.Instance|BindingFlags.NonPublic).Invoke(value,args);}
 static void Pump(int ms){var frame=new DispatcherFrame();var timer=new DispatcherTimer{Interval=TimeSpan.FromMilliseconds(ms)};timer.Tick+=delegate{timer.Stop();frame.Continue=false;};timer.Start();Dispatcher.PushFrame(frame);}
 static IEnumerable<T> Visuals<T>(DependencyObject root)where T:DependencyObject{for(int i=0;i<VisualTreeHelper.GetChildrenCount(root);i++){var child=VisualTreeHelper.GetChild(root,i);if(child is T)yield return (T)child;foreach(var x in Visuals<T>(child))yield return x;}}
 public static double[] Run(string fixture,int samples){
  var service=new DesktopService(fixture);var project=new ProjectEntry{Id="example",Name="측정 예제",Directory=fixture,Commands=new List<string>(),Ide="vscode",Terminal="powershell"};
  File.WriteAllText(Path.Combine(fixture,"config","projects.json"),service.Json.Serialize(new ProjectStore{SchemaVersion=2,Projects=new List<ProjectEntry>{project}}));
  var developer=service.Developer();developer.SelectedProjectId=project.Id;service.SaveDeveloper(developer);
  var actions=new[]{"ide","ai","project-terminal","folder"}.Select((kind,i)=>new SessionAction{Id="step-"+i,Kind=kind}).ToList();
  File.WriteAllText(Path.Combine(fixture,"config","development-sessions.json"),service.Json.Serialize(new SessionStore{Presets=new List<DevelopmentSession>{new DevelopmentSession{Id="ai-coding",Name="측정 세션",Builtin=true,Actions=actions}}}));
  var app=Application.Current??new Application();app.ShutdownMode=ShutdownMode.OnExplicitShutdown;System.Threading.SynchronizationContext.SetSynchronizationContext(new DispatcherSynchronizationContext(app.Dispatcher));
  var window=new MainWindow(fixture,"development-sessions"){Width=1180,Height=800};var results=new List<double>();
  try{window.Show();Pump(600);var editor=(StackPanel)Field(window,"sessionStepEditor");var first=Visuals<Expander>(editor).First();first.IsExpanded=true;window.UpdateLayout();Pump(80);var step=((DevelopmentSession)Field(window,"sessionDraft")).Actions[0];
   // Four warm-up moves (even count) leave the selected step in its original position.
   for(int i=0;i<samples+4;i++){var timer=Stopwatch.StartNew();Call(window,"MoveSessionStep",step,i%2==0?1:-1);window.UpdateLayout();timer.Stop();if(i>=4)results.Add(timer.Elapsed.TotalMilliseconds);Pump(5);}
   return results.ToArray();
  }finally{window.GetType().GetField("allowClose",BindingFlags.Instance|BindingFlags.NonPublic).SetValue(window,true);window.Close();Pump(80);}
 }
}
'@
$folder=Join-Path $Root ('tests\v30-editor-measure-'+[guid]::NewGuid().ToString('N'));New-Item -ItemType Directory -Force $folder|Out-Null
$source=Join-Path $folder 'Measure.cs';$assembly=Join-Path $folder 'Measure.dll';[IO.File]::WriteAllText($source,$code,$Utf8)
& (Join-Path $framework 'csc.exe') @('/nologo','/target:library',('/out:'+$assembly)) @($refs|ForEach-Object {'/reference:'+$_}) $source
if($LASTEXITCODE -ne 0){throw '세션 측정 도우미 컴파일 실패'}
$null=[Reflection.Assembly]::LoadFrom($assembly)
$fixture=Join-Path $folder 'fixture';New-Item -ItemType Directory -Force $fixture,(Join-Path $fixture 'assets')|Out-Null
Copy-Item (Join-Path $Root 'config') $fixture -Recurse;Copy-Item (Join-Path $Root 'assets\branding') (Join-Path $fixture 'assets') -Recurse
$values=[SessionMeasure]::Run($fixture,$Samples)
Write-Json @{Status='passed';ExecutableSha256=(Get-FileHash $Executable).Hash;Samples=$Samples;Ms=$values;Scope='Windows STA 실제 WPF. 1180x800 DIP. 동일 4단계 중 첫 단계 속성을 펼친 상태에서 위/아래 이동 후 UpdateLayout 완료까지. 준비 4회 제외. 외부 도구 실행 및 사용자 세션 저장 없음.'} (Join-Path $Root ('logs\v30-'+$Label+'-session-editor.json'))
Write-Output ('세션 단계 이동 '+$Samples+'회 측정: '+$Label)
