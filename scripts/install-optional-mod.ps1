param([Parameter(Mandatory=$true)][string]$Id,[switch]$Enable)
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
foreach($id in @($Id)){
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

$settingsPath=Join-Path $Root ('windhawk\'+$Id+'.settings.json')
$settings=Get-Content $settingsPath -Raw -Encoding UTF8|ConvertFrom-Json
$data=Join-Path $wh 'AppData'
$dest=Join-Path $data 'Engine\Mods'
foreach($mod in $mods){
 $to=Join-Path $dest ('64\'+$mod.library)
 if(!(Test-Path $to)){Copy-Item $mod.dll $to}
 Copy-Item $mod.source (Join-Path $data ('ModsSource\'+$mod.id+'.wh.cpp')) -Force
 $code=Get-Content $mod.source -Raw -Encoding UTF8
 $includes=@([regex]::Matches($code,'(?m)^// @include\s+(\S+)')|ForEach-Object {$_.Groups[1].Value})
 $deployment=Join-Path $Root ('windhawk\'+$mod.id+'.deployment.json')
 if(Test-Path $deployment){
  $targets=@((Get-Content $deployment -Raw -Encoding UTF8|ConvertFrom-Json).include)
  if(!$targets.Count){throw '모드 프로세스 제한이 비어 있습니다.'}
  foreach($target in $targets){if($target -notmatch '^[A-Za-z0-9_.-]+\.exe$' -or ($includes -notcontains '*' -and $includes -notcontains $target)){throw ('공식 소스 범위 밖의 모드 프로세스입니다: '+$target)}}
  $includes=$targets
 }
 $lines=@('[Mod]',('LibraryFileName='+$mod.library),('Disabled='+[int](!$Enable)),'LoggingEnabled=0','DebugLoggingEnabled=0',('Include='+($includes -join '|')),('IncludeCustom='+($includes -join '|')),'IncludeExcludeCustomOnly=1','Architecture=x86-64',('Version='+$mod.version),('SettingsChangeTime='+[DateTimeOffset]::UtcNow.ToUnixTimeSeconds()),'','[Settings]')
 $lines+=@($settings.PSObject.Properties|ForEach-Object {$_.Name+'='+[string]$_.Value})
 $ini=Join-Path $dest ($Id+'.ini');$temp=$ini+'.'+[guid]::NewGuid().ToString('N')+'.tmp'
 $backup=Join-Path $Root ('backups\mod-install-'+(Get-Date -Format 'yyyyMMdd-HHmmss-fff')+'\'+$Id+'.ini');New-Item -ItemType Directory -Force (Split-Path $backup -Parent)|Out-Null
 [IO.File]::WriteAllText($temp,($lines -join "`r`n")+"`r`n",[Text.Encoding]::Unicode)
 if(Test-Path $ini){[IO.File]::Replace($temp,$ini,$backup)}else{Move-Item $temp $ini}
 Write-Log 'optional-mod' 'configured' ($Id+' 구성 완료, 활성화='+[bool]$Enable)
}

& "$PSScriptRoot\export-windhawk-state.ps1"
