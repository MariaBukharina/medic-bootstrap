$env:Path+=";C:\Users\"+[Environment]::UserName+"\AppData\Local\Android\android-sdk\tools\"

$slaveAddr = "localhost:9889"
$buildbotDir = "C:/bb/"
$slaveName = "slv_win"

if($args[0] -eq "windows81") {
    android update sdk --no-ui --filter platform-tool
    android update sdk --no-ui --filter tool
    android update sdk --no-ui --filter android-19
}

mkdir $buildbotDir
$argList = $("create-slave " + $buildbotDir + $slaveName + " " + $slaveAddr + " windows-slave pass")
Start-Process -FilePath buildslave -ArgumentList $argList -Wait

'$argList = "start ' + $buildbotDir + $slaveName + ' "
Start-Process -FilePath buildslave -ArgumentList $argList' > $($buildbotDir + "start.ps1")

icacls $buildbotDir  /grant:r AutoUser:F /T

$StartUpValue = "powershell " + $buildbotDir + "start.ps1"
New-ItemProperty -Path registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run -Name Buildbot -Value $StartUpValue

if($args[0] -eq "windows81") {
    Show-WindowsDeveloperLicenseRegistration
}
Set-ItemProperty -Path registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\policies\system -Name EnableLUA -Value 1
shutdown /r