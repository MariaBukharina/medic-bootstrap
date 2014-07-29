medic-bootstrap
===============

Scripts to automate Apache Cordova Test Automation tool aka Medic deployment

For successful executing administrator permissions are required.

Known issues: 

If you are using Built-in Administrator account you can meet this problem during running medic tests: 

    This app can't open. 
    Store can't be opened using the Built-in Administrator account. Sign in with a different account and try again.
    
It occurs because User Account Control is turned off for this account.
For enabling UAC

    1. run "secpol.msc" and enable
        Local Policies -> Security Options -> User Account Control: Admin Approval Mode for Built-in Administrator account       
    
    or
    
    run in PowerShell
        Set-ItemProperty -Path registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\policies\system -Name EnableLUA -Value 1
        
    2. restart 
        
After that you can encounter an EPERM error at Deploy steps. Run Command Prompt as Administrator and run:
    icacls C:\bb /grant:r userName:(OI)(CI)F
    
   This command gives all necessary permissions for user with userName for C:\bb folder.
 
 
Alternative way
===============

1. Clone repo and upload init.ps1 on your machine
2. Open init.ps1 and set $platformName that is necessary
3. Run init.ps1 with PowerShell
4. Wait for reboot
5. Login as any user to your machine; Script should add AutoUser to autologon and reboot the machine
6. Now wait while everythin is installing under autouser
7. If you are installing "windows81" version, after some time (about 30 minutes) you have to login and accept licenses for Android SDK tools and get Windows Developer licence
 
