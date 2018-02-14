Write-Host Importing StartLayout
Import-StartLayout -LayoutPath "$PSScriptRoot\20171211_Win10_Start_and_Taskbar_Layout.xml" -MountPath $env:SystemDrive\ -InformationVariable $importRes
Write-Host $importRes
Write-Host Copying Internet Explorer link to Start Menu
Copy-Item -Path "$PSScriptRoot\Internet Explorer.lnk" -Destination $env:SystemDrive'\ProgramData\Microsoft\Windows\Start Menu\Programs' -Force