<# Chigos OS - brand asset generator (Windows PowerShell / System.Drawing)
   Renders: 3 wallpapers (PNG) + 1 logo (PNG).
   Run:  powershell -ExecutionPolicy Bypass -File make-branding.ps1
#>
Add-Type -AssemblyName System.Drawing

$OutDir = Join-Path $env:USERPROFILE 'chigos-build\branding'
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$FontFace  = 'Segoe UI'
$FontFaceM = 'Consolas'

function New-Wallpaper {
    param([string]$Name, [int]$W, [int]$H, [int]$AccentR, [int]$AccentG, [int]$AccentB, [string]$Tagline)

    $bmp  = New-Object System.Drawing.Bitmap($W, $H)
    $g    = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAlias

    # Background gradient (dark slate)
    $rect = New-Object System.Drawing.Rectangle(0, 0, $W, $H)
    $bg   = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        $rect, [System.Drawing.Color]::FromArgb(255, 13, 17, 23),
        [System.Drawing.Color]::FromArgb(255, 4, 6, 11),
        90.0)
    $g.FillRectangle($bg, $rect)

    # Faint hexagon grid
    $hexPen = New-Object System.Drawing.Pen(
        [System.Drawing.Color]::FromArgb(18, $AccentR, $AccentG, $AccentB), 1)
    $size = 46.0
    $hStep = 1.5 * $size
    $vStep = [Math]::Sqrt(3) * $size
    for ($y = -$vStep; $y -lt $H + $vStep; $y += $vStep) {
        $row = [int](($y + $vStep) / $vStep)
        $offs = if ($row % 2 -eq 0) { 0 } else { $hStep / 2 }
        for ($x = -$hStep + $offs; $x -lt $W + $hStep; $x += $hStep) {
            $pts = New-Object 'System.Drawing.PointF[]' 6
            for ($i = 0; $i -lt 6; $i++) {
                $ang = 2 * [Math]::PI * $i / 6 + [Math]::PI / 6
                $pts[$i] = New-Object System.Drawing.PointF(
                    ($x + $size * [Math]::Cos($ang)),
                    ($y + $size * [Math]::Sin($ang)))
            }
            $g.DrawPolygon($hexPen, $pts)
        }
    }

    # Radial accent glow - upper right
    $glow = New-Object System.Drawing.Drawing2D.GraphicsPath
    $cx = [single]($W * 0.82); $cy = [single]($H * 0.16); $cr = [single]($W * 0.42)
    $glow.AddEllipse($cx - $cr, $cy - $cr, 2 * $cr, 2 * $cr)
    $pBrush = New-Object System.Drawing.Drawing2D.PathGradientBrush($glow)
    $pBrush.CenterColor = [System.Drawing.Color]::FromArgb(70, $AccentR, $AccentG, $AccentB)
    $pBrush.SurroundColors = @([System.Drawing.Color]::FromArgb(0, 0, 0, 0))
    $g.FillPath($pBrush, $glow)

    # Radiant accent glow - lower left (secondary)
    $glow2 = New-Object System.Drawing.Drawing2D.GraphicsPath
    $c2x = [single]($W * 0.14); $c2y = [single]($H * 0.85); $c2r = [single]($W * 0.35)
    $glow2.AddEllipse($c2x - $c2r, $c2y - $c2r, 2 * $c2r, 2 * $c2r)
    $pBrush2 = New-Object System.Drawing.Drawing2D.PathGradientBrush($glow2)
    $pBrush2.CenterColor = [System.Drawing.Color]::FromArgb(40, $AccentR, $AccentG, $AccentB)
    $pBrush2.SurroundColors = @([System.Drawing.Color]::FromArgb(0, 0, 0, 0))
    $g.FillPath($pBrush2, $glow2)

    # Wordmark "Chigos"
    $fontWord = New-Object System.Drawing.Font($FontFace, 210, [System.Drawing.FontStyle]::Bold)
    $str     = 'Chigos'
    $sz      = $g.MeasureString($str, $fontWord)
    $wx      = ($W - $sz.Width) / 2
    $wy      = ($H - $sz.Height) / 2 - 70

    # Shadow
    $shadow = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(120, 0, 0, 0))
    $g.DrawString($str, $fontWord, $shadow, $wx + 5, $wy + 6)

    # Gradient text fill via brush
    $textRect = New-Object System.Drawing.RectangleF($wx, $wy, $sz.Width, $sz.Height)
    $textBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        $textRect,
        [System.Drawing.Color]::White,
        [System.Drawing.Color]::FromArgb(215, 230, 245),
        0.0)
    $g.DrawString($str, $fontWord, $textBrush, $wx, $wy)

    # Accent underline bar
    $barW = 520.0; $barH = 8.0
    $barX = ($W - $barW) / 2; $barY = $wy + $sz.Height + 28
    $barBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        (New-Object System.Drawing.RectangleF($barX, $barY, $barW, $barH)),
        [System.Drawing.Color]::FromArgb(255, $AccentR, $AccentG, $AccentB),
        [System.Drawing.Color]::FromArgb(255, ($AccentR * 0.4), ($AccentG * 0.4), ($AccentB * 0.4)),
        0.0)
    $g.FillRectangle($barBrush, $barX, $barY, $barW, $barH)

    # Tagline
    $fontTag = New-Object System.Drawing.Font($FontFaceM, 30, [System.Drawing.FontStyle]::Regular)
    $tagBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(200, 200, 212))
    $tsz = $g.MeasureString($Tagline, $fontTag)
    $g.DrawString($Tagline, $fontTag, $tagBrush, ($W - $tsz.Width) / 2, $barY + $barH + 22)

    $path = Join-Path $OutDir "$Name.png"
    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $bmp.Dispose()
    Write-Host "Generated: $path"
}

function New-Logo {
    param([int]$Size=512, [int]$AccentR, [int]$AccentG, [int]$AccentB)

    $bmp = New-Object System.Drawing.Bitmap($Size, $Size)
    $g   = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAlias

    $rect = New-Object System.Drawing.Rectangle(0, 0, $Size, $Size)
    $bg = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        $rect,
        [System.Drawing.Color]::FromArgb(255, 13, 17, 23),
        [System.Drawing.Color]::FromArgb(255, 4, 6, 11),
        90.0)
    $g.FillRectangle($bg, $rect)

    # Hexagon socket
    $hexPen = New-Object System.Drawing.Pen(
        [System.Drawing.Color]::FromArgb(220, $AccentR, $AccentG, $AccentB), 10)
    $cx = $Size / 2; $cy = $Size / 2; $R = $Size * 0.38
    $pts = New-Object 'System.Drawing.PointF[]' 6
    for ($i = 0; $i -lt 6; $i++) {
        $ang = 2 * [Math]::PI * $i / 6 - [Math]::PI / 2
        $pts[$i] = New-Object System.Drawing.PointF(($cx + $R * [Math]::Cos($ang)), ($cy + $R * [Math]::Sin($ang)))
    }
    $g.DrawPolygon($hexPen, $pts)

    # Inner "C" glyph
    $fontC = New-Object System.Drawing.Font($FontFace, [single]($R * 1.15), [System.Drawing.FontStyle]::Bold)
    $sz   = $g.MeasureString('C', $fontC)
    $cBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, $AccentR, $AccentG, $AccentB))
    $g.DrawString('C', $fontC, $cBrush, ($cx - $sz.Width / 2), ($cy - $sz.Height / 2))

    $path = Join-Path $OutDir "logo-chigos.png"
    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $bmp.Dispose()
    Write-Host "Generated: $path"
}

# ---- Render all assets ------------------------------------------------------
New-Wallpaper -Name 'wallpaper-chigos-dark'  -W 2560 -H 1440 -AccentR 61 -AccentG 199 -AccentB 120 -Tagline 'FOR CS STUDENTS · CODERS · PENTESTERS'
New-Wallpaper -Name 'wallpaper-chigos-blue'  -W 2560 -H 1440 -AccentR 64 -AccentG 156 -AccentB 255 -Tagline 'OPENCODE · GAMING · HACKING TOOLSET'
New-Wallpaper -Name 'wallpaper-chigos-green' -W 2560 -H 1440 -AccentR 130 -AccentG 90 -AccentB 255 -Tagline 'OPENCODE · GAMING · HACKING TOOLSET'
New-Logo -Size 512 -AccentR 64 -AccentG 156 -AccentB 255

Write-Host "All Chigos brand assets written to $OutDir"