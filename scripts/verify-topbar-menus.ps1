param([switch]$SkipFlyout)
. "$PSScriptRoot\common.ps1"
Add-Type -AssemblyName System.Windows.Forms,System.Drawing,Accessibility,UIAutomationClient,UIAutomationTypes
Add-Type @'
using System;using System.Collections.Generic;using System.Runtime.InteropServices;using System.Text;
public static class GuntNativeUITest {
 public delegate bool Callback(IntPtr h,IntPtr p);
 [DllImport("user32.dll")] static extern bool EnumWindows(Callback c,IntPtr p);
 [DllImport("user32.dll")] static extern bool EnumChildWindows(IntPtr h,Callback c,IntPtr p);
 [DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr h);
 [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr h,out uint pid);
 [DllImport("user32.dll",CharSet=CharSet.Unicode)] static extern IntPtr FindWindow(string c,string t);
 [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h,uint m,IntPtr w,IntPtr l);
 [DllImport("user32.dll")] public static extern void keybd_event(byte k,byte s,uint f,UIntPtr p);
 [DllImport("user32.dll")] public static extern bool SetProcessDpiAwarenessContext(IntPtr c);
 [DllImport("oleacc.dll")] static extern int AccessibleObjectFromWindow(IntPtr h,uint id,ref Guid iid,[MarshalAs(UnmanagedType.Interface)] out Accessibility.IAccessible a);
 public static IntPtr Bar(){return FindWindow(null,"GUNT Desktop \u2014 Midnight Purple");}
 public static Accessibility.IAccessible Accessible(IntPtr h){Accessibility.IAccessible a;Guid id=new Guid("618736E0-3C3D-11CF-810C-00AA00389B71");return AccessibleObjectFromWindow(h,0xfffffffc,ref id,out a)==0?a:null;}
 public static IntPtr Navigation(){IntPtr found=IntPtr.Zero;EnumChildWindows(Bar(),delegate(IntPtr h,IntPtr p){var a=Accessible(h);try{if(a!=null&&a.accChildCount==5&&a.get_accName(1)=="GUnT_0x9")found=h;}catch{}return true;},IntPtr.Zero);return found;}
 public static string[] MenuNames(){var a=Accessible(Navigation());var result=new List<string>();if(a!=null)for(int i=1;i<=a.accChildCount;i++)result.Add(a.get_accName(i));return result.ToArray();}
 public static void OpenMenu(int index){Accessible(Navigation()).accDoDefaultAction(index);}
 public static string[] Popups(uint process){var names=new List<string>();EnumWindows(delegate(IntPtr h,IntPtr p){uint pid;GetWindowThreadProcessId(h,out pid);if(pid!=process||!IsWindowVisible(h)||h==Bar())return true;var a=Accessible(h);if(a!=null){for(int i=1;i<=a.accChildCount;i++){try{names.Add(a.get_accName(i));}catch{}}}return true;},IntPtr.Zero);return names.ToArray();}
 public static bool InvokePopup(uint process,string name){bool done=false;EnumWindows(delegate(IntPtr h,IntPtr p){uint pid;GetWindowThreadProcessId(h,out pid);if(pid!=process||!IsWindowVisible(h)||h==Bar())return true;var a=Accessible(h);if(a!=null)for(int i=1;i<=a.accChildCount;i++){try{if(a.get_accName(i)==name){a.accDoDefaultAction(i);done=true;return false;}}catch{}}return true;},IntPtr.Zero);return done;}
 public static void CloseMenus(uint process){EnumWindows(delegate(IntPtr h,IntPtr p){uint pid;GetWindowThreadProcessId(h,out pid);if(pid==process&&h!=Bar()&&IsWindowVisible(h)){PostMessage(h,0x100,new IntPtr(0x1b),IntPtr.Zero);PostMessage(h,0x101,new IntPtr(0x1b),IntPtr.Zero);}return true;},IntPtr.Zero);}
 public static void Win(byte key){keybd_event(0x5b,0,0,UIntPtr.Zero);if(key!=0){keybd_event(key,0,0,UIntPtr.Zero);keybd_event(key,0,2,UIntPtr.Zero);}keybd_event(0x5b,0,2,UIntPtr.Zero);}
}
'@ -ReferencedAssemblies Accessibility
[GuntNativeUITest]::SetProcessDpiAwarenessContext([IntPtr](-4))|Out-Null
$results=New-Object Collections.Generic.List[object]
function Result($n,$s,$e){$results.Add([pscustomobject]@{Test=$n;Status=$s;Evidence=$e});Write-Log $n $s $e}
$owned=Get-Process 'GUNT-Bar'|Select-Object -First 1
$names=@([GuntNativeUITest]::MenuNames())
Result '한국어 메뉴 이름' $(if(($names -join '|') -eq 'GUnT_0x9|작업공간|개발|도구|시스템'){'passed'}else{'failed'}) ($names -join ', ')
$expected=@('GUnT_0x9 제어 센터','파일 탐색기','윈도우 터미널','작업 관리자','시스템 모니터 전환')
for($i=1;$i -le 5;$i++){
 try{
  [GuntNativeUITest]::OpenMenu($i);Start-Sleep -Milliseconds 300
  $popups=@([GuntNativeUITest]::Popups($owned.Id))
  Result ('실제 드롭다운 '+$names[$i-1]) $(if($popups -contains $expected[$i-1]){'passed'}else{'partial'}) ($popups -join ', ')
 }catch{Result ('실제 드롭다운 '+$i) 'failed' $_.Exception.Message}
 finally{[GuntNativeUITest]::CloseMenus($owned.Id);Start-Sleep -Milliseconds 100}
}
# Open the genuine Windows notification/calendar surface; inspect its host only.
if(!$SkipFlyout){
[GuntNativeUITest]::Win(0x4e);Start-Sleep -Seconds 2
$hosts=@(Get-Process ShellHost,ShellExperienceHost -ErrorAction SilentlyContinue)
$loaded=@()
foreach($hostProcess in $hosts){try{$loaded+=@($hostProcess.Modules|Where-Object {$_.ModuleName -like 'windows-11-notification-center-styler_*'}|Select-Object -ExpandProperty ModuleName)}catch{}}
Result '알림 센터 스타일 모드' $(if($loaded.Count){'passed'}else{'partial'}) $(if($loaded.Count){$loaded -join ', '}else{'호스트에서 모드 로드를 확인하지 못했습니다.'})
& (Join-Path $Root 'scripts\capture.ps1') -Name 'v21-calendar'
[GuntNativeUITest]::Win(0x4e)
}
Write-Json $results.ToArray() (Join-Path $Root $(if($SkipFlyout){'logs\v23-menu-verification.json'}else{'logs\v23-native-ui-verification.json'}))
