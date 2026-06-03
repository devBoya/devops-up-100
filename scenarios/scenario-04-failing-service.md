# Scenario 4 — Failing Service

> **Incident ticket**
> Severity: P1
> Reporter: PagerDuty
> "API is down. We're seeing connection refused on port 8080. Customer dashboards are showing red."

## Your job

Get `lab-api` back to healthy. Capture enough evidence (logs, status, unit file inspection) that you could write a 5-line post-mortem afterwards.

## Setup (facilitator only)

Pick one — both produce a "failing API" but exercise different muscles:

```bash
# Variant A: brute stop. Easiest to diagnose.
sudo systemctl stop lab-api

# Variant B: corrupt the script so it exits non-zero.
sudo sed -i '1i exit 7' /opt/linux-ops-lab/scripts/api.sh
sudo systemctl restart lab-api
```

For first delivery, recommend **Variant A** during walk-through and **Variant B** as the stretch challenge.

## What "good" looks like at the end

- `systemctl status lab-api` shows `active (running)`.
- `curl localhost:8080` returns `linux-ops-lab healthy`.
- The student can name *what* was wrong (stopped / bad exit / etc.) without guessing.

## Suggested investigation path

1. **Reproduce the report.**
   ```bash
   curl -v localhost:8080
   ```
2. **Look at the service.**
   ```bash
   systemctl status lab-api
   ```
   Note the `Active:` line, the `Main PID:` line, and the `CGroup:` block.
3. **Read the journal.**
   ```bash
   journalctl -u lab-api --since "15 min ago" --no-pager
   journalctl -u lab-api -p err --since "1 hour ago"
   ```
4. **Inspect the unit + binary.**
   ```bash
   systemctl cat lab-api
   sudo -u labapp /opt/linux-ops-lab/scripts/api.sh   # try to run it by hand
   ```
5. **Fix and verify.**
   ```bash
   # Variant A
   sudo systemctl start lab-api

   # Variant B
   sudo sed -i '/^exit 7$/d' /opt/linux-ops-lab/scripts/api.sh
   sudo systemctl restart lab-api
   curl localhost:8080
   ```

## Discussion prompts

- What's the difference between `systemctl status` and `journalctl -u`?
- Why is `systemctl cat <unit>` better than `cat /etc/systemd/system/<unit>.service`?
- How would you have caught Variant B with a healthcheck *before* PagerDuty fired?
- What would you have monitored to alert on this earlier?

## Root cause (facilitator key)

Either the unit was stopped (Variant A) or the script was edited to exit non-zero before reaching the server bind (Variant B). In both cases the journal shows the failure clearly — the lesson is "read the journal before guessing".
