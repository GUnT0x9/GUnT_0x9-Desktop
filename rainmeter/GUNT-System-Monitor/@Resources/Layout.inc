[Panel]
Meter=Shape
Shape=Rectangle 0.5,0.5,(#PanelWidth#*#Scale#-1),(#PanelHeight#*#Scale#-1),(#PanelRadius#*#Scale#) | Fill Color #Panel# | StrokeWidth 1 | Stroke Color #Border#
DynamicVariables=1
[Title]
Meter=String
MeterStyle=BaseText
Text=시스템 모니터
FontFace=#HeadingFont#
FontSize=(11.25*#Scale#)
Y=(14*#Scale#)
W=((#PanelWidth#-130)*#Scale#)
[Refresh]
Meter=String
MeterStyle=SecondaryText
Text=새로고침
X=((#PanelWidth#-116)*#Scale#)
Y=(25*#Scale#)
W=(52*#Scale#)
H=(28*#Scale#)
StringAlign=CenterCenter
SolidColor=14,14,18,1
MouseActionCursor=1
LeftMouseUpAction=[!Refresh]
ToolTipText=시스템 모니터 새로고침
[Mode]
Meter=String
MeterStyle=BaseText
Text=#ToggleLabel#
FontSize=(9.75*#Scale#)
X=((#PanelWidth#-42)*#Scale#)
Y=(25*#Scale#)
W=(64*#Scale#)
H=(28*#Scale#)
StringAlign=CenterCenter
SolidColor=27,27,36,255
MouseActionCursor=1
ToolTipText=간단히 / 자세히 전환
LeftMouseUpAction=[!CommandMeasure ToggleMode "Run"]

[ToggleMode]
Measure=Plugin
Plugin=RunCommand
Program=powershell.exe
Parameter=-NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File "#ToggleScript#" -DeferRefresh
State=Hide
OutputType=UTF8
UpdateDivider=-1
FinishAction=[!Refresh]

[CPUName]
Meter=String
MeterStyle=BaseText
Y=((#CPUY#)*#Scale#)
Text=[&Sensors:CpuTitle()]
Hidden=#HideCPU#


[CPUValue]
Meter=String
MeterStyle=NumericText
Y=((#CPUY#-3)*#Scale#)
Text=[&Sensors:CpuValue()]
Hidden=#HideCPU#


[MeterCPUModel]
Meter=String
MeterStyle=SecondaryText
Y=((#CPUY#+30)*#Scale#)
Text=[CpuModel]
Hidden=#HideCPUDetail#
FontFace=#LatinFont#

[CPUInfo]
Meter=String
MeterStyle=SecondaryText
Y=((#CPUY#+52)*#Scale#)
Text=[&Sensors:CpuInfo()]
Hidden=#HideCPUDetail#


[CPUGuides]
Meter=Shape
X=(16*#Scale#)
Y=((#CPUGraphY#)*#Scale#)
Shape=Line 0,0,((#PanelWidth#-32)*#Scale#),0 | StrokeWidth 1 | Stroke Color #Border#
Shape2=Line 0,(#CpuGraphHeight#*#Scale#/2),((#PanelWidth#-32)*#Scale#),(#CpuGraphHeight#*#Scale#/2) | StrokeWidth 1 | Stroke Color #Border#
Shape3=Line 0,(#CpuGraphHeight#*#Scale#),((#PanelWidth#-32)*#Scale#),(#CpuGraphHeight#*#Scale#) | StrokeWidth 1 | Stroke Color #Border#
Hidden=#HideCPUGraph#
DynamicVariables=1

[CPUHistory]
Meter=Shape
X=(16*#Scale#)
Y=((#CPUGraphY#)*#Scale#)
Shape=Path Data | StrokeWidth 1.5 | Stroke Color #Accent# | Fill Color 0,0,0,0
Data=0,0 | LineTo 0,0
Hidden=#HideCPUGraph#
DynamicVariables=1

[CPUAxis]
Meter=String
MeterStyle=SecondaryText
Y=((#CPUGraphY#-19)*#Scale#)
Text=[&Sensors:CpuAxis()]
Hidden=#HideCPUGraph#
FontSize=(8.25*#Scale#)

[CPUTimeAxis]
Meter=String
MeterStyle=SecondaryText
Y=((#CPUGraphY#+#CpuGraphHeight#+2)*#Scale#)
Text=−#HistorySeconds#초
Hidden=#HideCPUGraph#
FontSize=(8.25*#Scale#)

[CPUStats]
Meter=String
MeterStyle=SecondaryText
Y=((#CPUStatsY#)*#Scale#)
Text=[&Sensors:CpuStats()]
Hidden=#HideCPUDetail#


[CPUDivider]
Meter=Shape
X=(16*#Scale#)
Y=((#CPUEnd#)*#Scale#)
Shape=Line 0,0,((#PanelWidth#-32)*#Scale#),0 | StrokeWidth 1 | Stroke Color #Border#
Hidden=#HideCPU#
DynamicVariables=1

[RAMName]
Meter=String
MeterStyle=BaseText
Y=((#RAMY#)*#Scale#)
Text=메모리
Hidden=#HideRAM#


[RAMValue]
Meter=String
MeterStyle=NumericText
Y=((#RAMY#-3)*#Scale#)
Text=[&Sensors:RamValue()]
Hidden=#HideRAM#


[RAMDetails]
Meter=String
MeterStyle=SecondaryText
Y=((#RAMY#+30)*#Scale#)
Text=[&Sensors:RamDetails()]
Hidden=#HideRAMDetail#


[RAMCommit]
Meter=String
MeterStyle=SecondaryText
Y=((#RAMY#+52)*#Scale#)
Text=[&Sensors:Commit()]
Hidden=#HideRAMDetail#


[RAMDivider]
Meter=Shape
X=(16*#Scale#)
Y=((#RAMEnd#)*#Scale#)
Shape=Line 0,0,((#PanelWidth#-32)*#Scale#),0 | StrokeWidth 1 | Stroke Color #Border#
Hidden=#HideRAM#
DynamicVariables=1

[GPUName]
Meter=String
MeterStyle=BaseText
Y=((#GPUY#)*#Scale#)
Text=GPU
Hidden=#HideGPU#


[GPUValue]
Meter=String
MeterStyle=NumericText
Y=((#GPUY#-3)*#Scale#)
Text=[&Sensors:GpuValue()]
Hidden=#HideGPU#


[MeterGPUModel]
Meter=String
MeterStyle=SecondaryText
Y=((#GPUY#+30)*#Scale#)
Text=[GpuModel]
Hidden=#HideGPUDetail#
FontFace=#LatinFont#

[GPUMemory]
Meter=String
MeterStyle=SecondaryText
Y=((#GPUY#+52)*#Scale#)
Text=[&Sensors:GpuMemory()]
Hidden=#HideGPUDetail#


[GPUDivider]
Meter=Shape
X=(16*#Scale#)
Y=((#GPUEnd#)*#Scale#)
Shape=Line 0,0,((#PanelWidth#-32)*#Scale#),0 | StrokeWidth 1 | Stroke Color #Border#
Hidden=#HideGPU#
DynamicVariables=1

[DiskTitle]
Meter=String
MeterStyle=BaseText
Y=((#DiskY#)*#Scale#)
Text=저장공간
Hidden=#HideDisk#


[MeterStorageCLabel]
Meter=String
MeterStyle=BaseText
Y=((#StorageCY#)*#Scale#)
Text=[&Sensors:StorageLabel('C')]
Hidden=#HideStorageC#


W=(145*#Scale#)

[StorageCValue]
Meter=String
MeterStyle=SecondaryText
Y=((#StorageCY#)*#Scale#)
Text=[&Sensors:StorageValue('C')]
Hidden=#HideStorageC#
StringAlign=Right
X=((#PanelWidth#-16)*#Scale#)
W=(170*#Scale#)

[StorageCFree]
Meter=String
MeterStyle=SecondaryText
Y=((#StorageCY#+23)*#Scale#)
Text=[&Sensors:StorageFree('C')]
Hidden=#HideStorageC#


[StorageCTrack]
Meter=Shape
X=(16*#Scale#)
Y=((#StorageCY#+46)*#Scale#)
Shape=Line 0,0,((#PanelWidth#-32)*#Scale#),0 | StrokeWidth 2 | Stroke Color #Border#
Shape2=Line 0,0,0,0 | StrokeWidth 2 | Stroke Color #Accent#
Hidden=#HideStorageC#
DynamicVariables=1

[MeterStorageDLabel]
Meter=String
MeterStyle=BaseText
Y=((#StorageDY#)*#Scale#)
Text=[&Sensors:StorageLabel('D')]
Hidden=#HideStorageD#


W=(145*#Scale#)

[StorageDValue]
Meter=String
MeterStyle=SecondaryText
Y=((#StorageDY#)*#Scale#)
Text=[&Sensors:StorageValue('D')]
Hidden=#HideStorageD#
StringAlign=Right
X=((#PanelWidth#-16)*#Scale#)
W=(170*#Scale#)

[StorageDFree]
Meter=String
MeterStyle=SecondaryText
Y=((#StorageDY#+23)*#Scale#)
Text=[&Sensors:StorageFree('D')]
Hidden=#HideStorageD#


[StorageDTrack]
Meter=Shape
X=(16*#Scale#)
Y=((#StorageDY#+46)*#Scale#)
Shape=Line 0,0,((#PanelWidth#-32)*#Scale#),0 | StrokeWidth 2 | Stroke Color #Border#
Shape2=Line 0,0,0,0 | StrokeWidth 2 | Stroke Color #Accent#
Hidden=#HideStorageD#
DynamicVariables=1

[DiskPhysical]
Meter=String
MeterStyle=SecondaryText
Y=((#DiskInfoY#)*#Scale#)
Text=[&Sensors:DiskPhysical()]
Hidden=#HideDisk#


[DiskDivider]
Meter=Shape
X=(16*#Scale#)
Y=((#DiskEnd#)*#Scale#)
Shape=Line 0,0,((#PanelWidth#-32)*#Scale#),0 | StrokeWidth 1 | Stroke Color #Border#
Hidden=#HideDisk#
DynamicVariables=1

[NetworkName]
Meter=String
MeterStyle=BaseText
Y=((#NetworkY#)*#Scale#)
Text=네트워크
Hidden=#HideNetwork#


[NetworkRates]
Meter=String
MeterStyle=BaseText
Y=((#NetworkY#+27)*#Scale#)
Text=[&Sensors:NetworkRates()]
Hidden=#HideNetwork#
FontFace=#MetricFont#
FontSize=(12*#Scale#)

[NetworkInfo]
Meter=String
MeterStyle=SecondaryText
Y=((#NetworkY#+53)*#Scale#)
Text=[&Sensors:NetworkInfo()]
Hidden=#HideNetworkDetail#


[NetworkGuides]
Meter=Shape
X=(16*#Scale#)
Y=((#NetworkGraphY#)*#Scale#)
Shape=Line 0,0,((#PanelWidth#-32)*#Scale#),0 | StrokeWidth 1 | Stroke Color #Border#
Shape2=Line 0,(#NetworkGraphHeight#*#Scale#/2),((#PanelWidth#-32)*#Scale#),(#NetworkGraphHeight#*#Scale#/2) | StrokeWidth 1 | Stroke Color #Border#
Shape3=Line 0,(#NetworkGraphHeight#*#Scale#),((#PanelWidth#-32)*#Scale#),(#NetworkGraphHeight#*#Scale#) | StrokeWidth 1 | Stroke Color #Border#
Hidden=#HideNetworkGraph#
DynamicVariables=1

[NetworkHistory]
Meter=Shape
X=(16*#Scale#)
Y=((#NetworkGraphY#)*#Scale#)
Shape=Path Data | StrokeWidth 1.5 | Stroke Color #Accent# | Fill Color 0,0,0,0
Data=0,0 | LineTo 0,0
Hidden=#HideNetworkGraph#
DynamicVariables=1

[NetworkUpload]
Meter=Shape
X=(16*#Scale#)
Y=((#NetworkGraphY#)*#Scale#)
Shape=Path Data | StrokeWidth 1.5 | Stroke Color #Special# | Fill Color 0,0,0,0
Data=0,0 | LineTo 0,0
Hidden=#HideNetworkGraph#
DynamicVariables=1

[NetworkAxis]
Meter=String
MeterStyle=SecondaryText
Y=((#NetworkGraphY#-19)*#Scale#)
Text=[&Sensors:AxisLabel()]
Hidden=#HideNetworkGraph#
FontSize=(8.25*#Scale#)

[NetworkTimeAxis]
Meter=String
MeterStyle=SecondaryText
Y=((#NetworkGraphY#+#NetworkGraphHeight#+2)*#Scale#)
Text=−#HistorySeconds#초
Hidden=#HideNetworkGraph#
FontSize=(8.25*#Scale#)

[NetworkTotal]
Meter=String
MeterStyle=SecondaryText
Y=((#NetworkTotalY#)*#Scale#)
Text=[&Sensors:NetworkTotal()]
Hidden=#HideNetworkDetail#


[NetworkDivider]
Meter=Shape
X=(16*#Scale#)
Y=((#NetworkEnd#)*#Scale#)
Shape=Line 0,0,((#PanelWidth#-32)*#Scale#),0 | StrokeWidth 1 | Stroke Color #Border#
Hidden=#HideNetwork#
DynamicVariables=1

[BatteryLine]
Meter=String
MeterStyle=SecondaryText
Y=((#BatteryY#)*#Scale#)
Text=[&Sensors:BatteryStatus()]
Hidden=#HideBattery#


[UptimeText]
Meter=String
MeterStyle=SecondaryText
Y=((#UptimeY#)*#Scale#)
Text=가동 시간  [Uptime]
Hidden=#HideUptime#


[SensorStatus]
Meter=String
MeterStyle=SecondaryText
Y=((#SensorStatusY#)*#Scale#)
Text=[&Sensors:TemperatureStatus()]
Hidden=#HideSensorStatus#
FontSize=(8.25*#Scale#)

[CPUTimeRight]
Meter=String
MeterStyle=SecondaryText
Text=현재
Y=((#CPUGraphY#+#CpuGraphHeight#+2)*#Scale#)
X=((#PanelWidth#-16)*#Scale#)
StringAlign=Right
W=(50*#Scale#)
FontSize=(8.25*#Scale#)
Hidden=#HideCPUGraph#

[NetworkTimeRight]
Meter=String
MeterStyle=SecondaryText
Text=현재
Y=((#NetworkGraphY#+#NetworkGraphHeight#+2)*#Scale#)
X=((#PanelWidth#-16)*#Scale#)
StringAlign=Right
W=(50*#Scale#)
FontSize=(8.25*#Scale#)
Hidden=#HideNetworkGraph#
