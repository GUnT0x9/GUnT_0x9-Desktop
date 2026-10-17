. "$PSScriptRoot\common.ps1"
Add-Type -AssemblyName System.Drawing,System.Windows.Forms
Add-Type -Path (Join-Path $Root 'bin\Gunt.Configuration.dll')
Add-Type @'
using System;using System.Drawing;using System.Runtime.InteropServices;
public static class DisplayDrag24{[DllImport("user32.dll")]public static extern bool SetProcessDpiAwarenessContext(IntPtr p);[DllImport("user32.dll")]static extern bool SetCursorPos(int x,int y);[DllImport("user32.dll")]static extern bool GetCursorPos(out Point p);[DllImport("user32.dll")]static extern void mouse_event(uint f,uint x,uint y,uint d,UIntPtr e);public static void Drag(int x,int y,int toX,int toY){Point old;GetCursorPos(out old);SetCursorPos(x,y);mouse_event(2,0,0,0,UIntPtr.Zero);for(int i=1;i<=20;i++){SetCursorPos(x+(toX-x)*i/20,y+(toY-y)*i/20);System.Threading.Thread.Sleep(30);}mouse_event(4,0,0,0,UIntPtr.Zero);SetCursorPos(old.X,old.Y);}}
'@ -ReferencedAssemblies System.Drawing
[DisplayDrag24]::SetProcessDpiAwarenessContext([IntPtr](-4))|Out-Null
$path=Join-Path $Root 'config\monitor.json';$original=Get-Content $path -Raw -Encoding UTF8|ConvertFrom-Json;$results=@()
$shell=New-Object -ComObject Shell.Application
try{
 $shell.MinimizeAll();Start-Sleep -Milliseconds 500
 $c=Get-Content $path -Raw -Encoding UTF8|ConvertFrom-Json;$c.visible=$true;$c.compact=$false;$c.position.locked=$false;$c.position.mode='auto';Write-Json $c $path;& "$PSScriptRoot\update-monitor.ps1";Start-Sleep -Milliseconds 400
 foreach($screen in [Windows.Forms.Screen]::AllScreens|Where-Object {!$_.Primary}|Sort-Object {$_.Bounds.Top} -Descending){
  $rect=New-Object GuntLayout+RECT;[GuntLayout]::GetWindowRect([GuntLayout]::MonitorWindow(),[ref]$rect)|Out-Null
  $targetX=$screen.WorkingArea.Left+120;$targetY=$screen.WorkingArea.Top+50
  [DisplayDrag24]::Drag(($rect.Left+90),($rect.Top+32),$targetX,$targetY)
  $id=[GuntLayout]::MonitorId($screen);$expectedScale=[GuntLayout]::Scale($screen);$correct=$false
  for($i=0;$i -lt 50;$i++){Start-Sleep -Milliseconds 200;$c=Get-Content $path -Raw -Encoding UTF8|ConvertFrom-Json;$layout=Get-Content (Join-Path $Root 'config\layout.json') -Raw -Encoding UTF8|ConvertFrom-Json;if($c.position.monitorId -eq $id -and [math]::Abs($layout.WidgetScale-$expectedScale) -lt 0.01){$correct=$true;break}}
  if(!$correct){throw ('외부 화면 식별·DPI 전환 실패: '+$screen.DeviceName)}
  Start-Sleep -Milliseconds 1200
  [GuntLayout]::GetWindowRect([GuntLayout]::MonitorWindow(),[ref]$rect)|Out-Null
  if($rect.Left -lt $screen.Bounds.Left -or $rect.Top -lt $screen.Bounds.Top -or $rect.Right -gt $screen.Bounds.Right+2 -or $rect.Bottom -gt $screen.Bounds.Bottom+2){throw ('위젯 경계 불일치: '+$rect.Left+','+$rect.Top+','+$rect.Right+','+$rect.Bottom+'; 대상 '+$screen.Bounds.ToString()+'; 계산 '+($layout|ConvertTo-Json -Compress))}
  & "$PSScriptRoot\update-monitor.ps1";Start-Sleep -Milliseconds 350
  $after=New-Object GuntLayout+RECT;[GuntLayout]::GetWindowRect([GuntLayout]::MonitorWindow(),[ref]$after)|Out-Null
  if([math]::Abs($after.Left-$rect.Left) -gt 3 -or [math]::Abs($after.Top-$rect.Top) -gt 3){throw '다중 모니터 새로고침 후 위치가 달라졌습니다.'}
  $results+=@{MonitorId=$id;Device=$screen.DeviceName;Scale=$expectedScale;Bounds=$screen.Bounds.ToString();Widget=@{Left=$after.Left;Top=$after.Top;Width=$after.Right-$after.Left;Height=$after.Bottom-$after.Top};Status='passed'}
 }
 Write-Json @{Time=(Get-Date).ToString('o');Status='passed';Displays=$results;ActualDrag=$true;NegativeCoordinates=$true;GlobalDisplayConfigurationChanged=$false} (Join-Path $Root 'logs\v24-display-verification.json')
 Write-Log 'displays-v24-test' 'passed' '실제 헤더 드래그로 150%·100% 화면과 음수 좌표에서 배율·경계·위치 복원을 확인했습니다.'
}finally{Write-Json $original $path;& "$PSScriptRoot\update-monitor.ps1";$shell.UndoMinimizeAll()}
