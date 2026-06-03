# Facilitator Guide — Week 1: Linux Operations

This guide is the script for the mentor running the live Zoom session. It assumes you've already done a dry run of `install.sh` on your own VM and verified all four scenarios trigger and recover.

The student experience is **incident → investigation → command introduction → recovery**. Resist the urge to teach commands first — let the mess pull the commands out of them.

---

## Session 1 — Linux Architecture & Process Management (90 min)

### Agenda

| Time | Block | Activity |
|---|---|---|
| 0:00 – 0:10 | Welcome | Round-the-room: what is "Linux" to you in one sentence? |
| 0:10 – 0:25 | Live demo | Linux architecture whiteboard: kernel ↔ syscalls ↔ userspace ↔ processes |
| 0:25 – 0:35 | Verify environment | Everyone runs `./healthcheck.sh` and pastes output in chat |
| 0:35 – 1:00 | **Scenario 1 — CPU Starvation** | Facilitator triggers `make break-cpu`. Students drive. |
| 1:00 – 1:25 | **Scenario 2 — Memory Pressure** | Facilitator triggers `make break-memory`. Students drive. |
| 1:25 – 1:30 | Wrap | Slido + homework |

### Live demos (mentor screen)

1. **The process tree.** `pstree -p | head -40`. Point out `init/systemd` at PID 1, services hanging off it, your shell hanging off sshd.
2. **What `top` actually shows you.** Walk through every column. Most students have never had this explained.
3. **`/proc` is real.** `cat /proc/1/cmdline`, `ls /proc/$$/`. Demystify "where do these tools get their data".

### Student exercises

Run inside the VM, no help from the mentor:

1. Find the PID of `sshd` without `pgrep`. Confirm by reading `/proc`.
2. Pipe `ps` to show only your own processes, sorted by memory descending.
3. Open two `limactl shell` sessions. In one, run `top`. In the other, run `sleep 600 &`. Watch it appear without restarting top.

### Discussion questions

- What's the difference between a process, a thread, and a job?
- Why does `ps aux` show different rows depending on when you run it?
- If `kill -9` doesn't kill a process, what state is it in and why?

### Slido questions (live polling)

1. (MCQ) Which command shows real-time CPU usage by process?
   - `cat /proc/cpuinfo`
   - `top` ✅
   - `df -h`
   - `lsof`
2. (Free text) What does "load average" actually measure?
3. (MCQ) `kill -9 <pid>` sends which signal?
   - `SIGTERM`
   - `SIGKILL` ✅
   - `SIGSTOP`
   - `SIGHUP`

### Homework

- Read `man top` end-to-end. Write three sentences on what `%CPU` actually means with hyperthreading.
- On your own VM, reproduce **Scenario 2** without looking at the scenario doc. Time yourself.

---

## Session 2 — Linux Operations & Automation (90 min)

### Agenda

| Time | Block | Activity |
|---|---|---|
| 0:00 – 0:05 | Recap | One student demos the cpu-hog scenario start-to-finish |
| 0:05 – 0:20 | Live demo | systemd unit anatomy: walk through `systemd/lab-api.service` line by line |
| 0:20 – 0:40 | **Scenario 3 — Permission Denied** | Facilitator triggers `make break-permissions`. Students drive. |
| 0:40 – 1:05 | **Scenario 4 — Failing Service** | Variant A first; if time, Variant B as a stretch |
| 1:05 – 1:25 | Build something | Each student writes a 10-line bash script that prints a system health summary (mini `healthcheck.sh`) |
| 1:25 – 1:30 | Wrap | Slido + homework |

### Live demos

1. **`systemctl status` vs `journalctl -u`.** Same service, two views. Show why both matter.
2. **`systemctl cat <unit>` vs `cat /etc/systemd/system/<unit>.service`.** Why `systemctl cat` is the answer that survives drop-in overrides.
3. **SSH troubleshooting.** `ssh -v lima-linux-ops-lab`, then `journalctl -u ssh` inside the VM.

### Student exercises

1. Add a new `lab-counter.service` that runs a 5-line bash script printing an incrementing counter every 2s. Enable, start, verify in journal.
2. Modify `lab-worker.service` so it depends on `lab-api.service` (already wired — read it, explain it).
3. Write a one-liner that prints the 5 services with the highest memory usage out of all `lab-*` units.

### Discussion questions

- Why do we run services as a dedicated `labapp` user instead of root?
- What does `Restart=on-failure` *not* protect you from?
- When is `chmod 777` actually the right answer? (Almost never. Make them defend it.)
- What's a sane default for a brand-new daemon you're shipping next week?

### Slido questions

1. (MCQ) Which command shows logs for a specific systemd unit?
   - `cat /var/log/syslog`
   - `journalctl -u <unit>` ✅
   - `dmesg`
   - `systemctl logs`
2. (MCQ) Which file should you edit to add a custom systemd override?
   - The unit file itself
   - A drop-in under `/etc/systemd/system/<unit>.service.d/` ✅
   - `/etc/init.d/<unit>`
   - You can't override unit files
3. (Free text) Name one thing `Restart=on-failure` does *not* protect you from.

### Homework

- Read `man systemd.service` sections `[Service]` and `[Install]`.
- Write a `lab-mywatcher.service` that runs every 30s as a `Type=oneshot` paired with a `lab-mywatcher.timer`. Submit the two files in a PR to your fork.
- Reproduce Scenario 4 Variant B without notes.

---

## Teaching philosophy reminders

The repo intentionally does **not** teach commands first. Run the scenario, let students struggle for ~3 minutes, then introduce the command that breaks the deadlock. Students who learn `ps` because they *needed* it never forget it; students who learn it because slide 17 said to will forget it on Monday.

If a student solves a scenario fast, push them: "Great. Now write the post-mortem in 3 sentences and explain what monitoring would have caught this earlier."

---

## Mentor pre-flight checklist (do before the session)

- [ ] Fresh `limactl start --name=linux-ops-lab ./lab.yaml`
- [ ] `sudo ./install.sh` succeeds end-to-end
- [ ] `./healthcheck.sh` shows all four healthy services active
- [ ] `curl localhost:8080` returns `linux-ops-lab healthy`
- [ ] Each `make break-*` target visibly degrades the system
- [ ] `make reset` returns to clean state
- [ ] Zoom share + terminal font size ≥18pt
