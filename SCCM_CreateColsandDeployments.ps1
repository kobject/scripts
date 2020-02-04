$LimitingCollections = "All Users"
$groups = import-csv FILEPATH 


#Maak groepen
foreach ($Group in $groups){
      if (Get-CMUserCollection -name $($Group.name)){
      Write-Host -Foregroundcolor Yellow "Usercollection $($Group.name) already exists..."        
      }
         Else
       {
            Write-Host -Foregroundcolor Yellow "Create new User Collection $($Group.name)"
            $QueryGroup = "DOMAIN\\"+"$($Group.name)"
            $Query = "select SMS_R_USER.ResourceID,SMS_R_USER.ResourceType,SMS_R_USER.Name,SMS_R_USER.UniqueUserName,SMS_R_USER.WindowsNTDomain from SMS_R_User where SMS_R_User.SecurityGroupName = `"$QueryGroup`""
            New-CMUserCollection -Name $($Group.name) -LimitingCollectionName $LimitingCollections
            Sleep 1
            Add-CMUserCollectionQueryMembershipRule -CollectionName $($Group.name) -QueryExpression $Query -RuleName $($Group.name)
            }
 
}

#Verplaatst de Collection naar folder
foreach ($Group in $groups){
   Write-Host -ForegroundColor Yellow "Move collection $($Group.name) to MSI folder..."
   $destfolder = "<SMSSITECODE>:\UserCollection\Application\MSI"
   $collid =  Get-CMCollection -Name $($Group.name)
   Move-CMObject -InputObject $collid -FolderPath $destfolder    
}

#Maak Deployment
foreach ($Group in $groups){
    if(Get-CMApplicationDeployment -name $Group.name.Substring(2)){
    Write-Host -Foregroundcolor Yellow "Deployment exists for $($Group.name.Substring(2))"
    }
    Else{
    Write-Host -Foregroundcolor Yellow "Distribute content to All Distribution Points.."
    Start-CMContentDistribution -Applicationname $Group.name.Substring(2) -DistributionPointGroupName "All Distribution Points"
    Write-Host -Foregroundcolor Yellow "Create Application Deployment for $($Group.name)"
    New-CMApplicationDeployment -Collectionname $Group.name -Name $Group.name.Substring(2) -DeployAction Install -DeployPurpose Available -Usernotification DisplayAll -AvailableDateTime (get-date) -TimeBaseOn LocalTime
    }
}

