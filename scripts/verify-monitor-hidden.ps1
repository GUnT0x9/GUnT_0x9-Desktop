. "$PSScriptRoot\common.ps1"
Add-Type -AssemblyName System.Windows.Forms,System.Drawing
Add-Type -Path (Join-Path $Root 'bin\Gunt.Configuration.dll')
Add-Type @'
using System;using System.Collections.Generic;using System.Diagnostics;using System.Drawing;using System.Runtime.InteropServices;using System.Text;using System.Threading;using System.Windows.Forms;
public static class GuntConsoleWatch {
 public class Seen {public string Time,Process,Class,Title;public int Pid;public uint Event;}
 static readonly object sync=new object();static List<Seen> seen=new List<Seen>();static Thread thread;static ApplicationContext context;static ManualResetEvent ready=new ManualResetEvent(false);static WinEventDelegate callback;static IntPtr show,foreground;public static int Events;
 delegate void WinEventDelegate(IntPtr hook,uint ev,IntPtr hwnd,int obj,int child,uint tid,uint ms);
 [DllImport("user32.dll")]static extern IntPtr SetWinEventHook(uint a,uint b,IntPtr m,WinEventDelegate f,uint p,uint t,uint flags);
 [DllImport("user32.dll")]static extern bool UnhookWinEvent(IntPtr hook);
 [DllImport("user32.dll")]static extern bool IsWindowVisible(IntPtr h);
 [DllImport("user32.dll")]static extern uint GetWindowThreadProcessId(IntPtr h,out uint p);
 [DllImport("user32.dll",CharSet=CharSet.Unicode)]static extern int GetClassName(IntPtr h,StringBuilder s,int n);
 [DllImport("user32.dll",CharSet=CharSet.Unicode)]static extern int GetWindowText(IntPtr h,StringBuilder s,int n);
 [DllImport("user32.dll")]public static extern bool SetProcessDpiAwarenessContext(IntPtr c);
 [DllImport("user32.dll")]static extern IntPtr WindowFromPoint(Point p);
 public static long At(int x,int y){return WindowFromPoint(new Point(x,y)).ToInt64();}
 [DllImport("user32.dll")]static extern bool GetCursorPos(out Point p);
 [DllImport("user32.dll")]static extern bool SetCursorPos(int x,int y);
 [DllImport("user32.dll")]static extern void mouse_event(uint f,uint x,uint y,uint d,UIntPtr e);
 public static void Click(int x,int y){Point p;GetCursorPos(out p);SetCursorPos(x,y);mouse_event(2,0,0,0,UIntPtr.Zero);Thread.Sleep(30);mouse_event(4,0,0,0,UIntPtr.Zero);Thread.Sleep(120);SetCursorPos(p.X,p.Y);}
 static void Observe(IntPtr hook,uint ev,IntPtr h,int obj,int child,uint tid,uint ms){if(h==IntPtr.Zero||obj!=0||!IsWindowVisible(h))return;Interlocked.Increment(ref Events);try{uint pid;GetWindowThreadProcessId(h,out pid);string name=Process.GetProcessById((int)pid).ProcessName;var c=new StringBuilder(256);var t=new StringBuilder(1024);GetClassName(h,c,c.Capacity);GetWindowText(h,t,t.Capacity);if(c.ToString()=="ConsoleWindowClass"||c.ToString()=="CASCADIA_HOSTING_WINDOW_CLASS"||name.Equals("powershell",StringComparison.OrdinalIgnoreCase)||name.Equals("pwsh",StringComparison.OrdinalIgnoreCase)||name.Equals("WindowsTerminal",StringComparison.OrdinalIgnoreCase)||name.Equals("OpenConsole",StringComparison.OrdinalIgnoreCase)||name.Equals("conhost",StringComparison.OrdinalIgnoreCase)){lock(sync)seen.Add(new Seen{Time=DateTime.Now.ToString("o"),Process=name,Class=c.ToString(),Title=t.ToString(),Pid=(int)pid,Event=ev});}}catch{}}
 public static void Start(){thread=new Thread(()=>{context=new ApplicationContext();callback=Observe;show=SetWinEventHook(0x8002,0x8002,IntPtr.Zero,callback,0,0,0);foreground=SetWinEventHook(3,3,IntPtr.Zero,callback,0,0,0);ready.Set();Application.Run(context);UnhookWinEvent(show);UnhookWinEvent(foreground);});thread.IsBackground=true;thread.SetApartmentState(ApartmentState.STA);thread.Start();ready.WaitOne();if(show==IntPtr.Zero||foreground==IntPtr.Zero)throw new Exception("Window event hook unavailable");}
 public static Seen[] Stop(){context.ExitThread();thread.Join(3000);lock(sync)return seen.ToArray();}
}
'@ -ReferencedAssemblies System.Drawing,System.Windows.Forms
[GuntConsoleWatch]::SetProcessDpiAwarenessContext([IntPtr](-4))|Out-Null
$path=Join-Path $Root 'config\monitor.json';$original=Get-Content $path -Raw -Encoding UTF8|ConvertFrom-Json
if(!$original.visible){throw '모니터가 숨겨져 있어 실제 버튼 검사를 수행할 수 없습니다.'}
$started=Get-Date;$rows=@();$observing=$false;$shell=$null
try{
 $shell=New-Object -ComObject Shell.Application;$shell.MinimizeAll();$r=Get-Content (Join-Path $Root 'config\runtime.json') -Raw -Encoding UTF8|ConvertFrom-Json;Start-Process $r.rainmeter -ArgumentList '!ZPos 2 "GUNT-System-Monitor"';Start-Sleep -Milliseconds 600
 [GuntConsoleWatch]::Start();$observing=$true
 foreach($offset in 70,22,42,70,22,42){
  $m=Get-Content $path -Raw -Encoding UTF8|ConvertFrom-Json;$expected=!$m.compact
  $r=Get-Content (Join-Path $Root 'config\runtime.json') -Raw -Encoding UTF8|ConvertFrom-Json
  $rect=New-Object GuntLayout+RECT;[GuntLayout]::GetWindowRect([GuntLayout]::MonitorWindow(),[ref]$rect)|Out-Null
  Start-Process $r.rainmeter -ArgumentList '!ZPos 2 "GUNT-System-Monitor"';Start-Sleep -Milliseconds 200
  $clickWindow=[GuntConsoleWatch]::At(($rect.Right-[int]($offset*$r.widgetScale)),($rect.Top+[int](25*$r.widgetScale)));$stamp=Get-Date;$lastWrite=(Get-Item (Join-Path $Root 'config\runtime.json')).LastWriteTimeUtc
  [GuntConsoleWatch]::Click(($rect.Right-[int]($offset*$r.widgetScale)),($rect.Top+[int](25*$r.widgetScale)))
  $done=$false
  for($i=0;$i -lt 80;$i++){
   Start-Sleep -Milliseconds 150
   $m=Get-Content $path -Raw -Encoding UTF8|ConvertFrom-Json
   $r=Get-Content (Join-Path $Root 'config\runtime.json') -Raw -Encoding UTF8|ConvertFrom-Json
   $vars=[IO.File]::ReadAllText($r.variables)
   $height=[int]([regex]::Match($vars,'(?m)^PanelHeight=(\d+)').Groups[1].Value)
   [GuntLayout]::GetWindowRect([GuntLayout]::MonitorWindow(),[ref]$rect)|Out-Null
   if($m.compact -eq $expected -and (Get-Item (Join-Path $Root 'config\runtime.json')).LastWriteTimeUtc -gt $lastWrite -and [math]::Abs(($rect.Bottom-$rect.Top)-$height*$r.widgetScale) -lt 3){$done=$true;break}
  }
  if(!$done){Write-Json @{Expected=$expected;Mode=$m.compact;ClickWindow=$clickWindow;MonitorWindow=([GuntLayout]::MonitorWindow().ToInt64());Rect=$rect;PanelHeight=$height;Scale=$r.widgetScale;Started=$stamp;LastRuntime=(Get-Item (Join-Path $Root 'config\runtime.json')).LastWriteTimeUtc;BeforeRuntime=$lastWrite} (Join-Path $Root 'logs\monitor-hidden-failure.json');throw ('모드 전환/실제 위젯 높이 갱신 실패: '+$offset)}
  Start-Sleep -Milliseconds 1000
  $rows+=@{Compact=$expected;ClickRightOffsetDip=$offset;HeightPx=$rect.Bottom-$rect.Top;ElapsedMs=[int]((Get-Date)-$stamp).TotalMilliseconds}
 }
 $windows=@([GuntConsoleWatch]::Stop());$observing=$false
 $completion=@(Get-Content (Join-Path $Root 'logs\changes.jsonl') -Encoding UTF8|ForEach-Object {try{$_|ConvertFrom-Json}catch{}}|Where-Object {$_.action -eq 'monitor-mode' -and $_.status -eq 'applied' -and [datetime]$_.time -ge $started})
 $result=@{Time=(Get-Date).ToString('o');Transitions=$rows;CompletedTransactions=$completion.Count;VisibleConsoleEvents=$windows;ObservedWindowEvents=[GuntConsoleWatch]::Events;OriginalPosition=$original.position;FinalPosition=$m.position;Status=$(if($windows.Count -eq 0 -and $completion.Count -eq 6){'passed'}else{'failed'})}
 Write-Json $result (Join-Path $Root 'logs\monitor-hidden-verification.json')
 if($result.Status -ne 'passed'){throw '가시 콘솔 이벤트 또는 모드 완료 기록이 예상과 다릅니다.'}
 Write-Log 'monitor-hidden-test' 'passed' '버튼 여백·문자 영역 6회 실제 클릭, 위젯 높이와 저장 완료 확인, 보이는 콘솔 이벤트 0건.'
}finally{
 if($observing){[GuntConsoleWatch]::Stop()|Out-Null}
 if((Get-Content $path -Raw -Encoding UTF8|ConvertFrom-Json).compact -ne $original.compact){$m=Get-Content $path -Raw -Encoding UTF8|ConvertFrom-Json;$m.compact=$original.compact;Write-Json $m $path;& "$PSScriptRoot\update-monitor.ps1"}
 if($r){Start-Process $r.rainmeter -ArgumentList '!ZPos -2 "GUNT-System-Monitor"'}
 if($shell){$shell.UndoMinimizeAll()}
}
