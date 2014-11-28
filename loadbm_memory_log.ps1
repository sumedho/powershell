# name: ReadSocketReturn
# info: Get message from stream
# author: Derek Carter 23/10/2014
# inputs: stream object
# return: message
function ReadSocketReturn ($stream) 
{ 
    if($stream.CanRead)
    {
        $outputBuffer = "" #create empty output buffer
        $encoding = new-object System.Text.AsciiEncoding #set encoding to ascii
        $buffer = new-object System.Byte[] 1024 # create a 1024 byte buffer
        
        # Keep reading while data is available
        do
        {
            $read = $ns.Read($buffer, 0, 1024)
            $outputBuffer += ($encoding.GetString($buffer, 0, $read))
        }
        while($stream.DataAvailable)
        $outputBuffer 
    }
}



function CallLavaScript
{
    # Get WMI envis process
    $cm_line_obj = Get-WmiObject win32_process | Where-object {$_.Caption -Contains "envis_gui.exe"} | Select-object Commandline

    # Split on "=" to get socket string
    $st1 = $cm_line_obj.Commandline -split "="

    # Get socket number and convert to int
    $socket_id = [int]$st1[1].Substring(0,5)
    $socket_id

    $sfv = New-Object System.Net.Sockets.TcpClient("localhost", $socket_id)

    if(!$sfv.Connected)
    {
        Write-Host "Failed to locally connect to port"
    }

    $lava_command = "loadbm.lava"

    $ns = $sfv.GetStream()
    $sw = new-object System.IO.StreamWriter($ns);
    $sw.AutoFlush = 1

    # Enable sending of telnet commands
    $sw.Write("t")

    # Check if can write

    $msg = ReadSocketReturn $ns # Call getoutput function

    # Check if return from Envisage is OK using REGEX
    if($msg -match "OK")
    {
        # construct the command to launch lava
        $command =  "LAUNCH:" + $lava_command + [char]10 # [char]10 is equal to newline char

        # Send command 
        $sw.WriteLine($command)
    }


    # Close socket
    $sfv.Close()
}

CallLavaScript

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


#write-host "does this come out now?"

