. "$PSScriptRoot\common.ps1"
Add-Type -AssemblyName System.Windows.Forms,System.Drawing
if(!('GuntNativeInfo' -as [type])) {
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System; using System.Runtime.InteropServices;
public static class GuntNativeInfo {
 [DllImport("user32.dll")] public static extern bool SetProcessDpiAwarenessContext(IntPtr c);
 [DllImport("shcore.dll")] public static extern int GetDpiForMonitor(IntPtr m,int t,out uint x,out uint y);
 [DllImport("user32.dll")] public static extern IntPtr MonitorFromPoint(System.Drawing.Point p,uint f);
 [StructLayout(LayoutKind.Sequential)] public class MEMORYSTATUSEX {public uint length=64, load;public ulong total,avail,page,availpage,virtualtotal,virtualavail,ext;}
 [DllImport("kernel32.dll")] public static extern bool GlobalMemoryStatusEx(MEMORYSTATUSEX m);
}
'@
}
[GuntNativeInfo]::SetProcessDpiAwarenessContext([IntPtr](-4))|Out-Null
$screens=@([Windows.Forms.Screen]::AllScreens|ForEach-Object {
    $dx=[uint32]0;$dy=[uint32]0;$pt=New-Object Drawing.Point ($_.Bounds.X+1),($_.Bounds.Y+1)
    [GuntNativeInfo]::GetDpiForMonitor([GuntNativeInfo]::MonitorFromPoint($pt,2),0,[ref]$dx,[ref]$dy)|Out-Null
    [pscustomobject]@{Device=$_.DeviceName;Primary=$_.Primary;X=$_.Bounds.X;Y=$_.Bounds.Y;Width=$_.Bounds.Width;Height=$_.Bounds.Height;WorkX=$_.WorkingArea.X;WorkY=$_.WorkingArea.Y;WorkWidth=$_.WorkingArea.Width;WorkHeight=$_.WorkingArea.Height;Dpi=$dx;Scale=($dx/96.0)}
})
$memory=New-Object GuntNativeInfo+MEMORYSTATUSEX
[GuntNativeInfo]::GlobalMemoryStatusEx($memory)|Out-Null
$apps=@(Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*','HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*','HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*' -ErrorAction SilentlyContinue|Where-Object {$_.DisplayName -match 'Rainmeter|Windhawk|Flow Launcher|PowerToys|Translucent|ExplorerPatcher|StartAllBack|Start11|Nexus|RocketDock|Visual Studio Code|GitHub Desktop|Chrome|Firefox|Brave|Everything'}|Select-Object DisplayName,DisplayVersion,InstallLocation)
$cpu=Get-ItemProperty 'HKLM:\HARDWARE\DESCRIPTION\System\CentralProcessor\0'
$video=Get-ItemProperty 'HKLM:\HARDWARE\DEVICEMAP\VIDEO' -ErrorAction SilentlyContinue
$gpu=@(foreach($property in $video.PSObject.Properties|Where-Object {$_.Name -match '^\\Device\\Video[0-9]+$'}){
 $devicePath=[string]$property.Value
 if($devicePath -like '\Registry\Machine\*'){Get-ItemProperty ('HKLM:\'+$devicePath.Substring(18)) -ErrorAction SilentlyContinue|Select-Object DriverDesc,DriverVersion}
})
$gpu=@($gpu|Where-Object DriverDesc|Sort-Object DriverDesc,DriverVersion -Unique)
$fonts=New-Object Drawing.Text.InstalledFontCollection
$result=[ordered]@{Timestamp=(Get-Date).ToString('o');HostBridge='WSL to local Windows';User=$env:USERNAME;Profile=$env:USERPROFILE;Documents=[Environment]::GetFolderPath('MyDocuments');Admin=(Test-Admin);OS=(Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'|Select-Object ProductName,DisplayVersion,CurrentBuild,UBR);CPU=$cpu.ProcessorNameString;LogicalProcessors=[Environment]::ProcessorCount;RAMBytes=$memory.total;GPU=$gpu;Monitors=$screens;Apps=$apps;AppPaths=(Get-AppPaths);Processes=@(Get-Process|Where-Object {$_.ProcessName -match 'Rainmeter|Windhawk|Flow|PowerToys|Translucent|ExplorerPatcher|StartAllBack|Start11|Nexus|RocketDock|explorer|WindowsTerminal'}|Select-Object Id,ProcessName,Path,CPU,WorkingSet64,Responding);Fonts=@($fonts.Families.Name|Where-Object {$_ -match 'Segoe UI|JetBrains|Consolas'});Wallpaper=(Get-ItemProperty 'HKCU:\Control Panel\Desktop'|Select-Object Wallpaper,WallpaperStyle,TileWallpaper);DefaultBrowser=(Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\https\UserChoice' -ErrorAction SilentlyContinue).ProgId;RestorePointStatus='일반 사용자 권한이므로 복원 지점은 생성하지 않았습니다. 파일·레지스트리 백업을 사용합니다.'}
Write-Json $result (Join-Path $Root 'logs\inspection.json')
Write-Log 'inspect' 'passed' "$($screens.Count) displays; $($result.CPU); $([math]::Round($memory.total/1GB)) GiB RAM"
$result|ConvertTo-Json -Depth 8
