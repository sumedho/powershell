#Quick PowerShell

Rename all files in a directory
```
Get-ChildItem | Rename-Item -NewName {$_.Name  -replace ".00t", "_ORIG.00t"} 
```

Get files in dir and export to csv
```
Get-ChildItem | Select-Object {$_.Name} | Export-Csv -Path "D:\vulcan_data\VUL8233\names.csv"
```