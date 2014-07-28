#TODO: store pw encripted
NET USER AutoUser "SomePassword2014" /ADD
NET LOCALGROUP "Administrators" "AutoUser" /ADD

# folder that is allowed to share between users
mkdir "C:\mytemp"

Set-ItemProperty -Path registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\policies\system -Name EnableLUA -Value 0

New-ItemProperty -Path registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\RunOnce -Name Installer -Value 'powershell "C:\mytemp\autologon.ps1"'

shutdown /r