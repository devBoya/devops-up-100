# Scenario 2 — Memory Pressure

> **Incident ticket**
> Severity: P2
> Reporter: customer support
> "Application is slow and services keep restarting. We're seeing intermittent 500s from the API and the worker queue is backing up."

## Your job

Find the process eating memory, stop the bleeding, and verify the healthy services recover. Capture a before/after snapshot so the post-mortem has data.

## Setup (facilitator only)

```bash
make break-memory     # or: sudo systemctl start lab-memory-leak
```

The leaker is capped at ~600MB with `MemoryMax=700M` so it will OOM itself before it can kill sshd. Students should still see real memory pressure — they just won't lose the VM.

## What "good" looks like at the end

- `free -h` shows `available` memory recovering.
- `systemctl status lab-memory-leak` shows the unit `inactive (dead)` and `disabled`.
- `lab-api`, `lab-worker`, `lab-scheduler`, `lab-logger` are all `active (running)`.
- `curl localhost:8080` returns `linux-ops-lab healthy`.

## Suggested investigation path

1. **Confirm pressure.**
   ```bash
   free -h
   vmstat 2 5                  # watch si/so swap activity, r/b run/blocked
   ```
2. **Find the hungry process.**
   ```bash
   top -o %MEM
   ps -eo pid,user,%mem,rss,comm --sort=-%mem | head
   ```
3. **Tie it back to systemd.**
   ```bash
   systemctl status lab-memory-leak
   journalctl -u lab-memory-leak --since "10 min ago"
   ```
4. **Look for OOM evidence in the kernel log.**
   ```bash
   sudo dmesg -T | grep -iE 'oom|killed process'
   journalctl -k --since "15 min ago" | grep -i oom
   ```
5. **Stop, disable, verify.**
   ```bash
   sudo systemctl stop    lab-memory-leak
   sudo systemctl disable lab-memory-leak
   free -h
   ```

## Discussion prompts

- What's the difference between `free`, `available`, and `cached` memory?
- How does Linux decide *which* process to OOM-kill? (`oom_score`, `oom_score_adj`)
- We set `OOMScoreAdjust=800` on the leaker. Why?
- When would `MemoryMax=` make a problem *worse* by hiding it?

## Root cause (facilitator key)

`lab-memory-leak.service` allocates ~20MB of RSS every 5s and touches every page (so the kernel can't lazy-allocate). With the soft cap, it self-OOMs and restarts (`Restart=on-failure`), which looks identical to a real leaky service flapping under load.
