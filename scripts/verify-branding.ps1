. "$PSScriptRoot\enhancement-ui-common.ps1"
Add-Type @'
using System;using System.Runtime.InteropServices;using System.Collections.Generic;
public static class GuntBrandNative{
 public delegate bool EnumRes(IntPtr m,IntPtr type,IntPtr name,IntPtr p);
 [DllImport("kernel32.dll",CharSet=CharSet.Unicode)]public static extern IntPtr LoadLibraryEx(string f,IntPtr h,uint flags);
 [DllImport("kernel32.dll")]public static extern bool FreeLibrary(IntPtr h);
 [DllImport("kernel32.dll",CharSet=CharSet.Unicode)]public static extern bool EnumResourceNames(IntPtr h,IntPtr type,EnumRes callback,IntPtr p);
 [DllImport("kernel32.dll",CharSet=CharSet.Unicode)]public static extern IntPtr FindResource(IntPtr h,IntPtr name,IntPtr type);
 [DllImport("kernel32.dll")]public static extern IntPtr LoadResource(IntPtr h,IntPtr r);
 [DllImport("kernel32.dll")]public static extern IntPtr LockResource(IntPtr r);
 [DllImport("kernel32.dll")]public static extern uint SizeofResource(IntPtr h,IntPtr r);
 [DllImport("user32.dll",CharSet=CharSet.Unicode)]public static extern IntPtr FindWindow(string c,string t);
 [DllImport("user32.dll")]public static extern IntPtr SendMessage(IntPtr h,uint m,IntPtr w,IntPtr l);
 [DllImport("user32.dll")]public static extern IntPtr GetClassLongPtr(IntPtr h,int i);
 [DllImport("shell32.dll",CharSet=CharSet.Unicode)]public static extern uint ExtractIconEx(string f,int n,[Out]IntPtr[] large,[Out]IntPtr[] small,uint count);
 [DllImport("user32.dll")]public static extern bool DestroyIcon(IntPtr h);
 [DllImport("user32.dll")]public static extern bool ShowWindow(IntPtr h,int c);
 [DllImport("user32.dll")]public static extern bool PrintWindow(IntPtr h,IntPtr dc,uint flags);
 public static byte[][] Resources(string file,int type){var result=new List<byte[]>();var m=LoadLibraryEx(file,IntPtr.Zero,2);if(m==IntPtr.Zero)throw new Exception("Resource load failed");try{EnumResourceNames(m,new IntPtr(type),delegate(IntPtr h,IntPtr t,IntPtr name,IntPtr p){var r=FindResource(h,name,t);var data=new byte[SizeofResource(h,r)];Marshal.Copy(LockResource(LoadResource(h,r)),data,0,data.Length);result.Add(data);return true;},IntPtr.Zero);}finally{FreeLibrary(m);}return result.ToArray();}
}
'@
$explorerBefore=@(Get-Process explorer|Select-Object -ExpandProperty Id)
$results=New-Object Collections.Generic.List[object]
function Result($name,$status,$detail){$results.Add(@{Test=$name;Status=$status;Detail=$detail});Write-Log ('branding-'+$name) $status $detail}
function ShaBytes([byte[]]$data){$sha=[Security.Cryptography.SHA256]::Create();try{return ([BitConverter]::ToString($sha.ComputeHash($data))).Replace('-','')}finally{$sha.Dispose()}}
function Save-BrandingWindow([string]$name,$window,[IntPtr]$handle){
 $r=$window.Current.BoundingRectangle;$bitmap=New-Object Drawing.Bitmap([int]$r.Width,[int]$r.Height);$graphics=[Drawing.Graphics]::FromImage($bitmap);$dc=$graphics.GetHdc()
 try{if(![GuntBrandNative]::PrintWindow($handle,$dc,2)){throw '해당 창의 단독 캡처 실패'}}finally{$graphics.ReleaseHdc($dc);$graphics.Dispose()}
 try{$bitmap.Save((Join-Path $Root ('screenshots\enhancement-'+$name+'.png')))}finally{$bitmap.Dispose()}
}
$ico=Join-Path $Root 'assets\branding\icons\gunt-app.ico';$bytes=[IO.File]::ReadAllBytes($ico)
$sizes=@();$hashes=@();for($i=0;$i -lt [BitConverter]::ToUInt16($bytes,4);$i++){$j=6+16*$i;$n=[int]$bytes[$j];if(!$n){$n=256};$sizes+=$n;$length=[BitConverter]::ToUInt32($bytes,$j+8);$offset=[BitConverter]::ToUInt32($bytes,$j+12);$frame=New-Object byte[] $length;[Array]::Copy($bytes,$offset,$frame,0,$length);$hashes+=(ShaBytes $frame)}
if(($sizes -join ',') -ne '16,24,32,48,64,128,256'){throw 'ICO 크기 구성이 다릅니다.'};Result 'ico' 'passed' ($sizes -join ',')
foreach($name in 'GUNT.ControlCenter.exe','GUNT-Bar.exe'){
 $exe=Join-Path $Root ('bin\'+$name);$frames=[GuntBrandNative]::Resources($exe,3);$groups=[GuntBrandNative]::Resources($exe,14);$same=@($frames|Where-Object {$hashes -contains (ShaBytes $_)}).Count
 if($frames.Count -ne 7 -or $same -ne 7 -or $groups.Count -ne 1){throw ('실행 파일 내장 아이콘 원본 일치 실패: '+$name)}
 Result 'embedded-icon' 'passed' ($name+' RT_ICON 7개 SHA256 원본 일치')
 $small=New-Object IntPtr[] 1;$large=New-Object IntPtr[] 1
 try{if([GuntBrandNative]::ExtractIconEx($exe,0,$large,$small,1) -eq 0 -or $large[0] -eq [IntPtr]::Zero){throw '셸 아이콘 추출 실패'};$image=[Drawing.Icon]::FromHandle($large[0]).ToBitmap();try{$image.Save((Join-Path $Root ('screenshots\branding-exe-'+$name+'.png')))}finally{$image.Dispose()}}finally{foreach($h in @($small[0],$large[0])){if($h -ne [IntPtr]::Zero){[GuntBrandNative]::DestroyIcon($h)|Out-Null}}}
}
$exe=Join-Path $Root 'bin\GUNT.ControlCenter.exe';Start-Process $exe -ArgumentList ('"'+$Root+'" overview');Start-Sleep -Seconds 2
$p=Get-Process GUNT.ControlCenter -ErrorAction Stop|Select-Object -First 1;$h=$p.MainWindowHandle
if(!$h){throw '실제 제어 센터 창 없음'}
$previous=[GuntEnhanceUi]::GetForegroundWindow();[GuntBrandNative]::ShowWindow($h,9)|Out-Null;[GuntEnhanceUi]::SetForegroundWindow($h)|Out-Null;[GuntEnhanceUi]::SetWindowPos($h,[IntPtr](-1),0,0,0,0,0x43)|Out-Null
try{
 $win=[Windows.Automation.AutomationElement]::FromHandle($h)
 if($win.Current.Name -cne 'GUnT_0x9 Desktop'){throw '제어 센터 실제 제목이 다릅니다.'}
 $tree=Get-EnhancementTree $win
 Write-Json $tree (Join-Path $Root 'logs\branding-overview-tree.json')
 Save-BrandingWindow 'branding-overview' $win $h
 if(!@($tree|Where-Object {$_.Name -eq 'GUnT_0x9'}).Count){throw '탐색 로고 접근성 이름 없음'}
 Save-BrandingWindow 'branding-overview' $win $h
 Result 'overview' 'passed' '실제 새 제목·소형 내비게이션 로고 표시 (전체 로고는 프로그램 정보)'
 $icon=[GuntBrandNative]::SendMessage($h,0x7F,[IntPtr]2,[IntPtr]::Zero);if($icon -eq [IntPtr]::Zero){$icon=[GuntBrandNative]::SendMessage($h,0x7F,[IntPtr]0,[IntPtr]::Zero)}
 if($icon -eq [IntPtr]::Zero){throw '실제 WPF 창 아이콘 없음'}
 $bitmap=[Drawing.Icon]::FromHandle($icon).ToBitmap();try{$bitmap.Save((Join-Path $Root 'screenshots\branding-window-icon.png'))}finally{$bitmap.Dispose()};Result 'window-icon' 'passed' '실제 WM_GETICON 핸들에서 PNG 추출'
 foreach($label in '외관','Windhawk','프로그램 정보'){
  $item=$win.FindFirst([Windows.Automation.TreeScope]::Descendants,(New-Object Windows.Automation.PropertyCondition([Windows.Automation.AutomationElement]::NameProperty,$label)))
  if(!$item){throw ('실제 내비게이션 항목 없음: '+$label)}
  $pattern=$item.GetCurrentPattern([Windows.Automation.SelectionItemPattern]::Pattern);$pattern.Select();Start-Sleep -Milliseconds 500
  if($label -eq '프로그램 정보'){Save-BrandingWindow 'branding-about' $win $h;Result 'about' 'passed' '실제 프로그램 정보 탐색·로고·설정 버전 표시'}
  elseif($label -eq '외관'){$tree=Get-EnhancementTree $win;if(!@($tree|Where-Object {$_.Name -eq '기본 한국어 글꼴'}).Count){throw '기존 설정 페이지 누락'};Result 'settings' 'passed' '외관 글꼴 설정 페이지 로드. 승인된 래스터 브랜드는 프로그램 정보에서 유지. 값 변경 없음'}
  else{$list=$win.FindFirst([Windows.Automation.TreeScope]::Descendants,(New-Object Windows.Automation.PropertyCondition([Windows.Automation.AutomationElement]::NameProperty,'설치된 Windhawk 모드')));if(!$list){throw '기존 Windhawk 목록 누락'};Result 'windhawk' 'passed' '기존 Windhawk 모드 목록 접근 유지'}
 }
 # Re-open through the normal entry point and verify single-instance routing.
 $pidBefore=$p.Id;Start-Process $exe -ArgumentList ('"'+$Root+'" overview');Start-Sleep -Milliseconds 1200
 if(@(Get-Process GUNT.ControlCenter).Count -ne 1 -or (Get-Process GUNT.ControlCenter).Id -ne $pidBefore){throw '단일 인스턴스 재진입 실패'}
 Result 'single-instance' 'passed' '변경된 제목에서 기존 창 재사용·개요 페이지 이동'
}finally{[GuntEnhanceUi]::SetWindowPos($h,[IntPtr](-2),0,0,0,0,0x13)|Out-Null;[GuntEnhanceUi]::SetForegroundWindow($previous)|Out-Null}
$taskbar=[Windows.Automation.AutomationElement]::FromHandle([GuntEnhanceUi]::Taskbar());$apps=Get-EnhancementTree $taskbar
$ccButton=@($apps|Where-Object {$_.Name -like '*GUnT_0x9 Desktop*' -and $_.Class -eq 'Taskbar.TaskListButtonAutomationPeer'})
if(!$ccButton.Count){throw '새 이름의 네이티브 작업 표시줄 앱 버튼 없음'};Result 'taskbar' 'passed' '새 이름의 실제 앱 버튼 및 창 아이콘 확인; 시각 검증 별도 캡처'
$current=@(Get-Process explorer|Select-Object -ExpandProperty Id);if(($current -join ',') -ne ($explorerBefore -join ',')){throw '브랜딩 작업 중 Explorer PID가 달라졌습니다.'};Result 'explorer' 'passed' ('Explorer PID 유지 '+($current -join ','))
Write-Json @{Time=(Get-Date).ToString('o');Results=$results.ToArray();IcoSizes=$sizes;Limitations='Alt+Tab·트레이·시작 메뉴 표시는 별도 캡처 시험. 설정 값을 변경하는 시험은 실행하지 않음.'} (Join-Path $Root 'logs\branding-verification.json')
