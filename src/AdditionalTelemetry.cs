using System;using System.Collections.Generic;using System.Diagnostics;using System.Globalization;using System.IO;using System.Linq;using System.Net.NetworkInformation;using System.Runtime.InteropServices;using System.Text;
public sealed class GuntAdditionalTelemetry {
 [DllImport("iphlpapi.dll")]static extern int GetBestInterface(uint dest,out uint index);
 [DllImport("kernel32.dll",CharSet=CharSet.Unicode)]static extern bool GetVolumeNameForVolumeMountPoint(string root,StringBuilder name,int length);
 string adapterId="";long received,sent,tick,sessionDown,sessionUp,storageTick;Dictionary<string,object> storage=new Dictionary<string,object>();
 public Dictionary<string,object> Collect(){var result=new Dictionary<string,object>();
  try{uint best;GetBestInterface(0x01010101,out best);var all=NetworkInterface.GetAllNetworkInterfaces().Where(x=>x.OperationalStatus==OperationalStatus.Up&&x.NetworkInterfaceType!=NetworkInterfaceType.Loopback).ToArray();NetworkInterface adapter=null;
   foreach(var item in all){try{if(item.GetIPProperties().GetIPv4Properties().Index==best){adapter=item;break;}}catch{}}
   if(adapter==null)adapter=all.OrderByDescending(x=>x.Speed).FirstOrDefault();
   if(adapter!=null){var stats=adapter.GetIPv4Statistics();long now=Stopwatch.GetTimestamp();double elapsed=tick==0?0:(now-tick)/(double)Stopwatch.Frequency;bool same=adapter.Id==adapterId&&stats.BytesReceived>=received&&stats.BytesSent>=sent;long down=same?stats.BytesReceived-received:0,up=same?stats.BytesSent-sent:0;
    if(same){sessionDown+=down;sessionUp+=up;}else{sessionDown=0;sessionUp=0;}
    bool valid=same&&elapsed>0&&elapsed<=10;result["NetHasRate"]=valid;result["NetDownBytesPerSecond"]=valid?(object)(down/elapsed):null;result["NetUpBytesPerSecond"]=valid?(object)(up/elapsed):null;result["NetAdapter"]=adapter.Name;result["NetAdapterId"]=adapter.Id;result["NetInterfaceType"]=adapter.NetworkInterfaceType.ToString();result["NetLinkBitsPerSecond"]=adapter.Speed;result["NetStatus"]=adapter.OperationalStatus.ToString();result["NetDownloadSessionBytes"]=sessionDown;result["NetUploadSessionBytes"]=sessionUp;
    received=stats.BytesReceived;sent=stats.BytesSent;tick=now;adapterId=adapter.Id;
   }else{result["NetHasRate"]=false;result["NetStatus"]="Disconnected";result["NetAdapter"]="연결 없음";tick=0;}
  }catch(Exception e){result["NetHasRate"]=false;result["NetStatus"]="Unavailable";result["NetworkError"]=e.Message;}
  if(storageTick==0||(Stopwatch.GetTimestamp()-storageTick)/(double)Stopwatch.Frequency>=10){storageTick=Stopwatch.GetTimestamp();var next=new Dictionary<string,object>();var volumes=new List<Dictionary<string,object>>();
   foreach(var d in DriveInfo.GetDrives()){try{if(d.DriveType!=DriveType.Fixed||!d.IsReady)continue;string drive=d.Name.Substring(0,1);var guid=new StringBuilder(128);GetVolumeNameForVolumeMountPoint(d.Name,guid,128);double used=100.0*(d.TotalSize-d.TotalFreeSpace)/d.TotalSize;volumes.Add(new Dictionary<string,object>{{"DriveLetter",drive+":"},{"Label",d.VolumeLabel},{"VolumeGuid",guid.ToString()},{"TotalBytes",d.TotalSize},{"FreeBytes",d.TotalFreeSpace},{"UsedBytes",d.TotalSize-d.TotalFreeSpace},{"UsedPercent",used}});string prefix="Storage"+drive;next[prefix+"Label"]=String.IsNullOrEmpty(d.VolumeLabel)?(drive=="C"?"시스템":"이름 없음"):d.VolumeLabel;next[prefix+"TotalBytes"]=d.TotalSize;next[prefix+"FreeBytes"]=d.TotalFreeSpace;next[prefix+"UsedBytes"]=d.TotalSize-d.TotalFreeSpace;next[prefix+"Percent"]=used;next[prefix+"Available"]=true;
   }catch{}}
   foreach(string drive in new[]{"C","D"})if(!next.ContainsKey("Storage"+drive+"Available"))next["Storage"+drive+"Available"]=false;
   next["Volumes"]=volumes;storage=next;
  }
  foreach(var pair in storage)result[pair.Key]=pair.Value;return result;
 }
}
