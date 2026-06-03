# Scenario 1 — CPU Starvation

> **Incident ticket**
> Severity: P2
> Reporter: on-call rotation
> "The VM is extremely slow and SSH is lagging. The dashboards are still green but every command takes seconds to return. Can you take a look?"

## Your job

You are on-call. The system is reachable but unhealthy. Restore normal performance and write a one-line root cause for the post-mortem.

## Setup (facilitator only)

```bash
make break-cpu        # or: sudo systemctl start lab-cpu-hog
```

## What "good" looks like at the end

- `uptime` shows load average drifting back toward the number of CPUs.
- `systemctl status lab-cpu-hog` shows `inactive (dead)` and `disabled`.
- The four healthy services (`lab-api`, `lab-worker`, `lab-scheduler`, `lab-logger`) are `active (running)`.
- `curl localhost:8080` returns `linux-ops-lab healthy` within ~1s.

## Suggested investigation path

1. **Confirm the symptom.** Don't trust the ticket; reproduce it.
   ```bash
   uptime              # load average vs nproc
   nproc
   ```
2. **Find the noisy neighbor.**
   ```bash
   top                 # sort by CPU (default); look for runaway %CPU
   ps aux --sort=-%cpu | head
   ```
3. **Connect the process back to a service.**
   ```bash
   systemctl status <PID>     # systemd will tell you which unit owns the PID
   ```
4. **Stop it. Disable it. Verify.**
   ```bash
   sudo systemctl stop    lab-cpu-hog
   sudo systemctl disable lab-cpu-hog
   uptime                       # load should fall over the next minute
   ```

## Discussion prompts

- Why does load average lag behind real CPU usage?
- What's the difference between `top`'s `%CPU` column and `load average`?
- The cpu-hog service was set with `Nice=10`. What would have changed if it were `Nice=-10` or default?
- How would you know this was the right process and not, say, a kernel thread?

## Root cause (facilitator key)

`lab-cpu-hog.service` was started (typically via `make break-cpu`). It spawns one busy `awk` loop per CPU, saturating all cores. Stopping and disabling the unit returns the system to normal.
