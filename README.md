# CSCE 465/765 Homework 4

Local Docker lab for investigating simulated agent data exfiltration.

## Team
- Michael Staron
- Avantiki Sahoo

## Environment
Ubuntu course VM using NAT networking.

## Lab services
- agent-node: 172.30.0.10
- web-lab: 172.30.0.40:8000
- mock-c2: 172.30.0.66:8080
- Bridge: br-hw4
- Subnet: 172.30.0.0/24

## Start
docker compose up -d --build

## Stop
docker compose down

## Evidence
- evidence/task1/
- evidence/task2/
- screenshots/
- hw4-malicious.pcap
- hw4-clean.pcap

