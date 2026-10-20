using System;using System.Runtime.InteropServices;
// Shared by the WinForms registration host and the WPF preferences editor.
public static class GuntLaunchpadHotkey {
 [DllImport("user32.dll",SetLastError=true)]public static extern bool RegisterHotKey(IntPtr window,int id,uint modifiers,uint key);
 [DllImport("user32.dll")]public static extern bool UnregisterHotKey(IntPtr window,int id);
 public static bool TryParse(string shortcut,out uint modifiers,out uint key){modifiers=0x4000;key=0;if(String.IsNullOrEmpty(shortcut))return false;var parts=shortcut.Split('+');if(parts.Length<2)return false;for(int i=0;i<parts.Length-1;i++){uint bit=parts[i]=="Ctrl"?2u:parts[i]=="Alt"?1u:parts[i]=="Shift"?4u:0u;if(bit==0||(modifiers&bit)!=0)return false;modifiers|=bit;}string tail=parts[parts.Length-1];if(tail.Length==1&&tail[0]>='A'&&tail[0]<='Z')key=tail[0];else if(tail.Length==1&&tail[0]>='0'&&tail[0]<='9')key=tail[0];else if(tail.StartsWith("F")){int value;if(Int32.TryParse(tail.Substring(1),out value)&&value>=1&&value<=24)key=(uint)(0x6F+value);}return key!=0&&(modifiers&3)!=0;}
 public static bool Probe(string shortcut){uint modifiers,key;if(!TryParse(shortcut,out modifiers,out key))return false;bool result=RegisterHotKey(IntPtr.Zero,195,modifiers,key);if(result)UnregisterHotKey(IntPtr.Zero,195);return result;}
}
