# Module 1: IT Service Desk & Incident Management

## Executive Summary
Configured and administered an enterprise-grade IT Service Management (ITSM) environment using **ServiceNow**.
Designed and executed a structured incident management lifecycle, demonstrating proficiency in ticket triage, SLA prioritization, assignment routing, and technical documentation.

---

## Technical Stack & Frameworks
* **ITSM Platform:** ServiceNow (Personal Developer Instance)
* **Methodology:** ITIL-aligned Incident Management, Priority Calculation Matrix (Impact vs. Urgency), and Knowledge Base Logging.

---

## Simulated Enterprise Incident Queue
To simulate high-pressure corporate help desk operations, four distinct incidents were logged, categorized, prioritized, and assigned:

1. **INC0010009 (Critical):** Corporate Email Server Down - Exchange Outage
   * **Category:** Software / Email
   * **Matrix:** Impact: High | Urgency: High $\rightarrow$ **Priority: 1 - Critical**
   * **Assignment Group:** Service Desk
   * **Technician Work Note:** Initial triage complete. Multiple users affected. Escalating to L2 Server Team and restarting local Exchange transport service.
   * **Customer Visible Comment:** Hello, we are currently investigating the email server outage and working with the infrastructure team to restore connectivity. We will provide another update shortly.

2. **INC0010008 (High):** Finance Payroll System Inaccessible After Lockout
   * **Category:** Inquiry / Help
   * **Matrix:** Impact: Medium | Urgency: High $\rightarrow$ **Priority: 2 - High**
   * **Assignment Group:** Service Desk

3. **INC0010010 (Medium):** Mobile Device Email Synchronization Failure
   * **Category:** Software
   * **Matrix:** Impact: Medium | Urgency: Medium $\rightarrow$ **Priority: 3 - Moderate**
   * **Assignment Group:** Software

4. **INC0010011 (Low):** Request for Dual Monitor Stand
   * **Category:** Hardware
   * **Matrix:** Impact: Low | Urgency: Low $\rightarrow$ **Priority: 4 - Low**
   * **Assignment Group:** Hardware

---

## Lab Screenshots

### 1. Incident Form & Dual-Logging (Work Notes & Customer Comments)
*Demonstrates enterprise ticket formulation, automatic priority matrix calculation, private technician work notes, and external customer communication.*
![Incident Form]<img width="959" height="455" alt="incident-form" src="https://github.com/user-attachments/assets/8e4d8678-15dd-4789-95a3-2caa5186835b" />

### 2. Active Enterprise Incident Queue
*Displays the global service desk queue, organized by states, priorities, and assigned enterprise groups to prevent ticket backlogs[cite: 2].*
![Queue View]<img width="959" height="317" alt="queue-view" src="https://github.com/user-attachments/assets/76709302-9b75-49e0-a769-9f77802ca7d8" />

---

## Key Takeaways & Competencies Proved
* **Prioritization Discipline:** Effectively distinguished between system-wide critical outages and individual requests to ensure proper SLA compliance.
* **Operational Routing:** Automated queue management by routing tickets to dedicated assignment groups (Service Desk, Software, Hardware).
* **Institutional Knowledge:** Maintained clear separation between backend troubleshooting logs (**Work Notes**) and user updates (**Customer Comments**).
