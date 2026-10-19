using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.InteropServices;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Interop;
using System.Windows.Media;

namespace Gunt.ControlCenter.Views
{
    internal static partial class UxTheme
    {
        [DllImport("dwmapi.dll")] static extern int DwmSetWindowAttribute(IntPtr window, int attribute, ref int value, int size);

        internal static Window Dialog(Window owner, string title, double width, double height)
        {
            var window = new Window { Title = title, Owner = owner, Width = width, Height = height,
                Background = Background, Foreground = Text, FontFamily = owner.FontFamily, FontSize = 14, Icon = owner.Icon,
                UseLayoutRounding = true, SnapsToDevicePixels = true,
                WindowStartupLocation = WindowStartupLocation.CenterOwner };
            window.Resources.MergedDictionaries.Add(Resources);
            window.SourceInitialized += delegate
            {
                var handle = new WindowInteropHelper(window).Handle;
                int dark = 1; DwmSetWindowAttribute(handle, 20, ref dark, 4);
                var screen = System.Windows.Forms.Screen.FromHandle(new WindowInteropHelper(owner).Handle);
                double scale = GuntLayout.Scale(screen);
                window.MaxWidth = Math.Max(280, screen.WorkingArea.Width / scale - 16);
                window.MaxHeight = Math.Max(240, Math.Min(screen.WorkingArea.Height / scale - 16, owner.ActualHeight - 16));
            };
            return window;
        }

        internal static int Confirm(Window owner, string title, string explanation, params string[] choices)
        {
            int answer = choices.Length - 1;
            var window = Dialog(owner, title, 560, 360);
            window.ResizeMode = ResizeMode.NoResize;
            window.SizeToContent = SizeToContent.Height;
            var layout = new DockPanel { Margin = new Thickness(16) };
            var buttons = new WrapPanel { HorizontalAlignment = HorizontalAlignment.Right, Margin = new Thickness(0, 16, 0, 0) };
            DockPanel.SetDock(buttons, Dock.Bottom); layout.Children.Add(buttons);
            for (int index = 0; index < choices.Length; index++)
            {
                int value = index;
                var button = new Button { Content = choices[index], IsCancel = index == choices.Length - 1 };
                button.Click += delegate { answer = value; window.DialogResult = true; };
                buttons.Children.Add(button);
            }
            layout.Children.Add(new ScrollViewer { MaxHeight = Math.Max(120, Math.Min(300, owner.ActualHeight - 150)),
                VerticalScrollBarVisibility = ScrollBarVisibility.Auto,
                Content = new TextBlock { Text = explanation, TextWrapping = TextWrapping.Wrap } });
            window.Content = layout;
            window.ShowDialog();
            return answer;
        }
    }

    public sealed partial class MainWindow
    {
        Window CreateEditorWindow(string title, out StackPanel panel)
        {
            var window = UxTheme.Dialog(this, title, 620, 650);
            var layout = new DockPanel { Margin = new Thickness(16) };
            var actions = new WrapPanel { HorizontalAlignment = HorizontalAlignment.Right, Margin = new Thickness(0, 12, 0, 0) };
            DockPanel.SetDock(actions, Dock.Bottom); layout.Children.Add(actions);
            window.Tag = actions;
            panel = new StackPanel();
            layout.Children.Add(new ScrollViewer { Content = panel, VerticalScrollBarVisibility = ScrollBarVisibility.Auto,
                HorizontalScrollBarVisibility = ScrollBarVisibility.Disabled });
            window.Content = layout;
            return window;
        }

        static IEnumerable<string> EditorValues(DependencyObject element)
        {
            var text = element as TextBox;
            if (text != null) { yield return text.Text; yield break; }
            var choice = element as ComboBox;
            if (choice != null) { yield return Convert.ToString(choice.SelectedValue); yield break; }
            var toggle = element as CheckBox;
            if (toggle != null) { yield return Convert.ToString(toggle.IsChecked); yield break; }
            var list = element as ListBox;
            if (list != null) { yield return String.Join(";", list.Items.Cast<object>().Select(Convert.ToString)); yield break; }
            foreach (object child in LogicalTreeHelper.GetChildren(element))
            {
                var nested = child as DependencyObject;
                if (nested != null) foreach (string value in EditorValues(nested)) yield return value;
            }
        }
    }
}
