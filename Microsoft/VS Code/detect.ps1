$RequiredExtensions = @("hnw.vscode-auto-open-markdown-preview-0.0.3","mitchdenny.ecdc-0.10.3","ms-vscode.PowerShell-0.6.2")
$Version = $(get-Item 'C:\Program Files (x86)\Microsoft VS Code\Code.exe').VersionInfo.FileVersion
if ($Version -eq "1.4.0")
{
    Get-ChildItem "C:\Users" | Foreach-Object {
        $InstalledExtensions = Get-ChildItem "$($_.FullName)\.vscode\extensions"   -ErrorAction SilentlyContinue
        if (-not $InstalledExtensions)
        {
            exit
        }
        Foreach($RequiredExtension in $RequiredExtensions)
        {
            $testPath = "$($_.FullName)\.vscode\extensions\$RequiredExtension"
            $isPresent = Test-Path -Path $testPath
            if ( -not $isPresent  )
            {
                exit
            }
        }
    }
    Write-Host "Installed"
    exit
}
exit