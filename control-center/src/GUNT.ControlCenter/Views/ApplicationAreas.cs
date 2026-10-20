using System;
using System.Linq;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using Gunt.ControlCenter.Services;

namespace Gunt.ControlCenter.Views
{
    public sealed partial class MainWindow
    {
        bool workspaceMode;
        readonly TextBlock areaLabel = new TextBlock
        {
            FontSize = 12,
            FontWeight = FontWeights.SemiBold,
            Margin = new Thickness(8, 0, 0, 8)
        };
        static string AreaRoute(string route)
        {
            return route == "backup" ? "diagnostics" : route == "settings" ? "overview" : route == "workspace" ? "workspace-overview" : route;
        }

        internal static bool IsWorkspacePage(string route)
        {
            return new[]
            {
                "workspace",
                "workspace-overview",
                "developer-setup",
                "projects",
                "development-sessions",
                "wsl-environments",
                "commands",
                "smart-automation"
            }.Contains(route);
        }

        void ConfigureArea(string route)
        {
            bool target = IsWorkspacePage(route);
            if (navigation.Items.Count > 0 && target == workspaceMode)
                return;
            workspaceMode = target;
            areaLabel.Text = workspaceMode ? "GUNT WORKSPACE" : "GUNT SETTINGS";
            selecting = true;
            navigation.Items.Clear();
            var groups = workspaceMode ? new[]
            {
                new[]
                {
                    "작업공간",
                    "workspace-overview",
                    "developer-setup",
                    "projects",
                    "development-sessions",
                    "wsl-environments"
                },
                new[]
                {
                    "도구",
                    "smart-automation",
                    "commands"
                }
            }

            : new[]
            {
                new[]
                {
                    "설정",
                    "overview"
                },
                new[]
                {
                    "개인 설정",
                    "appearance",
                    "dock",
                    "topbar",
                    "wallpaper",
                    "profiles"
                },
                new[]
                {
                    "시스템",
                    "displays",
                    "monitor",
                    "sensors",
                    "windhawk"
                },
                new[]
                {
                    "앱 설정",
                    "launchpad-settings",
                    "shortcuts",
                    "automation"
                },
                new[]
                {
                    "관리",
                    "diagnostics",
                    "about"
                }
            };
            foreach (var group in groups)
            {
                navigation.Items.Add(new ListBoxItem { Content = group[0], Visibility = ActualWidth > 0 && ActualWidth < 960 ? Visibility.Collapsed : Visibility.Visible, IsEnabled = false, Focusable = false, Foreground = Muted, FontSize = 11, Padding = new Thickness(8, 12, 8, 4) });
                foreach (string id in group.Skip(1))
                {
                    var p = pages.First(x => x[0] == id);
                    navigation.Items.Add(new ListBoxItem { Content = p[1], Tag = id, Padding = new Thickness(8, 6, 8, 6), MinHeight = 34, Background = Brushes.Transparent, Foreground = TextColor });
                }
            }

            navigation.SelectedItem = navigation.Items.Cast<ListBoxItem>().FirstOrDefault(x => Convert.ToString(x.Tag) == route);
            selecting = false;
        }

        void AreaButtons(Panel parent)
        {
            var buttons = new WrapPanel
            {
                Margin = new Thickness(0, 0, 0, 8)
            };
            parent.Children.Add(buttons);
            Button settings = new Button
            {
                Content = "설정",
                Padding = new Thickness(8, 4, 8, 4)
            }, workspace = new Button
            {
                Content = "작업공간",
                Padding = new Thickness(8, 4, 8, 4)
            };
            settings.Click += delegate
            {
                SelectPage("settings");
            };
            workspace.Click += delegate
            {
                SelectPage("workspace");
            };
            buttons.Children.Add(settings);
            buttons.Children.Add(workspace);
        }

        bool RenderAreaPage(string route)
        {
            if (route == "workspace-overview")
            {
                Text("프로젝트와 개발 환경", false);
                var developer = vm.Service.Developer();
                var selectedProject = vm.Service.Projects().FirstOrDefault(x => x.Id == developer.SelectedProjectId);
                Text(selectedProject == null ? "개발 세팅에서 사용할 프로젝트를 선택하세요." : "선택한 프로젝트 · " + selectedProject.Name, true);
                var actions = Actions();
                PageButton(actions, "개발 세팅", "developer-setup");
                PageButton(actions, "개발 세션", "development-sessions");
                PageButton(actions, "WSL 환경", "wsl-environments");
                var tools = Actions();
                PageButton(tools, "프로젝트 관리", "projects");
                PageButton(tools, "스마트 자동화", "smart-automation");
                PageButton(tools, "명령어 관리", "commands");
                Action(tools, "Launchpad 열기", () =>
                {
                    vm.Service.OpenControlCenter("launchpad");
                    return "Launchpad 열기를 요청했습니다.";
                });
                return true;
            }

            if (route == "launchpad-settings" || route == "shortcuts")
            {
                var c = vm.Service.Launchpad();
                Text(route == "shortcuts" ? "전역 단축키는 실행 중인 GUNT 상단 바가 등록합니다." : "설치 앱과 바로가기는 Launchpad에서 정리합니다.", true);
                Text("Launchpad · " + (c.HotkeyEnabled ? c.Shortcut : "단축키 사용 안 함"), false);
                Text("아이콘 " + c.IconSize + " DIP · 최대 " + c.Columns + "열 · " + (c.IconTheme == "original" ? "원래 앱 아이콘" : "GUNT 마스코트"), true);
                var actions = Actions();
                var edit = new Button
                {
                    Content = route == "shortcuts" ? "Launchpad 단축키 변경" : "Launchpad 사용자화"
                };
                edit.Click += delegate
                {
                    LaunchpadPreferences.Show(this, vm.Service);
                    Show(route);
                };
                actions.Children.Add(edit);
                Action(actions, "Launchpad 열기", () =>
                {
                    vm.Service.OpenControlCenter("launchpad");
                    return "Launchpad 열기를 요청했습니다.";
                });
                if (route == "launchpad-settings")
                    Action(actions, "숨긴 앱 다시 표시", () =>
                    {
                        var fresh = vm.Service.Launchpad();
                        foreach (var item in fresh.Items.Values)
                            item.Hidden = false;
                        vm.Service.SaveLaunchpad(fresh);
                        return "숨긴 앱을 다시 표시하도록 저장했습니다.";
                    });
                else
                    foreach (var field in vm.Fields)
                        AddField(field);
                return true;
            }

            return false;
        }
    }
}
