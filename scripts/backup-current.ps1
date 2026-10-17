. "$PSScriptRoot\common.ps1"
$dest=Join-Path $Root ('backups\manual-'+(Get-Date -Format 'yyyyMMdd-HHmmss'))
New-Item -ItemType Directory -Force $dest|Out-Null
foreach($folder in 'config','rainmeter','src','scripts','windhawk'){Copy-Item (Join-Path $Root $folder) (Join-Path $dest $folder) -Recurse -Force}
Write-Log 'manual-backup' 'passed' ('현재 프로젝트 설정을 백업했습니다: '+$dest)
