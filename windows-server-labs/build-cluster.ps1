# Two-node Hyper-V failover cluster build
# Run each section on the machine named in the comment. Passwords are placeholders.

# ---------- Hyper-V host ----------
New-VMSwitch -Name "MainSwitch"     -SwitchType Internal
New-VMSwitch -Name "myStorageNet"   -SwitchType Internal
New-VMSwitch -Name "myHeartbeatNet" -SwitchType Internal

$vms = @(
  @{Name="DC";      Memory=2GB;  VHD=50GB},
  @{Name="Storage"; Memory=2GB;  VHD=60GB},
  @{Name="VH1";     Memory=10GB; VHD=80GB},
  @{Name="VH2";     Memory=10GB; VHD=80GB}
)
foreach ($vm in $vms) {
  New-VM -Name $vm.Name -MemoryStartupBytes $vm.Memory -Generation 2 `
    -NewVHDPath "C:\Hyper-V\$($vm.Name).vhdx" -NewVHDSizeBytes $vm.VHD `
    -Path "C:\Hyper-V\" -SwitchName "MainSwitch"
}

Add-VMNetworkAdapter -VMName "Storage" -SwitchName "myStorageNet"   -Name "StorageNIC"
foreach ($n in "VH1","VH2") {
  Add-VMNetworkAdapter -VMName $n -SwitchName "myStorageNet"   -Name "StorageNIC"
  Add-VMNetworkAdapter -VMName $n -SwitchName "myHeartbeatNet" -Name "HeartbeatNIC"
  Set-VMProcessor -VMName $n -ExposeVirtualizationExtensions $true   # nodes must be off
}

# ---------- Every VM: static IP (example for DC) ----------
New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 172.50.57.100 -PrefixLength 24 -DefaultGateway 172.50.57.1
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 172.50.57.100
Enable-NetFirewallRule -DisplayName "File and Printer Sharing (Echo Request - ICMPv4-In)"

# ---------- DC ----------
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools
Install-ADDSForest -DomainName "tuladhar.local" -DomainNetbiosName "TULADHAR" -InstallDNS `
  -SafeModeAdministratorPassword (Read-Host -AsSecureString "DSRM password")

# ---------- Storage, VH1, VH2 ----------
Add-Computer -DomainName "tuladhar.local" -Credential TULADHAR\Administrator -Restart

# ---------- VH1 and VH2 ----------
Install-WindowsFeature -Name Hyper-V, Failover-Clustering -IncludeManagementTools -Restart
Set-Service MSiSCSI -StartupType Automatic; Start-Service MSiSCSI
(Get-InitiatorPort).NodeAddress          # note each node's IQN

# ---------- Storage server ----------
Install-WindowsFeature FS-iSCSITarget-Server -IncludeManagementTools
New-IscsiVirtualDisk -Path "C:\iSCSIDisk\ClusterDisk1.vhdx" -SizeBytes 25GB
New-IscsiServerTarget -TargetName "ClusterTarget" -InitiatorIds `
  "IQN:iqn.1991-05.com.microsoft:vh1.tuladhar.local", "IQN:iqn.1991-05.com.microsoft:vh2.tuladhar.local"
Add-IscsiVirtualDiskTargetMapping -TargetName "ClusterTarget" -Path "C:\iSCSIDisk\ClusterDisk1.vhdx"

# ---------- VH1 and VH2: connect over the storage network ----------
New-IscsiTargetPortal -TargetPortalAddress 192.168.111.200
Get-IscsiTarget | Connect-IscsiTarget -IsPersistent $true

# ---------- VH1 only ----------
Test-Cluster -Node VH1, VH2
New-Cluster -Name "HACluster" -Node VH1, VH2 -StaticAddress 172.50.57.101 -IgnoreNetwork 192.168.222.0/24
Get-ClusterAvailableDisk | Add-ClusterDisk

# Disk got taken as quorum witness -> free it, then make it a CSV
Get-ClusterQuorum
Set-ClusterQuorum -NodeMajority
Move-ClusterResource -Name "Cluster Disk 1" -Group "Available Storage"
Add-ClusterSharedVolume -Name "Cluster Disk 1"
Get-ClusterSharedVolume

# Highly available VM on the CSV, then live migration test
New-VM -Name AppServer -MemoryStartupBytes 4GB -Generation 2 -Path "C:\ClusterStorage\Volume1" `
  -NewVHDPath "C:\ClusterStorage\Volume1\AppServer.vhdx" -NewVHDSizeBytes 35GB
Add-ClusterVirtualMachineRole -VMName AppServer
Move-ClusterVirtualMachineRole -Name AppServer -Node VH2 -MigrationType Live
