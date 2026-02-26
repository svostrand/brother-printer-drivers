# PowerShell script to install an IP printer with Brother MFC-EX915DW driver
# Update the $printerIP and $printerName as needed


# Scan for gdi.zip in NinjaOne Downloads directory and extract to NinjaOne scripts directory
$ninjaDownloadsPath = "C:\ProgramData\NinjaRMMAgent\Downloads"
$gdiZip = Join-Path $ninjaDownloadsPath "gdi.zip"

# Download gdi.zip from Google Drive if not present (handles large file confirmation)
if (!(Test-Path $gdiZip)) {
	Write-Host "gdi.zip not found. Downloading from Google Drive..."
	$gdriveId = "11EhO0atrif6rffQmku5UmtwZVdncPWn8"
	$baseUrl = "https://drive.google.com/uc?export=download&id=$gdriveId"
	$cookieFile = "$env:TEMP\gdrive_cookie.txt"
	$initialResponse = Invoke-WebRequest -Uri $baseUrl -SessionVariable session -UseBasicParsing
	$confirmToken = $null
	if ($initialResponse.Content -match 'confirm=([0-9A-Za-z_]+)') {
		$confirmToken = $matches[1]
	}
	if ($confirmToken) {
		$downloadUrl = "https://drive.google.com/uc?export=download&confirm=$confirmToken&id=$gdriveId"
		try {
			Invoke-WebRequest -Uri $downloadUrl -OutFile $gdiZip -WebSession $session -UseBasicParsing
			Write-Host "Download complete."
		} catch {
			Write-Host "Failed to download gdi.zip from Google Drive. $_"
		}
	} else {
		Write-Host "Could not retrieve confirmation token. Download may fail."
	}
}
$ninjaScriptsDir = "C:\ProgramData\NinjaRMMAgent\Downloads\gdi"

if (Test-Path $gdiZip) {
	Write-Host "Found gdi.zip. Extracting to $ninjaScriptsDir..."
	if (!(Test-Path $ninjaScriptsDir)) {
		New-Item -ItemType Directory -Path $ninjaScriptsDir | Out-Null
	}
	Expand-Archive -Path $gdiZip -DestinationPath $ninjaScriptsDir -Force
	Write-Host "Extraction complete."
} else {
	Write-Host "gdi.zip not found on Desktop."
}

# Detect OS architecture
$arch = if ([System.Environment]::Is64BitOperatingSystem) { "amd64" } else { "x86" }
Write-Host "Detected OS architecture: $arch"

# Set GDI folder in NinjaOne Downloads directory for driver files
$gdiDir = "C:\ProgramData\NinjaRMMAgent\Downloads\gdi"

# Prompt for IP address
$printerIP = Read-Host "Enter the printer IP address"

# Prompt for printer model selection
$models = @(
	@{ Name = "MFC-EX915DW"; Driver = "Brother MFC-EX915DW"; InFile = "mfc-ex915dwn.in_" },
	@{ Name = "MFC-L5715DW"; Driver = "Brother MFC-L5715DW"; InFile = "mfc-l5715dwn.in_" },
	@{ Name = "MFC-EX575"; Driver = "Brother MFC-EX575"; InFile = "mfc-ex575n.in_" }
)

Write-Host "Select printer model:"
for ($i = 0; $i -lt $models.Count; $i++) {
	Write-Host "$($i+1): $($models[$i].Name)"
}
$modelIndex = Read-Host "Enter the number for the printer model (1-$($models.Count))"

$selectedModel = $models[$modelIndex-1]
$printerName = $selectedModel.Name
$driverName = $selectedModel.Driver
$inFile = Join-Path $gdiDir $selectedModel.InFile
$infFile = [System.IO.Path]::ChangeExtension($inFile, ".inf")

# Expand the .in_ file to .inf if needed
if (!(Test-Path $infFile)) {
	Write-Host "Expanding $inFile to $infFile..."
	expand $inFile $infFile
}

$driverInfPath = $infFile

# Install the printer driver
Write-Host "Installing printer driver..."
Add-PrinterDriver -Name $driverName -InfPath $driverInfPath

# Add the printer
Write-Host "Adding printer..."
Add-Printer -Name $printerName -DriverName $driverName -PortName $printerIP -PortType StandardTCP/IP

Write-Host "Printer installation complete."
