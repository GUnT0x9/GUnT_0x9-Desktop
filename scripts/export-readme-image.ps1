param([Parameter(Mandatory=$true)][string]$Source,[Parameter(Mandatory=$true)][string]$Destination,[ValidateRange(800,2400)][int]$MaxWidth=1600,[string]$MasksJson)
# 원본은 건드리지 않는다. 새 RGB 비트맵으로 저장해 메타데이터/숨은 알파를 전달하지 않는다.
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
if(Test-Path -LiteralPath $Destination){throw '기존 승인 이미지를 덮어쓰지 않습니다. 별도 검토 경로를 지정하세요.'}
$sourcePath=(Resolve-Path -LiteralPath $Source).Path
$original=[Drawing.Image]::FromFile($sourcePath)
$clean=New-Object Drawing.Bitmap($original.Width,$original.Height,[Drawing.Imaging.PixelFormat]::Format24bppRgb)
$g=[Drawing.Graphics]::FromImage($clean)
try{
 $g.Clear([Drawing.Color]::FromArgb(14,14,18));$g.DrawImage($original,(New-Object Drawing.Rectangle(0,0,$original.Width,$original.Height)),0,0,$original.Width,$original.Height,[Drawing.GraphicsUnit]::Pixel)
 if($MasksJson){
  foreach($r in @(Get-Content -LiteralPath $MasksJson -Raw -Encoding UTF8|ConvertFrom-Json)){
   if($r.x -lt 0 -or $r.y -lt 0 -or $r.width -le 0 -or $r.height -le 0 -or ($r.x+$r.width) -gt $clean.Width -or ($r.y+$r.height) -gt $clean.Height){throw '가림 좌표 범위를 확인하세요.'}
   # 축소 전에 완전히 불투명한 단색으로 원본 픽셀을 대체한다. 흐림/픽셀화 금지.
   $brush=New-Object Drawing.SolidBrush([Drawing.Color]::FromArgb(255,14,14,18))
   try{$g.FillRectangle($brush,[int]$r.x,[int]$r.y,[int]$r.width,[int]$r.height)}finally{$brush.Dispose()}
  }
 }
}finally{$g.Dispose();$original.Dispose()}
$output=$null
try{
 if($clean.Width -gt $MaxWidth){
  $height=[int][math]::Round($clean.Height*$MaxWidth/$clean.Width)
  $output=New-Object Drawing.Bitmap($MaxWidth,$height,[Drawing.Imaging.PixelFormat]::Format24bppRgb)
  $draw=[Drawing.Graphics]::FromImage($output)
  try{$draw.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic;$draw.PixelOffsetMode=[Drawing.Drawing2D.PixelOffsetMode]::HighQuality;$draw.DrawImage($clean,(New-Object Drawing.Rectangle(0,0,$MaxWidth,$height)),0,0,$clean.Width,$clean.Height,[Drawing.GraphicsUnit]::Pixel)}finally{$draw.Dispose()}
 }else{$output=$clean}
 $directory=Split-Path ([IO.Path]::GetFullPath($Destination)) -Parent;New-Item -ItemType Directory -Force $directory|Out-Null
 $output.Save([IO.Path]::GetFullPath($Destination),[Drawing.Imaging.ImageFormat]::Png)
 Write-Output ('검토용 PNG: '+$Destination+' / '+$output.Width+'x'+$output.Height)
}finally{if($output -and ![Object]::ReferenceEquals($output,$clean)){$output.Dispose()};$clean.Dispose()}
