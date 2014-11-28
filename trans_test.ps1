
# NAME: log
# AUTHOR: Derek Carter
# DATE: 26/11/2014
# COMMENTS: Outputs to console as
# well as to a log file. This helps with
# debugging.
function log($string,$log)
{
    Write-Host $string
    $enable = 1 # Enable logging: 1 Disable Logging: 0
    if($enable -eq 1)
    {
        $string | Out-File -Filepath $log -append
    }
}


#$logfile = 'C:\users\derek.carter\Documents\powershell\log2.txt'
$date = Get-Date
$date = $date.ToString('dd-MM-yy hh_mm_ss')
$filename = 'SYD-QA-WIN8-MB1' + " " + $date + "_log.txt"
$logfile = Join-Path $PSScriptRoot $filename


$sw = [Diagnostics.StopWatch]::StartNew()

log "Hello world how are you" $logfile 
log "Jump up jump up and get down" $logfile 
log $logfile $logfile 
$time = $sw.Elapsed.TotalSeconds
log "hello $time" $logfile 