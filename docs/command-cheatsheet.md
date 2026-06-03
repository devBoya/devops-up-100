# Command Cheatsheet — Week 1

Quick reference. Keep open in a second tab during the session.

## Navigation & files

```bash
pwd                          # where am I
ls -lah                      # detailed listing, all files, human sizes
cd -                         # back to previous directory
tree -L 2 .                  # 2-deep view of current dir (apt install tree)
find / -name 'lab-*.service' 2>/dev/null
```

## Reading files & logs

```bash
cat /etc/os-release          # what distro/version
less /var/log/syslog         # paged view; q to quit
tail -f /var/log/linux-ops-lab/api.log
head -n 50 file.log
grep -i 'error' file.log
grep -RIn 'pattern' /etc
```

## Processes

```bash
ps aux                       # every process, BSD style
ps -ef                       # every process, System V style
ps -eo pid,user,%cpu,%mem,comm --sort=-%cpu | head
pstree -p                    # tree view with PIDs
top                          # interactive, q to quit
htop                         # nicer top (apt install htop)
pgrep -fa cpu-hog            # find PIDs by name
kill <PID>                   # SIGTERM
kill -9 <PID>                # SIGKILL — last resort
```

## CPU / memory / disk

```bash
uptime                       # load averages
nproc                        # how many CPUs
free -h                      # memory in human units
vmstat 2 5                   # 5 samples, 2s apart
df -hT                       # disk usage by mount
du -sh /var/log/*            # disk usage per child
iostat -xz 2                 # apt install sysstat
```

## Permissions

```bash
ls -l file                   # see owner/group/mode
stat file                    # all the details
chmod 0644 file              # rw-r--r--
chmod u+x script.sh          # add execute for owner
chown labapp:labapp file     # change owner + group
id labapp                    # who is labapp
whoami
```

## Systemd

```bash
systemctl status lab-api
systemctl start lab-api
systemctl stop lab-api
systemctl restart lab-api
systemctl enable lab-api     # start at boot
systemctl disable lab-api
systemctl is-active lab-api
systemctl is-enabled lab-api
systemctl cat lab-api        # final assembled unit (incl. drop-ins)
systemctl list-units 'lab-*.service'
systemctl list-unit-files 'lab-*.service'
systemctl reset-failed lab-api
systemctl daemon-reload      # after editing a unit
```

## journald

```bash
journalctl -u lab-api                    # logs for one unit
journalctl -u lab-api --since "10 min ago"
journalctl -u lab-api -f                 # follow
journalctl -u lab-api -p err             # only errors
journalctl -k                            # kernel ring buffer
journalctl --disk-usage
```

## Networking

```bash
ip a                         # interfaces + addresses
ip route                     # routing table
ss -tulnp                    # listening sockets, with PIDs
curl -v localhost:8080
ping -c 3 1.1.1.1
dig example.com              # apt install dnsutils
```

## SSH

```bash
ssh -v user@host             # verbose handshake
ssh-keygen -t ed25519        # new keypair
ssh-copy-id user@host        # install pubkey on remote
~/.ssh/config                # per-host shortcuts
```

## Bash building blocks

```bash
set -Eeuo pipefail           # safe-by-default shebang line companion
trap 'echo failed at $LINENO' ERR
$(date --iso-8601=seconds)   # ISO timestamp
[[ -f file ]] && echo exists
for x in a b c; do echo $x; done
while read -r line; do ...; done < file.txt
```

## Lab-specific shortcuts

```bash
make help                    # list every make target
make install                 # sudo ./install.sh
make health                  # ./healthcheck.sh
make reset                   # restore baseline
make break-cpu               # trigger scenario 1
make break-memory            # trigger scenario 2
make break-permissions       # trigger scenario 3
make logs                    # journalctl -f -u 'lab-*'
```
