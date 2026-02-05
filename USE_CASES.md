# Use Cases & User Personas

> **Purpose**: This document defines the target users, use cases, and expected behaviors for the Agentforce AI agents in this demo environment. It serves as a guide for development, testing, and demonstration scenarios.

---

## Table of Contents

- [Industry Context](#industry-context)
- [User Personas](#user-personas)
  - [Sales Personas (Hank)](#sales-personas-hank)
  - [Patient Services Personas (ARIA/Juno)](#patient-services-personas-ariajuno)
- [Agent Topic Architecture](#agent-topic-architecture)
- [Core Use Cases](#core-use-cases)
  - [Sales Use Cases (Hank)](#sales-use-cases-hank)
  - [Patient Services Use Cases (ARIA/Juno)](#patient-services-use-cases-ariajuno)
- [Routing Decision Framework](#routing-decision-framework)
- [Success Criteria](#success-criteria)
- [Future Considerations](#future-considerations)

---

## Industry Context

This demo environment is designed for **pharmaceutical, life sciences, and medical technology** companies. The AI agents support field-based commercial teams who interact with healthcare professionals (HCPs), healthcare organizations (HCOs), and other stakeholders in the healthcare ecosystem.

### Key Industry Characteristics

| Characteristic | Implication for AI Agents |
|----------------|---------------------------|
| **Highly regulated** | Compliance tracking (samples, materials) is critical |
| **Relationship-driven** | Meeting quality matters more than quantity |
| **Mobile workforce** | Reps are often in cars, between appointments |
| **Complex sales cycles** | Multiple touchpoints, long decision timelines |
| **Specialized knowledge** | Products, therapies, and clinical data |
| **Territory-based** | Reps own geographic regions and account relationships |

### Common Terminology

| Term | Definition |
|------|------------|
| **HCP** | Healthcare Professional (physicians, nurses, pharmacists) |
| **HCO** | Healthcare Organization (hospitals, clinics, practices) |
| **KOL** | Key Opinion Leader (influential HCPs in a therapeutic area) |
| **Formulary** | List of approved drugs/products at a healthcare organization |
| **Sample** | Product samples provided to HCPs (heavily regulated) |
| **Detail** | A sales call or meeting with an HCP |
| **Territory** | Geographic region assigned to a rep |
| **Pipeline** | Active sales opportunities / deals in progress |
| **Forecast** | Predicted revenue, typically categorized by confidence level |

---

## User Personas

### Primary Persona: Field Sales Representative

**Role**: Pharmaceutical Sales Rep / Medical Device Rep / Territory Manager

**Profile**:
- Spends 80% of time in the field visiting accounts
- Manages 50-200 HCP/HCO relationships
- Mobile-first: uses phone/tablet between appointments
- Time-constrained: often has 5-10 minutes between calls
- Measured on call activity, sample compliance, and revenue

**Technology Context**:
- Often dictating or typing quickly while in car
- May use voice-to-text (Siri, Google Assistant)
- Expects fast, low-friction interactions
- Will abandon tools that slow them down

**Key Frustrations**:
- Spending time on admin instead of selling
- Having to remember exact names/spellings
- Systems that require too many clicks or fields
- Losing meeting notes because logging was too hard
- Can't quickly update deals while on the go

**What They Say**:
> "I just finished with Dr. Smith, I have 10 minutes before my next call. I need to log this meeting and move on."

> "I know who I met with. Why is the system making me search for them?"

> "Just log it. I'll add more details later if I need to."

> "The Memorial deal just went to negotiation. Can I update that from my phone in 30 seconds?"

---

### Secondary Persona: Sales Manager / District Manager

**Role**: First-line sales manager overseeing 8-12 field reps

**Profile**:
- Reviews rep activity and coaching opportunities
- Needs visibility into territory coverage and meeting quality
- Relies on CRM data for forecasting and planning
- Conducts field rides with reps periodically

**What They Need from AI Agents**:
- Rich meeting data (not just "had a meeting")
- Outcome tracking (productive vs. needs follow-up)
- Follow-up visibility (are reps closing the loop?)
- Pipeline accuracy and forecast confidence
- Competitive intelligence capture

**What They Say**:
> "I need to see what's really happening in the field, not just that calls are being made."

> "If a rep loses an account to a competitor, I need to know about it."

> "The best meeting logs tell a story - who, what, how it went, what's next."

> "Show me committed deals closing this quarter - are we going to hit our number?"

---

### Tertiary Persona: Commercial Operations / Sales Ops

**Role**: Supports field teams with data, analytics, and systems

**Profile**:
- Configures and maintains Salesforce/CRM
- Creates reports and dashboards
- Ensures data quality and compliance
- Trains reps on tools and processes

**What They Need**:
- Consistent data capture across reps
- Compliance fields populated (samples, materials)
- Clean account/contact data
- Automation that reduces manual work
- Accurate pipeline data for forecasting

---

## Patient Services Personas (ARIA/Juno)

### Primary Persona: Patient Services Representative (ARIA User)

**Role**: Hub Services Rep / Patient Support Coordinator / Enrollment Specialist

**Profile**:
- Handles inbound and outbound patient communications
- Manages enrollment workflows for patient support programs
- Conducts benefits verification (BV) and eligibility checks
- Tracks missing documentation and follow-ups
- Coordinates with specialty pharmacies and providers

**Technology Context**:
- Desktop-based, working from a call queue
- Multiple systems open simultaneously (CRM, pharmacy portals, insurance tools)
- Needs quick access to patient information during calls
- Values efficiency and reduced data entry

**Key Frustrations**:
- Switching between multiple systems to find patient info
- Manually tracking what documents are missing from each patient
- Repetitive data entry across enrollment steps
- Losing context when patients call back

**What They Say**:
> "I have the patient on the phone - I need to see their full enrollment status in one place."

> "What's still missing from this patient before I can move them forward?"

> "Can you run a BV while I'm talking to them?"

> "I need to schedule her injection appointment and log this call."

---

### Secondary Persona: Patient (Juno User - B2C)

**Role**: Patient enrolling in or managing their support program

**Profile**:
- Chronic condition requiring specialty medication (e.g., osteoporosis/Prolia)
- May not be tech-savvy
- Often anxious about insurance, costs, and treatment
- Values clear communication and quick answers

**Technology Context**:
- Using web portal or chat interface
- May access from mobile device
- Expects self-service capabilities
- Wants human escalation available when needed

**Key Frustrations**:
- Not knowing the status of their enrollment
- Difficulty scheduling appointments
- Confusion about what information is needed
- Long hold times to speak with a representative

**What They Say**:
> "I submitted my enrollment last week - has anything happened?"

> "I need to reschedule my appointment for next week."

> "What are the side effects of this medication?"

> "I can't remember if I sent my insurance card."

---

### Tertiary Persona: Healthcare Provider (Juno User - B2B)

**Role**: Physician, nurse, or office staff managing patient enrollments

**Profile**:
- Time-constrained, often checking status between patients
- Manages multiple patients in support programs
- Needs to verify patient eligibility quickly
- May delegate to office staff

**What They Need**:
- Quick patient status lookup
- Ability to refer new patients to programs
- Confirmation that patients are enrolled and compliant
- Easy appointment scheduling for patients

---

## Agent Topic Architecture

### Design Philosophy

The agent's topic structure is designed around **user intent**, not CRM objects. A sales rep doesn't think "I need to create an Opportunity record" - they think "I need to update my deal." Topics should map to how reps naturally talk about their work.

### Topic Structure Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           HANK AGENT - TOPIC MAP                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  📊 PIPELINE & DEALS                                                        │
│     Purpose: Manage sales opportunities and forecast                        │
│     Keywords: deal, opportunity, pipeline, forecast, stage, close date,     │
│               amount, commit, best case, products on deal                   │
│     Actions: Opportunity Action                                             │
│                                                                             │
│  📝 ACTIVITY LOGGING                                                        │
│     Purpose: Record meetings, calls, visits, and tasks                      │
│     Keywords: log, record, had a meeting, called, visited, met with,        │
│               task, follow up, remind me                                    │
│     Actions: Meeting Action, Task Action                                    │
│                                                                             │
│  🔍 ACCOUNT RESEARCH                                                        │
│     Purpose: Get background intelligence on companies                       │
│     Keywords: tell me about, what do we know about, background on,          │
│               research on, intel on, brief me on                            │
│     Actions: Account Intelligence (prompt template)                         │
│                                                                             │
│  📇 CRM DATA MANAGEMENT                                                     │
│     Purpose: Create/update records in the CRM                               │
│     Keywords: create account, update contact, find account,                 │
│               change address, add phone number                              │
│     Actions: Account Action, Contact Action, Case Action, Email Action      │
│                                                                             │
│  📦 ORDERS & FULFILLMENT                                                    │
│     Purpose: Manage customer orders and line items                          │
│     Keywords: order, shipment, line item, order status                      │
│     Actions: Customer Order Action                                          │
│                                                                             │
│  💊 SPECIALIZED TOPICS                                                      │
│     - Diagnostic Test Results                                               │
│     - Insurance & Benefits Verification                                     │
│     - Billing Requests & Triage                                             │
│     - Potential Adverse Events                                              │
│     - Correspondence/Email                                                  │
│     - General Q&A (Knowledge Base)                                          │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Topic Routing Principles

1. **Intent Over Entity**: Route based on what the user wants to *do*, not what object they're touching
2. **Explicit Claims**: Each topic should explicitly claim its trigger phrases
3. **Explicit Exclusions**: Each topic should explicitly exclude what it doesn't handle
4. **Natural Language**: Trigger phrases should match how people actually talk

---

## Core Use Cases

### Use Case 1: Pipeline & Deal Management (PRIMARY)

**Description**: Sales rep updates, queries, or manages their sales opportunities.

**Trigger Phrases**:
- "Update the [account] deal to [stage]"
- "Move [opportunity] to proposal/negotiation/closed won"
- "The [account] deal is now worth $X"
- "Push the close date to [date]"
- "This is a commit for the quarter"
- "What deals do I have in proposal stage?"
- "What's closing this month?"
- "Add [product] to the [deal]"

**Expected Agent Behavior**:
1. Find the opportunity by account name or opportunity name
2. Update the requested fields (stage, amount, close date, forecast, etc.)
3. Confirm the update was made
4. For line items, manage products on the opportunity

**Key Fields**:
- StageName (Prospecting → Qualification → Proposal → Negotiation → Closed)
- Amount (deal value)
- CloseDate (expected close)
- ForecastCategoryName (Pipeline, Best Case, Commit, Closed)
- NextStep (action items)
- Products/Line Items (OpportunityLineItem)

**Routing Clarity**:
- Any mention of "deal", "opportunity", "pipeline", "stage", "amount", "forecast" → Pipeline & Deals
- Company name + deal context → Pipeline & Deals (NOT Account Research)
- "Memorial Hospital deal" is about the OPPORTUNITY, not researching the account

**Success Criteria**:
- Deal updated in ≤2 conversational turns for typical updates
- Fuzzy matching on opportunity/account names works
- Multi-field updates in single request supported

---

### Use Case 2: Meeting Logging (PRIMARY)

**Description**: Field rep logs a meeting/call/visit with an HCP or HCO after the interaction.

**Trigger Phrases**:
- "Log a meeting with..."
- "Had a call with..."
- "Just left [account/contact]..."
- "Met with..."
- "Record a meeting..."
- "I had a tough meeting at..."

**Required Data** (Minimum Viable Meeting):
- Who (Contact and/or Account)
- When (Date - often inferred from "today", "yesterday", "just left")
- What type (In-Person, Phone, Virtual, Conference)
- How it went (Outcome)

**Desired Data** (Rich Meeting):
- Description/summary of discussion
- Products or therapies discussed
- Next steps / follow-up items
- Samples dropped off (Y/N)
- Marketing materials provided (Y/N)
- Competitive mentions

**Expected Agent Behavior**:
1. Accept natural language input with minimal friction
2. Infer what can be inferred (date, meeting type, outcome)
3. Probe for critical missing data (but don't over-ask)
4. Create the meeting record
5. Offer to create follow-up tasks if next steps mentioned
6. Offer to create new contacts if mentioned

**Routing Clarity**:
- "I had a meeting at Memorial Hospital" → Activity Logging (NOT Account Research)
- Negative meetings (tough, challenging, disaster) still get logged here
- Any explicit mention of "log", "record", "meeting", "call", "visit" → Activity Logging

**Success Criteria**:
- Meeting created in ≤3 conversational turns for typical scenarios
- Rep never blocked from creating a meeting due to contact lookup
- Rich data captured when rep provides it
- Graceful handling when data is sparse

---

### Use Case 3: Account Research & Daily Brief

**Description**: Get pre-gathered intelligence and research about a company, or receive a comprehensive daily briefing on market news, industry trends, and account updates.

**Account Intelligence - Trigger Phrases**:
- "Tell me about [account]..."
- "What do we know about [company]..."
- "Give me background on..."
- "Research on [account]..."
- "Brief me before my meeting at..."
- "Intel on [company]..."

**Daily Brief - Trigger Phrases**:
- "Give me my daily brief"
- "Morning briefing"
- "What's the news?"
- "Catch me up"
- "Market update"
- "Start my day"
- "What's happening in the industry?"

**Expected Agent Behavior - Account Intelligence**:
1. Retrieve Account_Intel__c records for the specified account
2. Surface relevant CRM data (recent meetings, open opportunities, key contacts)
3. Provide external intelligence where available
4. Summarize key insights

**Expected Agent Behavior - Daily Brief**:
1. Generate comprehensive briefing covering:
   - Quick Account Updates (CRM, PR Newswire, portal data, ERP)
   - Inside the House (company announcements, internal updates)
   - Market Overview (healthcare trends, hospital purchasing, treatment decisions)
   - Clinical and Biologic Updates (drug approvals, trial results, HCP implications)
   - Med-Surg and Diagnostic Tech (device news, AI diagnostics, surgical workflows)
   - Corporate and Strategic Moves (M&A, partnerships, competitive landscape)
2. Present in an easily digestible, podcast-style format

**Routing Clarity**:
- **IS** Account Research: "Tell me about Memorial Hospital", "What do we know about Accusage?"
- **IS** Daily Brief: "What's the news today?", "Give me my morning update", "Start my day"
- **NOT** Account Research: "Update the Memorial Hospital deal", "Log my meeting at Accusage"
- The presence of a company name does NOT automatically mean Account Research
- Research = wanting to LEARN about an account or market
- NOT Research = wanting to DO something involving an account (log meeting, update deal)

**Success Criteria**:
- Account intel surfaced quickly with actionable summaries
- Daily Brief provides relevant, timely industry updates
- Properly distinguished from activity logging and pipeline management

---

### Use Case 4: Task Creation & Follow-up Tracking

**Description**: Create tasks to track follow-up items from meetings or independent action items.

**Trigger Phrases**:
- "Create a task to..."
- "Remind me to..."
- "I need to follow up on..."
- "Schedule a follow-up..."
- [Automatically offered after meeting with next steps]

**Expected Agent Behavior**:
1. Create task linked to appropriate Account/Contact
2. Set reasonable due dates based on context
3. Capture task description from conversation
4. Link to related meeting if applicable

---

### Use Case 5: CRM Data Management

**Description**: Create, update, or find records in the CRM (accounts, contacts, cases).

**Trigger Phrases**:
- "Create an account for..."
- "Update [contact]'s phone number..."
- "Find the contact for..."
- "Change the address on..."
- "Add a new contact at [account]..."

**Routing Clarity**:
- Explicit CRUD operations on CRM entities → CRM Data Management
- This is NOT for deal/opportunity updates (→ Pipeline & Deals)
- This is NOT for meeting/task logging (→ Activity Logging)

---

### Use Case 6: Orders & Fulfillment

**Description**: Track and manage customer orders.

**Trigger Phrases**:
- "Check order status for..."
- "What orders does [account] have?"
- "Create an order for..."
- "Update the line items on order..."

---

### Use Case 7: Email/Correspondence

**Description**: Draft and send professional correspondence to contacts.

**Trigger Phrases**:
- "Send an email to..."
- "Draft a follow-up email..."
- "Write a thank you note to..."

---

## Patient Services Use Cases (ARIA/Juno)

### Use Case PS-1: Patient Enrollment (ARIA & Juno)

**Description**: Enroll a new patient in a support program, collecting required information incrementally.

**ARIA Trigger Phrases** (Internal Rep):
- "Start a new enrollment for [patient name]"
- "Pull up [patient]'s enrollment"
- "Move [patient] to Benefits Verification"
- "What's the status on [patient]'s enrollment?"

**Juno Trigger Phrases** (External Patient):
- "I need to enroll in the Prolia support program"
- "What's the status of my enrollment?"
- "I want to sign up for patient assistance"

**Expected Agent Behavior**:
1. Collect minimum required info (name, DOB, email, phone)
2. Create Program_Candidate__c record
3. Incrementally gather additional info (address, insurance)
4. Move through enrollment statuses (New Inquiry → Information Gathering → Benefits Verification → Approved → Enrolled)
5. Confirm enrollment and explain next steps

**Key Fields**: FirstName__c, LastName__c, Date_of_Birth__c, Email__c, Phone__c, Insurance_Provider__c, Insurance_Policy_Number__c, Enrollment_Status__c

---

### Use Case PS-2: Missing Information Tracking (ARIA)

**Description**: Track and manage documents/data needed from patients.

**Trigger Phrases**:
- "What's missing for [patient]?"
- "We need [patient]'s consent form"
- "Add insurance card to missing items"
- "[Patient] sent her insurance card" / "Mark it received"

**Expected Agent Behavior**:
1. Find all Missing_Information__c records for a patient
2. Create new missing info items when needed
3. Update status to "Received" when documents arrive
4. Report counts (X missing, Y received)

**Information Types**: Insurance Card, Member ID, Income Verification, Date of Birth, Prescription, Consent Form, ID Document, Address Verification, Contact Information, Other

---

### Use Case PS-3: Benefits Verification (ARIA)

**Description**: Check patient insurance coverage via Thespis API.

**Trigger Phrases**:
- "Run a benefits check for [patient]"
- "Check [patient]'s insurance coverage"
- "Is her coverage active?"
- "BV [patient name]"

**Expected Agent Behavior**:
1. Call Thespis getCoverages API with patient insurance info
2. Display coverage status (active/inactive)
3. Show plan details, copay, deductible info
4. Offer to update enrollment record with results

---

### Use Case PS-4: Appointment Management (ARIA & Juno)

**Description**: View, schedule, reschedule, or cancel patient appointments.

**ARIA Trigger Phrases** (Internal Rep):
- "Show me [patient]'s appointments"
- "When can we schedule her next injection?"
- "Move her Thursday appointment to Friday"
- "Cancel her appointment"

**Juno Trigger Phrases** (External Patient):
- "When is my next appointment?"
- "I need to schedule a Prolia injection"
- "I need to reschedule my appointment"
- "Cancel my appointment"

**Expected Agent Behavior**:
1. Retrieve appointments via Thespis getAppointments
2. Find available slots via Thespis getSlots
3. Book/reschedule/cancel via Thespis updateAppointment
4. Confirm changes and provide details

---

### Use Case PS-5: Diagnostic Test Orders (ARIA & Juno)

**Description**: Check status of lab and diagnostic test orders.

**Trigger Phrases**:
- "What's the status of [patient]'s blood panel?"
- "Does [patient] have any tests pending?"
- "Are her lab results back yet?"

**Expected Agent Behavior**:
1. Search Diagnostic_Test_Order__c for patient
2. Report status (Ordered, Processing, Ready)
3. **Privacy**: For Juno (external), status only - never share actual results. Direct to provider.

---

### Use Case PS-6: Case Management (ARIA)

**Description**: Handle support cases, escalations, and callback requests.

**Trigger Phrases**:
- "Does [patient] have any open cases?"
- "Create a support case for [patient]"
- "Catch me up on [patient]'s case"
- "Change the case to In Progress"

**Expected Agent Behavior**:
1. Find/create/update Case records
2. Provide TL;DR summary of case history
3. Manage case status and priority
4. Link to appropriate Account/Contact

---

### Use Case PS-7: Activity Logging (ARIA)

**Description**: Log contact attempts, calls, and emails.

**Trigger Phrases**:
- "I just called [patient] - no answer"
- "Log that I spoke with [patient] about insurance"
- "I sent [patient] an email about her appointment"
- "Create a task to call [patient] tomorrow"

**Expected Agent Behavior**:
1. Create Task records for contact attempts
2. Log completed calls with notes
3. Record email communications
4. Schedule follow-up tasks

---

### Use Case PS-8: Drug/Therapy Questions (Juno)

**Description**: Answer patient questions about medications using knowledge base.

**Trigger Phrases**:
- "Can you tell me about Prolia?"
- "What are the side effects?"
- "How does this medication work?"

**Expected Agent Behavior**:
1. Use knowledge retriever to find relevant information
2. Provide accurate, patient-friendly explanations
3. Include appropriate safety guidance
4. Offer escalation to healthcare provider for medical advice

---

## Routing Decision Framework

When the agent receives a message, use this framework to determine the correct topic:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        ROUTING DECISION TREE                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Does the message mention:                                                  │
│  "deal", "opportunity", "pipeline", "stage", "amount", "forecast",          │
│  "close date", "commit", "best case", "products on"?                        │
│                                                                             │
│      YES → PIPELINE & DEALS                                                 │
│      │                                                                      │
│      └── Examples:                                                          │
│          • "Update the Memorial deal to proposal"                           │
│          • "The Accusage opportunity is now $200K"                          │
│          • "Move University Medical to negotiation"                         │
│                                                                             │
│  Does the message mention:                                                  │
│  "log", "record", "meeting", "called", "visited", "met with",               │
│  "had a", "just left", "task", "follow up", "remind me"?                    │
│                                                                             │
│      YES → ACTIVITY LOGGING                                                 │
│      │                                                                      │
│      └── Examples:                                                          │
│          • "Log my meeting with Dr. Smith at Memorial"                      │
│          • "I just called Accusage about their order"                       │
│          • "Create a task to follow up with University Medical"             │
│                                                                             │
│  Does the message explicitly ask for research/background/intel?             │
│  "tell me about", "what do we know about", "background on",                 │
│  "research", "intel on", "brief me on"?                                     │
│                                                                             │
│      YES → ACCOUNT RESEARCH                                                 │
│      │                                                                      │
│      └── Examples:                                                          │
│          • "Tell me about Memorial Hospital"                                │
│          • "What do we know about Accusage?"                                │
│          • "Brief me before my call with University Medical"                │
│                                                                             │
│  Is this explicit CRM record manipulation?                                  │
│  "create account", "update contact", "find", "change address"               │
│                                                                             │
│      YES → CRM DATA MANAGEMENT                                              │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Common Misrouting Scenarios to Avoid

| User Says | WRONG Topic | CORRECT Topic | Why |
|-----------|-------------|---------------|-----|
| "Update the Memorial deal to proposal" | Account Research | Pipeline & Deals | "deal" = opportunity context |
| "The Accusage opportunity is $150K now" | Account Research | Pipeline & Deals | "opportunity" + "amount" = pipeline |
| "I had a meeting at Memorial Hospital" | Account Research | Activity Logging | "had a meeting" = activity logging |
| "What deals do I have with Accusage?" | Account Research | Pipeline & Deals | "deals" = opportunities |
| "What's closing this month?" | Account Research | Pipeline & Deals | pipeline/forecast query |

---

## Success Criteria

### For Field Reps

| Metric | Target | Rationale |
|--------|--------|-----------|
| **Time to log meeting** | < 60 seconds for typical scenario | Reps have limited time |
| **Time to update deal** | < 30 seconds for stage/amount update | Quick pipeline hygiene |
| **Conversational turns** | ≤ 3 turns for standard operations | Minimize back-and-forth |
| **Blocking errors** | 0% - never block record creation | Data capture is the priority |
| **Correct routing** | 95%+ first-time routing | Users shouldn't need to re-explain |
| **Contact/Account resolution** | 90%+ when record exists | Fuzzy matching should work |

### For Data Quality

| Metric | Target | Rationale |
|--------|--------|-----------|
| **Meeting Type populated** | 100% | Inference should handle this |
| **Meeting Outcome populated** | 100% | Critical for reporting |
| **Opportunity Stage accurate** | 100% | Pipeline integrity |
| **Description populated** | 90%+ | Context matters |
| **Sample tracking accurate** | 100% | Compliance requirement |

### For User Experience

| Principle | Description |
|-----------|-------------|
| **Never block** | Always provide a path forward, even with missing data |
| **Infer aggressively** | Use context clues to populate fields |
| **Route correctly** | First topic should be right 95%+ of the time |
| **Ask once** | Don't repeatedly ask for the same information |
| **Acknowledge frustration** | If user says "just log it", do it |
| **Offer, don't require** | Task/contact creation should be offered, not forced |

### Demo Mode Philosophy

This is a **demo environment** - prioritize a frictionless user experience over enterprise-grade data quality:

| Scenario | Demo Mode Behavior |
|----------|-------------------|
| **Multiple matches found** | Pick the most recent one and proceed |
| **Contact not found** | Create the meeting anyway, offer to create contact |
| **Opportunity name is sloppy** | Fuzzy match on account name + keywords |
| **Product name is sloppy** | Fuzzy match, case-insensitive, normalized |
| **Date not specified** | Default to today |
| **Order vs Opportunity ambiguous** | Ask clarifying question, then proceed |
| **Account name has suffix issues** | "Accusage" should match "Accusage, Inc." |

**Key Principle:** For demos, it's better to create a record with slightly imperfect data than to block the user and require perfect input.

---

## Future Considerations

### Completed Enhancements ✅

- [x] **Dedicated "Pipeline & Deals" topic** - Manages opportunities, forecasts, deal products with clear routing claims
- [x] **Renamed "Account Intelligence" to "Account Research"** - Narrowed scope to pre-gathered intel only
- [x] **Split "General CRM Updates" into focused topics** - Now: Pipeline & Deals, Activity Logging, CRM Data Management, Orders & Fulfillment, Correspondence
- [x] **Fuzzy opportunity search** - "permadyne oncology" finds "Permadyne GmbH, LTD - Oncology Treatment Protocol"
- [x] **Fuzzy product matching** - "cardiomonitor pros" finds "CardioMonitor Pro"
- [x] **Order vs Opportunity clarification** - Agent asks when request is ambiguous
- [x] **Graceful failure handling** - Agent suggests close matches and offers to create when not found
- [x] **Daily Brief integration** - Morning briefings on market news and account updates

### Remaining Enhancements

- [ ] Voice-optimized interactions
- [ ] Pre-call planning assistance ("Brief me before my meeting")
- [ ] Competitive intelligence capture
- [ ] Multi-turn context retention improvements

### Potential Future Use Cases

| Use Case | Description | Priority |
|----------|-------------|----------|
| **Pre-call Planning** | "Brief me on my meeting with [account] tomorrow" | High |
| **Pipeline Review** | "Walk me through my deals closing this quarter" | High |
| **Activity Reporting** | "What did I log this week?" | Medium |
| **Territory Overview** | "How am I doing on my call targets?" | Medium |
| **Coaching Insights** | (Manager) "Show me [rep]'s recent activity" | Medium |

---

## Document History

| Date | Author | Changes |
|------|--------|---------|
| 2026-01-16 | AI Agent | Added Patient Services personas (ARIA/Juno) and use cases PS-1 through PS-8 |
| 2026-01-10 | AI Agent | Added Pipeline & Deals use case, Topic Architecture section, Routing Decision Framework |
| 2026-01-09 | AI Agent | Updated completed enhancements, documented fuzzy search and demo mode improvements |
| 2026-01-10 | AI Agent | Initial framework creation |

---

*Last Updated: January 16, 2026*
