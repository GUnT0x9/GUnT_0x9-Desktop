. "$PSScriptRoot\enhancement-ui-common.ps1"
Add-Type @'
using System;using System.Runtime.InteropServices;public static class UxProjectDialog{[DllImport("user32.dll",CharSet=CharSet.Unicode)]static extern IntPtr FindWindow(string c,string t);public static IntPtr Window(string title){return FindWindow(null,title);}}
'@
$exe=Join-Path $Root 'bin\GUNT.ControlCenter.exe';$qa='UX QA '+[guid]::NewGuid().ToString('N').Substring(0,6)
function Find-Control($parent,[string]$name,$type){$parent.FindFirst([Windows.Automation.TreeScope]::Descendants,(New-Object Windows.Automation.AndCondition((New-Object Windows.Automation.PropertyCondition([Windows.Automation.AutomationElement]::NameProperty,$name)),(New-Object Windows.Automation.PropertyCondition([Windows.Automation.AutomationElement]::ControlTypeProperty,$type)))))}
function Invoke-Control($parent,[string]$name){$b=Find-Control $parent $name ([Windows.Automation.ControlType]::Button);if(!$b -or !$b.Current.IsEnabled){throw ('사용할 수 없는 버튼: '+$name)};($b.GetCurrentPattern([Windows.Automation.InvokePattern]::Pattern)).Invoke();Start-Sleep -Milliseconds 300}
function Editor([string]$title){$h=[IntPtr]::Zero;for($i=0;$i -lt 30 -and $h -eq [IntPtr]::Zero;$i++){Start-Sleep -Milliseconds 100;$h=[UxProjectDialog]::Window($title)};if($h -eq [IntPtr]::Zero){throw ('편집 창 없음: '+$title)};[Windows.Automation.AutomationElement]::FromHandle($h)}
function Set-Field($parent,[string]$label,[string]$value){$field=Find-Control $parent $label ([Windows.Automation.ControlType]::Edit);($field.GetCurrentPattern([Windows.Automation.ValuePattern]::Pattern)).SetValue($value)}
Start-Process $exe -ArgumentList ('"'+$Root+'" projects');Start-Sleep -Milliseconds 1500
$p=Get-Process GUNT.ControlCenter|Select-Object -First 1;$win=[Windows.Automation.AutomationElement]::FromHandle($p.MainWindowHandle)
$projectPath=Join-Path $Root 'config\projects.json';$recordId=$null;$outcome=@()
try{
 Invoke-Control $win '프로젝트 추가';$editor=Editor '프로젝트 추가';Set-Field $editor '이름' $qa;Set-Field $editor '폴더 경로' $Root;Set-Field $editor 'GitHub HTTPS 주소' 'https://github.com/GUnT0x9/GUnT_0x9-Desktop'
 Invoke-Control $editor '프로젝트 저장';Start-Sleep -Milliseconds 500
 $data=Get-Content $projectPath -Raw -Encoding UTF8|ConvertFrom-Json;$record=$data.Projects|Where-Object Name -eq $qa;if(!$record){throw '실제 프로젝트 저장 실패'};$recordId=$record.Id;$outcome+=@{Test='create';Status='passed'}
 $list=Find-Control $win '프로젝트 목록' ([Windows.Automation.ControlType]::List);$items=$list.FindAll([Windows.Automation.TreeScope]::Children,[Windows.Automation.Condition]::TrueCondition);$item=@($items|Where-Object {$_.Current.Name -like ('*'+$qa+'*')})|Select-Object -First 1
 if(!$item){throw '저장한 실제 프로젝트 행 없음'};($item.GetCurrentPattern([Windows.Automation.SelectionItemPattern]::Pattern)).Select()
 Invoke-Control $win '폴더 열기';Start-Sleep -Milliseconds 800
 $shell=New-Object -ComObject Shell.Application;$folder=@();for($probe=0;$probe -lt 40 -and !$folder.Count;$probe++){Start-Sleep -Milliseconds 200;$folder=@($shell.Windows()|Where-Object {try{([uri]$_.LocationURL).LocalPath.TrimEnd('\') -eq $Root.TrimEnd('\')}catch{$false}})};Write-Json @($shell.Windows()|ForEach-Object {try{@{Name=$_.LocationName;URL=$_.LocationURL}}catch{}}) (Join-Path $Root 'logs\v25-project-folder-probe.json')
 if(!$folder.Count){throw '실제 프로젝트 폴더 창을 확인하지 못했습니다.'};$outcome+=@{Test='open-folder';Status='passed'}
 Invoke-Control $win '편집 / 경로 복구';$editor=Editor '프로젝트 편집';Set-Field $editor '이름' ($qa+' renamed');Invoke-Control $editor '프로젝트 저장';Start-Sleep -Milliseconds 400
 $data=Get-Content $projectPath -Raw -Encoding UTF8|ConvertFrom-Json;if(!@($data.Projects|Where-Object {$_.Id -eq $recordId -and $_.Name -eq ($qa+' renamed')}).Count){throw '프로젝트 이름 변경 실패'};$outcome+=@{Test='edit';Status='passed'}
 Invoke-Control $win '목록에서 삭제';$dialog=Editor '프로젝트 삭제';Invoke-Control $dialog '목록에서 삭제';Start-Sleep -Milliseconds 400
 $data=Get-Content $projectPath -Raw -Encoding UTF8|ConvertFrom-Json;if(@($data.Projects|Where-Object Id -eq $recordId).Count){throw '프로젝트 목록 삭제 실패'};$recordId=$null;$outcome+=@{Test='delete';Status='passed'}
 Write-Json @{Time=(Get-Date).ToString('o');Results=$outcome;ActualDirectoryVerified=$true;NoProjectCommandsExecuted=$true;Limitations='IDE·터미널·URL은 모델 인수 검증을 수행했으며 이 GUI 시험은 폴더 열기까지 검증함.'} (Join-Path $Root 'logs\v25-project-ui.json')
 Write-Output '실제 WPF 프로젝트 추가·폴더 열기·편집·삭제 통과. QA 기록 제거 완료.'
}finally{
 if($recordId){Add-Type -Path (Join-Path $Root 'bin\Gunt.Configuration.dll');$null=[Reflection.Assembly]::LoadFrom($exe);$service=New-Object Gunt.ControlCenter.Services.DesktopService $Root;$service.DeleteProject($recordId)}
}
