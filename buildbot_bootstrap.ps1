$wc = New-Object System.Net.WebClient

$medicRepo = "https://github.com/MSOpenTech/cordova-medic.git"
$medicBranch = "windows-fixes"
$couchAddr = "http://localhost:5984"
$buildbotDir = "C:/bb/"
$masterName = "testmaster"

Write-Host "Installing Chocolatey ..."
iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))
$env:Path+=";C:\ProgramData\chocolatey\bin"

#Git section
choco install git.install
Write-Host "Updating Git PATH ..."
$oldPath=(Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH).Path
$newPath=$oldPath+"C:\Program Files (x86)\Git\bin"
#Next line will fail w/o Administrator privileges
Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH –Value $newPath
$env:Path+=";C:\Program Files (x86)\Git\cmd;C:\Program Files (x86)\Git\bin"

#CouchDB section
$destination = $($env:TEMP + "\setup-couchdb-1.6.0_R16B02.exe")
$source = "http://apache-mirror.rbc.ru/pub/apache/couchdb/binary/win/1.6.0/setup-couchdb-1.6.0_R16B02.exe"
Write-Host "Downloading CouchDB ..."
$wc.DownloadFile($source, $destination)

$argList="/NORESTART /SILENT"

Write-Host "Installing CouchDB ..."
Start-Process -FilePath $destination -ArgumentList $argList -Wait

Write-Host "Updating CouchDB config"
$file = "C:\Program Files (x86)\Apache Software Foundation\CouchDB\etc\couchdb\local.ini"
$content = Get-Content $file
if ( $content -match ";bind_address = 127.0.0.1" ) {
    $content -replace ";bind_address = 127.0.0.1" , "bind_address = 0.0.0.0" | Set-Content $file
} else {
    if($content -match "bind_address = 0.0.0.0") {
        Write-Host "CouchDB config is already up-to date"
    } else {
        Write-Host "CouchDB config has invalid structure"
    }
}

Write-Host "Creating Couch tables..."
@("build_errors", "mobilespec_results", "test_details") | foreach {
    Invoke-WebRequest -Uri "127.0.0.1:5984/$_" -Method Put
}
Write-Host "Creating _design/results/sha view..."
'{"_id":"_design/results","views":{"sha":{"map":"function(doc){emit(doc.sha);}"}}}' |
Invoke-WebRequest -Uri "127.0.0.1:5984/mobilespec_results/_design/results" -Method Put

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

#Set PYTHONHOME to avoid PyWin32 to be installed improperly
Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PYTHONHOME –Value "C:\tools\python2"
$env:PYTHONHOME = "C:\tools\python2"
cinst PyWin32

#Buildbot prepare and install section
Write-Host "Installing buildbot and dependencies ..."
pip install buildbot
pip install buildbot-slave
Write-Host ""

#buildbot start section
$argList = $("clone $medicRepo -b $medicBranch " + $($env:TEMP + "\cordova-medic"))
Start-Process -FilePath git -ArgumentList $argList -Wait

mkdir $buildbotDir
$argList = $("create-master " + $buildbotDir + $masterName)
Start-Process -FilePath buildbot -ArgumentList $argList -Wait

copy $($env:TEMP + "\cordova-medic\master.cfg") $($buildbotDir + $masterName + "\master.cfg")
copy $($env:TEMP + "\cordova-medic\repos.json") $($buildbotDir + "repos.json")
copy $($env:TEMP + "\cordova-medic\config.json.sample-windows") $($buildbotDir + "config.json")

#Update config.json
$file = $($buildbotDir + "config.json")
$content = Get-Content $file
if ( $content -match "http://localcouchdb:5984" ) {
    $content -replace "http://localcouchdb:5984" , $couchAddr | Set-Content $file
} else {
    Write-Host "config.json wasn't updated"
}

$argList = $("start " + $buildbotDir + $masterName)
Start-Process -FilePath buildbot -ArgumentList $argList

#Adding firewall rules
New-NetFirewallRule -DisplayName “Apache CouchDB” -Direction Inbound –LocalPort 5984 -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName “Waterfall” -Direction Inbound –LocalPort 8010 -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName “Slave” -Direction Inbound –LocalPort 9889 -Protocol TCP -Action Allow

shutdown /r

Write-Host "Press any key to continue ..."
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")