# CSCE 465/765 Homework 4 — Detect and Block Agent Exfiltration

## Project Overview

This project demonstrates a simulated indirect prompt-injection and data-exfiltration attack in an isolated Docker environment.

The lab consists of three containers: an agent, a web server hosting benign and adversarial webpages, and a mock command-and-control (C2) server. A mock agent skill creates an unexpected TCP listener and can transmit a fake-secret token to the mock-C2 server.

The assignment demonstrates how to discover suspicious services, capture and analyze network traffic, prevent unauthorized communication using iptables, and detect malicious activity using Suricata.

All IP addresses and secrets are simulated. No real credentials or external C2 servers are involved.

**Environment:** Ubuntu 24.04 VirtualBox VM  
**Repository:** https://github.com/Mstar05/CSCE-465-765-HW4

## 1. Network Architecture

| Container | IP Address | Purpose |
|---|---|---|
| agent-node | 172.30.0.10 | Runs the mock agent skill |
| web-lab | 172.30.0.40 | Hosts benign and adversarial webpages on port 8000 |
| mock-c2 | 172.30.0.66 | Receives simulated exfiltration on port 8080 |

All three containers communicate over the private Docker bridge network `172.30.0.0/24`.

The host bridge interface is `br-hw4`.

The lab illustrates two important trust boundaries:

1. AI/model context boundary: untrusted webpage content influencing agent behavior.
2. Service-to-service boundary: unauthorized communication between the agent and mock-C2 containers.

## 2. Repository Files

| File | Description |
|---|---|
| Dockerfile | Builds the container image and installs required utilities |
| docker-compose.yml | Defines the three containers and Docker network |
| mock_skill.sh | Implements the mock skill, listener, and simulated exfiltration |
| c2.py | Receives HTTP POST requests and stores transmitted data |
| fake_secrets.txt | Contains the synthetic token |
| web/benign.html | Benign webpage used for control testing |
| web/adversarial.html | Webpage containing the indirect prompt-injection marker |
| firewall.sh | Installs the iptables firewall policy |
| firewall-reset.sh | Removes the custom firewall policy |
| local.rules | Contains three Suricata detection signatures |
| README.md | Instructions for reproducing the experiment |
| AI_USAGE.md | Documents AI assistance |
| report.pdf | Contains the experiment results and incident summary |

Packet captures are named `hw4-clean.pcap` and `hw4-malicious.pcap`.

## 3. Prerequisites

The experiment requires:

- Ubuntu 24.04
- Docker Engine
- Docker Compose v2
- Nmap
- tcpdump
- TShark
- netcat
- iptables
- Suricata

A VM snapshot is recommended before modifying firewall configurations.

### 3.1 Install Docker

If Docker is not installed, follow the official instructions:

https://docs.docker.com/engine/install/ubuntu/

Verify the installation:

```bash
docker --version
docker compose version
docker run --rm hello-world
```

Docker commands should execute successfully before proceeding.

### 3.2 Install Network Analysis Tools

```bash
sudo apt update
sudo apt install -y nmap tcpdump tshark netcat-openbsd iptables curl
```

### 3.3 Install Suricata

```bash
sudo apt install -y software-properties-common
sudo add-apt-repository -y ppa:oisf/suricata-stable
sudo apt update
sudo apt install -y suricata
```

Verify:

```bash
nmap --version
tcpdump --version
tshark --version
sudo iptables --version
suricata -V
```

Suricata 7.0.3 was used during the team's Task 4 testing.

## 4. Clone and Start the Lab

Clone the repository:

```bash
git clone https://github.com/Mstar05/CSCE-465-765-HW4.git
cd CSCE-465-765-HW4
```

All subsequent commands should be executed from the repository root unless otherwise specified.

Remove any existing Homework 4 firewall configuration:

```bash
./firewall-reset.sh
```

Build and start the Docker containers:

```bash
docker compose up -d --build
```

Verify that the containers are running:

```bash
docker compose ps
```

Inspect the network:

```bash
docker network inspect hw4net
```

Expected results:

- agent-node: 172.30.0.10
- web-lab: 172.30.0.40
- mock-c2: 172.30.0.66

Confirm that the agent can access the benign webpage:

```bash
docker compose exec -T agent-node curl --noproxy '*' -fsS http://172.30.0.40:8000/benign.html
```

The command should return the benign webpage content.

## 5. Task 1 — Reproduce the Mock Skill

The mock skill simulates an agent tool that performs unauthorized actions.

It starts a harmless listener on TCP port 9009 and, when provided with the argument `exfiltrate-course-file`, sends the fake-secret token to mock-C2.

### 5.1 Start the Listener

```bash
docker compose exec -T agent-node sh /app/mock_skill.sh
```

Check the listener:

```bash
nc -w 3 172.30.0.10 9009
```

Expected output:

```text
HW4 harmless banner
```

### 5.2 Reproduce the Simulated Exfiltration

Before testing, remove any previously received file:

```bash
docker compose exec -T mock-c2 rm -f /data/received.bin
```

Trigger the mock skill:

```bash
docker compose exec -T agent-node sh /app/mock_skill.sh exfiltrate-course-file
```

Expected result:

```text
HTTP status: 204
```

This indicates that the mock-C2 server accepted the HTTP POST request.

Verify the transmitted data:

```bash
sha256sum fake_secrets.txt
docker compose exec -T mock-c2 sha256sum /data/received.bin
```

The two SHA-256 hashes should match.

Matching hashes confirm that the fake-secret token was transmitted successfully.

This experiment must be performed before installing the firewall because the firewall is designed to block the connection.

## 6. Task 2 — Network Discovery and Packet Capture

Task 2 involves discovering the unexpected listener, recording benign and malicious traffic, and reconstructing the incident using packet analysis.

### 6.1 Discover the Listener Using Nmap

Ensure the mock skill has started its listener:

```bash
docker compose exec -T agent-node sh /app/mock_skill.sh
```

Perform a scoped scan:

```bash
nmap -sT -Pn -p 9009 172.30.0.10
```

Expected result: TCP port 9009 is open.

This identifies the unexpected network service created by the mock skill.

### 6.2 Capture Benign Traffic

Open two terminals in the repository directory.

In Terminal A, begin capturing traffic:

```bash
sudo tcpdump -i br-hw4 -s 0 -U -w hw4-clean-reproduced.pcap 'net 172.30.0.0/24'
```

In Terminal B, request the benign webpage:

```bash
docker compose exec -T agent-node curl --noproxy '*' -fsS http://172.30.0.40:8000/benign.html
```

Return to Terminal A and press Ctrl+C.

Verify the capture:

```bash
tcpdump -nn -r hw4-clean-reproduced.pcap
```

The capture should contain benign HTTP traffic without the injection marker or fake-secret exfiltration.

### 6.3 Capture Malicious Traffic

Ensure the firewall is disabled:

```bash
./firewall-reset.sh
```

Remove any previously received C2 file:

```bash
docker compose exec -T mock-c2 rm -f /data/received.bin
```

In Terminal A, begin capturing traffic:

```bash
sudo tcpdump -i br-hw4 -s 0 -U -w hw4-malicious-reproduced.pcap 'net 172.30.0.0/24'
```

In Terminal B, request the adversarial webpage:

```bash
docker compose exec -T agent-node curl --noproxy '*' -fsS http://172.30.0.40:8000/adversarial.html
```

Trigger the mock skill:

```bash
docker compose exec -T agent-node sh /app/mock_skill.sh exfiltrate-course-file
```

Return to Terminal A and stop tcpdump using Ctrl+C.

Expected results:

- The adversarial webpage contains the course injection marker.
- The mock skill sends the fake-secret token.
- The mock-C2 server responds with HTTP 204.
- The packet capture records the HTTP communication.

This command sequence manually reproduces the attack behavior; it does not independently demonstrate that an autonomous AI agent chose to execute the webpage instructions.

### 6.4 Analyze the Packet Captures

Display packets with readable timestamps:

```bash
tcpdump -nn -tttt -r hw4-malicious-reproduced.pcap
```

Inspect HTTP requests:

```bash
tshark -r hw4-malicious-reproduced.pcap -Y 'http.request'
```

Inspect HTTP responses:

```bash
tshark -r hw4-malicious-reproduced.pcap -Y 'http.response'
```

Inspect communication with mock-C2:

```bash
tshark -r hw4-malicious-reproduced.pcap -Y 'ip.addr == 172.30.0.66 && tcp.port == 8080'
```

These commands help reconstruct the sequence from the webpage request to the simulated exfiltration.

## 7. Task 3 — Firewall Implementation and Verification

Task 3 implements a stateful, default-deny firewall using iptables.

The firewall must:

1. Allow established and related traffic.
2. Allow new agent-to-web-lab connections on TCP port 8000.
3. Log and block new agent-to-mock-C2 connections on TCP port 8080.
4. Block other unauthorized new connections from the agent.
5. Preserve unrelated Docker traffic.

### 7.1 Install the Firewall

```bash
chmod +x firewall.sh firewall-reset.sh
./firewall.sh
```

Expected output:

```text
HW4 firewall installed successfully.
```

Inspect the rules:

```bash
sudo iptables -L DOCKER-USER -n -v --line-numbers
sudo iptables -L HW4-EGRESS -n -v --line-numbers
```

The `HW4-EGRESS` chain contains the firewall policy.

### 7.2 Test A — Allow Legitimate Web Traffic

```bash
docker compose exec -T agent-node curl --noproxy '*' -sS -o /dev/null -w '%{http_code}\n' http://172.30.0.40:8000/benign.html
```

Expected output:

```text
200
```

The firewall should allow the request.

Inspect counters:

```bash
sudo iptables -L HW4-EGRESS -n -v --line-numbers
```

The corresponding allow-rule counter should increase.

### 7.3 Test B — Block Agent-to-C2 Exfiltration

Remove the previously received file:

```bash
docker compose exec -T mock-c2 rm -f /data/received.bin
```

Attempt the exfiltration:

```bash
docker compose exec -T agent-node sh /app/mock_skill.sh exfiltrate-course-file
```

Expected result: the connection fails or times out instead of receiving HTTP 204.

Verify that the file was not received:

```bash
docker compose exec -T mock-c2 sh -c 'test ! -e /data/received.bin && echo "No exfiltration file received"'
```

Inspect firewall counters:

```bash
sudo iptables -L HW4-EGRESS -n -v --line-numbers
```

Inspect kernel logs:

```bash
sudo journalctl -k --no-pager | grep 'HW4-C2-DROP:' | tail
```

Expected log information:

```text
SRC=172.30.0.10 DST=172.30.0.66 DPT=8080
```

The team's verification observed three logged SYN packets matching the blocked connection.

### 7.4 Test C — Block Other Unauthorized Agent Egress

```bash
docker compose exec -T agent-node curl --noproxy '*' --connect-timeout 3 --max-time 5 http://172.30.0.40:8080/ || true
```

Expected result: the connection does not succeed.

Inspect the firewall counters:

```bash
sudo iptables -L HW4-EGRESS -n -v --line-numbers
```

The default-deny counter should increase.

### 7.5 Test D — Preserve Host-to-Agent Traffic

If the harmless listener is already running, connect to it:

```bash
nc -w 3 172.30.0.10 9009
```

Expected output:

```text
HW4 harmless banner
```

If the listener is not running, start it using the mock skill before retrying.

This confirms that the firewall does not interfere with the tested host-to-agent communication.

### 7.6 Test E — Preserve Unrelated Docker Traffic

Send a request from web-lab to mock-C2:

```bash
docker compose exec -T web-lab curl --noproxy '*' -sS -o /dev/null -w '%{http_code}\n' -X POST --data 'unrelated-service-test' http://172.30.0.66:8080/
```

Expected output:

```text
204
```

The firewall should permit this request because its source is web-lab rather than agent-node.

Inspect the counters:

```bash
sudo iptables -L HW4-EGRESS -n -v --line-numbers
```

### 7.7 Reset the Firewall

```bash
./firewall-reset.sh
```

Verify that the custom firewall chain has been removed:

```bash
sudo iptables -L DOCKER-USER -n -v --line-numbers
```

Reset the firewall before repeating the unrestricted attack demonstration.

## 8. Task 4 — Suricata Intrusion Detection

Task 4 evaluates three custom Suricata signatures against clean and malicious packet captures.

The rules are stored in `local.rules`.

### 8.1 Detection Rules

| SID | Detection |
|---|---|
| 1000001 | Fake-secret token in an outbound HTTP request |
| 1000002 | Indirect prompt-injection marker in an HTTP response |
| 1000003 | TCP connection attempt to the known mock-C2 server |

The first two rules inspect HTTP content. The third detects a TCP SYN packet directed toward mock-C2.

### 8.2 Validate the Rules

```bash
sudo suricata -T -c /etc/suricata/suricata.yaml -S local.rules
```

Expected result: successful rule validation.

### 8.3 Analyze the Malicious Capture

Create the output directory:

```bash
mkdir -p suricata-malicious
```

Run Suricata:

```bash
suricata -k none -r hw4-malicious.pcap -S local.rules -l suricata-malicious
```

View alerts:

```bash
cat suricata-malicious/fast.log
```

Expected alerts:

```text
HW4 Indirect-injection marker detected
HW4 Known mock-C2 connection detected
HW4 Fake-secret exfiltration detected
```

The team's verified malicious capture generated all three alerts.

### 8.4 Analyze the Clean Capture

```bash
mkdir -p suricata-clean
```

Run Suricata:

```bash
suricata -k none -r hw4-clean.pcap -S local.rules -l suricata-clean
```

View alerts:

```bash
cat suricata-clean/fast.log
```

Expected result: no matching alerts.

The `-k none` option disables checksum verification, which is important for Docker bridge captures affected by checksum offloading.

### 8.5 Detection Evaluation

| SID | Malicious PCAP | Clean PCAP |
|---|---|---|
| 1000001 | True Positive | True Negative |
| 1000002 | True Positive | True Negative |
| 1000003 | True Positive | True Negative |

No false positives or false negatives were observed in the team's two evaluated captures.

A limitation is that the signatures rely on known IP addresses, ports, and exact content patterns. Modified attacks or encrypted HTTP content may evade the corresponding detection rules.

## 9. Task 5 — Incident Summary

The final report includes a one-page incident summary reconstructing the attack.

The incident summary covers:

- The affected assets: agent-node, web-lab, and mock-C2.
- A timeline based on Task 2 packet timestamps.
- Preventive controls that failed or succeeded.
- Detective controls that generated alerts.
- Trust boundaries crossed during the incident.
- Two prioritized security improvements.

The primary trust boundaries were:

**AI/Model Context Boundary:** Untrusted webpage instructions influenced the agent's behavior.

**Service-to-Service Boundary:** The agent transmitted information to an unauthorized destination within the Docker network.

The original malicious capture demonstrated successful simulated exfiltration. The later firewall verification demonstrated that the same destination could be blocked by enforcing the Task 3 network policy.

These are separate experiments and should not be interpreted as a single continuous incident.

The recommended improvements are stronger handling of untrusted agent inputs and consistent enforcement of default-deny network egress.

## 10. Expected Results

| Experiment | Expected Result |
|---|---|
| Docker startup | Three containers running |
| Benign webpage request | HTTP 200 |
| Mock skill listener | TCP 9009 open |
| Nmap scan | Port 9009 discovered |
| Unrestricted exfiltration | HTTP 204 and matching SHA-256 hashes |
| Clean PCAP | Benign traffic |
| Malicious PCAP | Adversarial response and outbound POST |
| Firewall allowed-traffic test | HTTP 200 |
| Firewall blocked-C2 test | Connection blocked |
| Firewall default-deny test | Unauthorized connection blocked |
| Firewall host-to-agent test | Banner returned |
| Firewall unrelated-service test | HTTP 204 |
| Suricata rule validation | Successful |
| Suricata malicious capture | Three expected signatures fire |
| Suricata clean capture | No matching alerts |

## 11. Troubleshooting

### Docker Containers Do Not Start

Check Docker status:

```bash
sudo systemctl status docker
```

Inspect container status:

```bash
docker compose ps
```

Inspect logs:

```bash
docker compose logs --tail=100
```

Verify that the Docker subnet does not conflict with another network.

### TCP Port 9009 Is Closed

Ensure that the mock skill has started its listener:

```bash
docker compose exec -T agent-node sh /app/mock_skill.sh
```

Repeat the Nmap scan.

### Exfiltration Fails Before Installing the Firewall

Reset any existing Homework 4 firewall rules:

```bash
./firewall-reset.sh
```

Check the C2 container:

```bash
docker compose logs mock-c2
```

### Exfiltration Succeeds After Installing the Firewall

Inspect the custom firewall chain:

```bash
sudo iptables -L HW4-EGRESS -n -v --line-numbers
```

Check whether the chain is referenced by DOCKER-USER:

```bash
sudo iptables -L DOCKER-USER -n -v --line-numbers
```

Confirm that bridge netfilter is enabled:

```bash
sudo sysctl net.bridge.bridge-nf-call-iptables
```

### Suricata Does Not Generate Alerts

Confirm that the rule file exists and validates successfully.

Ensure that the packet capture contains the expected malicious traffic.

Use `-k none` to account for checksum offloading.

Verify that the token in `local.rules` matches the token contained in the recorded malicious capture.

If a new token is generated, the corresponding signature must be updated before testing.

### Suricata Output Directory Does Not Exist

Create the required directory before executing Suricata:

```bash
mkdir -p suricata-malicious suricata-clean
```

## 12. Cleanup

Remove the Homework 4 firewall policy:

```bash
./firewall-reset.sh
```

Stop the Docker containers:

```bash
docker compose down
```

To additionally remove the associated Docker volumes:

```bash
docker compose down -v
```

Only remove volumes if the stored mock-C2 evidence is no longer needed.

Retain packet captures and report evidence until grading is complete.

**Reproducibility note:** The commands should be verified from a clean environment before final submission. The README documents the team's recorded experiments but has not independently been tested end-to-end on a fresh VM.
