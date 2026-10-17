. "$PSScriptRoot\common.ps1"
Add-Type -AssemblyName System.Windows.Forms,System.Drawing,UIAutomationClient,UIAutomationTypes
Add-Type @'
using System;using System.Runtime.InteropServices;
public static class GuntLauncherTest {
 [DllImport("user32.dll")] public static extern bool SetProcessDpiAwarenessContext(IntPtr c);
 [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
 [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
 [DllImport("user32.dll")] public static extern void keybd_event(byte key,byte scan,uint flags,UIntPtr info);
}
'@
[GuntLauncherTest]::SetProcessDpiAwarenessContext([IntPtr](-4))|Out-Null
$foreground=[GuntLauncherTest]::GetForegroundWindow()
$flow=Get-Process 'Flow.Launcher' -ErrorAction Stop|Select-Object -First 1
$results=New-Object Collections.Generic.List[object]
function Result($name,$status,$detail){$results.Add([pscustomobject]@{Test=$name;Status=$status;Evidence=$detail});Write-Log $name $status $detail}
try {
    [GuntLauncherTest]::keybd_event(0x12,0,0,[UIntPtr]::Zero)
    [GuntLauncherTest]::keybd_event(0x20,0,0,[UIntPtr]::Zero)
    [GuntLauncherTest]::keybd_event(0x20,0,2,[UIntPtr]::Zero)
    [GuntLauncherTest]::keybd_event(0x12,0,2,[UIntPtr]::Zero)
    Start-Sleep -Seconds 1
    $condition=New-Object Windows.Automation.PropertyCondition([Windows.Automation.AutomationElement]::ProcessIdProperty,$flow.Id)
    $windows=[Windows.Automation.AutomationElement]::RootElement.FindAll([Windows.Automation.TreeScope]::Children,$condition)
    $window=@($windows|Where-Object {!$_.Current.IsOffscreen -and $_.Current.IsEnabled})|Select-Object -First 1
    if(!$window){
        # Foreground restrictions can prevent injected Alt+Space in a WSL test.
        # Also exercise the same executable launch used by the top-bar menu.
        Start-Process $flow.Path -WorkingDirectory (Split-Path $flow.Path -Parent)|Out-Null
        Start-Sleep -Seconds 2
        $windows=[Windows.Automation.AutomationElement]::RootElement.FindAll([Windows.Automation.TreeScope]::Children,$condition)
        foreach($candidate in $windows){$candidate.Current|Select-Object Name,IsEnabled,IsOffscreen,NativeWindowHandle|ConvertTo-Json -Compress|Write-Output}
        $window=@($windows|Where-Object {!$_.Current.IsOffscreen -and $_.Current.IsEnabled})|Select-Object -First 1
    }
    if(!$window){throw '자동 검사에서 표시 중인 Flow 검색창을 찾지 못했습니다.'}
    $textCondition=New-Object Windows.Automation.PropertyCondition([Windows.Automation.AutomationElement]::ControlTypeProperty,[Windows.Automation.ControlType]::Edit)
    $edits=$window.FindAll([Windows.Automation.TreeScope]::Descendants,$textCondition)
    foreach($edit in $edits){$edit.Current|Select-Object Name,AutomationId,IsEnabled,IsOffscreen|ConvertTo-Json -Compress|Write-Output}
    $query=@($edits|Where-Object {$_.Current.IsEnabled -and !$_.Current.IsOffscreen})|Select-Object -First 1
    if(!$query){throw 'UI 자동화에서 Flow 검색 입력란을 찾지 못했습니다.'}
    $value=$query.GetCurrentPattern([Windows.Automation.ValuePattern]::Pattern)
    $value.SetValue('Visual Studio Code')
    Start-Sleep -Seconds 3
    $items=$window.FindAll([Windows.Automation.TreeScope]::Descendants,[Windows.Automation.Condition]::TrueCondition)
    $names=@($items|ForEach-Object {$_.Current.Name}|Where-Object {$_})
    $listCondition=New-Object Windows.Automation.PropertyCondition([Windows.Automation.AutomationElement]::ControlTypeProperty,[Windows.Automation.ControlType]::ListItem)
    $list=$window.FindAll([Windows.Automation.TreeScope]::Descendants,$listCondition)
    $found=@($list|Where-Object {$_.Current.Name -match 'Visual Studio Code'}).Count -gt 0
    Result 'launcher-program-search' $(if($found){'passed'}else{'inconclusive'}) (($names|Select-Object -Unique|Select-Object -First 20) -join ' | ')
    $bounds=$window.Current.BoundingRectangle
    $bmp=New-Object Drawing.Bitmap ([int]$bounds.Width),([int]$bounds.Height)
    $graphics=[Drawing.Graphics]::FromImage($bmp)
    try{$graphics.CopyFromScreen([int]$bounds.X,[int]$bounds.Y,0,0,$bmp.Size);$bmp.Save((Join-Path $Root 'screenshots\launcher.png'))}finally{$graphics.Dispose();$bmp.Dispose()}
} catch {Result 'launcher-program-search' 'failed' $_.Exception.Message}
finally{
    if($window){
        $window.SetFocus()
        [Windows.Forms.SendKeys]::SendWait('{ESC}')
    }
    [GuntLauncherTest]::SetForegroundWindow($foreground)|Out-Null
}
$r=Get-Content (Join-Path $Root 'config\runtime.json') -Raw -Encoding UTF8|ConvertFrom-Json
$settings=Get-Content (Join-Path $r.flowData 'Settings\Settings.json') -Raw -Encoding UTF8|ConvertFrom-Json
Result 'launcher-theme' $(if($settings.Theme -eq 'Midnight Purple'){'passed'}else{'failed'}) ('적용 테마: '+$settings.Theme)
Result 'launcher-dialog-hotkey' $(if($settings.DialogJumpHotkey -eq 'Ctrl + Alt + Shift + G'){'passed'}else{'failed'}) ('선택형 대화상자 단축키: '+$settings.DialogJumpHotkey)
Write-Json $results.ToArray() (Join-Path $Root 'logs\launcher-verification.json')
