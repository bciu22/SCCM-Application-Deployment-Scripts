:: DPL 20141009
:: This script will automatically install the CMTrace utility
@echo off
cls

:: Get execution path
SET _thisdir=%~dp0

echo Usage: InstallCMTrace.bat [y]
echo        y - accept prompt to activate
echo.

::check parameter
IF "%1%" == "y" GOTO LOAD

:PROMPT
::Get input from user to continue
echo ##########################
echo # Install CMTrace? (y/n) #
echo ##########################
set /P input="Select: "
IF /I '%input%'=='y' GOTO LOAD
IF /I '%input%'=='n' GOTO DONE
echo ***Unrecognized Entry, Try Again***
GOTO PROMPT

:LOAD
cls
::Pre-Install Section - put things here to do before installation
:: echo Processing Pre-Install Items
:: taskkill /F /IM firefox.exe /T
echo ######################
echo # Installing CMTrace #
echo ######################
echo.
IF EXIST "%_thisdir%cmtrace.exe" (
	echo Setting up CMTrace.exe
	MKDIR "%PROGRAMFILES%\CMTrace"
	COPY "%_thisdir%cmtrace.exe" "%PROGRAMFILES%\CMTrace" /Y
	echo Creating shortcut to CMTrace.exe
	cscript "%_thisdir%CreateShortcut.vbs" "%PROGRAMFILES%\CMTrace\cmtrace.exe" "%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Microsoft System Center\Configuration Manager\CMTrace.lnk"
	setx /m path "%PATH%;%PROGRAMFILES%\CMTrace"
	GOTO CLEANUP
) ELSE (
	echo Unable to find "cmtrace.exe"
	echo Update not installed.
)
echo.

:CLEANUP
:: Use this section to perform post-install cleanups, some examples follow
:: XCOPY "%_thisdir%override.ini" "C:\Program Files\Mozilla Firefox" /Y
:: REG DELETE "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "QuickTime Task" /f
:: schtasks /delete /tn "\Apple\AppleSoftwareUpdate" /F
:: IF EXIST "%PUBLIC%\Desktop\Adobe Acrobat X Pro.lnk" DEL /Q "%PUBLIC%\Desktop\Adobe Acrobat X Pro.lnk"

:DONE
echo DONE
ping loopback -n 10 > nul
set input=
EXIT