# Active Directory

**Environment:** Windows Server 2016 domain `practicelabs.com`. PLABDC01 (domain controller), PLABDM01 and PLABSA01 (member servers), PLABDCORE01 (Server Core) and PLABWIN10 (Windows 10 client).

## Contents
- [1. Account management and offline domain join](#1-account-management-and-offline-domain-join)
- [2. IFM, RODC and password replication](#2-ifm-rodc-and-password-replication)
- [3. AD design and Group Policy](#3-ad-design-and-group-policy)

---

## 1. Account management and offline domain join

### Scenario
A server needs to rejoin the domain while it can't reach a domain controller. The domain also needs account lockout protection and a way to find accounts that are locked, disabled or unused.

### What I did
**Offline domain join**
1. Removed PLABSA01 from the domain and deleted its computer object in ADUC
2. On the DC, ran `djoin /provision` to pre-create the computer account and save it to a blob file
3. Copied the blob to PLABSA01 over a mapped network drive
4. Paused the DC so PLABSA01 had no DC to talk to, then ran `djoin /requestODJ` and restarted
5. Resumed the DC and confirmed PLABSA01 was back in the domain

**Account lockout and clean-up**
- Set an account lockout threshold in Group Policy, then locked a test user out on purpose from the Windows 10 client
- Used PowerShell to find locked-out, disabled and inactive accounts, and re-enabled a disabled account

**User rights**
- Set "Allow log on locally" and "Allow log on through Remote Desktop Services" for specific security groups, and added a group to Remote Desktop Users

### Commands
```powershell
# Offline domain join
djoin /provision /domain practicelabs.com /machine PLABSA01 /savefile c:\plabsa01.txt   # on the DC
djoin /requestODJ /loadfile c:\plabsa01.txt /windowspath %SystemRoot% /localos         # on PLABSA01
shutdown /r /t 0

# Account checks
Search-ADAccount -LockedOut
Search-ADAccount -AccountDisabled
Enable-ADAccount -Identity <username>
Search-ADAccount -AccountInactive -UsersOnly -TimeSpan 1.00:00:00 | ft name
```

### How I checked it worked
- PLABSA01 showed under Computers in ADUC after the restart, without ever contacting the DC during the join
- The client showed the "account is locked out" message, and `Search-ADAccount -LockedOut` returned that user

### Where this applies
Lockouts are one of the most common service desk tickets. Offline join is useful when a machine is built somewhere it can't reach a DC, like an imaging network or a remote site.

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

## 2. IFM, RODC and password replication

### Scenario
Add domain controllers without copying the whole AD database over the network, and set up a read-only DC for a less secure site that only caches the passwords it needs.

### What I did
**Install from media (IFM)**
1. On PLABDC01, created IFM media with `ntdsutil`, which takes a snapshot of the AD database and SYSVOL
2. Shared the media to PLABDM01 and promoted it to a domain controller using that copy, so only changes since the snapshot had to replicate

**Read-only domain controller**
1. Installed AD DS on PLABSA01 and promoted it as an RODC with PowerShell
2. Created a "VPN Users" group and added it to the Allowed RODC Password Replication Group
3. Set the RODC's password replication policy and prepopulated passwords for specific users, so they can log on at that site even if the link to a writable DC is down

### Commands
```
ntdsutil
  activate instance ntds
  ifm
  create sysvol full C:\IFM
```
```powershell
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools
Install-ADDSDomainController -DomainName practicelabs.com -ReadOnlyReplica `
  -SiteName "Default-First-Site-Name" -Credential (Get-Credential)
```

### How I checked it worked
- Both new DCs showed under Domain Controllers in ADUC, with PLABSA01 as read-only
- The Advanced Password Replication Policy on the RODC showed which accounts' passwords were stored

### Troubleshooting
The test user didn't show under "Accounts that have been authenticated to this RODC". The Windows 10 client failed to log on with a domain trust relationship error, so the RODC never saw an authentication from it. The fix for a broken trust is `Test-ComputerSecureChannel -Repair` on the client, or rejoining it to the domain.

### Where this applies
An RODC goes in a branch office with weak physical security. If it's stolen, only the passwords you allowed are exposed. IFM saves bandwidth when building DCs at sites with slow links.

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

## 3. AD design and Group Policy

### Scenario
Design and build a domain for one head office and two sites, then use Group Policy to control what users can run.

### Design
| Server | Role |
|---|---|
| PLABDC01 | Root domain `practicelabs.com` (Sydney), primary DNS and authentication |
| PLABDM01 | Child domain DC for MEL |
| PLABSA01 | Child domain DC for BNE |
| PLABDCORE01 | Read-only DC on Server Core |
| PLABWIN10 | Domain client for testing |

I used two OUs, one for standard users and one for admin users, so policies could target each group separately.

### What I did
1. Promoted both child domains and the RODC entirely in PowerShell
2. Created the OUs and users with `dsadd`:
   - a standard user who must change their password at first logon
   - an admin user (in Domain Admins) whose password never expires
3. **User GPO:** "Don't run specified Windows applications", linked to the standard users' OU
4. **Computer GPO:** "Turn off the Store application", linked to the Windows 10 client
5. Ran `gpupdate /force` and tested both users on the client

### Commands
```powershell
Install-ADDSDomain -DomainType ChildDomain -NewDomainName MEL -ParentDomainName practicelabs.com `
  -InstallDNS -Credential (Get-Credential)
Install-ADDSDomainController -DomainName practicelabs.com -ReadOnlyReplica `
  -SiteName "Default-First-Site-Name" -Credential (Get-Credential)

gpupdate /force
gpresult /r
```

### How I checked it worked
- The blocked app was stopped for the standard user but still opened for the admin user, because the user policy only applied to the standard users' OU
- The Store was blocked for both users, because that one was a computer policy and applies to anyone on that machine
- `gpresult /r` listed which GPOs applied to each user

### Troubleshooting
Blocking Microsoft Edge with "Don't run specified Windows applications" did nothing. Checking the Edge shortcut showed it was a UWP app (`Microsoft.MicrosoftEdge_8wekyb3d8bbwe`) with no `.exe` on disk, and that policy only matches executable names. I pointed the policy at `iexplore.exe` instead to prove the GPO worked. Blocking a UWP app properly needs AppLocker packaged-app rules.

### Where this applies
"Why can this user still open X?" is a common Group Policy ticket. The fix usually comes down to checking scope (user vs computer, which OU), then confirming what applied with `gpresult`.

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
