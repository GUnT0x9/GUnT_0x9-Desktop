param([switch]$Candidate)
. "$PSScriptRoot\common.ps1"
$csc=Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
$framework=Split-Path $csc -Parent;$wpf=Join-Path $framework 'WPF'
if(!(Test-Path $csc)){throw '.NET Framework C# 컴파일러가 없습니다.'}
if(!$Candidate -and (Get-Process GUNT.ControlCenter -ErrorAction SilentlyContinue)){throw '열려 있는 제어 센터를 닫은 뒤 빌드하세요.'}
$build=Join-Path $Root ('bin\control-center-'+[guid]::NewGuid().ToString('N'));New-Item -ItemType Directory -Force $build|Out-Null
$out=Join-Path $build 'GUNT.ControlCenter.exe'
$args=@(('/win32icon:'+(Join-Path $Root 'assets\branding\icons\gunt-app.ico')),'/nologo','/target:winexe','/optimize+','/platform:anycpu',('/out:'+$out),('/win32manifest:'+(Join-Path $Root 'control-center\app.manifest')))
foreach($ref in 'System.dll','System.Core.dll','System.Drawing.dll','System.Windows.Forms.dll','System.Web.Extensions.dll','System.Xaml.dll'){$args+=('/reference:'+(Join-Path $framework $ref))}
foreach($ref in 'PresentationFramework.dll','PresentationCore.dll','WindowsBase.dll'){$args+=('/reference:'+(Join-Path $wpf $ref))}
$args+=('/reference:'+(Join-Path $Root 'bin\Gunt.Configuration.dll'))
$args+=('/reference:'+(Join-Path $Root 'bin\Gunt.Sensors.dll'))
$args+=(Join-Path $Root 'src\LaunchpadHotkey.cs')
$args+=@(Get-ChildItem (Join-Path $Root 'control-center\src') -Filter '*.cs' -Recurse|Select-Object -ExpandProperty FullName)
& $csc @args
if($LASTEXITCODE -ne 0 -or !(Test-Path $out)){throw '제어 센터 빌드 실패. 기존 실행 파일은 보존했습니다.'}
if($Candidate){Copy-Item (Join-Path $Root 'bin\Gunt.Configuration.dll'),(Join-Path $Root 'bin\Gunt.Sensors.dll') $build;Write-Output $out;return}
$target=Join-Path $Root 'bin\GUNT.ControlCenter.exe';if(Test-Path $target){Copy-Item $target ($target+'.previous') -Force};Copy-Item $out $target -Force
Write-Log 'control-center-build' 'passed' 'WPF 제어 센터를 빌드했습니다.'
