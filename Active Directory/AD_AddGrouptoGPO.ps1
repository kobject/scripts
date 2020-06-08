$username = whoami.exe
$group = ""

$guids = get-gpo -all | where-object { $_.owner -eq $username } | select-object -ExpandProperty id

foreach ($guid in $guids) {
    Set-GPPermission -guid $guid -TargetName $group -TargetType Group -PermissionLevel GpoEditDeleteModifySecurity
    Set-GPPermission -guid $guid -TargetName $username -TargetType User -PermissionLevel None 
}
