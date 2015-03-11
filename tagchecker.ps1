##############################
# Datastore Tag Check
# Author: Jordan Sheen
# Date: 11 March 2015
#
# Usage:
# ./tagchecker.ps1
#
##############################

Write-host "TagChecker running..."

if ($global:DefaultViServers.count -gt 0){
	Write-host "Connected to the ViServer: "
	$global.DefaultViServers
} else{
	$viserver = Read-host "Connect to which server?"
	connect-viserver -server $viserver
}

Write-host "Checking datastores..."

$dc = get-datastorecluster
foreach ($datastorecluster in $dc){
	$dscount = 0;
	$dstagcount = 0;
	#Does the datastorecluster have an assignment?
	$dctag = get-tagassignment -entity $datastorecluster
	if (!$dctag){
		$dc_tag_flag = 0;
		Write-host "Not checking $datastorecluster"
		return
	} else{
		$dc_tag_flag = 1;
		Write-host "$datastorecluster is tagged."
	}
	
	Write-host "Checking datastores in $datastorecluster for tags"
	$datastores = $datastorecluster | get-datastore
	$dscount = $datastores.count
	foreach ($datastore in $datastores){
		$assignment = get-tagassignment -entity $datastore
		if ($assignment){
			$dstagcount++;
		}
	}
	
	if ($dscount -ne $dstagcount){
		Write-host "Total Datastores: $dscount"
		Write-host "Total tags: $dstagcount"
		Write-host -foregroundcolor "red" "Not all datastores in $datastorecluster are tagged."
	} else{
		Write-host -foregroundcolor "green" "All Datastores in $datastorecluster are tagged."
	}
	
}
