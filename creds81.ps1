$user = "AutoUser"
#TODO: store pw encripted
$pass = "SomePass2014" | convertto-securestring -asplaintext -force
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $user, $pass
$arglist = "C:\mytemp\medic-bootstrap\win81.ps1"
start-process powershell $arglist -Credential $cred