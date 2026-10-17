. "$PSScriptRoot\common.ps1"
$out=Join-Path $Root 'bin\Gunt.Configuration.dll';$source=Join-Path $Root 'src\Configuration.cs'
$hash=(Get-FileHash $source).Hash+'-stable-assembly-v2';$record=Join-Path $Root 'state\configuration-build.sha256'
if((Test-Path $out) -and (Test-Path $record) -and (Get-Content $record -Raw).Trim() -eq $hash){return}
$buildDir=Join-Path $Root ('bin\configuration-'+[guid]::NewGuid().ToString('N'));New-Item -ItemType Directory -Force $buildDir|Out-Null
$temp=Join-Path $buildDir 'Gunt.Configuration.dll'
Add-Type -Path $source -ReferencedAssemblies System.Core,System.Web.Extensions,System.Windows.Forms,System.Drawing -OutputAssembly $temp -OutputType Library
# A running GUNT component holds the current library. Never interrupt it on compile failure.
if(Test-Path $out){$revision=Join-Path $Root ('backups\configuration-build-'+[guid]::NewGuid().ToString('N')+'\Gunt.Configuration.dll');New-Item -ItemType Directory -Force (Split-Path $revision -Parent)|Out-Null;try{Move-Item $out $revision}catch{throw '구성 라이브러리를 사용하는 GUNT 창을 닫은 뒤 다시 적용하세요.'}}
Move-Item $temp $out;[IO.File]::WriteAllText($record,$hash,$Utf8)
Write-Log 'configuration-build' 'passed' '공통 설정·모니터 배치 라이브러리를 빌드했습니다.'
