. "$PSScriptRoot\common.ps1"
Add-Type -AssemblyName System.Windows.Forms,System.Drawing,UIAutomationClient,UIAutomationTypes
if(!('GuntEnhanceUi' -as [type])){Add-Type @'
using System;using System.Drawing;using System.Runtime.InteropServices;using System.Threading;
public static class GuntEnhanceUi {
 [DllImport("user32.dll")]public static extern bool SetProcessDpiAwarenessContext(IntPtr p);
 [DllImport("user32.dll",CharSet=CharSet.Unicode)]static extern IntPtr FindWindow(string c,string t);
 [DllImport("user32.dll")]public static extern bool SetForegroundWindow(IntPtr h);
 [DllImport("user32.dll")]public static extern IntPtr GetForegroundWindow();
 [DllImport("user32.dll")]public static extern bool SetWindowPos(IntPtr h,IntPtr a,int x,int y,int w,int z,uint f);
 [DllImport("user32.dll")]public static extern bool GetWindowRect(IntPtr h,out RECT r);
 [StructLayout(LayoutKind.Sequential)]public struct RECT{public int Left,Top,Right,Bottom;}
 [DllImport("user32.dll")]static extern IntPtr WindowFromPoint(Point p);
 [DllImport("user32.dll")]static extern IntPtr GetAncestor(IntPtr h,uint a);
 public static IntPtr At(int x,int y){return GetAncestor(WindowFromPoint(new Point(x,y)),2);}
 [DllImport("user32.dll")]static extern bool GetCursorPos(out Point p);
 [DllImport("user32.dll")]static extern bool SetCursorPos(int x,int y);
 [DllImport("user32.dll")]static extern void mouse_event(uint f,uint x,uint y,int d,UIntPtr e);
 [DllImport("user32.dll")]public static extern void keybd_event(byte k,byte s,uint f,UIntPtr e);
 public static IntPtr Taskbar(){return FindWindow("Shell_TrayWnd",null);}
 [StructLayout(LayoutKind.Sequential)]struct K{public ushort vk,scan;public uint flags,time;public UIntPtr extra;}
 [StructLayout(LayoutKind.Sequential)]struct M{public int x,y;public uint data,flags,time;public UIntPtr extra;}
 [StructLayout(LayoutKind.Explicit)]struct I{[FieldOffset(0)]public uint type;[FieldOffset(8)]public K keyboard;[FieldOffset(8)]public M mouse;}
 [DllImport("user32.dll",SetLastError=true)]static extern uint SendInput(uint count,I[] input,int size);
 public static void Key(byte k,bool down){var i=new I{type=1,keyboard=new K{vk=k,flags=(down?0u:2u)|((k==0x5b||k==0x5c)?1u:0u)}};if(SendInput(1,new[]{i},Marshal.SizeOf(typeof(I)))!=1)throw new System.ComponentModel.Win32Exception(Marshal.GetLastWin32Error());Thread.Sleep(90);}
 public static void Text(string text){foreach(char c in text){var down=new I{type=1,keyboard=new K{scan=c,flags=4}};var up=new I{type=1,keyboard=new K{scan=c,flags=6}};if(SendInput(2,new[]{down,up},Marshal.SizeOf(typeof(I)))!=2)throw new System.ComponentModel.Win32Exception(Marshal.GetLastWin32Error());Thread.Sleep(45);}}
 public static void Chord(byte mod,byte k){Key(mod,true);Key(k,true);Key(k,false);Key(mod,false);}
 public static void Tap(byte k){Key(k,true);Key(k,false);}
 public static void Click(int x,int y){Point p;GetCursorPos(out p);SetCursorPos(x,y);Thread.Sleep(80);mouse_event(2,0,0,0,UIntPtr.Zero);Thread.Sleep(40);mouse_event(4,0,0,0,UIntPtr.Zero);Thread.Sleep(150);SetCursorPos(p.X,p.Y);}
 public static void DoubleClick(int x,int y){Point p;GetCursorPos(out p);SetCursorPos(x,y);Thread.Sleep(60);for(int i=0;i<2;i++){mouse_event(2,0,0,0,UIntPtr.Zero);Thread.Sleep(35);mouse_event(4,0,0,0,UIntPtr.Zero);Thread.Sleep(80);}Thread.Sleep(150);SetCursorPos(p.X,p.Y);}
 public static void MouseAt(int x,int y){SetCursorPos(x,y);Thread.Sleep(100);}
 public static Point Cursor(){Point p;GetCursorPos(out p);return p;}
}
'@ -ReferencedAssemblies System.Drawing}
[GuntEnhanceUi]::SetProcessDpiAwarenessContext([IntPtr](-4))|Out-Null
function Get-EnhancementWindows { @([Windows.Automation.AutomationElement]::RootElement.FindAll([Windows.Automation.TreeScope]::Children,[Windows.Automation.Condition]::TrueCondition)) }
function Get-EnhancementTree($Window){@($Window.FindAll([Windows.Automation.TreeScope]::Descendants,[Windows.Automation.Condition]::TrueCondition)|ForEach-Object {try{@{Name=$_.Current.Name;Class=$_.Current.ClassName;Id=$_.Current.AutomationId;Type=$_.Current.ControlType.ProgrammaticName;Offscreen=$_.Current.IsOffscreen;Rect=$_.Current.BoundingRectangle.ToString()}}catch{}})}
function Save-EnhancementShot([string]$Name,$Rectangle=$null){
 if(!$Rectangle){$Rectangle=[Windows.Forms.Screen]::PrimaryScreen.Bounds}
 $bmp=New-Object Drawing.Bitmap([int]$Rectangle.Width,[int]$Rectangle.Height);$graphics=[Drawing.Graphics]::FromImage($bmp)
 try{$graphics.CopyFromScreen([int]$Rectangle.X,[int]$Rectangle.Y,0,0,$bmp.Size);$bmp.Save((Join-Path $Root ('screenshots\enhancement-'+$Name+'.png')))}finally{$graphics.Dispose();$bmp.Dispose()}
}
function Open-EnhancementStart {
 $taskbar=[Windows.Automation.AutomationElement]::FromHandle([GuntEnhanceUi]::Taskbar())
 $start=$taskbar.FindFirst([Windows.Automation.TreeScope]::Descendants,(New-Object Windows.Automation.PropertyCondition([Windows.Automation.AutomationElement]::AutomationIdProperty,'StartButton')))
 if(!$start){throw '네이티브 시작 버튼을 찾지 못했습니다.'}
 $watch=[Diagnostics.Stopwatch]::StartNew();$screen=[Windows.Forms.Screen]::PrimaryScreen.Bounds
 $candidate=[Windows.Automation.AutomationElement]::FromHandle([GuntEnhanceUi]::At([int]($screen.X+$screen.Width/2),[int]($screen.Y+$screen.Height/2)))
 if(@((Get-Process StartMenuExperienceHost -ErrorAction SilentlyContinue).Id) -notcontains $candidate.Current.ProcessId){
  $r=$start.Current.BoundingRectangle;[GuntEnhanceUi]::Click([int]($r.X+$r.Width/2),[int]($r.Y+$r.Height/2))
 }
 $win=$null;$screen=[Windows.Forms.Screen]::PrimaryScreen.Bounds
 for($i=0;$i -lt 25 -and !$win;$i++){
  Start-Sleep -Milliseconds 80
  $h=[GuntEnhanceUi]::At([int]($screen.X+$screen.Width/2),[int]($screen.Y+$screen.Height/2))
  $candidate=[Windows.Automation.AutomationElement]::FromHandle($h)
  if(@((Get-Process StartMenuExperienceHost -ErrorAction SilentlyContinue).Id) -contains $candidate.Current.ProcessId){$win=$candidate}
 }
 if(!$win){Write-Json @{Button=$start.Current.BoundingRectangle.ToString();ProbeHandle=$h.ToInt64();CandidateName=$candidate.Current.Name;CandidatePid=$candidate.Current.ProcessId;StartPid=@((Get-Process StartMenuExperienceHost).Id);Screen=$screen.ToString()} (Join-Path $Root 'logs\enhancement-start-probe-failure.json');throw '시작 메뉴가 실제 화면에 나타나지 않았습니다.'}
 $script:StartOpenMs=$watch.ElapsedMilliseconds;return $win
}
