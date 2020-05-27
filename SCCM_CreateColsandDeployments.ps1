$limitingcollection = "All Users"
$groups = import-csv c:\Temp\sccm_create_col.csv
$dpgroupname = "All DP's on-premises"
$smssitecode = "XX"


foreach ($adgroup in $groups){
    $groupname = $($adgroup.name)    
    $obj =  Get-ADGroup -LDAPFilter "(SAMAccountName=$groupname)"
    if($obj -eq $null){
    Write-Host -Foregroundcolor Yellow "Creating security group in Active Directory..."   
    New-ADGroup –name “$($adgroup.name)” –groupscope Global –path "AD CN PATH"
    }else{
    Write-Host -Foregroundcolor Yellow "Group already exists"  
    }
}

#Import SCCM Module
Import-Module $env:SMS_ADMIN_UI_PATH.Replace("\bin\i386", "\bin\configurationmanager.psd1")

#Connect to SCCM Remote uncomment this\
#$SCCMHost = "SSCCM FQDN"
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
            New-CMUserCollection -Name $($group.name) -LimitingCollectionName $limitingcollection -RefreshType Both | Out-Null
            Sleep 1
            Add-CMUserCollectionQueryMembershipRule -CollectionName $($group.name) -QueryExpression $Query -RuleName $($group.name) | Out-Null
            }
 
}

#Move collection to folder
foreach ($group in $groups){
   Write-Host -ForegroundColor Yellow "Move collection $($group.name) to MSI folder..."
   $destfolder = "$($smssitecode):\UserCollection\Applications\MSI"
   $collid =  Get-CMCollection -Name $($group.name)
   Move-CMObject -InputObject $collid -FolderPath $destfolder | Out-Null   
}

#Create deployment
foreach ($group in $groups){
    if(Get-CMApplicationDeployment -name $group.name.Substring(2)){
    Write-Host -Foregroundcolor Yellow "Deployment exists for $($group.name.Substring(2))"
    }
    Else{
    Write-Host -Foregroundcolor Yellow "Distribute content to All Distribution Points.."
    Start-CMContentDistribution -Applicationname $group.name.Substring(2) -DistributionPointGroupName $dpgroupname | Out-Null
    Write-Host -Foregroundcolor Yellow "Create Application Deployment for $($group.name)"
    New-CMApplicationDeployment -Collectionname $group.name -Name $group.name.Substring(2) -DeployAction Install -DeployPurpose Available -Usernotification DisplayAll -AvailableDateTime (get-date) -TimeBaseOn LocalTime | Out-Null
    }
}
