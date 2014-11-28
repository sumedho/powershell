$proc="envis_gui.exe"
$proc > log.txt
"DATE,HANDLES,WS,VM,COMMITSIZE" >> log.txt
while($true)
{
    $myobj = Get-WmiObject win32_process | where {$_.Name -eq $proc}
    $handle = $myobj | select-object -expand Handles
    $VM = $myobj | select-object -expand VM
    $WS = $myobj | select-object -expand WS
    $PageFileUsage = $myobj | select-object -expand PageFileUsage

    $VM = $VM/1024
    $WS = $WS/1024
    
    [string][datetime]::now + "," + [string]$handle + "," + [string]$WS + "," + [string]$VM + "," + [string]$PageFileUsage >> log.txt
    #sleep -seconds 5
}