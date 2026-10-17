. "$PSScriptRoot\common.ps1"
Add-Type -Path (Join-Path $Root 'bin\Gunt.Configuration.dll')
Add-Type @'
using System;using System.Text;using System.Runtime.InteropServices;
public static class Keyboard24{
 [StructLayout(LayoutKind.Sequential)]struct GUITHREADINFO{public int cbSize;public uint flags;public IntPtr active,focus,capture,menu,move,caret;public int l,t,r,b;}
 [DllImport("user32.dll")]static extern void keybd_event(byte key,byte scan,uint flags,UIntPtr data);[DllImport("user32.dll")]static extern bool GetGUIThreadInfo(uint id,ref GUITHREADINFO info);[DllImport("user32.dll",CharSet=CharSet.Unicode)]static extern int GetWindowText(IntPtr h,StringBuilder s,int n);[DllImport("user32.dll")]public static extern bool IsWindowVisible(IntPtr h);[DllImport("user32.dll")]public static extern IntPtr GetForegroundWindow();[DllImport("user32.dll")]public static extern bool SetForegroundWindow(IntPtr h);
 public static void Hotkey(){keybd_event(0x12,0,0,UIntPtr.Zero);keybd_event(0x10,0,0,UIntPtr.Zero);keybd_event(0x47,0,0,UIntPtr.Zero);keybd_event(0x47,0,2,UIntPtr.Zero);keybd_event(0x10,0,2,UIntPtr.Zero);keybd_event(0x12,0,2,UIntPtr.Zero);}
 public static string Focus(){var info=new GUITHREADINFO();info.cbSize=Marshal.SizeOf(typeof(GUITHREADINFO));GetGUIThreadInfo(0,ref info);var s=new StringBuilder(128);GetWindowText(info.focus,s,128);return s.ToString();}public static void Space(){keybd_event(0x20,0,0,UIntPtr.Zero);keybd_event(0x20,0,2,UIntPtr.Zero);}
}
'@
$fg=[Keyboard24]::GetForegroundWindow();$before=[Keyboard24]::IsWindowVisible([GuntLayout]::MonitorWindow())
try{
 [Keyboard24]::Hotkey();Start-Sleep -Milliseconds 400;$focused=[Keyboard24]::Focus();if($focused -ne '모니터'){throw ('키보드 포커스가 모니터 버튼에 도달하지 않았습니다: '+$focused)}
 [Keyboard24]::Space();$changed=$false;for($i=0;$i -lt 35;$i++){Start-Sleep -Milliseconds 200;if([Keyboard24]::IsWindowVisible([GuntLayout]::MonitorWindow()) -ne $before){$changed=$true;break}}
 if(!$changed){throw 'Space 키로 실제 위젯이 전환되지 않았습니다.'}
 Write-Json @{Time=(Get-Date).ToString('o');Status='passed';Focus=$focused;AltShiftG=$true;SpaceActualToggle=$true} (Join-Path $Root 'logs\v24-keyboard-verification.json')
}finally{if([Keyboard24]::IsWindowVisible([GuntLayout]::MonitorWindow()) -ne $before){& "$PSScriptRoot\desktop-actions.ps1" -Action monitor-toggle};[Keyboard24]::SetForegroundWindow($fg)|Out-Null}
Write-Log 'keyboard-v24-test' 'passed' '실제 Alt+Shift+G 포커스와 Space 동작을 확인했습니다.'
