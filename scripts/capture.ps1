param([string]$Name='after')
. "$PSScriptRoot\common.ps1"
Add-Type -AssemblyName System.Windows.Forms,System.Drawing
if(!('GuntCapture' -as [type])){Add-Type '[System.Runtime.InteropServices.DllImport("user32.dll")] public static extern bool SetProcessDpiAwarenessContext(System.IntPtr c);' -Name GuntCapture -Namespace Native}
[Native.GuntCapture]::SetProcessDpiAwarenessContext([IntPtr](-4))|Out-Null
New-Item -ItemType Directory -Force (Join-Path $Root 'screenshots')|Out-Null
$b=[Windows.Forms.SystemInformation]::VirtualScreen
$bmp=New-Object Drawing.Bitmap $b.Width,$b.Height
$g=[Drawing.Graphics]::FromImage($bmp)
try{$g.CopyFromScreen($b.Location,[Drawing.Point]::Empty,$b.Size);$file=Join-Path $Root ("screenshots\"+$Name+'.png');$bmp.Save($file);Write-Log 'screenshot' 'saved' $file}finally{$g.Dispose();$bmp.Dispose()}
$primary=[Windows.Forms.Screen]::PrimaryScreen.Bounds
$bmp=New-Object Drawing.Bitmap $primary.Width,$primary.Height
$g=[Drawing.Graphics]::FromImage($bmp)
try{$g.CopyFromScreen($primary.Location,[Drawing.Point]::Empty,$primary.Size);$bmp.Save((Join-Path $Root ("screenshots\"+$Name+'-primary.png')))}finally{$g.Dispose();$bmp.Dispose()}
