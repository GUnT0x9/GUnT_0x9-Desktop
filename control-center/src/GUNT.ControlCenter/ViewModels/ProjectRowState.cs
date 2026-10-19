using System;
using System.ComponentModel;
using Gunt.ControlCenter.Models;

namespace Gunt.ControlCenter.ViewModels
{
    // Transient presentation data. Never written to the project database.
    public sealed class ProjectRowState : INotifyPropertyChanged
    {
        public ProjectEntry Entry { get; private set; }
        public ProjectInfo Info { get; private set; }
        public bool Loading { get; set; }
        public string Type { get; private set; }
        public string Git { get; private set; }
        public string Recent { get; private set; }
        public string Name { get { return Entry.Name; } }
        public string Directory { get { return Entry.Directory; } }
        public bool Pinned { get { return Entry.Pinned; } }
        public string FavoriteName { get { return Entry.Name + " 즐겨찾기"; } }
        public string Metadata { get { return Type + " · " + Git; } }
        public event PropertyChangedEventHandler PropertyChanged;

        public ProjectRowState(ProjectEntry entry, string recent)
        {
            Entry = entry;
            Type = "유형 확인 중";
            Git = "Git 확인 중";
            DateTimeOffset timestamp;
            Recent = DateTimeOffset.TryParse(recent, out timestamp)
                ? "최근 " + timestamp.ToLocalTime().ToString("MM-dd HH:mm") : "사용 기록 없음";
        }

        public void SetInfo(ProjectInfo info)
        {
            Info = info;
            Type = String.IsNullOrEmpty(info.Type) ? "유형 확인 불가" : info.Type;
            Git = !String.IsNullOrEmpty(info.Error) || String.IsNullOrEmpty(info.Repository)
                ? "Git 정보 확인 불가"
                : (String.IsNullOrEmpty(info.Branch) ? "분기 확인 불가" : info.Branch)
                    + " · 수정 " + info.Modified + " / 미추적 " + info.Untracked;
            Notify("Metadata");
        }

        public void FavoriteChanged() { Notify("Pinned"); }
        void Notify(string name)
        {
            var handler = PropertyChanged;
            if (handler != null) handler(this, new PropertyChangedEventArgs(name));
        }
        public override string ToString() { return Name + " · " + Metadata + " · " + Recent; }
    }
}
