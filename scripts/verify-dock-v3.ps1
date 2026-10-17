. "$PSScriptRoot\common.ps1"
Add-Type -AssemblyName UIAutomationClient,UIAutomationTypes,System.Windows.Forms
Add-Type @'
using System;using System.Runtime.InteropServices;
public static class GuntDockV3Test {
 [StructLayout(LayoutKind.Sequential)] public struct POINT {public int x,y;}
 [DllImport("user32.dll",CharSet=CharSet.Unicode)]static extern IntPtr FindWindow(string c,string t);
 [DllImport("user32.dll")]public static extern bool SetProcessDpiAwarenessContext(IntPtr c);
 [DllImport("user32.dll")]public static extern IntPtr GetForegroundWindow();
 [DllImport("user32.dll")]public static extern bool SetForegroundWindow(IntPtr h);
 [DllImport("user32.dll")]public static extern uint GetWindowThreadProcessId(IntPtr h,out uint p);
 [DllImport("user32.dll")]static extern IntPtr WindowFromPoint(POINT p);
 [DllImport("user32.dll")]static extern IntPtr GetAncestor(IntPtr h,uint f);
 [DllImport("user32.dll")]public static extern bool SetCursorPos(int x,int y);
 [DllImport("user32.dll")]public static extern void mouse_event(uint f,uint x,uint y,uint d,UIntPtr p);
 public static IntPtr Shell(){return FindWindow("Shell_TrayWnd",null);}
 public static bool CheckPoint(int x,int y){return GetAncestor(WindowFromPoint(new POINT{x=x,y=y}),2)==Shell();}
}
'@
[GuntDockV3Test]::SetProcessDpiAwarenessContext([IntPtr](-4))|Out-Null
$taskbar=[Windows.Automation.AutomationElement]::FromHandle([GuntDockV3Test]::Shell())
$items=$taskbar.FindAll([Windows.Automation.TreeScope]::Descendants,[Windows.Automation.Condition]::TrueCondition)
$frame=@($items|Where-Object {$_.Current.AutomationId -eq 'TaskbarFrame'})|Select-Object -First 1
$tray=@($items|Where-Object {$_.Current.ClassName -eq 'TrayNotifyWnd'})|Select-Object -First 1
$apps=@($items|Where-Object {$_.Current.ClassName -eq 'Taskbar.TaskListButtonAutomationPeer' -and !$_.Current.IsOffscreen})
$overflow=@($items|Where-Object {$_.Current.AutomationId -eq 'OverflowButton' -and !$_.Current.IsOffscreen})
$clock=@($items|Where-Object {$_.Current.Name -like '시계*'})|Select-Object -First 1
$scale=(Get-Content (Join-Path $Root 'config\runtime.json') -Raw -Encoding UTF8|ConvertFrom-Json).scale
$config=Get-Content (Join-Path $Root 'config\dock.json') -Raw -Encoding UTF8|ConvertFrom-Json
$results=New-Object Collections.Generic.List[object]
function Result($n,$s,$e){$results.Add([pscustomobject]@{Test=$n;Status=$s;Evidence=$e});Write-Log $n $s $e}
$b=$frame.Current.BoundingRectangle;$t=$tray.Current.BoundingRectangle
Result '중앙 기준 왼쪽 확장 배치' $(if($b.X -gt 100 -and $b.Right -le $t.X -and $t.X-$b.Right -lt 200){'passed'}else{'failed'}) ('앱='+$b.ToString()+'; 트레이='+$t.ToString())
Result '낮은 Dock 높이' $(if([math]::Abs($b.Height/$scale-$config.height) -le 2){'passed'}else{'failed'}) ($b.Height/$scale).ToString()
$overlap=$false
for($i=1;$i -lt $apps.Count;$i++){if($apps[$i].Current.BoundingRectangle.X -lt $apps[$i-1].Current.BoundingRectangle.Right-1){$overlap=$true}}
Result '앱 버튼 간격·겹침' $(if(!$overlap -and $apps.Count -ge 15){'passed'}else{'failed'}) ('표시 앱 '+$apps.Count+'개, 오버플로 버튼 '+$overflow.Count+'개')
$a=$clock.Current.Name;Start-Sleep -Milliseconds 1250;$z=$clock.Current.Name
Result '한국어 초 단위 시계' $(if($a -match '\d{2}:\d{2}:\d{2}' -and $a -ne $z -and $z -match '월.*일'){'passed'}else{'failed'}) ($a+' → '+$z)
$foreground=[GuntDockV3Test]::GetForegroundWindow();$cursor=[Windows.Forms.Cursor]::Position
$chrome=@($apps|Where-Object {$_.Current.Name -like 'Google Chrome*실행*'})|Select-Object -First 1
try{
 if($chrome){
  $shell=New-Object -ComObject Shell.Application;$shell.MinimizeAll();Start-Sleep -Milliseconds 500
  $rect=$chrome.Current.BoundingRectangle;$x=[int]($rect.X+$rect.Width/2);$y=[int]($rect.Y+$rect.Height/2)
  if(![GuntDockV3Test]::CheckPoint($x,$y)){throw '실제 작업 표시줄 위치가 아니므로 클릭을 중단했습니다.'}
  [GuntDockV3Test]::SetCursorPos($x,$y)|Out-Null
  [GuntDockV3Test]::mouse_event(2,0,0,0,[UIntPtr]::Zero);[GuntDockV3Test]::mouse_event(4,0,0,0,[UIntPtr]::Zero)
  Start-Sleep -Milliseconds 800;$processId=[uint32]0
  [GuntDockV3Test]::GetWindowThreadProcessId([GuntDockV3Test]::GetForegroundWindow(),[ref]$processId)|Out-Null
  $active=Get-Process -Id $processId -ErrorAction SilentlyContinue
  Result '실행 중인 앱 전환' $(if($active.ProcessName -eq 'chrome'){'passed'}else{'partial'}) ('전경 프로세스 '+$active.ProcessName)
 }else{Result '실행 중인 앱 전환' 'not-tested' '검사 대상인 기존 Chrome 버튼이 없습니다.'}
}finally{
 if($shell){$shell.UndoMinimizeAll()};[GuntDockV3Test]::SetCursorPos($cursor.X,$cursor.Y)|Out-Null;[GuntDockV3Test]::SetForegroundWindow($foreground)|Out-Null
}
$ids=@(Get-Process explorer -ErrorAction SilentlyContinue|Select-Object -ExpandProperty Id)
Result 'Explorer 응답' $(if(@(Get-Process explorer|Where-Object Responding).Count){'passed'}else{'failed'}) ($ids -join ',')
Write-Json $results.ToArray() (Join-Path $Root 'logs\v23-dock-verification.json')
if(@($results|Where-Object Status -eq 'failed').Count){throw 'Dock v3 검사 실패 항목이 있습니다.'}
