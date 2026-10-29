# IT Support Home Labs

Hands-on labs for L1/L2 IT service desk work, built and broken on purpose in a fictional aged care provider, **Banksia Aged Care**.

The servers, domain, policies and logs in these labs are real and built by me. The user calls and fault stories are role-played. Each module has the setup, the problems I hit, how I diagnosed and fixed them, and screenshots as evidence. Where something is simulated (for example Cisco Packet Tracer), the module says so.

## Modules

| Module | What I did | Tools and keywords |
|---|---|---|
| [1. ServiceNow ITSM](./module-01-servicenow-itsm/) | Logged, prioritised, escalated and resolved incidents (including a P1 outage with child incidents), split an incident from a service request, wrote a knowledge article | ServiceNow, incident management, SLA, impact/urgency, knowledge base |
| [2. End User Device Support](./module-02-end-user-device-support/) | Built a Windows 11 VM, added a data drive, diagnosed a slow PC in Task Manager, traced unexpected shutdowns in Event Viewer, restored a deleted file from backup | Windows 11, VMware, Event Viewer, Disk Management, backup and restore |
| [3. Active Directory](./module-03-active-directory/) | Built a domain controller, joined a PC, designed OUs and groups, delegated password resets, set lockout and logon-notice GPOs, investigated a lockout via Event 4740, handled a leaver | Active Directory, Windows Server 2025, Group Policy, DNS, RSAT, least privilege |
| [4. Microsoft 365 and Cloud](./module-04-m365/) | Group-based licensing, shared mailboxes, distribution lists, leaver process, sign-in log troubleshooting, MFA reset, Helpdesk Administrator role, Teams and SharePoint permissions, Azure budget and Reader role | Microsoft 365, Entra ID, Exchange Online, SharePoint, Teams, Azure RBAC |
| [5. Network and Internet Support](./module-05-networking/) | DHCP and DNS on a Windows server, fixed a full scope, wrong gateway, wrong DNS and an IP conflict; VLANs and router-on-a-stick, SOHO Wi-Fi and WAN routes (Packet Tracer); WireGuard VPN | DHCP, DNS, TCP/IP, VLAN, `ipconfig`, `nslookup`, `tracert`, WireGuard |
| [6. Company File Sharing](./module-06-file-sharing/) | Departmental shares with share and NTFS permissions, access-based enumeration, drive maps by GPO, Previous Versions, a NAS with RAID1 | NTFS permissions, file shares, Group Policy, `icacls`, RAID1, OpenMediaVault |
| [7. Backup, Endpoint Protection and Printing](./module-07-backup-endpoint-printing/) | Print server with GPO-deployed printers, Defender policy and an EICAR false-positive exclusion, Windows Server Backup to a NAS with a restore verified by file hash, a backup failure from a rotated service-account password | Print server, Microsoft Defender, Windows Server Backup, `wbadmin`, RPO/RTO |

## Lab environment

- **Hypervisor:** VMware Workstation, with Windows Server 2025 (`banksia.local`) and Windows 11 Enterprise VMs
- **NAS:** OpenMediaVault with a RAID1 mirror
- **Ticketing:** ServiceNow Personal Developer Instance
- **Cloud:** Microsoft 365 Business Premium trial and an Azure free account
- **Network simulation:** Cisco Packet Tracer

[LinkedIn](www.linkedin.com/in/shristi-tuladhar) · [Email](shristi.tuladhar@outlook.com)
