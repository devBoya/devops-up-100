# Scenario 3 — Permission Denied

> **Incident ticket**
> Severity: P3
> Reporter: developer who shipped the latest config change
> "Application can't write logs after the last deploy. The service fires up and then crashes a few seconds later. Logs aren't even showing up in our log directory."

## Your job

Figure out *why* the service can't write, fix the underlying permissions, and confirm the service stays up.

## Setup (facilitator only)

```bash
make break-permissions
```

That target chowns `/var/log/linux-ops-lab/permission-bug.log` to `root:root` with mode `0600` and starts `lab-permission-bug`, which runs as `labapp` and therefore cannot write.

## What "good" looks like at the end

- `/var/log/linux-ops-lab/permission-bug.log` is owned by `labapp:labapp`, mode `0644` or `0664`.
- `systemctl status lab-permission-bug` shows `active (running)` and no `(failure)` in the recent history.
- New lines appear in `permission-bug.log` every few seconds.

## Suggested investigation path

1. **Read the ticket literally.** The user said "can't write logs". Start with the log directory.
   ```bash
   ls -l /var/log/linux-ops-lab/
   ```
2. **Ask systemd what happened.**
   ```bash
   systemctl status lab-permission-bug
   journalctl -u lab-permission-bug --since "10 min ago"
   ```
   Look for `Permission denied` and the exit code on each restart attempt.
3. **Compare the service's identity vs the file's owner.**
   ```bash
   systemctl show lab-permission-bug --property=User
   id labapp
   stat /var/log/linux-ops-lab/permission-bug.log
   ```
4. **Fix the perms. Two valid approaches — pick one and justify.**
   ```bash
   # Option A: change ownership back to labapp
   sudo chown labapp:labapp /var/log/linux-ops-lab/permission-bug.log
   sudo chmod 0644          /var/log/linux-ops-lab/permission-bug.log

   # Option B: delete the broken file and let the service recreate it
   sudo rm /var/log/linux-ops-lab/permission-bug.log
   ```
5. **Restart and verify.**
   ```bash
   sudo systemctl restart lab-permission-bug
   systemctl status lab-permission-bug
   tail -f /var/log/linux-ops-lab/permission-bug.log
   ```

## Discussion prompts

- Why does the service exit instead of just logging the error and retrying? (Hint: look at `permission-bug.sh`.)
- What's the difference between `chown`, `chgrp`, and `chmod`?
- When would mode `0644` be wrong and `0664` be right? (Group writes.)
- How would `systemd-tmpfiles` have prevented this class of bug from recurring?

## Root cause (facilitator key)

`/var/log/linux-ops-lab/permission-bug.log` was chowned to root with mode 0600. The service runs as `labapp` and therefore gets `EACCES` on every write. Because the script exits non-zero on write failure (no silent swallowing), systemd flips the unit into `failed` and `Restart=on-failure` keeps the loop visible.
