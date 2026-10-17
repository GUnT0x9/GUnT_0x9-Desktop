[Console]::OutputEncoding = New-Object Text.UTF8Encoding($false)
$OutputEncoding = [Console]::OutputEncoding
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$script:Root = Split-Path $PSScriptRoot -Parent
$script:Utf8 = New-Object Text.UTF8Encoding($false)
foreach ($d in 'logs','backups','config','bin','state','downloads') { New-Item -ItemType Directory -Force (Join-Path $Root $d) | Out-Null }
function Write-Log([string]$Action,[string]$Status,[string]$Detail) {
    $entry=[ordered]@{ time=(Get-Date).ToString('o'); action=$Action; status=$Status; detail=$Detail }
    $line=($entry|ConvertTo-Json -Compress)
    [IO.File]::AppendAllText((Join-Path $Root 'logs\changes.jsonl'),$line+[Environment]::NewLine,$Utf8)
    [Console]::WriteLine("[$Status] $Action : $Detail")
}
function Write-Json($Object,[string]$Path) {
 $text=$Object|ConvertTo-Json -Depth 24
 $directory=Split-Path $Path -Parent;New-Item -ItemType Directory -Force $directory|Out-Null
 $mutex=New-Object Threading.Mutex($false,'Local\GUNTSettingsV24');$held=$false
 try{$held=$mutex.WaitOne(15000);if(!$held){throw '다른 설정 저장 작업이 진행 중입니다.'};$temp=$Path+'.'+[guid]::NewGuid().ToString('N')+'.tmp';[IO.File]::WriteAllText($temp,$text,$Utf8)
  if(Test-Path $Path){$revision=$Path+'.previous';[IO.File]::Replace($temp,$Path,$revision)}else{Move-Item $temp $Path}
 }finally{if($temp -and (Test-Path $temp)){Remove-Item $temp -Force};if($held){$mutex.ReleaseMutex()};$mutex.Dispose()}
}
function Read-Theme { Get-Content (Join-Path $Root 'config\theme.json') -Raw -Encoding UTF8 | ConvertFrom-Json }
function Test-Admin { ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) }
function Get-State { $p=Join-Path $Root 'state\baseline.clixml'; if(Test-Path $p){Import-Clixml $p}else{$null} }
function Save-State($State) {
    $p=Join-Path $Root 'state\baseline.clixml'; $temp="$p.tmp"
    $State | Export-Clixml $temp -Depth 20
    Move-Item $temp $p -Force
}
function Backup-Target([string]$Path) {
    $s=Get-State
    if(!$s){throw 'Run backup.ps1 before changing user settings.'}
    if(@($s.Files|Where-Object {$_.Path -eq $Path}).Count){return}
    $i=@($s.Files).Count
    $dest=Join-Path $s.BackupPath ('files\'+$i)
    $exists=Test-Path -LiteralPath $Path
    if($exists) { New-Item -ItemType Directory -Force (Split-Path $dest -Parent)|Out-Null; Copy-Item -LiteralPath $Path -Destination $dest -Recurse -Force -ErrorAction Stop }
    $s.Files=@($s.Files)+[pscustomobject]@{Path=$Path;Exists=$exists;Backup=$dest;Touched=$false}
    Save-State $s
}
function Mark-Target([string]$Path) {
    Backup-Target $Path
    $s=Get-State; ($s.Files|Where-Object {$_.Path -eq $Path}).Touched=$true; Save-State $s
}
function Set-GuntValue([string]$Path,[string]$Name,$Value,[string]$Kind='DWord') {
    $s=Get-State; if(!$s){throw 'Baseline missing.'}
    if(!@($s.Registry|Where-Object {$_.Path -eq $Path -and $_.Name -eq $Name}).Count) {
        $key=Get-Item $Path -ErrorAction SilentlyContinue
        $exists=$key -and ($key.GetValueNames() -contains $Name)
        $s.Registry=@($s.Registry)+[pscustomobject]@{Path=$Path;Name=$Name;Exists=[bool]$exists;Kind=$(if($exists){$key.GetValueKind($Name).ToString()}else{$Kind});Value=$(if($exists){$key.GetValue($Name,$null,[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)}else{$null});Touched=$false}
        Save-State $s
    }
    if(!(Test-Path $Path)){New-Item -Path $Path|Out-Null}
    # Journal before writing, so an interrupted write can still be restored.
    $s=Get-State; ($s.Registry|Where-Object {$_.Path -eq $Path -and $_.Name -eq $Name}).Touched=$true; Save-State $s
    New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Kind -Force|Out-Null
    Write-Log 'registry' 'applied' "$Path / $Name"
}
function Get-AppPaths {
    $a=[ordered]@{explorer="$env:WINDIR\explorer.exe"; terminal="$env:LOCALAPPDATA\Microsoft\WindowsApps\wt.exe"; code="$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe"; wsl="$env:WINDIR\System32\wsl.exe"; settings='ms-settings:'; browser='https://www.google.com'; github=$null}
    $prog=(Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\https\UserChoice' -ErrorAction SilentlyContinue).ProgId
    $br=@{ChromeHTML="$env:ProgramFiles\Google\Chrome\Application\chrome.exe";BraveHTML="$env:ProgramFiles\BraveSoftware\Brave-Browser\Application\brave.exe";MSEdgeHTM="${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"}
    foreach($k in $br.Keys){if($prog -like "$k*"){if(Test-Path $br[$k]){$a.browser=$br[$k]}}}
    if($prog -like 'Firefox*' -and (Test-Path "$env:ProgramFiles\Mozilla Firefox\firefox.exe")){$a.browser="$env:ProgramFiles\Mozilla Firefox\firefox.exe"}
    $gh=Get-ChildItem "$env:LOCALAPPDATA\GitHubDesktop\app-*\GitHubDesktop.exe" -ErrorAction SilentlyContinue|Sort-Object FullName -Descending|Select-Object -First 1
    if($gh){$a.github=$gh.FullName}
    [pscustomobject]$a
}
function Get-RainmeterExe {
    $c=@((Join-Path $Root 'apps\Rainmeter\Rainmeter.exe'),"$env:ProgramFiles\Rainmeter\Rainmeter.exe","${env:ProgramFiles(x86)}\Rainmeter\Rainmeter.exe")
    $p=Get-Process Rainmeter -ErrorAction SilentlyContinue|Select-Object -First 1
    if($p){$c=@($p.Path)+$c}
    $c|Where-Object {$_ -and (Test-Path -LiteralPath $_)}|Select-Object -First 1
}
function Get-FlowExe {
    $c=@(Get-ChildItem (Join-Path $Root 'apps\FlowLauncher') -Filter Flow.Launcher.exe -Recurse -ErrorAction SilentlyContinue|Where-Object {$_.Directory.Name -like 'app-*'}|Sort-Object LastWriteTime -Descending|Select-Object -ExpandProperty FullName)
    $c+=@((Join-Path $Root 'apps\FlowLauncher\Flow.Launcher.exe'))
    $c+=@(Get-ChildItem "$env:LOCALAPPDATA\FlowLauncher\app-*\Flow.Launcher.exe" -ErrorAction SilentlyContinue|Sort-Object LastWriteTime -Descending|Select-Object -ExpandProperty FullName)
    $p=Get-Process 'Flow.Launcher' -ErrorAction SilentlyContinue|Select-Object -First 1
    if($p){$c=@($p.Path)+$c}
    $c|Where-Object {$_ -and (Test-Path -LiteralPath $_)}|Select-Object -First 1
}
function Start-GuntProcess([string]$File,[string]$Arguments='') { Start-Process -FilePath $File -ArgumentList $Arguments -WorkingDirectory (Split-Path $File -Parent) -PassThru }
