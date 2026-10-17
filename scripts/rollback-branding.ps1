[CmdletBinding(SupportsShouldProcess=$true)]param()
. "$PSScriptRoot\common.ps1"
$checkpoint=Get-Content (Join-Path $Root 'state\pre-official-branding-checkpoint.json') -Raw -Encoding UTF8|ConvertFrom-Json
$applied=Get-Content (Join-Path $Root 'state\official-branding-applied.json') -Raw -Encoding UTF8|ConvertFrom-Json
$backup=[IO.Path]::GetFullPath($checkpoint.BackupPath)
if(!$backup.StartsWith([IO.Path]::GetFullPath((Join-Path $Root 'backups'))+'\',[StringComparison]::OrdinalIgnoreCase)){throw '프로젝트 밖 백업은 복구하지 않습니다.'}
foreach($entry in $applied.Files){
 $path=Join-Path $Root $entry.Relative;$from=Join-Path $backup ('files\'+$entry.Relative)
 $record=@($checkpoint.Hashes|Where-Object {$_.Relative.Replace('/','\') -eq ('files\'+$entry.Relative)})|Select-Object -First 1
 if(!$record -or !(Test-Path $from) -or (Get-FileHash $from).Hash -ne $record.SHA256){throw ('브랜딩 백업 해시 오류: '+$entry.Relative)}
 if($entry.Relative -ne 'config\topbar.json' -and (Get-FileHash $path).Hash -ne $entry.SHA256){throw ('브랜딩 이후 수정된 파일은 덮어쓰지 않습니다: '+$entry.Relative)}
}
if($WhatIfPreference){$applied.Files.Relative;Write-Output '백업·적용 해시 확인 완료. 실제 설정은 바꾸지 않았습니다.';return}
if(Get-Process GUNT.ControlCenter -ErrorAction SilentlyContinue){throw '저장되지 않은 설정 보호를 위해 제어 센터를 닫은 뒤 복구하세요.'}
if(!$PSCmdlet.ShouldProcess('GUnT_0x9 Desktop','이전 브랜딩 파일·아이콘 복구')){return}
Add-Type @'
using System;using System.Runtime.InteropServices;public static class BrandRollback{[DllImport("user32.dll",CharSet=CharSet.Unicode)]static extern IntPtr FindWindow(string c,string t);[DllImport("user32.dll")]static extern bool PostMessage(IntPtr h,uint m,IntPtr w,IntPtr l);public static void Close(){PostMessage(FindWindow(null,"GUNT Desktop \u2014 Midnight Purple"),0x10,IntPtr.Zero,IntPtr.Zero);}}
'@
$bar=@(Get-Process GUNT-Bar -ErrorAction SilentlyContinue|Where-Object {$_.Path -eq (Join-Path $Root 'bin\GUNT-Bar.exe')})
[BrandRollback]::Close();foreach($p in $bar){if(!$p.WaitForExit(5000)){throw '상단 바가 종료되지 않아 복구를 중단했습니다.'}}
$revision=Join-Path $Root ('backups\before-branding-rollback-'+(Get-Date -Format 'yyyyMMdd-HHmmss'));New-Item -ItemType Directory -Force $revision|Out-Null
foreach($entry in $applied.Files){
 $path=Join-Path $Root $entry.Relative;$from=Join-Path $backup ('files\'+$entry.Relative);$to=Join-Path $revision $entry.Relative;New-Item -ItemType Directory -Force (Split-Path $to -Parent)|Out-Null;Copy-Item $path $to
 if($entry.Relative -eq 'config\topbar.json'){$current=Get-Content $path -Raw -Encoding UTF8|ConvertFrom-Json;$old=Get-Content $from -Raw -Encoding UTF8|ConvertFrom-Json;foreach($key in 'brandText','brandFont','brandSize'){$current.$key=$old.$key};Write-Json $current $path}else{Copy-Item $from $path -Force}
}
$shortcuts=Get-Content (Join-Path $Root 'state\branding-shortcuts.json') -Raw -Encoding UTF8|ConvertFrom-Json;$wsh=New-Object -ComObject WScript.Shell
foreach($change in $shortcuts.Changes){if(Test-Path -LiteralPath $change.Path){if((Get-FileHash -LiteralPath $change.Path).Hash -ne $change.AppliedSHA256){Write-Log 'branding-shortcut-rollback' 'skipped' '이후 수정된 바로가기는 유지했습니다.';continue};if($change.Created){Remove-Item -LiteralPath $change.Path}else{$link=$wsh.CreateShortcut($change.Path);$link.IconLocation=$change.Before.Icon;$link.Description=$change.Before.Description;$link.Save()}}}
if($bar.Count){Start-Process (Join-Path $Root 'bin\GUNT-Bar.exe') -ArgumentList ('"'+$Root+'"')}
Write-Log 'branding-rollback' 'completed' '브랜딩 파일을 복원했습니다. 새 원본 자산·문서·Windhawk·Rainmeter·Lively는 유지했습니다.'
