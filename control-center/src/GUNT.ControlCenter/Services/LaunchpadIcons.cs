using System;
using System.Linq;
using System.IO;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Threading;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Interop;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using Gunt.ControlCenter.Models;

namespace Gunt.ControlCenter.Services
{
    public sealed class LaunchpadIcons
    {
        readonly object gate = new object ();
        readonly Dictionary<string, ImageSource> cache = new Dictionary<string, ImageSource>();
        readonly Queue<string> order = new Queue<string>();
        readonly SemaphoreSlim workers = new SemaphoreSlim(2);
        readonly string root;
        public LaunchpadIcons(string directory)
        {
            root = directory;
        }

        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        struct FileInfo
        {
            public IntPtr Icon;
            public int Index;
            public uint Attributes;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 260)]
            public string DisplayName;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 80)]
            public string TypeName;
        }

        [DllImport("shell32.dll", CharSet = CharSet.Unicode)]
        static extern IntPtr SHGetFileInfo(string path, uint attributes, out FileInfo info, uint size, uint flags);
        [DllImport("user32.dll")]
        static extern bool DestroyIcon(IntPtr icon);
        [DllImport("gdi32.dll")]
        static extern bool DeleteObject(IntPtr bitmap);
        [StructLayout(LayoutKind.Sequential)]
        struct Size
        {
            public int Width, Height;
        }

        [ComImport, Guid("bcc18b79-ba16-442f-80c4-8a59c30c463b"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
        interface IImageFactory
        {
            [PreserveSig]
            int GetImage(Size size, int flags, out IntPtr bitmap);
        }

        [DllImport("shell32.dll", CharSet = CharSet.Unicode, PreserveSig = false)]
        static extern void SHCreateItemFromParsingName(string path, IntPtr bind, ref Guid iid, [MarshalAs(UnmanagedType.Interface)] out IImageFactory factory);
        public static readonly string[] Poses =
        {
            "default",
            "coding",
            "ai",
            "search",
            "utility",
            "gaming",
            "settings",
            "sleep",
            "network",
            "folder"
        };
        public string PosePath(string pose, int pixels)
        {
            if (!Array.Exists(Poses, x => x == pose))
                return null;
            string path = Path.Combine(root, "assets", "branding", "mascot", pose, "128.png");
            if (File.Exists(path))
                return path;
            if (pose == "default" || pose == "coding")
                return Path.Combine(root, "assets", "branding", "icons", "gunt-app-128.png");
            return null;
        }

        static ImageSource ShellImage(string path)
        {
            IImageFactory factory = null;
            IntPtr bitmap = IntPtr.Zero;
            try
            {
                Guid iid = typeof(IImageFactory).GUID;
                SHCreateItemFromParsingName(path, IntPtr.Zero, ref iid, out factory);
                if (factory.GetImage(new Size { Width = 128, Height = 128 }, 1, out bitmap) != 0)
                    return null;
                var source = Imaging.CreateBitmapSourceFromHBitmap(bitmap, IntPtr.Zero, Int32Rect.Empty, BitmapSizeOptions.FromEmptyOptions());
                source.Freeze();
                return source;
            }
            finally
            {
                if (bitmap != IntPtr.Zero)
                    DeleteObject(bitmap);
                if (factory != null)
                    Marshal.FinalReleaseComObject(factory);
            }
        }

        public Task<ImageSource> Get(ApplicationEntry app, string pose, bool mascot, CancellationToken cancellation = default(CancellationToken))
        {
            string custom = mascot ? PosePath(pose, 128) : null;
            string path = custom ?? app.Icon ?? (new[]
            {
                "exe",
                "shortcut",
                "folder"
            }.Contains(app.Kind) ? app.Target : null);
            if (path == null && (app.Kind == "project" || app.Kind == "group"))
                path = "stock:folder";
            if (path == null && app.Kind == "website")
                path = "stock:website";
            string key = path ?? ("builtin:" + app.Kind);
            ImageSource source;
            lock (gate)
            {
                if (cache.TryGetValue(key, out source))
                    return Task.FromResult(source);
            }

            return Task.Run(async () =>
            {
                await workers.WaitAsync(cancellation).ConfigureAwait(false);
                try
                {
                    cancellation.ThrowIfCancellationRequested();
                    lock (gate)
                        if (cache.TryGetValue(key, out source))
                            return source;
                    try
                    {
                        if (path != null && path.EndsWith(".png", StringComparison.OrdinalIgnoreCase) && File.Exists(path))
                        {
                            var image = new BitmapImage();
                            image.BeginInit();
                            image.CacheOption = BitmapCacheOption.OnLoad;
                            image.DecodePixelWidth = 128;
                            image.UriSource = new Uri(path);
                            image.EndInit();
                            image.Freeze();
                            source = image;
                        }
                        else if (path != null)
                        {
                            if (!path.StartsWith("stock:", StringComparison.Ordinal))
                            {
                                try
                                {
                                    source = ShellImage(path);
                                }
                                catch (Exception)
                                {
                                    source = null;
                                }
                            }

                            if (source == null)
                            {
                                FileInfo info;
                                bool stock = path.StartsWith("stock:", StringComparison.Ordinal);
                                string nativePath = stock ? (path == "stock:folder" ? "folder" : "website.url") : path;
                                uint attributes = stock && path == "stock:folder" ? 16u : 128u;
                                uint flags = 0x100u | (stock ? 0x10u : 0u);
                                if (SHGetFileInfo(nativePath, attributes, out info, (uint)Marshal.SizeOf(typeof(FileInfo)), flags) != IntPtr.Zero && info.Icon != IntPtr.Zero)
                                {
                                    try
                                    {
                                        source = Imaging.CreateBitmapSourceFromHIcon(info.Icon, Int32Rect.Empty, BitmapSizeOptions.FromWidthAndHeight(64, 64));
                                        source.Freeze();
                                    }
                                    finally
                                    {
                                        DestroyIcon(info.Icon);
                                    }
                                }
                            }
                        }
                    }
                    catch (Exception)
                    {
                        source = null;
                    }

                    if (source == null && new[]
                    {
                        "shortcut",
                        "exe",
                        "packaged"
                    }.Contains(app.Kind))
                    {
                        source = Imaging.CreateBitmapSourceFromHIcon(System.Drawing.SystemIcons.Application.Handle, Int32Rect.Empty, BitmapSizeOptions.FromWidthAndHeight(64, 64));
                        source.Freeze();
                    }

                    if (source == null)
                    {
                        var image = new BitmapImage();
                        image.BeginInit();
                        image.CacheOption = BitmapCacheOption.OnLoad;
                        image.DecodePixelWidth = 128;
                        image.UriSource = new Uri(Path.Combine(root, "assets", "branding", "icons", "gunt-app-128.png"));
                        image.EndInit();
                        image.Freeze();
                        source = image;
                    }

                    lock (gate)
                    {
                        if (!cache.ContainsKey(key))
                        {
                            cache.Add(key, source);
                            order.Enqueue(key);
                            while (order.Count > 128)
                                cache.Remove(order.Dequeue());
                        }
                    }

                    return source;
                }
                finally
                {
                    workers.Release();
                }
            });
        }
    }
}
