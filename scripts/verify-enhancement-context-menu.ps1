. "$PSScriptRoot\enhancement-ui-common.ps1"
Add-Type @'
using System;using System.Drawing;using System.Runtime.InteropServices;using System.Threading;
public static class GuntContextInput{[DllImport("user32.dll")]static extern bool SetCursorPos(int x,int y);[DllImport("user32.dll")]static extern void mouse_event(uint f,uint x,uint y,uint d,UIntPtr e);public static void Right(int x,int y){SetCursorPos(x,y);Thread.Sleep(80);mouse_event(8,0,0,0,UIntPtr.Zero);Thread.Sleep(40);mouse_event(16,0,0,0,UIntPtr.Zero);Thread.Sleep(400);}}
'@ -ReferencedAssemblies System.Drawing
Add-Type @'
using System;using System.Collections.Generic;using System.Runtime.InteropServices;
public static class GuntHwinfoWindows{delegate bool E(IntPtr h,IntPtr p);[DllImport("user32.dll")]static extern bool EnumWindows(E f,IntPtr p);[DllImport("user32.dll")]static extern bool IsWindowVisible(IntPtr h);[DllImport("user32.dll")]static extern bool IsIconic(IntPtr h);[DllImport("user32.dll")]static extern uint GetWindowThreadProcessId(IntPtr h,out uint p);[DllImport("user32.dll")]static extern bool ShowWindowAsync(IntPtr h,int c);public static IntPtr[] Minimize(int[] ids){var wanted=new HashSet<int>(ids);var result=new List<IntPtr>();EnumWindows((h,p)=>{uint id;GetWindowThreadProcessId(h,out id);if(wanted.Contains((int)id)&&IsWindowVisible(h)&&!IsIconic(h)&&ShowWindowAsync(h,6))result.Add(h);return true;},IntPtr.Zero);return result.ToArray();}public static void Restore(IntPtr[] all){foreach(var h in all)ShowWindowAsync(h,4);}}
'@
$minimized=@()
$case=Get-Content (Join-Path $Root 'logs\enhancement-explorer-verification.json') -Raw -Encoding UTF8|ConvertFrom-Json;$dir=Join-Path $case.Fixture 'destination'
Start-Process explorer.exe -ArgumentList ('/n,"'+$dir+'"');$shell=New-Object -ComObject Shell.Application;$folder=$null
for($i=0;$i -lt 30 -and !$folder;$i++){Start-Sleep -Milliseconds 200;foreach($w in $shell.Windows()){try{if($w.Document.Folder.Self.Path -eq $dir){$folder=$w;break}}catch{}}}
if(!$folder){throw '상황 메뉴 시험 폴더 창을 찾지 못했습니다.'}
$h=[IntPtr]$folder.HWND;$folder.Document.CurrentViewMode=4;[GuntEnhanceUi]::SetWindowPos($h,[IntPtr](-1),0,0,0,0,0x13)|Out-Null
try{
 $minimized=@([GuntHwinfoWindows]::Minimize([int[]]@((Get-Process HWiNFO64 -ErrorAction SilentlyContinue).Id)))
 Start-Sleep -Milliseconds 600;$win=[Windows.Automation.AutomationElement]::FromHandle($h)
 $item=$win.FindFirst([Windows.Automation.TreeScope]::Descendants,(New-Object Windows.Automation.PropertyCondition([Windows.Automation.AutomationElement]::NameProperty,'gunt-renamed-test.txt')))
 if(!$item){throw '시험 파일의 실제 항목을 찾지 못했습니다.'}
 $r=$item.Current.BoundingRectangle;$x=[int]($r.X+[math]::Min(80,$r.Width/2));$y=[int]($r.Y+$r.Height/2)
 [GuntContextInput]::Right($x,$y)
 Save-EnhancementShot 'explorer-context'
 $names=@();$automationError=$null
 try{
  $e=[Windows.Automation.AutomationElement]::FromPoint((New-Object Windows.Point ($x+50),($y+60)));$menu=$e
  for($i=0;$i -lt 10 -and $menu -and $menu.Current.ControlType -ne [Windows.Automation.ControlType]::Menu;$i++){$menu=[Windows.Automation.TreeWalker]::ControlViewWalker.GetParent($menu)}
  if($menu){$names=@((Get-EnhancementTree $menu)|Where-Object {$_.Name}|ForEach-Object {$_.Name})}
 }catch{$automationError=$_.Exception.Message}
 Write-Json @{Time=(Get-Date).ToString('o');MenuNames=$names;AutomationError=$automationError;File='gunt-renamed-test.txt';Status=$(if(@($names|Where-Object {$_ -match '복사|속성|이름|잘라내기'}).Count -gt 1){'passed'}else{'partial'});FilesystemChanges=$false} (Join-Path $Root 'logs\enhancement-context-menu.json')
 [GuntEnhanceUi]::Tap(0x1b)
 Write-Log 'enhancement-context-menu' $(if($names.Count){'passed'}else{'partial'}) ('실제 시험 파일 우클릭 메뉴 항목 '+$names.Count+'개')
}finally{[GuntEnhanceUi]::SetWindowPos($h,[IntPtr](-2),0,0,0,0,0x13)|Out-Null;$folder.Quit();[GuntHwinfoWindows]::Restore([IntPtr[]]$minimized)}
