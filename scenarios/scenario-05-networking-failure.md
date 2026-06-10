# Scenario 5 — Networking Failure

> **Incident ticket**
> Severity: P2
> Reporter: customer support
> "The application says it is running, but users cannot reach it. Some requests time out, some fail with connection refused, and one internal service cannot resolve another service by name."

## Your job

Diagnose why the application is not reachable from the host and from other services. Work through the network path step by step: interface, IP address, listening ports, DNS, routes, firewall rules, and packet flow. Stop the bleeding, restore access, and capture evidence for the post-mortem.

## Learning goals

By the end of this scenario, students should be able to:

* Explain how an application uses the Linux kernel network stack through sockets.
* Identify whether a service is listening on the expected IP address and port.
* Distinguish between `connection refused`, `connection timeout`, and DNS resolution failure.
* Inspect interfaces, IP addresses, routes, sockets, firewall rules, and packets.
* Use network diagnostics tools in a production-style troubleshooting flow.
* Connect Linux networking concepts to cloud networking concepts such as security groups, subnets, route tables, and private/public access.

## Setup

```bash
make break-networking
```

This starts five services and injects two additional failures (firewall block + DNS corruption):

| Service | Port | Expected failure |
|---|---|---|
| `lab-network-api` | `:9080` | Healthy reference — should work normally |
| `lab-network-wrong-port` | `:9081` (expected) / `:9181` (actual) | Listens on the wrong port |
| `lab-network-loopback` | `:9082` | Bound to `127.0.0.1` only — unreachable from outside |
| `lab-network-firewalled` | `:9083` | Listens correctly, but iptables blocks traffic |
| `lab-network-dns-client` | N/A | Cannot resolve `lab-network-api.local` |

> Keep SSH access safe. Port 22 is never touched by the break scripts.

## What "good" looks like at the end

* `curl localhost:9080` returns `lab-network-api healthy`.
* `ss -tulpn` shows the expected services listening on the expected ports.
* The wrong-port service is identified: actually on `:9181`, not `:9081`.
* The loopback-only service is identified: bound to `127.0.0.1:9082`, not `0.0.0.0:9082`.
* Firewall rules are inspected and the blocked service on `:9083` is restored.
* DNS resolution for `lab-network-api.local` is restored.
* `journalctl -u lab-network-dns-client` shows the client recovering.
* Students can explain each failure mode using evidence, not guesses.

## Suggested investigation path

### 1. Confirm the VM has a network interface and IP address

```bash
ip addr
ip -br addr
```

Questions:

* What network interfaces exist?
* Which interface has the VM IP address?
* Is the interface up?

### 2. Confirm route table and default gateway

```bash
ip route
```

Questions:

* Where does traffic go by default?
* Is there a default route?

### 3. Check whether services are listening

```bash
sudo ss -tulpn
sudo ss -tulpn | grep '908'
```

Look for the bind address and port for each service:

* `0.0.0.0:9080` — healthy API (good)
* Nothing on `:9081` — where is the wrong-port service?
* `127.0.0.1:9082` — loopback only (bad for external access)
* `0.0.0.0:9083` — firewalled service (listening but blocked)

### 4. Test local application access

```bash
curl -v localhost:9080    # healthy — should work
curl -v localhost:9081    # connection refused
curl -v localhost:9082    # works locally (loopback)
curl -v localhost:9083    # timeout (firewall drops packets)
```

Questions:

* Which service works?
* Which gives `connection refused`? What does that mean?
* Which gives `connection timeout`? What does that mean?
* Can you reach port `9181`? What does that tell you?

### 5. Map port to process and service

```bash
sudo ss -tulpn | grep ':9181'
ps -fp <PID>
systemctl status lab-network-wrong-port
journalctl -u lab-network-wrong-port --since "10 min ago"
```

### 6. Test DNS resolution

```bash
getent hosts lab-network-api.local
nslookup lab-network-api.local
dig lab-network-api.local
cat /etc/hosts
```

Questions:

* Does the name resolve?
* What IP does it resolve to?
* Is `192.0.2.1` a routable address?
* Where is the entry coming from — `/etc/hosts` or DNS?

### 7. Check firewall rules

```bash
sudo iptables -L -n -v
sudo iptables -L INPUT -n -v
```

Questions:

* Is port `9083` blocked?
* Which chain has the DROP rule?
* Are packets being counted by the rule?

### 8. Trace packets (optional)

```bash
sudo tcpdump -i any port 9083 -nn
```

In another terminal:

```bash
curl -v --max-time 3 localhost:9083
```

Questions:

* Do you see SYN packets?
* Do you see any replies?

## Fixing each issue

### Wrong port

```bash
# The service listens on 9181 instead of 9081.
# Fix the script or update documentation/callers to use the correct port.
curl localhost:9181
```

### Loopback only

```bash
# The service binds to 127.0.0.1:9082 instead of 0.0.0.0:9082.
# To fix, change the bind address in the script from 127.0.0.1 to 0.0.0.0.
```

### Firewall

```bash
# Remove the DROP rule
sudo iptables -D INPUT -p tcp --dport 9083 -j DROP
curl localhost:9083
```

### DNS

```bash
# Inspect the current hosts entry
cat /etc/hosts | grep lab-network-api.local

# Fix: point the name back to 127.0.0.1
sudo sed -i '/lab-network-api.local/d' /etc/hosts
echo '127.0.0.1 lab-network-api.local' | sudo tee -a /etc/hosts

# Verify
getent hosts lab-network-api.local
journalctl -u lab-network-dns-client -f    # watch it recover
```

## Required commands

You should use at least these commands during the scenario:

```bash
ip addr
ip route
ss -tulpn
curl -v
getent hosts
sudo iptables -L -n -v
systemctl status <service-name>
journalctl -u <service-name>
```

Optional:

```bash
nslookup
dig
sudo tcpdump -i any port <port>
traceroute
ping
```

## Common failure modes

| Symptom | Likely cause | Key command |
|---|---|---|
| `connection refused` | Nothing listening on that port | `ss -tulpn` |
| `connection timeout` | Firewall dropping packets | `iptables -L -n -v` |
| Works locally, not from outside | Bound to `127.0.0.1` | `ss -tulpn` (check bind address) |
| Works by IP, fails by name | DNS / `/etc/hosts` broken | `getent hosts <name>` |

## DevOps mapping to cloud concepts

| Linux concept | Cloud / production equivalent |
|---|---|
| `ip addr` | Instance private/public IPs |
| `ip route` | VPC route tables |
| `iptables` | Security groups, NACLs, NetworkPolicy |
| `ss -tulpn` | Load balancer target port / container port |
| `/etc/hosts` | VPC DNS resolver / cluster DNS |
| `tcpdump` | VPC flow logs, service mesh telemetry |
| `127.0.0.1` binding | Pod-local vs. service-exposed ports in Kubernetes |

## Discussion prompts

* Why can a service be `active (running)` but still unreachable?
* What is the difference between `connection refused` and `connection timeout`?
* Why is binding to `127.0.0.1` safe for local-only services but wrong for externally accessed services?
* When would DNS be the real problem even though the application is healthy?
* How would this same failure show up in AWS, Kubernetes, or a corporate network?
* Why should we avoid changing firewall or route rules randomly in production?
* What evidence would you capture before applying a fix?

## Student deliverable

Students should submit a short incident note with:

```text
1. Symptom observed
2. Commands used
3. Evidence found
4. Root cause
5. Temporary mitigation
6. Permanent fix recommendation
7. How they verified recovery
```

## Root cause (facilitator key)

### `lab-network-wrong-port`

Service expected on `:9081`, but script hardcodes port `9181`.

```bash
sudo ss -tulpn | grep 9181
curl -v localhost:9081   # connection refused
curl -v localhost:9181   # works
```

Fix: update the script to bind to `9081`, or update callers to use `9181`.

### `lab-network-loopback`

Service binds to `127.0.0.1:9082` instead of `0.0.0.0:9082`.

```bash
sudo ss -tulpn | grep 9082   # shows 127.0.0.1:9082
curl localhost:9082           # works
curl <vm-ip>:9082             # connection refused
```

Fix: change bind address from `127.0.0.1` to `0.0.0.0`.

### `lab-network-firewalled`

iptables INPUT chain has a DROP rule for port `9083`.

```bash
sudo iptables -L INPUT -n -v   # shows DROP tcp dpt:9083
sudo tcpdump -i any port 9083  # SYN arrives, no reply
```

Fix: `sudo iptables -D INPUT -p tcp --dport 9083 -j DROP`

### `lab-network-dns-client`

`/etc/hosts` points `lab-network-api.local` to `192.0.2.1` (RFC 5737 TEST-NET, non-routable).

```bash
getent hosts lab-network-api.local   # returns 192.0.2.1
cat /etc/hosts                       # shows wrong entry
```

Fix: replace with `127.0.0.1 lab-network-api.local`.
