. "$PSScriptRoot\common.ps1"
Add-Type -AssemblyName System.Drawing
Add-Type -Path (Join-Path $Root 'bin\Gunt.Configuration.dll')
Add-Type '[System.Runtime.InteropServices.DllImport("user32.dll")]public static extern bool SetProcessDpiAwarenessContext(System.IntPtr p);' -Name MonitorShot -Namespace GuntV24
[GuntV24.MonitorShot]::SetProcessDpiAwarenessContext([IntPtr](-4))|Out-Null
$shell=New-Object -ComObject Shell.Application
try{
 $shell.MinimizeAll();Start-Sleep -Milliseconds 800
 $r=New-Object GuntLayout+RECT;if(![GuntLayout]::GetWindowRect([GuntLayout]::MonitorWindow(),[ref]$r)){throw '위젯 창을 찾지 못했습니다.'}
 $bmp=New-Object Drawing.Bitmap ($r.Right-$r.Left),($r.Bottom-$r.Top);$g=[Drawing.Graphics]::FromImage($bmp)
 try{$g.CopyFromScreen($r.Left,$r.Top,0,0,$bmp.Size);$bmp.Save((Join-Path $Root 'screenshots\v24-system-monitor-thermal.png'))}finally{$g.Dispose();$bmp.Dispose()}
}finally{$shell.UndoMinimizeAll()}
Write-Log 'monitor-screenshot' 'saved' '현재 실제 모니터의 위젯 영역을 직접 캡처했습니다.'
