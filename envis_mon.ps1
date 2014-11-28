$proc="envis_gui"
$proc > log.txt
"TIME | HANDLES | CPU | WORKING | PRIVATE" >> log.txt
while($true)
{
    ps -ea 0 $proc | %{"$([datetime]::now) | $($_.Handles) | $($_.cpu) | $($_.WS) | $($_.PM)" >> log.txt}
    sleep -seconds 5
}