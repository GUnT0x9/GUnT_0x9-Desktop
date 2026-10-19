using System;
using System.Windows;
using System.Windows.Controls;

namespace Gunt.ControlCenter.Views
{
    public sealed partial class MainWindow
    {
        readonly StackPanel pageActionHost = new StackPanel { Visibility = Visibility.Collapsed };
        ScrollViewer pageScroll;
        WrapPanel developerQuickActions;
        TextBlock developerEnvironmentDetails;
        bool projectContextOnRow = true;

        WrapPanel PageActions()
        {
            pageActionHost.Children.Clear();
            pageActionHost.Visibility = Visibility.Visible;
            var actions = new WrapPanel { Margin = new Thickness(0, 0, 0, 4) };
            pageActionHost.Children.Add(actions);
            return actions;
        }

        void ResetPageLayout(string next)
        {
            pageActionHost.Children.Clear();
            pageActionHost.Visibility = Visibility.Collapsed;
            pageActionHost.IsEnabled = true;
            pageScroll.Content = shell;
            pageScroll.VerticalScrollBarVisibility = ScrollBarVisibility.Auto;
            if (next != "wallpaper" && wallpaperWatcher != null) wallpaperWatcher.EnableRaisingEvents = false;
            if (next != "wallpaper" && wallpaperList != null) wallpaperList.ItemsSource = null;
            if (next != "development-sessions")
            {
                sessionPreviewTimer.Stop();
                sessionStepViews.Clear();
                sessionDraft = null;
            }
        }

        void SetGalleryViewport(DockPanel layout)
        {
            pageScroll.Content = layout;
            pageScroll.VerticalScrollBarVisibility = ScrollBarVisibility.Disabled;
        }
    }
}
