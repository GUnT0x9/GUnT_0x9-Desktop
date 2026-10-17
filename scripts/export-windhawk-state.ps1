. "$PSScriptRoot\common.ps1"
$modsDir=Join-Path $Root 'apps\Windhawk\AppData\Engine\Mods'
$rows=@()
foreach($file in Get-ChildItem $modsDir -Filter '*.ini'|Sort-Object BaseName){
 $text=[IO.File]::ReadAllText($file.FullName)
 function Ini-Value([string]$key){[regex]::Match($text,'(?m)^'+[regex]::Escape($key)+'=(.*)').Groups[1].Value.Trim()}
 $id=$file.BaseName;$provenance=$null;$record=Join-Path $Root ('windhawk\'+$id+'.source.json')
 if(Test-Path $record){$provenance=Get-Content $record -Raw -Encoding UTF8|ConvertFrom-Json}
 $rows+=@{id=$id;version=(Ini-Value 'Version');enabled=((Ini-Value 'Disabled') -eq '0');installed=$true;library=(Ini-Value 'LibraryFileName');targetProcesses=(Ini-Value 'IncludeCustom');commit=$provenance.commit;sourceSHA256=$provenance.sha256;source=$provenance.url;officialUrl=('https://windhawk.net/mods/'+$id);capturedAt=(Get-Date).ToString('o');stateSource=$file.FullName;verification='활성 상태는 실제 INI에서 읽은 값입니다. 기능·화면 검증 결과는 개별 로그와 호환성 표를 참조하세요.'}
}
Write-Json $rows (Join-Path $Root 'windhawk\mods.json')
Write-Log 'windhawk-state' 'recorded' ('설치 '+$rows.Count+'개 / 활성 '+@($rows|Where-Object enabled).Count+'개; 실제 INI 상태를 다시 기록했습니다.')
