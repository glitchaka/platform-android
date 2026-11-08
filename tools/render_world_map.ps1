$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$projectRoot = Split-Path -Parent $PSScriptRoot
$mapDirectory = Join-Path $projectRoot 'Builds/Maps'
$drawing = Get-Content -Raw -Encoding UTF8 (Join-Path $mapDirectory 'map-drawing.json') | ConvertFrom-Json
$bitmap = New-Object System.Drawing.Bitmap ([int]$drawing.width),([int]$drawing.height)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
$format = New-Object System.Drawing.StringFormat
$format.FormatFlags = [System.Drawing.StringFormatFlags]::NoWrap
foreach ($c in $drawing.commands) {
    if ($c.kind -eq 'rect') {
        $brush = New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml($c.fill))
        $graphics.FillRectangle($brush,[single]$c.x,[single]$c.y,[single]$c.w,[single]$c.h)
        $brush.Dispose()
        if ($c.stroke) {
            $pen = New-Object System.Drawing.Pen ([System.Drawing.ColorTranslator]::FromHtml($c.stroke)),([single]$c.sw)
            $graphics.DrawRectangle($pen,[single]$c.x,[single]$c.y,[single]$c.w,[single]$c.h)
            $pen.Dispose()
        }
    } elseif ($c.kind -eq 'path') {
        $pen = New-Object System.Drawing.Pen ([System.Drawing.ColorTranslator]::FromHtml($c.color)),([single]$c.sw)
        if ($c.dash) { $pen.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Dash }
        $points = [System.Drawing.PointF[]]@($c.points | ForEach-Object { New-Object System.Drawing.PointF ([single]$_[0]),([single]$_[1]) })
        $graphics.DrawLines($pen,$points)
        $pen.Dispose()
    } else {
        $style = if ($c.weight -eq 'bold') { [System.Drawing.FontStyle]::Bold } else { [System.Drawing.FontStyle]::Regular }
        $font = New-Object System.Drawing.Font 'Arial',([single]$c.size),$style,([System.Drawing.GraphicsUnit]::Pixel)
        $brush = New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml($c.color))
        $format.Alignment = if ($c.align -eq 'center') { [System.Drawing.StringAlignment]::Center } else { [System.Drawing.StringAlignment]::Near }
        $graphics.DrawString([string]$c.text,$font,$brush,([single]$c.x),([single]$c.y),$format)
        $brush.Dispose()
        $font.Dispose()
    }
}
$bitmap.Save((Join-Path $mapDirectory 'mapa-completo.png'),[System.Drawing.Imaging.ImageFormat]::Png)
$graphics.Dispose()
$bitmap.Dispose()
$format.Dispose()
Write-Output 'Rendered Builds/Maps/mapa-completo.png'
