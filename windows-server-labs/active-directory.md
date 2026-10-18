# Active Directory

Windows Server 2016 domain: PLABDC01 (DC), PLABDM01, PLABSA01, PLABDCORE01 (Server Core) and PLABWIN10 (client).

## Contents

- [AD account management and offline domain join](#ad-account-management-and-offline-domain-join)
- [Install from Media (IFM), RODC and password replication policy](#install-from-media-ifm-rodc-and-password-replication-policy)
- [AD design, deployment and Group Policy](#ad-design-deployment-and-group-policy)

---

## AD account management and offline domain join

### What I did
- Removed PLABSA01 from the domain, then deleted its computer object in ADUC
- On the DC, ran `djoin /provision` to pre-create the computer account and save a blob file
- Paused the DC, so PLABSA01 couldn't reach it, and joined PLABSA01 offline with `djoin /requestODJ`
- Resumed the DC and confirmed PLABSA01 was back in the domain
- Set an account lockout threshold in Group Policy, then locked a test user out on purpose from the Windows 10 client
- Used PowerShell to find locked, disabled and inactive accounts, and re-enabled a disabled one
- Set "Allow log on locally" and "Allow log on through Remote Desktop Services" rights for specific groups

### Commands I used
```powershell
djoin /provision /domain practicelabs.com /machine PLABSA01 /savefile c:\plabsa01.txt
djoin /requestODJ /loadfile c:\plabsa01.txt /windowspath %SystemRoot% /localos

Search-ADAccount -LockedOut
Search-ADAccount -AccountDisabled
Enable-ADAccount -Identity <username>
Search-ADAccount -AccountInactive -UsersOnly -TimeSpan 1.00:00:00 | ft name
```

### Why this matters for support
Locked-out accounts are one of the most common service desk tickets. Offline domain join is useful when a machine is being built somewhere it can't reach a DC.

### Screenshots
**Computer account pre-provisioned on the DC with djoin**

![Computer account pre-provisioned on the DC with djoin](images/01-djoin-provision-computer-account.png)

**Offline join on PLABSA01 with djoin /requestODJ**

![Offline join on PLABSA01 with djoin /requestODJ](images/02-djoin-offline-join.png)

**PLABSA01 back in the domain**

![PLABSA01 back in the domain](images/03-plabsa01-back-in-domain.png)

**Account lockout threshold set in Group Policy**

![Account lockout threshold set in Group Policy](images/04-account-lockout-policy.png)

**User locked out at sign-in**

![User locked out at sign-in](images/05-user-locked-out.png)

**Finding locked-out accounts in PowerShell**

![Finding locked-out accounts in PowerShell](images/06-search-locked-out-accounts.png)

---

## Install from Media (IFM), RODC and password replication policy

### What I did
- Created IFM media on the existing DC with `ntdsutil`
- Promoted PLABDM01 to a DC using that media, so it didn't have to pull the whole AD database over the network
- Installed a read-only domain controller (RODC) on PLABSA01 with PowerShell
- Set up its password replication policy: created a group, added it to the Allowed RODC Password Replication Group, and prepopulated passwords for specific users

### Commands I used
```
ntdsutil "activate instance ntds" ifm "create sysvol full C:\IFM" quit quit
```
```powershell
Install-ADDSDomainController -DomainName practicelabs.com -ReadOnlyReplica -SiteName "Default-First-Site-Name" -Credential (Get-Credential)
```

### Troubleshooting
The test user didn't show under "Accounts that have been authenticated to this RODC" because the Windows 10 client failed to log on with a domain trust relationship error. The fix for that is `Test-ComputerSecureChannel -Repair` on the client.

### Why this matters
An RODC is what you'd put in a branch office with weak physical security. It doesn't store everyone's passwords, only the ones you allow.

### Screenshots
**IFM media created with ntdsutil**

![IFM media created with ntdsutil](images/07-ntdsutil-ifm-media-created.png)

**Promoting PLABDM01 to a DC with the AD DS wizard**

![Promoting PLABDM01 to a DC with the AD DS wizard](images/08-dc-promotion-wizard.png)

**RODC showing in ADUC**

![RODC showing in ADUC](images/09-rodc-in-aduc.png)

**RODC password replication policy**

![RODC password replication policy](images/10-rodc-password-replication-policy.png)

---

## AD design, deployment and Group Policy

### Goal
Build a domain structure across four servers and a Windows 10 client: a root domain, child domains for two sites, a read-only DC, OUs and users. Then use Group Policy to control what software users can run.

### My design
- **Root domain:** `practicelabs.com` on PLABDC01 (Sydney). This is the main DNS and authentication server
- **Child domains:** MEL (on PLABDM01) and BNE (on PLABSA01), one per site
- **RODC:** PLABDCORE01 (Server Core) in the root domain
- **OUs:** one for standard users, one for admin users

### What I built
- Promoted the child domains and the RODC entirely in PowerShell
- Created OUs and users with `dsadd`: a standard user who has to change password at first logon, and an admin user whose password never expires
- **Software GPO:** "Don't run specified Windows applications", linked to the standard users' OU
- **Computer GPO:** "Turn off the Store application", linked to the client
- Checked both with `gpupdate /force` and `gpresult /r`

```powershell
Install-ADDSDomain -DomainType ChildDomain -NewDomainName MEL -ParentDomainName practicelabs.com -InstallDNS -Credential (Get-Credential)
Install-ADDSDomainController -DomainName practicelabs.com -ReadOnlyReplica -SiteName "Default-First-Site-Name" -Credential (Get-Credential)
```

### Troubleshooting
The plan was to block Microsoft Edge with a GPO, but blocking `msedge.exe` did nothing. When I checked the shortcut, Edge on that Windows 10 build was a UWP app (`Microsoft.MicrosoftEdge_8wekyb3d8bbwe`) with no .exe on disk for the policy to match. "Don't run specified applications" only matches executable names. I switched the policy to `iexplore.exe` to prove the GPO worked. In a real environment I'd block a UWP app with AppLocker packaged-app rules instead.

### Screenshots
**AD design**

![AD design](images/11-ad-design-topology.png)

**Child domain promoted in PowerShell**

![Child domain promoted in PowerShell](images/12-child-domain-promoted.png)

**RODC promoted on Server Core**

![RODC promoted on Server Core](images/13-rodc-promoted-server-core.png)

**Domain controllers in ADUC**

![Domain controllers in ADUC](images/14-domain-controllers-aduc.png)

**OUs and user created with dsadd**

![OUs and user created with dsadd](images/15-ou-and-user-created-dsadd.png)

**Password change forced at first logon**

![Password change forced at first logon](images/16-must-change-password-first-logon.png)

**GPO: don't run iexplore.exe**

![GPO: don't run iexplore.exe](images/17-gpo-dont-run-iexplore.png)

**App blocked for the standard user**

![App blocked for the standard user](images/18-app-blocked-for-user.png)

**Edge is a UWP app, not an .exe**

![Edge is a UWP app, not an .exe](images/19-edge-is-uwp-not-exe.png)

**GPO: turn off the Store application**

![GPO: turn off the Store application](images/20-gpo-turn-off-store.png)

**Store blocked on the client**

![Store blocked on the client](images/21-store-blocked.png)

**gpresult /r confirming the policies applied**

![gpresult /r confirming the policies applied](images/22-gpresult-r.png)


