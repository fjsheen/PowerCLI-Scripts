##############################
# Move vCD VMs to correct pools
# Author: Jordan Sheen
# Description: This script was written to automate moving 
# several hundred VMs back to the correct resource pools.
#
# Usage:
# ./movecivmtocorrectresourcepool.ps1
#
##############################




Write-Host -foregroundcolor green "`r`n`r`nStarting CIVM Resource Pool Move..."
#Check if connected to ycloud, if not, initiate connection
if(!$global:defaultciservers){
Write-Host "Connecting to vCD.."
connect-ciserver 
}
#check
if(!$defaultviservers){
connect-viserver 
}
#check for module
$moduleCheck = get-module -name convert-tovm | select-object *
if(!$moduleCheck){
	Write-Host -foregroundcolor red "Convert-ToVM Module not loaded"
	exit
}

$moveItems = @();

Write-Host -foregroundcolor darkmagenta "Collecting Organizations..."
$organizations = get-org
$organizations = $organizations | sort-object
foreach ($org in $organizations){
	$orgVDC = get-org -name $org | get-orgvdc #get-orgvdc
	Write-Host -ForegroundColor cyan "Collecting orgvdcs for " $org
	if(!$orgvdc){
		continue
	}
	foreach ($vdc in $orgVDC){
		Write-Host -foregroundColor green "Checking ORG" $vdc.name
		$vApps = $vdc | get-civapp
		if(!$vApps){
			continue
		}
		foreach ($vApp in $vApps){
			$civms = $vApp | get-civm
			foreach ($civm in $civms){
				if ($civm.status -eq "FailedCreation"){
					continue
				} elseif (!$civm){
					continue
				}
				$vmrr = $civm | convert-tovm
				$rp =  $vmrr.resourcepool
				$name = $vmrr.name
								
				if ($rp -match "resources"){
					$moveTask = new-object psobject
					$torp = get-resourcepool | where-object {$_.name -match $vdc.name}
					Add-member -inputobject $movetask -memberType NoteProperty -name "vmtomove" -Value $vmrr.name
					Add-member -inputobject $movetask -membertype NoteProperty -name "destrp" -value $torp; #$org.name when getting all orgs
					$movetask.vmtomove
					$movetask.destrp
					$moveItems += $movetask
				}				
			}
		}
	}	
}
#Start move
foreach ($move in $moveItems){
	#Write-host -foregroundcolor white $move
	get-vm -name $move.vmtomove | move-vm -destination (get-resourcepool -name $move.destrp)
}