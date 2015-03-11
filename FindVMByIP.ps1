##############################
# Datastore Tag Check
# Author: Jared Griffes and Jordan Sheen
# Date: 11 March 2015
#
# Usage:
# ./findvmbyip
#
##############################

if ($global:DefaultViServers.count -gt 0){
	Write-host "Connected to the ViServer: "
	$global.DefaultViServers
} else{
	$viserver = Read-host "Connect to which server?"
	connect-viserver -server $viserver
}

$tgtIP = read-host "enter IP Address to find"
$vms = Get-VM
foreach($vm in $vms){
  
  $vmIP = $vm.Guest.IPAddress
  foreach($ip in $vmIP){
    if($ip -eq $tgtIP) {
      Write-Host "Found the VM!" 
      $vm.Name 
    }
  }
}