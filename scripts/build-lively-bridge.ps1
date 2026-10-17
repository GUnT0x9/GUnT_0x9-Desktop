. "$PSScriptRoot\common.ps1"
$lively=Join-Path $env:LOCALAPPDATA 'Programs\Lively Wallpaper'
$runtime=Get-ChildItem "$env:ProgramFiles\dotnet\shared\Microsoft.NETCore.App" -Directory|Where-Object {$_.Name -match '^10\.'}|Sort-Object {[version]$_.Name} -Descending|Select-Object -First 1
if(!$runtime){throw '설치된 .NET 10 런타임을 찾지 못했습니다. 새 런타임을 자동 설치하지 않았습니다.'}
$csc=Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
$out=Join-Path $Root 'bin\Gunt.LivelyBridge.dll'
$rsp=Join-Path $Root 'state\lively-bridge-build.rsp'
$lines=@('/nologo','/utf8output','/nostdlib+','/target:exe','/platform:anycpu',('/out:"'+$out+'"'))
$lines+=@(Get-ChildItem $runtime.FullName -Filter '*.dll'|Where-Object {try{$null=[Reflection.AssemblyName]::GetAssemblyName($_.FullName);$true}catch{$false}}|ForEach-Object {'/reference:"'+$_.FullName+'"'})
$lines+=@('GrpcDotNetNamedPipes.dll','Grpc.Core.Api.dll','Google.Protobuf.dll','Lively.Grpc.Common.dll'|ForEach-Object {'/reference:"'+(Join-Path $lively $_)+'"'})
$lines+='"'+(Join-Path $Root 'src\LivelyBridge.cs')+'"'
[IO.File]::WriteAllText($rsp,($lines -join "`r`n"),[Text.Encoding]::UTF8)
$output=& $csc /noconfig ('@'+$rsp) 2>&1
$output|Out-File (Join-Path $Root 'logs\lively-bridge-build.log') -Encoding UTF8
if($LASTEXITCODE -ne 0){throw ('Lively 연동 빌드 실패: '+($output -join "`n"))}
Write-Json @{runtimeOptions=@{tfm='net10.0';framework=@{name='Microsoft.NETCore.App';version=$runtime.Name}}} (Join-Path $Root 'bin\Gunt.LivelyBridge.runtimeconfig.json')
Write-Log 'lively-bridge-build' 'passed' '기존 .NET 런타임과 Lively 공식 어셈블리를 사용했습니다. 새 SDK·엔진 설치는 없습니다.'
