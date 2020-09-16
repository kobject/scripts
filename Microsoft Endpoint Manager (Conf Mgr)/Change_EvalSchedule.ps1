[CmdletBinding()]
Param(
    [parameter(Mandatory = $true, HelpMessage = "Enter sitecode of ConfigMgr server")] [string]$SMSProvider,
    [parameter(Mandatory = $false, HelpMessage = "Taskscheduler or Script (Default = Script)")] [string]$Type,
    [parameter(Mandatory = $true, HelpMessage = "Enter only the path. Logfile will be created with timestamp")] [string]$LogPath

)
if (!$Type) { $Type = 'Script' }

Function Get-SiteCode {
    $wqlQuery = 'SELECT * FROM SMS_ProviderLocation'
    $a = Get-WmiObject -Query $wqlQuery -Namespace 'root\sms' -ComputerName $SMSProvider
    $a | ForEach-Object {
        if ($_.ProviderForLocalSite) {
            $script:SiteCode = $_.SiteCode
        }
    }
    return $SiteCode
}

function Get-TimeStamp {
    return "[{0:MM/dd/yy} {0:HH:mm:ss}]" -f (Get-Date)
}

Function Convert-NormalDateToConfigMgrDate {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$starttime
    )
    return [System.Management.ManagementDateTimeconverter]::ToDMTFDateTime($starttime)
}

Function create-ScheduleToken {
    $SMS_ST_RecurInterval = "SMS_ST_RecurInterval"
    $class_SMS_ST_RecurInterval = [wmiclass]""
    $class_SMS_ST_RecurInterval.psbase.Path = "\\$($SMSProvider)\ROOT\SMS\Site_$($SiteCode):$($SMS_ST_RecurInterval)"
    $script:scheduleToken = $class_SMS_ST_RecurInterval.CreateInstance()
    if ($scheduleToken) {
        $scheduleToken.DayDuration = 0
        $scheduleToken.DaySpan = 0
        $scheduleToken.HourDuration = 0
        $scheduleToken.HourSpan = 4
        $scheduleToken.IsGMT = $false
        $scheduleToken.MinuteDuration = 0
        $scheduleToken.MinuteSpan = 0
        $scheduleToken.StartTime = (Convert-NormalDateToConfigMgrDate $startTime)
    }
}

[datetime]$startTime = [datetime]::Today
$SiteCode = Get-SiteCode
create-ScheduleToken


$Collections = Get-WmiObject -Class SMS_Collection -Namespace root\sms\site_$SiteCode
Write-Verbose "Getting "

If ($Type -eq 'Script') {
    foreach ($Collection in $Collections) {
        try {
            $Coll = Get-WmiObject -Class SMS_Collection -Namespace root\sms\site_$SiteCode -ComputerName $SMSProvider -Filter "CollectionID ='$($Collection.CollectionID)'"
            $Coll = [wmi]$Coll.__PATH
            $Coll.RefreshSchedule = $scheduletoken
            $Coll.RefreshType = 2
            $Coll.put() | Out-Null
            Write-Verbose "$(Get-TimeStamp) Successfully edited Collection $($Coll.Name)."
            Write-Output "$(Get-TimeStamp) Successfully edited Collection $($Coll.Name)." | Out-File $LogPath\$(Get-TimeStamp)-Change_Col_Eval_Script.log -Append
        }
        catch {
            Write-Verbose "$(Get-TimeStamp) $($Coll.Name) could not be edited."
        }
    }
}     

#Get all newly added Collections
If ($Type -eq 'TaskScheduler') {   
    foreach ($Collection in $Collections) {
        try {
            $Coll = Get-WmiObject -Class SMS_Collection -Namespace root\sms\site_P02 -ComputerName $SMSProvider -Filter "CollectionID ='$($Collection.CollectionID)' and RefreshType = '6'"
            $Coll = [wmi]$Coll.__PATH
            $Coll.RefreshSchedule = $scheduletoken
            $Coll.RefreshType = 2
            $Coll.put() | Out-Null
            Write-Verbose "$(Get-TimeStamp) Successfully edited Collection $($Coll.Name)."
            Write-Output "$(Get-TimeStamp) Successfully edited Collection $($Coll.Name)." | Out-File $LogPath\$(Get-TimeStamp)-Change_Col_Eval_TaskScheduler.log -Append
        }
        catch {
            Write-Verbose "$(Get-TimeStamp) $($Coll.Name) could not be edited."
        }
    }
}