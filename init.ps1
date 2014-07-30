# accepted "windows81" or "windows80"
$platformName = "windows81"
$autoUserName = "AutoUser"
$autoUserPassword = "SomePass2014"

NET USER $autoUserName $autoUserPassword /ADD
NET LOCALGROUP "Administrators" $autoUserName /ADD

# folder that is allowed to share between users
mkdir "C:\mytemp"

Write-Host "Installing Chocolatey ..."
iex ((new-object net.webclient).DownloadString("https://chocolatey.org/install.ps1"))
$env:Path+=";C:\ProgramData\chocolatey\bin"

choco install git.install
Write-Host "Updating Git PATH ..."
$oldPath=(Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment" -Name PATH).Path
$newPath=$oldPath+"C:\Program Files (x86)\Git\bin"
#Next line will fail w/o Administrator privileges
Set-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment" -Name PATH –Value $newPath
$env:Path+=";C:\Program Files (x86)\Git\cmd;C:\Program Files (x86)\Git\bin"

git clone "https://github.com/akvelon/medic-bootstrap.git" "C:\mytemp\medic-bootstrap"

Set-ItemProperty -Path registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\policies\system -Name EnableLUA -Value 0

New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name AutoAdminLogon -Value 1
New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name DefaultUserName -Value $autoUserName
New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name DefaultPassword -Value $autoUserPassword
# Unresticted (or less?) is necessary with windows80 parameter for Windows Server 2012
$runValue = $("powershell -ExecutionPolicy Unrestricted C:\mytemp\medic-bootstrap\windows_slave.ps1 " + $platformName)
New-ItemProperty -Path registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\RunOnce -Name Installer -Value $runValue

shutdown /r