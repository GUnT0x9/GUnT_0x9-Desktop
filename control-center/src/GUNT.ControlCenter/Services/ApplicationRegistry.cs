using System;
using System.IO;
using System.Linq;
using System.Collections.Generic;
using System.Diagnostics;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Security.Cryptography;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using Gunt.ControlCenter.Models;

namespace Gunt.ControlCenter.Services
{
    public sealed partial class DesktopService
    {
        public LaunchpadConfig Launchpad()
        {
            var c = Local("launchpad", () => new LaunchpadConfig());
            if (c == null || c.SchemaVersion != 1 || c.Categories == null || c.Items == null || c.Shortcuts == null || c.Folders == null)
                throw new InvalidDataException("Launchpad 설정 버전을 확인하세요. 원본은 보존했습니다.");
            ValidateLaunchpad(c);
            return c;
        }

        public void SaveLaunchpad(LaunchpadConfig c)
        {
            ValidateLaunchpad(c);
            SaveLocal("launchpad", c);
        }

        static void ValidateLaunchpad(LaunchpadConfig c)
        {
            if (c.IconSize < 48 || c.IconSize > 80 || c.Columns < 4 || c.Columns > 8 || !new[]
            {
                "pointer",
                "foreground"
            }.Contains(c.Monitor) || !new[]
            {
                "original",
                "mascot"
            }.Contains(c.IconTheme))
                throw new ArgumentException("Launchpad 표시 설정을 확인하세요.");
            uint modifiers, key;
            if (!GuntLaunchpadHotkey.TryParse(c.Shortcut, out modifiers, out key))
                throw new ArgumentException("Ctrl/Alt를 포함한 단축키를 선택하세요.");
            if (c.Categories.Any(x => String.IsNullOrWhiteSpace(x.Id) || String.IsNullOrWhiteSpace(x.Name) || x.Name.Length > 40) || c.Categories.Select(x => x.Id).Distinct().Count() != c.Categories.Count)
                throw new ArgumentException("카테고리 이름과 ID를 확인하세요.");
            foreach (var builtin in new LaunchpadConfig().Categories)
                if (!c.Categories.Any(x => x.Id == builtin.Id && x.Builtin))
                    throw new ArgumentException("기본 카테고리를 보존하세요.");
            if (!c.Categories.Any(x => x.Id == c.DefaultCategory) || !c.Categories.Any(x => x.Id == c.SelectedCategory))
                throw new ArgumentException("기본 카테고리를 확인하세요.");
            if (c.Folders.Any(x => String.IsNullOrWhiteSpace(x.Name) || x.Name.Length > 40 || !c.Categories.Any(y => y.Id == x.Category && y.Id != "all" && y.Id != "favorites")) || c.Folders.Select(x => x.Id).Distinct().Count() != c.Folders.Count)
                throw new ArgumentException("폴더 이름·카테고리를 확인하세요.");
            if (c.Shortcuts.Any(x => String.IsNullOrEmpty(x.Id) || !x.Id.StartsWith("custom-")) || c.Shortcuts.Select(x => x.Id).Distinct().Count() != c.Shortcuts.Count)
                throw new ArgumentException("사용자 바로가기 ID를 확인하세요.");
            foreach (var app in c.Shortcuts)
                ValidateApplication(app, false);
        }

        public static LaunchpadItem Item(LaunchpadConfig c, string id)
        {
            LaunchpadItem item;
            if (!c.Items.TryGetValue(id, out item))
            {
                item = new LaunchpadItem();
                c.Items.Add(id, item);
            }

            return item;
        }

        public static string ApplicationId(string kind, string identity)
        {
            using (var sha = SHA256.Create())
                return kind + "-" + BitConverter.ToString(sha.ComputeHash(Encoding.UTF8.GetBytes(identity.ToUpperInvariant()))).Replace("-", "").Substring(0, 24);
        }

        public ApplicationCatalog CachedApplications()
        {
            string path = Path.Combine(Root, "state", "launchpad-catalog.json");
            if (!File.Exists(path))
                return new ApplicationCatalog();
            try
            {
                var c = Json.Deserialize<ApplicationCatalog>(GuntConfiguration.ReadShared(path));
                return c != null && c.SchemaVersion == 1 && c.Apps != null ? c : new ApplicationCatalog();
            }
            catch (ArgumentException)
            {
                return new ApplicationCatalog();
            }
            catch (InvalidOperationException)
            {
                return new ApplicationCatalog();
            }
        }

        // Shell COM enumeration runs on its own STA, never on the WPF dispatcher.
        public Task<ApplicationCatalog> DiscoverApplicationsAsync()
        {
            var result = new TaskCompletionSource<ApplicationCatalog>();
            var thread = new Thread(() =>
            {
                try
                {
                    var catalog = DiscoverApplications();
                    GuntConfiguration.Atomic(Root, Path.Combine(Root, "state", "launchpad-catalog.json"), Json.Serialize(catalog), false);
                    result.SetResult(catalog);
                }
                catch (Exception e)
                {
                    result.SetException(e);
                }
            });
            thread.SetApartmentState(ApartmentState.STA);
            thread.IsBackground = true;
            thread.Name = "GUNT application discovery";
            thread.Start();
            return result.Task;
        }

        static object Com(object target, string name, params object[] args)
        {
            return target.GetType().InvokeMember(name, BindingFlags.InvokeMethod | BindingFlags.GetProperty, null, target, args);
        }

        static void Release(object value)
        {
            if (value != null && Marshal.IsComObject(value))
                Marshal.FinalReleaseComObject(value);
        }

        public ApplicationCatalog DiscoverApplications()
        {
            var catalog = new ApplicationCatalog
            {
                Refreshed = DateTimeOffset.Now.ToString("o")
            };
            var seen = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            object shell = null, wscript = null;
            try
            {
                wscript = Activator.CreateInstance(Type.GetTypeFromProgID("WScript.Shell"));
                foreach (string root in new[]
                {
                    Environment.GetFolderPath(Environment.SpecialFolder.StartMenu),
                    Environment.GetFolderPath(Environment.SpecialFolder.CommonStartMenu)
                }

                )
                {
                    var queue = new Queue<string>();
                    if (Directory.Exists(root))
                        queue.Enqueue(root);
                    while (queue.Count > 0 && catalog.Apps.Count < 5000)
                    {
                        string folder = queue.Dequeue();
                        try
                        {
                            foreach (string child in Directory.GetDirectories(folder))
                                if ((File.GetAttributes(child) & FileAttributes.ReparsePoint) == 0)
                                    queue.Enqueue(child);
                            foreach (string path in Directory.GetFiles(folder, "*.lnk"))
                            {
                                object link = null;
                                try
                                {
                                    link = Com(wscript, "CreateShortcut", path);
                                    string target = Convert.ToString(Com(link, "TargetPath")), args = Convert.ToString(Com(link, "Arguments")), working = Convert.ToString(Com(link, "WorkingDirectory"));
                                    // Exact target + arguments + working directory only. Unknown / advertised links retain their own identity.
                                    string identity = String.IsNullOrEmpty(target) ? path : target + "\n" + args + "\n" + working;
                                    if (!seen.Add(identity))
                                        continue;
                                    catalog.Apps.Add(new ApplicationEntry { Id = ApplicationId("app", identity), Name = Path.GetFileNameWithoutExtension(path), Kind = "shortcut", Target = path, Icon = path, Category = GuessCategory(path), Source = "시작 메뉴", Context = "앱" });
                                }
                                catch (Exception)
                                {
                                    catalog.Warnings.Add("일부 시작 메뉴 항목을 읽지 못했습니다.");
                                }
                                finally
                                {
                                    Release(link);
                                }
                            }
                        }
                        catch (UnauthorizedAccessException)
                        {
                            catalog.Warnings.Add("일부 시작 메뉴 폴더 접근이 제한됐습니다.");
                        }
                        catch (IOException)
                        {
                            catalog.Warnings.Add("일부 시작 메뉴 폴더를 읽지 못했습니다.");
                        }
                    }
                }

                foreach (var hive in new[]
                {
                    Microsoft.Win32.RegistryHive.CurrentUser,
                    Microsoft.Win32.RegistryHive.LocalMachine
                }

                )
                    foreach (var view in new[]
                    {
                        Microsoft.Win32.RegistryView.Registry64,
                        Microsoft.Win32.RegistryView.Registry32
                    }

                    )
                    {
                        try
                        {
                            using (var baseKey = Microsoft.Win32.RegistryKey.OpenBaseKey(hive, view))
                            using (var apps = baseKey.OpenSubKey(@"Software\Microsoft\Windows\CurrentVersion\App Paths"))
                            {
                                if (apps == null)
                                    continue;
                                foreach (string name in apps.GetSubKeyNames())
                                {
                                    using (var appKey = apps.OpenSubKey(name))
                                    {
                                        if (appKey == null)
                                            continue;
                                        string target = Environment.ExpandEnvironmentVariables(Convert.ToString(appKey.GetValue(null))).Trim('"');
                                        if (!Path.IsPathRooted(target) || !target.EndsWith(".exe", StringComparison.OrdinalIgnoreCase) || !File.Exists(target))
                                            continue;
                                        string identity = target + "\n\n";
                                        if (!seen.Add(identity))
                                            continue;
                                        string display = Path.GetFileNameWithoutExtension(name);
                                        try
                                        {
                                            string description = FileVersionInfo.GetVersionInfo(target).FileDescription;
                                            if (!String.IsNullOrWhiteSpace(description))
                                                display = description;
                                        }
                                        catch (IOException)
                                        {
                                        }
                                        catch (System.ComponentModel.Win32Exception)
                                        {
                                        }

                                        catalog.Apps.Add(new ApplicationEntry { Id = ApplicationId("app", identity), Name = display, Kind = "exe", Target = target, Icon = target, Category = GuessCategory(display), Source = "Windows 앱 경로 등록", Context = "앱" });
                                    }
                                }
                            }
                        }
                        catch (System.Security.SecurityException)
                        {
                            catalog.Warnings.Add("일부 앱 경로 등록을 읽지 못했습니다.");
                        }
                        catch (UnauthorizedAccessException)
                        {
                            catalog.Warnings.Add("일부 앱 경로 등록에 접근할 수 없습니다.");
                        }
                    }

                shell = Activator.CreateInstance(Type.GetTypeFromProgID("Shell.Application"));
                object folderApps = null, items = null;
                try
                {
                    folderApps = Com(shell, "NameSpace", "shell:AppsFolder");
                    if (folderApps != null)
                    {
                        items = Com(folderApps, "Items");
                        int count = Convert.ToInt32(Com(items, "Count"));
                        for (int i = 0; i < count; i++)
                        {
                            object entry = null;
                            try
                            {
                                entry = Com(items, "Item", i);
                                string id = Convert.ToString(Com(entry, "ExtendedProperty", "System.AppUserModel.ID"));
                                // AppsFolder is the supported app registration view. Package AUMIDs contain '!'. Desktop entries already come from .lnk.
                                if (String.IsNullOrWhiteSpace(id) || !id.Contains("!") || !System.Text.RegularExpressions.Regex.IsMatch(id, @"^[A-Za-z0-9._!\-]+$"))
                                    continue;
                                if (!seen.Add("aumid:" + id))
                                    continue;
                                catalog.Apps.Add(new ApplicationEntry { Id = ApplicationId("package", id), Name = Convert.ToString(Com(entry, "Name")), Kind = "packaged", Target = id, Icon = "shell:AppsFolder\\" + id, Category = "system", Source = "Windows 앱 등록", Context = "Windows 앱" });
                            }
                            catch (Exception)
                            {
                                catalog.Warnings.Add("일부 Windows 앱 등록을 읽지 못했습니다.");
                            }
                            finally
                            {
                                Release(entry);
                            }
                        }
                    }
                }
                finally
                {
                    Release(items);
                    Release(folderApps);
                }
            }
            finally
            {
                Release(wscript);
                Release(shell);
            }

            catalog.Apps = catalog.Apps.OrderBy(x => x.Name, StringComparer.CurrentCultureIgnoreCase).ToList();
            catalog.Warnings = catalog.Warnings.Distinct().ToList();
            return catalog;
        }

        static string GuessCategory(string path)
        {
            string s = path.ToLowerInvariant();
            if (new[]
            {
                "visual studio",
                "python",
                "git",
                "node",
                "terminal",
                "docker",
                "개발"
            }.Any(s.Contains))
                return "development";
            if (new[]
            {
                "chrome",
                "edge",
                "firefox",
                "internet",
                "브라우저"
            }.Any(s.Contains))
                return "internet";
            if (new[]
            {
                "steam",
                "game",
                "게임"
            }.Any(s.Contains))
                return "games";
            if (new[]
            {
                "system",
                "시스템",
                "windows"
            }.Any(s.Contains))
                return "system";
            return "utilities";
        }

        public ApplicationEntry[] ApplicationEntries(ApplicationCatalog catalog, LaunchpadConfig config)
        {
            var projects = Projects();
            var commandConfig = CommandsConfig();
            var result = new List<ApplicationEntry>(catalog.Apps);
            result.AddRange(config.Shortcuts);
            foreach (var command in Commands())
                result.Add(new ApplicationEntry { Id = "gunt-" + command.Id, Aliases = command.Aliases + " " + String.Join(" ", commandConfig.Aliases.Where(pair => pair.Value == command.Id).Select(pair => pair.Key)), Name = command.ProjectId != null && command.Action == "developer" ? DeveloperText.Action(command.Value) + " 실행" : command.Name, Kind = "command", Target = command.Id, Category = command.ProjectId != null || command.Action == "developer" ? "development" : "system", Source = "GUNT", Context = command.ProjectId != null ? "프로젝트 · " + projects.FirstOrDefault(p => p.Id == command.ProjectId) : "GUNT 명령" });
            foreach (var project in projects)
                result.Add(new ApplicationEntry { Id = "project-" + project.Id, Name = project.Name, Kind = "project", Target = project.Id, Icon = project.Directory, Category = "development", Source = "GUNT Workspace", Context = "프로젝트" });
            foreach (var preset in Sessions().Presets)
                result.Add(new ApplicationEntry { Id = "session-" + preset.Id, Name = preset.Name, Kind = "session", Target = preset.Id, Category = "development", Source = "GUNT Workspace", Context = "개발 세션" });
            return result.GroupBy(x => x.Id).Select(x => x.First()).ToArray();
        }

        public static void ValidateApplication(ApplicationEntry app, bool requireExists)
        {
            if (app == null || String.IsNullOrWhiteSpace(app.Name) || app.Name.Length > 100 || String.IsNullOrWhiteSpace(app.Target) || app.Target.IndexOfAny(new[] { '\0', '\r', '\n' }) >= 0 || app.Arguments == null || app.Arguments.Any(x => x == null || x.IndexOf('\0') >= 0))
                throw new ArgumentException("앱 이름과 실행 대상을 확인하세요.");
            if (app.Kind == "website")
            {
                Uri uri;
                if (!Uri.TryCreate(app.Target, UriKind.Absolute, out uri) || (uri.Scheme != "http" && uri.Scheme != "https") || !String.IsNullOrEmpty(uri.UserInfo))
                    throw new ArgumentException("인증 정보가 없는 HTTP/HTTPS 주소를 입력하세요.");
                if (app.Arguments.Length > 0)
                    throw new ArgumentException("웹 주소에는 인수를 지정하지 않습니다.");
            }
            else if (new[]
            {
                "exe",
                "shortcut",
                "folder"
            }.Contains(app.Kind))
            {
                if (!Path.IsPathRooted(app.Target) || app.Target.Contains("\""))
                    throw new ArgumentException("절대 경로를 선택하세요.");
                if (app.Kind != "folder" && !app.Target.EndsWith(app.Kind == "exe" ? ".exe" : ".lnk", StringComparison.OrdinalIgnoreCase))
                    throw new ArgumentException("지원하는 실행 파일 또는 바로가기를 선택하세요.");
                if (app.Kind != "exe" && app.Arguments.Length > 0)
                    throw new ArgumentException("추가 인수는 실행 파일에서만 지원합니다.");
                if (requireExists && !(app.Kind == "folder" ? Directory.Exists(app.Target) : File.Exists(app.Target)))
                    throw new FileNotFoundException("앱 또는 바로가기 대상이 없습니다. 다시 검색하거나 경로를 확인하세요.");
            }
            else if (app.Kind == "packaged")
            {
                if (!System.Text.RegularExpressions.Regex.IsMatch(app.Target, @"^[A-Za-z0-9._\-]+![A-Za-z0-9._\-]+$"))
                    throw new ArgumentException("지원하지 않는 Windows 앱 식별자입니다.");
            }
            else if (!new[]
            {
                "command",
                "project",
                "session"
            }.Contains(app.Kind))
                throw new ArgumentException("지원하지 않는 실행 대상입니다.");
        }

        [DllImport("shell32.dll", CharSet = CharSet.Unicode)]
        static extern int SHParseDisplayName(string name, IntPtr bind, out IntPtr pidl, uint flags, out uint attributes);
        public string LaunchApplication(ApplicationEntry app)
        {
            ValidateApplication(app, true);
            if (app.Kind == "shortcut")
            {
                object shell = null, link = null;
                try
                {
                    shell = Activator.CreateInstance(Type.GetTypeFromProgID("WScript.Shell"));
                    link = Com(shell, "CreateShortcut", app.Target);
                    string target = Convert.ToString(Com(link, "TargetPath"));
                    if (!String.IsNullOrEmpty(target) && Path.IsPathRooted(target) && !File.Exists(target) && !Directory.Exists(target))
                        throw new FileNotFoundException("바로가기의 실행 대상이 없습니다. 앱을 다시 검색하거나 경로를 확인하세요.");
                }
                finally
                {
                    Release(link);
                    Release(shell);
                }
            }

            if (app.Kind == "packaged")
            {
                var latest = CachedApplications();
                if (!latest.Apps.Any(x => x.Kind == "packaged" && x.Target == app.Target))
                    throw new ArgumentException("현재 등록 목록에 없는 Windows 앱입니다. 앱을 다시 검색하세요.");
                IntPtr pidl;
                uint attributes;
                int result = SHParseDisplayName("shell:AppsFolder\\" + app.Target, IntPtr.Zero, out pidl, 0, out attributes);
                try
                {
                    if (result < 0 || pidl == IntPtr.Zero)
                        throw new ArgumentException("Windows 앱 등록이 없습니다. 앱을 다시 검색하세요.");
                }
                finally
                {
                    if (pidl != IntPtr.Zero)
                        Marshal.FreeCoTaskMem(pidl);
                }
            }

            if (app.Kind == "command")
            {
                var command = Commands().FirstOrDefault(x => x.Id == app.Target);
                if (command == null)
                    throw new ArgumentException("등록된 GUNT 명령이 없습니다.");
                if (command.Action == "page")
                    OpenControlCenter(command.Value);
                else if (command.Action == "panel")
                    OpenControlCenter("quick-panel");
                else if (command.Action == "session")
                    OpenControlCenter("development-sessions");
                else
                    return ExecuteCommand(command);
            }
            else if (app.Kind == "project")
            {
                var project = Projects().FirstOrDefault(x => x.Id == app.Target);
                if (project == null)
                    throw new ArgumentException("등록된 프로젝트가 없습니다.");
                return LaunchDeveloper(project, "folder");
            }
            else if (app.Kind == "session")
                throw new InvalidOperationException("실행할 프로젝트와 세션 미리보기를 확인하세요.");
            else if (app.Kind == "packaged")
                Launch(new ProcessStartInfo("explorer.exe", NativeArgument("shell:AppsFolder\\" + app.Target)) { UseShellExecute = true });
            else if (app.Kind == "folder")
                Launch(new ProcessStartInfo("explorer.exe", NativeArgument(app.Target)) { UseShellExecute = true });
            else
                Launch(new ProcessStartInfo(app.Target, String.Join(" ", app.Arguments.Select(NativeArgument))) { UseShellExecute = true });
            return app.Name + " 실행 요청을 전달했습니다.";
        }

        public static ApplicationEntry[] FilterApplications(IEnumerable<ApplicationEntry> entries, LaunchpadConfig c, string category, string folder, string query)
        {
            bool searching = !String.IsNullOrWhiteSpace(query);
            return entries.Where(a =>
            {
                var item = Item(c, a.Id);
                return !item.Hidden && (searching || (folder != null ? item.Folder == folder : category == "favorites" ? item.Favorite : category == "all" ? String.IsNullOrEmpty(item.Folder) && (a.Kind != "command" || new[]
                {
                    "settings",
                    "workspace"
                }.Contains(a.Target)) : (item.Category ?? a.Category) == category && String.IsNullOrEmpty(item.Folder)));
            }).Select(a => new { App = a, Score = searching ? MatchCommand(query, (Item(c, a.Id).Label ?? a.Name) + " " + Item(c, a.Id).Aliases + " " + a.Aliases + " " + a.Context + " " + c.Categories.Where(x => x.Id == (Item(c, a.Id).Category ?? a.Category)).Select(x => x.Name).FirstOrDefault()) : 1 }).Where(x => x.Score > 0).OrderByDescending(x => searching ? x.Score : 0).ThenBy(x => category == "favorites" ? Item(c, x.App.Id).FavoriteOrder : Item(c, x.App.Id).Order).ThenByDescending(x => searching && Item(c, x.App.Id).Favorite).ThenByDescending(x => searching ? Item(c, x.App.Id).LastLaunched : null).ThenBy(x => Item(c, x.App.Id).Label ?? x.App.Name, StringComparer.CurrentCultureIgnoreCase).Select(x => x.App).ToArray();
        }

        public static void DeleteLaunchpadCategory(LaunchpadConfig c, string id)
        {
            var category = c.Categories.First(x => x.Id == id);
            if (category.Builtin)
                throw new ArgumentException("기본 카테고리는 삭제하지 않습니다.");
            c.Categories.Remove(category);
            foreach (var item in c.Items.Values)
                if (item.Category == id)
                    item.Category = "utilities";
            foreach (var folder in c.Folders)
                if (folder.Category == id)
                    folder.Category = "utilities";
            if (c.DefaultCategory == id)
                c.DefaultCategory = "all";
            if (c.SelectedCategory == id)
                c.SelectedCategory = "all";
        }

        public static void DeleteLaunchpadFolder(LaunchpadConfig c, string id)
        {
            c.Folders.RemoveAll(x => x.Id == id);
            foreach (var item in c.Items.Values)
                if (item.Folder == id)
                    item.Folder = null;
        }
    }
}
