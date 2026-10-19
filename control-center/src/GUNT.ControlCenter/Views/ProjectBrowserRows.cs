using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Automation;
using System.Windows.Controls;
using System.Windows.Controls.Primitives;
using System.Windows.Data;
using Gunt.ControlCenter.Models;
using Gunt.ControlCenter.Services;
using Gunt.ControlCenter.ViewModels;

namespace Gunt.ControlCenter.Views
{
    public sealed partial class MainWindow
    {
        ProjectRowState[] developerRows = new ProjectRowState[0];
        readonly SemaphoreSlim projectMetadataSlots = new SemaphoreSlim(2);
        DesktopService projectMetadataService;
        Task projectSelectionRequest;
        int developerSelectionGeneration;
        bool WaitForDeveloperSelection(Action next)
        {
            var request=projectSelectionRequest;
            if(page!="developer-setup"||request==null||request.IsCompleted)return false;
            navigation.IsEnabled=false;
            request.ContinueWith(task=>{if(Dispatcher.HasShutdownStarted)return;Dispatcher.BeginInvoke((Action)delegate{navigation.IsEnabled=!busy;if(task.IsFaulted){vm.Status="프로젝트 선택 저장 실패: "+task.Exception.GetBaseException().Message;RestoreNavSelection();return;}next();});});
            return true;
        }

        bool IsProjectRowLaunchGesture(DependencyObject source)
        {
            while(source!=null&&source!=developerProjects)
            {
                if(source is ButtonBase)return false;
                if(source is ListBoxItem)return true;
                var text=source as FrameworkContentElement;
                source=text!=null?text.Parent:System.Windows.Media.VisualTreeHelper.GetParent(source);
            }
            return false;
        }

        ProjectEntry SelectedDeveloperEntry()
        {
            var row = developerProjects == null ? null : developerProjects.SelectedItem as ProjectRowState;
            return row == null ? null : row.Entry;
        }

        DataTemplate ProjectRowTemplate()
        {
            var row = new FrameworkElementFactory(typeof(DockPanel));
            row.AddHandler(FrameworkElement.LoadedEvent, new RoutedEventHandler(ProjectRowLoaded));
            var favorite = new FrameworkElementFactory(typeof(CheckBox));
            favorite.SetValue(DockPanel.DockProperty, Dock.Right);
            favorite.SetValue(ContentControl.ContentProperty, "즐겨찾기");
            favorite.SetValue(FrameworkElement.MarginProperty, new Thickness(8, 0, 0, 0));
            favorite.SetValue(FrameworkElement.VerticalAlignmentProperty, VerticalAlignment.Top);
            favorite.SetBinding(ToggleButton.IsCheckedProperty, new Binding("Pinned") { Mode = BindingMode.OneWay });
            favorite.SetBinding(AutomationProperties.NameProperty, new Binding("FavoriteName"));
            favorite.AddHandler(ButtonBase.ClickEvent, new RoutedEventHandler(ProjectFavoriteClick));
            row.AppendChild(favorite);
            var labels = new FrameworkElementFactory(typeof(StackPanel));
            var titleLine = new FrameworkElementFactory(typeof(DockPanel));
            var recent = new FrameworkElementFactory(typeof(TextBlock));
            recent.SetValue(DockPanel.DockProperty, Dock.Right);
            recent.SetValue(TextBlock.ForegroundProperty, Muted);
            recent.SetValue(TextBlock.FontSizeProperty, 11.0);
            recent.SetValue(FrameworkElement.MarginProperty, new Thickness(8, 0, 0, 0));
            recent.SetBinding(TextBlock.TextProperty, new Binding("Recent"));
            titleLine.AppendChild(recent);
            var title = new FrameworkElementFactory(typeof(TextBlock));
            title.SetBinding(TextBlock.TextProperty, new Binding("Name"));
            title.SetValue(TextBlock.TextTrimmingProperty, TextTrimming.CharacterEllipsis);
            titleLine.AppendChild(title); labels.AppendChild(titleLine);
            var metadata = new FrameworkElementFactory(typeof(TextBlock));
            metadata.SetBinding(TextBlock.TextProperty, new Binding("Metadata"));
            metadata.SetValue(TextBlock.ForegroundProperty, Muted);
            metadata.SetValue(TextBlock.FontSizeProperty, 12.0);
            metadata.SetValue(TextBlock.TextTrimmingProperty, TextTrimming.CharacterEllipsis);
            labels.AppendChild(metadata);
            row.SetBinding(ToolTipService.ToolTipProperty, new Binding("Directory"));
            row.AppendChild(labels);
            return new DataTemplate { VisualTree = row };
        }

        async void ProjectRowLoaded(object sender, RoutedEventArgs args)
        {
            var element = (FrameworkElement)sender;
            // A recycled container can receive a new project without another Loaded event.
            if (element.Tag == null)
            {
                element.Tag = true;
                element.DataContextChanged += delegate { LoadVisibleProjectRow(element); };
            }
            await EnrichProjectRow(element.DataContext as ProjectRowState);
        }

        async void LoadVisibleProjectRow(FrameworkElement element)
        {
            if (element.IsLoaded) await EnrichProjectRow(element.DataContext as ProjectRowState);
        }

        async void LoadVisibleProjectRowSelection(ProjectRowState row){await EnrichProjectRow(row);if(page=="developer-setup"&&row!=null&&row.Info!=null&&SelectedDeveloperEntry()==row.Entry)ShowProjectInfo(row.Entry,row.Info);}

        async Task EnrichProjectRow(ProjectRowState row)
        {
            if (row == null || row.Loading || row.Info != null) return;
            row.Loading = true;
            var service = projectMetadataService;
            await projectMetadataSlots.WaitAsync();
            try
            {
                if (page != "developer-setup" || !developerRows.Contains(row)) return;
                var info = await Task.Factory.StartNew(() =>
                {
                    try { return service.GitStatus(row.Entry); }
                    catch (Exception error) { return new ProjectInfo { Error = error.Message }; }
                });
                if(Dispatcher.HasShutdownStarted)return;
                await Dispatcher.InvokeAsync((Action)delegate{
                    if (page == "developer-setup" && developerRows.Contains(row))
                    {
                        row.SetInfo(info);
                        if (SelectedDeveloperEntry() == row.Entry) ShowProjectInfo(row.Entry, info);
                    }
                });
            }
            catch(TaskCanceledException) { }
            finally { row.Loading = false; projectMetadataSlots.Release(); }
        }

        void ProjectFavoriteClick(object sender, RoutedEventArgs args)
        {
            args.Handled = true;
            var check = (CheckBox)sender;
            var row = check.DataContext as ProjectRowState;
            if (row == null) return;
            bool target = !row.Entry.Pinned;
            // Restore the one-way binding immediately; persist first, then publish state.
            check.SetBinding(ToggleButton.IsCheckedProperty, new Binding("Pinned") { Mode = BindingMode.OneWay });
            Run(() =>
            {
                var service = new DesktopService(root);
                var project = service.RegisterDiscovered(service.Json.Deserialize<ProjectEntry>(service.Json.Serialize(row.Entry)));
                project.Pinned = target;
                service.SaveProject(project);
                return "즐겨찾기를 저장했습니다.";
            }, () =>
            {
                row.Entry.Pinned = target;
                row.FavoriteChanged();
                if (SelectedDeveloperEntry() == row.Entry) RefreshDeveloperDetails(row.Entry);
            });
        }
    }
}
