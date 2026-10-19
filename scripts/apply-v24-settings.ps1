param([Parameter(Mandatory=$true)][string]$Components)
. "$PSScriptRoot\common.ps1"
Add-Type -Path (Join-Path $Root 'bin\Gunt.Configuration.dll')
$names=@($Components.Split(','));foreach($n in $names){if($n -notin 'theme','topbar','monitor','sensors','startup','dock','ux'){throw ('지원하지 않는 설정 적용: '+$n)};[GuntConfiguration]::Validate($n,[GuntConfiguration]::Read($Root,$n))}
if(@($names|Where-Object {$_ -in 'theme','topbar','monitor'}).Count){
 & "$PSScriptRoot\update-monitor.ps1"
 $config=[GuntConfiguration]::Read($Root,'monitor');$r=Get-Content (Join-Path $Root 'config\runtime.json') -Raw -Encoding UTF8|ConvertFrom-Json
 $vars=[IO.File]::ReadAllText($r.variables)
 if($vars -notmatch ('(?m)^HideCPUGraph='+[int](![bool]$config['showCpuGraph'] -or [bool]$config['compact'] -or ![bool]$config['showCpu'])+'\r?$')){throw 'CPU 그래프 설정 내보내기 검증 실패'}
 $h=[GuntLayout]::MonitorWindow();if($h -eq [IntPtr]::Zero){throw 'Rainmeter 모니터 창을 확인하지 못했습니다.'}
}
if(@($names|Where-Object {$_ -in 'theme','topbar','ux'}).Count){
 if(!('GuntApplyBar24' -as [type])){Add-Type @'
using System;using System.Runtime.InteropServices;public static class GuntApplyBar24{[DllImport("user32.dll",CharSet=CharSet.Unicode)]static extern IntPtr FindWindow(string c,string t);[DllImport("user32.dll")]static extern bool PostMessage(IntPtr h,uint m,IntPtr w,IntPtr l);public static bool Reload(){var h=FindWindow(null,"GUNT Desktop \u2014 Midnight Purple");return h!=IntPtr.Zero&&PostMessage(h,0x8002,IntPtr.Zero,IntPtr.Zero);}}
'@}
 if(![GuntApplyBar24]::Reload()){throw '상단 바 새로고침 요청을 전달하지 못했습니다.'}
}
if($names -contains 'dock'){
 & "$PSScriptRoot\install-dock.ps1"
 $d=[GuntConfiguration]::Read($Root,'dock');$ini=[IO.File]::ReadAllText((Join-Path $Root 'apps\Windhawk\AppData\Engine\Mods\taskbar-icon-size.ini'))
 foreach($pair in @(@('TaskbarHeight',([int]$d.height+[int]$d.bottomMargin)),@('IconSize',$d.iconSize),@('TaskbarButtonWidth',$d.hitArea))){if($ini -notmatch ('(?m)^'+$pair[0]+'='+$pair[1]+'\r?$')){throw ('Dock 내보내기 불일치: '+$pair[0])}}
}
if($names -contains 'startup'){& "$PSScriptRoot\register-startup-v24.ps1"}
Write-Log 'settings-v24' 'passed' ('설정 내보내기 및 구성 요소 확인: '+$Components)
