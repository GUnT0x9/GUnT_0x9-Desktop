using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Globalization;
using System.Linq;
using System.Windows;
using System.Windows.Automation;
using System.Windows.Controls;
using System.Windows.Controls.Primitives;
using System.Windows.Data;
using System.Windows.Input;
using System.Windows.Media;
using Gunt.ControlCenter.Models;

namespace Gunt.ControlCenter.Views
{
    public sealed partial class MainWindow
    {
        // The built-in recycling list virtualizes bands; each realized band contains only 1–6 tiles.
        sealed class WallpaperRow : INotifyPropertyChanged
        {
            WallpaperEntry entry;
            public WallpaperEntry Entry {get{return entry;}set{entry=value;var handler=PropertyChanged;if(handler!=null)foreach(string name in new[]{"Title","Detail","Assignment","Tooltip"})handler(this,new PropertyChangedEventArgs(name));}}
            public string Tooltip{get{return Title+"\n"+Detail+"\n"+Assignment;}}
            bool selected;
            public string Title { get { return Entry.Title; } }
            public string Detail { get { return (Entry.Favorite ? "즐겨찾기 · " : "") + Entry.Type; } }
            public string Assignment { get { return String.IsNullOrEmpty(Entry.Assigned) ? "화면에 적용되지 않음" : "적용 중 · " + Entry.Assigned; } }
            public string Selection { get { return selected ? "선택됨" : ""; } }
            public bool Selected
            {
                get { return selected; }
                set
                {
                    if (selected == value) return;
                    selected = value;
                    var handler = PropertyChanged;
                    if (handler != null) { handler(this, new PropertyChangedEventArgs("Selected")); handler(this, new PropertyChangedEventArgs("Selection")); }
                }
            }
            public event PropertyChangedEventHandler PropertyChanged;
            public override string ToString() { return Title + " · " + Detail + " · " + Assignment; }
        }
        sealed class WallpaperBand
        {
            public WallpaperRow[] Entries { get; set; }
            public int Columns { get; set; }
            public override string ToString() { return String.Join(", ", Entries.Select(e => e.Title)); }
        }
        sealed class ThumbnailRatio : IValueConverter
        {
            public object Convert(object value, Type target, object parameter, CultureInfo culture)
            {
                double width = value is double ? (double)value : 0;
                return width > 0 ? width * 9.0 / 16.0 : 100;
            }
            public object ConvertBack(object value, Type target, object parameter, CultureInfo culture) { throw new NotSupportedException(); }
        }
        WallpaperRow selectedGalleryRow;
        WallpaperRow[] filteredWallpapers = new WallpaperRow[0];
        int galleryColumns = 1;
        TextBlock galleryEmpty;

        void ConfigureWallpaperGrid()
        {
            wallpaperList.Height = Math.Max(180,Math.Min(380,ActualHeight-440));
            // A band has no selection chrome. Selection/focus belong to its wallpaper buttons.
            var bandStyle = new Style(typeof(ListBoxItem));
            bandStyle.Setters.Add(new Setter(Control.PaddingProperty, new Thickness(0)));
            bandStyle.Setters.Add(new Setter(Control.HorizontalContentAlignmentProperty, HorizontalAlignment.Stretch));
            bandStyle.Setters.Add(new Setter(UIElement.FocusableProperty, false));
            bandStyle.Setters.Add(new Setter(Control.TemplateProperty, (ControlTemplate)System.Windows.Markup.XamlReader.Parse(@"<ControlTemplate xmlns='http://schemas.microsoft.com/winfx/2006/xaml/presentation' TargetType='ListBoxItem'><ContentPresenter/></ControlTemplate>")));
            wallpaperList.ItemContainerStyle = bandStyle;
            var bands = new FrameworkElementFactory(typeof(ItemsControl));
            bands.SetBinding(ItemsControl.ItemsSourceProperty, new Binding("Entries"));
            var grid = new FrameworkElementFactory(typeof(UniformGrid));
            grid.SetBinding(UniformGrid.ColumnsProperty, new Binding("Columns"));
            bands.SetValue(ItemsControl.ItemsPanelProperty, new ItemsPanelTemplate(grid));
            bands.SetValue(ItemsControl.ItemTemplateProperty, WallpaperTileTemplate());
            wallpaperList.ItemTemplate = new DataTemplate { VisualTree = bands };
            wallpaperList.SizeChanged += delegate
            {
                int columns = Math.Max(1, Math.Min(6, (int)Math.Floor(Math.Max(1, wallpaperList.ActualWidth - 16) / 200)));
                if (columns == galleryColumns) return;
                galleryColumns = columns; BuildWallpaperBands();
            };
            wallpaperList.PreviewKeyDown += WallpaperGridKeyDown;
            galleryEmpty = new TextBlock { Text = "표시할 배경이 없습니다. 검색어나 즐겨찾기 필터를 확인하세요.", Foreground = Muted, TextWrapping = TextWrapping.Wrap, Visibility = Visibility.Collapsed, Margin = new Thickness(0, 0, 0, 8) };
            content.Children.Add(galleryEmpty);
        }

        DataTemplate WallpaperTileTemplate()
        {
            var button = new FrameworkElementFactory(typeof(Button));
            button.SetValue(FrameworkElement.MarginProperty, new Thickness(4));
            button.SetValue(Control.PaddingProperty, new Thickness(6));
            button.SetValue(Control.HorizontalContentAlignmentProperty, HorizontalAlignment.Stretch);
            button.SetBinding(AutomationProperties.NameProperty, new Binding("Title"));
            button.SetBinding(ToolTipService.ToolTipProperty, new Binding("Tooltip"));
            var selectedStyle = new Style(typeof(Button), (Style)UxTheme.Resources[typeof(Button)]);
            var selected = new DataTrigger { Binding = new Binding("Selected"), Value = true };
            selected.Setters.Add(new Setter(Control.BorderBrushProperty, Accent));
            selected.Setters.Add(new Setter(Control.FontWeightProperty, FontWeights.SemiBold));
            selectedStyle.Triggers.Add(selected);
            button.SetValue(FrameworkElement.StyleProperty, selectedStyle);
            button.AddHandler(ButtonBase.ClickEvent, new RoutedEventHandler(WallpaperTileClick));
            button.AddHandler(Control.MouseDoubleClickEvent, new MouseButtonEventHandler(WallpaperTileDoubleClick));
            var body = new FrameworkElementFactory(typeof(StackPanel));
            var thumbnail=new FrameworkElementFactory(typeof(Grid));
            var fallback=new FrameworkElementFactory(typeof(TextBlock));fallback.SetValue(TextBlock.TextProperty,"썸네일 없음");fallback.SetValue(TextBlock.ForegroundProperty,Muted);fallback.SetValue(TextBlock.FontSizeProperty,12.0);fallback.SetValue(FrameworkElement.VerticalAlignmentProperty,VerticalAlignment.Center);fallback.SetValue(FrameworkElement.HorizontalAlignmentProperty,HorizontalAlignment.Center);
            var fallbackStyle=new Style(typeof(TextBlock));fallbackStyle.Setters.Add(new Setter(UIElement.VisibilityProperty,Visibility.Collapsed));var missing=new DataTrigger{Binding=new Binding("Source"){ElementName="Thumbnail"},Value=null};missing.Setters.Add(new Setter(UIElement.VisibilityProperty,Visibility.Visible));fallbackStyle.Triggers.Add(missing);fallback.SetValue(FrameworkElement.StyleProperty,fallbackStyle);thumbnail.AppendChild(fallback);
            var image = new FrameworkElementFactory(typeof(Image));image.Name="Thumbnail";
            image.SetValue(Image.StretchProperty, Stretch.UniformToFill);
            image.SetValue(UIElement.ClipToBoundsProperty, true);
            image.SetBinding(FrameworkElement.HeightProperty, new Binding("ActualWidth") { RelativeSource = new RelativeSource(RelativeSourceMode.Self), Converter = new ThumbnailRatio() });
            image.AddHandler(FrameworkElement.LoadedEvent, new RoutedEventHandler(LoadGalleryThumbnail));
            thumbnail.AppendChild(image);body.AppendChild(thumbnail);
            var title = new FrameworkElementFactory(typeof(TextBlock));
            title.SetBinding(TextBlock.TextProperty, new Binding("Title"));
            title.SetValue(TextBlock.TextTrimmingProperty, TextTrimming.CharacterEllipsis);
            title.SetValue(FrameworkElement.MarginProperty, new Thickness(0, 8, 0, 4));
            body.AppendChild(title);
            foreach (var field in new[] { "Detail", "Assignment", "Selection" })
            {
                var text = new FrameworkElementFactory(typeof(TextBlock));
                text.SetBinding(TextBlock.TextProperty, new Binding(field));
                text.SetValue(TextBlock.FontSizeProperty, 12.0);
                text.SetValue(TextBlock.ForegroundProperty, Muted);
                text.SetValue(TextBlock.TextTrimmingProperty, TextTrimming.CharacterEllipsis);
                text.SetValue(FrameworkElement.MinHeightProperty, 16.0);
                body.AppendChild(text);
            }
            button.AppendChild(body);
            return new DataTemplate { VisualTree = button };
        }

        void WallpaperTileClick(object sender, RoutedEventArgs args)
        {
            args.Handled = true;
            SelectGalleryRow(((FrameworkElement)sender).DataContext as WallpaperRow);
        }
        void WallpaperTileDoubleClick(object sender, MouseButtonEventArgs args)
        {
            var row = ((FrameworkElement)sender).DataContext as WallpaperRow;
            if (row == null) return;
            SelectGalleryRow(row); PreviewThumbnail(row.Entry); args.Handled = true;
        }
        void SelectGalleryRow(WallpaperRow row)
        {
            if (selectedGalleryRow != null) selectedGalleryRow.Selected = false;
            selectedGalleryRow = row;
            if (row != null) row.Selected = true;
        }
        void BuildWallpaperBands()
        {
            if (wallpaperList == null) return;
            var bands = new List<WallpaperBand>();
            for (int index = 0; index < filteredWallpapers.Length; index += galleryColumns)
                bands.Add(new WallpaperBand { Columns = galleryColumns, Entries = filteredWallpapers.Skip(index).Take(galleryColumns).ToArray() });
            wallpaperList.ItemsSource = bands;
            if (galleryEmpty != null) galleryEmpty.Visibility = bands.Count == 0 ? Visibility.Visible : Visibility.Collapsed;
        }
        void WallpaperGridKeyDown(object sender, KeyEventArgs args)
        {
            var focus=Keyboard.FocusedElement as FrameworkElement;var focusedRow=focus==null?null:focus.DataContext as WallpaperRow;if(focusedRow!=null)SelectGalleryRow(focusedRow);
            int index = Array.IndexOf(filteredWallpapers, selectedGalleryRow);
            int delta = args.Key == Key.Down ? galleryColumns : args.Key == Key.Up ? -galleryColumns : args.Key == Key.Right ? 1 : args.Key == Key.Left ? -1 : 0;
            if (delta != 0 && filteredWallpapers.Length > 0)
            {
                index = Math.Max(0, Math.Min(filteredWallpapers.Length - 1, Math.Max(0, index) + delta));
                SelectGalleryRow(filteredWallpapers[index]);
                var band = wallpaperList.Items[index / galleryColumns];
                wallpaperList.ScrollIntoView(band);
                wallpaperList.UpdateLayout();
                var container = wallpaperList.ItemContainerGenerator.ContainerFromItem(band) as ListBoxItem;
                if (container != null) FocusGalleryTile(container, selectedGalleryRow);
                args.Handled = true;
            }
            else if (args.Key == Key.Enter && selectedGalleryRow != null)
            {
                PreviewThumbnail(selectedGalleryRow.Entry); args.Handled = true;
            }
        }
        static bool FocusGalleryTile(DependencyObject parent, WallpaperRow row)
        {
            for (int i = 0; i < VisualTreeHelper.GetChildrenCount(parent); i++)
            {
                var child = VisualTreeHelper.GetChild(parent, i);
                var button = child as Button;
                if (button != null && ReferenceEquals(button.DataContext, row)) { button.Focus(); return true; }
                if (FocusGalleryTile(child, row)) return true;
            }
            return false;
        }
    }
}
