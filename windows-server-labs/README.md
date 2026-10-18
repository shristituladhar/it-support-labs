# Windows Server Labs

Hands-on Windows Server administration across two areas: **Active Directory** and **Hyper-V / failover clustering**. Each page covers the scenario, what I built, the commands I used, how I checked it worked, and what went wrong along the way.

| Page | Covers |
|---|---|
| [Active Directory](active-directory.md) | Offline domain join, account lockout and clean-up, user rights, DC from IFM, RODC and password replication, multi-domain design, Group Policy |
| [Hyper-V and Failover Clustering](hyper-v.md) | VM sizing, nested virtualisation, vSwitches, 2-node failover cluster on iSCSI storage, live migration, changes on a live cluster, Docker |

## Skills covered
| Area | What I did |
|---|---|
| Accounts and access | Domain join (online and offline), account lockout policy, locked, disabled and inactive accounts, user rights assignment, OUs and users |
| Domain services | DC promotion, install from media (IFM), read-only DC and password replication policy, child domains, DNS |
| Group Policy | Software and Store restrictions, linking GPOs to OUs and computers, checking results with `gpupdate` and `gpresult` |
| Virtualisation | Sizing VMs to user needs and host limits, nested virtualisation, internal vSwitches, static IPs |
| High availability | Failover Clustering, iSCSI target and initiators, Cluster Shared Volumes, quorum, live migration, change requests |
| Containers | Docker Compose, Windows NAT, building, pushing and pulling images |
| Scripting | PowerShell for AD, networking, Hyper-V and clustering, plus `djoin`, `ntdsutil` and `dsadd` |

## Lab environment
- **AD labs:** Windows Server 2016 domain with 4 servers and a Windows 10 client
- **Hyper-V labs:** Windows Server Hyper-V host (8 vCPU, 32 GB RAM) running Windows Server VMs with nested virtualisation

## How this maps to support work
| Ticket | Where I've done it |
|---|---|
| "I'm locked out" | Finding and checking locked accounts with `Search-ADAccount` |
| "This PC can't join the domain" | Online and offline domain join, DNS pointing at the DC |
| "User can still open an app they shouldn't" | GPO scope (user vs computer settings) and `gpresult /r` |
| "Branch office needs a DC but the site isn't secure" | RODC with a limited password replication policy |
| "The server went down. Is the app still up?" | Failover cluster and live migration between nodes |

Related module: Module 3 (Active Directory).
