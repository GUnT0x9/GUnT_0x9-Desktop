param([switch]$Candidate)
. "$PSScriptRoot\common.ps1"
$source=Join-Path $Root 'src\GuntBar.cs';$out=Join-Path $Root 'bin\GUNT-Bar.exe'
$developerSource=Join-Path $Root 'src\GuntDeveloperIntegration.cs'
$sensorSource=Join-Path $Root 'src\Sensors.cs'
$additional=Join-Path $Root 'src\AdditionalTelemetry.cs'
$hwinfoSource=Join-Path $Root 'src\HwinfoTelemetry.cs'
$configuration=Join-Path $Root 'bin\Gunt.Configuration.dll'
$launchpadSource=Join-Path $Root 'src\LaunchpadHotkey.cs'
$signature=((Get-FileHash $launchpadSource).Hash+(Get-FileHash $developerSource).Hash+(Get-FileHash $source).Hash+(Get-FileHash $sensorSource).Hash+(Get-FileHash $configuration).Hash+(Get-FileHash $additional).Hash+(Get-FileHash $hwinfoSource).Hash+(Get-FileHash (Join-Path $Root 'assets\branding\icons\gunt-app.ico')).Hash);$record=Join-Path $Root 'state\bar-build.sha256'
if(!$Candidate -and (Test-Path $out) -and (Test-Path $record) -and ((Get-Content $record -Raw).Trim() -eq $signature)){Write-Log 'build' 'existing' '상단 바 빌드가 최신입니다.';return}
$temp=Join-Path $Root ('bin\GUNT-Bar.build-'+[guid]::NewGuid().ToString('N')+'.exe')
$buildDir=Join-Path $Root ('bin\build-'+[guid]::NewGuid().ToString('N'));New-Item -ItemType Directory -Force $buildDir|Out-Null
$sensorTemp=Join-Path $buildDir 'Gunt.Sensors.dll'
Add-Type -Path @($sensorSource,$additional,$hwinfoSource) -ReferencedAssemblies System.Core,System.Web.Extensions -OutputAssembly $sensorTemp -OutputType Library
$csc=Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
& $csc /nologo /target:winexe /optimize+ ('/win32icon:'+(Join-Path $Root 'assets\branding\icons\gunt-app.ico')) ('/out:'+$temp) /reference:System.Windows.Forms.dll /reference:System.Drawing.dll /reference:System.Web.Extensions.dll /reference:System.Core.dll /reference:Accessibility.dll ('/reference:'+$sensorTemp) ('/reference:'+$configuration) $source $developerSource $launchpadSource
if($LASTEXITCODE -ne 0 -or !(Test-Path $temp)){throw '공식 아이콘을 포함한 상단 바 빌드 실패. 기존 실행 파일은 유지했습니다.'}
if($Candidate){Copy-Item $temp (Join-Path $buildDir 'GUNT-Bar.exe');Copy-Item $configuration $buildDir;Write-Output (Join-Path $buildDir 'GUNT-Bar.exe');return}
if(!('GuntBuildNative' -as [type])){Add-Type @'
using System;using System.Runtime.InteropServices;
public static class GuntBuildNative {
 [DllImport("user32.dll",CharSet=CharSet.Unicode)] public static extern IntPtr FindWindow(string c,string t);
 [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h,uint m,IntPtr w,IntPtr l);
 public static IntPtr FindBar(){return FindWindow(null,"GUNT Desktop \u2014 Midnight Purple");}
}
'@}
$running=@(Get-Process 'GUNT-Bar' -ErrorAction SilentlyContinue|Where-Object {$_.Path -eq $out})
if($running.Count){
 $handle=[GuntBuildNative]::FindBar()
 if($handle -ne [IntPtr]::Zero){[GuntBuildNative]::PostMessage($handle,0x10,[IntPtr]::Zero,[IntPtr]::Zero)|Out-Null}
 foreach($process in $running){
  if(!$process.WaitForExit(5000)){
   # This helper has no unsaved documents. Restrict the fallback to its exact
   # project-owned executable; Explorer and work applications are untouched.
   if($process.Path -ne $out){throw '상단 바 실행 경로가 일치하지 않아 교체를 중단했습니다.'}
   Stop-Process -Id $process.Id -Force
   if(!$process.WaitForExit(2000)){throw '기존 상단 바 프로세스가 종료되지 않았습니다.'}
   Write-Log 'bar-replace' 'recovered' '종료 메시지에 응답하지 않은 기존 GUNT 상단 바만 종료했습니다.'
  }
 }
}
if(Test-Path $out){Move-Item $out "$out.previous" -Force}
$sensorOut=Join-Path $Root 'bin\Gunt.Sensors.dll'
if(Test-Path $sensorOut){Move-Item $sensorOut "$sensorOut.previous" -Force}
Move-Item $sensorTemp $sensorOut
Move-Item $temp $out
[IO.File]::WriteAllText($record,$signature,$Utf8)
Write-Log 'build' 'passed' '기존 상단 바를 정상 종료하고 v2.4 한국어 메뉴 바를 빌드했습니다.'
