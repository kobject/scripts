#Because Get-CMApplication takes pretty long. Otherwise use something like
#Get-Appsnames = Get-CMApplication
#Now you can use Get-Appsnames.LocalizedDisplayName
$csv = import-csv "PATH"

#Import SCCM Module
$smssitecode = "SCCMSITECODE"
Import-Module $env:SMS_ADMIN_UI_PATH.Replace("\bin\i386", "\bin\configurationmanager.psd1")
Set-Location "$($smssitecode):"

Function SetSourceUpdateProductCode{
    if ( $($app.name).StartsWith("XXX")) {
        $appname = Get-CMApplication -ApplicationName $($app.name)
        [xml]$xml = ($appname | Get-CMDeploymentType | select SDMPackageXML).SDMPackageXML
        $pc = $xml.ChildNodes.DeploymentType.Installer.CustomData.ProductCode
        $pca = $pc = $pc -replace "[{}]",""
        if (-not ([string]::IsNullOrEmpty($pc))){
            $getdepname = $appname | Get-CMDeploymentType
            $depname = $($getdepname.LocalizedDisplayName)
            Set-CMMsiDeploymentType -ApplicationName $($appname.LocalizedDisplayName) -DeploymentTypeName $depname -SourceUpdateProductCode $pc
            Write-Host "Source Update Product Code is gezet voor $($app.name)"
        }
        Else{
        Write-Host "No Productcode set $($app.name)"
        }
    }else{
    Write-Host "Error $($app.name), appname not started with XXX..."
    }
}


foreach($app in $csv){
    Try{
        SetSourceUpdateProductCode
    }Catch{
       Write-Host "An error occurred while exceuting script for $($app.name)"
    }
}
