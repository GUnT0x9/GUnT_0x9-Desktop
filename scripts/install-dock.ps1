. "$PSScriptRoot\common.ps1"
$wh=Join-Path $Root 'apps\Windhawk'
$compiler=Join-Path $wh 'Compiler'
$engine=Join-Path $wh 'Engine\1.7.3\64\windhawk.lib'
$outDir=Join-Path $Root 'bin\mods'
New-Item -ItemType Directory -Force $outDir|Out-Null
function Quote-Native([string]$value) {
    if($value -notmatch '[\s"]'){return $value}
    '"'+[regex]::Replace([regex]::Replace($value,'(\\*)"','$1$1\"'),'(\\+)$','$1$1')+'"'
}
$mods=@()
foreach($id in 'windows-11-taskbar-styler','taskbar-icon-size'){
    $source=Join-Path $Root ('windhawk\'+$id+'.wh.cpp')
    $provenance=Get-Content (Join-Path $Root ('windhawk\'+$id+'.source.json')) -Raw -Encoding UTF8|ConvertFrom-Json
    if((Get-FileHash $source -Algorithm SHA256).Hash -ne $provenance.sha256){throw "공식 소스 해시가 일치하지 않습니다: $id"}
    $code=Get-Content $source -Raw -Encoding UTF8
    $version=[regex]::Match($code,'(?m)^// @version\s+(\S+)').Groups[1].Value
    $options=[regex]::Match($code,'(?m)^// @compilerOptions\s+(.+)').Groups[1].Value.Trim() -split '\s+'
    $name=$id+'_'+$version+'_'+$provenance.sha256.Substring(0,10)+'.dll'
    $dll=Join-Path $outDir $name
    if(!(Test-Path $dll)){
        $arguments=@('-std=c++23','-O2','-shared','-DUNICODE','-D_UNICODE','-DWINVER=0x0A00','-D_WIN32_WINNT=0x0A00','-D_WIN32_IE=0x0A00','-DNTDDI_VERSION=0x0A000008','-D__USE_MINGW_ANSI_STDIO=0','-DWH_MOD',('-DWH_MOD_ID=L"'+$id+'"'),('-DWH_MOD_VERSION=L"'+$version+'"'),$engine,'-x','c++',$source,'-include','windhawk_api.h','-target','x86_64-w64-mingw32','-Wl,--export-all-symbols','-o',$dll)+@($options|Where-Object {$_})
        $info=New-Object Diagnostics.ProcessStartInfo
        $info.FileName=Join-Path $compiler 'bin\clang++.exe'
        $info.Arguments=($arguments|ForEach-Object {Quote-Native $_}) -join ' '
        $info.WorkingDirectory=$compiler;$info.UseShellExecute=$false;$info.CreateNoWindow=$true
        $info.RedirectStandardOutput=$true;$info.RedirectStandardError=$true
        Write-Log 'dock-build' 'started' "$id $version; 공식 소스 커밋 $($provenance.commit)"
        $process=[Diagnostics.Process]::Start($info)
        $stdout=$process.StandardOutput.ReadToEndAsync();$stderr=$process.StandardError.ReadToEndAsync()
        if(!$process.WaitForExit(240000)){$process.Kill();throw "컴파일 제한 시간을 초과했습니다: $id"}
        [IO.File]::WriteAllText((Join-Path $Root ('logs\compile-'+$id+'.log')),($stdout.Result+$stderr.Result),$Utf8)
        if($process.ExitCode -ne 0){throw "컴파일 실패: $id. See logs\compile-$id.log"}
        Write-Log 'dock-build' 'passed' "$name; SHA256=$((Get-FileHash $dll).Hash)"
    }
    $mods+=@{id=$id;version=$version;source=$source;dll=$dll;library=$name;provenance=$provenance}
}
$data=Join-Path $wh 'AppData'
$dest=Join-Path $data 'Engine\Mods'
Mark-Target $dest
Mark-Target (Join-Path $data 'ModsSource')
New-Item -ItemType Directory -Force (Join-Path $dest '64'),(Join-Path $data 'ModsSource')|Out-Null
foreach($pair in @(@('libc++.dll','libc++.whl'),@('libunwind.dll','libunwind.whl'),@('windhawk-mod-shim.dll','windhawk-mod-shim.dll'))){
    $from=Join-Path $compiler ('x86_64-w64-mingw32\bin\'+$pair[0]);$to=Join-Path $dest ('64\'+$pair[1])
    if(!(Test-Path $to) -or (Get-FileHash $from).Hash -ne (Get-FileHash $to).Hash){Copy-Item $from $to -Force}
}
$taskbar=Get-Content (Join-Path $Root 'config\dock-styles.json') -Raw -Encoding UTF8|ConvertFrom-Json
$t=Read-Theme
$dock=Get-Content (Join-Path $Root 'config\dock.json') -Raw -Encoding UTF8|ConvertFrom-Json
$layout=Get-Content (Join-Path $Root 'config\layout.json') -Raw -Encoding UTF8|ConvertFrom-Json
# Derive the available application region from the actual native tray.
if(!('GuntDockGeometry' -as [type])){Add-Type @'
using System;using System.Runtime.InteropServices;
public static class GuntDockGeometry {
 [StructLayout(LayoutKind.Sequential)]public struct RECT{public int left,top,right,bottom;}
 [DllImport("user32.dll",CharSet=CharSet.Unicode)]static extern IntPtr FindWindow(string c,string t);
 [DllImport("user32.dll",CharSet=CharSet.Unicode)]static extern IntPtr FindWindowEx(IntPtr p,IntPtr a,string c,string t);
 [DllImport("user32.dll")]static extern bool GetWindowRect(IntPtr h,out RECT r);
 [DllImport("user32.dll")]public static extern bool SetProcessDpiAwarenessContext(IntPtr c);
 public static IntPtr ShellHandle(){return FindWindow("Shell_TrayWnd",null);}
 public static int TrayWidth(){RECT r;var h=FindWindowEx(FindWindow("Shell_TrayWnd",null),IntPtr.Zero,"TrayNotifyWnd",null);return h!=IntPtr.Zero&&GetWindowRect(h,out r)?r.right-r.left:0;}
}
'@}
[GuntDockGeometry]::SetProcessDpiAwarenessContext([IntPtr](-4))|Out-Null
$screenDip=$layout.PrimaryWidth/$layout.Scale
$trayDip=[math]::Ceiling([GuntDockGeometry]::TrayWidth()/$layout.Scale)
if($trayDip -le 0){$trayDip=420}
$left=0
$maxWidth=[math]::Min($screenDip*$dock.maxWidthRatio,$screenDip-$trayDip-$dock.controlGap-32)
$right=0
try{
 Add-Type -AssemblyName UIAutomationClient,UIAutomationTypes
 $element=[Windows.Automation.AutomationElement]::FromHandle([GuntDockGeometry]::ShellHandle())
 $condition=New-Object Windows.Automation.PropertyCondition([Windows.Automation.AutomationElement]::AutomationIdProperty,'TaskbarFrame')
 $frame=$element.FindFirst([Windows.Automation.TreeScope]::Descendants,$condition)
 $trayCondition=New-Object Windows.Automation.PropertyCondition([Windows.Automation.AutomationElement]::ClassNameProperty,'TrayNotifyWnd')
 $tray=$element.FindFirst([Windows.Automation.TreeScope]::Descendants,$trayCondition)
 if($frame -and $tray){
  $contentDip=$frame.Current.BoundingRectangle.Width/$layout.Scale
  $controlLeft=$tray.Current.BoundingRectangle.X/$layout.Scale
  # Keep a natural centered Dock, shifting only enough to clear the control Dock.
  $right=[math]::Max(0,[math]::Ceiling($screenDip+$contentDip-2*$controlLeft+2*$dock.controlGap))
 }
}catch{Write-Log 'dock-width' 'fallback' '기본 중앙 배치와 Windows 자체 트레이 예약을 사용합니다.'}
Write-Json @{Time=(Get-Date).ToString('o');ScreenDIP=$screenDip;TrayDIP=$trayDip;LeftDIP=$left;RightDIP=$right;MaximumAppDIP=$maxWidth;Note='자연 콘텐츠 폭·중앙 기준 배치, 컨트롤 Dock 앞까지 필요한 만큼 왼쪽 이동. 고정 앱·실행 앱 순서는 Windows가 관리합니다.'} (Join-Path $Root 'config\dock-layout.json')
foreach($style in $taskbar){
 $style.styles=@($style.styles|ForEach-Object {
  $v=[string]$_
  if($style.target -eq 'Taskbar.TaskbarFrame' -and $v -match '^Margin='){$v='Margin='+$left+',0,'+$right+',0'}
  if($style.target -eq 'Taskbar.TaskbarFrame' -and $v -match '^HorizontalAlignment='){$v='HorizontalAlignment=Center'}
  if($v -match '^CornerRadius='){$v='CornerRadius='+$dock.radius}
  if($style.target -like '*RootGrid' -and $v -match '^Margin='){$v='Margin=0,0,0,'+$dock.bottomMargin}
  if($style.target -like '*RootGrid' -and $v -match '^Padding='){$v='Padding='+$dock.padding+',0,'+$dock.padding+',0'}
  if($style.target -like '*SystemTrayFrameGrid*' -and $v -match '^Margin='){$v='Margin=8,0,8,'+$dock.bottomMargin}
  $v=$v.Replace('#FF0E0E12','#FF'+$t.palette.panel.TrimStart('#')).Replace('#FF23232B','#FF'+$t.palette.border.TrimStart('#')).Replace('#FFA78BFA','#FF'+$t.palette.accent.TrimStart('#'))
  $v
 })
}
foreach($mod in $mods){
    $to=Join-Path $dest ('64\'+$mod.library)
    if(!(Test-Path $to) -or (Get-FileHash $mod.dll).Hash -ne (Get-FileHash $to).Hash){Copy-Item $mod.dll $to -Force}
    Copy-Item $mod.source (Join-Path $data ('ModsSource\'+$mod.id+'.wh.cpp')) -Force
    $settings=[ordered]@{}
    if($mod.id -eq 'windows-11-taskbar-styler'){
        $settings.theme='DockLike';$settings.clickThroughTaskbar=0;$settings.xamlDiagnosticsHandling='allow'
        $i=0
        foreach($style in $taskbar){
            $settings[('controlStyles['+$i+'].target')]=$style.target
            $j=0;foreach($value in $style.styles){$settings[('controlStyles['+$i+'].styles['+$j+']')]=[string]$value;$j++};$i++
        }
    }else{
        $settings.TaskbarHeight=($dock.height+$dock.bottomMargin);$settings.IconSize=$dock.iconSize;$settings.TaskbarButtonWidth=$dock.hitArea;$settings.IconSizeSmall=$dock.iconSize;$settings.TaskbarButtonWidthSmall=$dock.hitArea
    }
    $lines=@('[Mod]',('LibraryFileName='+$mod.library),'Disabled=0','LoggingEnabled=0','DebugLoggingEnabled=0','Include=explorer.exe','Exclude=','IncludeCustom=explorer.exe','ExcludeCustom=','IncludeExcludeCustomOnly=1','Architecture=x86-64',('Version='+$mod.version),('SettingsChangeTime='+[DateTimeOffset]::UtcNow.ToUnixTimeSeconds()),'','[Settings]')
    $lines+=@($settings.GetEnumerator()|ForEach-Object {$_.Key+'='+$_.Value})
    $ini=Join-Path $dest ($mod.id+'.ini');$temp=$ini+'.'+[guid]::NewGuid().ToString('N')+'.tmp'
    [IO.File]::WriteAllText($temp,($lines -join "`r`n")+"`r`n",[Text.Encoding]::Unicode)
    if(Test-Path $ini){$backup=Join-Path $Root ('backups\dock-ini-'+(Get-Date -Format 'yyyyMMdd-HHmmss')+'\'+$mod.id+'.ini');New-Item -ItemType Directory -Force (Split-Path $backup -Parent)|Out-Null;[IO.File]::Replace($temp,$ini,$backup)}else{Move-Item $temp $ini}
    Start-Sleep -Milliseconds 1500
}
$runtime=Get-Content (Join-Path $Root 'config\runtime.json') -Raw -Encoding UTF8|ConvertFrom-Json
$runtime|Add-Member -NotePropertyName windhawk -NotePropertyValue (Join-Path $wh 'windhawk.exe') -Force
$runtime.dock='Windhawk DockLike / Midnight Purple'
Write-Json $runtime (Join-Path $Root 'config\runtime.json')
Write-Json $mods (Join-Path $Root 'logs\dock-mods.json')
if(!(Get-Process windhawk -ErrorAction SilentlyContinue)){Start-Process $runtime.windhawk -ArgumentList '-tray-only' -WorkingDirectory $wh|Out-Null}
Write-Log 'dock' 'started' '포터블 Windhawk 설정을 반영했습니다. 실제 모드 로드와 작업 표시줄 상태는 별도로 검증합니다.'
