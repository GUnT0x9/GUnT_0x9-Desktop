. "$PSScriptRoot\enhancement-ui-common.ps1"
$case=Join-Path $Root ('tests\windhawk-enhancement\'+(Get-Date -Format 'yyyyMMdd-HHmmss'))
$source=Join-Path $case 'source';$dest=Join-Path $case 'destination';$large=Join-Path $case 'large'
foreach($folder in $source,$dest,$large){New-Item -ItemType Directory -Force $folder|Out-Null}
$file=Join-Path $source 'gunt-copy-test.txt';[IO.File]::WriteAllText($file,'GUNT Explorer copy, paste and rename validation.',$Utf8)
for($i=0;$i -lt 500;$i++){[IO.File]::WriteAllText((Join-Path $large ('sample-'+$i.ToString('000')+'.txt')),'QA',$Utf8)}
$shell=New-Object -ComObject Shell.Application
Start-Process explorer.exe -ArgumentList ('/n,"'+$source+'"')
$folderWindow=$null
for($i=0;$i -lt 30 -and !$folderWindow;$i++){Start-Sleep -Milliseconds 200;foreach($item in $shell.Windows()){try{if($item.Document.Folder.Self.Path -eq $source){$folderWindow=$item;break}}catch{}}}
if(!$folderWindow){throw '검증용 탐색기 창을 찾지 못했습니다.'}
$h=[IntPtr]$folderWindow.HWND;$folderWindow.Document.CurrentViewMode=4
[GuntEnhanceUi]::SetWindowPos($h,[IntPtr](-1),0,0,0,0,0x13)|Out-Null;[GuntEnhanceUi]::SetForegroundWindow($h)|Out-Null
$clip=$null;$clipboardChanged=$false;$results=@{}
try{
 Start-Sleep -Milliseconds 600
 $win=[Windows.Automation.AutomationElement]::FromHandle($h)
 $item=$win.FindFirst([Windows.Automation.TreeScope]::Descendants,(New-Object Windows.Automation.PropertyCondition([Windows.Automation.AutomationElement]::NameProperty,'gunt-copy-test.txt')))
 if(!$item){throw '탐색기의 실제 시험 파일 항목을 찾지 못했습니다.'}
 $selection=$item.GetCurrentPattern([Windows.Automation.SelectionItemPattern]::Pattern);$selection.Select();$item.SetFocus()
 # Materialize clipboard data before replacing it, without exposing content in logs.
 $previous=[Windows.Forms.Clipboard]::GetDataObject();$clip=New-Object Windows.Forms.DataObject
 if($previous){foreach($format in $previous.GetFormats($false)){$data=$previous.GetData($format,$false);if($null -ne $data){$clip.SetData($format,$false,$data)}}}
 [GuntEnhanceUi]::Chord(0x11,0x43);$clipboardChanged=$true;Start-Sleep -Milliseconds 300
 if(![Windows.Forms.Clipboard]::ContainsFileDropList()){throw '탐색기 복사 명령이 파일 클립보드를 만들지 못했습니다.'}
 $drop=[Windows.Forms.Clipboard]::GetFileDropList();if($drop -notcontains $file){throw '복사된 항목이 시험 파일이 아닙니다.'}
 $folderWindow.Navigate2($dest);Start-Sleep -Milliseconds 600
 $win=[Windows.Automation.AutomationElement]::FromHandle($h);[GuntEnhanceUi]::SetForegroundWindow($h)|Out-Null;Start-Sleep -Milliseconds 150;$focusRect=$win.Current.BoundingRectangle;[GuntEnhanceUi]::Click([int]($focusRect.X+$focusRect.Width*0.60),[int]($focusRect.Y+$focusRect.Height*0.60));[GuntEnhanceUi]::Chord(0x11,0x56)
 $copied=Join-Path $dest 'gunt-copy-test.txt';for($i=0;$i -lt 30 -and !(Test-Path $copied);$i++){Start-Sleep -Milliseconds 150}
 if(!(Test-Path $copied) -or (Get-FileHash $copied).Hash -ne (Get-FileHash $file).Hash){throw '탐색기 붙여넣기 후 내용 해시가 맞지 않습니다.'};$results.CopyPaste=$true
 $nativeItem=$folderWindow.Document.Folder.ParseName('gunt-copy-test.txt');$nativeItem.Name='gunt-renamed-test.txt';Start-Sleep -Milliseconds 300
 $renamed=Join-Path $dest 'gunt-renamed-test.txt';if(!(Test-Path $renamed)){throw '셸 이름 변경 결과를 찾을 수 없습니다.'};$results.ShellRename=$true
 [GuntEnhanceUi]::SetForegroundWindow($h)|Out-Null;Start-Sleep -Milliseconds 150;$focusRect=$win.Current.BoundingRectangle;[GuntEnhanceUi]::Click([int]($focusRect.X+$focusRect.Width*0.60),[int]($focusRect.Y+$focusRect.Height*0.60));[GuntEnhanceUi]::Chord(0x11,0x54);Start-Sleep -Milliseconds 400
 $tabsBefore=@($win.FindAll([Windows.Automation.TreeScope]::Descendants,(New-Object Windows.Automation.PropertyCondition([Windows.Automation.AutomationElement]::ControlTypeProperty,[Windows.Automation.ControlType]::TabItem))))
 $results.TabCount=$tabsBefore.Count;if($tabsBefore.Count -lt 2){throw '탐색기 새 탭이 생성되지 않았습니다.'}
 [GuntEnhanceUi]::Chord(0x11,0x57);Start-Sleep -Milliseconds 350
 $folderWindow.Navigate2($large);$watch=[Diagnostics.Stopwatch]::StartNew()
 for($i=0;$i -lt 60;$i++){Start-Sleep -Milliseconds 150;try{if($folderWindow.Document.Folder.Self.Path -eq $large -and $folderWindow.Document.Folder.Items().Count -eq 500){break}}catch{}}
 $results.LargeDirectoryCount=$folderWindow.Document.Folder.Items().Count;$results.LargeDirectoryObservedMs=$watch.ElapsedMilliseconds
 if($results.LargeDirectoryCount -ne 500){throw '500개 파일 목록을 읽지 못했습니다.'}
 Save-EnhancementShot 'explorer-after' $win.Current.BoundingRectangle
 # Use the native Explorer search box, after returning to our sandbox volume.
 $folderWindow.Navigate2($dest);Start-Sleep -Milliseconds 600
 [GuntEnhanceUi]::SetForegroundWindow($h)|Out-Null
 [GuntEnhanceUi]::Chord(0x11,0x46);Start-Sleep -Milliseconds 180
 $focused=[Windows.Automation.AutomationElement]::FocusedElement
 if($focused.Current.ProcessId -ne $win.Current.ProcessId -or $focused.Current.Name -notmatch '검색'){throw '탐색기 검색 상자에 포커스를 두지 못했습니다.'}
 [GuntEnhanceUi]::Text('gunt-renamed-test');[GuntEnhanceUi]::Tap(0x0d)
 $found=@()
 for($i=0;$i -lt 50 -and !$found.Count;$i++){
  Start-Sleep -Milliseconds 150
  try{$found=@($folderWindow.Document.Folder.Items()|Where-Object {$_.Name -like 'gunt-renamed-test*'})}catch{}
 }
 $results.SearchFound=$found.Count -gt 0
 if(!$results.SearchFound){throw '탐색기 파일 검색에서 시험 파일을 찾지 못했습니다.'}
 Save-EnhancementShot 'explorer-search' $win.Current.BoundingRectangle
 # Open a standard context menu on our sandbox result only.
 $result=$win.FindAll([Windows.Automation.TreeScope]::Descendants,(New-Object Windows.Automation.PropertyCondition([Windows.Automation.AutomationElement]::ControlTypeProperty,[Windows.Automation.ControlType]::ListItem)))|Where-Object {$_.Current.Name -like 'gunt-renamed-test*'}|Select-Object -First 1
 if($result){$result.SetFocus();[GuntEnhanceUi]::Chord(0x10,0x79);Start-Sleep -Milliseconds 300;Save-EnhancementShot 'explorer-context';[GuntEnhanceUi]::Tap(0x1b);$results.ContextMenu='화면 캡처 별도 확인'}else{$results.ContextMenu='자동 입력 미확인'}
 $results.LoadedModules=@((Get-Process explorer|ForEach-Object {$_.Modules}|Where-Object {$_.ModuleName -like 'fix-explorer-white-flash_*' -or $_.ModuleName -like 'explorer-details-better-file-sizes_*'})|Select-Object -ExpandProperty ModuleName -Unique)
 $results.Time=(Get-Date).ToString('o');$results.Fixture=$case;$results.NetworkPath='현재 검증 가능한 기존 UNC 연결 없음; 미시험';$results.Status='passed'
 Write-Json $results (Join-Path $Root 'logs\enhancement-explorer-verification.json');Write-Log 'enhancement-explorer' 'passed' '실제 탐색기 복사·붙여넣기 해시, 셸 이름 변경, 탭, 검색, 500개 파일 목록 검증.'
}catch{$results.Status='failed';$results.Error=$_.Exception.Message;$results.Time=(Get-Date).ToString('o');try{$results.CurrentLocation=$folderWindow.Document.Folder.Self.Path}catch{};Write-Json $results (Join-Path $Root 'logs\enhancement-explorer-failure.json');throw}finally{
 if($clipboardChanged){if($previous){[Windows.Forms.Clipboard]::SetDataObject($clip,$true)}else{[Windows.Forms.Clipboard]::Clear()}}
 [GuntEnhanceUi]::SetWindowPos($h,[IntPtr](-2),0,0,0,0,0x13)|Out-Null
 # This window was created solely for this sandbox test.
 if($folderWindow){$folderWindow.Quit()}
}
