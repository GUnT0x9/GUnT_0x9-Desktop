local history,axis,cpuValue={},1024,nil
local function n(name) local m=SKIN:GetMeasure(name);return m and m:GetValue() or 0 end
local function t(name) local m=SKIN:GetMeasure(name);return m and m:GetStringValue() or '' end
local function v(name,default) return tonumber(SKIN:GetVariable(name)) or default end
local function fresh() return math.abs(os.time()-n('SensorEpoch'))<10 end
local function bytes(x)
 if x>=1073741824 then return string.format('%.1f GiB',x/1073741824) end
 if x>=1048576 then return string.format('%.1f MiB',x/1048576) end
 if x>=1024 then return string.format('%.1f KiB',x/1024) end
 return string.format('%.0f B',x)
end
local Graph
local function path(field,max,height)
 local scale=v('Scale',1)
 return Graph.Path(history,field,max,(v('PanelWidth',360)-32)*scale,height*scale,os.time(),v('HistorySeconds',60))
end
function Initialize() Graph=dofile(SKIN:GetVariable('@')..'Graph.lua');history={};axis=1024;cpuValue=nil end
function Update()
 local now=os.time();if #history>0 and now-history[#history].time>v('UpdateMs',2000)/1000*2.5 then history={} end;cpuValue=n('CPU');local sample={time=now,cpu=cpuValue}
 if fresh() and t('NetHasRate'):lower()=='true' then sample.down=n('Down');sample.up=n('Up') end
 history[#history+1]=sample
 while #history>1 and (now-history[1].time>v('HistorySeconds',60) or #history>122) do table.remove(history,1) end
 axis=1024
 if SKIN:GetVariable('NetworkScaleMode')=='fixed' then axis=v('NetworkFixedMax',10485760)
 else for _,p in ipairs(history) do while math.max(p.down or 0,p.up or 0)>axis do axis=axis*2 end end end
 if SKIN:GetVariable('HideCPUGraph')=='0' then SKIN:Bang('!SetOption','CPUHistory','Data',path('cpu',100,v('CpuGraphHeight',64))) end
 if SKIN:GetVariable('HideNetworkGraph')=='0' then
  SKIN:Bang('!SetOption','NetworkHistory','Data',path('down',axis,v('NetworkGraphHeight',56)))
  SKIN:Bang('!SetOption','NetworkUpload','Data',path('up',axis,v('NetworkGraphHeight',56)))
 end
 for _,d in ipairs({'C','D'}) do
  local w=(v('PanelWidth',360)-32)*v('Scale',1)*math.max(0,math.min(100,n('Storage'..d..'Percent')))/100
  SKIN:Bang('!SetOption','Storage'..d..'Track','Shape2',string.format('Line 0,0,%.2f,0 | StrokeWidth 2 | Stroke Color %s',w,SKIN:GetVariable('Accent')))
 end
 return cpuValue
end
function CpuValue() return string.format('%.0f%%',cpuValue or n('CPU'))..(fresh() and n('HasCpuTemperature')==1 and string.format('  %.0f°C',n('CpuTemperature')) or '') end
function CpuInfo()
 local s=string.format('%.0f코어 / %.0f스레드',n('PhysicalCores'),n('LogicalProcessors'))
 if fresh() and n('CpuFrequency')>0 then s=s..string.format(' · %.2f GHz',n('CpuFrequency')/1000) end
 if fresh() and n('CpuPackagePower')>0 then s=s..string.format(' · %.1f W',n('CpuPackagePower')) end
 return s
end
function CpuStats() local sum,max=0,0;for _,p in ipairs(history) do sum=sum+p.cpu;max=math.max(max,p.cpu) end;return string.format('최근 %d초  샘플 평균 %.0f%% · 최대 %.0f%%',#history>1 and os.time()-history[1].time or 0,#history>0 and sum/#history or 0,max) end
function CpuAxis() return '0 / 50 / 100% · '..v('UpdateMs',2000)/1000 ..'초 간격' end
function RamValue() if n('RAMTotal')<=0 or n('RAM')>n('RAMTotal') then return '수집 대기' end;return string.format('%.0f%%',n('RAM')/math.max(1,n('RAMTotal'))*100) end
function RamDetails() if n('RAMTotal')<=0 or n('RAM')>n('RAMTotal') then return '메모리 용량 수집 대기' end;return '사용 '..bytes(n('RAM'))..' / '..bytes(n('RAMTotal'))..' · 가용 '..bytes(n('RAMTotal')-n('RAM')) end
function Commit() if not fresh() or n('CommitLimit')<=0 then return '커밋 정보 갱신 대기' end;return '커밋 '..bytes(n('Committed'))..' / '..bytes(n('CommitLimit')) end
function GpuValue() if not fresh() or n('HasGpu')~=1 then return '수집 대기' end;return string.format('%.0f%%',n('Gpu'))..(n('HasGpuTemperature')==1 and string.format('  %.0f°C',n('GpuTemperature')) or '') end
function GpuMemory() if not fresh() or n('HasGpu')~=1 then return 'GPU 측정 불가' end;return '전용 '..bytes(n('GpuDedicated'))..' / '..bytes(n('GpuDedicatedCapacity'))..' · 공유 '..bytes(n('GpuShared')) end
function StorageLabel(d) return d..':  '..t('Storage'..d..'Label') end
function StorageValue(d) if not fresh() or t('Storage'..d..'Available'):lower()~='true' then return '연결 확인 필요' end;return bytes(n('Storage'..d..'UsedBytes'))..' / '..bytes(n('Storage'..d..'TotalBytes')) end
function StorageFree(d) if not fresh() or t('Storage'..d..'Available'):lower()~='true' then return '' end;return string.format('여유 %s · 사용 %.0f%%',bytes(n('Storage'..d..'FreeBytes')),n('Storage'..d..'Percent')) end
function DiskPhysical() return SKIN:GetVariable('PhysicalDiskLabel','물리 저장장치')..(fresh() and n('HasSsdTemperature')==1 and string.format(' · %.0f°C',n('SsdTemperature')) or '') end
function NetworkRates() if not fresh() or t('NetHasRate'):lower()~='true' then return '네트워크 샘플 수집 대기' end;return '↓ '..bytes(n('Down'))..'/s   ↑ '..bytes(n('Up'))..'/s' end
function NetworkInfo() if not fresh() then return '어댑터 갱신 대기' end;local speed=n('NetLink')/1000000;return t('Adapter')..(speed>0 and string.format(' · 링크 %.0f Mbps',speed) or '') end
function NetworkTotal() if not fresh() then return '' end;return '수집 세션  ↓ '..bytes(n('NetRxSession'))..'  ↑ '..bytes(n('NetTxSession')) end
function AxisLabel() return '↓ 보라 / ↑ 청록 · 0–'..bytes(axis)..'/s' end
function BatteryStatus() local ac=t('ACConnected'):lower()=='true';return string.format('배터리 %.0f%% · ',n('BatteryPercent'))..(t('BatteryCharging'):lower()=='true' and '충전 중' or (ac and '전원 연결' or '배터리 사용')) end
function TemperatureStatus() if fresh() and (n('HasCpuTemperature')==1 or n('HasGpuTemperature')==1) then return '온도 · HWiNFO 가젯 · 공급자 갱신 확인' end;return '온도 센서 연결 대기 · 설정에서 공급자 확인' end

function CpuTitle() if fresh() and n('HasCpuTemperature')==1 then return t('CpuTemperatureKind')=='core' and 'CPU · 코어 온도' or 'CPU · 패키지 온도' end;return 'CPU' end
