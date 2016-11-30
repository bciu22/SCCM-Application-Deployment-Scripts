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
	Deploy-Application.ps1
.EXAMPLE
	Deploy-Application.ps1 -DeployMode 'Silent'
.EXAMPLE
	Deploy-Application.ps1 -AllowRebootPassThru -AllowDefer
.EXAMPLE
	Deploy-Application.ps1 -DeploymentType Uninstall
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
	[string]$appVendor = 'SolidWorks'
	[string]$appName = 'SolidWorks 2016-2017'
	[string]$appVersion = ''
	[string]$appArch = ''
	[string]$appLang = 'EN'
	[string]$appRevision = '01'
	[string]$appScriptVersion = '1.0.0'
	[string]$appScriptDate = '08/17/2015'
	[string]$appScriptAuthor = 'Charles Crossan'
	##*===============================================
	
	##* Do not modify section below
	#region DoNotModify
	
	## Variables: Exit Code
	[int32]$mainExitCode = 0
	
	## Variables: Script
	[string]$deployAppScriptFriendlyName = 'Deploy Application'
	[version]$deployAppScriptVersion = [version]'3.6.5'
	[string]$deployAppScriptDate = '08/17/2015'
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
		
		Execute-Process -Path "$dirFiles\64bit\OfficeWeb_11\owc11.exe" -Parameters "/quiet"
		Execute-Process -Path "$dirFiles\64bit\Microsoft_C++_2005_Redistributable_(x64)\vcredist_x64.exe" -Parameters "/Q"
		Execute-Process -Path "$dirFiles\64bit\Microsoft_C++_2005_Redistributable\vcredist_x86.exe" -Parameters "/Q"
		Execute-Process -Path "$dirFiles\64bit\Microsoft_C++_2008_Redistributable_(x64)\vcredist_x64.exe" -Parameters "/Q"
		Execute-Process -Path "$dirFiles\64bit\Microsoft_C++_2008_Redistributable\vcredist_x86.exe" -Parameters "/Q"
		Execute-Process -Path "$dirFiles\64bit\Microsoft_C++_2010_Redistributable_(x64)\vcredist_x64.exe" -Parameters "/Q"
		Execute-Process -Path "$dirFiles\64bit\Microsoft_C++_2010_Redistributable\vcredist_x86.exe" -Parameters "/Q"
		Execute-Process -Path "$dirFiles\64bit\Microsoft_C++_2012_Redistributable_(x64)\vcredist_x64.exe" -Parameters "/Q"
		Execute-Process -Path "$dirFiles\64bit\Microsoft_C++_2012_Redistributable\vcredist_x86.exe" -Parameters "/Q"
		Execute-Process -Path "$dirFiles\64bit\.Net_Framework_4.5.2\NDP452-KB2901907-x86-x64-AllOS-ENU" -Parameters "/Q"
		#Execute-MSI -Path "$dirFiles\64bit\Microsoft_VSTA\vsta_aide.msi"
		Execute-Process -Path "$dirFiles\64bit\VSRemoteDebugger\install.exe" -Parameters "/Q"
		Execute-MSI -Path "$dirFiles\64bit\Microsoft_VBA\vba71.msi"
		Execute-MSI -Path "$dirFiles\64bit\Microsoft_VBA_1033\vba71_1033.msi"
		Execute-MSI -Path "$dirFiles\64bit\Bonjour\Bonjour64.msi"
		## <Perform Installation tasks here>
		Execute-MSI -Path "$dirFiles\64bit\SOLIDWORKS\SOLIDWORKS.msi" -AddParameters "INSTALLDIR=""C:\Program Files\SolidWorks"" ADDLOCAL=SolidWorks SERVERLIST=""25734@server.org"" SOLIDWORKSSERIALNUMBER=""xxxx xxxx xxxx xxxx xxxx"" OFFICEOPTION=3 ENABLEPERFORMANCE=0"
		#Execute-MSI -Path "$dirFiles\eDrawings\eDrawings.msi" -AddParameters "INSTALLDIR=""C:\Program Files\your_folder"" LOGPERFORMANCE=1 SNLSERVER=eDrawings_SNL_server TRANSFORMS=1040.mst ADDLOCAL=All"
		#Execute-MSI -Path "$dirFiles\SOLIDWORKS Explorer\SOLIDWORKS Explorer.msi"  -AddParameters "INSTALLDIR=""C:\Program Files\your_folder"" EXPLORERORPDM=1 ADDLOCAL=VaultAdmin,Client,Standalone,DocMgr,LicenseEXE ACTIVSERIALNUMBER=""xxxx xxxx xxxx xxxx xxxx xxxx"""


		##*===============================================
		##* POST-INSTALLATION
		##*===============================================
		[string]$installPhase = 'Post-Installation'
		
		## <Perform Post-Installation tasks here>
		
		## Display a message at the end of the install
		If (-not $useDefaultMsi) { Show-InstallationPrompt -Message "$AppName - $AppVersion installation complete." -ButtonRightText 'OK' -Icon Information -NoWait }
	}
	ElseIf ($deploymentType -ieq 'Uninstall')
	{
		##*===============================================
		##* PRE-UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Pre-Uninstallation'
		
		## Show Welcome Message, close Internet Explorer with a 60 second countdown before automatically closing
		Show-InstallationWelcome -CloseApps 'iexplore' -CloseAppsCountdown 60
		
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