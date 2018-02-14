if WScript.Arguments.count <> 2 then
	WScript.Echo "Missing source and destination"
	WScript.Quit 1
end if

strSource = WScript.Arguments.Item(0)
strDestination = WScript.Arguments.Item(1)

'WScript.echo "S: " + strSource
'WScript.Echo "D: " + strDestination

Set oWS = WScript.CreateObject("WScript.Shell")
Set oLink = oWS.CreateShortcut(strDestination)
oLink.TargetPath = strSource
oLink.Save