#Quick PowerShell

Rename all files in a directory
` Get-ChildItem | Rename-Item -NewName {$_.Name  -replace ".00t", "_ORIG.00t"} `