. "$PSScriptRoot\common.ps1"
Add-Type -AssemblyName System.Windows.Forms,System.Drawing,UIAutomationClient,UIAutomationTypes
. "$PSScriptRoot\desktop-native.ps1"
Add-Type -ReferencedAssemblies System.Windows.Forms,System.Drawing -TypeDefinition @'
using System;using System.Runtime.InteropServices;using System.Collections.Generic;using System.Text;
public class GuntWindowInfo {public long Handle;public string Class,Title;public int X,Y,Width,Height;public bool Visible;}
public static class GuntVerifyNative {
 public delegate bool Callback(IntPtr h,IntPtr p);
 [StructLayout(LayoutKind.Sequential)] public struct RECT {public int left,top,right,bottom;}
 [DllImport("user32.dll")] public static extern bool SetProcessDpiAwarenessContext(IntPtr c);
 [DllImport("user32.dll")] static extern bool EnumWindows(Callback c,IntPtr p);
 [DllImport("user32.dll",CharSet=CharSet.Unicode)] static extern int GetWindowText(IntPtr h,StringBuilder s,int n);
 [DllImport("user32.dll",CharSet=CharSet.Unicode)] static extern int GetClassName(IntPtr h,StringBuilder s,int n);
 [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h,out RECT r);
 [DllImport("dwmapi.dll")] public static extern int DwmGetWindowAttribute(IntPtr h,int a,out RECT r,int size);
 [DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr h);
 [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
 [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
 [DllImport("user32.dll")] public static extern void keybd_event(byte key,byte scan,uint flags,UIntPtr info);
 public static GuntWindowInfo[] Windows(){var list=new List<GuntWindowInfo>();EnumWindows(delegate(IntPtr h,IntPtr p){var t=new StringBuilder(512);var c=new StringBuilder(256);GetWindowText(h,t,512);GetClassName(h,c,256);RECT r;GetWindowRect(h,out r);list.Add(new GuntWindowInfo{Handle=h.ToInt64(),Title=t.ToString(),Class=c.ToString(),Visible=IsWindowVisible(h),X=r.left,Y=r.top,Width=r.right-r.left,Height=r.bottom-r.top});return true;},IntPtr.Zero);return list.ToArray();}
}
'@
[GuntVerifyNative]::SetProcessDpiAwarenessContext([IntPtr](-4))|Out-Null
$results=New-Object Collections.Generic.List[object]
function Result($name,$status,$evidence){$results.Add([pscustomobject]@{Test=$name;Status=$status;Evidence=$evidence});Write-Log $name $status ([string]$evidence)}
$r=Get-Content (Join-Path $Root 'config\runtime.json') -Raw -Encoding UTF8|ConvertFrom-Json
$windows=@([GuntVerifyNative]::Windows())
$bar=$windows|Where-Object {$_.Title -like 'GUNT Desktop*'}|Select-Object -First 1
$monitor=$windows|Where-Object {$_.Class -eq 'RainmeterMeterWindow' -and $_.Title -like '*GUNT-System-Monitor*'}|Select-Object -First 1
$taskbar=$windows|Where-Object Class -eq 'Shell_TrayWnd'|Select-Object -First 1
Result '한국어 상단 바' $(if($bar -and $bar.Visible -and $bar.Height -eq [int][math]::Round((Get-Content (Join-Path $Root 'config\topbar.json') -Raw -Encoding UTF8|ConvertFrom-Json).height*$r.scale)){'passed'}else{'failed'}) ($bar|ConvertTo-Json -Compress)
Result '시스템 모니터 위치' $(if($monitor -and $monitor.Visible -and [math]::Abs($monitor.X-$r.widgetX) -le 2 -and [math]::Abs($monitor.Y-$r.widgetY) -le 2){'passed'}else{'failed'}) ($monitor|ConvertTo-Json -Compress)
Result '작업 영역 예약' $(if($bar -and [Windows.Forms.Screen]::PrimaryScreen.WorkingArea.Top -ge ($bar.Y+$bar.Height)){'passed'}else{'failed'}) ([Windows.Forms.Screen]::PrimaryScreen.WorkingArea.ToString())
$wall=Get-ItemProperty 'HKCU:\Control Panel\Desktop'
$wallConfig=Get-Content (Join-Path $Root 'config\wallpaper.json') -Raw -Encoding UTF8|ConvertFrom-Json
$wallName=if($wallConfig.brightness -eq 100){'gojo-original.jpg'}else{'gojo-'+$wallConfig.brightness+'.png'}
$wallStyle=if($wallConfig.mode -eq 'Fit'){'6'}else{'10'}
Result '선택한 밝기 배경화면' $(if($wall.Wallpaper -eq (Join-Path $Root ('wallpaper\'+$wallName)) -and $wall.WallpaperStyle -eq $wallStyle){'passed'}else{'failed'}) $wall.Wallpaper
& "$PSScriptRoot\verify-native-ui.ps1" -SkipFlyout
$native=Get-Content (Join-Path $Root 'logs\v21-menu-verification.json') -Raw -Encoding UTF8|ConvertFrom-Json
foreach($item in $native){$results.Add($item)}
$modules=@(Get-Process explorer|ForEach-Object {$_.Modules}|Where-Object {$_.ModuleName -match '^(windows-11-taskbar-styler_|taskbar-icon-size_|taskbar-clock-customization_)'})
Result 'Dock 및 시계 모드 로드' $(if($modules.Count -ge 3){'passed'}else{'failed'}) (($modules.ModuleName) -join ', ')
Result 'Windows 작업 표시줄' $(if($taskbar.Visible -and (Get-Process explorer|Where-Object Responding)){'passed'}else{'failed'}) ('높이 '+$taskbar.Height+' 픽셀')
$w=New-Object Windows.Forms.Form
$w.Text='GUNT v2.1 최대화 검증';$w.StartPosition='Manual';$w.Location=New-Object Drawing.Point 100,200
try{
 $w.Show();$w.WindowState='Maximized';[Windows.Forms.Application]::DoEvents();Start-Sleep -Milliseconds 300
 $rect=New-Object GuntVerifyNative+RECT
 $ok=[GuntVerifyNative]::DwmGetWindowAttribute($w.Handle,9,[ref]$rect,16)
 Result '최대화 창 겹침 방지' $(if($ok -eq 0 -and $rect.top -ge ($bar.Y+$bar.Height)){'passed'}else{'failed'}) ('창 상단='+$rect.top+', 상단 바 하단='+($bar.Y+$bar.Height))
}finally{$w.Close();$w.Dispose()}
$hotkey=[GuntDesktopNative]::RegisterHotKey([IntPtr]::Zero,0x4760,0x4001,0x20)
if($hotkey){[GuntDesktopNative]::UnregisterHotKey([IntPtr]::Zero,0x4760)|Out-Null}
Result '런처 단축키' $(if(!$hotkey -and (Get-Process 'Flow.Launcher' -ErrorAction SilentlyContinue)){'passed'}else{'failed'}) 'Alt+Space 등록 상태'
Result '실제 게임·화면 잠금·재로그인' 'not-tested' '작업 보존을 위해 실행하지 않았습니다.'
Write-Json $results.ToArray() (Join-Path $Root 'logs\v21-verification.json')
Write-Json $windows (Join-Path $Root 'logs\v21-windows.json')
$results|ConvertTo-Json -Depth 5
