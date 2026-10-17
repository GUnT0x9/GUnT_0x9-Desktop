. "$PSScriptRoot\common.ps1"
if(!(Get-State)){throw 'Run backup.ps1 first.'}
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
$headers=@{'User-Agent'='GUNT-Desktop-local-setup';'Accept'='application/vnd.github+json'}
function Get-VerifiedFile([string]$Url,[string]$Hash,[string]$Name) {
    if($Url -notmatch '^https://github\.com/(rainmeter/rainmeter|ramensoftware/windhawk|Flow-Launcher/Flow\.Launcher)/releases/download/') {throw "Untrusted download origin: $Url"}
    $file=Join-Path $Root "downloads\$Name"
    if(!(Test-Path $file)) { Write-Log 'download' 'started' $Url; Invoke-WebRequest -UseBasicParsing -Uri $Url -OutFile $file -TimeoutSec 300 }
    $actual=(Get-FileHash $file -Algorithm SHA256).Hash.ToLowerInvariant()
    if($actual -ne $Hash.ToLowerInvariant()){throw "SHA256 mismatch: $Name"}
    Write-Log 'integrity' 'passed' "$Name SHA256=$actual"
    $file
}
function Record-Install($Name,$Version,$Path,$Source) {
    $s=Get-State
    if(!@($s.Installed|Where-Object {$_.Name -eq $Name}).Count){$s.Installed=@($s.Installed)+[pscustomobject]@{Name=$Name;Version=$Version;Path=$Path;Source=$Source;Portable=$true};Save-State $s}
    Write-Log 'install' 'passed' "$Name $Version at $Path"
}
$catalog=@()
if(!(Get-RainmeterExe)) {
    $url='https://github.com/rainmeter/rainmeter/releases/download/v4.5.28.3936/Rainmeter-4.5.28.exe'
    $hash='de6e010f8c28882bc28dcd8f319c899f34dfddec51e1e4dd4e7a23f68ebfe14d'
    $file=Get-VerifiedFile $url $hash 'Rainmeter-4.5.28.exe'
    $dest=Join-Path $Root 'apps\Rainmeter'
    $proc=Start-Process $file -ArgumentList "/S /PORTABLE=1 /RESTART=0 /AUTOSTARTUP=0 /D=$dest" -PassThru -Wait
    if($proc.ExitCode -ne 0 -or !(Test-Path "$dest\Rainmeter.exe")){throw "Rainmeter portable install failed: $($proc.ExitCode)"}
    Record-Install 'Rainmeter' '4.5.28.3936' $dest $url
    $catalog+=[pscustomobject]@{Name='Rainmeter';URL=$url;SHA256=$hash;Verification='winget Rainmeter.Rainmeter manifest, queried on this PC'}
} else {Write-Log 'install' 'existing' (Get-RainmeterExe)}
if(!(Get-FlowExe)) {
    $release=Invoke-RestMethod 'https://api.github.com/repos/Flow-Launcher/Flow.Launcher/releases/latest' -Headers $headers -TimeoutSec 45
    if($release.prerelease -or $release.draft){throw 'Flow release is not stable.'}
    $asset=$release.assets|Where-Object {$_.name -eq 'Flow-Launcher-Portable.zip'}|Select-Object -First 1
    if(!$asset -or $asset.digest -notmatch '^sha256:([0-9a-fA-F]{64})$'){throw 'Official Flow asset has no SHA256 digest; refusing unverified download.'}
    $hash=$Matches[1]
    $file=Get-VerifiedFile $asset.browser_download_url $hash 'Flow-Launcher-Portable.zip'
    $dest=Join-Path $Root 'apps\FlowLauncher'
    New-Item -ItemType Directory -Force $dest|Out-Null
    Expand-Archive -LiteralPath $file -DestinationPath $dest -Force
    $exe=Get-ChildItem $dest -Filter Flow.Launcher.exe -Recurse|Select-Object -First 1
    if(!$exe){throw 'Flow executable missing after extraction.'}
    $dest=$exe.DirectoryName
    New-Item -ItemType Directory -Force "$dest\UserData"|Out-Null
    Record-Install 'Flow Launcher' $release.tag_name $dest $asset.browser_download_url
    $catalog+=[pscustomobject]@{Name='Flow Launcher';URL=$asset.browser_download_url;SHA256=$hash;Verification='Official GitHub release asset SHA256 digest'}
} else {
    $flow=Get-FlowExe
    Write-Log 'install' 'existing' $flow
    if($flow.StartsWith($Root,[StringComparison]::OrdinalIgnoreCase)){Record-Install 'Flow Launcher' ([Diagnostics.FileVersionInfo]::GetVersionInfo($flow).ProductVersion) (Split-Path $flow -Parent) 'https://github.com/Flow-Launcher/Flow.Launcher/releases/tag/v2.1.4'}
}
$windhawk=Join-Path $Root 'apps\Windhawk\windhawk.exe'
if(!(Test-Path "$env:ProgramFiles\Windhawk\windhawk.exe") -and !(Test-Path $windhawk)) {
    $url='https://github.com/ramensoftware/windhawk/releases/download/v1.7.3/windhawk_setup.exe'
    $hash='5116cc1703384aac88b8d7a3b57f172aea5da32b6df7355fb2f8247d23813c8f'
    $file=Get-VerifiedFile $url $hash 'windhawk_setup.exe'
    $dest=Join-Path $Root 'apps\Windhawk'
    $proc=Start-Process $file -ArgumentList "/S /PORTABLE /D=$dest" -PassThru -Wait
    if($proc.ExitCode -ne 0 -or !(Test-Path $windhawk)){throw "Windhawk portable install failed: $($proc.ExitCode)"}
    Record-Install 'Windhawk' '1.7.3' $dest $url
    $catalog+=[pscustomobject]@{Name='Windhawk';URL=$url;SHA256=$hash;Verification='winget RamenSoftware.Windhawk manifest, queried on this PC'}
} else {Write-Log 'install' 'existing' 'Windhawk already present.'}
if($catalog.Count){Write-Json $catalog (Join-Path $Root 'logs\verified-downloads.json')}
