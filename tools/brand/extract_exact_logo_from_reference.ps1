param(
  [Parameter(Mandatory=$true)]
  [string]$Source,

  [string]$OutputDir = "."
)

$ErrorActionPreference = "Stop"

# FTR Akademi Plan 3 — EXACT approved brand extraction.
# Source reference: "ChatGPT Image 3 Eyl 2026 13_01_16.png"
# This script performs ONLY a rectangular pixel crop from the approved source.
# No resize, redraw, tracing, recolor, filter, sharpening, generative processing,
# compression re-interpretation, or AI transformation is permitted.

Add-Type -AssemblyName System.Drawing

$sourcePath = (Resolve-Path -LiteralPath $Source).Path
$sourceFile = Get-Item -LiteralPath $sourcePath
if (-not $sourceFile.Exists) { throw "Approved source image not found: $Source" }

$sourceImage = [System.Drawing.Image]::FromFile($sourcePath)
try {
  if ($sourceImage.Width -ne 1536 -or $sourceImage.Height -ne 1024) {
    throw "Unexpected approved-reference dimensions: $($sourceImage.Width)x$($sourceImage.Height). Expected 1536x1024. Refusing crop."
  }

  # Approved emblem instance: the large in-app empty/loading-screen logo shown in
  # the LEFT reference panel. Coordinates are expressed in ORIGINAL source pixels.
  # A small surrounding dark margin is intentionally retained so no emblem pixels
  # are clipped. Visual phone QA remains mandatory before FINAL/LOCKED status.
  $cropX = 137
  $cropY = 468
  $cropW = 112
  $cropH = 112

  if ($cropX -lt 0 -or $cropY -lt 0 -or ($cropX + $cropW) -gt $sourceImage.Width -or ($cropY + $cropH) -gt $sourceImage.Height) {
    throw "Crop rectangle is outside the approved source image."
  }

  New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
  $out = Join-Path $OutputDir "ftr-logo-exact.png"
  $shaOut = Join-Path $OutputDir "ftr-logo-exact.sha256"
  $metaOut = Join-Path $OutputDir "ftr-logo-exact.metadata.json"

  if (Test-Path -LiteralPath $out) { throw "Refusing to overwrite existing exact logo: $out" }
  if (Test-Path -LiteralPath $shaOut) { throw "Refusing to overwrite existing SHA lock: $shaOut" }
  if (Test-Path -LiteralPath $metaOut) { throw "Refusing to overwrite existing metadata: $metaOut" }

  $sourceBitmap = New-Object System.Drawing.Bitmap $sourceImage
  try {
    $rect = New-Object System.Drawing.Rectangle($cropX, $cropY, $cropW, $cropH)
    $crop = $sourceBitmap.Clone($rect, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    try {
      # PNG serialization is lossless. Pixel RGB(A) values inside the selected
      # rectangle are copied from the approved source; no resampling occurs.
      $crop.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
    }
    finally {
      $crop.Dispose()
    }
  }
  finally {
    $sourceBitmap.Dispose()
  }

  $sourceSha = (Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash.ToLowerInvariant()
  $logoSha = (Get-FileHash -Algorithm SHA256 -LiteralPath $out).Hash.ToLowerInvariant()
  Set-Content -LiteralPath $shaOut -Value $logoSha -NoNewline -Encoding ascii

  $meta = [ordered]@{
    status = "PIXEL_PRESERVING_CROP_CREATED_PHONE_VISUAL_QA_REQUIRED"
    approved_source_filename = $sourceFile.Name
    approved_source_sha256 = $sourceSha
    approved_source_dimensions = "1536x1024"
    crop = [ordered]@{ x=$cropX; y=$cropY; width=$cropW; height=$cropH }
    output_filename = "ftr-logo-exact.png"
    output_sha256 = $logoSha
    operations = @("rectangular_crop_only", "lossless_png_save")
    forbidden_operations_confirmed_absent = @("resize", "recolor", "filter", "sharpen", "trace", "AI_regeneration", "upscale")
    physical_phone_visual_qa = "PENDING"
    final_locked = $false
  }
  $meta | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $metaOut -Encoding utf8

  Write-Host "EXACT LOGO CROP CREATED"
  Write-Host "Source SHA-256: $sourceSha"
  Write-Host "Logo SHA-256:   $logoSha"
  Write-Host "Output:         $out"
  Write-Host "Lock:           $shaOut"
  Write-Host "Metadata:       $metaOut"
  Write-Host "PHONE VISUAL QA STILL REQUIRED"
}
finally {
  $sourceImage.Dispose()
}
