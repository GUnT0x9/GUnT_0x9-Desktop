. "$PSScriptRoot\enhancement-ui-common.ps1"
$old=[GuntEnhanceUi]::Cursor();$originalForeground=[GuntEnhanceUi]::GetForegroundWindow();$rows=@()
try{
 foreach($screen in [Windows.Forms.Screen]::AllScreens){
  $b=$screen.Bounds;[GuntEnhanceUi]::MouseAt([int]($b.X+$b.Width/2),[int]($b.Y+$b.Height/2))
  [GuntEnhanceUi]::Key(0x12,$true)
  try{
   [GuntEnhanceUi]::Tap(0x09);Start-Sleep -Milliseconds 450
   $h=[GuntEnhanceUi]::At([int]($b.X+$b.Width/2),[int]($b.Y+$b.Height/2));$w=[Windows.Automation.AutomationElement]::FromHandle($h)
   $tree=Get-EnhancementTree $w
   Save-EnhancementShot ('alt-tab-'+$screen.DeviceName.Replace('\','').Replace('.','')) $b
   $names=@($tree|Where-Object {$_.Name}|ForEach-Object {$_.Name})
   $isSwitcher=$w.Current.Name -match '작업 전환|Task Switching' -or @($names|Where-Object {$_ -match '실행 중인 프로그램|실행 중인 앱|작업 전환'}).Count -gt 0
   $rows+=@{Device=$screen.DeviceName;MonitorBounds=$b.ToString();WindowRoot=$w.Current.Name;WindowBounds=$w.Current.BoundingRectangle.ToString();Items=$names;DetectedSwitcher=$isSwitcher;Elements=$tree}
   [GuntEnhanceUi]::Tap(0x1b)
  }finally{[GuntEnhanceUi]::Key(0x12,$false)}
 }
 Write-Json @{Time=(Get-Date).ToString('o');ConfiguredMode='커서 화면에 전체 화면 목록; 기존 설정 보존';Monitors=$rows;Status=$(if(@($rows|Where-Object DetectedSwitcher).Count -eq 3){'passed'}else{'partial'});SettingsChanged=$false} (Join-Path $Root 'logs\enhancement-alt-tab.json')
 Write-Log 'enhancement-alt-tab' $(if(@($rows|Where-Object DetectedSwitcher).Count -eq 3){'passed'}else{'partial'}) ('세 화면 실제 Alt+Tab 호출; 전환 UI 감지 '+@($rows|Where-Object DetectedSwitcher).Count+'개')
}finally{[GuntEnhanceUi]::MouseAt($old.X,$old.Y);[GuntEnhanceUi]::SetForegroundWindow($originalForeground)|Out-Null}
