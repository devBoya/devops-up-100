# Student Setup — Linux (Multipass + Ubuntu 24.04 LTS)

Goal: by the end of this guide you have an Ubuntu 24.04 LTS VM on your Linux machine and you've cloned this repository inside it. ~10 minutes from a clean machine.

> The lab assumes **Ubuntu Server 24.04 LTS (Noble Numbat)**. Other distros mostly work but the facilitator can't help debug them.
>
> **"But I'm already on Linux — why do I need a VM?"** Because the scenarios deliberately break things at the systemd/permissions/CPU level. You do *not* want to run `make break-memory` against your real workstation. The VM keeps blast radius zero.

## 1. Host requirements

| Resource | Recommended host profile |
|---|---|
| CPU | 2 cores free, with KVM extensions enabled (VT-x / AMD-V) |
| RAM | 4 GB free for the VM |
| Disk | 20 GB free |
| Distro | Any modern Linux — Ubuntu, Fedora, Arch, Debian, openSUSE, etc. |

Confirm KVM is available:

```bash
egrep -c '(vmx|svm)' /proc/cpuinfo    # >0 means CPU supports it
lsmod | grep kvm                       # kvm + kvm_intel/kvm_amd should be loaded
```

If both are good, you can use any of the options below. If KVM isn't loaded, you'll be limited to VirtualBox or QEMU-TCG (slow).

## 2. Install Multipass (recommended path)

Multipass is Canonical's official tool for running Ubuntu VMs. One command, works on every distro.

```bash
sudo snap install multipass             # Ubuntu, Fedora (with snapd), most distros
# OR — on distros without snap, use the official tarball from
# https://canonical.com/multipass/install
```

Verify:

```bash
multipass version
```

Multipass uses QEMU+KVM on Linux by default.

## 3. Create the dedicated host folder

The VM mounts **only** `~/devops-lab/` from your host — not your entire home directory. This way, a root command inside the VM can never reach anything outside that folder.

```bash
mkdir -p ~/devops-lab
```

Anything outside `~/devops-lab/` is invisible to the VM. Treat that folder as the bridge between host and VM.

## 4. Start the lab VM

```bash
multipass launch 24.04 \
  --name linux-ops-lab \
  --cpus 1 \
  --memory 1G \
  --disk 8G \
  --mount "$HOME/devops-lab:/home/ubuntu/devops-lab"
```

First launch downloads the Ubuntu 24.04 cloud image (a few minutes on a fresh machine). The `--mount` flag scopes the host share to exactly one folder. Use `multipass mount` / `multipass unmount` afterwards to add or remove shares.

### Lab VM profile

| Resource | Lab VM profile |
|---|---|
| CPU | 1 |
| RAM | 1 GB |
| Disk | 8 GB |
| Host mount | `~/devops-lab` → `/home/ubuntu/devops-lab` (only) |

## 5. Get into the VM

```bash
multipass shell linux-ops-lab
```

Your prompt should now look like `ubuntu@linux-ops-lab:~$`. From here on, every command runs **inside** the VM unless explicitly marked "on the host".

## 6. Clone the repository

Two equivalent paths — pick one:

**Option A (recommended)** — clone into the shared folder so you can edit on the host and run inside the VM:

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

To hit the API from your host (outside the VM), grab the VM's IP:

```bash
multipass info linux-ops-lab   # look at the "IPv4" line
curl http://<that-ip>:8080
```

## 9. Multipass cheat sheet

```bash
multipass list                                                                # what VMs do I have
multipass shell linux-ops-lab                                                 # open a shell
multipass stop linux-ops-lab                                                  # power off, keep state
multipass start linux-ops-lab                                                 # power on
multipass delete linux-ops-lab                                                # mark for deletion
multipass purge                                                               # actually free the disk after delete
multipass info linux-ops-lab                                                  # IP, status, mounts, disk
multipass mount ~/devops-lab linux-ops-lab:/home/ubuntu/devops-lab            # re-mount if you launched without --mount
multipass unmount linux-ops-lab:/home/ubuntu/devops-lab                       # remove the share
```

> Avoid mounting `$HOME` wholesale — anything you mount is reachable by root inside the VM.

## Alternatives (use only if Multipass won't run on your host)

| Option | When to pick it | Trade-off |
|---|---|---|
| **virt-manager (KVM/libvirt)** | You want the "native Linux" path or you already use libvirt | Heavier setup, but uses the kernel hypervisor directly. GUI for VM management. |
| **LXD / Incus**  | You want fast boot (~1s) and don't care about kernel-level isolation | System containers share the host kernel. Fine for everything in this lab *except* demos that touch kernel space (e.g. `dmesg`, kernel modules). |
| **VirtualBox**   | KVM unavailable, or you want a familiar cross-platform GUI | Slower than KVM. Conflicts with KVM if both are loaded — pick one. |
| **Vagrant + libvirt** | You want a declarative `Vagrantfile` you can version-control | More moving parts. Overkill for a single VM but great if you build many. |
| **plain QEMU + cloud-init** | You want to script everything from scratch | Maximum control, minimum convenience. Skip unless you're already comfortable. |

### virt-manager quickstart (fallback)

```bash
# Ubuntu/Debian:
sudo apt install qemu-kvm libvirt-daemon-system virt-manager
sudo usermod -aG libvirt,kvm $USER
# Fedora:
sudo dnf install @virtualization
sudo systemctl enable --now libvirtd

# log out and back in so the group change takes effect, then:
virt-manager
```

In the GUI: **File → New Virtual Machine → Local install media** → point at an Ubuntu 24.04 Server ISO ([download here](https://ubuntu.com/download/server)) → 1 CPU / 1 GB RAM / 8 GB disk → finish.

### LXD quickstart (fallback)

```bash
sudo snap install lxd
sudo lxd init                                # accept defaults
sudo usermod -aG lxd $USER && newgrp lxd     # so you don't need sudo
lxc launch ubuntu:24.04 linux-ops-lab \
  -c limits.cpu=1 -c limits.memory=1GiB
lxc shell linux-ops-lab
```

Caveat: LXD containers share the host kernel. `systemctl reboot` reboots the container, not the host, which is what you want — but you won't see real kernel-level OOM messages in `dmesg` because `dmesg` shows the *host's* kernel ring buffer.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `multipass launch` hangs at "Retrieving image" | First-run image download | Wait — first boot can take 3–5 min |
| `launch failed: KVM not available` | KVM module not loaded or virtualization disabled in BIOS | `sudo modprobe kvm-intel` (or `kvm-amd`); enable VT-x/AMD-V in BIOS |
| `cannot connect to /var/snap/multipass/common/multipass_socket` | snap service not running | `sudo systemctl start snap.multipass.multipassd` |
| Multipass works but is slow | Falling back to QEMU-TCG (no KVM) | Check `lsmod \| grep kvm`; load the right kvm module for your CPU |
| Conflict between KVM and VirtualBox | Both want exclusive CPU access | Pick one: `sudo modprobe -r kvm_intel` to use VirtualBox, or uninstall VirtualBox to use KVM |
| `lsb_release` shows 22.04 | Used the wrong image | `multipass delete linux-ops-lab && multipass purge && multipass launch 24.04 ...` |
| "Permission denied" on `install.sh` | Forgot `chmod +x` after clone | `chmod +x install.sh scripts/*.sh && sudo ./install.sh` |
