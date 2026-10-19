using System;
using System.Collections.Generic;
using System.Linq;
using System.Windows;
using System.Windows.Automation;
using System.Windows.Controls;
using System.Windows.Input;
using Gunt.ControlCenter.Models;

namespace Gunt.ControlCenter.Views
{
    public sealed partial class MainWindow
    {
        DevelopmentSession sessionDraft;
        string sessionOriginal;
        bool changingSession;
        StackPanel sessionStepEditor;
        TextBlock sessionEditStatus;
        Button sessionSave;
        readonly HashSet<string> expandedSessionSteps = new HashSet<string>();
        readonly System.Windows.Threading.DispatcherTimer sessionPreviewTimer = new System.Windows.Threading.DispatcherTimer();
        bool sessionPreviewHooked;
        readonly Dictionary<string, SessionStepView> sessionStepViews = new Dictionary<string, SessionStepView>();
        sealed class SessionStepView
        {
            public Border Row; public Expander Editor; public TextBlock Title, Target;
            public CheckBox Enabled; public Button Up, Down;
        }
        System.Windows.DataTemplate sessionListTemplate;

        bool SessionDraftDirty
        {
            get { return page == "development-sessions" && sessionDraft != null && vm.Service.Json.Serialize(sessionDraft) != sessionOriginal; }
        }

        void BuildDevelopmentSessions()
        {
            sessionDraft = null;
            sessionOriginal = null;
            sessionStepViews.Clear();
            CaptureSessionProject();
            var layout = new Grid();
            layout.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(224) });
            layout.ColumnDefinitions.Add(new ColumnDefinition());
            layout.RowDefinitions.Add(new RowDefinition());
            layout.RowDefinitions.Add(new RowDefinition());
            var presets = new StackPanel { Margin = new Thickness(0, 0, 16, 0) };
            var editor = new StackPanel();
            Grid.SetColumn(editor, 1);
            layout.Children.Add(presets);
            layout.Children.Add(editor);
            content.Children.Add(layout);

            sessionList = DataList("개발 세션 목록", 272);
            if(sessionListTemplate==null){
                var body=new FrameworkElementFactory(typeof(StackPanel));
                var title=new FrameworkElementFactory(typeof(TextBlock));title.SetBinding(TextBlock.TextProperty,new System.Windows.Data.Binding());body.AppendChild(title);
                var summary=new FrameworkElementFactory(typeof(TextBlock));summary.SetBinding(TextBlock.TextProperty,new System.Windows.Data.Binding("Summary"));summary.SetValue(TextBlock.ForegroundProperty,Muted);summary.SetValue(TextBlock.FontSizeProperty,12.0);body.AppendChild(summary);
                sessionListTemplate=new DataTemplate{VisualTree=body};
            }
            sessionList.ItemTemplate=sessionListTemplate;
            presets.Children.Add(sessionList);
            var compactPicker=new ComboBox{Visibility=Visibility.Collapsed,Margin=new Thickness(0,0,0,8)};
            AutomationProperties.SetName(compactPicker,"개발 세션 선택");
            compactPicker.SetBinding(ItemsControl.ItemsSourceProperty,new System.Windows.Data.Binding("ItemsSource"){Source=sessionList});
            compactPicker.SetBinding(System.Windows.Controls.Primitives.Selector.SelectedItemProperty,new System.Windows.Data.Binding("SelectedItem"){Source=sessionList,Mode=System.Windows.Data.BindingMode.TwoWay});
            presets.Children.Add(compactPicker);
            var presetActions = new WrapPanel();
            presets.Children.Add(presetActions);
            LocalButton(presetActions, "새 세션", () =>
            {
                if (!ConfirmSessionDraft()) return;
                changingSession = true;
                sessionList.SelectedItem = null;
                changingSession = false;
                OpenSessionDraft(new DevelopmentSession { Id = "user-" + Guid.NewGuid().ToString("N"), Name = "새 개발 세션" }, true);
            });
            LocalButton(presetActions, "복제", () =>
            {
                if (sessionDraft == null || !ConfirmSessionDraft() || sessionDraft == null) return;
                var copy = CloneSession(sessionDraft);
                copy.Id = "user-" + Guid.NewGuid().ToString("N"); copy.Name += " 복사"; copy.Builtin = false;
                OpenSessionDraft(copy, true);
            });
            LocalButton(presetActions, "삭제", () =>
            {
                if (sessionDraft == null || sessionDraft.Builtin) { vm.Status = "사용자가 만든 세션을 선택하세요."; return; }
                if (Decide("세션 삭제", sessionDraft.Name + "을 목록에서 삭제할까요?", "삭제", "취소") != 0) return;
                if(vm.Service.Sessions().Presets.Any(item=>item.Id==sessionDraft.Id))vm.Service.DeleteSession(sessionDraft.Id);
                sessionDraft = null; ReloadSessionList(null);
            });
            sessionList.SelectionChanged += delegate
            {
                if (changingSession) return;
                var next = sessionList.SelectedItem as DevelopmentSession;
                if (next == null) return;
                if (!ConfirmSessionDraft())
                {
                    changingSession = true;
                    sessionList.SelectedItem = sessionList.Items.Cast<DevelopmentSession>().FirstOrDefault(p => p.Id == sessionDraft.Id);
                    changingSession = false;
                    return;
                }
                changingSession=true;sessionList.SelectedItem=sessionList.Items.Cast<DevelopmentSession>().FirstOrDefault(item=>item.Id==next.Id);changingSession=false;OpenSessionDraft(next, false);
            };

            sessionEditorHost = editor;
            ReloadSessionList(null);
            layout.SizeChanged += delegate
            {
                bool narrow = layout.ActualWidth < 680;
                layout.ColumnDefinitions[0].Width = narrow ? new GridLength(1, GridUnitType.Star) : new GridLength(224);
                layout.ColumnDefinitions[1].Width = narrow ? new GridLength(0) : new GridLength(1, GridUnitType.Star);
                Grid.SetColumn(editor, narrow ? 0 : 1);
                Grid.SetRow(editor, narrow ? 1 : 0);
                sessionList.Visibility=narrow?Visibility.Collapsed:Visibility.Visible;compactPicker.Visibility=narrow?Visibility.Visible:Visibility.Collapsed;
                sessionList.Height = 272;
            };
            if (!sessionPreviewHooked)
            {
                sessionPreviewHooked = true;
                sessionPreviewTimer.Interval = TimeSpan.FromMilliseconds(180);
                sessionPreviewTimer.Tick += delegate { sessionPreviewTimer.Stop(); RefreshSessionPreview(); };
                Closed += delegate { sessionPreviewTimer.Stop(); };
            }
        }

        ProjectEntry sessionProject;DeveloperPreferences sessionPreferences;string sessionProjectError;
        StackPanel sessionEditorHost;
        DevelopmentSession CloneSession(DevelopmentSession value)
        {
            return vm.Service.Json.Deserialize<DevelopmentSession>(vm.Service.Json.Serialize(value));
        }

        void ReloadSessionList(string id)
        {
            changingSession = true;
            var presets = vm.Service.Sessions().Presets;
            sessionList.ItemsSource = presets;
            sessionList.SelectedItem = presets.FirstOrDefault(s => s.Id == id) ?? presets.FirstOrDefault();
            changingSession = false;
            var selected = sessionList.SelectedItem as DevelopmentSession;
            if (selected != null) OpenSessionDraft(selected, false);
            else { sessionEditorHost.Children.Clear(); sessionEditorHost.Children.Add(new TextBlock { Text = "새 세션을 만들어 실행 단계를 추가하세요.", Foreground = Muted }); }
        }

        void OpenSessionDraft(DevelopmentSession original, bool unsaved)
        {
            sessionStepViews.Clear();
            sessionDraft = CloneSession(original);
            sessionOriginal = unsaved ? "" : vm.Service.Json.Serialize(sessionDraft);
            changingSession = true;
            sessionEditorHost.Children.Clear();
            var name = EditBox(sessionEditorHost, "세션 이름", sessionDraft.Name);
            name.TextChanged += delegate { sessionDraft.Name = name.Text; SessionEdited(); };
            var mode = Choice(sessionEditorHost, "실행 방식", new[] { new ChoiceOption("sequential", "순차 요청"), new ChoiceOption("independent", "독립 요청") }, sessionDraft.Mode);
            mode.SelectionChanged += delegate(object sender,SelectionChangedEventArgs args) {string value=SelectedChoice(args);if(value!=null){sessionDraft.Mode=value;SessionEdited();}};
            var settingsSection=new Expander{Header="세션 실행 설정",Margin=new Thickness(0,4,0,12)};
            settingsSection.Expanded+=delegate{if(settingsSection.Content==null)settingsSection.Content=CreateSessionSettings();};sessionEditorHost.Children.Add(settingsSection);
            sessionStepEditor = new StackPanel();
            sessionEditorHost.Children.Add(sessionStepEditor);
            RenderSessionSteps();
            var toolbar = new WrapPanel();
            sessionEditorHost.Children.Add(toolbar);
            LocalButton(toolbar, "단계 추가", () =>
            {
                if (sessionDraft.Actions.Count >= 20) { sessionEditStatus.Text = "단계는 최대 20개입니다."; return; }
                var step = new SessionAction { Kind = "ide" };
                sessionDraft.Actions.Add(step); expandedSessionSteps.Add(step.Id); RenderSessionSteps(); SessionEdited();
            });
            var sticky=PageActions();
            sessionSave = LocalButton(sticky, "변경 저장", () => SaveSessionDraft());
            LocalButton(sticky, "세션 변경 버리기", () =>
            {
                var saved = vm.Service.Sessions().Presets.FirstOrDefault(s => s.Id == sessionDraft.Id);
                if (saved != null) OpenSessionDraft(saved, false);
                else { sessionDraft = null; ReloadSessionList(null); }
            });
            sessionEditStatus = new TextBlock { Foreground = Muted, TextWrapping = TextWrapping.Wrap, Margin = new Thickness(0, 0, 0, 8) };
            sessionEditorHost.Children.Add(sessionEditStatus);
            SectionHeader(sessionEditorHost, "실행 미리보기");
            sessionDetails = new TextBlock { Foreground = Muted, TextWrapping = TextWrapping.Wrap };
            AutomationProperties.SetName(sessionDetails, "개발 세션 실행 미리보기");
            sessionEditorHost.Children.Add(sessionDetails);
            var launch = new WrapPanel { Margin = new Thickness(0, 12, 0, 0) };
            sessionEditorHost.Children.Add(launch);
            Action(sticky, "저장하고 세션 시작", () => LaunchSessionFromUi(false));
            Action(launch, "이전 세션 다시 시작", () => LaunchSessionFromUi(true));
            Action(launch, "세션 종료 기록", () => vm.Service.EndDevelopmentSession());
            PageButton(launch, "프로젝트 선택", "developer-setup");
            sessionResults = DataList("단계별 실행 요청 결과", 144);
            sessionResults.Visibility = Visibility.Collapsed;
            sessionEditorHost.Children.Add(sessionResults);
            var historySection=new Expander{Header="전체 실행 이력",IsExpanded=false,Margin=new Thickness(0,12,0,0)};
            historySection.Expanded+=delegate{if(historySection.Content==null)historySection.Content=new TextBox { IsReadOnly = true, TextWrapping = TextWrapping.Wrap, Height = 128, VerticalScrollBarVisibility = ScrollBarVisibility.Auto, Text = String.Join("\n", vm.Service.SessionHistory().Take(10).Select(r => r.Started + " · " + r.PresetId + " · " + r.Result + "\n" + String.Join("\n", r.Actions.Select(a => a.ToString())))) };};sessionEditorHost.Children.Add(historySection);
            sessionEditorHost.Children.Remove(launch);sessionEditorHost.Children.Insert(sessionEditorHost.Children.IndexOf(sessionDetails)-1,launch);
            changingSession = false;
            SessionEdited();sessionPreviewTimer.Stop(); RefreshSessionPreview();
        }

        StackPanel CreateSessionSettings(){
            var settings = new StackPanel();
            var terminal = Choice(settings, "터미널", new[] { new ChoiceOption("", "프로젝트 설정 상속"), new ChoiceOption("windows-terminal", "Windows Terminal"), new ChoiceOption("cmd", "CMD") }, sessionDraft.TerminalHost ?? "");
            terminal.SelectionChanged += delegate(object sender,SelectionChangedEventArgs args) {string value=SelectedChoice(args);if(value!=null){sessionDraft.TerminalHost=value;SessionEdited();}};
            var profile = Choice(settings, "작업공간", new[] { new ChoiceOption("", "프로젝트 설정 상속") }.Concat(vm.Service.Profiles().Select(p => new ChoiceOption(p.Id, p.Name))), sessionDraft.WorkspaceProfile ?? "");
            profile.SelectionChanged += delegate(object sender,SelectionChangedEventArgs args) {string value=SelectedChoice(args);if(value!=null){sessionDraft.WorkspaceProfile=value;SessionEdited();}};
            var allow = new CheckBox { Content = "이 세션의 자동 실행 허용 (프로젝트 명령 제외)", IsChecked = sessionDraft.AllowAutomation };
            allow.Click += delegate { sessionDraft.AllowAutomation = allow.IsChecked == true; SessionEdited(); };
            settings.Children.Add(allow);
            return settings;
        }

        void RenderSessionSteps()
        {
            var ids=new HashSet<string>(sessionDraft.Actions.Select(action=>action.Id));
            foreach(string stale in sessionStepViews.Keys.Where(id=>!ids.Contains(id)).ToArray()){
                sessionStepEditor.Children.Remove(sessionStepViews[stale].Row);sessionStepViews.Remove(stale);expandedSessionSteps.Remove(stale);
            }
            if(sessionDraft.Actions.Count==0){sessionStepEditor.Children.Clear();sessionStepEditor.Children.Add(new TextBlock{Text="단계 추가로 실행 순서를 구성하세요.",Foreground=Muted});return;}
            if(sessionStepEditor.Children.OfType<TextBlock>().Any())sessionStepEditor.Children.Clear();
            for(int index=0;index<sessionDraft.Actions.Count;index++){
                var step=sessionDraft.Actions[index];SessionStepView view;
                if(!sessionStepViews.TryGetValue(step.Id,out view)){
                    view=new SessionStepView();var row=new DockPanel();var buttons=new WrapPanel{VerticalAlignment=VerticalAlignment.Top};DockPanel.SetDock(buttons,Dock.Right);row.Children.Add(buttons);
                    var enabled=new CheckBox{Content="사용",IsChecked=step.Enabled,Margin=new Thickness(8,0,8,0)};view.Enabled=enabled;buttons.Children.Add(enabled);
                    view.Up=LocalButton(buttons,"↑",()=>MoveSessionStep(step,-1));view.Down=LocalButton(buttons,"↓",()=>MoveSessionStep(step,1));
                    LocalButton(buttons,"제거",()=>{sessionDraft.Actions.Remove(step);RenderSessionSteps();SessionEdited();});
                    var header=new StackPanel();view.Title=new TextBlock();view.Target=new TextBlock{Foreground=Muted,FontSize=12,TextTrimming=TextTrimming.CharacterEllipsis};header.Children.Add(view.Title);header.Children.Add(view.Target);
                    var editor=new Expander{Header=header,Margin=new Thickness(0,0,0,4)};view.Editor=editor;
                    editor.Expanded+=delegate{expandedSessionSteps.Add(step.Id);if(editor.Content==null)editor.Content=CreateSessionStepProperties(step);};
                    editor.Collapsed+=delegate{expandedSessionSteps.Remove(step.Id);};
                    enabled.Click+=delegate{step.Enabled=enabled.IsChecked==true;RenderSessionSteps();SessionEdited();};
                    row.Children.Add(editor);view.Row=new Border{Child=row,BorderBrush=Line,BorderThickness=new Thickness(0,0,0,1),Margin=new Thickness(0,0,0,8)};sessionStepViews.Add(step.Id,view);
                }
                view.Title.Text=(index+1).ToString("00")+" · "+DeveloperText.Action(step.Kind)+(step.Enabled?"":" · 제외");
                view.Target.Text=step.Kind=="tool"?(String.IsNullOrEmpty(step.Value)?"등록 도구 선택 필요":step.Value):sessionProject==null?"프로젝트 선택 필요":sessionProject.Name;
                ((StackPanel)view.Editor.Header).Opacity=step.Enabled?1:0.65;view.Up.IsEnabled=index>0;view.Down.IsEnabled=index+1<sessionDraft.Actions.Count;
                AutomationProperties.SetName(view.Enabled,(index+1)+"단계 사용");AutomationProperties.SetName(view.Up,(index+1)+"단계 위로");AutomationProperties.SetName(view.Down,(index+1)+"단계 아래로");AutomationProperties.SetName(view.Editor,(index+1)+"단계 "+DeveloperText.Action(step.Kind)+" 편집");
                view.Editor.IsExpanded=expandedSessionSteps.Contains(step.Id);
                if(view.Editor.IsExpanded&&view.Editor.Content==null)view.Editor.Content=CreateSessionStepProperties(step);
                int current=sessionStepEditor.Children.IndexOf(view.Row);if(current!=index){if(current>=0)sessionStepEditor.Children.RemoveAt(current);sessionStepEditor.Children.Insert(index,view.Row);}
            }
        }

        StackPanel CreateSessionStepProperties(SessionAction step){
            var properties = new StackPanel { Margin = new Thickness(8, 4, 0, 8) };
                var kind = Choice(properties, "실행 동작", new[] { "ai", "project-terminal", "ide", "codex", "opencode", "wsl", "cmd", "powershell", "terminal", "folder", "repository", "command", "tool" }.Select(k => new ChoiceOption(k, DeveloperText.Action(k))), step.Kind);
                kind.SelectionChanged += delegate(object sender,SelectionChangedEventArgs args)
                {
                    string value=SelectedChoice(args);
                    if(value==null||value==step.Kind)return;
                    step.Kind=value;sessionStepViews[step.Id].Editor.Content=null;expandedSessionSteps.Add(step.Id);SessionEdited();
                    // SelectedValue is still the old value during WPF's SelectionChanged coercion.
                    // Read AddedItems and rebuild after the selector finishes its current event.
                    Dispatcher.BeginInvoke((Action)delegate{if(page!="development-sessions"||sessionDraft==null||!sessionDraft.Actions.Contains(step))return;RenderSessionSteps();var editor=sessionStepViews[step.Id].Editor;if(editor.IsExpanded&&editor.Content==null)editor.Content=CreateSessionStepProperties(step);});
                };
                if (step.Kind == "tool")
                {
                    var tool = Choice(properties, "실행할 등록 도구", new[] { new ChoiceOption("", "도구 선택") }.Concat(vm.Service.Developer().Tools.Select(t => new ChoiceOption(t.Id, t.Name))), step.Value ?? "");
                    tool.SelectionChanged += delegate(object sender,SelectionChangedEventArgs args){string value=SelectedChoice(args);if(value!=null){step.Value=value;RenderSessionSteps();SessionEdited();}};
                }
                else
                {
                    properties.Children.Add(new TextBlock { Text = SessionStepTarget(step), Foreground = Muted, TextWrapping = TextWrapping.Wrap });
                    LocalButton(properties, "프로젝트 실행 설정 편집", () =>
                    {
                        try { EditDeveloperPreferences(vm.Service.ActiveProject()); CaptureSessionProject(); foreach(var view in sessionStepViews.Values)view.Editor.Content=null;RenderSessionSteps();RefreshSessionPreview(); }
                        catch (Exception error) { sessionEditStatus.Text = error.Message; }
                    });
                    if (step.Kind == "command") PageButton(properties, "프로젝트 명령 편집", "projects");
                }
            return properties;
        }

        static string SelectedChoice(SelectionChangedEventArgs args){var item=args.AddedItems.OfType<ChoiceOption>().FirstOrDefault();return item==null?null:item.Key;}

        string SessionStepTarget(SessionAction step)
        {
            try
            {
                if(sessionProject==null)return sessionProjectError??"프로젝트를 선택하세요.";
                var project = sessionProject;
                var prefs = sessionPreferences;
                string detail = step.Kind == "command" ? String.Join("\n", project.Commands ?? new List<string>())
                    : step.Kind == "repository" ? project.RepositoryUrl
                    : (step.Kind == "ai" || step.Kind == "codex" || step.Kind == "opencode" || step.Kind == "wsl")
                        ? "WSL " + (prefs.WslDistribution ?? "미지정") + " · " + (step.Kind == "ai" ? prefs.DefaultAiCli : step.Kind)
                        : "터미널 " + (String.IsNullOrEmpty(sessionDraft.TerminalHost)?prefs.TerminalHost:sessionDraft.TerminalHost) + " · 편집기 " + prefs.Editor;
                return "대상: " + project.Name + "\n" + project.Directory + "\n" + (String.IsNullOrEmpty(detail) ? "프로젝트 설정 필요" : detail)
                    + "\n실행 인수는 기존 프로젝트 설정을 사용합니다.";
            }
            catch (Exception error) { return error.Message; }
        }

        void MoveSessionStep(SessionAction step, int direction)
        {
            int index = sessionDraft.Actions.IndexOf(step), next = index + direction;
            if (next < 0 || next >= sessionDraft.Actions.Count) return;
            sessionDraft.Actions.RemoveAt(index); sessionDraft.Actions.Insert(next, step);
            RenderSessionSteps(); SessionEdited();
        }

        Button LocalButton(Panel panel, string label, Action click)
        {
            var button = new Button { Content = label };
            AutomationProperties.SetName(button, label);
            button.Click += delegate { try { click(); } catch (Exception error) { vm.Status = error.Message; } };
            panel.Children.Add(button); return button;
        }

        void SessionEdited()
        {
            if (changingSession || sessionSave == null) return;
            bool dirty=SessionDraftDirty;
            sessionSave.IsEnabled = dirty;
            sessionEditStatus.Text = dirty ? "저장하지 않은 세션 변경이 있습니다." : "저장된 세션";
            sessionPreviewTimer.Stop(); sessionPreviewTimer.Start();
        }

        void RefreshSessionPreview()
        {
            if (page != "development-sessions" || sessionDetails == null || sessionDraft == null) return;
            try { if(sessionProject==null){sessionDetails.Text=sessionProjectError??"프로젝트를 선택하세요.";return;}sessionDetails.Text = vm.Service.SessionPreview(sessionProject, sessionDraft,sessionPreferences); }
            catch (Exception error) { sessionDetails.Text = error.Message; }
        }

        void CaptureSessionProject(){try{sessionProject=vm.Service.ActiveProject();sessionPreferences=vm.Service.Preferences(sessionProject);sessionProjectError=null;}catch(Exception error){sessionProject=null;sessionPreferences=null;sessionProjectError=error.Message;}}

        bool SaveSessionDraft()
        {
            try
            {
                sessionDraft.Name=sessionDraft.Name.Trim();vm.Service.SaveSession(sessionDraft);
                sessionOriginal = vm.Service.Json.Serialize(sessionDraft);
                changingSession = true;
                var sessions = vm.Service.Sessions().Presets;
                sessionList.ItemsSource = sessions;
                sessionList.SelectedItem = sessions.FirstOrDefault(s => s.Id == sessionDraft.Id);
                changingSession = false;
                SessionEdited(); return true;
            }
            catch (Exception error) { sessionEditStatus.Text = "저장 실패: " + error.Message; return false; }
        }

        bool ConfirmSessionDraft()
        {
            if (!SessionDraftDirty) return true;
            int answer = Decide("미저장 세션", "세션 편집 내용을 저장할까요?", "저장하고 이동", "버리고 이동", "계속 편집");
            if (answer == 2) return false;
            if (answer == 0) return SaveSessionDraft();
            sessionDraft=String.IsNullOrEmpty(sessionOriginal)?null:vm.Service.Json.Deserialize<DevelopmentSession>(sessionOriginal);
            return true;
        }
    }
}
