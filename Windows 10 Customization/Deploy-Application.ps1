<#
.SYNOPSIS
	This script performs the installation or uninstallation of an application(s).
.DESCRIPTION
	The script is provided as a template to perform an install or uninstall of an application(s).
	The script either performs an "Install" deployment type or an "Uninstall" deployment type.
	The install deployment type is broken down into 3 main sections/phases: Pre-Install, Install, and Post-Install.
	The script dot-sources the AppDeployToolkitMain.ps1 script which contains the logic and functions required to install or uninstall an application.
.PARAMETER DeploymentType
	The type of deployment to perform. Default is: Install.
.PARAMETER DeployMode
	Specifies whether the installation should be run in Interactive, Silent, or NonInteractive mode. Default is: Interactive. Options: Interactive = Shows dialogs, Silent = No dialogs, NonInteractive = Very silent, i.e. no blocking apps. NonInteractive mode is automatically set if it is detected that the process is not user interactive.
.PARAMETER AllowRebootPassThru
	Allows the 3010 return code (requires restart) to be passed back to the parent process (e.g. SCCM) if detected from an installation. If 3010 is passed back to SCCM, a reboot prompt will be triggered.
.PARAMETER TerminalServerMode
	Changes to "user install mode" and back to "user execute mode" for installing/uninstalling applications for Remote Destkop Session Hosts/Citrix servers.
.PARAMETER DisableLogging
	Disables logging to file for the script. Default is: $false.
.EXAMPLE
    powershell.exe -Command "& { & '.\Deploy-Application.ps1' -DeployMode 'Silent'; Exit $LastExitCode }"
.EXAMPLE
    powershell.exe -Command "& { & '.\Deploy-Application.ps1' -AllowRebootPassThru; Exit $LastExitCode }"
.EXAMPLE
    powershell.exe -Command "& { & '.\Deploy-Application.ps1' -DeploymentType 'Uninstall'; Exit $LastExitCode }"
.EXAMPLE
    Deploy-Application.exe -DeploymentType "Install" -DeployMode "Silent"
.NOTES
	Toolkit Exit Code Ranges:
	60000 - 68999: Reserved for built-in exit codes in Deploy-Application.ps1, Deploy-Application.exe, and AppDeployToolkitMain.ps1
	69000 - 69999: Recommended for user customized exit codes in Deploy-Application.ps1
	70000 - 79999: Recommended for user customized exit codes in AppDeployToolkitExtensions.ps1
.LINK 
	http://psappdeploytoolkit.com
#>
[CmdletBinding()]
Param (
	[Parameter(Mandatory=$false)]
	[ValidateSet('Install','Uninstall')]
	[string]$DeploymentType = 'Install',
	[Parameter(Mandatory=$false)]
	[ValidateSet('Interactive','Silent','NonInteractive')]
	[string]$DeployMode = 'Interactive',
	[Parameter(Mandatory=$false)]
	[switch]$AllowRebootPassThru = $false,
	[Parameter(Mandatory=$false)]
	[switch]$TerminalServerMode = $false,
	[Parameter(Mandatory=$false)]
	[switch]$DisableLogging = $false
)

Try {
	## Set the script execution policy for this process
	Try { Set-ExecutionPolicy -ExecutionPolicy 'ByPass' -Scope 'Process' -Force -ErrorAction 'Stop' } Catch {}
	
	##*===============================================
	##* VARIABLE DECLARATION
	##*===============================================
	## Variables: Application
	[string]$appVendor = 'BCIU'
	[string]$appName = 'Windows 10 Build Config'
	[string]$appVersion = '1.0'
	[string]$appArch = 'x86/x64'
	[string]$appLang = 'EN'
	[string]$appRevision = '02'
	[string]$appScriptVersion = '1.0.1'
	[string]$appScriptDate = '20151019'
	[string]$appScriptAuthor = 'Dan Lezoche'
	##*===============================================
	## Variables: Install Titles (Only set here to override defaults set by the toolkit)
	[string]$installName = ''
	[string]$installTitle = ''
	
	##* Do not modify section below
	#region DoNotModify
	
	## Variables: Exit Code
	[int32]$mainExitCode = 0
	
	## Variables: Script
	[string]$deployAppScriptFriendlyName = 'Deploy Application'
	[version]$deployAppScriptVersion = [version]'3.6.9'
	[string]$deployAppScriptDate = '02/12/2017'
	[hashtable]$deployAppScriptParameters = $psBoundParameters
	
	## Variables: Environment
	If (Test-Path -LiteralPath 'variable:HostInvocation') { $InvocationInfo = $HostInvocation } Else { $InvocationInfo = $MyInvocation }
	[string]$scriptDirectory = Split-Path -Path $InvocationInfo.MyCommand.Definition -Parent
	
	## Dot source the required App Deploy Toolkit Functions
	Try {
		[string]$moduleAppDeployToolkitMain = "$scriptDirectory\AppDeployToolkit\AppDeployToolkitMain.ps1"
		If (-not (Test-Path -LiteralPath $moduleAppDeployToolkitMain -PathType 'Leaf')) { Throw "Module does not exist at the specified location [$moduleAppDeployToolkitMain]." }
		If ($DisableLogging) { . $moduleAppDeployToolkitMain -DisableLogging } Else { . $moduleAppDeployToolkitMain }
	}
	Catch {
		If ($mainExitCode -eq 0){ [int32]$mainExitCode = 60008 }
		Write-Error -Message "Module [$moduleAppDeployToolkitMain] failed to load: `n$($_.Exception.Message)`n `n$($_.InvocationInfo.PositionMessage)" -ErrorAction 'Continue'
		## Exit the script, returning the exit code to SCCM
		If (Test-Path -LiteralPath 'variable:HostInvocation') { $script:ExitCode = $mainExitCode; Exit } Else { Exit $mainExitCode }
	}
	
	#endregion
	##* Do not modify section above
	##*===============================================
	##* END VARIABLE DECLARATION
	##*===============================================
		
	If ($deploymentType -ine 'Uninstall') {
		##*===============================================
		##* PRE-INSTALLATION
		##*===============================================
		[string]$installPhase = 'Pre-Installation'
		
		## Show Welcome Message, close Internet Explorer if required, allow up to 3 deferrals, verify there is enough disk space to complete the install, and persist the prompt
		Show-InstallationWelcome -CloseApps 'iexplore' -AllowDefer -DeferTimes 3 -CheckDiskSpace -PersistPrompt
		
		## Show Progress Message (with the default message)
		Show-InstallationProgress
		
		## <Perform Pre-Installation tasks here>
		
		
		##*===============================================
		##* INSTALLATION 
		##*===============================================
		[string]$installPhase = 'Installation'
		
		## Handle Zero-Config MSI Installations
		If ($useDefaultMsi) {
			[hashtable]$ExecuteDefaultMSISplat =  @{ Action = 'Install'; Path = $defaultMsiFile }; If ($defaultMstFile) { $ExecuteDefaultMSISplat.Add('Transform', $defaultMstFile) }
			Execute-MSI @ExecuteDefaultMSISplat; If ($defaultMspFiles) { $defaultMspFiles | ForEach-Object { Execute-MSI -Action 'Patch' -Path $_ } }
		}
		
		## <Perform Installation tasks here>
		Write-Log -Message "Setting up Environment"
        #Enable RDP 
        Set-RegistryKey -Key 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server' -Name 'fDenyTSConnections' -Value 0 -Type DWord
        #Configure RDP Auth (No NLA)
        Set-RegistryKey -Key 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name UserAuthentication -Value 0 -Type DWord
        #Enable Remote Registry
        Set-ServiceStartMode -Name 'remoteregistry' -StartMode Automatic
        Start-ServiceAndDependencies -name 'remoteregistry'
        #Show File Extension
        Set-RegistryKey -Key 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\Folder\HideFileExt' -Name DefaultValue -Value 0 -Type DWord
        #Disable Wifi-Sense
        Set-RegistryKey -Key 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\config' -Name AutoConnectAllowedOEM -Value 0 -Type DWord
        #Set PowerShell Execution Policy
        Set-RegistryKey -Key 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\PowerShell' -Name EnableScripts -Value 1 -Type DWord
        Set-RegistryKey -Key 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\PowerShell' -Name ExecutionPolicy -Value Unrestricted -Type String
        
        Write-Log -Message "Setting up Firewall"
        Set-NetFirewallRule -DisplayGroup "File and Printer Sharing" -Enabled True
        Set-NetFirewallRule -DisplayGroup "Windows Remote management" -Enabled True
        Set-NetFirewallRule -DisplayGroup "Windows Management Instrumentation (WMI)" -Enabled True
        Set-NetFirewallRule -DisplayGroup "Network Discovery" -Enabled True

        Write-Log -Message "Setting up Background"
        TAKEOWN /F "$env:systemroot\Web\Wallpaper\Windows\img0.jpg"
        ICACLS "$env:systemroot\Web\Wallpaper\Windows\img0.jpg" /reset
        Rename-Item -Path "$env:systemroot\Web\Wallpaper\Windows\img0.jpg" -NewName imgX.jpg -Confirm:$False -Force
        Copy-File -Path "$dirSupportFiles\BCIU-Win10-Background.jpg" -Destination "$env:systemroot\Web\Wallpaper\Windows\img0.jpg"
        
        Write-Log -Message "Setting up User Tiles"
        Rename-Item -Path "$env:ALLUSERSPROFILE\Microsoft\User Account Pictures\user.bmp" -NewName userX.bmp -Confirm:$False -Force
        Rename-Item -Path "$env:ALLUSERSPROFILE\Microsoft\User Account Pictures\user.png" -NewName userX.png -Confirm:$False -Force
        Rename-Item -Path "$env:ALLUSERSPROFILE\Microsoft\User Account Pictures\user-32.png" -NewName userX-32.png -Confirm:$False -Force
        Rename-Item -Path "$env:ALLUSERSPROFILE\Microsoft\User Account Pictures\user-40.png" -NewName userX-40.png -Confirm:$False -Force
        Rename-Item -Path "$env:ALLUSERSPROFILE\Microsoft\User Account Pictures\user-48.png" -NewName userX-48.png -Confirm:$False -Force
        Rename-Item -Path "$env:ALLUSERSPROFILE\Microsoft\User Account Pictures\user-192.png" -NewName userX-192.png -Confirm:$False -Force
        Copy-File -Path "$dirSupportFiles\Win10_UserTiles.bmp" -Destination "$env:ALLUSERSPROFILE\Microsoft\User Account Pictures\user.bmp"
        Copy-File -Path "$dirSupportFiles\Win10_UserTiles.png" -Destination "$env:ALLUSERSPROFILE\Microsoft\User Account Pictures\user.png"
        Copy-File -Path "$dirSupportFiles\Win10_UserTiles-32.png" -Destination "$env:ALLUSERSPROFILE\Microsoft\User Account Pictures\user-32.png"
        Copy-File -Path "$dirSupportFiles\Win10_UserTiles-40.png" -Destination "$env:ALLUSERSPROFILE\Microsoft\User Account Pictures\user-40.png"
        Copy-File -Path "$dirSupportFiles\Win10_UserTiles-48.png" -Destination "$env:ALLUSERSPROFILE\Microsoft\User Account Pictures\user-48.png"
        Copy-File -Path "$dirSupportFiles\Win10_UserTiles-192.png" -Destination "$env:ALLUSERSPROFILE\Microsoft\User Account Pictures\user-192.png"

        Write-Log -Message "Setting up Power Profile"
        powercfg -setactive 381b4222-f694-41f0-9685-ff5bb260df2e
        powercfg -change -monitor-timeout-ac 30
        powercfg -change -disk-timeout-ac 0
        powercfg -change -standby-timeout-ac 0
        powercfg -change -hibernate-timeout-ac 0
        powercfg -change -hibernate-timeout-dc 60
        #update balanced power profile lid close action on AC power to do nothing
        powercfg -setACValueIndex 381b4222-f694-41f0-9685-ff5bb260df2e 4f971e89-eebd-4455-a8de-9e59040e7347 5ca83367-6e45-459f-a27b-476b1d01c936 0
        
        Write-Log -message "Setting up Default Theme"
        Copy-File -Path "$dirSupportFiles\BCIU22_Wi" -Destination "C:\Users\Default\AppData\Local\Microsoft\Windows\Themes" -Recurse
        
        Write-Log -Message "Setting up Default Profile"
        [ScriptBlock]$HKCURegistrySettings = {
            #Show File Extensions
			Set-RegistryKey -SID $UserProfile.SID -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name HideFileExt -Type DWord -Value 0 
			#Lock the Taskbar
            Set-RegistryKey -SID $UserProfile.SID -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name TaskbarSizeMove -Type DWord -Value 0  
			#Enable Desktop Preview
            Set-RegistryKey -SID $UserProfile.SID -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name DisablePreviewDesktop -Type DWord -Value 0  
			#Show Normal Taskbar Icons
            Set-RegistryKey -SID $UserProfile.SID -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name TaskbarSmallIcons -Type DWord -Value 0  
			#Group Taskbar Items
            Set-RegistryKey -SID $UserProfile.SID -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name TaskbarGlomLevel -Type DWord -Value 0
			#Enable PowerShell on Win+X Menu
            Set-RegistryKey -SID $UserProfile.SID -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name DontUsePowerShellOnWinX -Type DWord -value 0
            #Launch Explorer to 'My Computer' Instead of Quick Access (2)
            Set-RegistryKey -SID $UserProfile.SID -Key "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name LaunchTo -Type DWord -value 1
			#Show All Tray Items
            Set-RegistryKey -SID $UserProfile.SID -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer" -Name EnableAutoTray -Type Dword -Value 0 
			#Set Default Start Menu Colors
            Set-RegistryKey -SID $UserProfile.SID -Key "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Accent" -Name AccentPalette -Type Binary -Value CCCCCC00AEAEAE0092929200767676004F4F4F003737370026262600D1343800
			Set-RegistryKey -SID $UserProfile.SID -Key "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Accent" -Name StartColorMenu -Type DWord -Value 0xff4f4f4f
			Set-RegistryKey -SID $UserProfile.SID -Key "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Accent" -Name AccentColorMenu -Type DWord -Value 0xff767676  
			#Use Search Button Instead of Box (2) or Disable (0)
            Set-RegistryKey -SID $UserProfile.SID -Key "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name SearchboxTaskbarMode -Type DWord -Value 1
            #Set Screen Saver Defaults
            Set-RegistryKey -SID $UserProfile.SID -Key "HKCU\Control Panel\Desktop" -Name ScreenSaveTimeOut -Type String -Value 600
            Set-RegistryKey -SID $UserProfile.SID -Key "HKCU\Control Panel\Desktop" -Name ScreenSaveIsSecure -Type String -Value 1
            Set-RegistryKey -SID $UserProfile.SID -Key "HKCU\Control Panel\Desktop" -Name ScreenSaveActive -Type String -Value 1
            #Set Default DPI
            Set-RegistryKey -SID $UserProfile.SID -Key "HKCU\Control Panel\Desktop" -Name LogPixels -Type DWord -Value 96
            Set-RegistryKey -SID $UserProfile.SID -Key "HKCU\Control Panel\Desktop" -Name Win8DpiScaling -Type DWord -Value 1
            #Set Default Theme
            Set-RegistryKey -SID $UserProfile.SID -Key "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes" -Name CurrentTheme -Type String -value "%LOCALAPPDATA%\Microsoft\Windows\Themes\BCIU22_Wi\BCIU22_Wi.theme"
            Set-RegistryKey -SID $UserProfile.SID -Key "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\High Contract" -name "Pre-High Contrast Scheme" -Type String -Value "%LOCALAPPDATA%\Microsoft\Windows\Themes\BCIU22_Wi\BCIU22_Wi.theme"
            #Disable OneDrive AutoRun
            Remove-RegistryKey -SID $UserProfile.SID -Key "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name OneDriveSetup
		}
		Invoke-HKCURegistrySettingsForAllUsers -RegistrySettings $HKCURegistrySettings
		
		##*===============================================
		##* POST-INSTALLATION
		##*===============================================
		[string]$installPhase = 'Post-Installation'
		
		## <Perform Post-Installation tasks here>
		
		## Display a message at the end of the install
		#If (-not $useDefaultMsi) { Show-InstallationPrompt -Message 'You can customize text to appear at the end of an install or remove it completely for unattended installations.' -ButtonRightText 'OK' -Icon Information -NoWait }
	}
	ElseIf ($deploymentType -ieq 'Uninstall')
	{
		##*===============================================
		##* PRE-UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Pre-Uninstallation'
		
		## Show Welcome Message, close Internet Explorer with a 60 second countdown before automatically closing
		#Show-InstallationWelcome -CloseApps 'iexplore' -CloseAppsCountdown 60
		
		## Show Progress Message (with the default message)
		Show-InstallationProgress
		
		## <Perform Pre-Uninstallation tasks here>
		
		
		##*===============================================
		##* UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Uninstallation'
		
		## Handle Zero-Config MSI Uninstallations
		If ($useDefaultMsi) {
			[hashtable]$ExecuteDefaultMSISplat =  @{ Action = 'Uninstall'; Path = $defaultMsiFile }; If ($defaultMstFile) { $ExecuteDefaultMSISplat.Add('Transform', $defaultMstFile) }
			Execute-MSI @ExecuteDefaultMSISplat
		}
		
		# <Perform Uninstallation tasks here>
		
		
		##*===============================================
		##* POST-UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Post-Uninstallation'
		
		## <Perform Post-Uninstallation tasks here>
		
		
	}
	
	##*===============================================
	##* END SCRIPT BODY
	##*===============================================
	
	## Call the Exit-Script function to perform final cleanup operations
	Exit-Script -ExitCode $mainExitCode
}
Catch {
	[int32]$mainExitCode = 60001
	[string]$mainErrorMessage = "$(Resolve-Error)"
	Write-Log -Message $mainErrorMessage -Severity 3 -Source $deployAppScriptFriendlyName
	Show-DialogBox -Text $mainErrorMessage -Icon 'Stop'
	Exit-Script -ExitCode $mainExitCode
}