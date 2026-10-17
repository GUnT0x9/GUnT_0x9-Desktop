. "$PSScriptRoot\common.ps1"
Add-Type -AssemblyName System.Drawing
Add-Type @'
using System;using System.Runtime.InteropServices;using System.Text;
public static class GuntGraphTestNative {
 public delegate bool Callback(IntPtr h,IntPtr p);
 [StructLayout(LayoutKind.Sequential)]public struct RECT{public int left,top,right,bottom;}
 [DllImport("user32.dll")]static extern bool EnumWindows(Callback c,IntPtr p);
 [DllImport("user32.dll",CharSet=CharSet.Unicode)]static extern int GetWindowText(IntPtr h,StringBuilder s,int n);
 [DllImport("user32.dll")]public static extern bool GetWindowRect(IntPtr h,out RECT r);
 [DllImport("user32.dll")]public static extern bool SetProcessDpiAwarenessContext(IntPtr c);
 public static IntPtr Window(){IntPtr found=IntPtr.Zero;EnumWindows(delegate(IntPtr h,IntPtr p){var t=new StringBuilder(512);GetWindowText(h,t,512);if(t.ToString().Contains("GUNT-Graph-Test"))found=h;return true;},IntPtr.Zero);return found;}
}
'@
[GuntGraphTestNative]::SetProcessDpiAwarenessContext([IntPtr](-4))|Out-Null
$r=Get-Content (Join-Path $Root 'config\runtime.json') -Raw -Encoding UTF8|ConvertFrom-Json
$folder=Join-Path (Split-Path $r.skin -Parent) 'GUNT-Graph-Test';New-Item -ItemType Directory -Force $folder|Out-Null
$ini=@('[Rainmeter]','Update=100','AccurateText=1','DynamicWindowSize=1','OnRefreshAction=[!Move 150 150][!ZPos 2]','','[Panel]','Meter=Image','W=360','H=850','SolidColor=14,14,18','','[Heading]','Meter=String','X=14','Y=10','FontFace=Segoe UI','FontSize=11','FontColor=244,244,245','AntiAlias=1','Text=그래프 고정값 검증 · 실제 CPU 아님')
$values=@(0,10,25,50,75,90,100)
for($i=0;$i -lt $values.Count;$i++){
 $v=$values[$i];$y=55+$i*110
 $ini+=@('',('[Value'+$i+']'),'Measure=Calc',('Formula='+$v),'MinValue=0','MaxValue=100','',('[Label'+$i+']'),'Meter=String',('MeasureName=Value'+$i),'X=18',('Y='+($y+25)),'FontFace=Consolas','FontSize=12','FontColor=244,244,245','Text=%1%','',('[Graph'+$i+']'),'Meter=Line',('MeasureName=Value'+$i),'X=120',('Y='+$y),'W=220','H=80','LineColor=167,139,250','SolidColor=21,21,28','LineWidth=1','AutoScale=0','AntiAlias=1')
}
[IO.File]::WriteAllText((Join-Path $folder 'GUNT-Graph-Test.ini'),($ini -join "`r`n"),[Text.Encoding]::Unicode)
$results=@()
try{
 Start-Process $r.rainmeter -ArgumentList '!RefreshApp' -Wait|Out-Null
 Start-Process $r.rainmeter -ArgumentList '!ActivateConfig "GUNT-Graph-Test" "GUNT-Graph-Test.ini"' -Wait|Out-Null
 Start-Sleep -Milliseconds 1900
 $window=[GuntGraphTestNative]::Window();if($window -eq [IntPtr]::Zero){throw '검증용 그래프 창을 찾을 수 없습니다.'}
 $rect=New-Object GuntGraphTestNative+RECT;[GuntGraphTestNative]::GetWindowRect($window,[ref]$rect)|Out-Null
 $bmp=New-Object Drawing.Bitmap 360,850;$graphics=[Drawing.Graphics]::FromImage($bmp)
 try{$graphics.CopyFromScreen($rect.left,$rect.top,0,0,$bmp.Size)}finally{$graphics.Dispose()}
 $bmp.Save((Join-Path $Root 'screenshots\v23-graph-controlled.png'))
 for($i=0;$i -lt $values.Count;$i++){
  $ys=@();$top=55+$i*110
  for($x=330;$x -le 336;$x++){for($y=0;$y -lt 80;$y++){$c=$bmp.GetPixel($x,$top+$y);if($c.R -gt 65 -and $c.B -gt 110 -and $c.B -gt $c.R+25 -and $c.G -gt 50){$ys+=$y}}}
  $expected=$values[$i]
  $observed=if($ys.Count){100*(79-($ys|Measure-Object -Average).Average)/79}elseif($expected -eq 0){0}else{$null}
  $status=if($null -ne $observed -and [math]::Abs($observed-$expected) -le 3){'passed'}else{'failed'}
  $results+=[pscustomobject]@{ExpectedPercent=$expected;ObservedPercent=$(if($null -ne $observed){[math]::Round($observed,2)}else{$null});TracePixels=$ys.Count;Status=$status;Note=$(if(!$ys.Count -and $expected -eq 0){'0% 기준선에 겹침'}else{'실제 Rainmeter Line 미터 화면 픽셀'})}
 }
 $bmp.Dispose()
}finally{Start-Process $r.rainmeter -ArgumentList '!DeactivateConfig "GUNT-Graph-Test"' -Wait|Out-Null}
Write-Json @{Time=(Get-Date).ToString('o');Cases=$results;Source='실제 Rainmeter 렌더러, 별도 테스트 스킨';LiveReadings=$false;Options='Measure MinValue=0 MaxValue=100 / Line AutoScale=0';TolerancePercent=3} (Join-Path $Root 'logs\v23-graph-verification.json')
$results|ConvertTo-Json -Depth 5
if(@($results|Where-Object Status -eq 'failed').Count){throw '그래프 고정 범위 렌더링 검사 실패 항목이 있습니다.'}
