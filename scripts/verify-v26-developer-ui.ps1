. "$PSScriptRoot\enhancement-ui-common.ps1"
Add-Type -Path (Join-Path $Root 'bin\Gunt.Configuration.dll');$null=[Reflection.Assembly]::LoadFrom((Join-Path $Root 'bin\GUNT.ControlCenter.exe'))
$s=New-Object Gunt.ControlCenter.Services.DesktopService $Root;$exe=Join-Path $Root 'bin\GUNT.ControlCenter.exe'
$parent=Join-Path $Root ('tests\v26-discovery-'+[guid]::NewGuid().ToString('N'));$child=Join-Path $parent '한글 프로젝트';New-Item -ItemType Directory -Force $child|Out-Null;[IO.File]::WriteAllText((Join-Path $child 'package.json'),'{}')
$old=$s.Developer();$oldSelected=$old.SelectedProjectId;$qa=$null
function Find-Name($parent,$name){$parent.FindFirst([Windows.Automation.TreeScope]::Descendants,(New-Object Windows.Automation.PropertyCondition([Windows.Automation.AutomationElement]::NameProperty,$name)))}
try{
 $s.RegisterRoot($parent);Start-Process $exe -ArgumentList ('"'+$Root+'" developer-setup');Start-Sleep -Seconds 2;$win=Get-EnhancementWindows|Where-Object {$_.Current.Name -eq 'GUnT_0x9 Desktop'}|Select-Object -First 1
 $scan=Find-Name $win '다시 탐색';($scan.GetCurrentPattern([Windows.Automation.InvokePattern]::Pattern)).Invoke();$item=$null
 for($probe=0;$probe -lt 100 -and !$item;$probe++){Start-Sleep -Milliseconds 100;$items=$win.FindAll([Windows.Automation.TreeScope]::Descendants,(New-Object Windows.Automation.PropertyCondition([Windows.Automation.AutomationElement]::ControlTypeProperty,[Windows.Automation.ControlType]::ListItem)));$item=$items|Where-Object {$_.Current.Name -like '*한글 프로젝트*' -and $_.Current.Name -like ('*'+$parent+'*')}|Select-Object -First 1}
 if(!$item){throw '다시 탐색 후 실제 하위 프로젝트가 표시되지 않았습니다.'};($item.GetCurrentPattern([Windows.Automation.SelectionItemPattern]::Pattern)).Select();Start-Sleep -Seconds 1;$qa=$s.Projects()|Where-Object Directory -eq $child|Select-Object -First 1
 if(!$qa -or $s.ActiveProject().Id -ne $qa.Id){throw '선택 프로젝트 저장 또는 기존 목록 연결 실패'}
 Write-Json @{Time=(Get-Date).ToString('o');Status='passed';ScanButton=$true;RealUnicodeChild=$true;SelectionPersisted=$true;ExistingRegistryReused=$true} (Join-Path $Root 'logs\v26-developer-ui.json')
 Write-Output '실제 루트·다시 탐색 버튼·한글 하위 폴더·선택 프로젝트 저장 통과'
}finally{if($qa){$s.DeleteProject($qa.Id)};$s.RemoveRoot($parent);$d=$s.Developer();$d.SelectedProjectId=$oldSelected;$s.SaveDeveloper($d)}
