# linux-ops-lab-week1

A self-contained Linux operations lab for Week 1 of the DevOps mentorship.

Students stand up an Ubuntu 24.04 LTS VM, install a fake multi-service application, and then work through four production-style incidents — CPU starvation, memory pressure, permission denied, and a failing service — while being introduced to Linux fundamentals, systemd, journald, permissions, and Bash automation along the way.

The lab is intentionally **incident-first, command-second**. The first thing a student sees is a ticket. Commands are introduced when they're needed to make progress.

## Quick start

Pick the setup guide for your host. All three end at the same Ubuntu 24.04 VM with this repo cloned inside it.

| Host OS | Recommended tool | Guide |
|---|---|---|
| macOS                | Lima (pinned to 24.04 via `lab.yaml`) | [docs/setup-macos.md](docs/setup-macos.md) |
| Windows 10/11        | Multipass (Hyper-V or VirtualBox backend) | [docs/setup-windows.md](docs/setup-windows.md) |
| Other Linux distros  | Multipass (KVM backend)                   | [docs/setup-linux.md](docs/setup-linux.md) |

**Safety note on host mounts.** All three setup paths mount **only** a dedicated `~/devops-lab/` folder from your host into the VM — never your whole home directory. The lab deliberately exercises root commands (`chown`, `chmod`, `systemctl`, the failure services), and scoping the mount keeps blast radius contained to that one folder. Create it on the host before launching the VM (`mkdir -p ~/devops-lab` on Mac/Linux, `New-Item -ItemType Directory -Force -Path $HOME\devops-lab` on Windows).

Once you're inside the VM, every host converges on the same three commands:

```bash
sudo apt-get install -y git
git clone https://github.com/devBoya/devops-up-100.git
cd devops-up-100/linux-ops-lab-week1
sudo ./install.sh
./healthcheck.sh
curl localhost:8080         # → linux-ops-lab healthy
```

## Learning outcomes (Week 1)

- Navigate Linux systems confidently.
- Understand Linux architecture at the kernel/userspace/process level.
- Inspect running processes (`ps`, `top`, `pstree`, `/proc`).
- Analyze CPU, memory, and disk usage.
- Investigate service failures with `systemctl` and `journalctl`.
- Read and write basic systemd unit files.
- Manage Unix permissions (`chown`, `chmod`, ownership vs mode).
- Write simple Bash automation that's safe-by-default.
- Follow a real troubleshooting methodology under time pressure.

## Operating system

Ubuntu Server **24.04 LTS** (Noble Numbat). All package names, paths, and image references target this release.

## Repository structure

```
linux-ops-lab-week1/
├── README.md                  # this file
├── Makefile                   # make help — convenience wrappers
├── lab.yaml                   # Lima VM config pinned to Ubuntu 24.04
├── install.sh                 # bootstrap labapp user, dirs, services
├── uninstall.sh               # remove everything install.sh added
├── reset-lab.sh               # back to a clean, healthy baseline
├── healthcheck.sh             # one-screen system + service snapshot
├── scripts/                   # service workloads
│   ├── api.sh                 # HTTP :8080 returning "linux-ops-lab healthy"
│   ├── worker.sh              # fake job processor
│   ├── scheduler.sh           # fake periodic tasks
│   ├── logger.sh              # structured JSON-ish log writer
│   ├── cpu-hog.sh             # scenario 1: CPU starvation
│   ├── memory-leak.sh         # scenario 2: memory pressure
│   └── permission-bug.sh      # scenario 3: permission denied
├── systemd/                   # one unit file per service, runs as labapp
│   ├── lab-api.service
│   ├── lab-worker.service
│   ├── lab-scheduler.service
│   ├── lab-logger.service
│   ├── lab-cpu-hog.service
│   ├── lab-memory-leak.service
│   └── lab-permission-bug.service
├── scenarios/                 # incident tickets + investigation paths
│   ├── scenario-01-cpu-starvation.md
│   ├── scenario-02-memory-pressure.md
│   ├── scenario-03-permission-denied.md
│   └── scenario-04-failing-service.md
└── docs/
    ├── setup-macos.md         # student VM setup — Lima
    ├── setup-windows.md       # student VM setup — Multipass / WSL2 fallback
    ├── setup-linux.md         # student VM setup — Multipass / KVM / LXD
    ├── facilitator-guide.md   # session agendas, Slido, homework
    ├── student-guide.md       # daily flow + rules of engagement
    └── command-cheatsheet.md  # one-page reference
```

## Services installed by `install.sh`

| Unit | Default state | What it does |
|---|---|---|
| `lab-api`        | enabled, running  | HTTP server on :8080, returns `linux-ops-lab healthy` |
| `lab-worker`     | enabled, running  | Picks fake jobs off an in-memory queue, logs each one |
| `lab-scheduler`  | enabled, running  | Runs fake periodic tasks |
| `lab-logger`     | enabled, running  | Writes structured logs to `/var/log/linux-ops-lab/app.log` |
| `lab-cpu-hog`        | installed, **disabled** | Scenario 1 — saturates every CPU |
| `lab-memory-leak`    | installed, **disabled** | Scenario 2 — grows RSS until soft-capped |
| `lab-permission-bug` | installed, **disabled** | Scenario 3 — fails to write its log |

All services run as the unprivileged `labapp` user, restart on failure, and log to journald.

## Scenarios

Each scenario is a one-page incident report. Facilitator triggers, students drive:

| # | Incident | How to trigger |
|---|---|---|
| 1 | "The VM is slow and SSH is lagging."           | `make break-cpu` |
| 2 | "App is slow, services keep restarting."        | `make break-memory` |
| 3 | "Application can't write logs."                 | `make break-permissions` |
| 4 | "API is down."                                  | `sudo systemctl stop lab-api` (variant A) |

See [scenarios/](scenarios/) for the full ticket, investigation hints, and facilitator key.

## Common operations

```bash
make help                    # discover every target
sudo ./install.sh            # bootstrap the lab
./healthcheck.sh             # system + service snapshot
sudo ./reset-lab.sh          # back to baseline
sudo ./uninstall.sh          # nuke everything

make break-cpu               # inject scenario 1
make break-memory            # inject scenario 2
make break-permissions       # inject scenario 3
make reset                   # recover
make logs                    # tail every lab service journal
make status                  # systemctl status for all lab units
make lint                    # bash -n every script
```

## Verify the environment

```bash
uname -a
lsb_release -a       # → Ubuntu 24.04 LTS
free -h
df -h
```

## License

Internal mentorship material. Treat as proprietary; do not distribute outside the cohort.
