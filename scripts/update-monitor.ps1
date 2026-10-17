param([switch]$DeferRefresh)
. "$PSScriptRoot\common.ps1"
Add-Type -AssemblyName System.Windows.Forms,System.Drawing
Add-Type -Path (Join-Path $Root 'bin\Gunt.Configuration.dll')
if(!('GuntLayoutNative' -as [type])){Add-Type @'
using System;using System.Drawing;using System.Runtime.InteropServices;
public static class GuntLayoutNative {
 [DllImport("user32.dll")] public static extern bool SetProcessDpiAwarenessContext(IntPtr c);
 [DllImport("user32.dll")] public static extern IntPtr MonitorFromPoint(Point p,uint f);
 [DllImport("shcore.dll")] public static extern int GetDpiForMonitor(IntPtr m,int t,out uint x,out uint y);
}
'@ -ReferencedAssemblies System.Drawing}
[GuntLayoutNative]::SetProcessDpiAwarenessContext([IntPtr](-4))|Out-Null
$monitor=Get-Content (Join-Path $Root 'config\monitor.json') -Raw -Encoding UTF8|ConvertFrom-Json
$bar=Get-Content (Join-Path $Root 'config\topbar.json') -Raw -Encoding UTF8|ConvertFrom-Json
$dock=Get-Content (Join-Path $Root 'config\dock.json') -Raw -Encoding UTF8|ConvertFrom-Json
$t=Read-Theme
foreach($key in 'width','margin','topGap','updateMs','radius'){$t.monitor.$key=$monitor.$key}
$t.bar.height=$bar.height;$t.dock.height=$dock.height;$t.dock.iconSize=$dock.iconSize
Write-Json $t (Join-Path $Root 'config\theme.json')
$screen=[Windows.Forms.Screen]::PrimaryScreen
$placement=[GuntLayout]::Resolve($Root,0);$scale=[double]$placement['scale']
$r=Get-Content (Join-Path $Root 'config\runtime.json') -Raw -Encoding UTF8|ConvertFrom-Json
$skin=[IO.Path]::GetFullPath($r.skin)
$source=Join-Path $Root 'rainmeter\GUNT-System-Monitor'
foreach($file in Get-ChildItem $source -File -Recurse){
 $to=Join-Path $skin $file.FullName.Substring($source.Length+1)
 New-Item -ItemType Directory -Force (Split-Path $to -Parent)|Out-Null
 # Rainmeter 4.5 recognizes Unicode Lua only with a UTF-16 LE BOM.
 if($file.Extension -in '.ini','.inc','.lua'){[IO.File]::WriteAllText($to,[IO.File]::ReadAllText($file.FullName),[Text.Encoding]::Unicode)}else{Copy-Item $file.FullName $to -Force}
}
$vars=[ordered]@{VisibilityAction=$(if($monitor.PSObject.Properties.Name -contains 'visible' -and !$monitor.visible){'!Hide'}else{'!Show'});PanelRadius=$monitor.radius;Scale=$scale.ToString([Globalization.CultureInfo]::InvariantCulture);PanelWidth=$monitor.width;UpdateMs=[math]::Max(1000,$monitor.updateMs);UIFont=$t.fonts.ui;SecondaryFont=$t.fonts.secondary;HeadingFont=$t.fonts.heading;LatinFont=$t.fonts.latin;MetricFont=$t.fonts.metrics;SystemDrive=$env:SystemDrive;NetInterface='Best';ConfigPath=Join-Path $Root 'config\monitor.json';ToggleScript=Join-Path $Root 'scripts\toggle-monitor.ps1';ToggleLabel=$(if($monitor.compact){'자세히'}else{'간단히'});WidgetX=[int]($screen.Bounds.Right-($monitor.width+$monitor.margin)*$scale);WidgetY=[int]($screen.Bounds.Top+[math]::Round($bar.height*$scale)+[math]::Round($monitor.topGap*$scale))}
$fonts=New-Object Drawing.Text.InstalledFontCollection
if($fonts.Families.Name -contains $t.fonts.metrics){$vars.MetricFont=$t.fonts.metrics}
$map=@{panel='Panel';border='Border';text='Text';muted='Muted';accent='Accent';special='Special';surface='Surface'}
foreach($key in $map.Keys){$c=[Drawing.ColorTranslator]::FromHtml($t.palette.$key);$vars[$map[$key]]="$($c.R),$($c.G),$($c.B)"}
$compact=[bool]$monitor.compact
$vars.ProjectRoot=$Root;$vars.ControlCenter=Join-Path $Root 'bin\GUNT.ControlCenter.exe'
$vars.MeasureAction=$(if($monitor.visible){'!EnableMeasureGroup'}else{'!DisableMeasureGroup'})
$vars.HistorySeconds=[int]$monitor.graphHistorySeconds;$vars.NetworkScaleMode=$monitor.networkScaleMode;$vars.NetworkFixedMax=$monitor.networkFixedMaxBytesPerSecond
$vars.HideDetail=[int]$compact
$topologyPath=Join-Path $Root 'state\storage-topology.json'
if(!(Test-Path $topologyPath)){& "$PSScriptRoot\inspect-storage-topology.ps1"|Out-Null}
$vars.PhysicalDiskLabel='물리 저장장치 정보 확인 필요'
if(Test-Path $topologyPath){
 $topology=Get-Content $topologyPath -Raw -Encoding UTF8|ConvertFrom-Json
 $selected=@($topology.Volumes|Where-Object {@($monitor.storageVolumes) -contains $_.DriveLetter})
 $groups=@($selected|Group-Object DiskUniqueId)
 if($groups.Count -eq 1 -and $selected.Count){$disk=$selected[0];$vars.PhysicalDiskLabel=$disk.BusType+' '+$disk.DiskNumber+' · '+(($selected.DriveLetter) -join ' / ')+$(if($selected.Count -gt 1){' 공유 장치'}else{''})}
 elseif($groups.Count -gt 1){$vars.PhysicalDiskLabel='물리 장치 '+$groups.Count+'개 · 볼륨별 장치 매핑은 진단 참조'}
}
$sensorPath=Join-Path $Root 'state\sensors.json';$sensors=$null
if(Test-Path $sensorPath){try{$sensors=Get-Content $sensorPath -Raw -Encoding UTF8|ConvertFrom-Json}catch{}}
$hasGpu=$null -ne $sensors -and @($sensors.Gpus).Count -gt 0
$cpuGraphHeight=64;$networkGraphHeight=56
for($pass=0;$pass -lt 2;$pass++){
$y=52
foreach($name in 'CPU','RAM','GPU','Disk','Network','Battery','Uptime'){
 $key=@{CPU='showCpu';RAM='showRam';GPU='showGpu';Disk='showDisk';Network='showNetwork';Battery='showBattery';Uptime='showUptime'}[$name]
 $visible=[bool]$monitor.$key
 if($name -eq 'GPU' -and !$hasGpu){$visible=$false}
 if($compact -and $name -in 'Disk','Uptime'){$visible=$false}
 $vars[($name+'Y')]=$y;$vars[('Hide'+$name)]=[int](!$visible)
 $vars[('Hide'+$name+'Detail')]=[int](!$visible -or $compact)
 switch($name){
 'CPU' {
  $graph=$visible -and !$compact -and [bool]$monitor.showCpuGraph;$vars.HideCPUGraph=[int](!$graph)
  $vars.CPUGraphY=$y+94;$vars.CPUStatsY=if($graph){$y+94+$cpuGraphHeight+22}else{$y+76}
  $height=if($compact){44}elseif($graph){206+$cpuGraphHeight-64}else{102}
 }
 'RAM' {$height=if($compact){44}else{86}}
 'GPU' {$height=if($compact){44}else{90}}
 'Disk' {
  $dy=$y+30
  foreach($drive in 'C','D'){
   $volume=@($sensors.Volumes|Where-Object {$_.DriveLetter -eq ($drive+':')})
   $show=$visible -and @($monitor.storageVolumes) -contains ($drive+':') -and $volume.Count -gt 0
   $vars[('HideStorage'+$drive)]=[int](!$show);$vars[('Storage'+$drive+'Y')]=$dy
   if($show){$dy+=62}
  }
  $vars.DiskInfoY=$dy;$height=$dy-$y+26
 }
 'Network' {
  $graph=$visible -and !$compact -and [bool]$monitor.showNetworkGraph;$vars.HideNetworkGraph=[int](!$graph)
  $vars.NetworkGraphY=$y+95;$vars.NetworkTotalY=if($graph){$y+95+$networkGraphHeight+23}else{$y+77}
  $height=if($compact){62}elseif($graph){198+$networkGraphHeight-56}else{100}
 }
 'Battery' {$height=32}
 'Uptime' {$height=28}
 }
 $vars[($name+'End')]=$y+$height-10
 if($visible){$y+=$height}
}
$vars.SensorStatusY=$y;$vars.HideSensorStatus=[int]$compact
if(!$compact){$y+=20}
$vars.PanelHeight=$y+8
if($pass -eq 0 -and !$compact){
 $need=[math]::Max(0,[math]::Ceiling($vars.PanelHeight-([double]$placement['workHeight']-16)/$scale))
 if($need -gt 0){
  if($vars.HideCPUGraph -eq 0){$take=[math]::Min(16,$need);$cpuGraphHeight-=$take;$need-=$take}
  if($need -gt 0 -and $vars.HideNetworkGraph -eq 0){$take=[math]::Min(16,$need);$networkGraphHeight-=$take}
 }
}
}
$vars.CpuGraphHeight=$cpuGraphHeight;$vars.NetworkGraphHeight=$networkGraphHeight
# Hidden meters still contribute their coordinates to Rainmeter's window bounds.
# Move only hidden sections to the origin so compact mode reclaims all space.
$layoutFile=Join-Path $skin '@Resources\Layout.inc'
$layoutText=[IO.File]::ReadAllText($layoutFile)
$layoutText=[regex]::Replace($layoutText,'(?ms)^\[[^\r\n]+\]\r?\n.*?(?=^\[|\z)',[Text.RegularExpressions.MatchEvaluator]{param($section)
 $body=$section.Value;$hidden=[regex]::Match($body,'(?m)^Hidden=#(Hide\w+)#\r?$')
 if($hidden.Success -and $vars[$hidden.Groups[1].Value] -eq 1){$body=[regex]::Replace($body,'(?m)^Y=.*$','Y=0')}
 return $body
})
[IO.File]::WriteAllText($layoutFile,$layoutText,[Text.Encoding]::Unicode)

$vars.Draggable=[int](!$monitor.position.locked);$vars.DragRight=[int](116*$scale);$vars.DragBottom=[int](($vars.PanelHeight-40)*$scale)
$placement=[GuntLayout]::Resolve($Root,[int]$vars.PanelHeight);$vars.WidgetX=[int]$placement['x'];$vars.WidgetY=[int]$placement['y']
$r.skin=$skin;$r.variables=Join-Path $skin '@Resources\Variables.inc';$r.scale=[GuntLayout]::Scale($screen);$r|Add-Member -NotePropertyName widgetScale -NotePropertyValue $scale -Force;$r.widgetX=$vars.WidgetX;$r.widgetY=$vars.WidgetY
[IO.File]::WriteAllText($r.variables,"[Variables]`r`n"+(($vars.GetEnumerator()|ForEach-Object {$_.Key+'='+$_.Value}) -join "`r`n")+"`r`n",[Text.Encoding]::Unicode)
Write-Json $r (Join-Path $Root 'config\runtime.json')
$layout=[ordered]@{Time=(Get-Date).ToString('o');Primary=$screen.DeviceName;PrimaryWidth=$screen.Bounds.Width;PrimaryHeight=$screen.Bounds.Height;Scale=[GuntLayout]::Scale($screen);WidgetScale=$scale;WidgetMonitorId=$placement['monitorId'];TemporaryFallback=$placement['temporaryFallback'];WidgetX=$vars.WidgetX;WidgetY=$vars.WidgetY;WidgetWidth=[int]($monitor.width*$scale);WidgetHeight=[int]($vars.PanelHeight*$scale);BarHeight=[int][math]::Round($bar.height*[GuntLayout]::Scale($screen));Monitors=@([Windows.Forms.Screen]::AllScreens|ForEach-Object {@{Device=$_.DeviceName;Primary=$_.Primary;Bounds=$_.Bounds.ToString()}})}
Write-Json $layout (Join-Path $Root 'config\layout.json')
if(!$DeferRefresh -and (Get-Process Rainmeter -ErrorAction SilentlyContinue)){Start-Process $r.rainmeter -ArgumentList '!Refresh "GUNT-System-Monitor"' -WindowStyle Hidden|Out-Null;Start-Process $r.rainmeter -ArgumentList ('!Move '+$vars.WidgetX+' '+$vars.WidgetY+' "GUNT-System-Monitor"') -WindowStyle Hidden|Out-Null}
Write-Log 'monitor-layout' 'applied' ("위젯 배율 "+$scale+", 위젯 좌표 "+$vars.WidgetX+","+$vars.WidgetY)
