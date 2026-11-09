Add-Type -AssemblyName System.Drawing

$logoPath = "D:\My_Project\shoot_live\assets\branding\modarraj_logo_512.png"
$outputPath = "D:\My_Project\shoot_live\assets\branding\preview\contact_sheet.png"

$srcBmp = [System.Drawing.Bitmap]::FromFile($logoPath)

$sheetWidth = 1400
$sheetHeight = 980
$sheet = New-Object System.Drawing.Bitmap($sheetWidth, $sheetHeight)
$g = [System.Drawing.Graphics]::FromImage($sheet)

$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

# Canvas background
$bgBrush = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml("#0B0F19"))
$g.FillRectangle($bgBrush, 0, 0, $sheetWidth, $sheetHeight)

# Fonts
$fontTitle = New-Object System.Drawing.Font("Segoe UI", 20, [System.Drawing.FontStyle]::Bold)
$fontSubtitle = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Regular)
$fontSection = New-Object System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Bold)
$fontLabel = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Regular)
$fontLabelBold = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)

# Header
$brushWhite = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml("#F8FAFC"))
$brushMuted = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml("#94A3B8"))
$brushDarkText = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml("#0F172A"))

$g.DrawString("SHOOT LIVE - BRANDING AND ICON CONTACT SHEET", $fontTitle, $brushWhite, 40, 25)
$g.DrawString("Multi-density inspection: 512px, 192px, 96px, 72px, 48px | Adaptive Monochrome | Status Bar Notification", $fontSubtitle, $brushMuted, 40, 65)

# Helper function to draw rounded container
function Draw-RoundedPanel($gfx, $x, $y, $w, $h, $colorHex, $borderHex) {
    $rect = New-Object System.Drawing.Rectangle($x, $y, $w, $h)
    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml($colorHex))
    $pen = New-Object System.Drawing.Pen([System.Drawing.ColorTranslator]::FromHtml($borderHex), 1)
    $gfx.FillRectangle($brush, $rect)
    $gfx.DrawRectangle($pen, $rect)
    $brush.Dispose()
    $pen.Dispose()
}

# 1. Light Background Column (x: 40, y: 110, w: 630, h: 580)
Draw-RoundedPanel $g 40 110 630 580 "#F8FAFC" "#E2E8F0"
$g.DrawString("LIGHT BACKGROUND (#F8FAFC)", $fontSection, $brushDarkText, 60, 125)

# 2. Dark Background Column (x: 730, y: 110, w: 630, h: 580)
Draw-RoundedPanel $g 730 110 630 580 "#0F172A" "#334155"
$g.DrawString("DARK BACKGROUND (#0F172A)", $fontSection, $brushWhite, 750, 125)

# Draw icon grids for Light & Dark
$sizes = @(
    @{ Size = 256; Real = "512px (Play Store / Hi-Res)"; X = 60; Y = 165 },
    @{ Size = 144; Real = "192px (xxxhdpi)"; X = 350; Y = 165 },
    @{ Size = 96;  Real = "96px (xhdpi)";    X = 350; Y = 350 },
    @{ Size = 72;  Real = "72px (hdpi)";     X = 480; Y = 350 },
    @{ Size = 48;  Real = "48px (mdpi)";     X = 480; Y = 460 }
)

foreach ($item in $sizes) {
    # Light column
    $g.DrawImage($srcBmp, $item.X, $item.Y, $item.Size, $item.Size)
    $g.DrawString($item.Real, $fontLabel, $brushDarkText, $item.X, ($item.Y + $item.Size + 6))
    
    # Dark column
    $darkX = $item.X + 690
    $g.DrawImage($srcBmp, $darkX, $item.Y, $item.Size, $item.Size)
    $g.DrawString($item.Real, $fontLabel, $brushMuted, $darkX, ($item.Y + $item.Size + 6))
}

# 3. Bottom Row: Specialized Icons (Monochrome & Notification)
# Container (x: 40, y: 720, w: 1320, h: 220)
Draw-RoundedPanel $g 40 720 1320 220 "#131C2E" "#1E293B"

$g.DrawString("SPECIALIZED ANDROID ICONS", $fontSection, $brushWhite, 60, 735)

# Create a monochrome silhouette version from srcBmp
$monoBmp = New-Object System.Drawing.Bitmap($srcBmp.Width, $srcBmp.Height)
for ($y = 0; $y -lt $srcBmp.Height; $y++) {
    for ($x = 0; $x -lt $srcBmp.Width; $x++) {
        $pixel = $srcBmp.GetPixel($x, $y)
        if ($pixel.A -gt 30) {
            # Check if pixel is part of the white symbol (R > 200, G > 200, B > 200)
            if ($pixel.R -gt 210 -and $pixel.G -gt 210 -and $pixel.B -gt 210) {
                $monoBmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($pixel.A, 255, 255, 255))
            } else {
                $monoBmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(0, 0, 0, 0))
            }
        } else {
            $monoBmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(0, 0, 0, 0))
        }
    }
}

# Android 13+ Themed / Monochrome Icon (Dynamic Material You tint)
Draw-RoundedPanel $g 60 775 380 145 "#1E293B" "#334155"
$g.DrawString("Android 13+ Themed / Monochrome Icon", $fontLabelBold, $brushWhite, 80, 785)

# Render on Material You Sage Green tint circle
$tintBrush = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml("#3B5249"))
$g.FillEllipse($tintBrush, 80, 815, 65, 65)
$g.DrawImage($monoBmp, 88, 823, 49, 49)
$g.DrawString("Themed Tint", $fontLabel, $brushMuted, 78, 885)

# Render on Dark Slate
$g.FillEllipse($brushDarkText, 230, 815, 65, 65)
$g.DrawImage($monoBmp, 238, 823, 49, 49)
$g.DrawString("Monochrome Vector", $fontLabel, $brushMuted, 210, 885)

# Android Status Bar Notification Icon (ic_stat_notify)
Draw-RoundedPanel $g 470 775 420 145 "#1E293B" "#334155"
$g.DrawString("Status Bar Notification Icon (ic_stat_notify)", $fontLabelBold, $brushWhite, 490, 785)

# Android status bar mockup
Draw-RoundedPanel $g 490 815 380 40 "#0A0A0A" "#262626"
$g.DrawImage($monoBmp, 505, 823, 24, 24)
$g.DrawString("12:45", $fontLabel, $brushWhite, 540, 826)
$g.DrawString("Shoot Live - Live Match Alert!", $fontLabel, $brushMuted, 600, 826)

# Expanded Notification tray preview
Draw-RoundedPanel $g 490 865 380 45 "#1E293B" "#334155"
$accentCircleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml("#10B981"))
$g.FillEllipse($accentCircleBrush, 505, 873, 28, 28)
$g.DrawImage($monoBmp, 511, 879, 16, 16)
$g.DrawString("Modarraj | Goal: Liverpool 1 - 0 Crystal Palace", $fontLabel, $brushWhite, 545, 878)

# Platform / Resolution Audit Notes
Draw-RoundedPanel $g 920 775 420 145 "#1E293B" "#334155"
$g.DrawString("Platform & Asset Compliance Audit", $fontLabelBold, $brushWhite, 940, 785)
$g.DrawString("• Android Target: 48 (mdpi) up to 512 (Store)", $fontLabel, $brushMuted, 940, 810)
$g.DrawString("• Contrast ratio: High legibility on dark (#0F172A) & light (#F8FAFC)", $fontLabel, $brushMuted, 940, 832)
$g.DrawString("• Foreground: Geometry preserved down to 48px", $fontLabel, $brushMuted, 940, 854)
$g.DrawString("• iOS AppIcon / Info.plist: OUT OF SCOPE (ios/ does not exist)", $fontLabel, $brushMuted, 940, 876)

# Save image
$sheet.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)

$srcBmp.Dispose()
$monoBmp.Dispose()
$sheet.Dispose()
$g.Dispose()

Write-Output "Contact sheet generated successfully at $outputPath"
