. "$PSScriptRoot\common.ps1"
Add-Type @'
using System;using System.Runtime.InteropServices;
public static class GuntRestoreTest {
 [DllImport("user32.dll",CharSet=CharSet.Unicode)] static extern IntPtr FindWindow(string c,string t);
 [DllImport("user32.dll")] static extern bool PostMessage(IntPtr h,uint m,IntPtr w,IntPtr l);
 public static bool CloseBar(){return PostMessage(FindWindow(null,"GUNT Desktop \u2014 Midnight Purple"),0x10,IntPtr.Zero,IntPtr.Zero);}
}
'@
$before=@(Get-Process 'GUNT-Bar','Rainmeter','Flow.Launcher','windhawk' -ErrorAction SilentlyContinue|Select-Object ProcessName,Id)
$bar=Get-Process 'GUNT-Bar' -ErrorAction Stop|Select-Object -First 1
[GuntRestoreTest]::CloseBar()|Out-Null
if(!$bar.WaitForExit(5000)){throw '복원 검사를 위해 상단 바를 정상 종료하지 못했습니다.'}
$run=(Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run').GUNTDesktop
Start-Process "$env:WINDIR\System32\wscript.exe" -ArgumentList ('"'+(Join-Path $Root 'scripts\start-hidden.vbs')+'"')|Out-Null
$limit=(Get-Date).AddSeconds(20)
do{Start-Sleep -Milliseconds 500;$new=Get-Process 'GUNT-Bar' -ErrorAction SilentlyContinue|Where-Object {$_.Path -eq (Join-Path $Root 'bin\GUNT-Bar.exe')}}while(!$new -and (Get-Date) -lt $limit)
Start-Sleep -Seconds 2
$after=@(Get-Process 'GUNT-Bar','Rainmeter','Flow.Launcher','windhawk' -ErrorAction SilentlyContinue|Select-Object ProcessName,Id,Responding)
$duplicates=@($after|Group-Object ProcessName|Where-Object Count -gt 1)
$status=if($new -and $new.Id -ne $bar.Id -and !$duplicates.Count -and $after.Count -eq 4 -and $run -like '*start-hidden.vbs*'){'passed'}else{'failed'}
Write-Json @{Time=(Get-Date).ToString('o');Status=$status;RunValue=$run;Before=$before;After=$after;DuplicateProcesses=@($duplicates|ForEach-Object Name);Limitations='실제 로그인 때 쓰는 VBS를 직접 실행해 종료된 상단 바 복원과 중복 실행 방지를 검사했습니다. 재부팅·로그아웃 검사는 실행하지 않았습니다.'} (Join-Path $Root 'logs\v21-startup-verification.json')
Write-Log 'startup-recovery' $status ('상단 바 PID '+$bar.Id+' → '+$new.Id+'; 복원 후 구성 요소 '+$after.Count+'개')
