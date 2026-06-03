# Security

This repository is a deliberately-vulnerable Linux operations training lab. Read this file before running anything in it.

## What this project is (and isn't)

This is a teaching lab. It contains services designed to **fail**, **saturate**, **leak memory**, and **misuse permissions**. Those aren't bugs — they're the curriculum. Do not treat anything here as production-ready code.

- Not hardened.
- Not audited.
- Not safe to run outside a throwaway VM.
- Not safe to expose to a public network.

## Threat model

| In scope (we protect against) | Out of scope (we do not) |
|---|---|
| A misbehaving lab service taking down the host machine | A motivated attacker on the lab VM |
| A root command inside the VM reaching files outside `~/devops-lab/` on the host | The lab API requiring authentication |
| A failure service consuming so much memory/CPU that recovery is impossible | The lab API being safe to expose to the public internet |
| A student accidentally running a destructive command on their workstation | A student deliberately running destructive commands inside the VM (that's the point) |

## How blast radius is contained

If you follow the setup guides as written, damage from anything inside the VM stops at the VM boundary plus one host folder. Specifically:

1. **The lab runs in a VM, not on the host.** All setup guides (macOS / Windows / Linux) launch an Ubuntu 24.04 VM via Lima or Multipass. Never run `install.sh` directly on a host you care about.
2. **The host mount is scoped to `~/devops-lab/`.** Lima's `lab.yaml` and the Multipass `--mount` flag both bind only this one folder into the VM. A `sudo rm -rf` inside the VM cannot reach anything else on your machine. See `docs/setup-*.md` for the rationale.
3. **Lab services run as `labapp`, not root.** Every service unit in `systemd/` declares `User=labapp` and `Group=labapp`. `install.sh` is the only thing in the repo that needs root, and only for the bootstrap steps documented in [scenarios/scenario-03-permission-denied.md](scenarios/scenario-03-permission-denied.md).
4. **Failure services have resource caps.**
   - `lab-memory-leak.service` has `MemoryMax=700M` and `OOMScoreAdjust=800` so the kernel kills the leaker — not sshd — under pressure.
   - `lab-cpu-hog.service` uses `Nice=10` and `CPUSchedulingPolicy=batch` so the VM stays SSH-able while a student investigates.
   - Both have `Restart=on-failure` with `StartLimitBurst` set so a runaway loop is visible without hanging the system.
5. **Light systemd sandboxing.** Every unit declares `NoNewPrivileges=true`, `ProtectSystem=full`, and `ProtectHome=true`. This is educational sandboxing, not a security boundary — students can and should disable it during exercises if they want to see what changes.

## What students should never do

- **Do not** run `install.sh` on a workstation or shared server. It is only safe inside a disposable VM.
- **Do not** forward port 8080 to a public IP. The lab API has no authentication, no rate limit, no TLS. Inside the VM, behind Lima/Multipass port forwarding to localhost only, it's fine.
- **Do not** copy the systemd unit files into a production repo and adapt them for real services. They're written for clarity, not hardening. Read [`scripts/permission-bug.sh`](scripts/permission-bug.sh) as a counter-example of how to handle errors loudly — that pattern *does* generalize.
- **Do not** reuse the `labapp` user account pattern verbatim. In real systems, service users need `/usr/sbin/nologin` (which we do), but they also need scoped capabilities, file ACLs, and a real review of `/etc/systemd/system/<unit>.service.d/` overrides.

## Known intentional weaknesses

These are documented for clarity, not as a bug list:

| File / unit | What's "wrong" | Why |
|---|---|---|
| `scripts/cpu-hog.sh` | Spawns one busy `awk` loop per CPU | Scenario 1 |
| `scripts/memory-leak.sh` | Allocates ~20 MB / 5 s without bound (capped at 600 MB by systemd) | Scenario 2 |
| `scripts/permission-bug.sh` | Tries to append to a log it cannot write | Scenario 3 |
| `lab-api.service` | API listens on `0.0.0.0:8080` and serves a static body with no auth | Demo only |
| `Makefile` target `break-permissions` | Deliberately `chown root:root` on a labapp-owned log | Scenario 3 trigger |
| Healthy services log to `/var/log/linux-ops-lab/` without rotation | Files grow until `reset-lab.sh` truncates them | Keeps log-investigation exercises realistic |

## Reporting a vulnerability

If you find a security issue in the **lab tooling itself** — for example, `install.sh` does something dangerous that the curriculum didn't intend, a systemd unit has a path traversal, or the Multipass mount escapes its scope — please report it privately.

**Contact:** rob@boyahq.com

Please include:
- What you ran
- What happened that you didn't expect
- Whether it's reproducible from a clean `limactl delete` / `multipass delete` followed by a fresh install

Do not open a public GitHub issue for unintended privilege-escalation or VM-escape findings.

The intentional weaknesses listed above are *not* vulnerabilities — they are the lesson. Reports of "lab-cpu-hog uses 100% CPU" will be closed with the link to [scenarios/scenario-01-cpu-starvation.md](scenarios/scenario-01-cpu-starvation.md).

## Supply chain

- **Base image:** Ubuntu Server 24.04 LTS (Noble Numbat) cloud images, fetched directly from `cloud-images.ubuntu.com`. Pinned in `lab.yaml`.
- **Hypervisor tools:**
  - Lima — installed via Homebrew (`brew install lima`)
  - Multipass — installed via `winget` (Windows) or `snap` (Linux), both from Canonical
- **Inside the VM:** apt packages from the default Ubuntu archive (`curl`, `jq`, `htop`, `procps`, `net-tools`, `sysstat`). No third-party PPAs, no curl-to-bash.
- **No outbound network from lab services.** The four healthy services and three failure services do not initiate outbound connections.

## Lifecycle

A fresh `limactl delete linux-ops-lab` / `multipass delete linux-ops-lab && multipass purge` followed by re-running the setup guide should produce a byte-identical lab environment. If it doesn't, that's worth reporting via the contact above.
