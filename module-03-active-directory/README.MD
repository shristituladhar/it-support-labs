# Module 3: Active Directory

All tickets are **simulated scenarios** set in **Banksia Aged Care**, a fictional aged care provider. The domain, accounts, policies and logs are real and built by me; the user calls are role-played.

## Summary

Built a Windows Server 2025 domain controller (banksia.local), joined a Windows 11 PC to it, and handled realistic Service Desk work (a new starter, a locked-out user and a leaver), each tracked as a ServiceNow ticket.

**Skills shown:** AD DS installation · DNS · domain join · OU design · users and security groups · delegation (least privilege) · RSAT · Group Policy · account lockout policy · audit policy and Security log investigation

## Environment

| Item | BANKSIA-DC01 (server) | BANKSIA-PC01 (staff PC) |
|---|---|---|
| OS | Windows Server 2025 Standard Evaluation (Desktop Experience) | Windows 11 Enterprise Evaluation (Module 2) |
| Role | Domain controller + DNS | Domain-joined workstation |
| IP address | 192.168.126.10 (fixed) | Automatic |
| Gateway | 192.168.126.2 | Automatic |
| DNS | 127.0.0.1 (itself), forwarder 192.168.126.2 | 192.168.126.10 (DC01) |
| Domain | banksia.local | Joined |

## Key terms

| Term | Meaning |
|---|---|
| **Active Directory (AD)** | Central directory of an organisation's users, computers, groups and permissions |
| **Domain controller (DC)** | The server that runs AD and checks every login |
| **OU** | A folder for organising accounts; policies and permissions apply to it |
| **Security group** | Users given access together |
| **Delegation** | Giving a group limited admin powers over part of AD |
| **GPO** | A set of settings pushed from the DC to computers or users |
| **RSAT** | Tools that let an IT PC manage AD without logging in to the server |

---

## Part 1: Building the domain

**What I did:** installed Windows Server 2025, renamed it DC01, gave it a fixed IP, added the **Active Directory Domain Services** role, and created the domain **banksia.local** (which also installed DNS).

**Why a fixed IP:** every PC finds the domain by contacting the DC. If its address changed after a restart, no one could log in. I used .10 because it sits outside VMware's automatic address range, so nothing else gets the same address.

**Why a DNS forwarder:** PCs use DC01 for DNS. DC01 knows the names inside banksia.local, but the forwarder tells it where to send lookups for outside websites. Without it, staff could log in but not browse the web.

DC01 named and given its fixed IP. *(Taken before the domain existed, so it shows WORKGROUP. The time zone was corrected from US Pacific to Sydney later; see Part 6.)*

![DC01 configured](images/01-dc01-configured.jpg)

The banksia.local domain in Active Directory Users and Computers.

![Domain created](images/02-domain-created.jpg)

*Real world: Microsoft recommends a subdomain of a domain the organisation owns (e.g. ad.banksiacare.com.au); `.local` is common in labs.*

## Part 2: Joining PC01 to the domain

**What I did:** pointed PC01's DNS at DC01, checked with `nslookup banksia.local`, renamed it **BANKSIA-PC01** and joined it to the domain.

**Why DNS first:** a PC finds the domain controller through DNS. If PC01 used an internet DNS server, it could never find banksia.local, and the join would fail with "domain controller could not be contacted." Domain PCs must use the DC for DNS.

PC01 successfully joined to banksia.local.

![PC01 joined](images/03-pc01-joined.jpg)

**Local vs domain accounts:** PC01 now has its **local** account from Module 2 (`.\labadmin`, works only on PC01) and **domain** accounts (`BANKSIA\username`, work on any domain PC). I kept labadmin as a backup login in case PC01 loses contact with the domain. Real organisations manage these with **LAPS**, which gives each PC a unique, rotating local admin password.

## Part 3: OUs, users and groups

**What I did:** built the OU structure below, moved PC01 into Banksia\Computers, created four security groups, and added staff to the matching OU and group.
```
Banksia
├── Computers        (BANKSIA-PC01)
├── Disabled Users   (leavers)
├── Groups           (Clinical Staff, Care Managers, Admin Office, Service Desk)
├── IT               (Shristi Tuladhar – Service Desk)
└── Staff
    ├── Admin        (Sabrina Deppert)
    ├── Clinical     (Fred Luddy, Jade Erlebach, Agency RN)
    └── Management   (Beth Anglin)
```


**Why this design:**
- Policies and permissions apply by OU. The logon notice targets only Banksia\Computers, and the Service Desk manages only Staff.
- **IT** sits outside **Staff** on purpose, so the Service Desk can't reset IT accounts.
- PC01 was moved because the built-in Computers folder is a **container**, not an OU, and Group Policy can't be linked to it.

**Why groups:** access is given to **groups, not individuals**. Adding a new nurse to Clinical Staff gives them everything nurses need; removing them takes it all away.

New accounts are set to **change password at next logon**, so only the user knows their final password. Usernames follow **first initial + surname** (e.g. fluddy).

The OU structure, with PC01 in Banksia\Computers.

![OU structure](images/04-ou-structure.jpg)

Fred's group membership: Clinical Staff plus the default Domain Users.

![Fred's groups](images/06-user-groups-fred.jpg)

## Part 4: New starter request

**Scenario:** Beth Anglin (Care Manager) requests an account for new RN Jade Erlebach, the same kind of task as Module 1's new starter ticket, done for real this time.

**What I did:** logged a **service request** (a planned task, not a fault), created Jade's account in Staff\Clinical, added her to Clinical Staff, set a temporary password, and closed the request with a work note and an update to Beth. The temporary password went to the manager in person, never into the ticket.

Jade's new account in Staff\Clinical.

![Jade's account](images/07a-jade-account.jpg)

The request closed with a work note and an update to the manager.

![New starter ticket](images/07b-ticket-new-starter.jpg)

## Part 5: Delegating password resets to the Service Desk

**What I did:** used **Delegate Control** on the Staff OU to give the Service Desk group two rights:
1. Reset passwords and force a change at next logon
2. Read and write **lockoutTime**, which lets them see whether an account is locked and unlock it (AD sets this field when an account locks, and unlocking sets it back to 0)

**Why:** the Service Desk resets passwords and unlocks accounts all day, but making them Domain Admins would let them delete accounts or change anything. Delegation gives exactly what the job needs, only over staff accounts. This is **least privilege**: if a Service Desk account were misused or hacked, the damage would be limited.

The delegation wizard summary.

![Delegation](images/08-delegation.jpg)

**Testing it:** I installed **RSAT** on PC01 (as Administrator, since installing Windows features needs admin rights), then logged in as my Service Desk account. The Settings app didn't list RSAT, so I installed it with PowerShell:
`Add-WindowsCapability -Online -Name Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0`

I tested from PC01 because normal accounts can't log in to a domain controller directly. That's also how it works in real jobs: Service Desk staff use RSAT on their own PC, and RSAT is deployed only to IT devices.

As the Service Desk account, resetting Fred's password **worked**.

![Reset allowed](images/09a-delegation-test1.jpg)

Deleting Fred was **blocked**, because deletion was never delegated. Having the tool doesn't grant power; permissions in AD do.

![Delete denied](images/09b-delegation-test2.jpg)

## Part 6: Group Policy and auditing

### Account lockout policy
Set in the **Default Domain Policy**: lock after **5** wrong passwords, unlock automatically after **10 minutes**.

**Why:** it stops attackers guessing passwords. The trade-off is that lockouts become a common Service Desk call (see Part 7).

The lockout settings.

![Lockout policy](images/05b-lockout-policy.jpg)

### Logon notice GPO
Created **Clinical PCs - Logon Notice**, linked to Banksia\Computers, displaying before login:
*"Banksia Aged Care – Authorised Use Only. This system contains confidential resident information. Access is monitored. Lock the screen or log out when leaving the workstation."*

**Why:** healthcare organisations remind staff before every login that the system holds confidential information and is monitored. It's also visible proof that a policy set on the DC reached the PC.

The two message settings in the GPO.

![GPO settings](images/10a-gpo-settings.jpg)

On PC01 I ran `gpupdate /force` and restarted. PCs normally check for new policies at startup and about every 90 minutes; this applies them immediately. The restart brings back the login screen where the notice appears.

The notice on PC01 before login.

![Logon notice](images/10b-logon-notice.jpg)

`gpresult /r /scope computer` lists the policies actually applied. It's the first thing to check when someone says a policy isn't working.

gpresult showing the GPO applied to PC01.

![gpresult](images/11-gpresult.jpg)

### Audit policy
Set in the **Default Domain Controllers Policy** (Advanced Audit Policy), Success and Failure for:
- **Kerberos Authentication Service:** wrong passwords at the DC (Event 4771)
- **User Account Management:** accounts created, reset, disabled or locked (4720, 4724, 4725, 4740)
- **Logon:** logons to the DC

**Why:** audit logs record who did what and when. Without them, nobody could prove who changed an account or where failed logins came from, which matters in healthcare. Before using the logs, I changed DC01's time zone from US Pacific to **Sydney**, so entries show the correct local time.

The audit settings.

![Audit policy](images/05a-audit-policy.jpg)

## Part 7: Locked-out user

**Scenario:** Fred calls saying he can't log in.

**What I did:**
1. Entered a wrong password for `BANKSIA\fluddy` five times, which locked the account.
2. Logged an incident: Impact 3 (one person), Urgency 1 (can't work).
3. Confirmed the lockout in ADUC.
4. Filtered the DC's Security log for **Event 4740**. **Caller Computer Name: BANKSIA-PC01** showed where the failed attempts came from.
5. Verified identity, unlocked the account, reset the password with change at next logon, and resolved the ticket.

**Why check 4740:** it shows **where** the bad attempts came from. If the source is a device the user isn't using (often a phone with an old saved password), unlocking alone won't help; they'll be locked out again until that device is updated.

**Why reset as well as unlock:** if Fred has forgotten his password, unlocking isn't enough, and forcing a change means only he knows the final one. Identity is always verified first, or anyone could phone pretending to be Fred.

The lockout message on PC01.

![Locked at login](images/12a-account-locked.jpg)

Fred's account showing as locked in ADUC.

![Locked in ADUC](images/12b-account-locked.jpg)

Event 4740: fluddy locked out, source BANKSIA-PC01.

![Event 4740](images/13-event-4740.jpg)

The incident resolved with the findings and fix.

![Lockout ticket](images/14-ticket-lockout.jpg)

## Part 8: Leaver

**Scenario:** the agency RN's contract has ended.

**What I did:** logged a service request, then **disabled** the account, removed it from Clinical Staff, added a description with the request number, and moved it to Disabled Users.

**Why disable instead of delete:** a disabled account can't log in, but its history is kept and it can be restored if needed. Deleting it would lose the audit trail. Removing the group means that if it's ever re-enabled by mistake, the old access doesn't come back. Accounts are usually deleted after a set retention period (e.g. 30–90 days).

The disabled account in Disabled Users.

![Leaver disabled](images/15-leaver-disabled.jpg)

**Audit check:** filtering the Security log for 4720, 4724, 4725, 4740 and 4771 shows the whole lab in order:

| Time | Event | What happened |
|---|---|---|
| 10:48 | 4720 | Jade's account created |
| 11:41 | 4724 | Fred's password reset by the Service Desk account (delegation test) |
| 11:57 | 4771 ×5 | Fred's five wrong passwords |
| 11:57 | 4740 | Fred's account locked |
| 12:05 | 4724 (failure) ×2 | Two reset attempts refused, most likely because the password didn't meet the complexity rules |
| 12:05 | 4724 | Fred's password reset by Administrator (lockout fix) |
| 12:10 | 4725 | Agency RN disabled |

Each event's **Subject** shows who made the change, so every action, including failed attempts, can be traced to a person.

The filtered Security log, with an event open showing who performed it.

![Audit events](images/16-audit-events.jpg)

The leaver request closed with a full work note.

![Leaver ticket](images/17-ticket-leaver.jpg)

---

## What I learned

- **DNS is the foundation of a domain:** the DC needs a fixed IP and must be the PCs' DNS server.
- **OUs organise, groups grant access:** policies and delegation apply to OUs, access is given to groups.
- **Least privilege works:** the Service Desk could reset a password but not delete the same account.
- **Tools don't give power, permissions do:** RSAT is harmless without delegated rights.
- **Group Policy isn't instant:** `gpupdate /force` applies it now, and `gpresult` confirms it.
- **Lockouts need investigating, not just unlocking:** Event 4740 shows the source.
- **Leavers are disabled, not deleted,** so access is removed but the history stays.
- **Audit logs make every change traceable,** including failures.

