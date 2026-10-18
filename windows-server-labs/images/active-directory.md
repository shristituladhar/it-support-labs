Active Directory
Windows Server 2016 domain: PLABDC01 (DC), PLABDM01, PLABSA01, PLABDCORE01 (Server Core) and PLABWIN10 (client).
Contents
AD account management and offline domain join
Install from Media (IFM), RODC and password replication policy
AD design, deployment and Group Policy
---
AD account management and offline domain join
What I did
Removed PLABSA01 from the domain, then deleted its computer object in ADUC
On the DC, ran `djoin /provision` to pre-create the computer account and save a blob file
Paused the DC, so PLABSA01 couldn't reach it, and joined PLABSA01 offline with `djoin /requestODJ`
Resumed the DC and confirmed PLABSA01 was back in the domain
Set an account lockout threshold in Group Policy, then locked a test user out on purpose from the Windows 10 client
Used PowerShell to find locked, disabled and inactive accounts, and re-enabled a disabled one
Set "Allow log on locally" and "Allow log on through Remote Desktop Services" rights for specific groups
Commands I used
```powershell
djoin /provision /domain practicelabs.com /machine PLABSA01 /savefile c:\plabsa01.txt
djoin /requestODJ /loadfile c:\plabsa01.txt /windowspath %SystemRoot% /localos

Search-ADAccount -LockedOut
Search-ADAccount -AccountDisabled
Enable-ADAccount -Identity <username>
Search-ADAccount -AccountInactive -UsersOnly -TimeSpan 1.00:00:00 | ft name
```
Why this matters for support
Locked-out accounts are one of the most common service desk tickets. Offline domain join is useful when a machine is being built somewhere it can't reach a DC.
Screenshots
Djoin provision computer account
![djoin provision computer account](images/ad-01-djoin-provision-computer-account.png)
Djoin requestodj offline join
![djoin requestodj offline join](images/ad-02-djoin-requestodj-offline-join.png)
Plabsa01 back in domain aduc
![plabsa01 back in domain aduc](images/ad-03-plabsa01-back-in-domain-aduc.png)
Account lockout threshold policy
![account lockout threshold policy](images/ad-04-account-lockout-threshold-policy.png)
User locked out signin
![user locked out signin](images/ad-05-user-locked-out-signin.png)
Search locked out accounts ps
![search locked out accounts ps](images/ad-06-search-locked-out-accounts-ps.png)
Inactive accounts ps
![inactive accounts ps](images/ad-07-inactive-accounts-ps.png)
Rds logon user rights
![rds logon user rights](images/ad-08-rds-logon-user-rights.png)

---
Install from Media (IFM), RODC and password replication policy
What I did
Created IFM media on the existing DC with `ntdsutil`
Promoted PLABDM01 to a DC using that media, so it didn't have to pull the whole AD database over the network
Installed a read-only domain controller (RODC) on PLABSA01 with PowerShell
Set up its password replication policy: created a group, added it to the Allowed RODC Password Replication Group, and prepopulated passwords for specific users
Commands I used
```
ntdsutil "activate instance ntds" ifm "create sysvol full C:\IFM" quit quit
```
```powershell
Install-ADDSDomainController -DomainName practicelabs.com -ReadOnlyReplica -SiteName "Default-First-Site-Name" -Credential (Get-Credential)
```
Troubleshooting
The test user didn't show under "Accounts that have been authenticated to this RODC" because the Windows 10 client failed to log on with a domain trust relationship error. The fix for that is `Test-ComputerSecureChannel -Repair` on the client.
Why this matters
An RODC is what you'd put in a branch office with weak physical security. It doesn't store everyone's passwords, only the ones you allow.
Screenshots
Ntdsutil ifm media created
![ntdsutil ifm media created](images/ad-09-ntdsutil-ifm-media-created.png)
Dc promotion from ifm options
![dc promotion from ifm options](images/ad-10-dc-promotion-from-ifm-options.png)
New dc in aduc
![new dc in aduc](images/ad-11-new-dc-in-aduc.png)
Rodc install powershell
![rodc install powershell](images/ad-12-rodc-install-powershell.png)
Rodc in aduc
![rodc in aduc](images/ad-13-rodc-in-aduc.png)
Allowed rodc password replication group
![allowed rodc password replication group](images/ad-14-allowed-rodc-password-replication-group.png)
Rodc advanced password replication policy
![rodc advanced password replication policy](images/ad-15-rodc-advanced-password-replication-policy.png)

---
AD design, deployment and Group Policy
Goal
Build a domain structure across four servers and a Windows 10 client: a root domain, child domains for two sites, a read-only DC, OUs and users. Then use Group Policy to control what software users can run.
My design
Root domain: `practicelabs.com` on PLABDC01 (Sydney). This is the main DNS and authentication server
Child domains: MEL (on PLABDM01) and BNE (on PLABSA01), one per site
RODC: PLABDCORE01 (Server Core) in the root domain
OUs: one for standard users, one for admin users
What I built
Promoted the child domains and the RODC entirely in PowerShell
Created OUs and users with `dsadd`: a standard user who has to change password at first logon, and an admin user whose password never expires
Software GPO: "Don't run specified Windows applications", linked to the standard users' OU
Computer GPO: "Turn off the Store application", linked to the client
Checked both with `gpupdate /force` and `gpresult /r`
```powershell
Install-ADDSDomain -DomainType ChildDomain -NewDomainName MEL -ParentDomainName practicelabs.com -InstallDNS -Credential (Get-Credential)
Install-ADDSDomainController -DomainName practicelabs.com -ReadOnlyReplica -SiteName "Default-First-Site-Name" -Credential (Get-Credential)
```
Troubleshooting
The plan was to block Microsoft Edge with a GPO, but blocking `msedge.exe` did nothing. When I checked the shortcut, Edge on that Windows 10 build was a UWP app (`Microsoft.MicrosoftEdge_8wekyb3d8bbwe`) with no .exe on disk for the policy to match. "Don't run specified applications" only matches executable names. I switched the policy to `iexplore.exe` to prove the GPO worked. In a real environment I'd block a UWP app with AppLocker packaged-app rules instead.
Screenshots
Ad design topology
![ad design topology](images/ad-16-ad-design-topology.png)
Hyperv lab vms
![hyperv lab vms](images/ad-17-hyperv-lab-vms.png)
Child domain mel promoted
![child domain mel promoted](images/ad-18-child-domain-mel-promoted.png)
Rodc promoted server core
![rodc promoted server core](images/ad-19-rodc-promoted-server-core.png)
Domain controllers aduc
![domain controllers aduc](images/ad-20-domain-controllers-aduc.png)
Ou and user created dsadd
![ou and user created dsadd](images/ad-21-ou-and-user-created-dsadd.png)
Must change password first logon
![must change password first logon](images/ad-22-must-change-password-first-logon.png)
Gpo dont run iexplore
![gpo dont run iexplore](images/ad-23-gpo-dont-run-iexplore.png)
Ie blocked for user
![ie blocked for user](images/ad-24-ie-blocked-for-user.png)
Edge is uwp not exe
![edge is uwp not exe](images/ad-25-edge-is-uwp-not-exe.png)
Gpo turn off store
![gpo turn off store](images/ad-26-gpo-turn-off-store.png)
Store blocked
![store blocked](images/ad-27-store-blocked.png)
Gpresult r
![gpresult r](images/ad-28-gpresult-r.png)
