[CmdletBinding()]
param(
    [switch]$ConfigureOnly,
    [string]$DeviceId
)

$ErrorActionPreference = 'Stop'

function Get-ActiveWifiIPv4Address {
    $candidates = [System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() |
        Where-Object {
            $_.OperationalStatus -eq [System.Net.NetworkInformation.OperationalStatus]::Up -and
            $_.NetworkInterfaceType -eq [System.Net.NetworkInformation.NetworkInterfaceType]::Wireless80211
        } |
        ForEach-Object {
            $properties = $_.GetIPProperties()
            $address = $properties.UnicastAddresses |
                Where-Object {
                    $_.Address.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork -and
                    -not [System.Net.IPAddress]::IsLoopback($_.Address) -and
                    -not $_.Address.ToString().StartsWith('169.254.')
                } |
                Select-Object -First 1

            if ($null -ne $address) {
                [PSCustomObject]@{
                    Name = $_.Name
                    Address = $address.Address.ToString()
                    HasGateway = $properties.GatewayAddresses.Count -gt 0
                }
            }
        }

    $selected = $candidates |
        Sort-Object -Property @{ Expression = 'HasGateway'; Descending = $true } |
        Select-Object -First 1

    if ($null -eq $selected) {
        throw 'No active Wi-Fi IPv4 address was found. Connect this computer and the Android phone to the same Wi-Fi network.'
    }

    return $selected
}

$wifi = Get-ActiveWifiIPv4Address
$apiBaseUrl = "http://$($wifi.Address):8080"
$healthUrl = "$apiBaseUrl/api/v1/health"

Write-Host "Detected Wi-Fi adapter '$($wifi.Name)' at $($wifi.Address)."
Write-Host "Checking NhamHealth API at $healthUrl ..."

try {
    $health = Invoke-RestMethod -Uri $healthUrl -Method Get -TimeoutSec 5
} catch {
    throw "The API is not reachable at $apiBaseUrl. Start nhamhealth_api and ensure server.address=0.0.0.0. $($_.Exception.Message)"
}

if ($health.status -ne 'UP') {
    throw "The API health check at $healthUrl did not return status UP."
}

$appRoot = Split-Path -Parent $PSScriptRoot
$configPath = Join-Path $appRoot 'config\local_api.json'
$config = @{ API_BASE_URL = $apiBaseUrl } | ConvertTo-Json
Set-Content -LiteralPath $configPath -Value $config -Encoding UTF8

Write-Host "Configured Android API base URL: $apiBaseUrl"

if ($ConfigureOnly) {
    exit 0
}

$flutterArguments = @(
    'run',
    '--dart-define-from-file=config/google_oauth.json',
    '--dart-define-from-file=config/local_api.json'
)

if (-not [string]::IsNullOrWhiteSpace($DeviceId)) {
    $flutterArguments += @('-d', $DeviceId)
}

Push-Location $appRoot
try {
    & flutter @flutterArguments
    exit $LASTEXITCODE
} finally {
    Pop-Location
}
