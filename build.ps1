# Vajra 2.0 Build Script
# Usage: .\build.ps1 [dev|prod|test|bench|clean]

param(
    [Parameter(Position=0)]
    [string]$Target = "dev"
)

$ProjectRoot = $PSScriptRoot
$SrcDir = Join-Path $ProjectRoot "src"
$OutputDir = Join-Path $ProjectRoot "bin"
$ExeName = "vajra2.exe"
$OutputExe = Join-Path $OutputDir $ExeName

# Ensure output directory exists
if (!(Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}

function Build-Dev {
    Write-Host "Building Vajra 2.0 (Development)..." -ForegroundColor Cyan
    # -gc none might be useful for chess engines to avoid GC pauses, but unsafe if memory management is not manual.
    # V usually handles memory well with default autofree or GC. keeping check.
    v -g $SrcDir -o $OutputExe
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Build successful!" -ForegroundColor Green
    } else {
        Write-Host "✗ Build failed!" -ForegroundColor Red
        exit 1
    }
}

function Build-Prod {
    Write-Host "Building Vajra 2.0 (Production)..." -ForegroundColor Cyan
    # Using TCC with manual memory management (fastest for engines if no leaks)
    # Refactored search to be alloc-free.
    v -prod -gc none -cc tcc $SrcDir -o $OutputExe
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Production build successful!" -ForegroundColor Green
        $size = (Get-Item $OutputExe).Length / 1KB
        Write-Host "Binary size: $([math]::Round($size, 2)) KB" -ForegroundColor Yellow
    } else {
        Write-Host "✗ Build failed!" -ForegroundColor Red
        exit 1
    }
}

function Run-App {
    if (Test-Path $OutputExe) {
        & $OutputExe
    } else {
        Write-Host "Binary not found. Build first." -ForegroundColor Yellow
    }
}

switch ($Target) {
    "dev"   { Build-Dev }
    "prod"  { Build-Prod }
    "run"   { Build-Dev; Run-App }
    default { Build-Dev }
}
