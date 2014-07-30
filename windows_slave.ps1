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

if($args[0] -eq "windows81") {
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
} else {
    if($args[0] -eq "windows80") {
        choco install VisualStudioExpress2012Windows8
        choco install VisualStudioExpress2012WindowsPhone
    }
}

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

$runValue = $("powershell -ExecutionPolicy Unrestricted C:\mytemp\medic-bootstrap\final.ps1 " + $args[0])
New-ItemProperty -Path registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\RunOnce -Name Installer -Value $runValue

# Disable hyperprotective IE policy to make Developer License Registration window available
Set-ItemProperty -Path "registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}" -Name IsInstalled -Value 0

shutdown /r

Write-Host "Press any key to continue ..."
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")