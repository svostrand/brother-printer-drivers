# PowerShell script to install an IP printer with Brother MFC-EX915DW driver
# Update the $printerIP and $printerName as needed


# Scan for gdi.zip in NinjaOne Downloads directory and extract to NinjaOne scripts directory
$ninjaDownloadsPath = "C:\ProgramData\NinjaRMMAgent\download"
$ninjaScriptsDir = "C:\ProgramData\NinjaRMMAgent\download"
$gdiZip = Join-Path $ninjaDownloadsPath "gdi.zip"


# Download gdi.zip from public GitHub repo if not present (commented out for now)
# if (!(Test-Path $gdiZip)) {
#     Write-Host "gdi.zip not found. Downloading from GitHub repo..."
#     $githubUrl = "https://github.com/svostrand/brother-printer-drivers/raw/main/gdi.zip"
#     try {
#         Invoke-WebRequest -Uri $githubUrl -OutFile $gdiZip -UseBasicParsing
#         Write-Host "Download complete."
#     } catch {
#         Write-Host "Failed to download gdi.zip from GitHub. $_"
#     }
# }

# if (Test-Path $gdiZip) {
# 	Write-Host "Found gdi.zip. Extracting to $ninjaScriptsDir..."
# 	if (!(Test-Path $ninjaScriptsDir)) {
# 		New-Item -ItemType Directory -Path $ninjaScriptsDir | Out-Null
# 	}
# 	Expand-Archive -Path $gdiZip -DestinationPath $ninjaScriptsDir -Force
# 	Write-Host "Extraction complete."
# } else {
# 	Write-Host "gdi.zip not found on Desktop."
# }

# Detect OS architecture
$arch = if ([System.Environment]::Is64BitOperatingSystem) { "amd64" } else { "x86" }
Write-Host "Detected OS architecture: $arch"

# Set GDI folder in NinjaOne Downloads directory for driver files
$gdiDir = Join-Path $ninjaScriptsDir "gdi"

# Set path to the main printer INF file
$driverInfPath = Join-Path $gdiDir "BRPRM20A.INF"

# Prompt for IP address
$printerIP = Read-Host "Enter the printer IP address"

# Prompt for printer model selection
$models = @(
    @{ Name = "MFC-EX915DW"; Driver = "Brother MFC-EX915DW series" },
    @{ Name = "MFC-L5715DW"; Driver = "Brother MFC-L5715DW Printer" }
)

Write-Host "Select printer model:"
for ($i = 0; $i -lt $models.Count; $i++) {
	Write-Host "$($i+1): $($models[$i].Name)"
}
$modelIndex = Read-Host "Enter the number for the printer model (1-$($models.Count))"



$selectedModel = $models[$modelIndex-1]
$printerName = $selectedModel.Name
# Set the exact driver name as it appears in the printer INF file (update this if needed)
$driverName = $selectedModel.Driver



# Install the printer driver
Write-Host "Installing printer driver..."
Add-PrinterDriver -Name $driverName

# Create Standard TCP/IP port if it doesn't exist
$portName = $printerIP
if (-not (Get-PrinterPort -Name $portName -ErrorAction SilentlyContinue)) {
	Write-Host "Creating Standard TCP/IP Port $portName..."
	Add-PrinterPort -Name $portName -PrinterHostAddress $printerIP
}

# Add the printer
Write-Host "Adding printer..."
Add-Printer -Name $printerName -DriverName $driverName -PortName $portName

Write-Host "Printer installation complete."
