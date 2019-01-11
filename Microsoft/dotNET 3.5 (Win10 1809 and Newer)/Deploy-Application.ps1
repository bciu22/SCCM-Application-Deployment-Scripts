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
	http://psappdeploytoolkit.codeplex.com
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
	[string]$appVendor = 'Microsoft'
	[string]$appName = '.Net 3.5'
	[string]$appVersion = ''
	[string]$appArch = 'x86/amd64'
	[string]$appLang = 'EN'
	[string]$appRevision = '01'
	[string]$appScriptVersion = '1.0.0'
	[string]$appScriptDate = '20190111'
	[string]$appScriptAuthor = 'Dan Lezoche'
	##*===============================================

<# SCCM DETECTION LOGIC:
    #Check if path is valid
    If(Test-Path "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v3.5")
    {
        #Get Install value
        $val = Get-ItemProperty -Path "HKLM:SOFTWARE\Microsoft\NET Framework Setup\NDP\v3.5" -Name Install
        #If Install=1, Installed
        If ($val.Install -eq 1)
        {
            return $true #success
        }
        #return nothing, write nothing on failure
    }
#>


	##* Do not modify section below
	#region DoNotModify
	
	## Variables: Exit Code
	[int32]$mainExitCode = 0
	
	## Variables: Script
	[string]$deployAppScriptFriendlyName = 'Deploy Application'
	[version]$deployAppScriptVersion = [version]'3.6.1'
	[string]$deployAppScriptDate = '03/26/2015'
	[hashtable]$deployAppScriptParameters = $psBoundParameters
	
	## Variables: Environment
	[string]$scriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
	
	## Dot source the required App Deploy Toolkit Functions
	Try {
		[string]$moduleAppDeployToolkitMain = "$scriptDirectory\AppDeployToolkit\AppDeployToolkitMain.ps1"
		If (-not (Test-Path -Path $moduleAppDeployToolkitMain -PathType Leaf)) { Throw "Module does not exist at the specified location [$moduleAppDeployToolkitMain]." }
		If ($DisableLogging) { . $moduleAppDeployToolkitMain -DisableLogging } Else { . $moduleAppDeployToolkitMain }
	}
	Catch {
		[int32]$mainExitCode = 60008
		Write-Error -Message "Module [$moduleAppDeployToolkitMain] failed to load: `n$($_.Exception.Message)`n `n$($_.InvocationInfo.PositionMessage)" -ErrorAction 'Continue'
		Exit $mainExitCode
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
		Show-InstallationWelcome -AllowDefer -DeferTimes 3 -CheckDiskSpace -PersistPrompt
		
		## Show Progress Message (with the default message)
		Show-InstallationProgress
		
		## <Perform Pre-Installation tasks here>
		#Stop-Process -Name "iexplore,firefox,chrome" -Force
        $currentVersion = (Get-WmiObject -Class Win32_OperatingSystem).BuildNumber
        $minVersion = 17763
        If(([System.Environment]::OSVersion.Version.Major -eq "10") -AND ([System.Environment]::OSVersion.Version.Minor -eq "0"))
        {
            Write-Log -Message "Installer running on Windows 10, checking build number requirements"
		    If($currentVersion -lt $minVersion )
            {
		        Write-Log -Message "Version $currentVersion doesn't meet minimum BuildNumber $minVersion" -Severity 3
                Exit-Script -ExitCode 1603
            }
            Else #supported version found
            {
                Write-Log -Message "Version $currentVersion is supported, continuing installation"
            }
        }
        Else
        {
            Write-Log -Message "OS Requirement (Windows 10) not met" -Severity 3
            Exit-Script -ExitCode 1603
        }
		
		##*===============================================
		##* INSTALLATION 
		##*===============================================
		[string]$installPhase = 'Installation'
		
		## Handle Zero-Config MSI Installations
		If ($useDefaultMsi) { Execute-MSI -Action 'Install' -Path $defaultMsiFile }
		
		## <Perform Installation tasks here>
        Write-Log -Message "Backing up WU registry key and restarting service"
        $UseWUServer = Get-RegistryKey -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Value "UseWUServer"
        Set-RegistryKey -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "UseWUServer" -Type "DWord" -Value 0
        Restart-Service wuauserv

        $rebootNeeded = $False
        $failureDetected = $False
		$capabilities = Get-WindowsCapability -Online | Where-Object {$_.Name -like "NetFx3*" -AND $_.State -eq "NotPresent"}
		If($capabilities -ne $null) #something to install
        {
            Write-Log -Message "Found $($capabilities.count) capabilities to install"
            ForEach($capability in $capabilities)
            {
                Try
                {
                    Write-Log -Message "Installing $($capability.Name)"
                    $result = Add-WindowsCapability -Online -Name $capability.Name
                    If(!$rebootNeeded -AND $result.RestartNeeded) #$True or $rebootNeeded already $true (don't process further)
                    {
                        Write-Log -Message "Found reboot requirement, updating return code" -Severity 2
                        $rebootNeeded = $True
                    }
                }
                Catch [System.Exception]
                {
                    Write-Log -Message "There was an error adding $($capability.Name)" -Severity 3
                    $failureDetected = $True
                }
            }
        }

		##*===============================================
		##* POST-INSTALLATION
		##*===============================================
		[string]$installPhase = 'Post-Installation'
		
		## <Perform Post-Installation tasks here>
        #Restore WU registry key configuration to before installation
        Write-Log -Message "Restoring WU registry key and restarting service"
        Set-RegistryKey -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "UseWUServer" -Type "DWord" -Value $UseWUServer
        Restart-Service wuauserv
        #handle return code for reboots
        If($rebootNeeded -OR $failureDetected)
        {
            Write-Log -Message "Returning soft reboot code"
            #SCCM Soft Reboot by default
            $mainExitCode = 3010
        }
        Else
        {
            Write-Log -Message "No reboot required/reported"
        }
		
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
		Show-InstallationWelcome -CloseAppsCountdown 60
		
		## Show Progress Message (with the default message)
		Show-InstallationProgress
		
		## <Perform Pre-Uninstallation tasks here>
		$rebootNeeded = $False
        $failureDetected = $False
        #Backup and temporarily disable WSUS AU (SCCM) config to allow Features on Demand (FOD) to work
        Write-Log -Message "Backing up WU registry key and restarting service"
        $UseWUServer = Get-RegistryKey -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Value "UseWUServer"
        Set-RegistryKey -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "UseWUServer" -Type "DWord" -Value 0
        Restart-Service wuauserv
		
		##*===============================================
		##* UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Uninstallation'
		
		## Handle Zero-Config MSI Uninstallations
		If ($useDefaultMsi) { Execute-MSI -Action 'Uninstall' -Path $defaultMsiFile }
		
		# <Perform Uninstallation tasks here>
        $capabilities = Get-WindowsCapability -Online | Where-Object {$_.Name -Like "NetFx3*" -AND $_.State -eq "Installed"}
        If($capabilities -ne $null) #remove any remaining capabilities
        {
            ForEach($Capability in $Capabilities)
            {
                Try
                {
                    Write-Log -Message "Removing $($capability.name)"
                    $result = Remove-WindowsCapability -Name $capability.Name -Online
                    If(!$rebootNeeded -AND $result.RestartNeeded) #$True or $rebootNeeded already $true (don't process further)
                    {
                        Write-Log -Message "Found reboot requirement, updating return code" -Severity 2
                        $rebootNeeded = $True
                    }
                }
                Catch [System.Exception]
                {
                    Write-Log -Message "There was an error removing $($capability.Name)" -Severity 3
                    $failureDetected = $True
                }
            }
        }
		
		##*===============================================
		##* POST-UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Post-Uninstallation'
		
		## <Perform Post-Uninstallation tasks here>
		#check for any capabilities still installed, if none, remove registry tatoo
        $capabilities = Get-WindowsCapability -Online | Where-Object {$_.Name -Like "NetFx3*" -AND $_.State -eq "Installed"}
        If($capabilities -eq $null) #no capabilities found
        {
            Write-Log -Message "All capabilities uninstalled"
        }
        Else
        {
            Write-Log -Message "Found $($capabilities.count) capabilities still installed, removal failed"
            $failureDetected = $True
        }
        Write-Log -Message "Restoring WU registry key and restarting service"
        Set-RegistryKey -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "UseWUServer" -Type "DWord" -Value $UseWUServer
        Restart-Service wuauserv
        #handle return code for reboots
        If($rebootNeeded -OR $failureDetected)
        {
            Write-Log -Message "Returning reboot code"
            #SCCM Soft Reboot by default
            $mainExitCode = 3010
        }
        Else
        {
            Write-Log -Message "No reboot required/reported"
        }		
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