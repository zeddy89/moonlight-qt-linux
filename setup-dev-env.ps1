# PowerShell script to set up development environment for Moonlight-Qt on Windows
# Run as Administrator

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Moonlight-Qt Development Environment Setup" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires Administrator privileges. Please run as Administrator." -ForegroundColor Red
    pause
    exit 1
}

# Function to test if a command exists
function Test-Command($command) {
    try {
        Get-Command $command -ErrorAction Stop | Out-Null
        return $true
    } catch {
        return $false
    }
}

Write-Host "Checking for existing tools..." -ForegroundColor Yellow

# Check for Chocolatey
if (-not (Test-Command choco)) {
    Write-Host "Installing Chocolatey package manager..." -ForegroundColor Green
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    
    # Refresh environment
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

# Check for Git
if (-not (Test-Command git)) {
    Write-Host "Installing Git..." -ForegroundColor Green
    choco install git -y
}

# Check for Visual Studio or Build Tools
$vsWhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
$hasVS = $false

if (Test-Path $vsWhere) {
    $vsPath = & $vsWhere -latest -property installationPath
    if ($vsPath) {
        Write-Host "Visual Studio found at: $vsPath" -ForegroundColor Green
        $hasVS = $true
    }
}

if (-not $hasVS) {
    Write-Host "Visual Studio not found. Installing Build Tools..." -ForegroundColor Yellow
    Write-Host "This will install Visual Studio Build Tools 2022." -ForegroundColor Yellow
    $confirm = Read-Host "Continue? (Y/N)"
    
    if ($confirm -eq 'Y') {
        choco install visualstudio2022buildtools -y
        choco install visualstudio2022-workload-vctools -y
    } else {
        Write-Host "Visual Studio is required. Please install it manually." -ForegroundColor Red
        pause
        exit 1
    }
}

# Check for Qt
Write-Host ""
Write-Host "Checking for Qt..." -ForegroundColor Yellow

$qtPath = $null
$qtVersions = @("6.7", "6.6", "6.5", "6.4", "6.3", "6.2")

foreach ($version in $qtVersions) {
    $testPath = "C:\Qt\$version.*\msvc*"
    if (Test-Path $testPath) {
        $qtPath = (Get-Item $testPath | Select-Object -First 1).FullName
        break
    }
}

if ($qtPath) {
    Write-Host "Qt found at: $qtPath" -ForegroundColor Green
} else {
    Write-Host "Qt not found. Please download and install Qt 6.7+ from:" -ForegroundColor Yellow
    Write-Host "https://www.qt.io/download-qt-installer" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "During installation, select:" -ForegroundColor Yellow
    Write-Host "  - MSVC 2019/2022 64-bit compiler" -ForegroundColor White
    Write-Host "  - Qt Quick" -ForegroundColor White
    Write-Host "  - Qt SVG" -ForegroundColor White
    Write-Host ""
    
    $openBrowser = Read-Host "Open Qt download page in browser? (Y/N)"
    if ($openBrowser -eq 'Y') {
        Start-Process "https://www.qt.io/download-qt-installer"
    }
}

# Install additional dependencies via Chocolatey
Write-Host ""
Write-Host "Installing additional dependencies..." -ForegroundColor Yellow

$packages = @(
    "ffmpeg",
    "7zip",
    "cmake",
    "ninja",
    "python3"
)

foreach ($package in $packages) {
    if (-not (Test-Command $package)) {
        Write-Host "Installing $package..." -ForegroundColor Green
        choco install $package -y
    } else {
        Write-Host "$package already installed" -ForegroundColor Gray
    }
}

# Clone submodules
Write-Host ""
Write-Host "Updating git submodules..." -ForegroundColor Yellow
Set-Location $PSScriptRoot
git submodule update --init --recursive

# Create build directory
if (-not (Test-Path "build")) {
    New-Item -ItemType Directory -Path "build" | Out-Null
    Write-Host "Created build directory" -ForegroundColor Green
}

# Generate VS Code configuration
Write-Host ""
Write-Host "Generating VS Code configuration..." -ForegroundColor Yellow

$vscodeDir = ".vscode"
if (-not (Test-Path $vscodeDir)) {
    New-Item -ItemType Directory -Path $vscodeDir | Out-Null
}

# Create c_cpp_properties.json for IntelliSense
$cppProperties = @'
{
    "configurations": [
        {
            "name": "Win32",
            "includePath": [
                "${workspaceFolder}/**",
                "${workspaceFolder}/app/**",
                "${workspaceFolder}/moonlight-common-c/src",
                "${workspaceFolder}/h264bitstream",
                "${workspaceFolder}/libs/windows/include/x64/**"
            ],
            "defines": [
                "_DEBUG",
                "UNICODE",
                "_UNICODE",
                "Q_OS_WIN32",
                "HAVE_FFMPEG"
            ],
            "windowsSdkVersion": "10.0.22621.0",
            "compilerPath": "cl.exe",
            "cStandard": "c11",
            "cppStandard": "c++17",
            "intelliSenseMode": "windows-msvc-x64"
        }
    ],
    "version": 4
}
'@

$cppProperties | Out-File -FilePath "$vscodeDir\c_cpp_properties.json" -Encoding UTF8

Write-Host "VS Code configuration created" -ForegroundColor Green

# Create convenience build script
Write-Host ""
Write-Host "Creating convenience scripts..." -ForegroundColor Yellow

# Summary
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Install Qt 6.7+ if not already installed" -ForegroundColor White
Write-Host "2. Open Qt Creator and load moonlight-qt.pro" -ForegroundColor White
Write-Host "3. Or run build-windows.bat from Qt command prompt" -ForegroundColor White
Write-Host ""
Write-Host "New optimization features added:" -ForegroundColor Yellow
Write-Host "- Low-latency mode for Ryzen Z1/Z1 Extreme" -ForegroundColor Green
Write-Host "- SteamOS/Gamescope optimizations" -ForegroundColor Green
Write-Host ""
Write-Host "See OPTIMIZATIONS.md for detailed documentation" -ForegroundColor Cyan
Write-Host ""
pause