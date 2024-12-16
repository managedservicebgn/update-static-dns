[CmdletBinding()]
param(
    [string]$OutputPath = ".\ComputerDNSInfo.json",
    [string]$ErrorLogPath = ".\ComputerDNSErrors.json"
)

# Domain filter, e.g., domain name is "mydomain.local"
$domainTLD = "local"
$domainSLD = "mydomain"  # Change this to your domain's SLD

function Write-Log {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        [Parameter(Mandatory=$false)]
        [ValidateSet("Info", "Warning", "Error")]
        [string]$Level = "Info"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    switch ($Level) {
        "Info" { Write-Host $logMessage -ForegroundColor Green }
        "Warning" { Write-Host $logMessage -ForegroundColor Yellow }
        "Error" { Write-Host $logMessage -ForegroundColor Red }
    }
}

try {
    Write-Log "Fetching computer list from Active Directory using Get-ADComputer"

    try {
        # Attempt to get the computer list using Get-ADComputer
        $computers = Get-ADComputer -Filter * -SearchBase "DC=$domainSLD,DC=$domainTLD" | Select-Object -ExpandProperty Name
        Write-Log "Successfully fetched computer list using Get-ADComputer"
    }
    catch {
        Write-Warning "Get-ADComputer failed: $($_.Exception.Message). Falling back to dsquery."

        # Fallback to dsquery if Get-ADComputer fails
        $computers = dsquery computer | Where-Object { $_ -like "*DC=$domainSLD,DC=$domainTLD*" } | ForEach-Object {
            ($_ -split ',')[0] -replace '^"CN=', '' -replace '^CN=', ''
        }

        if ($computers) {
            Write-Log "Successfully fetched computer list using dsquery"
        }
        else {
            throw "Failed to fetch computer list using both Get-ADComputer and dsquery."
        }
    }

    Write-Log "Resolving DNS for computers"
    $computerInfo = $computers | ForEach-Object {
        $computer = $_
        $result = $null
        $errorDetails = $null

        try {
            $dnsResult = Resolve-DnsName $computer -Type A -ErrorAction Stop

            # Construct result object
            $result = @{
                Name = $computer
                IPAddress = $dnsResult.IPAddress
                FullDNSName = $dnsResult.Name
            }
        }
        catch {
            # Capture detailed error information
            $errorDetails = @{
                Name = $computer
                ErrorMessage = $_.Exception.Message
                ErrorType = $_.Exception.GetType().FullName
            }
        }

        # Return result or error
        [PSCustomObject]@{
            Result = $result
            Error = $errorDetails
        }
    } | Where-Object { $_ -ne $null }

    # Separate successful and failed resolutions
    $successfulResolutions = $computerInfo.Where({ $_.Result -ne $null }).Result
    $failedResolutions = $computerInfo.Where({ $_.Error -ne $null }).Error

    Write-Log "Outputting successful DNS resolutions"
    $successfulResolutions | ConvertTo-Json -Depth 5 | Out-File $OutputPath -Encoding UTF8

    # Output error log
    if ($failedResolutions) {
        Write-Log "Outputting DNS resolution errors" -Level Warning
        $failedResolutions | ConvertTo-Json -Depth 5 | Out-File $ErrorLogPath -Encoding UTF8
    }

    Write-Log "Total Computers Processed: $($computers.Count)" -Level Info
    Write-Log "Successfully Resolved: $($successfulResolutions.Count)" -Level Info
}
catch {
    Write-Log "Critical Error: $($_.Exception.Message)" -Level Error
}
