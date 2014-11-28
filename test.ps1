$proc = "envis_gui.exe"
"HANDLES,WS,VM,COMMITSIZE"
$myobj = Get-WmiObject win32_process | where {$_.Name -eq $proc}
$handle = $myobj | select-object -expand Handles
$VM = $myobj | select-object -expand VM
$WS = $myobj | select-object -expand WS
$PageFileUsage = $myobj | select-object -expand PageFileUsage

$VM = $VM/1024
$WS = $WS/1024
    
[string]$handle + "," + [string]$WS + "," + [string]$VM + "," + [string]$PageFileUsage
