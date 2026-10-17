if(!('GuntDesktopNative' -as [type])) {
Add-Type @'
using System;using System.Runtime.InteropServices;using System.Text;
public static class GuntDesktopNative {
 [DllImport("user32.dll",CharSet=CharSet.Unicode,SetLastError=true)] public static extern bool SystemParametersInfo(uint action,uint param,string value,uint flags);
 [DllImport("user32.dll")] public static extern bool SetSysColors(int count,int[] elements,int[] colors);
 [DllImport("user32.dll",CharSet=CharSet.Unicode)] public static extern IntPtr FindWindow(string c,string n);
 [DllImport("user32.dll",CharSet=CharSet.Unicode)] public static extern IntPtr FindWindowEx(IntPtr p,IntPtr after,string c,string n);
 [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h,int cmd);
 [DllImport("user32.dll",CharSet=CharSet.Unicode)] public static extern IntPtr SendMessageTimeout(IntPtr h,uint m,IntPtr w,string l,uint f,uint t,out IntPtr result);
 [DllImport("user32.dll")] public static extern bool RegisterHotKey(IntPtr h,int id,uint mods,uint key);
 [DllImport("user32.dll")] public static extern bool UnregisterHotKey(IntPtr h,int id);
 public static void Icons(bool show) {
   IntPtr parent=IntPtr.Zero;
   while((parent=FindWindowEx(IntPtr.Zero,parent,null,null))!=IntPtr.Zero){
     IntPtr view=FindWindowEx(parent,IntPtr.Zero,"SHELLDLL_DefView",null);
     if(view!=IntPtr.Zero){IntPtr list=FindWindowEx(view,IntPtr.Zero,"SysListView32",null);if(list!=IntPtr.Zero)ShowWindow(list,show?5:0);}
   }
 }
 public static void Broadcast(){IntPtr r;SendMessageTimeout(new IntPtr(0xffff),0x001a,IntPtr.Zero,"ImmersiveColorSet",2,2000,out r);}
}
'@
}
