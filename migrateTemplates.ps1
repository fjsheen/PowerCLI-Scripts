$templateFolder = $args[0]
$dsName = $args[1]

function Move-VMTemplate{
    param( [string] $templateFolder, [string] $datastore)

    if($templateFolder -eq ""){Write-Host "Enter a folder name"}
    if($datastore -ne ""){$svmotion = $true}
	
	$vms = @();	
	$templates = get-template -location $template;
	
	foreach ($template in $templates){
		$vm = Set-Template -Template $template -ToVM;
		Write-Host "Converting $template to VM";
		$vms += $vm;
	}    
	
    foreach ($vm in $vms){
	    Write-Host "Migrate $vm to $datastore"
		# Move-VM -VM (Get-VM $vm) -Destination (Get-VMHost $esx) -Datastore (Get-Datastore $datastore) -Confirm:$false
		Move-VMThin (Get-VM $vm) (Get-Datastore $datastore)

		Write-Host "Converting $template to template"
		(Get-VM $vm | Get-View).MarkAsTemplate() | Out-Null
	}


}

function Move-VMThin {
    PARAM(
         [Parameter(Mandatory=$true,ValueFromPipeline=$true,HelpMessage="Virtual Machine Objects to Migrate")]
         [ValidateNotNullOrEmpty()]
            [System.String]$VM
        ,[Parameter(Mandatory=$true,HelpMessage="Destination Datastore")]
         [ValidateNotNullOrEmpty()]
            [System.String]$Datastore
    )

 Begin {
        #Nothing Necessary to process
 } #Begin

    Process {
        #Prepare Migration info, uses .NET API to specify a transformation to thin disk
        $vmView = Get-View -ViewType VirtualMachine -Filter @{"Name" = "$VM"}
        $dsView = Get-View -ViewType Datastore -Filter @{"Name" = "$Datastore"}

        #Abort Migration if free space on destination datastore is less than 50GB
        if (($dsView.info.freespace / 1GB) -lt 50) {throw "Move-ThinVM ERROR: Destination Datastore $Datastore has less than 50GB of free space. This script requires at least 50GB of free space for safety. Please free up space or use the VMWare Client to perform this Migration"}

        #Prepare VM Relocation Specificatoin
        $spec = New-Object VMware.Vim.VirtualMachineRelocateSpec
        $spec.datastore =  $dsView.MoRef
        $spec.transform = "sparse"

        #Perform Migration
        $vmView.RelocateVM($spec, $null)
    } #Process
}
########## 
Move-VMTemplate $vmName $dsName