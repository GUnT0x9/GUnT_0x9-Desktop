[CPU]
Measure=CPU
Processor=0
MinValue=0
MaxValue=100
Group=Monitoring
[RAM]
Measure=PhysicalMemory
Group=Monitoring
[RAMTotal]
Measure=PhysicalMemory
Total=1
UpdateDivider=1
Group=Monitoring
[Uptime]
Measure=Uptime
Format=%4!dd!일 %3!02i!시간 %2!02i!분
Group=Monitoring

[SensorEpoch]
Measure=Registry
RegHKey=HKEY_CURRENT_USER
RegKey=Software\GuntDesktop\Sensors
RegValue=SampleEpoch
Group=Monitoring

[CpuModel]
Measure=Registry
RegHKey=HKEY_CURRENT_USER
RegKey=Software\GuntDesktop\Sensors
RegValue=CpuModel
Group=Monitoring

[CpuFrequency]
Measure=Registry
RegHKey=HKEY_CURRENT_USER
RegKey=Software\GuntDesktop\Sensors
RegValue=CpuFrequencyMHz
Group=Monitoring

[PhysicalCores]
Measure=Registry
RegHKey=HKEY_CURRENT_USER
RegKey=Software\GuntDesktop\Sensors
RegValue=PhysicalCores
Group=Monitoring

[LogicalProcessors]
Measure=Registry
RegHKey=HKEY_CURRENT_USER
RegKey=Software\GuntDesktop\Sensors
RegValue=LogicalProcessors
Group=Monitoring

[CpuTemperature]
Measure=Registry
RegHKey=HKEY_CURRENT_USER
RegKey=Software\GuntDesktop\Sensors
RegValue=CpuTemperatureC
Group=Monitoring

[GpuTemperature]
Measure=Registry
RegHKey=HKEY_CURRENT_USER
RegKey=Software\GuntDesktop\Sensors
RegValue=GpuTemperatureC
Group=Monitoring

[SsdTemperature]
Measure=Registry
RegHKey=HKEY_CURRENT_USER
RegKey=Software\GuntDesktop\Sensors
RegValue=SsdTemperatureC
Group=Monitoring

[CpuPackagePower]
Measure=Registry
RegHKey=HKEY_CURRENT_USER
RegKey=Software\GuntDesktop\Sensors
RegValue=CpuPackagePowerW
Group=Monitoring

[HasCpuTemperature]
Measure=Registry
RegHKey=HKEY_CURRENT_USER
RegKey=Software\GuntDesktop\Sensors
RegValue=HasCpuTemperature
Group=Monitoring

[HasGpuTemperature]
Measure=Registry
RegHKey=HKEY_CURRENT_USER
RegKey=Software\GuntDesktop\Sensors
RegValue=HasGpuTemperature
Group=Monitoring

[HasSsdTemperature]
Measure=Registry
RegHKey=HKEY_CURRENT_USER
RegKey=Software\GuntDesktop\Sensors
RegValue=HasSsdTemperature
Group=Monitoring

[TemperatureQuality]
Measure=Registry
RegHKey=HKEY_CURRENT_USER
RegKey=Software\GuntDesktop\Sensors
RegValue=TemperatureQuality
Group=Monitoring

[HasGpu]
Measure=Registry
RegHKey=HKEY_CURRENT_USER
RegKey=Software\GuntDesktop\Sensors
RegValue=HasGpu
Group=Monitoring

[GpuModel]
Measure=Registry
RegHKey=HKEY_CURRENT_USER
RegKey=Software\GuntDesktop\Sensors
RegValue=GpuModel
Group=Monitoring

[Gpu]
Measure=Registry
RegHKey=HKEY_CURRENT_USER
RegKey=Software\GuntDesktop\Sensors
RegValue=GpuUtilizationPercent
Group=Monitoring

[GpuDedicated]
Measure=Registry
RegHKey=HKEY_CURRENT_USER
RegKey=Software\GuntDesktop\Sensors
RegValue=GpuDedicatedUsedBytes
Group=Monitoring

[GpuShared]
Measure=Registry
RegHKey=HKEY_CURRENT_USER
RegKey=Software\GuntDesktop\Sensors
RegValue=GpuSharedUsedBytes
Group=Monitoring

[GpuDedicatedCapacity]
Measure=Registry
RegHKey=HKEY_CURRENT_USER
RegKey=Software\GuntDesktop\Sensors
RegValue=GpuDedicatedCapacityBytes
Group=Monitoring

[Committed]
Measure=Registry
RegHKey=HKEY_CURRENT_USER
RegKey=Software\GuntDesktop\Sensors
RegValue=CommittedBytes
Group=Monitoring

[CommitLimit]
Measure=Registry
RegHKey=HKEY_CURRENT_USER
RegKey=Software\GuntDesktop\Sensors
RegValue=CommitLimitBytes
Group=Monitoring

[SystemCache]
Measure=Registry
RegHKey=HKEY_CURRENT_USER
RegKey=Software\GuntDesktop\Sensors
RegValue=SystemCacheBytes
Group=Monitoring

[DiskRead]
Measure=Registry
RegHKey=HKEY_CURRENT_USER
RegKey=Software\GuntDesktop\Sensors
RegValue=DiskReadBytesPerSecond
Group=Monitoring

[DiskWrite]
Measure=Registry
RegHKey=HKEY_CURRENT_USER
RegKey=Software\GuntDesktop\Sensors
RegValue=DiskWriteBytesPerSecond
Group=Monitoring

[ACConnected]
Measure=Registry
RegHKey=HKEY_CURRENT_USER
RegKey=Software\GuntDesktop\Sensors
RegValue=ACConnected
Group=Monitoring

[BatteryCharging]
Measure=Registry
RegHKey=HKEY_CURRENT_USER
RegKey=Software\GuntDesktop\Sensors
RegValue=BatteryCharging
Group=Monitoring

[BatteryPercent]
Measure=Registry
RegHKey=HKEY_CURRENT_USER
RegKey=Software\GuntDesktop\Sensors
RegValue=BatteryPercent
Group=Monitoring

[Down]
Measure=Registry
RegHKey=HKEY_CURRENT_USER
RegKey=Software\GuntDesktop\Sensors
RegValue=NetDownBytesPerSecond
Group=Monitoring

[Up]
Measure=Registry
RegHKey=HKEY_CURRENT_USER
RegKey=Software\GuntDesktop\Sensors
RegValue=NetUpBytesPerSecond
Group=Monitoring

[NetHasRate]
Measure=Registry
RegHKey=HKEY_CURRENT_USER
RegKey=Software\GuntDesktop\Sensors
RegValue=NetHasRate
Group=Monitoring

[Adapter]
Measure=Registry
RegHKey=HKEY_CURRENT_USER
RegKey=Software\GuntDesktop\Sensors
RegValue=NetAdapter
Group=Monitoring

[NetLink]
Measure=Registry
RegHKey=HKEY_CURRENT_USER
RegKey=Software\GuntDesktop\Sensors
RegValue=NetLinkBitsPerSecond
Group=Monitoring

[NetType]
Measure=Registry
RegHKey=HKEY_CURRENT_USER
RegKey=Software\GuntDesktop\Sensors
RegValue=NetInterfaceType
Group=Monitoring

[NetStatus]
Measure=Registry
RegHKey=HKEY_CURRENT_USER
RegKey=Software\GuntDesktop\Sensors
RegValue=NetStatus
Group=Monitoring

[NetRxSession]
Measure=Registry
RegHKey=HKEY_CURRENT_USER
RegKey=Software\GuntDesktop\Sensors
RegValue=NetDownloadSessionBytes
Group=Monitoring

[NetTxSession]
Measure=Registry
RegHKey=HKEY_CURRENT_USER
RegKey=Software\GuntDesktop\Sensors
RegValue=NetUploadSessionBytes
Group=Monitoring

[StorageCAvailable]
Measure=Registry
RegHKey=HKEY_CURRENT_USER
RegKey=Software\GuntDesktop\Sensors
RegValue=StorageCAvailable
Group=Monitoring

[StorageCLabel]
Measure=Registry
RegHKey=HKEY_CURRENT_USER
RegKey=Software\GuntDesktop\Sensors
RegValue=StorageCLabel
Group=Monitoring

[StorageCTotalBytes]
Measure=Registry
RegHKey=HKEY_CURRENT_USER
RegKey=Software\GuntDesktop\Sensors
RegValue=StorageCTotalBytes
Group=Monitoring

[StorageCFreeBytes]
Measure=Registry
RegHKey=HKEY_CURRENT_USER
RegKey=Software\GuntDesktop\Sensors
RegValue=StorageCFreeBytes
Group=Monitoring

[StorageCUsedBytes]
Measure=Registry
RegHKey=HKEY_CURRENT_USER
RegKey=Software\GuntDesktop\Sensors
RegValue=StorageCUsedBytes
Group=Monitoring

[StorageCPercent]
Measure=Registry
RegHKey=HKEY_CURRENT_USER
RegKey=Software\GuntDesktop\Sensors
RegValue=StorageCPercent
Group=Monitoring

[StorageDAvailable]
Measure=Registry
RegHKey=HKEY_CURRENT_USER
RegKey=Software\GuntDesktop\Sensors
RegValue=StorageDAvailable
Group=Monitoring

[StorageDLabel]
Measure=Registry
RegHKey=HKEY_CURRENT_USER
RegKey=Software\GuntDesktop\Sensors
RegValue=StorageDLabel
Group=Monitoring

[StorageDTotalBytes]
Measure=Registry
RegHKey=HKEY_CURRENT_USER
RegKey=Software\GuntDesktop\Sensors
RegValue=StorageDTotalBytes
Group=Monitoring

[StorageDFreeBytes]
Measure=Registry
RegHKey=HKEY_CURRENT_USER
RegKey=Software\GuntDesktop\Sensors
RegValue=StorageDFreeBytes
Group=Monitoring

[StorageDUsedBytes]
Measure=Registry
RegHKey=HKEY_CURRENT_USER
RegKey=Software\GuntDesktop\Sensors
RegValue=StorageDUsedBytes
Group=Monitoring

[StorageDPercent]
Measure=Registry
RegHKey=HKEY_CURRENT_USER
RegKey=Software\GuntDesktop\Sensors
RegValue=StorageDPercent
Group=Monitoring


[CpuTemperatureKind]
Measure=Registry
RegHKey=HKEY_CURRENT_USER
RegKey=Software\GuntDesktop\Sensors
RegValue=CpuTemperatureKind
Group=Monitoring

[Sensors]
Measure=Script
ScriptFile=#@#Sensors.lua
Group=Monitoring
