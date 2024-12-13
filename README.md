# How-To

1. Clone or download this repository to a computer that has access to Active Directory.
2. Change domain filter `domainTLD` and `domainSLD` inside file `ADComputerDNSInfo.ps1` to your domain name.
3. Open PowerShell as an Administrator and execute the `ADComputerDNSInfo.ps1` script.
4. After running the script, review the `ComputerDNSInfo.json` file located in the same folder.
5. Change `zoneName` inside file `UpdateADComputerDNSInfo.ps1` to your zone name (e.g yourdomain.com).
6. To update static DNS records, run the `UpdateADComputerDNSInfo.ps1` script in PowerShell.
