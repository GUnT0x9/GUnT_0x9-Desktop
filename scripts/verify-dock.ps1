. "$PSScriptRoot\common.ps1"
Add-Type -AssemblyName UIAutomationClient,UIAutomationTypes,System.Windows.Forms
Add-Type @'
using System;using System.Runtime.InteropServices;
public static class GuntDockTest {
 [DllImport("user32.dll",CharSet=CharSet.Unicode)] static extern IntPtr FindWindow(string c,string t);
 [DllImport("user32.dll")] public static extern bool SetProcessDpiAwarenessContext(IntPtr c);
 [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
 [StructLayout(LayoutKind.Sequential)] public struct POINT {public int x,y;}
 [DllImport("user32.dll")] static extern IntPtr WindowFromPoint(POINT p);
 [DllImport("user32.dll")] static extern IntPtr GetAncestor(IntPtr h,uint f);
 public static bool IsTaskbarPoint(int x,int y){return GetAncestor(WindowFromPoint(new POINT{x=x,y=y}),2)==Taskbar();}
 [DllImport("user32.dll")] public static extern bool SetCursorPos(int x,int y);
 [DllImport("user32.dll")] public static extern void mouse_event(uint f,uint x,uint y,uint data,UIntPtr info);
 [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
 public static IntPtr Taskbar(){return FindWindow("Shell_TrayWnd",null);}
}
'@
[GuntDockTest]::SetProcessDpiAwarenessContext([IntPtr](-4))|Out-Null
$foreground=[GuntDockTest]::GetForegroundWindow()
$cursor=[Windows.Forms.Cursor]::Position
$taskbar=[Windows.Automation.AutomationElement]::FromHandle([GuntDockTest]::Taskbar())
$items=$taskbar.FindAll([Windows.Automation.TreeScope]::Descendants,[Windows.Automation.Condition]::TrueCondition)
$frame=@($items|Where-Object {$_.Current.AutomationId -eq 'TaskbarFrame'})|Select-Object -First 1
$icon=@($items|Where-Object {$_.Current.AutomationId -eq 'Icon' -and $_.Current.ControlType -eq [Windows.Automation.ControlType]::Image})|Select-Object -First 1
$layout=Get-Content (Join-Path $Root 'config\layout.json') -Raw -Encoding UTF8|ConvertFrom-Json
$config=Get-Content (Join-Path $Root 'config\dock.json') -Raw -Encoding UTF8|ConvertFrom-Json
$bounds=$frame.Current.BoundingRectangle;$screen=[Windows.Forms.Screen]::PrimaryScreen.Bounds
$results=New-Object Collections.Generic.List[object]
function Result($n,$s,$e){$results.Add([pscustomobject]@{Test=$n;Status=$s;Evidence=$e});Write-Log $n $s $e}
Result 'Dock 중앙 배치' $(if([math]::Abs($bounds.X+$bounds.Width/2-($screen.Left+$screen.Width/2)) -le 3){'passed'}else{'failed'}) $bounds.ToString()
Result 'Dock 아이콘 확대' $(if($icon -and [math]::Abs($icon.Current.BoundingRectangle.Width-$config.iconSize*$layout.Scale) -le 2){'passed'}else{'partial'}) $(if($icon){$icon.Current.BoundingRectangle.ToString()}else{'아이콘 크기 자동 판독 불가'})
$tray=@($items|Where-Object {$_.Current.ClassName -eq 'TrayNotifyWnd'})|Select-Object -First 1
Result 'Dock과 트레이 간격' $(if($tray -and $bounds.Right -le $tray.Current.BoundingRectangle.X){'passed'}else{'failed'}) ('Dock 오른쪽 '+$bounds.Right+'; 트레이 왼쪽 '+$tray.Current.BoundingRectangle.X)
$manager=@($items|Where-Object {$_.Current.Name -eq '작업 관리자 고정됨'})|Select-Object -First 1
$before=@(Get-Process Taskmgr -ErrorAction SilentlyContinue|Select-Object -ExpandProperty Id)
try{
 if($manager -and !$before.Count){
  $shell=New-Object -ComObject Shell.Application;$shell.MinimizeAll();Start-Sleep -Milliseconds 500
  [GuntDockTest]::SetForegroundWindow([GuntDockTest]::Taskbar())|Out-Null
  $rect=$manager.Current.BoundingRectangle;$point=New-Object Drawing.Point ([int]($rect.X+$rect.Width/2)),([int]($rect.Y+$rect.Height/2))
  if(![GuntDockTest]::IsTaskbarPoint($point.X,$point.Y)){throw '대상 위치가 실제 Windows 작업 표시줄에 속하지 않아 클릭을 중단했습니다.'}
  [GuntDockTest]::SetCursorPos([int]$point.X,[int]$point.Y)|Out-Null
  [GuntDockTest]::mouse_event(2,0,0,0,[UIntPtr]::Zero);[GuntDockTest]::mouse_event(4,0,0,0,[UIntPtr]::Zero)
  Start-Sleep -Seconds 2
  $created=@(Get-Process Taskmgr -ErrorAction SilentlyContinue|Where-Object {$before -notcontains $_.Id})
  Result 'Dock 고정 앱 실행' $(if($created.Count -and @($created|Where-Object Responding).Count){'passed'}else{'partial'}) '고정된 작업 관리자 버튼의 실제 실행'
 }else{Result 'Dock 고정 앱 실행' 'not-tested' '기존 작업 관리자 창 또는 표시되지 않은 고정 버튼 때문에 자동 실행 검사를 건너뛰었습니다.'}
}catch{Result 'Dock 고정 앱 실행' 'failed' $_.Exception.Message}
finally{
 [GuntDockTest]::SetCursorPos($cursor.X,$cursor.Y)|Out-Null
 foreach($p in @($created)){if($p){$p.CloseMainWindow()|Out-Null;$p.WaitForExit(3000)|Out-Null}}
 if($shell){$shell.UndoMinimizeAll()}
 [GuntDockTest]::SetForegroundWindow($foreground)|Out-Null
}
Result '여러 창 전환·오른쪽 클릭 메뉴' 'not-tested' 'Windows 기본 작업 표시줄을 유지했습니다. 모든 창 그룹과 우클릭 조합은 검사하지 않았습니다.'
Write-Json $results.ToArray() (Join-Path $Root 'logs\v21-dock-verification.json')
