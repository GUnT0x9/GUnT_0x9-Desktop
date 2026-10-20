using System;using System.Collections.Generic;using System.Collections.ObjectModel;using System.ComponentModel;using System.Globalization;using System.Linq;using Gunt.ControlCenter.Models;using Gunt.ControlCenter.Services;
namespace Gunt.ControlCenter.ViewModels {
 public sealed class MainViewModel:INotifyPropertyChanged{
  public readonly DesktopService Service;public ObservableCollection<SettingField> Fields{get;private set;}string status="설정은 적용 버튼을 눌러 저장합니다.";public string Status{get{return status;}set{status=value;if(PropertyChanged!=null)PropertyChanged(this,new PropertyChangedEventArgs("Status"));}}public event PropertyChangedEventHandler PropertyChanged;
  public MainViewModel(string root){Service=new DesktopService(root);Fields=new ObservableCollection<SettingField>();}
  void Field(string config,string key,string label,string kind,string help="",params string[] options){var val=DesktopService.Get(Service.Read(config),key);var original=Service.Json.Serialize(val);if(kind=="volumes")val=String.Join(", ",((System.Collections.IEnumerable)val).Cast<object>().Select(x=>Convert.ToString(x)));Fields.Add(new SettingField{Config=config,Key=key,Label=label,Kind=kind,Help=help,Options=options,Value=val,Original=original});}
  public void Page(string page){Fields.Clear();
   if(page=="appearance"||page=="topbar"){
    Field("theme","fonts.ui","기본 한국어 글꼴","choice","Windows 시스템 아이콘 글꼴에는 적용하지 않습니다.","S-Core Dream 5 Medium","S-Core Dream 4 Regular","Segoe UI Variable");
    Field("theme","fonts.secondary","보조 글꼴","choice","","S-Core Dream 4 Regular","S-Core Dream 5 Medium","Segoe UI Variable");Field("theme","fonts.latin","영문 모델명 글꼴","choice","","Manrope Medium","Manrope","Segoe UI Variable");
    Field("theme","palette.accent","강조색","text","#RRGGBB 형식. GUnT_0x9 상단 바와 위젯 범위에 적용합니다.");
    if(page=="topbar"){Field("topbar","fontSize","메뉴 글자 크기 (DIP)","int");Field("topbar","iconSize","빠른 동작 아이콘 (DIP)","int");
    foreach(var p in new[]{new[]{"showMonitor","모니터 아이콘"},new[]{"showWallpaper","배경 아이콘"},new[]{"showFocus","집중 아이콘"},new[]{"showDisplay","화면 아이콘"},new[]{"showSettings","설정 아이콘"}})Field("topbar",p[0],p[1],"bool");}
   }else if(page=="dock"){
    Field("dock","height","Dock 높이 (DIP)","int");Field("dock","iconSize","아이콘 크기 (DIP)","int");Field("dock","hitArea","앱 버튼 폭 (DIP)","int");Field("dock","padding","좌우 안쪽 여백 (DIP)","int");Field("dock","bottomMargin","아래 여백 (DIP)","int");Field("dock","controlGap","컨트롤 Dock 간격 (DIP)","int");Field("dock","radius","모서리 반경 (DIP)","int");
   }else if(page=="monitor"){
    Field("monitor","compact","간단히 표시","bool");Field("monitor","showCpuGraph","CPU 그래프 표시","bool","숫자는 유지하고 그래프 공간만 접습니다.");Field("monitor","showNetworkGraph","네트워크 그래프 표시","bool","CPU 그래프와 독립적으로 저장합니다.");Field("monitor","graphHistorySeconds","그래프 시간 범위 (초)","int-choice","실제 시간축의 표시 범위입니다.","30","60","120");Field("monitor","updateMs","갱신 간격","int-choice","간격이 짧을수록 더 자주 갱신합니다.","1000","2000","5000");Field("monitor","networkScaleMode","네트워크 축","choice","동적 축은 현재 최대값에 맞춥니다. 고정 축은 입력한 상한을 유지합니다.","dynamic","fixed");Field("monitor","networkFixedMaxBytesPerSecond","고정 축 상한 (B/s)","int");Field("monitor","width","모니터 너비 (DIP)","int","300–520");Field("monitor","radius","모서리 반경 (DIP)","int","권장 6");foreach(var p in new[]{new[]{"showCpu","CPU"},new[]{"showRam","메모리"},new[]{"showGpu","GPU"},new[]{"showDisk","저장공간"},new[]{"showNetwork","네트워크"},new[]{"showBattery","배터리"},new[]{"showUptime","가동 시간"}})Field("monitor",p[0],p[1]+" 표시","bool");Field("monitor","storageVolumes","표시할 볼륨","volumes","C:, D: 중 쉼표로 구분. 연결된 고정 볼륨만 표시합니다.");
   }else if(page=="commands"||page=="shortcuts"){if(page=="shortcuts")Field("ux","commandPaletteShortcut","창 내부 명령 찾기","choice","GUNT 창 안에서만 사용합니다.","Ctrl+K","Ctrl+Shift+P","Disabled");Field("ux","globalPaletteShortcut","전역 명령 팔레트 단축키","choice","상단 바가 실행 중일 때 동작합니다. 다른 앱과 충돌하면 등록하지 않습니다.","Ctrl+Alt+Space","Ctrl+Shift+Space","Disabled");
   }else if(page=="automation"){
    Field("ux","commandPaletteShortcut","명령 찾기 단축키","choice","제어 센터 안에서만 동작합니다. Flow Launcher·Windows 전역 단축키는 변경하지 않습니다.","Ctrl+K","Ctrl+Shift+P","Disabled");
    Field("startup","enabled","로그인 시 데스크톱 복원","bool");Field("startup","restoreWallpaper","현재 배경 복원","bool");Field("startup","restoreLayout","위젯 배치 복원","bool");Field("startup","delaySeconds","로그인 복원 지연 (초)","int","0–10. 기존 사용자 시작 항목은 보존합니다.");
   }else if(page=="displays"){
    Field("monitor","position.locked","위젯 위치 잠금","bool","해제하면 제목 영역을 잡아 이동할 수 있습니다.");Field("monitor","position.mode","배치 모드","choice","auto: 주 모니터 우측 / manual: 마지막 이동 위치","auto","manual");Field("monitor","margin","자동 배치 오른쪽 여백 (DIP)","int");Field("monitor","topGap","자동 배치 위 여백 (DIP)","int");
   }else if(page=="sensors"){
    Field("sensors","provider","온도 공급자","choice","HWiNFO에서 선택한 실제 가젯 값만 읽습니다.","auto","none");Field("sensors","staleSeconds","온도 유효 시간 (초)","int","공급자 레지스트리 수정 시각 기준. 권장 10.");
   }
  }
 }
}
