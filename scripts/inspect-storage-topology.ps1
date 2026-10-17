. "$PSScriptRoot\common.ps1"
$rows=@(foreach($v in Get-Volume|Where-Object {$_.DriveLetter -and $_.DriveType -eq 'Fixed'}){
 $p=Get-Partition -DriveLetter $v.DriveLetter -ErrorAction SilentlyContinue|Select-Object -First 1
 $disk=if($p){Get-Disk -Number $p.DiskNumber -ErrorAction SilentlyContinue}
 [pscustomobject][ordered]@{DriveLetter=([string]$v.DriveLetter+':');Label=$v.FileSystemLabel;FileSystem=$v.FileSystem;Capacity=$v.Size;Free=$v.SizeRemaining;DiskNumber=$(if($disk){$disk.Number}else{$null});DiskModel=$(if($disk){$disk.FriendlyName}else{$null});DiskUniqueId=$(if($disk){$disk.UniqueId}else{$null});BusType=$(if($disk){$disk.BusType.ToString()}else{$null})}
})
Write-Json @{Time=(Get-Date).ToString('o');Volumes=$rows;Note='논리 볼륨과 물리 디스크 매핑. 온도는 물리 디스크 식별값에 연결해야 합니다.'} (Join-Path $Root 'state\storage-topology.json')
$rows|Select-Object DriveLetter,DiskNumber,DiskModel,BusType|ConvertTo-Json
