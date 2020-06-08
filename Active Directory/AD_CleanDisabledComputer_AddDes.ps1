#Logbestanden
$logdate = (Get-Date -format "dd-MM-yyy")
$logdir = ''
$succeslog_des = "$logdir\Succeslog_description " + $logdate + ".txt"
$errorlog_des = "$logdir\Errorlog_description " + $logdate + ".txt"
$succeslog_del = "$logdir\Succeslog_delete " + $logdate + ".txt"
$errorlog_del = "$logdir\Errorlog_delete " + $logdate + ".txt"

#Set datum voor description
$lastMonth = (get-date)
$firstDayOfLastMonth = get-date -year $lastMonth.Year -month $lastMonth.Month -day 1
$desdate = "{0:dd-MM-yyyy}" -f $firstDayOfLastMonth

#Datum voor filter
$zlastMonth = (get-date).AddMonths(+1)
$zfirstDayOfLastMonth = get-date -year $zlastMonth.Year -month $zlastMonth.Month -day 1
$zdesdate = "{0:dd-MM-yyyy}" -f $zfirstDayOfLastMonth

#Array
$cmplist = @()
$rmcmplist = @()

#Schoon array op als hij niet leeg is
If ($cmplist -ne $null) { clear-variable results }
If ($rmcmplist -ne $null) { clear-variable results }

#Zet computers in array
Get-ADComputer -Filter * -Properties * -Searchbase "ADD DN" | where { $_.Description -notlike "Object wordt verwijderd op $desdate" } | ForEach-Object { $cmplist += $_ } 
Get-ADComputer -Filter * -Properties * -Searchbase "ADD DN" | where { $_.Description -eq "Object wordt verwijderd op $desdate" } | ForEach-Object { $rmcmplist += $_ } 

#De functie om alle computers te voorzien van een description
Function Set-Description {
    Set-Adcomputer $cmp.name -description "Object wordt verwijderd op $zdesdate" 
    "Description succesvol toegevoegd aan $($cmp.name) op $logdate" | add-content $succeslog_des
}

#De functie om computers te verwijderen
Function Remove-Computers {
    Remove-ADObject $rmcmp.DistinguishedName -Recursive -Confirm:$false
    "De machine $($rmcmp.name) is succesvol verwijderd" | add-content $succeslog_del
}

#Loops om de functie te starten + foutmeldingen op te vangen.
Foreach ($rmcmp in $rmcmplist) {
    Try {
        Remove-Computers
    }
    Catch {
        "Error bij het verwijdern van $($rmcmp.name)" | add-content $errorlog_del
    }
}     


#Loops om de functie te starten + foutmeldingen op te vangen.
Foreach ($cmp in $cmplist) {
    Try {
        Set-Description
    }
    Catch {
        "Error bij aanpassen van de description bij $($cmp.name)" | add-content $errorlog_des
    }
}



