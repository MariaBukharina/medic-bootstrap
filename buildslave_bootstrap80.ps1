$wc = New-Object System.Net.WebClient

$slaveAddr = "23.102.130.9:9889"
$buildbotDir = "C:/bb/"
$slaveName = "slv_win"

Write-Host "Installing Chocolatey ..."
iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))
$env:Path+=";C:\ProgramData\chocolatey\bin"

#Installing nodejs; Chocolatey can't install it successfully under SYSTEM account
# so we have to do it explicitly
$source = "http://nodejs.org/dist/v0.10.29/node-v0.10.29-x86.msi"
$destination = $($env:TEMP + "\node-v0.10.29-x86.msi")
$wc.DownloadFile($source, $destination)

msiexec /qn /norestart /l* $($env:TEMP + "\node_inst.log") /i $destination ALLUSERS=1
$env:Path+=";C:\Program Files (x86)\nodejs\"

#Git section
choco install git.install
Write-Host "Updating Git PATH ..."
$oldPath=(Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH).Path
$newPath=$oldPath+"C:\Program Files (x86)\Git\bin"
#Next line will fail w/o Administrator privileges
Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH –Value $newPath
$env:Path+=";C:\Program Files (x86)\Git\cmd;C:\Program Files (x86)\Git\bin"

#Python section
$argList = "install python2"
Start-Process -FilePath choco -ArgumentList $argList -Wait

#Setup Tools section
Write-Host "Installing pip ..."
cinst pip
$env:Path+=";C:\tools\python2\Scripts"

Write-Host "Updating Python PATH ..."
$oldPath=(Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH).Path
$newPath=$oldPath+";C:\tools\python2;C:\tools\python2\Scripts"
#Next line will fail w/o Administrator privileges
Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH –Value $newPath
[Environment]::SetEnvironmentVariable("Path", "$env:Path;C:\tools\python2;C:\tools\python2\Scripts", "Machine")

cinst PyWin32

#Buildbot prepare and install section
Write-Host "Installing buildslave and dependencies ..."
pip install buildbot-slave
Write-Host ""

#Grunt-cli install section
Write-Host "Installing Grunt-cli and dependencies ..."
npm install -g grunt-cli
$oldPath=(Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH).Path
$newPath=$oldPath+";C:\Users\"+[Environment]::UserName+"\AppData\Roaming\npm"
#Next line will fail w/o Administrator privileges
Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH –Value $newPath
Write-Host ""

#SDKs and VS install section
choco install VisualStudioExpress2012Windows8
choco install VisualStudioExpress2012WindowsPhone

Install-WindowsFeature Desktop-Experience

#buildslave start section
mkdir $buildbotDir

$argList = $("create-slave " + $buildbotDir + $slaveName + " " + $slaveAddr + " win8-slave pass")
Start-Process -FilePath buildslave -ArgumentList $argList -Wait

#TODO: Switch of buildslave start for now. Place it to autorun then
#$argList = $("start " + $buildbotDir + $slaveName)
#Start-Process -FilePath buildslave -ArgumentList $argList

#reboot system to apply changes
shutdown /r

Write-Host "Press any key to continue ..."
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")