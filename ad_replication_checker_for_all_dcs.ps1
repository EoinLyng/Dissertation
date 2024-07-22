
### PowerShell Script to Check AD Replication for All Domain Controllers and show last time of replication


# ad_health_checker_for_all_dcs.ps1
$allDCs = Get-ADDomainController -Filter *
$errors = $false

foreach ($dc in $allDCs) {
    Write-Host "Checking Domain Controller: $($dc.Name)"
    
    # Check AD Replication
    $replicationStatus = Get-ADReplicationPartnerMetadata -Target $dc.HostName
    $replicationStatus | ForEach-Object {
        if ($_.LastReplicationSuccess -eq $null -or $_.ResultCode -ne 0) {
            Write-Host "Replication error with server: $($_.Server)"
            Write-Host "Last attempted: $($_.LastReplicationAttempt)"
            Write-Host "Result code: $($_.ResultCode)"
            $errors = $true
        } else {
            Write-Host "Replication successful with server: $($_.Server)"
            Write-Host "Last replication attempt: $($_.LastReplicationAttempt)"
        }
    }

    # Check Service Status
    $services = Get-Service -ComputerName $dc.HostName -Name NTDS, DNS, KDC
    foreach ($service in $services) {
        if ($service.Status -ne "Running") {
            Write-Host "$($service.Name) service not running on $($dc.Name)"
            $errors = $true
        } else {
            Write-Host "$($service.Name) service is running on $($dc.Name)"
        }
    }
}

if ($errors) {
    exit 1
}
