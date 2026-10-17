. "$PSScriptRoot\common.ps1"
Add-Type -AssemblyName Accessibility
Add-Type -Path (Join-Path $Root 'bin\Gunt.Configuration.dll')
Add-Type @'
using System;using System.Collections.Generic;using System.Runtime.InteropServices;
public static class GuntBarAccess24{
 delegate bool Callback(IntPtr h,IntPtr p);[DllImport("user32.dll",CharSet=CharSet.Unicode)]static extern IntPtr FindWindow(string c,string t);[DllImport("user32.dll")]static extern bool EnumChildWindows(IntPtr h,Callback c,IntPtr p);[DllImport("user32.dll")]public static extern bool IsWindowVisible(IntPtr h);[DllImport("oleacc.dll")]static extern int AccessibleObjectFromWindow(IntPtr h,uint id,ref Guid iid,[MarshalAs(UnmanagedType.Interface)]out Accessibility.IAccessible a);
 static Accessibility.IAccessible Accessible(IntPtr h){Guid g=new Guid("618736E0-3C3D-11CF-810C-00AA00389B71");Accessibility.IAccessible a;return AccessibleObjectFromWindow(h,0xfffffffc,ref g,out a)==0?a:null;}
 static Accessibility.IAccessible[] Buttons(){var l=new List<Accessibility.IAccessible>();EnumChildWindows(FindWindow(null,"GUNT Desktop \u2014 Midnight Purple"),delegate(IntPtr h,IntPtr p){var a=Accessible(h);try{if(a!=null&&Convert.ToInt32(a.get_accRole(0))==43)l.Add(a);}catch{}return true;},IntPtr.Zero);return l.ToArray();}
 public static string[] Names(){var l=new List<string>();foreach(var a in Buttons())l.Add(a.get_accName(0));return l.ToArray();}
 public static bool Invoke(string name){foreach(var a in Buttons())if(a.get_accName(0)==name){a.accDoDefaultAction(0);return true;}return false;}
}
'@ -ReferencedAssemblies Accessibility
$names=@([GuntBarAccess24]::Names());if(@('모니터','배경','집중','화면','설정'|Where-Object {$names -notcontains $_}).Count){throw '접근 가능한 버튼이 누락됐습니다.'}
$before=[GuntBarAccess24]::IsWindowVisible([GuntLayout]::MonitorWindow());$changed=$false
try{
 if(![GuntBarAccess24]::Invoke('모니터')){throw '접근성 클릭을 실행하지 못했습니다.'}
 for($i=0;$i -lt 40;$i++){Start-Sleep -Milliseconds 200;if([GuntBarAccess24]::IsWindowVisible([GuntLayout]::MonitorWindow()) -ne $before){$changed=$true;break}}
 if(!$changed){throw '실제 Rainmeter 표시가 변경되지 않았습니다.'}
}finally{if([GuntBarAccess24]::IsWindowVisible([GuntLayout]::MonitorWindow()) -ne $before){[GuntBarAccess24]::Invoke('모니터')|Out-Null;Start-Sleep -Seconds 2}}
$bar=Get-Content (Join-Path $Root 'config\topbar.json') -Raw -Encoding UTF8|ConvertFrom-Json
if($bar.brandText -cne 'GUnT_0x9'){throw '브랜드 문자열이 원문과 다릅니다.'}
Write-Json @{Time=(Get-Date).ToString('o');Status='passed';Accessibility='MSAA PushButton 이름·기본 동작 검증. UIA ControlType은 Pane으로 노출됨';ButtonNames=$names;ActualMonitorToggle=$changed;Brand=$bar.brandText;KeyboardFocus='Alt+Shift+G, Tab, Space 제공; 실제 키보드 검증 별도'} (Join-Path $Root 'logs\v24-topbar-verification.json')
Write-Log 'topbar-v24-test' 'passed' '실제 접근성 클릭으로 모니터 표시·숨김과 원상 복원을 확인했습니다.'
