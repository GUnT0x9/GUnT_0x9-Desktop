# Refresh only presentation resources; preserve runtime variables, measurements and placement.
. "$PSScriptRoot\enhancement-ui-common.ps1"
Add-Type -Path (Join-Path $Root 'bin\Gunt.Configuration.dll')
Add-Type @'
using System;using System.Runtime.InteropServices;
public static class V30MonitorVisual {
 [DllImport("user32.dll")]public static extern bool PrintWindow(IntPtr h,IntPtr dc,uint flags);
 [DllImport("user32.dll")]public static extern bool IsWindowVisible(IntPtr h);
}
'@
$runtime=Get-Content -Raw -Encoding UTF8 (Join-Path $Root 'config\runtime.json')|ConvertFrom-Json
$skin=$runtime.skin;$names=@('Styles.inc','Layout.inc');$stamp=Get-Date -Format 'yyyyMMdd-HHmmss'
$folder=Join-Path $Root ('screenshots\v30-dev3-monitor-'+$stamp);New-Item -ItemType Directory -Force $folder|Out-Null
$handle=[GuntLayout]::MonitorWindow();if($handle -eq [IntPtr]::Zero -or ![V30MonitorVisual]::IsWindowVisible($handle)){throw '현재 보이는 GUNT 위젯만 검사합니다. 숨김 설정은 변경하지 않습니다.'}
function Capture-Monitor($name){
 $r=New-Object GuntLayout+RECT;if(![GuntLayout]::GetWindowRect([GuntLayout]::MonitorWindow(),[ref]$r)){throw '위젯 좌표 조회 실패'}
 $b=New-Object Drawing.Bitmap(($r.Right-$r.Left),($r.Bottom-$r.Top));$g=[Drawing.Graphics]::FromImage($b);$dc=$g.GetHdc()
 try{if(![V30MonitorVisual]::PrintWindow([GuntLayout]::MonitorWindow(),$dc,2)){throw '위젯 캡처 실패'}}finally{$g.ReleaseHdc($dc);$g.Dispose()}
 try{$b.Save((Join-Path $folder ($name+'.png')))}finally{$b.Dispose()}
 return @($r.Left,$r.Top,$r.Right,$r.Bottom)
}
$protected=@(Get-ChildItem $skin -Recurse -File|Where-Object {$_.Extension -in '.lua','.ini','.inc' -and $_.Name -notin $names})+@(Get-Item (Join-Path $Root 'config\monitor.json'))
$before=@{};foreach($f in $protected){$before[$f.FullName]=(Get-FileHash $f.FullName).Hash}
$rectBefore=Capture-Monitor 'before'
foreach($name in $names){Copy-Item (Join-Path $skin ('@Resources\'+$name)) (Join-Path $folder $name)}
try{
 # The deployed layout has Y=0 for hidden meters. Patch presentation keys only.
 $changes=@{ 'Styles.inc'=@{NumericText=@('FontSize')};'Layout.inc'=@{CPUAxis=@('FontSize');CPUTimeAxis=@('FontSize');NetworkRates=@('FontSize','StringAlign','X');NetworkAxis=@('FontSize');NetworkTimeAxis=@('FontSize');SensorStatus=@('FontSize');CPUTimeRight=@('FontSize');NetworkTimeRight=@('FontSize')} }
 foreach($name in $names){
  $target=Join-Path $skin ('@Resources\'+$name);$live=[IO.File]::ReadAllText($target);$source=[IO.File]::ReadAllText((Join-Path $Root ('rainmeter\GUNT-System-Monitor\@Resources\'+$name)))
  foreach($section in $changes[$name].Keys){
   $pattern='(?ms)^\['+[regex]::Escape($section)+'\]\r?\n.*?(?=^\[|\z)';$block=[regex]::Match($live,$pattern).Value;$desired=[regex]::Match($source,$pattern).Value
   if(!$block -or !$desired){throw ('표시 섹션 없음: '+$section)}
   $updated=$block
   foreach($key in $changes[$name][$section]){
    $keyPattern='(?m)^'+[regex]::Escape($key)+'=[^\r\n]*';$value=[regex]::Match($desired,$keyPattern).Value
    if(!$value){throw ('표시 속성 없음: '+$section+'/'+$key)}
    if([regex]::IsMatch($updated,$keyPattern)){$updated=[regex]::Replace($updated,$keyPattern,$value)}else{$updated=$updated.TrimEnd()+"`r`n"+$value+"`r`n`r`n"}
   }
   $live=$live.Replace($block,$updated)
  }
  [IO.File]::WriteAllText($target,$live,[Text.Encoding]::Unicode)
 }
 $p=Start-Process $runtime.rainmeter -ArgumentList '!Refresh "GUNT-System-Monitor"' -PassThru;$null=$p.WaitForExit(5000);$p.Dispose();Start-Sleep -Seconds 3
 $rectAfter=Capture-Monitor 'after';$changed=@($protected|Where-Object {(Get-FileHash $_.FullName).Hash -ne $before[$_.FullName]})
 if($changed.Count){throw '표시 외 파일 변경 감지'}
 Write-Json @{Status='passed';ProtectedFiles=$protected.Count;ProtectedHashesUnchanged=$true;PositionUnchanged=($rectBefore[0] -eq $rectAfter[0] -and $rectBefore[1] -eq $rectAfter[1]);BoundsUnchanged=(($rectBefore -join ',') -eq ($rectAfter -join ','));BeforeBounds=$rectBefore;AfterBounds=$rectAfter;Screens=@([Windows.Forms.Screen]::AllScreens|ForEach-Object {@{Width=$_.Bounds.Width;Height=$_.Bounds.Height;Scale=[GuntLayout]::Scale($_)}});Scope='두 표시 include만 교체. 측정식·샘플링·사용자 Variables·설정 해시 보존. 센서값은 실제 현재 값.'} (Join-Path $Root 'logs\v30-dev3-monitor-visual.json')
 Write-Output ('실제 위젯 전후 캡처: '+$folder)
}catch{
 foreach($name in $names){Copy-Item (Join-Path $folder $name) (Join-Path $skin ('@Resources\'+$name)) -Force}
 Start-Process $runtime.rainmeter -ArgumentList '!Refresh "GUNT-System-Monitor"'|Out-Null
 throw
}
