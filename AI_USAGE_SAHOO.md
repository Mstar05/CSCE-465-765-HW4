# AI Usage Description

**Tool/model and date:**  
ChatGPT (OpenAI, GPT-6), November 2026.

**Purpose:**  
I used ChatGPT to assist with implementing, understanding, testing, and documenting Tasks 3 and 4 of Homework 4, as well as preparing my portion of the Task 5 incident summary. Specifically, I used AI to help understand iptables firewall rules, Suricata IDS signatures, trust boundaries, and possible security improvements. I also used it for Git guidance, drafting the AI usage document, and drafting the README.

**AI Conversation Log files:**  
AI_LOG_SAHOO.html

**AI Conversation Chat link:** 
https://chatgpt.com/share/6b0388a1-01b4-83ea-b9d1-8ec84cc51e4b

**What I used:**  
I used ChatGPT's explanations and suggestions to help develop the `firewall.sh` and `firewall-reset.sh` scripts for Task 3 and the three detection rules in `local.rules` for Task 4. I also used AI assistance to understand the firewall verification tests, interpret Suricata alerts, and identify preventive controls, detective controls, and trust boundaries for Task 5.

**What I changed:** 
I reviewed the suggested explanations and selected the trust boundaries, and improvements most relevant to the experiment. I wrote the report explanations in my own words.

**How I tested it:** 
I tested the firewall by verifying that legitimate agent-to-web traffic succeeded, unauthorized agent-to-mock-C2 traffic was blocked, and unrelated Docker traffic continued functioning. I inspected iptables packet counters and kernel logs to confirm the filtering behavior. For Suricata, I validated the rules using `suricata -T` and analyzed both `hw4-malicious.pcap` and `hw4-clean.pcap`. The malicious capture generated all three expected alerts, while the clean capture generated none.

**One error, limitation, or rejected suggestion:**  
One suggestion I rejected was the list of keywords the agent provided. The agent provided both keywords and components. As a result, I did not use what the AI provided, and instead searched up what parts of the rules were keywords, and their definitions. 
