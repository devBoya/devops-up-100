# Student Guide — Week 1

Welcome. By the end of this week you should feel less afraid of a Linux box that's misbehaving.

## What you'll do

1. Stand up a real Ubuntu 24.04 VM on your Mac (see [setup-macos.md](./setup-macos.md)).
2. Install a multi-service fake application (`./install.sh`).
3. Get four production-style incident tickets thrown at you.
4. Investigate, fix, and explain each one.

You are *not* expected to know the commands ahead of time. You are expected to:

- Read the ticket carefully.
- Form a hypothesis before typing a command.
- Run **one** command at a time and read the output.
- Ask questions in the Zoom chat, not Google.

## Learning outcomes

By the end of Week 1 you should be able to, unprompted:

- Navigate `/`, `/var/log`, `/opt`, `/etc`, `/proc` and explain what each is for.
- Sketch the Linux architecture (kernel ↔ syscalls ↔ userspace) on a whiteboard.
- Use `top`, `ps`, `free`, `df`, `vmstat`, `uptime` to characterize a system.
- Investigate a service failure using `systemctl status` + `journalctl -u`.
- Read and explain a systemd unit file.
- Use `chown` / `chmod` correctly and explain when each is right.
- Write a Bash script (10–30 lines) that prints a useful system snapshot.
- State a troubleshooting methodology in your own words.

## Daily flow

Each scenario lives in [`scenarios/`](../scenarios). The pattern is the same:

1. Read the ticket at the top.
2. **Don't read further.** Try to solve it.
3. If you're stuck for more than ~5 min, scroll to "Suggested investigation path".
4. Once you've recovered the system, read the "Discussion prompts" and answer them in your own words.
5. Run `./healthcheck.sh` and `make reset` before moving on.

## Useful one-liners while you learn

```bash
# What process is using port 8080?
sudo ss -tlnp | grep 8080

# What's the heaviest CPU consumer right now?
ps -eo pid,user,%cpu,comm --sort=-%cpu | head

# What's the heaviest RAM consumer right now?
ps -eo pid,user,%mem,rss,comm --sort=-%mem | head

# Tail every lab service log at once.
journalctl -f -u 'lab-*'

# Reset the lab.
sudo ./reset-lab.sh
```

Full reference: [`command-cheatsheet.md`](./command-cheatsheet.md).

## Asking good questions

A great question gives the mentor enough context to answer in one Zoom message:

> "I'm on Scenario 2. `free -h` shows `available: 80M` but `ps --sort=-%mem` doesn't show any lab process over 50M RSS. What am I missing?"

A not-great question:

> "memory broken help"

## Rules of engagement

- Do not `sudo rm -rf /`. It is funny once. It is not funny on a Zoom share.
- Take a screenshot of your `systemctl status <unit>` output before you "fix" anything. That output is the evidence for your post-mortem.
- If your fix involves `chmod 777`, you have not fixed it.
