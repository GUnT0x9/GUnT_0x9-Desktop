. "$PSScriptRoot\common.ps1"
Add-Type -Path (Join-Path $Root 'bin\Gunt.Configuration.dll')
Add-Type @'
using System;using System.Runtime.InteropServices;using System.Drawing;
public static class GuntMonitorInput24{[DllImport("user32.dll")]public static extern bool SetProcessDpiAwarenessContext(IntPtr p);[DllImport("user32.dll")]static extern bool GetCursorPos(out Point p);[DllImport("user32.dll")]static extern bool SetCursorPos(int x,int y);[DllImport("user32.dll")]static extern void mouse_event(uint f,uint x,uint y,uint d,UIntPtr e);public static void Click(int x,int y){Point old;GetCursorPos(out old);SetCursorPos(x,y);mouse_event(2,0,0,0,UIntPtr.Zero);mouse_event(4,0,0,0,UIntPtr.Zero);SetCursorPos(old.X,old.Y);}public static void Drag(int x,int y,int dx,int dy){Point old;GetCursorPos(out old);SetCursorPos(x,y);mouse_event(2,0,0,0,UIntPtr.Zero);for(int i=1;i<=10;i++){SetCursorPos(x+dx*i/10,y+dy*i/10);System.Threading.Thread.Sleep(25);}mouse_event(4,0,0,0,UIntPtr.Zero);SetCursorPos(old.X,old.Y);}}
'@ -ReferencedAssemblies System.Drawing
[GuntMonitorInput24]::SetProcessDpiAwarenessContext([IntPtr](-4))|Out-Null
$path=Join-Path $Root 'config\monitor.json';$original=Get-Content $path -Raw -Encoding UTF8|ConvertFrom-Json
$rows=@();$testStart=Get-Date
try{
 # Input tests require the desktop, so temporarily minimize and then restore ordinary windows.
 $shell=New-Object -ComObject Shell.Application;$shell.MinimizeAll();Start-Sleep -Milliseconds 600
 foreach($cpu in $true,$false){foreach($network in $true,$false){
  $m=Get-Content $path -Raw -Encoding UTF8|ConvertFrom-Json;$m.compact=$false;$m.visible=$true;$m.showCpuGraph=$cpu;$m.showNetworkGraph=$network;Write-Json $m $path
  & "$PSScriptRoot\update-monitor.ps1";Start-Sleep -Milliseconds 500
  $runtime=Get-Content (Join-Path $Root 'config\runtime.json') -Raw -Encoding UTF8|ConvertFrom-Json
  $vars=[IO.File]::ReadAllText($runtime.variables);$h=[int]([regex]::Match($vars,'(?m)^PanelHeight=(\d+)').Groups[1].Value)
  if($vars -notmatch ('(?m)^HideCPUGraph='+[int](!$cpu)+'\r?$') -or $vars -notmatch ('(?m)^HideNetworkGraph='+[int](!$network)+'\r?$')){throw '독립 그래프 표시 설정 불일치'}
  $rows+=@{CpuGraph=$cpu;NetworkGraph=$network;HeightDip=$h}
 }}
 $both=$rows|Where-Object {$_.CpuGraph -and $_.NetworkGraph};$none=$rows|Where-Object {!$_.CpuGraph -and !$_.NetworkGraph}
 if($both.HeightDip-$none.HeightDip -ne 202){throw '그래프를 접을 때 높이 회수량이 맞지 않습니다.'}
 $m=Get-Content $path -Raw -Encoding UTF8|ConvertFrom-Json;$m.compact=$false;Write-Json $m $path;& "$PSScriptRoot\update-monitor.ps1";Start-Sleep -Milliseconds 300
 $bounds=New-Object GuntLayout+RECT;[GuntLayout]::GetWindowRect([GuntLayout]::MonitorWindow(),[ref]$bounds)|Out-Null
 $scale=(Get-Content (Join-Path $Root 'config\runtime.json') -Raw -Encoding UTF8|ConvertFrom-Json).widgetScale
 # Click the left padding, away from the mode label center.
 [GuntMonitorInput24]::Click(($bounds.Right-[int](70*$scale)),($bounds.Top+[int](25*$scale)))
 for($i=0;$i -lt 40;$i++){Start-Sleep -Milliseconds 200;$c=Get-Content $path -Raw -Encoding UTF8|ConvertFrom-Json;if($c.compact){break}}
 if(!$c.compact){throw '간단히 버튼의 여백 클릭이 작동하지 않습니다.'}
 [GuntMonitorInput24]::Click(($bounds.Right-[int](22*$scale)),($bounds.Top+[int](25*$scale)))
 for($i=0;$i -lt 40;$i++){Start-Sleep -Milliseconds 200;$c=Get-Content $path -Raw -Encoding UTF8|ConvertFrom-Json;if(!$c.compact){break}}
 if($c.compact){throw '자세히 버튼의 전체 클릭 영역이 작동하지 않습니다.'}
 $c.position.mode='auto';$c.position.locked=$false;Write-Json $c $path;& "$PSScriptRoot\update-monitor.ps1";Start-Sleep -Milliseconds 400
 [GuntLayout]::GetWindowRect([GuntLayout]::MonitorWindow(),[ref]$bounds)|Out-Null
 [GuntMonitorInput24]::Drag(($bounds.Left+90),($bounds.Top+32),-180,60)
 for($i=0;$i -lt 35;$i++){Start-Sleep -Milliseconds 200;$c=Get-Content $path -Raw -Encoding UTF8|ConvertFrom-Json;if($c.position.mode -eq 'manual'){break}}
 if($c.position.mode -ne 'manual'){throw '제목 드래그 위치가 저장되지 않았습니다.'}
 $saved=$c.position;& "$PSScriptRoot\update-monitor.ps1";Start-Sleep -Milliseconds 400
 $expected=[GuntLayout]::Resolve($Root,0);[GuntLayout]::GetWindowRect([GuntLayout]::MonitorWindow(),[ref]$bounds)|Out-Null
 if([math]::Abs($bounds.Left-$expected['x']) -gt 3){throw '새로고침 후 저장 좌표가 유지되지 않습니다.'}
 $result=@{Time=(Get-Date).ToString('o');Status='passed';GraphCombinations=$rows;ReclaimedHeightDip=202;WholeModeButton=$true;HeaderDrag=$true;SavedPosition=$saved;RefreshRestoresPosition=$true;ActualSignIn='미시험';CrossMonitorDrag='별도 검증 필요'}
 Write-Json $result (Join-Path $Root 'logs\v24-monitor-verification.json');Write-Log 'monitor-v24-test' 'passed' '그래프 4조합·모드 버튼 여백·제목 드래그 저장·새로고침 복원을 확인했습니다.'
}finally{Write-Json $original $path;& "$PSScriptRoot\update-monitor.ps1";if($shell){$shell.UndoMinimizeAll()}}
