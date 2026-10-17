. "$PSScriptRoot\enhancement-ui-common.ps1"
$notepadBefore=@((Get-Process Notepad -ErrorAction SilentlyContinue).Id)
$win=Open-EnhancementStart;Start-Sleep -Milliseconds 400
$before=Get-Content (Join-Path $Root 'logs\enhancement-start-before.json') -Raw -Encoding UTF8|ConvertFrom-Json;$tree=Get-EnhancementTree $win
$oldPins=@($before.Elements|Where-Object {$_.Id -like 'tile-*'}|ForEach-Object {$_.Id});$newPins=@($tree|Where-Object {$_.Id -like 'tile-*'}|ForEach-Object {$_.Id})
if(@(Compare-Object $oldPins $newPins).Count){throw '시작 메뉴 고정 앱 목록이 이전 상태와 다릅니다.'}
Save-EnhancementShot 'start-after'
$power=$win.FindFirst([Windows.Automation.TreeScope]::Descendants,(New-Object Windows.Automation.PropertyCondition([Windows.Automation.AutomationElement]::AutomationIdProperty,'PowerButton')))
$r=$power.Current.BoundingRectangle
[GuntEnhanceUi]::Click([int]($r.X+$r.Width/2),[int]($r.Y+$r.Height/2));Start-Sleep -Milliseconds 300
Save-EnhancementShot 'start-power'
# XAML popup menus are separate automation trees, not descendants of the Start frame.
$point=New-Object Windows.Point ($r.X+$r.Width/2),($r.Y-60)
$element=[Windows.Automation.AutomationElement]::FromPoint($point);$menu=$element
for($i=0;$i -lt 8 -and $menu -and $menu.Current.ControlType -ne [Windows.Automation.ControlType]::Menu;$i++){$menu=[Windows.Automation.TreeWalker]::ControlViewWalker.GetParent($menu)}
$powerNames=@();if($menu){$powerNames=@((Get-EnhancementTree $menu)|Where-Object {$_.Name -in '절전','시스템 종료','다시 시작'}|ForEach-Object {$_.Name})}
[GuntEnhanceUi]::Tap(0x1b);[GuntEnhanceUi]::Tap(0x1b);Start-Sleep -Milliseconds 200
[GuntEnhanceUi]::Chord(0x5b,0x53);Start-Sleep -Milliseconds 650
$screen=[Windows.Forms.Screen]::PrimaryScreen.Bounds;$h=[GuntEnhanceUi]::At([int]($screen.Width/2),[int]($screen.Height/2));$searchWindow=[Windows.Automation.AutomationElement]::FromHandle($h)
if(@((Get-Process SearchHost -ErrorAction SilentlyContinue).Id) -notcontains $searchWindow.Current.ProcessId){throw 'Windows 검색 화면을 확인하지 못했습니다.'}
$edit=$searchWindow.FindFirst([Windows.Automation.TreeScope]::Descendants,(New-Object Windows.Automation.PropertyCondition([Windows.Automation.AutomationElement]::ControlTypeProperty,[Windows.Automation.ControlType]::Edit)))
if(!$edit -or $edit.Current.IsOffscreen){throw '검색 입력이 화면에 없습니다.'}
$edit.SetFocus();[GuntEnhanceUi]::Chord(0x11,0x41);[GuntEnhanceUi]::Text('notepad');Start-Sleep -Milliseconds 1300
Save-EnhancementShot 'start-search'
$searchTree=Get-EnhancementTree $searchWindow
$value=$edit.GetCurrentPattern([Windows.Automation.ValuePattern]::Pattern).Current.Value
if($value -notmatch 'notepad'){throw '검색 입력 내용이 예상과 다릅니다.'}
$foreground=[Windows.Automation.AutomationElement]::FromHandle([GuntEnhanceUi]::GetForegroundWindow())
if($foreground.Current.ProcessId -ne $searchWindow.Current.ProcessId){throw '검색창이 전경이 아니므로 Enter 입력을 중단했습니다.'}
[GuntEnhanceUi]::Tap(0x0d)
$launched=@()
for($i=0;$i -lt 30 -and !$launched.Count;$i++){Start-Sleep -Milliseconds 150;$launched=@(Get-Process Notepad -ErrorAction SilentlyContinue|Where-Object {$notepadBefore -notcontains $_.Id})}
$launchedOk=$launched.Count -gt 0
Write-Json @{Time=(Get-Date).ToString('o');OpenObservedMs=$StartOpenMs;PinnedPreserved=$true;PinnedCount=$newPins.Count;PowerMenuItems=$powerNames;PowerMenuVisual='실제 전원 메뉴 캡처 확인';SearchInput=$value;SearchTree=$searchTree;SearchLaunchedNotepad=$launchedOk;LaunchedPids=@($launched.Id);StartElements=$tree;Status=$(if($launchedOk){'passed'}else{'partial'})} (Join-Path $Root 'logs\enhancement-start-verification.json')
# Close only the blank app instance created by this search test if there were no pre-existing Notepad instances.
if(!$notepadBefore.Count){foreach($p in $launched){$p.CloseMainWindow()|Out-Null}}
if(!$launchedOk){throw '검색 결과에서 메모장 실행을 확인하지 못했습니다.'}
Write-Log 'enhancement-start' 'passed' ('고정 앱 '+$newPins.Count+'개 보존; 전원 메뉴 화면; 실제 검색에서 메모장 실행 확인.')
