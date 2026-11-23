# AI Usage Statement — Michael Staron
  
**AI tool/model and date:** OpenAI ChatGPT (GPT-6), November 22, 2026 

## Purpose
I used ChatGPT as a reference, analysis, and documentation assistant while working on Homework 4, primarily for understanding the Task 1 and Task 2 requirements, preparing the Docker network environment, interpreting network traffic evidence, and reviewing our existing implementation against the assignment instructions. I also used ChatGPT to identify missing evidence, distinguish required work from optional suggestions, and help organize the incident overview and timeline for Task 5.

## AI Conversation Log Files
AI_LOG_STARON.txt

## What I Used
Task 1 and 2 — Assignment requirements: I supplied the homework PDF and asked ChatGPT to summarize the requirements, setup procedures, and required evidence. I also asked it to distinguish mandatory requirements from optional suggestions.

Environment setup: I asked which software dependencies were necessary and how to verify their installation. ChatGPT explained Docker, Nmap, tcpdump, TShark, and the difference between VMware NAT and Docker bridge networking.

Task 1 — Docker lab: I asked ChatGPT to review our Docker configuration, container addresses, mock skill, and C2 receiver against the assignment requirements.

Task 2 — Packet analysis: I asked about the required Nmap scan, packet captures, and TShark reconstruction. ChatGPT reviewed our malicious and clean PCAPs, including HTTP requests, TCP streams, timestamps, and SHA-256 hashes.

Partner coordination: I asked what files and evidence my partner needed for implementing the firewall and Suricata rules in Tasks 3 and 4.

Implementation review: I uploaded our repository ZIP and asked ChatGPT to identify missing evidence, inconsistencies, and unsupported conclusions in our work.

Task 5 — Incident summary: I asked ChatGPT to draft an incident overview and evidence-based timeline using our captured network traffic, leaving the remaining sections for my partner.

## What I Changed
I treated ChatGPT's explanations and analysis as references rather than automatically accepting its conclusions. I compared its findings against our existing implementation, assignment requirements, and recorded evidence. I also used its suggestions to organize the incident timeline while keeping conclusions limited to what our packet captures demonstrated.

## How I Tested It
I reviewed our Docker container status, network configuration, Nmap results, packet captures, and SHA-256 comparisons. The recorded evidence showed that the mock skill transmitted the fake token successfully and that the original and received file hashes matched. I also examined the malicious and clean captures to verify the HTTP traffic and exfiltration details.

ChatGPT reviewed these results but did not independently execute the entire lab in my Ubuntu VM. Firewall and Suricata functionality still required verification through their actual testing outputs.

## One Error, Limitation, or Rejected Suggestion
ChatGPT initially reported packet counts that excluded ARP frames, which it later corrected. Additionally, although it reviewed the firewall and Suricata configurations, it could not confirm their effectiveness without execution logs. The packet captures also could not prove that an autonomous AI agent followed the injected instruction, only that the simulated sequence occurred. I therefore treated these findings as limitations and avoided making unsupported claims in the report.

