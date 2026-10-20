using System;
using System.Collections.Generic;

namespace Gunt.ControlCenter.Models
{
    public sealed class ApplicationEntry
    {
        public string Id, Name, Kind, Target, Source, Icon, Category, Context, Aliases;
        public string[] Arguments = new string[0];
        public override string ToString()
        {
            return Name;
        }
    }

    public sealed class ApplicationCatalog
    {
        public int SchemaVersion = 1;
        public string Refreshed;
        public List<ApplicationEntry> Apps = new List<ApplicationEntry>();
        public List<string> Warnings = new List<string>();
    }

    public sealed class LaunchpadCategory
    {
        public string Id, Name, Pose;
        public bool Builtin;
        public override string ToString()
        {
            return Name;
        }
    }

    public sealed class LaunchpadFolder
    {
        public string Id, Name, Category = "utilities", Pose = "folder";
        public override string ToString()
        {
            return Name;
        }
    }

    public sealed class LaunchpadItem
    {
        public string Category, Folder, Label, Aliases, Pose, LastLaunched;
        public bool Favorite, Hidden;
        public int Order = 100000, FavoriteOrder = 100000;
    }

    public sealed class LaunchpadConfig
    {
        public int SchemaVersion = 1;
        public string Shortcut = "Ctrl+Alt+L", Monitor = "pointer", DefaultCategory = "all", SelectedCategory = "all", IconTheme = "original";
        public bool HotkeyEnabled = true, CloseAfterLaunch = true, Animations = true, Transparency;
        public int IconSize = 64, Columns = 7;
        public List<LaunchpadCategory> Categories = new List<LaunchpadCategory>
        {
            new LaunchpadCategory
            {
                Id = "all",
                Name = "전체 앱",
                Builtin = true,
                Pose = "default"
            },
            new LaunchpadCategory
            {
                Id = "favorites",
                Name = "즐겨찾기",
                Builtin = true,
                Pose = "default"
            },
            new LaunchpadCategory
            {
                Id = "development",
                Name = "개발",
                Builtin = true,
                Pose = "coding"
            },
            new LaunchpadCategory
            {
                Id = "utilities",
                Name = "유틸리티",
                Builtin = true,
                Pose = "utility"
            },
            new LaunchpadCategory
            {
                Id = "internet",
                Name = "인터넷",
                Builtin = true,
                Pose = "network"
            },
            new LaunchpadCategory
            {
                Id = "games",
                Name = "게임",
                Builtin = true,
                Pose = "gaming"
            },
            new LaunchpadCategory
            {
                Id = "system",
                Name = "시스템",
                Builtin = true,
                Pose = "settings"
            }
        };
        public List<LaunchpadFolder> Folders = new List<LaunchpadFolder>();
        public List<ApplicationEntry> Shortcuts = new List<ApplicationEntry>();
        public Dictionary<string, LaunchpadItem> Items = new Dictionary<string, LaunchpadItem>();
    }
}
