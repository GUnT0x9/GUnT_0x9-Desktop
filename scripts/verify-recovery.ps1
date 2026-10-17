. "$PSScriptRoot\common.ps1"
$s=Get-Content (Join-Path $Root 'state\v21-backup.json') -Raw -Encoding UTF8|ConvertFrom-Json
$missing=@($s.Files|Where-Object {$_.Exists -and !(Test-Path -LiteralPath $_.Backup)})
$missingReg=@($s.RegistryExports|Where-Object {!(Test-Path -LiteralPath $_.File)})
$result=[ordered]@{Time=(Get-Date).ToString('o');Status=$(if(!$missing.Count -and !$missingReg.Count){'passed'}else{'failed'});Snapshot=$s.BackupPath;BackedUpTargets=@($s.Files|Where-Object Exists).Count;RegistryExports=@($s.RegistryExports).Count;Missing=@($missing|ForEach-Object Relative)+@($missingReg|ForEach-Object Key);RollbackScript=(Test-Path (Join-Path $Root 'scripts\rollback.ps1'));OriginalWindowsRollback=(Test-Path (Join-Path $Root 'scripts\rollback-original.ps1'));RestorePoint=$s.RestorePoint;Limitations='백업 파일과 복구 경로를 읽기 전용으로 검사했습니다. 실제 원상복구는 실행하지 않았습니다.'}
Write-Json $result (Join-Path $Root 'logs\v21-recovery-verification.json')
$result|ConvertTo-Json -Depth 5
