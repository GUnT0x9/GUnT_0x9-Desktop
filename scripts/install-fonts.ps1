. "$PSScriptRoot\common.ps1"
Add-Type -AssemblyName System.Drawing
Add-Type @'
using System;using System.Runtime.InteropServices;
public static class GuntFontInstall {
 [DllImport("gdi32.dll",CharSet=CharSet.Unicode)]public static extern int AddFontResourceEx(string path,uint flags,IntPtr reserved);
 [DllImport("user32.dll",CharSet=CharSet.Unicode)]static extern IntPtr SendMessageTimeout(IntPtr h,uint m,IntPtr w,IntPtr l,uint f,uint timeout,out IntPtr result);
 public static void Notify(){IntPtr value;SendMessageTimeout(new IntPtr(0xffff),0x1D,IntPtr.Zero,IntPtr.Zero,2,1000,out value);}
}
'@
$manifest=Get-Content (Join-Path $Root 'assets\fonts\manifest.json') -Raw -Encoding UTF8|ConvertFrom-Json
$folder=Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts';New-Item -ItemType Directory -Force $folder|Out-Null
$key='HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts';if(!(Test-Path $key)){New-Item $key -Force|Out-Null}
$statePath=Join-Path $Root 'state\v24-fonts.json'
$state=if(Test-Path $statePath){Get-Content $statePath -Raw -Encoding UTF8|ConvertFrom-Json}else{[pscustomobject]@{Time=(Get-Date).ToString('o');Entries=@()}}
foreach($font in $manifest){
 $source=Join-Path $Root ('assets\fonts\'+$font.file)
 if((Get-FileHash $source).Hash -ne $font.sha256){throw ('공식 자산 해시가 일치하지 않습니다: '+$font.file)}
 $dest=Join-Path $folder ('GUNT-'+$font.file);$name='GUNT '+$font.family+' (OpenType)'
 if(!@($state.Entries|Where-Object Path -eq $dest).Count){
  $existing=Get-ItemProperty $key -ErrorAction SilentlyContinue;$had=$existing.PSObject.Properties.Name -contains $name
  $backup=$null;if(Test-Path $dest){$backup=Join-Path $Root ('backups\fonts-v24\'+$font.file);New-Item -ItemType Directory -Force (Split-Path $backup -Parent)|Out-Null;Copy-Item $dest $backup -Force}
  $state.Entries=@($state.Entries)+[pscustomobject]@{Path=$dest;Name=$name;PreviousRegistered=$had;PreviousValue=$(if($had){$existing.$name}else{$null});PreviousFile=$backup}
  Write-Json $state $statePath
 }
 if(!(Test-Path $dest) -or (Get-FileHash $dest).Hash -ne $font.sha256){Copy-Item $source $dest -Force}
 New-ItemProperty $key -Name $name -Value $dest -PropertyType String -Force|Out-Null
 if([GuntFontInstall]::AddFontResourceEx($dest,0,[IntPtr]::Zero) -eq 0){throw ('글꼴을 로드하지 못했습니다: '+$font.family)}
}
[GuntFontInstall]::Notify()
$families=@((New-Object Drawing.Text.InstalledFontCollection).Families|ForEach-Object {$_.Name;$_.GetName(1033)})
$missing=@($manifest|Where-Object {$families -notcontains $_.family})
Write-Json @{Time=(Get-Date).ToString('o');Families=@($manifest.family);Missing=@($missing.family);Status=$(if(!$missing.Count){'passed'}else{'failed'})} (Join-Path $Root 'logs\v24-font-verification.json')
if($missing.Count){throw ('등록 확인에 실패했습니다: '+($missing.family -join ', '))}
Write-Log 'fonts-v24' 'passed' '현재 사용자용 글꼴 5종을 등록했습니다. Windows 기본·아이콘 글꼴 매핑은 유지됩니다.'
