# Module 2: End User Device Support

All tickets are **simulated scenarios** set in **Banksia Aged Care**, a fictional aged care provider. The ServiceNow tickets and the Windows work are real; the calls and fault stories are role-played. In a real workplace I'd connect to the user's PC with a remote tool such as TeamViewer; here I worked directly in the VM.

## Environment

| Item | Detail |
|---|---|
| Host | Laptop with 16 GB RAM |
| Hypervisor | VMware Workstation Pro (free for personal use) |
| Guest OS | Windows 11 Enterprise Evaluation (90-day), local account |
| Virtual PC | BANKSIA-PC01: 2 CPUs, 5 GB RAM, 64 GB disk, virtual TPM, NAT network |
| Ticketing | ServiceNow Personal Developer Instance (see Module 1) |

VM files are stored outside OneDrive, because syncing a running virtual disk can corrupt it.

## Setup: building BANKSIA-PC01

Installed Windows 11 from an ISO with a **local account** (work PCs don't use personal Microsoft accounts), ran Windows Update until up to date, then took a **snapshot** so I could return to a clean PC after breaking things on purpose.

VM hardware: 2 CPUs, 5 GB RAM, 64 GB disk and a virtual TPM (required by Windows 11).

![VM settings](images/01-vm-settings.jpg)

Installing onto the empty virtual disk (Disk 0, unallocated). The laptop's own drive isn't touched.

![Choosing the install disk](images/02-install-disk.jpg)

`winver` confirms the installed edition and build.

![Windows version](images/03-windows-installed.jpg)

Windows Update run until up to date, so the PC is patched before any other work.

![Windows Update complete](images/04-windows-update.jpg)

Snapshot of the clean, updated PC, used as a restore point before breaking things on purpose.

![Snapshot](images/05-snapshot.jpg)

**Setup problems and fixes**

| Problem | Fix |
|---|---|
| VirtualBox (my first hypervisor): black screen at first boot | Changed the Graphics Controller to VMSVGA; boot text then appeared |
| VirtualBox: "failed to boot, no bootable option" | I had missed the "Press any key" prompt; mounted the ISO from the dialog and retried |
| VirtualBox: screen would not resize after repeated Guest Additions installs | Switched to VMware Workstation, where VMware Tools sized the screen |
| VMware: "Could not create anonymous paging file for 6144 MB" | Not enough free host memory; reduced the VM from 6 GB to 5 GB |

## Part 1: Add a data drive

**Why:** In real workplaces, user data is often kept on a separate drive from Windows. If Windows breaks and the PC has to be rebuilt, the data drive survives. Adding and preparing a new drive is also a routine upgrade task when a PC runs low on storage. In this lab, the Data drive is also the backup destination used in Part 4.

**What I did:** Added a 20 GB virtual disk, then set it up in Disk Management:
- **Initialised it as GPT**: a new disk is blank, and Windows has to prepare it before use. GPT is the modern partition style used on current PCs (MBR is the older one).
- **Created a volume and formatted it NTFS** (label Data): NTFS is the standard Windows file system, supporting permissions and large files.
- **Assigned a drive letter**: it took E: because D: is the DVD drive.

Disk Management showing the original Windows disk (Disk 0) and the new Data drive (Disk 1, E:).

![New data drive](images/06-new-data-drive.jpg)

## Part 2: Slow PC (INC0010022)

**Scenario:** the nurses' station PC is extremely slow.

**Why:** "My PC is slow" is one of the most common tickets. The first step is finding what is using the computer's resources, rather than guessing or restarting straight away.

**What I did:** I simulated a stuck program using two PowerShell loops (`while($true){}`), commands that run forever and keep the processor busy, like a frozen app would. In Task Manager, sorted by CPU, total CPU was 99% with two PowerShell processes at about 46% each. I ended both and CPU dropped to 8%. I added a work note and a plain-English comment to the caller, then resolved the ticket.

Task Manager sorted by CPU: total usage at 99%, with two PowerShell processes using about 46% each.

![Diagnosis](images/07-slow-diagnosis.jpg)

After ending both processes, CPU usage dropped back to 8%.

![After ending the processes](images/08-slow-fixed.jpg)

Ticket timeline: internal work note, plain-English update to the caller, and resolution.

![Ticket](images/09-ticket-slow.jpg)

**Real-world note:** a hung process is only one cause. The same check in Task Manager also shows high memory use (too many apps open or not enough RAM) or high disk use (updates, scans or a failing drive), each with a different fix.

## Part 3: PC switching off by itself (INC0010024)

**Scenario:** the PC has turned off twice without warning.

**Why:** staff can't tell whether a PC switched off because of a crash, an update or a power problem, and each needs a different fix. The Windows logs record what actually happened, so I checked the evidence before changing anything.

**What I did:** I simulated power loss with **VM > Power > Power Off** twice, plus one normal restart for comparison. In Event Viewer (System log, filtered to Event IDs 41, 6008 and 1074):

| Event ID | Meaning | What I saw |
|---|---|---|
| 41 (Kernel-Power) | Windows restarted without a clean shutdown | Two entries |
| 6008 | The previous shutdown was unexpected | One within seconds of each 41 |
| 1074 | A planned restart | My normal restart |

This is consistent with a sudden loss of power rather than a normal restart. In a real case I'd also check for crash events and the physical power connection. The ticket recommends checking the power connection and using a UPS for clinical workstations.

System log filtered to Event IDs 41, 6008 and 1074: two unexpected shutdowns and one planned restart.

![Event Viewer](images/10-event-viewer.jpg)

Ticket with the findings and recommendations (check the power connection, UPS for clinical workstations).

![Ticket](images/11-ticket-shutdowns.jpg)

## Part 4: Restore a deleted file (INC0010025)

**Scenario:** a staff roster file was deleted and the Recycle Bin emptied.

**Why:** restoring deleted or overwritten files is one of the most frequent L1 requests. It only works if backups were set up beforehand, so the job covers both configuring a backup and recovering from it.

**What I did:** File History would not accept the second virtual disk ("Reconnect your drive"), so I used **Backup and Restore (Windows 7)** instead. My first run included a system image and failed for lack of space on the 20 GB drive. I unticked it and backed up Documents only. Then I deleted `Staff-roster.txt`, emptied the Recycle Bin and restored it from the backup.

Backup of Documents to the Data drive (E:) completed successfully.

![Backup complete](images/12-backup-complete.jpg)

Staff-roster.txt after restoring from the backup. The file had been deleted and the Recycle Bin emptied beforehand.

![File restored](images/13-file-restored.jpg)

Ticket closed with the restore confirmed.

![Ticket](images/14-ticket-restore.jpg)

**Real-world note:** a backup on a drive inside the same PC doesn't protect against theft, fire or ransomware. Real backups follow the **3-2-1 rule** (3 copies, 2 types of storage, 1 off-site) and are usually run centrally, for example with OneDrive or SharePoint for user files. This lab shows the idea at small scale.

## Further notes (not lab-tested)

These cover syllabus topics that can't be practised in a VM. They are
study notes, not hands-on work.

### Common hardware faults: first checks

| Symptom | Likely cause | First check |
|---|---|---|
| No power at all | Power cable, power strip or PSU | Try another outlet and cable |
| Powers on, no display | Monitor cable or input, loose RAM | Test another monitor, reseat the RAM |
| Random restarts or blue screens | Faulty RAM, overheating or a failing PSU | Windows Memory Diagnostic, check temperatures, Event Viewer |
| Very slow, disk at 100%, clicking noise | Failing hard drive | Back up first, check SMART status, replace (SSD upgrade) |
| Loud fan or hot case | Dust or a failed fan | Clean it, check the fan spins |
| "No bootable device" | Boot order, loose cable or failed disk | Check the boot order in BIOS, then the disk |

Before any hardware work: back up the data, power off and unplug (remove
the battery on laptops), and use anti-static care. When upgrading RAM,
match the type (e.g. DDR4 or DDR5) to what the board supports.

### BIOS and driver updates

- **Why:** stability, security fixes and hardware compatibility.
- **BIOS/firmware:** check the current version (`msinfo32`), download
  from the PC maker's site, read the release notes, back up first, keep
  the laptop on mains power, and suspend BitLocker beforehand so it
  doesn't ask for the recovery key. Never interrupt the update. In a
  managed workplace it is deployed through the maker's tool or the
  management platform, to a small test group first.
- **Drivers:** update through Windows Update or the maker's site. If a
  new driver breaks something (for example no network after a network
  driver update), use Device Manager > Properties > Driver > **Roll Back
  Driver**. Take a snapshot or restore point first.
- A VM uses virtual hardware, so BIOS updates don't apply to it.

### Imaging and deployment (concept)

- **Golden image:** one fully set-up PC used as the template for others.
- **Sysprep** removes machine-specific details (name, identity) so each
  copy gets its own when deployed. Cloning a PC without it can cause
  duplicate-identity problems.
- **Capture and deploy:** capture the image (e.g. with DISM), then deploy
  it with tools such as MDT, WDS or Intune Autopilot. For a like-for-like
  hardware swap, a disk-cloning tool such as Clonezilla also works.
- **User data:** move it separately (e.g. OneDrive Known Folder Move or
  USMT) so a rebuild doesn't lose files.
- Many workplaces now use Autopilot instead of building images.

## Key terms

- **Virtual machine (VM):** a full computer running inside a window on another computer.
- **Snapshot:** a save point for a whole VM that lets you roll back after changes.
- **Local account:** a login that exists only on that PC, not tied to a Microsoft account.
- **TPM:** a security chip that Windows 11 requires; the VM provides a virtual one.
- **GPT / NTFS:** the partition style and file system used to set up the new drive.
- **Hung process:** a program that has stopped responding but keeps using resources.
- **Kernel-Power 41 / Event 6008:** Windows log entries recorded when a PC shuts down without warning.
- **Event 1074:** the log entry for a planned restart.

## What I learned

- "PC is slow": check Task Manager first (CPU, memory, disk) before changing anything.
- "PC keeps turning off": Event Viewer tells you whether it was a planned restart (1074) or a sudden loss of power (41 and 6008).
- A backup on the same PC isn't enough; follow 3-2-1.
- When a tool fails (File History here), say what happened, switch to another that does the job, and document it.
- A snapshot makes it safe to break things and recover quickly.
