using System;using System.Linq;using System.IO;using System.Collections.Generic;using System.Runtime.InteropServices;using System.Threading;using System.Threading.Tasks;using System.Windows;using System.Windows.Interop;using System.Windows.Media;using System.Windows.Media.Imaging;
using Gunt.ControlCenter.Models;
namespace Gunt.ControlCenter.Services {
 public sealed class LaunchpadIcons {
  readonly object gate=new object();readonly Dictionary<string,ImageSource> cache=new Dictionary<string,ImageSource>();readonly Queue<string> order=new Queue<string>();readonly SemaphoreSlim workers=new SemaphoreSlim(2);readonly string root;
  public LaunchpadIcons(string directory){root=directory;}
  [StructLayout(LayoutKind.Sequential,CharSet=CharSet.Unicode)]struct FileInfo {public IntPtr Icon;public int Index;public uint Attributes;[MarshalAs(UnmanagedType.ByValTStr,SizeConst=260)]public string DisplayName;[MarshalAs(UnmanagedType.ByValTStr,SizeConst=80)]public string TypeName;}
  [DllImport("shell32.dll",CharSet=CharSet.Unicode)]static extern IntPtr SHGetFileInfo(string path,uint attributes,out FileInfo info,uint size,uint flags);
  [DllImport("user32.dll")]static extern bool DestroyIcon(IntPtr icon);
  [DllImport("gdi32.dll")]static extern bool DeleteObject(IntPtr bitmap);
  [StructLayout(LayoutKind.Sequential)]struct Size {public int Width,Height;}
  [ComImport,Guid("bcc18b79-ba16-442f-80c4-8a59c30c463b"),InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]interface IImageFactory {[PreserveSig]int GetImage(Size size,int flags,out IntPtr bitmap);}
  [DllImport("shell32.dll",CharSet=CharSet.Unicode,PreserveSig=false)]static extern void SHCreateItemFromParsingName(string path,IntPtr bind,ref Guid iid,[MarshalAs(UnmanagedType.Interface)]out IImageFactory factory);
  public static readonly string[] Poses={"default","coding","ai","search","utility","gaming","settings","sleep","network","folder"};
  public string PosePath(string pose,int pixels){if(!Array.Exists(Poses,x=>x==pose))return null;string path=Path.Combine(root,"assets","branding","mascot",pose,"128.png");if(File.Exists(path))return path;if(pose=="default"||pose=="coding")return Path.Combine(root,"assets","branding","icons","gunt-app-128.png");return null;}
  public Task<ImageSource> Get(ApplicationEntry app,string pose,bool mascot) {
   string custom=mascot?PosePath(pose,128):null;string path=custom??app.Icon??(new[]{"exe","shortcut","folder"}.Contains(app.Kind)?app.Target:null);
   string key=path??("builtin:"+app.Kind);ImageSource source;lock(gate){if(cache.TryGetValue(key,out source))return Task.FromResult(source);}
   return Task.Factory.StartNew(()=>{workers.Wait();try{lock(gate)if(cache.TryGetValue(key,out source))return source;
    try{if(path!=null&&path.EndsWith(".png",StringComparison.OrdinalIgnoreCase)&&File.Exists(path)){var image=new BitmapImage();image.BeginInit();image.CacheOption=BitmapCacheOption.OnLoad;image.DecodePixelWidth=128;image.UriSource=new Uri(path);image.EndInit();image.Freeze();source=image;}
     else if(path!=null){if(path.StartsWith("shell:",StringComparison.OrdinalIgnoreCase)){IImageFactory factory=null;IntPtr bitmap=IntPtr.Zero;try{Guid iid=typeof(IImageFactory).GUID;SHCreateItemFromParsingName(path,IntPtr.Zero,ref iid,out factory);if(factory.GetImage(new Size{Width=128,Height=128},1,out bitmap)==0){source=Imaging.CreateBitmapSourceFromHBitmap(bitmap,IntPtr.Zero,Int32Rect.Empty,BitmapSizeOptions.FromEmptyOptions());source.Freeze();}}finally{if(bitmap!=IntPtr.Zero)DeleteObject(bitmap);if(factory!=null)Marshal.FinalReleaseComObject(factory);}}
      else{FileInfo info;if(SHGetFileInfo(path,0,out info,(uint)Marshal.SizeOf(typeof(FileInfo)),0x100|0x1000)!=IntPtr.Zero&&info.Icon!=IntPtr.Zero){try{source=Imaging.CreateBitmapSourceFromHIcon(info.Icon,Int32Rect.Empty,BitmapSizeOptions.FromWidthAndHeight(64,64));source.Freeze();}finally{DestroyIcon(info.Icon);}}}}
    }catch(Exception){source=null;}
    if(source==null){var image=new BitmapImage();image.BeginInit();image.CacheOption=BitmapCacheOption.OnLoad;image.DecodePixelWidth=128;image.UriSource=new Uri(Path.Combine(root,"assets","branding","icons","gunt-app-128.png"));image.EndInit();image.Freeze();source=image;}
    lock(gate){if(!cache.ContainsKey(key)){cache.Add(key,source);order.Enqueue(key);while(order.Count>128)cache.Remove(order.Dequeue());}}return source;
   }finally{workers.Release();}});
  }
 }
}
