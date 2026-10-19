using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.Globalization;
using System.IO;
using System.Net.NetworkInformation;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;
using System.Web.Script.Serialization;
using System.Windows.Forms;

[assembly:System.Reflection.AssemblyTitle("GUnT_0x9 Desktop")]
[assembly:System.Reflection.AssemblyProduct("GUnT_0x9 Desktop")]
[assembly:System.Runtime.Versioning.TargetFramework(".NETFramework,Version=v4.8")]
public sealed partial class GuntBar : Form {
    const uint NEW=0, REMOVE=1, QUERY=2, SET=3;
    const int CALLBACK=0x8001;
    [StructLayout(LayoutKind.Sequential)] struct RECT {public int left,top,right,bottom;}
    [StructLayout(LayoutKind.Sequential)] struct APPBARDATA {public uint cbSize;public IntPtr hWnd;public uint uCallbackMessage,uEdge;public RECT rc;public IntPtr lParam;}
    [DllImport("shell32.dll")] static extern UIntPtr SHAppBarMessage(uint msg,ref APPBARDATA data);
    [DllImport("user32.dll")] static extern bool SetProcessDpiAwarenessContext(IntPtr c);
    [DllImport("user32.dll")] static extern IntPtr MonitorFromPoint(Point p,uint f);
    [DllImport("shcore.dll")] static extern int GetDpiForMonitor(IntPtr m,int t,out uint x,out uint y);
    [DllImport("user32.dll")] static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] static extern bool GetWindowRect(IntPtr h,out RECT r);
    [DllImport("user32.dll",CharSet=CharSet.Unicode)] static extern int GetClassName(IntPtr h,StringBuilder b,int n);
    [DllImport("user32.dll",CharSet=CharSet.Unicode)] static extern uint RegisterWindowMessage(string s);
    [DllImport("user32.dll")] static extern bool DestroyIcon(IntPtr h);
    [DllImport("user32.dll")] static extern bool LockWorkStation();
    [DllImport("user32.dll")] static extern void keybd_event(byte k,byte scan,uint flags,UIntPtr extra);
    [DllImport("powrprof.dll")] static extern bool SetSuspendState(bool hibernate,bool force,bool disableWake);
    delegate bool WindowCallback(IntPtr h,IntPtr p);
    [DllImport("user32.dll")] static extern bool EnumWindows(WindowCallback c,IntPtr p);
    [DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll",CharSet=CharSet.Unicode)] static extern int GetWindowText(IntPtr h,StringBuilder b,int n);
    IntPtr MonitorHandle(){IntPtr found=IntPtr.Zero;EnumWindows(delegate(IntPtr h,IntPtr p){var c=new StringBuilder(128);var t=new StringBuilder(512);GetClassName(h,c,128);GetWindowText(h,t,512);if(c.ToString()=="RainmeterMeterWindow"&&t.ToString().Contains("GUNT-System-Monitor"))found=h;return true;},IntPtr.Zero);return found;}
    bool MonitorIsVisible(){var h=MonitorHandle();return h!=IntPtr.Zero&&IsWindowVisible(h);}
    readonly string root;
    readonly JavaScriptSerializer json=new JavaScriptSerializer();
    readonly CultureInfo korean=CultureInfo.GetCultureInfo("ko-KR");
    readonly System.Windows.Forms.Timer timer=new System.Windows.Forms.Timer();
    GuntSensorSampler sensors;
    readonly NotifyIcon tray=new NotifyIcon();
    readonly MenuStrip navigation=new MenuStrip();
    readonly FlowLayoutPanel status=new FlowLayoutPanel();
    readonly List<Font> ownedFonts=new List<Font>();
    Dictionary<string,object> theme,runtime,apps,bar;
    Color panel,text,muted,accent,border;
    Button monitorButton,wallpaperButton,focusButton,displayButton,settingsButton;
    readonly ToolTip quickTips=new ToolTip{InitialDelay=500,ReshowDelay=100,AutoPopDelay=5000};
    delegate void WinEventCallback(IntPtr hook,uint kind,IntPtr h,int obj,int child,uint thread,uint time);
    WinEventCallback moveCallback;IntPtr moveHook;
    [DllImport("user32.dll")]static extern IntPtr SetWinEventHook(uint min,uint max,IntPtr module,WinEventCallback callback,uint process,uint thread,uint flags);
    [DllImport("user32.dll")]static extern bool UnhookWinEvent(IntPtr hook);
    [DllImport("user32.dll")]static extern bool RegisterHotKey(IntPtr h,int id,uint modifiers,uint key);
    [DllImport("user32.dll")]static extern bool UnregisterHotKey(IntPtr h,int id);
    [DllImport("user32.dll")]static extern bool SetForegroundWindow(IntPtr h);
    bool registered,moving,gameMode,fullscreen,exiting,monitorBeforeFullscreen=true,monitorBeforeGame=true;
    float scale=1;int barHeight;
    Icon trayIcon;Image compactBrand;
    readonly uint taskbarCreated=RegisterWindowMessage("TaskbarCreated");
    APPBARDATA Data(){return new APPBARDATA{cbSize=(uint)Marshal.SizeOf(typeof(APPBARDATA)),hWnd=Handle,uCallbackMessage=CALLBACK,uEdge=1};}
    Dictionary<string,object> Read(string path){return json.Deserialize<Dictionary<string,object>>(GuntConfiguration.ReadShared(Path.Combine(root,path)));}
    static int Num(Dictionary<string,object> d,string k,int fallback){return d.ContainsKey(k)?Convert.ToInt32(d[k]):fallback;}
    static bool Flag(Dictionary<string,object> d,string k,bool fallback){return d.ContainsKey(k)?Convert.ToBoolean(d[k]):fallback;}
    static string Str(Dictionary<string,object> d,string k,string fallback){return d.ContainsKey(k)?Convert.ToString(d[k]):fallback;}
    int Px(float n){return (int)Math.Round(n*scale);}
    void Log(string state,string detail){try{File.AppendAllText(Path.Combine(root,"logs","bar.jsonl"),json.Serialize(new {time=DateTimeOffset.Now.ToString("o"),status=state,detail=detail})+Environment.NewLine);}catch{}}
    public GuntBar(string directory){
        root=directory;LoadConfiguration();
        FormBorderStyle=FormBorderStyle.None;ShowInTaskbar=false;StartPosition=FormStartPosition.Manual;AutoScaleMode=AutoScaleMode.None;TopMost=true;Text="GUNT Desktop — Midnight Purple";AccessibleName="GUnT_0x9 Desktop 한국어 메뉴 바";
        SetStyle(ControlStyles.AllPaintingInWmPaint|ControlStyles.OptimizedDoubleBuffer|ControlStyles.UserPaint,true);
        navigation.Name="GuntNavigation";navigation.AccessibleName="GUnT_0x9 한국어 메뉴";navigation.AutoSize=false;navigation.Dock=DockStyle.Left;navigation.LayoutStyle=ToolStripLayoutStyle.HorizontalStackWithOverflow;navigation.ShowItemToolTips=true;MainMenuStrip=navigation;Controls.Add(navigation);
        status.AutoSize=false;status.Dock=DockStyle.Right;status.WrapContents=false;status.FlowDirection=FlowDirection.LeftToRight;Controls.Add(status);
        using(var sourceIcon=new Icon(Path.Combine(root,"assets","branding","icons","gunt-app.ico"),new Size(32,32)))trayIcon=(Icon)sourceIcon.Clone();
        Icon=trayIcon;compactBrand=Image.FromFile(Path.Combine(root,"assets","branding","wordmark","gunt-logo-compact.png"));
        tray.Icon=trayIcon;tray.Text="GUnT_0x9 Desktop";tray.Visible=true;
        var menu=new ContextMenuStrip();menu.Items.Add("게임 모드 전환",null,delegate{SetGameMode(!gameMode);});menu.Items.Add("레이아웃 새로고침",null,delegate{Reload();});menu.Items.Add("프로젝트 폴더",null,delegate{Launch(root);});menu.Items.Add("상단 바 종료",null,delegate{Close();});tray.ContextMenuStrip=menu;
        tray.DoubleClick+=delegate{SetGameMode(!gameMode);};
        quickTips.OwnerDraw=true;
        quickTips.Popup+=delegate(object sender,PopupEventArgs e){using(var f=TipFont()){var size=TextRenderer.MeasureText(quickTips.GetToolTip(e.AssociatedControl),f);e.ToolTipSize=new Size(size.Width+Px(18),size.Height+Px(10));}};
        quickTips.Draw+=delegate(object sender,DrawToolTipEventArgs e){e.Graphics.Clear(panel);using(var pen=new Pen(border))e.Graphics.DrawRectangle(pen,0,0,e.Bounds.Width-1,e.Bounds.Height-1);using(var f=TipFont())TextRenderer.DrawText(e.Graphics,e.ToolTipText,f,e.Bounds,text,TextFormatFlags.HorizontalCenter|TextFormatFlags.VerticalCenter|TextFormatFlags.NoPadding);};
        timer.Interval=2000;timer.Tick+=delegate{TickDesktop();};
        Shown+=delegate{PositionBar();BuildControls();ConfigureDeveloperHotkey();timer.Start();try{moveCallback=delegate(IntPtr hook,uint kind,IntPtr h,int obj,int child,uint thread,uint time){try{if(h==GuntLayout.MonitorWindow()&&!exiting&&IsHandleCreated)BeginInvoke((Action)delegate{try{GuntLayout.SavePosition(root,h);ReflowWidget();}catch(Exception e){Log("move-error",e.Message);}});}catch(Exception e){Log("move-hook",e.Message);}};moveHook=SetWinEventHook(0xB,0xB,IntPtr.Zero,moveCallback,0,0,0);if(!RegisterHotKey(Handle,24,0x4005,0x47))Log("hotkey-unavailable","Alt+Shift+G 단축키가 이미 사용 중입니다.");sensors=new GuntSensorSampler(root,delegate{return MonitorIsVisible()||Process.GetProcessesByName("GUNT.ControlCenter").Length>0;});}catch(Exception e){Log("sensors",e.Message);}TickDesktop();Log("started","한국어 메뉴 바와 작업 영역 예약이 시작되었습니다.");};
        FormClosed+=delegate{exiting=true;timer.Stop();if(sensors!=null)sensors.Dispose();Unregister();if(moveHook!=IntPtr.Zero)UnhookWinEvent(moveHook);UnregisterHotKey(Handle,24);UnregisterHotKey(Handle,26);quickTips.Dispose();tray.Visible=false;tray.Dispose();trayIcon.Dispose();compactBrand.Dispose();foreach(var f in ownedFonts)f.Dispose();};
    }
    void LoadConfiguration(){
        theme=Read("config/theme.json");runtime=Read("config/runtime.json");apps=Read("config/apps.json");
        bar=File.Exists(Path.Combine(root,"config/topbar.json"))?Read("config/topbar.json"):(Dictionary<string,object>)theme["bar"];
        var colors=(Dictionary<string,object>)theme["palette"];
        panel=ColorTranslator.FromHtml(Convert.ToString(colors["panel"]));text=ColorTranslator.FromHtml(Convert.ToString(colors["text"]));muted=ColorTranslator.FromHtml(Convert.ToString(colors["muted"]));accent=ColorTranslator.FromHtml(Convert.ToString(colors["accent"]));border=ColorTranslator.FromHtml(Convert.ToString(colors["border"]));BackColor=panel;
    }
    void Reload(){try{LoadConfiguration();Unregister();PositionBar();BuildControls();ConfigureDeveloperHotkey();TickDesktop();Log("reload","메뉴와 위젯 레이아웃을 새로고침했습니다.");}catch(Exception e){Error("레이아웃 새로고침",e);}}
    protected override bool ShowWithoutActivation{get{return true;}}
    protected override CreateParams CreateParams{get{var p=base.CreateParams;p.ExStyle|=0x08000080;return p;}}
    protected override void WndProc(ref Message m){
        if(m.Msg==0x312&&m.WParam.ToInt32()==26)LaunchDeveloperWindow("palette");
        if(m.Msg==0x312&&m.WParam.ToInt32()==24){Show();SetForegroundWindow(Handle);if(status.Controls.Count>0)status.Controls[0].Focus();}
        if(m.Msg==0x8002&&!exiting)BeginInvoke((Action)Reload);
        if(m.Msg==CALLBACK&&m.WParam.ToInt32()==1&&!moving&&!gameMode&&!exiting)BeginInvoke((Action)PositionBar);
        if(m.Msg==(int)taskbarCreated&&!exiting){registered=false;BeginInvoke((Action)PositionBar);}
        if((m.Msg==0x007e||m.Msg==0x02e0)&&IsHandleCreated&&!exiting)BeginInvoke((Action)delegate{Unregister();PositionBar();BuildControls();});
        base.WndProc(ref m);
    }
    void Unregister(){if(registered){var d=Data();SHAppBarMessage(REMOVE,ref d);registered=false;}}
    void PositionBar(){
        if(moving||exiting||gameMode)return;moving=true;
        try{
            var s=Screen.PrimaryScreen;uint dx=96,dy=96;GetDpiForMonitor(MonitorFromPoint(new Point(s.Bounds.Left+1,s.Bounds.Top+1),2),0,out dx,out dy);scale=dx/96f;barHeight=Px(Num(bar,"height",46));
            if(registered&&Left==s.Bounds.Left&&Top==s.Bounds.Top&&Width==s.Bounds.Width&&Height==barHeight)return;
            var d=Data();if(!registered){SHAppBarMessage(NEW,ref d);registered=true;}
            d.rc=new RECT{left=s.Bounds.Left,top=s.Bounds.Top,right=s.Bounds.Right,bottom=s.Bounds.Top+barHeight};SHAppBarMessage(QUERY,ref d);d.rc.bottom=d.rc.top+barHeight;SHAppBarMessage(SET,ref d);
            Bounds=new Rectangle(d.rc.left,d.rc.top,d.rc.right-d.rc.left,barHeight);TopMost=true;UpdateWidget(s);Invalidate();
            File.WriteAllText(Path.Combine(root,"state/bar-layout.json"),json.Serialize(new{x=Left,y=Top,width=Width,height=Height,scale=scale,workTop=Screen.PrimaryScreen.WorkingArea.Top,reserved=registered}));
        }catch(Exception e){Log("failed","배치 실패: "+e.Message);}finally{moving=false;}
    }
    void ReflowWidget(){try{var info=new ProcessStartInfo("powershell.exe","-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File \""+Path.Combine(root,"scripts","update-monitor.ps1")+"\""){UseShellExecute=false,CreateNoWindow=true};Process.Start(info);}catch(Exception e){Log("layout-error",e.Message);}}
    void UpdateWidget(Screen s){ReflowWidget();}
    Font TipFont(){var fonts=(Dictionary<string,object>)theme["fonts"];return new Font(Str(fonts,"secondary","S-Core Dream 4 Regular"),Px(13),FontStyle.Regular,GraphicsUnit.Pixel);}
    Font UiFont(int size,bool bold=false){var fonts=(Dictionary<string,object>)theme["fonts"];string family=Str(fonts,bold?"heading":"ui",bold?"S-Core Dream 6 Bold":"S-Core Dream 5 Medium");var f=new Font(family,Px(size),FontStyle.Regular,GraphicsUnit.Pixel);ownedFonts.Add(f);return f;}
    void BuildControls(){
        while(navigation.Items.Count>0){var item=navigation.Items[0];navigation.Items.RemoveAt(0);item.Dispose();}while(status.Controls.Count>0){var control=status.Controls[0];status.Controls.RemoveAt(0);control.Dispose();}foreach(var f in ownedFonts)f.Dispose();ownedFonts.Clear();
        navigation.BackColor=panel;navigation.ForeColor=text;navigation.Font=UiFont(Num(bar,"fontSize",14));navigation.Padding=new Padding(Px(22),0,0,0);navigation.Height=barHeight;navigation.Width=Px(650);
        navigation.Renderer=new GuntMenuRenderer(new PurpleTable(panel,text,accent,border),compactBrand);
        var g=NavMenu("GUNT",true);Add(g,"빠른 패널",delegate{LaunchDeveloperWindow("quick-panel");});Add(g,"명령 팔레트",delegate{LaunchDeveloperWindow("palette");});
        Add(g,"GUnT_0x9 제어 센터",delegate{DesktopAction("settings","overview");});Add(g,"테마 설정",delegate{DesktopAction("settings","appearance");});Add(g,"배경화면 설정",delegate{DesktopAction("settings","wallpaper");});Add(g,"위젯 설정",delegate{DesktopAction("settings","monitor");});Add(g,"Dock 설정",delegate{DesktopAction("settings","dock");});Add(g,"레이아웃 새로고침",delegate{DesktopAction("layout-restore");});Add(g,"설정 백업",delegate{DesktopAction("backup");});Add(g,"이전 설정 복원",delegate{DesktopAction("settings","backup");});Add(g,"프로그램 정보",delegate{DesktopAction("settings","about");});
        var w=NavMenu("작업공간");PathItem(w,"파일 탐색기",Environment.GetFolderPath(Environment.SpecialFolder.UserProfile));PathItem(w,"프로젝트 폴더",root);PathItem(w,"다운로드",Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile),"Downloads"));PathItem(w,"문서",Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments));
        if(Directory.Exists(@"D:\project"))PathItem(w,"최근 프로젝트",@"D:\project");
        Add(w,"작업 폴더 열기…",delegate{using(var dialog=new FolderBrowserDialog()){dialog.Description="열 작업 폴더를 선택하세요.";if(dialog.ShowDialog()==DialogResult.OK)Launch(dialog.SelectedPath);}});
        var profileMenu=new ToolStripMenuItem("작업공간 프로필");w.DropDownItems.Add(profileMenu);profileMenu.DropDownOpening+=delegate{try{var a=Read("state/profile-active.json");profileMenu.Text="작업공간 프로필 · "+WorkspaceProfileCaption();}catch{profileMenu.Text="작업공간 프로필 · 사용자 설정";}};
        string profiles=Path.Combine(root,"config","profiles");if(Directory.Exists(profiles))foreach(string file in Directory.GetFiles(profiles,"*.json")){try{var p=Read("config/profiles/"+Path.GetFileName(file));string id=Path.GetFileNameWithoutExtension(file);Add(profileMenu,Str(p,"name",id),delegate{DesktopAction("profile-preview",id);});}catch{}}
        var favoritesMenu=new ToolStripMenuItem("고정 프로젝트");w.DropDownItems.Add(favoritesMenu);w.DropDownOpening+=delegate{favoritesMenu.DropDownItems.Clear();try{var store=Read("config/projects.json");object entries=store.ContainsKey("Projects")?store["Projects"]:store["projects"];foreach(object obj in (System.Collections.IEnumerable)entries){var project=obj as Dictionary<string,object>;if(project==null)continue;bool pinned=Flag(project,"Pinned",Flag(project,"pinned",false));if(!pinned)continue;string name=Str(project,"Name",Str(project,"name","프로젝트")),path=Str(project,"Directory",Str(project,"directory",""));if(Directory.Exists(path))PathItem(favoritesMenu,name,path);else{var missing=new ToolStripMenuItem(name+" · 경로 확인 필요"){Enabled=false};favoritesMenu.DropDownItems.Add(missing);}}}catch{}if(favoritesMenu.DropDownItems.Count==0)favoritesMenu.DropDownItems.Add(new ToolStripMenuItem("고정된 프로젝트 없음"){Enabled=false});};
        Add(w,"이전 작업공간으로 돌아가기",delegate{DesktopAction("profile-restore");});Add(w,"프로젝트 바로가기 관리",delegate{DesktopAction("settings","projects");});Add(w,"창 배치 설정",delegate{DesktopAction("settings","displays");});
        var d=NavMenu("개발");Add(d,"개발 세팅",delegate{LaunchDeveloperWindow("developer-setup");});Add(d,"개발 세션",delegate{LaunchDeveloperWindow("development-sessions");});Add(d,"WSL 환경",delegate{LaunchDeveloperWindow("wsl-environments");});AppItem(d,"윈도우 터미널","terminal");AppItem(d,"파워셸","powershell");if(apps.ContainsKey("wsl")&&File.Exists(Convert.ToString(apps["wsl"])))Add(d,"WSL 리눅스",delegate{Launch(Convert.ToString(apps["terminal"]),"-w new wsl.exe");});AppItem(d,"비주얼 스튜디오 코드","code");AppItem(d,"Git 도구","git");AppItem(d,"도커 데스크톱","docker");AppItem(d,"깃허브 데스크톱","github");
        var t=NavMenu("도구");Add(t,"작업 관리자",delegate{Launch("taskmgr.exe");});Add(t,"Windows 설정",delegate{Launch("ms-settings:");});Add(t,"장치 관리자",delegate{Launch("mmc.exe","devmgmt.msc");});Add(t,"네트워크 설정",delegate{Launch("ms-settings:network-status");});Add(t,"볼륨 믹서",delegate{Launch("ms-settings:apps-volume");});Add(t,"화면 캡처",delegate{Launch("ms-screenclip:");});Add(t,"화면 녹화 모드",delegate{DesktopAction("recording");});Add(t,"클립보드 기록",delegate{DesktopAction("clipboard");});Add(t,"시스템 정보",delegate{Launch("msinfo32.exe");});Add(t,"Windows 업데이트",delegate{Launch("ms-settings:windowsupdate");});
        var sy=NavMenu("시스템");Add(sy,"시스템 모니터 전환",delegate{DesktopAction("monitor-toggle");});Add(sy,"배경 애니메이션 전환",delegate{DesktopAction("wallpaper-toggle");});Add(sy,"게임·성능 프로필",delegate{DesktopAction("profile-preview","Gaming");});Add(sy,"시작 구성 요소 상태",delegate{DesktopAction("settings","diagnostics");});Add(sy,"구성 요소 복원",delegate{DesktopAction("startup-recover");});Add(sy,"디스플레이 설정",delegate{Launch("ms-settings:display");});Add(sy,"화면 잠금",delegate{LockWorkStation();});Add(sy,"절전",delegate{if(Confirm("절전 모드로 전환할까요?"))SetSuspendState(false,false,false);});Add(sy,"재시작",delegate{if(Confirm("열려 있는 작업을 저장했나요?\n30초 뒤 Windows를 다시 시작할까요?"))Launch("shutdown.exe","/r /t 30");});Add(sy,"종료",delegate{if(Confirm("열려 있는 작업을 저장했나요?\n30초 뒤 Windows를 종료할까요?"))Launch("shutdown.exe","/s /t 30");});Add(sy,"종료·재시작 예약 취소",delegate{Launch("shutdown.exe","/a");});
        status.BackColor=panel;status.Width=Px(238);status.Height=barHeight;status.Padding=new Padding(0,Px(3),Px(18),0);
        monitorButton=StatusLabel("모니터","monitor",delegate{DesktopAction("monitor-toggle");});
        wallpaperButton=StatusLabel("배경","wallpaper",delegate{DesktopAction("wallpaper-toggle");});
        focusButton=StatusLabel("집중","focus",delegate{DesktopAction("focus-toggle");});
        displayButton=StatusLabel("화면","display",delegate{if(displayButton.ContextMenuStrip!=null)displayButton.ContextMenuStrip.Show(displayButton,new Point(0,barHeight));});
        settingsButton=StatusLabel("설정","settings",delegate{DesktopAction("settings","overview");});
        var mon=QuickMenu();mon.Items.Add("간단히 / 자세히",null,delegate{DesktopAction("monitor-compact-toggle");});mon.Items.Add("모니터 설정",null,delegate{DesktopAction("settings","monitor");});monitorButton.ContextMenuStrip=mon;
        var wp=QuickMenu();wp.Items.Add("자동 재생",null,delegate{DesktopAction("wallpaper-play");});wp.Items.Add("일시정지",null,delegate{DesktopAction("wallpaper-pause");});wp.Items.Add("정적 배경",null,delegate{DesktopAction("wallpaper-static");});wp.Items.Add("기존 애니메이션 배경",null,delegate{DesktopAction("wallpaper-live");});wp.Items.Add("배경 밝기",null,delegate{DesktopAction("settings","wallpaper");});wp.Items.Add("Lively 설정",null,delegate{DesktopAction("wallpaper-settings");});wallpaperButton.ContextMenuStrip=wp;
        var focus=QuickMenu();focus.Items.Add("이전 상태로 돌아가기",null,delegate{DesktopAction("profile-restore");});focus.Items.Add("Windows 집중 설정",null,delegate{DesktopAction("focus-settings");});focusButton.ContextMenuStrip=focus;
        var display=QuickMenu();display.Items.Add("현재 구성 · "+Screen.AllScreens.Length+"개 화면",null,delegate{DesktopAction("settings","displays");});display.Items.Add("위젯 위치 복원",null,delegate{DesktopAction("layout-restore");});display.Items.Add("Windows 디스플레이 설정",null,delegate{Launch("ms-settings:display");});displayButton.ContextMenuStrip=display;
        TickDesktop();
    }
    string WorkspaceProfileCaption(){try{var active=Read("state/profile-active.json");string name=Str(active,"name","사용자 설정");var monitor=Read("config/monitor.json");bool paused=File.Exists(Path.Combine(root,"state","wallpaper-playback.json"))&&Flag(Read("state/wallpaper-playback.json"),"ManualPaused",false);foreach(var path in Directory.GetFiles(Path.Combine(root,"config","profiles"),"*.json")){var preset=Read("config/profiles/"+Path.GetFileName(path));if(Str(preset,"name","")!=name)continue;bool compact=Flag(preset,"compact",false);if(preset.ContainsKey("settings")){var settings=preset["settings"] as Dictionary<string,object>;if(settings!=null&&settings.ContainsKey("monitor"))compact=Flag((Dictionary<string,object>)settings["monitor"],"compact",compact);}bool match=MonitorIsVisible()==Flag(preset,"monitorVisible",false)&&Flag(monitor,"compact",false)==compact&&paused==Flag(preset,"manualPaused",false);return name+(match?" · 일치":" · 수동 변경");}return name+" · 확인 필요";}catch{return "사용자 설정";}}
    ContextMenuStrip QuickMenu(){var menu=new ContextMenuStrip();menu.BackColor=panel;menu.ForeColor=text;menu.Font=UiFont(13);menu.Renderer=new GuntMenuRenderer(new PurpleTable(panel,text,accent,border));return menu;}
    void DesktopAction(string action,string value=""){string args="-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File \""+Path.Combine(root,"scripts","desktop-actions.ps1")+"\" -Action "+action;if(!String.IsNullOrEmpty(value))args+=" -Value \""+value.Replace("\"","")+"\"";try{Process.Start(new ProcessStartInfo("powershell.exe",args){UseShellExecute=false,CreateNoWindow=true});}catch(Exception e){Error("빠른 동작",e);}}
    ToolStripMenuItem NavMenu(string id,bool brand=false){string title=brand?Str(bar,"brandText","GUnT_0x9"):id;var item=new ToolStripMenuItem(title);item.Name=id;item.AccessibleName=title;if(bar.ContainsKey("visibleMenus")){bool visible=false;foreach(object value in (System.Collections.IEnumerable)bar["visibleMenus"])if(Convert.ToString(value)==id)visible=true;item.Visible=visible;}if(brand){var font=new Font(Str(bar,"brandFont","Cambria Math"),Px(Num(bar,"brandSize",20)),FontStyle.Regular,GraphicsUnit.Pixel);ownedFonts.Add(font);item.Font=font;}item.ForeColor=brand?accent:text;item.Padding=new Padding(Px(12),0,Px(12),0);item.AutoSize=false;item.Size=new Size(brand?Px(188):TextRenderer.MeasureText(title,item.Font??navigation.Font).Width+Px(28),barHeight);navigation.Items.Add(item);item.DropDown.BackColor=panel;item.DropDown.ForeColor=text;item.DropDown.Font=UiFont(Num(bar,"dropdownFontSize",14));return item;}
    void Add(ToolStripMenuItem parent,string label,Action action){var item=new ToolStripMenuItem(label);item.Padding=new Padding(Px(10),Px(7),Px(16),Px(7));item.Click+=delegate{try{action();}catch(Exception e){Error(label,e);}};parent.DropDownItems.Add(item);}
    void PathItem(ToolStripMenuItem m,string label,string path){if(Directory.Exists(path))Add(m,label,delegate{Launch(path);});}
    void AppItem(ToolStripMenuItem m,string label,string key){if(apps.ContainsKey(key)&&apps[key]!=null&&File.Exists(Convert.ToString(apps[key])))Add(m,label,delegate{Launch(Convert.ToString(apps[key]));});}
    Button StatusLabel(string name,string icon,Action action){var button=new GuntIconButton(Path.Combine(root,"assets","icons"),icon,Px(Num(bar,"iconSize",20))){Text=name,Name=icon,AccessibleName=name,AccessibleDescription=name,AccessibleRole=AccessibleRole.PushButton,TabStop=true,Width=Px(36),Height=Px(36),Margin=new Padding(0,0,Px(8),0),ForeColor=muted,BackColor=panel,Cursor=Cursors.Hand};button.Click+=delegate{action();};quickTips.SetToolTip(button,name);status.Controls.Add(button);return button;}
    void TickDesktop(){
        PollDeveloperAutomation();
        if(monitorButton!=null){monitorButton.ForeColor=MonitorIsVisible()?accent:muted;monitorButton.Visible=Flag(bar,"showMonitor",true);wallpaperButton.Visible=Flag(bar,"showWallpaper",true);focusButton.Visible=Flag(bar,"showFocus",true);displayButton.Visible=Flag(bar,"showDisplay",true);settingsButton.Visible=Flag(bar,"showSettings",true);try{string p=Path.Combine(root,"state","profile-active.json");bool paused=false;string playback=Path.Combine(root,"state","wallpaper-playback.json");if(File.Exists(playback))paused=Flag(Read("state/wallpaper-playback.json"),"ManualPaused",false);focusButton.ForeColor=File.Exists(p)&&Str(Read("state/profile-active.json"),"name","")=="집중"&&!MonitorIsVisible()&&paused?accent:muted;}catch{}}
        bool full=FullscreenWindow();if(full!=fullscreen){fullscreen=full;if(!gameMode){if(full)monitorBeforeFullscreen=MonitorIsVisible();Visible=!full;TopMost=!full;Rainmeter(full?"!Hide":monitorBeforeFullscreen?"!Show":"!Hide");Rainmeter(full||!monitorBeforeFullscreen?"!DisableMeasureGroup Monitoring":"!EnableMeasureGroup Monitoring");}Log("fullscreen",full?"전체 화면 앱: 메뉴와 위젯 일시 중지":"데스크톱 복원");}
    }
    bool FullscreenWindow(){IntPtr h=GetForegroundWindow();if(h==IntPtr.Zero||h==Handle)return false;var name=new StringBuilder(128);GetClassName(h,name,128);string c=name.ToString();if(c=="WorkerW"||c=="Progman"||c.Contains("Shell_TrayWnd"))return false;RECT r;if(!GetWindowRect(h,out r))return false;var s=Screen.PrimaryScreen.Bounds;return r.left<=s.Left&&r.top<=s.Top&&r.right>=s.Right&&r.bottom>=s.Bottom;}
    void Rainmeter(string bang){try{if(runtime.ContainsKey("rainmeter")&&File.Exists(Convert.ToString(runtime["rainmeter"])))Process.Start(new ProcessStartInfo(Convert.ToString(runtime["rainmeter"]),bang+" \"GUNT-System-Monitor\""){UseShellExecute=false,CreateNoWindow=true});}catch(Exception e){Log("rainmeter-error",e.Message);}}
    void SetGameMode(bool active){gameMode=active;if(active){monitorBeforeGame=MonitorIsVisible();Unregister();Hide();Rainmeter("!Hide");Rainmeter("!DisableMeasureGroup Monitoring");}else{Show();PositionBar();Rainmeter(monitorBeforeGame?"!Show":"!Hide");Rainmeter(monitorBeforeGame?"!EnableMeasureGroup Monitoring":"!DisableMeasureGroup Monitoring");}tray.Text=active?"GUnT_0x9 — 게임 모드":"GUnT_0x9 Desktop";}
    void Edit(string path){Launch("notepad.exe","\""+Path.Combine(root,path)+"\"");}
    void Launch(string file,string args=""){try{Process.Start(new ProcessStartInfo(file,args){UseShellExecute=true});}catch(Exception e){Error("실행",e);}}
    void Error(string action,Exception e){Log("error",action+": "+e.Message);MessageBox.Show(action+"에 실패했습니다.\n"+e.Message,"GUnT_0x9 Desktop",MessageBoxButtons.OK,MessageBoxIcon.Warning);}
    bool Confirm(string message){return MessageBox.Show(message,"GUnT_0x9 Desktop 확인",MessageBoxButtons.YesNo,MessageBoxIcon.Question,MessageBoxDefaultButton.Button2)==DialogResult.Yes;}
    static void Hotkey(byte key){keybd_event(0x5b,0,0,UIntPtr.Zero);keybd_event(key,0,0,UIntPtr.Zero);keybd_event(key,0,2,UIntPtr.Zero);keybd_event(0x5b,0,2,UIntPtr.Zero);}
    protected override void OnPaint(PaintEventArgs e){base.OnPaint(e);using(var p=new Pen(border))e.Graphics.DrawLine(p,0,Height-1,Width,Height-1);}
    sealed class PurpleTable:ProfessionalColorTable{readonly Color panel,border;public PurpleTable(Color p,Color t,Color a,Color b){panel=p;border=b;UseSystemColors=false;}public override Color ToolStripDropDownBackground{get{return panel;}}public override Color ImageMarginGradientBegin{get{return panel;}}public override Color ImageMarginGradientMiddle{get{return panel;}}public override Color ImageMarginGradientEnd{get{return panel;}}public override Color MenuItemSelected{get{return Color.FromArgb(35,35,43);}}public override Color MenuItemBorder{get{return border;}}public override Color MenuBorder{get{return border;}}public override Color MenuItemSelectedGradientBegin{get{return panel;}}public override Color MenuItemSelectedGradientEnd{get{return panel;}}public override Color MenuItemPressedGradientBegin{get{return panel;}}public override Color MenuItemPressedGradientEnd{get{return panel;}}}
    [STAThread]public static void Main(string[] args){bool created;using(var mutex=new Mutex(true,"Local\\GUNTDesktopBar",out created)){if(!created)return;SetProcessDpiAwarenessContext(new IntPtr(-4));AppContext.SetSwitch("Switch.UseLegacyAccessibilityFeatures",false);AppContext.SetSwitch("Switch.UseLegacyAccessibilityFeatures.2",false);AppContext.SetSwitch("Switch.UseLegacyAccessibilityFeatures.3",false);Application.EnableVisualStyles();Application.SetCompatibleTextRenderingDefault(false);string directory=args.Length>0?args[0]:Directory.GetParent(AppDomain.CurrentDomain.BaseDirectory.TrimEnd('\\')).FullName;try{Application.Run(new GuntBar(directory));}catch(Exception e){File.AppendAllText(Path.Combine(directory,"logs/bar-fatal.txt"),DateTimeOffset.Now+" "+e+Environment.NewLine);}}}
}

public sealed class GuntIconButton:Button {
 readonly Image glyph;readonly int iconSize;bool hover,pressed;
 public GuntIconButton(string folder,string name,int size){iconSize=size;int best=20;foreach(int n in new[]{20,25,30,35,40,60})if(Math.Abs(n-size)<Math.Abs(best-size))best=n;glyph=Image.FromFile(Path.Combine(folder,name+"-normal-"+best+".png"));FlatStyle=FlatStyle.Flat;FlatAppearance.BorderSize=0;UseVisualStyleBackColor=false;SetStyle(ControlStyles.UserPaint|ControlStyles.OptimizedDoubleBuffer,true);}
 protected override AccessibleObject CreateAccessibilityInstance(){return new IconAccessible(this);}
 sealed class IconAccessible:ControlAccessibleObject{readonly GuntIconButton button;public IconAccessible(GuntIconButton b):base(b){button=b;}public override AccessibleRole Role{get{return AccessibleRole.PushButton;}}public override string DefaultAction{get{return "누르기";}}public override void DoDefaultAction(){button.PerformClick();}public override string Name{get{return button.AccessibleName;}set{button.AccessibleName=value;}}}
 protected override void OnMouseEnter(EventArgs e){hover=true;Invalidate();base.OnMouseEnter(e);}protected override void OnMouseLeave(EventArgs e){hover=false;Invalidate();base.OnMouseLeave(e);}protected override void OnMouseDown(MouseEventArgs e){pressed=true;Invalidate();base.OnMouseDown(e);}protected override void OnMouseUp(MouseEventArgs e){pressed=false;Invalidate();base.OnMouseUp(e);}
 protected override void OnPaint(PaintEventArgs e){e.Graphics.Clear(pressed?Color.FromArgb(35,35,43):hover?Color.FromArgb(27,27,36):BackColor);using(var attributes=new System.Drawing.Imaging.ImageAttributes()){var c=Enabled?ForeColor:Color.FromArgb(80,80,90);var matrix=new System.Drawing.Imaging.ColorMatrix(new float[][]{new float[]{0,0,0,0,0},new float[]{0,0,0,0,0},new float[]{0,0,0,0,0},new float[]{0,0,0,1,0},new float[]{c.R/255f,c.G/255f,c.B/255f,0,1}});attributes.SetColorMatrix(matrix);e.Graphics.DrawImage(glyph,new Rectangle((Width-iconSize)/2,(Height-iconSize)/2,iconSize,iconSize),0,0,glyph.Width,glyph.Height,GraphicsUnit.Pixel,attributes);}if(Focused)ControlPaint.DrawFocusRectangle(e.Graphics,new Rectangle(2,2,Width-4,Height-4),ForeColor,BackColor);}
 protected override void Dispose(bool disposing){if(disposing)glyph.Dispose();base.Dispose(disposing);}
}

public sealed class GuntMenuRenderer:ToolStripProfessionalRenderer {
 readonly Image brand;
 public GuntMenuRenderer(ProfessionalColorTable table):this(table,null){}
 public GuntMenuRenderer(ProfessionalColorTable table,Image logo):base(table){brand=logo;}
 protected override void OnRenderItemText(ToolStripItemTextRenderEventArgs e){if(e.Item.Name=="GUNT"&&brand!=null){float scale=e.Item.Height/42f;float width=e.Item.Width-20*scale;float height=width*brand.Height/brand.Width;e.Graphics.InterpolationMode=System.Drawing.Drawing2D.InterpolationMode.HighQualityBicubic;e.Graphics.DrawImage(brand,(e.Item.Width-width)/2,(e.Item.Height-height)/2,width,height);return;}base.OnRenderItemText(e);}
}
