# Student Setup — macOS (Lima + Ubuntu 24.04 LTS)

Goal: by the end of this guide you have an Ubuntu 24.04 LTS VM on your Mac and you've cloned this repository inside it. ~15 minutes from a clean machine.

> The lab assumes **Ubuntu Server 24.04 LTS (Noble Numbat)**. Other distros will mostly work but the facilitator can't help debug them.

## 1. Host requirements

| Resource | Recommended host profile |
|---|---|
| CPU | 2 cores free for the VM |
| RAM | 4 GB free for the VM |
| Disk | 20 GB free |
| macOS | 13 Ventura or newer |

You do not need Docker, Vagrant, or VirtualBox. Lima ships its own VM driver.

## 2. Install Lima

```bash
brew install lima
limactl --version    # confirm it installed
```

If you don't have Homebrew yet: https://brew.sh

## 3. Start the lab VM

There are two ways. **Use the pinned config in this repo** — it's reproducible across the cohort.

### Option A — Use the pinned `lab.yaml` (preferred)

After you clone the repo on the host (see step 4), run:

```bash
limactl start --name=linux-ops-lab ./lab.yaml
```

### Option B — Use Lima's tracking template

```bash
limactl start --name=linux-ops-lab template://ubuntu-lts
```

The `ubuntu-lts` template tracks the most recent Ubuntu LTS (currently 24.04 Noble Numbat). Option A pins explicitly to 24.04 so we all run the same kernel + package set.

### Lab VM profile (what `lab.yaml` requests)

| Resource | Lab VM profile |
|---|---|
| CPU | 1 |
| RAM | 1 GB |
| Disk | 8 GB |

## 4. Get into the VM

```bash
limactl shell linux-ops-lab
```

You should be at a shell that looks like `username@lima-linux-ops-lab:/Users/you$`. From now on every command in the lab runs *inside* the VM unless explicitly marked "on the host".

## 5. Clone the repository inside the VM

```bash
sudo apt-get update
sudo apt-get install -y git
git clone https://github.com/devBoya/devops-up-100.git
cd devops-up-100/linux-ops-lab-week1
```

## 6. Verify you're on Ubuntu 24.04

```bash
uname -a
lsb_release -a
free -h
df -h
```

Expected: `Ubuntu 24.04 LTS` on the `Description:` line of `lsb_release -a`.

## 7. Run the installer

```bash
sudo ./install.sh
./healthcheck.sh
curl localhost:8080
```

You should see `linux-ops-lab healthy`.

## 8. Lima cheat sheet

```bash
limactl list                            # what VMs do I have
limactl shell linux-ops-lab             # open a shell
limactl stop linux-ops-lab              # power off, keep state
limactl start linux-ops-lab             # power on
limactl delete linux-ops-lab            # nuke it (lab.yaml lets you recreate)
```

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `limactl start` hangs at "writing image" | First-run cloud image download | Wait — first boot can take 3-5 min on slow links |
| `curl localhost:8080` fails *on the host* | Lima doesn't forward ports by default | Either `curl` from inside `limactl shell`, or expose with the `portForwards` block in `lab.yaml` |
| `lsb_release` shows 22.04 | Used an old Lima template | `limactl delete linux-ops-lab` and recreate with `lab.yaml` |
| "Permission denied" on `install.sh` | Forgot `chmod +x` after clone | `chmod +x install.sh scripts/*.sh && sudo ./install.sh` |
