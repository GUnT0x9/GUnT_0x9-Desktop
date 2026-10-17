using System;
using System.IO;
using System.Reflection;
using System.Runtime.CompilerServices;
using Google.Protobuf;
using Google.Protobuf.WellKnownTypes;
using GrpcDotNetNamedPipes;
using Lively.Grpc.Common.Proto.Settings;
public static class LivelyBridgeBootstrap {
 public static int Main(string[] args){
  try{
   string directory=args[0];
   AppDomain.CurrentDomain.AssemblyResolve+=delegate(object sender,ResolveEventArgs e){string file=Path.Combine(directory,new AssemblyName(e.Name).Name+".dll");return File.Exists(file)?Assembly.LoadFrom(file):null;};
   return LivelyBridgeCommand.Run(args);
  }catch(Exception e){Console.Error.WriteLine("Lively 연동 오류: "+e.Message);return 1;}
 }
}
public static class LivelyBridgeCommand {
 [MethodImpl(MethodImplOptions.NoInlining)]
 public static int Run(string[] args){
  var client=new SettingsService.SettingsServiceClient(new NamedPipeChannel(".","Grpc_LIVELY:DESKTOPWALLPAPERSYSTEM"+Environment.UserName));
  var current=client.GetSettings(new Empty(),deadline:DateTime.UtcNow.AddSeconds(4));
  if(args.Length>1&&args[1]=="policy"){
   for(int i=2;i<args.Length;i++){
    var pair=args[i].Split('=');bool enabled=pair[1]=="true";var rule=enabled?AppRules.Pause:AppRules.Ignore;
    switch(pair[0]){
     case "battery":current.BatteryPause=rule;break;
     case "fullscreen":current.AppFullscreenPause=rule;break;
     case "covered":current.ProcessMonitorAlogorithm=enabled?ProcessMonitorRule.Grid:ProcessMonitorRule.Foreground;current.AppFocusPause=AppRules.Ignore;break;
     case "saver":current.PowerSaveModePause=rule;break;
     default:throw new ArgumentException("지원하지 않는 정책입니다: "+pair[0]);
    }
   }
   client.SetSettings(current,deadline:DateTime.UtcNow.AddSeconds(4));
   current=client.GetSettings(new Empty(),deadline:DateTime.UtcNow.AddSeconds(4));
  }
  Console.WriteLine(new JsonFormatter(new JsonFormatter.Settings(true)).Format(current));return 0;
 }
}
