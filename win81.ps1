echo $env:USERNAME
$wc = New-Object System.Net.WebClient

#Installing nodejs; Chocolatey cannot install it successfully under SYSTEM account
# so we have to do it explicitly
$source = "http://nodejs.org/dist/v0.10.29/node-v0.10.29-x86.msi"
$destination = $($env:TEMP + "\node-v0.10.29-x86.msi")
$wc.DownloadFile($source, $destination)

msiexec /qn /norestart /l* $($env:TEMP + "\node_inst.log") /i $destination ALLUSERS=1
$env:Path+=";C:\Program Files (x86)\nodejs"

#Python section
choco install python2

#Setup Tools section
Write-Host "Installing pip ..."
cinst pip
$env:Path+=";C:\tools\python2\Scripts"

Write-Host "Updating Python PATH ..."
$oldPath=(Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment" -Name PATH).Path
$newPath=$oldPath+";C:\tools\python2;C:\tools\python2\Scripts"
#Next line will fail w/o Administrator privileges
Set-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment" -Name PATH –Value $newPath
[Environment]::SetEnvironmentVariable("Path", "$env:Path;C:\tools\python2;C:\tools\python2\Scripts", "Machine")

cinst PyWin32

#Buildbot prepare and install section
Write-Host "Installing buildslave and dependencies ..."
pip install buildbot-slave
Write-Host ""

#SDKs and VS install section

#choco install VisualStudioExpress2013Windows
#choco install VS2013.2

choco install jdk8

choco install ant

choco install android-sdk
Write-Host "Updating Android SDK PATH ..."
$oldPath=(Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment" -Name PATH).Path
$newPath=$oldPath+";C:\Users\"+[Environment]::UserName+"\AppData\Local\Android\android-sdk\tools"
#Next line will fail w/o Administrator privileges
Set-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment" -Name PATH –Value $newPath

#Grunt-cli install section
Write-Host "Installing Grunt-cli and dependencies ..."
npm install -g grunt-cli
$oldPath=(Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment" -Name PATH).Path
$newPath=$oldPath+";C:\Users\"+[Environment]::UserName+"\AppData\Roaming\npm"
#Next line will fail w/o Administrator privileges
Set-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment" -Name PATH –Value $newPath
Write-Host ""
$env:Path += ";C:\Users\"+[Environment]::UserName+"\AppData\Roaming\npm"

Install-WindowsFeature Desktop-Experience

$runValue = "powershell C:\mytemp\medic-bootstrap\final.ps1"
New-ItemProperty -Path registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\RunOnce -Name Installer -Value $runValue

# Enable JavaScript to show license window
regsvr32 jscript.dll
# Enable cookies
Set-ItemProperty -Path 'registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\3' -Name 1A10 -Value 1

shutdown /r

Write-Host "Press any key to continue ..."
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")