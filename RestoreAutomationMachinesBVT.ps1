#Build Verification Test
#.\RestoreAutomationMachinesBVT.ps1 -MachinesToUse "SYD-QA-WIN8-MB1" -listSelected "TEST" -buildLocation "\\10.2.128.12\Vulcan-Build\Weekly\Mainline\zip-installshieldMSI_vulcan-v100-b141120-1265-x64-3eea9b58_AutoIS.7z" -autoID "0" 
param(
	[string]$MachinesToUse,
	[string]$listSelected,
	[string]$buildLocation,
	[string]$autoID
)

#$HostMachine = "SYD-QA-CybrCtrl" # The Sydney Controller
$HostMachine = [System.Net.Dns]::GetHostName() # get host machine controller name automatically
$server = "SYD-VC-SERVER" # The Sydney VI server

$AutomationMachines = @($MachinesToUse.split())
$configuration = ""

#Extract only the build name from the build path
$splitPath = $buildLocation.replace('/','\')
$splitPath = $splitPath.split('\')
$buildName = $splitPath[$splitPath.length-1]
$splitName = $buildName.split('-')
$containsVUL = 0

##Check for maintenance and any other branch build
for($i = 0; $i -lt $splitName.length; $i++)
{
	if($splitName[$i].Contains("VUL"))
	{
		$containsVUL = 1
		if($splitName[$i+1].Contains("24000"))
		{
			$configuration = "Maintenance"
		}
		else
		{
			$code = $splitName[$i+1]	
			$configuration = "VUL$code"
			break
		}
	}
}

#Check for mainline
if ($containsVUL -eq 0)
{
	$configuration = "Mainline"
}

#Check for RC
if ($buildName.Contains("RC"))
{
	$pos = $buildName.indexof("RC")
	if($buildName[$pos+2] -match '[0-9]')
	{
		$configuration = "RC"+$buildName[$pos+2]
	}
	else
	{
		$configuration = "RC"
	}
}

#Add the Vulcan architecture
if ($buildName.Contains("x86") -or $buildName.Contains("32-bit") -or $buildName.Contains("32bit"))
{
	$configuration = $configuration + "-32"
}
else
{
	$configuration = $configuration + "-64"
}


echo ""
echo "Automation Machines: $AutomationMachines"
echo "Test list: $listSelected"
echo "Build URL: $buildLocation"
echo "Build ID: $configuration"
echo ""


#Stop an error from occurring when a transcript is already stopped
$ErrorActionPreference="SilentlyContinue"
Stop-Transcript | out-null

#Reset the error level before starting the transcript
$ErrorActionPreference="Continue"
#Start-Transcript -path C:\temp\Shutdown_NonProductionVMs.log -append 

if ( (Get-PSSnapin -Name VMware.VimAutomation.Core -ErrorAction SilentlyContinue) -eq $null )
{
    Add-PSSnapin VMware.VimAutomation.Core
}

#Get the Credentials
$creds = Get-VICredentialStoreItem -file .\newcreds.creds

# Connect to the VI server
Connect-VIServer -Server $server -User $creds.User -Password $creds.Password

#Revert the Automation machines
foreach ($Machine in $AutomationMachines)
{
	
	$vm = Get-VM $Machine.toLower()
	echo $Machine
	echo ***********************************************************************************************************
	$vm
	echo ***********************************************************************************************************
	set-vm -snapshot(get-snapshot -NAME "1" -VM $vm) -VM $vm -confirm:$false
	Start-VM $vm
	echo ***********************************************************************************************************
}


echo "Automation machines being used for $configuration :"
echo $AutomationMachines

#Path should be changed to correct location of branch builds once we know it.
if(Test-Path $buildLocation)
{
	$VulcanBranch = get-item $buildLocation
	echo $VulcanBranch
}
else
{
	"Warning: the build path does not exist."
	Exit
}


#Copy Setup items
$fromscripts = "\\"+$HostMachine+"\c$\qa_test\AutomatedTesting\CshScripts"
foreach ($Machine in $AutomationMachines)
{
	$toinstall = "\\"+$Machine+"\c$\vulcan_installs"
	echo "our install folder is"  + $toinstall
	$toscripts = "\\"+$Machine+"\c$\datasets\scripts"
	
	#Not every machine has these, so we need to add them.
	$toMachine = $toInstall+"\\tomachine"
	$toVulcanApi = $toInstall+"\\VulcanApi"	
    #$toMachineSource = "\\"+$HostMachine+"\\Batch\\ToMachine"
    $toMachineSource = "\\"+$HostMachine + "\c$\qa_test\MiscellaneousTools\TestController\Exe\Batch\ToMachine"
	$VulcanApiSource = "\\"+$HostMachine+"\\VulcanAPI"
	#$AutoSetupDaily = "\\"+$HostMachine+"\\Batch\\AutoSetupDaily.bat"
    $AutoSetupDaily = "\\"+$HostMachine + "\c$\qa_test\MiscellaneousTools\TestController\Exe\Batch\AutoSetupDaily.bat"
	
	
	#Some machines may have a folder named cshscripts, so if so, let's rename that so we don't have to copy as much
	$toscriptsOldName = "\\"+$Machine+"\c$\datasets\cshscripts"
	if ((Test-Path $toscriptsOldName)) 
	{
		[void](rename-item -path $toscriptsOldName -newname $toscripts)
	}
     
	#Create the folder for the installs, so we don't get screwed later
    if (!(Test-Path $toinstall )) 
	{
		[void](new-item $toinstall  -itemType directory)
	}
            	 
	#Robocopy will wait until machine is ready
	RoboCopy $fromscripts $toscripts *.* /E /S /Mt:2 /R:5 /W:20
	RoboCopy $toMachineSource $toMachine *.* /E /S /Mt:2 /R:5 /W:20
	#RoboCopy $VulcanApiSource $toVulcanApi *.* /E /S /Mt:2 /R:5 /W:20
	copy $AutoSetupDaily $toinstall
}

$32 = @()
$64 = @()
#Tag:copyInstalls
#Copy the correct install to each machine

if($buildLocation.ToLower().Contains("x86"))
{
	$32 += $AutomationMachines
}
else
{
	$64 += $AutomationMachines
}
		
$build = $VulcanBranch
foreach($Machine in $AutomationMachines)
{
	$toinstall = "\\"+$Machine+"\c$\vulcan_installs"
	cpi $build $toinstall
}

$64installerPath = "C:\vulcan_installs\vulcan\setup.exe"
$32installerPath = "C:\vulcan_installs\vulcan\setup.exe"

& .\setupRemoteInstaller.ps1 $64 $32 $64installerPath $32installerPath
echo "installing Vulcan"

$guid = [guid]::NewGuid()
Get-Date -f yyyy-MM-dd_H:m >> .\logs\$guid+RemoteTestRunnerOutput.log
& .\RemoteTestRunner.exe >> .\logs\$guid+RemoteTestRunnerOutput.log
echo "remote test runner started"

#Checks for Vulcan install in each machine and removes machines from array if Vulcan is not installed
$tempAutomationMachines = @()
foreach($Machine in $AutomationMachines)
{
	$isInstalled = "\\"+$Machine+"\c$\Program Files*\Maptek\Vulcan*\bin\exe\vlauncher.exe"	
	if(Test-Path $isInstalled)
	{
		echo $Machine
		$tempAutomationMachines += $Machine
	}
	else
	{
		echo "$Machine does not have Vulcan installed."
	}
}
$AutomationMachines = $tempAutomationMachines


#Setting up the machine properties 
#& .\CreateTestSettings.ps1 $configuration $autoID This is now in this script Commit left for reference.
if ($configuration.Contains("32"))
{
    $VulcanArchitecture = "32"
}
else
{
    $VulcanArchitecture = "64"
}

#Updating the settings file
$testsettingsName = $HostMachine + "_" + $configuration + "onWin7-64"
$fileName = "C:\qa_test\CSharpTests\remotewin8-64.testsettings"
$updatedfileName = "C:\qa_test\CSharpTests\" + $testsettingsName + ".testsettings"


#Update the autoid value
$toReplace = '<AgentProperty name="build" value=".+" />'
$replaceWith = "<AgentProperty name=`"autoid`" value=`"$autoID`" />"
$lines = (Get-Content $fileName) | foreach-object {$_ -replace $toReplace, $replaceWith} | Set-Content $updatedfileName

#Update the naming scheme for test results within the general settings
$toReplace = '<NamingScheme baseName="RemoteWin7-64-lab11Branch"'
$replaceWith = "<NamingScheme baseName=`"$testsettingsName`""
$lines = (Get-Content $updatedfileName) | foreach-object {$_ -replace $toReplace, $replaceWith} | Set-Content $updatedfileName
 
#Update the Vulcan architecture
$toReplace = '<AgentProperty name="Vulcan Architecture" value=".+" />'
$replaceWith = "<AgentProperty name=`"Vulcan Architecture`" value=`"$VulcanArchitecture`" />"
$lines = (Get-Content $updatedfileName) | foreach-object {$_ -replace $toReplace, $replaceWith} | Set-Content $updatedfileName

echo "Test settings have been created"
Start-Sleep -Seconds 130

foreach ($Machine in $AutomationMachines)
{
	$vm = Get-VM $Machine
	Restart-VM $vm -confirm:$false
	echo "Restarting $Machine"
}
Disconnect-VIServer -confirm:$false
Start-Sleep -Seconds 600 #Changed sleep to 60secs for testing

#& E:\testresults\RunCSharpsBVT.ps1 $configuration $listSelected This is now in this script Commit left for reference.

$jobs = @()				
$dir = "C:\qa_test\CSharpTests\"	
$pwd = (Get-Item -Path ".\" -Verbose).FullName
$testsettings = $HostMachine + "_" + $configuration + "onWin7-64.testsettings"
echo =================================================================================
echo =================================================================================
echo $testsettings
echo =================================================================================

echo $pwd

echo =================================================================================
echo $((get-location).path)
echo =============================================================================
#$cmd = "$pwd\setloaction.ps1 -ArgumentList $pwd"
echo $cmd
echo $dir$testsettings
echo $listSelected
#$jobs += Start-Job -Init ([ScriptBlock]::Create("Set-Location $pwd")) -FilePath .\RunTestsBVT.ps1 -ArgumentList $dir$testsettings, $listSelected

#echo 'All jobs started.'

#Get-Date -f yyyy-MM-dd_H:m >> $pwd\log.txt
 
#foreach($job in $jobs)
#{
#	Wait-Job $job
#	"**************" >> $pwd\log.txt
#	"**************" >> $pwd\log.txt
#	Receive-Job $Job >> $pwd\log.txt
#}

.\RunTestsBVT.ps1 -setting $dir$testsettings -listSelected $listSelected






Remove-Item -path $dir$testsettings
#Copy-item -path 'E:\testresults\TestResults\*.trx' -destination  "\\win7-64-sql\C$\TestResults\ImportFromHereTrx\"

echo "end RestoreAutomationMachinesBVT.ps1"