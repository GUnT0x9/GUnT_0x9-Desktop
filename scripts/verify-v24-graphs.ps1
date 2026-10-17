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
 $ini+=@('',('[Value'+$i+']'),'Measure=Calc',('Formula='+$v),'MinValue=0','MaxValue=100','',('[Label'+$i+']'),'Meter=String',('MeasureName=Value'+$i),'X=18',('Y='+($y+25)),'FontFace=Consolas','FontSize=12','FontColor=244,244,245','Text=%1%','',('[Graph'+$i+']'),'Meter=Shape','X=120',('Y='+$y),'W=220','H=80','Shape=Path Data | StrokeWidth 1.5 | Stroke Color 167,139,250 | Fill Color 0,0,0,0','Data=0,80 | LineTo 220,80','DynamicVariables=1')
}
[IO.File]::WriteAllText((Join-Path $folder 'GUNT-Graph-Test.ini'),($ini -join "`r`n"),[Text.Encoding]::Unicode)
$module=Join-Path $Root 'rainmeter\GUNT-System-Monitor\@Resources\Graph.lua'
[IO.File]::WriteAllText((Join-Path $folder 'Graph.lua'),[IO.File]::ReadAllText($module),[Text.Encoding]::Unicode)
$lua="function Initialize()`r`n local Graph=dofile(SKIN:GetVariable('CURRENTPATH')..'Graph.lua')`r`n local values={0,10,25,50,75,90,100}`r`n for i,value in ipairs(values) do local samples={{time=0,cpu=value},{time=60,cpu=value}};SKIN:Bang('!SetOption','Graph'..(i-1),'Data',Graph.Path(samples,'cpu',100,220,80,60,60)) end`r`n local sample={{time=0,down=512,up=128},{time=60,down=1536,up=256}};assert(Graph.Axis(sample)==2048);assert(Graph.Path(sample,'down',2048,220,80,60,60):match('0.00,60.00'));assert(Graph.Path(sample,'down',2048,220,80,60,60):match('220.00,20.00'));assert(Graph.Path(sample,'up',2048,220,80,60,60):match('220.00,70.00'));SKIN:Bang('!SetOption','TestMarker','SolidColor','0,255,0,255')`r`nend"
[IO.File]::WriteAllText((Join-Path $folder 'Fixture.lua'),$lua,[Text.Encoding]::Unicode)
$ini+=@('','[TestMarker]','Meter=Image','X=345','Y=10','W=10','H=10','SolidColor=255,0,0,255')
$ini+=@('','[Fixture]','Measure=Script','ScriptFile=Fixture.lua')
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
 $bmp.Save((Join-Path $Root 'screenshots\v24-graph-controlled.png'))
 for($i=0;$i -lt $values.Count;$i++){
  $ys=@();$top=55+$i*110
  for($x=330;$x -le 336;$x++){for($y=0;$y -lt 80;$y++){$c=$bmp.GetPixel($x,$top+$y);if($c.R -gt 65 -and $c.B -gt 110 -and $c.B -gt $c.R+25 -and $c.G -gt 50){$ys+=$y}}}
  $expected=$values[$i]
  $observed=if($ys.Count){100*(79-($ys|Measure-Object -Average).Average)/79}elseif($expected -eq 0){0}else{$null}
  $status=if($null -ne $observed -and [math]::Abs($observed-$expected) -le 3){'passed'}else{'failed'}
  $results+=[pscustomobject]@{ExpectedPercent=$expected;ObservedPercent=$(if($null -ne $observed){[math]::Round($observed,2)}else{$null});TracePixels=$ys.Count;Status=$status;Note=$(if(!$ys.Count -and $expected -eq 0){'0% 기준선에 겹침'}else{'실제 Rainmeter Shape / 실제 운영 Graph.lua 화면 픽셀'})}
 }
 if($bmp.GetPixel(350,15).G -lt 200){throw '공통 그래프 모듈의 네트워크 재투영 수학 검증이 실패했습니다.'}
 $bmp.Dispose()
}finally{Start-Process $r.rainmeter -ArgumentList '!DeactivateConfig "GUNT-Graph-Test"' -Wait|Out-Null}
Write-Json @{Time=(Get-Date).ToString('o');Cases=$results;Source='실제 Rainmeter 렌더러, 별도 테스트 스킨';LiveReadings=$false;Options='운영 Graph.lua 고정 0–100% 경로; 네트워크 원시 이력 재투영 Lua assert';TolerancePercent=3} (Join-Path $Root 'logs\v24-graph-verification.json')
$results|ConvertTo-Json -Depth 5
if(@($results|Where-Object Status -eq 'failed').Count){throw '그래프 고정 범위 렌더링 검사 실패 항목이 있습니다.'}
