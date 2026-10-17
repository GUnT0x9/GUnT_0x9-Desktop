param([string]$Name='enhancement-desktop-final')
. "$PSScriptRoot\common.ps1"
$shell=New-Object -ComObject Shell.Application
Add-Type @'
using System;using System.Collections.Generic;using System.Runtime.InteropServices;
public static class GuntCaptureOverlays {
 public delegate bool Callback(IntPtr h,IntPtr p);
 [DllImport("user32.dll")] static extern bool EnumWindows(Callback c,IntPtr p);
 [DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr h);
 [DllImport("user32.dll")] static extern bool IsIconic(IntPtr h);
 [DllImport("user32.dll",EntryPoint="GetWindowLongPtrW")] static extern IntPtr GetWindowLongPtr(IntPtr h,int index);
 [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr h,out uint pid);
 [DllImport("user32.dll",CharSet=CharSet.Unicode)] static extern int GetWindowTextLength(IntPtr h);
 [DllImport("user32.dll")] static extern bool ShowWindow(IntPtr h,int command);
 [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
 [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
 public static IntPtr[] HideOverlays(int[] keep){
  var kept=new HashSet<int>(keep);var hidden=new List<IntPtr>();
  EnumWindows(delegate(IntPtr h,IntPtr p){
   uint pid;GetWindowThreadProcessId(h,out pid);
   if(!kept.Contains((int)pid)&&IsWindowVisible(h)&&!IsIconic(h)&&GetWindowTextLength(h)>0&&(GetWindowLongPtr(h,-20).ToInt64()&8)!=0){hidden.Add(h);ShowWindow(h,0);}
   return true;
  },IntPtr.Zero);return hidden.ToArray();
 }
 public static void Restore(IntPtr[] windows){if(windows!=null)foreach(var h in windows)ShowWindow(h,4);}
}
'@
$foreground=[GuntCaptureOverlays]::GetForegroundWindow()
$hidden=@()
try{
    $shell.MinimizeAll()
    $monitor=Get-Content (Join-Path $Root 'config\monitor.json') -Raw -Encoding UTF8|ConvertFrom-Json
    if($monitor.visible){
      Add-Type -Path (Join-Path $Root 'bin\Gunt.Configuration.dll')
      $widget=[GuntLayout]::MonitorWindow();if($widget -ne [IntPtr]::Zero){[GuntCaptureOverlays]::Restore([IntPtr[]]@($widget))}
    }
    $livelyDir=Join-Path $env:LOCALAPPDATA 'Programs\Lively Wallpaper'
    $keep=@(Get-Process|Where-Object {$_.ProcessName -in 'GUNT-Bar','Rainmeter','explorer' -or ($_.Path -and $_.Path.StartsWith($livelyDir,[StringComparison]::OrdinalIgnoreCase))}|Select-Object -ExpandProperty Id)
    $hidden=[GuntCaptureOverlays]::HideOverlays([int[]]$keep)
    Start-Sleep -Milliseconds 1500
    & "$PSScriptRoot\capture.ps1" -Name $Name
}finally{
    $shell.UndoMinimizeAll()
    [GuntCaptureOverlays]::Restore([IntPtr[]]$hidden)
    [GuntCaptureOverlays]::SetForegroundWindow($foreground)|Out-Null
}
