$env:Path+=";C:\Users\"+[Environment]::UserName+"\AppData\Local\Android\android-sdk\tools\"
android update sdk --no-ui --filter platform,platform-tool,tool
android update sdk --no-ui --filter android-19
Show-WindowsDeveloperLicenseRegistration
Set-ItemProperty -Path registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\policies\system -Name EnableLUA -Value 1
shutdown /r