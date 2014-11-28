$MachinesToUse = "SYD-QA-WIN8-MB1 SYD-QA-WIN8-MB1"
$buildLocation = "\\10.2.128.12\Vulcan-Build\Weekly\Mainline\zip-installshieldMSI_vulcan-v100-b141120-1265-x64-3eea9b58_AutoIS.7z"


$AutomationMachines = @($MachinesToUse.split())
$configuration = ""

#Extract only the build name from the build path
$splitPath = $buildLocation.replace('/','\')
$splitPath = $splitPath.split('\')
$buildName = $splitPath[$splitPath.length-1]
$splitName = $buildName.split('-')
$containsVUL = 0

echo $splitPath
echo $splitName
echo $buildName



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

#echo $configuration
