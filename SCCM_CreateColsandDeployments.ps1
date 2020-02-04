$smssitecode = "SMSSITECODE"
$limitingcollection = "All Users"
$groups = import-csv FILEPATH 
$dpgroupname = "DPGROUPNAME"

#Sitecode
$smssitecode = "OT1"

#Import SCCM Module
Import-Module $env:SMS_ADMIN_UI_PATH.Replace("\bin\i386", "\bin\configurationmanager.psd1")

#Connect to SCCM Remote uncomment this
#$SCCMHost = "SCCMSERVERFQDN"
#if((Get-PSDrive -Name $smssitecode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
#   New-PSDrive -Name $smssitecode -PSProvider CMSite -Root $SCCMHost}

Set-Location "$($smssitecode):"

#Create collection
foreach ($group in $groups){
      if (Get-CMUserCollection -name $($group.name)){
      Write-Host -Foregroundcolor Yellow "Usercollection $($group.name) already exists..."        
      }
         Else
       {
            Write-Host -Foregroundcolor Yellow "Create new User Collection $($group.name)"
            $querygroup = "DOMAIN\\"+"$($group.name)"
            $Query = "select SMS_R_USER.ResourceID,SMS_R_USER.ResourceType,SMS_R_USER.Name,SMS_R_USER.UniqueUserName,SMS_R_USER.WindowsNTDomain from SMS_R_User where SMS_R_User.SecurityGroupName = `"$querygroup`""
            New-CMUserCollection -Name $($group.name) -LimitingCollectionName $limitingcollection
            Sleep 1
            Add-CMUserCollectionQueryMembershipRule -CollectionName $($group.name) -QueryExpression $Query -RuleName $($group.name)
            }
 
}

#Move collection to folder
foreach ($group in $groups){
   Write-Host -ForegroundColor Yellow "Move collection $($group.name) to MSI folder..."
   $destfolder = "$($smssitecode):\UserCollection\Application\MSI"
   $collid =  Get-CMCollection -Name $($group.name)
   Move-CMObject -InputObject $collid -FolderPath $destfolder    
}

#Create deployment
foreach ($group in $groups){
    if(Get-CMApplicationDeployment -name $group.name.Substring(2)){
    Write-Host -Foregroundcolor Yellow "Deployment exists for $($group.name.Substring(2))"
    }
    Else{
    Write-Host -Foregroundcolor Yellow "Distribute content to All Distribution Points.."
    Start-CMContentDistribution -Applicationname $group.name.Substring(2) -DistributionPointGroupName $dpgroupname
    Write-Host -Foregroundcolor Yellow "Create Application Deployment for $($group.name)"
    New-CMApplicationDeployment -Collectionname $group.name -Name $group.name.Substring(2) -DeployAction Install -DeployPurpose Available -Usernotification DisplayAll -AvailableDateTime (get-date) -TimeBaseOn LocalTime
    }
}

