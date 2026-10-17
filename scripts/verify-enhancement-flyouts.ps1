. "$PSScriptRoot\enhancement-ui-common.ps1"
$task=[Windows.Automation.AutomationElement]::FromHandle([GuntEnhanceUi]::Taskbar())
$buttons=$task.FindAll([Windows.Automation.TreeScope]::Descendants,[Windows.Automation.Condition]::TrueCondition)
$clock=$buttons|Where-Object {$_.Current.Name -like '시계 *'}|Select-Object -First 1
$screen=[Windows.Forms.Screen]::PrimaryScreen.Bounds
$r=$clock.Current.BoundingRectangle;[GuntEnhanceUi]::Click([int]($r.X+$r.Width/2),[int]($r.Y+$r.Height/2));Start-Sleep -Milliseconds 500
$h=[GuntEnhanceUi]::At(($screen.Right-100),($screen.Bottom-300));$win=[Windows.Automation.AutomationElement]::FromHandle($h)
if($win.Current.Name -notmatch '알림|Notification'){throw '실제 알림 센터가 열리지 않았습니다.'}
Save-EnhancementShot 'notification-after'
$header=$win.FindFirst([Windows.Automation.TreeScope]::Descendants,(New-Object Windows.Automation.PropertyCondition([Windows.Automation.AutomationElement]::AutomationIdProperty,'HeaderButton')))
$month=$header.Current.Name
$next=$win.FindFirst([Windows.Automation.TreeScope]::Descendants,(New-Object Windows.Automation.PropertyCondition([Windows.Automation.AutomationElement]::AutomationIdProperty,'NextButton')))
$previous=$win.FindFirst([Windows.Automation.TreeScope]::Descendants,(New-Object Windows.Automation.PropertyCondition([Windows.Automation.AutomationElement]::AutomationIdProperty,'PreviousButton')))
$next.GetCurrentPattern([Windows.Automation.InvokePattern]::Pattern).Invoke();Start-Sleep -Milliseconds 350;$nextMonth=$header.Current.Name
$previous.GetCurrentPattern([Windows.Automation.InvokePattern]::Pattern).Invoke();Start-Sleep -Milliseconds 350;$restored=$header.Current.Name
if($month -eq $nextMonth -or $month -ne $restored){throw '달력 월 이동과 복원이 일치하지 않습니다.'}
$notificationTree=Get-EnhancementTree $win
[GuntEnhanceUi]::Tap(0x1b);Start-Sleep -Milliseconds 250
$quick=$buttons|Where-Object {$_.Current.ClassName -eq 'SystemTray.OmniButton' -and $_.Current.Name -notlike '시계 *'}|Select-Object -First 1
if(!$quick){$quick=$buttons|Where-Object {$_.Current.Name -match '스피커|Wi-Fi|네트워크' -and $_.Current.ControlType -eq [Windows.Automation.ControlType]::Button}|Select-Object -First 1}
if(!$quick){throw '실제 빠른 설정 버튼을 찾지 못했습니다.'}
$r=$quick.Current.BoundingRectangle;[GuntEnhanceUi]::Click([int]($r.X+$r.Width/2),[int]($r.Y+$r.Height/2));Start-Sleep -Milliseconds 600
Save-EnhancementShot 'quick-settings-after'
$h=[GuntEnhanceUi]::At(($screen.Right-100),($screen.Bottom-300));$quickWindow=[Windows.Automation.AutomationElement]::FromHandle($h);$quickTree=Get-EnhancementTree $quickWindow
Write-Json @{Time=(Get-Date).ToString('o');NotificationOpened=$true;CalendarMonth=$month;NextMonth=$nextMonth;RestoredMonth=$restored;NotificationTree=$notificationTree;QuickSettingsRoot=$quickWindow.Current.Name;QuickSettingsTree=$quickTree;QuickSettingsButton=$quick.Current.Name;NativeSettingsChanged=$false;Status='passed'} (Join-Path $Root 'logs\enhancement-flyout-verification.json')
[GuntEnhanceUi]::Tap(0x1b)
Write-Log 'enhancement-flyouts' 'passed' '실제 알림 센터·달력 월 이동/복원·빠른 설정을 확인했습니다. 전원·네트워크·집중 설정은 변경하지 않았습니다.'
