#Set vars 
$date = (Get-Date -format "dd-MM-yyy HH:mm")
$runninguser = $env:username
$result = "$logdir\Results.csv"
$csv = Import-Csv "" -Header IP1
$intunegroup = 'G-UG-IntuneCloudOnlyUsers'

#Logs
$logdir = ''
$addedusers = "$logdir\addedusers.txt"
$err_addedusers = "$logdir\Error_addedusers.txt"


Function adduserstogroup {
    Add-ADGroupMember -Identity $intunegroup -members $user.IP1
    "$($user.IP1) succesvol toegevoegd aan $intunegroup door $runninguser op $date" | add-content $addedusers
}


foreach ($user in $csv) {
    Try {
        adduserstogroup
    }
    Catch {
        "Error bij het toevoegen van $($user.IP1) aan $intunegroup" | add-content $err_addedusers
    }
}
