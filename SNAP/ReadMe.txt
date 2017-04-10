Download the Update Package and Client Only Installation Package from the Member's Area Downloads Section:
http://psni.cc/PSN/Members/Downloads.aspx

Run them, but don't install them. 
goto %LocalAppData%\Temp, and copy the MSIs and .ini's for SNAP into files\ClientInst and files\ClientUpd
The MSIs are named: 
Install: SNAP Health Center.msi
Upgrade: Health Center Update.msi

The script as it stands searches to see if a version is installed, and if so, runs the update. 
Otherwise, it runs the new client installer.

The next version I'll probably change it to just uninstall all version, and always install fresh. 
This is mainly due to how it's handled, as when you install the update, another product is installed,
but does not show in Programs and Features. Also makes it harder to do SCCM Detection.

Speaking of SCCM Detection...
* Check to see if {0A92289F-138F-44B4-A3A1-EEBEF120D6A1} is installed with version equals 4.5.1 
OR (Then group the following two)
* Check to see if {01CD8FB3-F98C-476A-A62F-4840831A52FB} is installed with version 4.5.1
  AND
  Check to see if {0A92289F-138F-44B4-A3A1-EEBEF120D6A1} is installed.

The first line checks for striaght new installs to version 4.5.1 (see what I mean with this being easier?)
The next two are grouped, as if it's updated, the original stall stays at it's version (4.3.2 in my case),
then the updater is added to version 4.5.1. So those need to be a grouped AND, and then the group needs to 
be OR compared to the first.