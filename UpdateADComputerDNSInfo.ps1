# DNS Server and Zone Configuration 
# E.g mydomain.com
$zoneName = "ganti-zone-name-nya"

# Import JSON file
$computers = Get-Content .\ComputerDNSInfo.json | ConvertFrom-Json

# Loop through computers and add A records
foreach ($computer in $computers) {
    $fullDnsName = $computer.FullDNSName
    $ipAddress = $computer.IPAddress

    try {
        # Add DNS A Record
        Add-DnsServerResourceRecord -A `
            -Name $computer.Name `
            -ZoneName $zoneName `
            -IPv4Address $ipAddress `
            -ErrorAction Stop

        Write-Host "Successfully added A record for $fullDnsName with IP $ipAddress" -ForegroundColor Green
    }
    catch {
        Write-Warning "Failed to add DNS record for $fullDnsName : $($_.Exception.Message)"
    }
}
