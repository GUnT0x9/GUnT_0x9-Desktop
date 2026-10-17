param([switch]$Before)
. "$PSScriptRoot\common.ps1"
Add-Type -AssemblyName System.Drawing,UIAutomationClient,UIAutomationTypes
Add-Type @'
using System;using System.Runtime.InteropServices;
public static class GuntFileSizeQa{
 [DllImport("user32.dll")]public static extern bool SetProcessDpiAwarenessContext(IntPtr c);
 [DllImport("user32.dll")]public static extern bool SetForegroundWindow(IntPtr h);
 [DllImport("user32.dll")]public static extern bool SetWindowPos(IntPtr h,IntPtr after,int x,int y,int w,int z,uint f);
}
'@
[GuntFileSizeQa]::SetProcessDpiAwarenessContext([IntPtr](-4))|Out-Null
$dir=Join-Path $Root 'diagnostics\filesize-fixture';New-Item -ItemType Directory -Force $dir|Out-Null
foreach($size in 1,20){$path=Join-Path $dir ($size.ToString()+'MiB.bin');if(!(Test-Path $path)){$stream=[IO.File]::Create($path);try{$stream.SetLength($size*1MB)}finally{$stream.Dispose()}}}
$shell=New-Object -ComObject Shell.Application
$folder=$null
foreach($w in $shell.Windows()){try{if($w.Document.Folder.Self.Path -eq $dir){$folder=$w;break}}catch{}}
if(!$folder){Start-Process explorer.exe -ArgumentList ('/n,"'+$dir+'"');for($i=0;$i -lt 25 -and !$folder;$i++){Start-Sleep -Milliseconds 300;foreach($w in $shell.Windows()){try{if($w.Document.Folder.Self.Path -eq $dir){$folder=$w;break}}catch{}}}}
if(!$folder){throw '검증용 탐색기 폴더 창을 찾지 못했습니다.'}
$folder.Document.CurrentViewMode=4;$folder.Refresh();Start-Sleep -Seconds 2
$h=[IntPtr]$folder.HWND
[GuntFileSizeQa]::SetForegroundWindow($h)|Out-Null;[GuntFileSizeQa]::SetWindowPos($h,[IntPtr](-1),0,0,0,0,0x13)|Out-Null
Start-Sleep -Milliseconds 400
try{
 $win=[Windows.Automation.AutomationElement]::FromHandle($h)
 $elements=@($win.FindAll([Windows.Automation.TreeScope]::Descendants,[Windows.Automation.Condition]::TrueCondition)|ForEach-Object {$pattern=$null;$value=$null;if($_.TryGetCurrentPattern([Windows.Automation.ValuePattern]::Pattern,[ref]$pattern)){$value=$pattern.Current.Value};@{Name=$_.Current.Name;Type=$_.Current.ControlType.ProgrammaticName;Value=$value}})
 $r=$win.Current.BoundingRectangle;$bmp=New-Object Drawing.Bitmap([int]$r.Width,[int]$r.Height);$graphics=[Drawing.Graphics]::FromImage($bmp)
 try{$graphics.CopyFromScreen([int]$r.X,[int]$r.Y,0,0,$bmp.Size);$bmp.Save((Join-Path $Root ('screenshots\v24-file-sizes-'+$(if($Before){'before'}else{'after'})+'.png')))}finally{$graphics.Dispose();$bmp.Dispose()}
 $pidValue=$win.Current.ProcessId;$process=Get-Process -Id $pidValue
 $modules=@($process.Modules|Where-Object {$_.ModuleName -like 'explorer-details-better-file-sizes_*'}|Select-Object -ExpandProperty ModuleName)
 $terms=@($elements|Where-Object {$_.Name -eq '크기' -and $_.Value -match '^\s*\d[\d.,]*\s*(?:MiB|KiB|GiB)\s*$'})
 $result=@{Time=(Get-Date).ToString('o');Before=[bool]$Before;Handle=$h.ToInt64();Pid=$pidValue;Modules=$modules;DisplayedValues=$terms;UiElements=$elements;Responding=$process.Responding;Fixture=@(@{File='1MiB.bin';Bytes=1048576},@{File='20MiB.bin';Bytes=20971520});Status=$(if($Before){'baseline'}elseif($modules.Count -and @($terms|Where-Object {$_.Value -eq '1.00MiB'}).Count -eq 1 -and @($terms|Where-Object {$_.Value -eq '20.0MiB'}).Count -eq 1){'passed'}else{'failed'})}
 Write-Json $result (Join-Path $Root ('logs\v24-file-sizes-'+$(if($Before){'before'}else{'after'})+'.json'))
 if(!$Before -and $result.Status -ne 'passed'){throw '탐색기 실제 용량 표기 또는 모드 DLL 검증에 실패했습니다.'}
 Write-Log 'file-size-mod-test' $result.Status ('탐색기 PID '+$pidValue+'; 실제 IEC 용량 셀 '+$terms.Count+'개')
}finally{[GuntFileSizeQa]::SetWindowPos($h,[IntPtr](-2),0,0,0,0,0x13)|Out-Null}
