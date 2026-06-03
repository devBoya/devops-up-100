# Student Setup — Windows (Multipass + Ubuntu 24.04 LTS)

Goal: by the end of this guide you have an Ubuntu 24.04 LTS VM on your Windows machine and you've cloned this repository inside it. ~15 minutes from a clean machine.

> The lab assumes **Ubuntu Server 24.04 LTS (Noble Numbat)**. Other distros mostly work but the facilitator can't help debug them.

## 1. Host requirements

| Resource | Recommended host profile |
|---|---|
| CPU | 2 cores free for the VM (CPU virtualization enabled in BIOS/UEFI) |
| RAM | 4 GB free for the VM |
| Disk | 20 GB free |
| Windows | 10 (build 19041+) or 11 — Home or Pro |

Confirm virtualization is on: open Task Manager → Performance → CPU → "Virtualization: Enabled". If it says Disabled, reboot into BIOS/UEFI and enable VT-x (Intel) or AMD-V (AMD).

## 2. Install Multipass (recommended path)

Multipass is Canonical's official tool for running Ubuntu VMs. One binary, works on Home and Pro.

```powershell
# In an elevated (Administrator) PowerShell:
winget install Canonical.Multipass
```

Reopen PowerShell after install so `multipass` is on `PATH`:

```powershell
multipass version
```

Multipass picks Hyper-V on Windows Pro, or falls back to VirtualBox/QEMU on Home. You don't have to choose — let it.

## 3. Create the dedicated host folder

The VM mounts **only** `%USERPROFILE%\devops-lab` from your machine — not your entire user profile. This way, a root command inside the VM can never reach anything outside that folder.

```powershell
New-Item -ItemType Directory -Force -Path $HOME\devops-lab
```

Anything outside `%USERPROFILE%\devops-lab` is invisible to the VM. Treat that folder as the bridge between host and VM.

## 4. Start the lab VM

```powershell
multipass launch 24.04 `
  --name linux-ops-lab `
  --cpus 1 `
  --memory 1G `
  --disk 8G `
  --mount "${HOME}\devops-lab:/home/ubuntu/devops-lab"
```

The first launch downloads the Ubuntu 24.04 cloud image (a few minutes on a fresh machine). The `--mount` flag scopes the host share to exactly one folder. If you need to add or remove mounts after launch, use `multipass mount` / `multipass unmount`.

### Lab VM profile

| Resource | Lab VM profile |
|---|---|
| CPU | 1 |
| RAM | 1 GB |
| Disk | 8 GB |
| Host mount | `%USERPROFILE%\devops-lab` → `/home/ubuntu/devops-lab` (only) |

## 5. Get into the VM

```powershell
multipass shell linux-ops-lab
```

Your prompt should now look like `ubuntu@linux-ops-lab:~$`. From here on, every command runs **inside** the VM unless explicitly marked "on the host".

## 6. Clone the repository

Two equivalent paths — pick one:

**Option A (recommended)** — clone into the shared folder so you can edit on Windows with VS Code and run inside the VM:

```bash
cd ~/devops-lab
git clone https://github.com/devBoya/devops-up-100.git
cd devops-up-100/linux-ops-lab-week1
```

**Option B** — clone into a VM-only location (host stays clean):

```bash
sudo apt-get update && sudo apt-get install -y git
git clone https://github.com/devBoya/devops-up-100.git ~/devops-up-100
cd ~/devops-up-100/linux-ops-lab-week1
```

## 7. Verify you're on Ubuntu 24.04

```bash
uname -a
lsb_release -a
free -h
df -h
```

Expected: `Ubuntu 24.04 LTS` on the `Description:` line.

## 8. Run the installer

```bash
sudo ./install.sh
./healthcheck.sh
curl localhost:8080            # → linux-ops-lab healthy
```

To hit the API from Windows itself (outside the VM), grab the VM's IP:

```powershell
multipass info linux-ops-lab    # look at the "IPv4" line
curl http://<that-ip>:8080
```

## 9. Multipass cheat sheet

```powershell
multipass list                                                  # what VMs do I have
multipass shell linux-ops-lab                                   # open a shell
multipass stop linux-ops-lab                                    # power off, keep state
multipass start linux-ops-lab                                   # power on
multipass delete linux-ops-lab                                  # mark for deletion
multipass purge                                                 # actually free the disk after delete
multipass info linux-ops-lab                                    # IP, status, mounts, disk usage
multipass mount $HOME\devops-lab linux-ops-lab:/home/ubuntu/devops-lab    # re-mount if you launched without --mount
multipass unmount linux-ops-lab:/home/ubuntu/devops-lab         # remove the share
```

> Avoid mounting `%USERPROFILE%` (`$HOME`) wholesale — anything you mount is reachable by root inside the VM.

## Alternatives (use only if Multipass won't run)

| Option | When to pick it | Trade-off |
|---|---|---|
| **WSL2 (Ubuntu 24.04)** | Corporate laptop where you can't install a hypervisor, but WSL2 is allowed | Not a "real" VM — shares kernel with Windows. `systemd` works only with `[boot] systemd=true` in `/etc/wsl.conf` (Windows 11 / WSL ≥0.67). `journalctl -k`, kernel module loading, and some signal handling differ from a real Linux box. Fine for ~80% of the lab; awkward for the rest. |
| **Hyper-V + Ubuntu Server ISO** | Windows Pro, you want the full "install Linux from scratch" experience | More clicks, slower to set up. Great learning moment but doesn't fit a 90-min session. |
| **VirtualBox + Ubuntu Server ISO** | Windows Home where Hyper-V isn't available and Multipass refuses to start | Heaviest of the options. Battle-tested and well-documented. |
| **VMware Workstation Player** | You already have a VMware license | Free for personal use only; corporate use needs a paid license. |

### WSL2 quickstart (fallback)

```powershell
wsl --install -d Ubuntu-24.04
wsl -d Ubuntu-24.04
```

Inside the WSL distro, edit `/etc/wsl.conf` (create it if missing):

```ini
[boot]
systemd=true
```

Then `exit`, run `wsl --shutdown` from PowerShell, reopen the distro. Verify systemd is PID 1:

```bash
ps -p 1 -o comm=        # should print: systemd
```

After that, the rest of the lab (`sudo ./install.sh`, `systemctl status lab-api`, etc.) works largely the same. Caveats:

- `curl localhost:8080` from Windows works because WSL2 forwards loopback.
- Scenario 2 (memory pressure) is less visceral because WSL2 manages memory dynamically.
- `systemctl reboot` will not actually reboot a hypervisor — use `wsl --shutdown` from Windows instead.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `multipass launch` hangs at "Retrieving image" | First-run image download | Wait — first boot can take 3–5 min on slow links |
| `launch failed: CPU does not support KVM extensions` | Virtualization disabled in BIOS | Reboot into BIOS/UEFI, enable VT-x or AMD-V |
| `Hyper-V is not available` on Home edition | Multipass needs a hypervisor backend | Install VirtualBox first, then `multipass set local.driver=virtualbox` |
| `curl localhost:8080` fails from Windows | Multipass doesn't forward ports by default | Use `multipass info`'s IP, or set up `multipass exec` proxying |
| `lsb_release` shows 22.04 | Used an old image name | `multipass delete linux-ops-lab && multipass purge && multipass launch 24.04 --name linux-ops-lab` |
| "Permission denied" on `install.sh` | Forgot `chmod +x` after clone | `chmod +x install.sh scripts/*.sh && sudo ./install.sh` |
| WSL2: `systemctl status` says "System has not been booted with systemd" | `systemd=true` not set or WSL not restarted | Edit `/etc/wsl.conf`, run `wsl --shutdown` from PowerShell, reopen |
