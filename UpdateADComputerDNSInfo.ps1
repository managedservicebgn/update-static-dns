# DNS Server and Zone Configuration 
$zoneName = "ganti-zone-name-nya"

# Import JSON file
$computers = Get-Content .\ComputerDNSInfo.json | ConvertFrom-Json

# Loop through computers and add A records
foreach ($computer in $computers) {
    $fullDnsName = $computer.FullDNSName
    $ipAddress = $computer.IPAddress

    try {
        # Try to add DNS A Record using Add-DnsServerResourceRecord
        Add-DnsServerResourceRecord -A `
            -Name $computer.Name `
            -ZoneName $zoneName `
            -IPv4Address $ipAddress `
            -ErrorAction Stop

        Write-Host "Successfully added A record for $fullDnsName with IP $ipAddress using Add-DnsServerResourceRecord" -ForegroundColor Green
    }
    catch {
        Write-Warning "Add-DnsServerResourceRecord failed for $fullDnsName. Trying with dnscmd..."

        try {
            # Fallback to dnscmd if Add-DnsServerResourceRecord fails
            dnscmd . /RecordAdd $zoneName $computer.Name A $ipAddress > $null 2>&1
            Write-Host "Successfully added A record for $fullDnsName with IP $ipAddress using dnscmd" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to add DNS record for $fullDnsName with both Add-DnsServerResourceRecord and dnscmd: $($_.Exception.Message)"
        }
    }
}
