# Pat Dennis Agentforce SDO Assets

A comprehensive library of production-ready Agentforce components for building intelligent AI agents on Salesforce. This repository provides reusable Apex actions, utilities, and configurations that accelerate Agentforce implementations for Salesforce employees, implementation partners, and customers.

## 🎯 Purpose

This repository serves as a hub for high-quality Agentforce technology assets. Whether you're a Salesforce employee building demos, an implementation partner deploying customer solutions, or a customer exploring Agentforce capabilities, these components provide battle-tested patterns for common AI agent use cases.

## 👥 Who This Is For

- **Salesforce Employees** - Accelerate demos, POCs, and customer implementations
- **Implementation Partners** - Leverage pre-built components for faster project delivery
- **Customers** - Access enterprise-grade patterns for Agentforce deployments
- **Developers** - Learn best practices for building Agentforce actions

## 🤖 Agent Overview

This repository supports multiple AI agents for different personas and use cases:

| Agent | Type | Audience | Purpose | Status |
|-------|------|----------|---------|--------|
| **Hank** | Employee | Sales Reps | Sales CRM - Pipeline, Meetings, Orders, Cases, Account Intel | ✅ Production |
| **ARIA** | Employee | Patient Services Reps | Enrollments, BV, Appointments, Cases, Missing Info | ✅ Production |
| **Juno** | Service | Patients & HCPs | Self-service enrollment, appointments, drug questions | ✅ Production |
| **Deal Review Agent** | Employee | Sales Reps | MEDDPICC deal coaching with adjustable intensity | ✅ Production |

### Agent Details

**Hank** (Sales/CRM):
- Topics: Pipeline & Deals, Activity Logging, Account Research, CRM Data Management, Orders & Fulfillment, Cases & Support, Product Knowledge
- Key Actions: Opportunity, Meeting, Task, Account, Contact, Case, Customer Order, Account Intel

**ARIA** (Patient Services - Internal):
- Topics: Program Enrollment, Benefits Verification, Appointments, Diagnostic Test Orders, Case Management, Activity Logging, Patient Information
- Key Actions: Program Candidate, Missing Information, Case, Task, Contact, Thespis APIs (getCoverages, getAppointments)
- See: `docs/ARIA_NOVO_PLAN.md` for full architecture

**Juno** (Patient Services - External):
- Topics: Program Enrollment, Appointment Handling, Drug & Therapy Inquiries
- Key Actions: Program Candidate, Thespis appointment APIs, Knowledge retriever
- Privacy: Status-only responses, no PHI in test results

**Deal Review Agent** (Sales Coaching):
- Topics: MEDDPICC Deal Qualification
- Key Actions: Update MEDDPICC Fields, Knowledge-based Q&A
- Features: Coaching intensity slider (1-5), session feedback collection

---

## 📦 What's Included

**Repository Focus**: This repository contains only reusable Agentforce assets - Apex classes, custom objects, permission sets, and documentation. Agent-specific configurations (planner bundles, bot metadata, GenAI plugins) are not included as they are org-specific and should be created per deployment.

### 🤖 Consolidated CRUD & Analytics Action Classes (14 Total)

Unified action classes that support all CRUD operations (Create, Read, Update, Delete, Find) for core CRM objects, plus analytics and intelligence actions:

**Sales/CRM Actions:**
- **AFAccountAction** - Full account management with ambiguity handling
- **AFContactAction** - Contact operations with email/name resolution
- **AFLeadAction** - Lead management (Company + LastName required) with name/email/company search
- **AFOpportunityAction** - Sales pipeline management with aggregate operations
- **AFCaseAction** - Customer service case handling
- **AFTaskAction** - Activity and to-do management
- **AFMeetingAction** - Custom Meeting object for field sales (pharmaceutical/medical)
- **AFCustomerOrderAction** - Order management with nested line items
- **AFUniversalAnalyticsAction** - Dynamic aggregate queries for analytics (SUM, COUNT, AVG, MIN, MAX, GROUP BY)
- **AFAccountIntelAction** - Retrieves pre-gathered account intelligence from Account_Intel__c records
- **Daily_Brief_Agents_Action** - Prompt template action generating podcast-style morning briefings

**Patient Services Actions:**
- **AFProgramCandidateAction** - Program candidate enrollment for post-prescription support programs
- **AFMissingInformationAction** - Tracks documents/data needed from patients (insurance cards, consent forms, etc.)
- **AFDiagnosticTestOrderAction** - Diagnostic test order management and status tracking

**Note**: All action labels in Agentforce UI include the "Agentforce" prefix (e.g., "Agentforce Account Action", "Agentforce Task Action") for better branding and discoverability.

Each consolidated action class provides:
- ✅ **Create** - Single or bulk record creation with field enrichment
- ✅ **Read** - Retrieve complete record details with related data
- ✅ **Update** - Modify existing records with name-based resolution
- ✅ **Delete** - Safe record deletion with cascade handling
- ✅ **Find** - Intelligent search with disambiguation

**Operation Inference**: Operations can be explicitly specified or automatically inferred from context (e.g., has fieldDataJson + recordId = update, has fieldDataJson only = create).

### 🛠️ Core Utilities

#### AFUniversalCrmRecordAction
The backbone of all CRUD operations. This utility class provides:
- Dynamic SOQL generation
- Field enrichment suggestions
- Preview mode (confirm parameter)
- Ambiguous relationship detection
- Name-based record resolution
- Transaction management with savepoint/rollback
- Line item helper methods for Customer Orders

#### AFUniversalAnalyticsAction
Dynamic aggregate query engine for analytics use cases. Available as "Agentforce Analytics Query" in Agentforce UI:
- SUM, COUNT, AVG, MIN, MAX operations
- Dynamic GROUP BY support
- Date range filtering
- Multi-object querying
- Answers questions like "How much pipeline do I have?", "How many accounts by industry?"

#### AmbiguousRelationshipException
Custom exception class for handling scenarios where AI agents encounter multiple matching records (e.g., multiple contacts named "John Smith"). Returns candidate list for user clarification.

### 🎨 Custom Objects & Fields

This repository includes custom objects designed for demo and POC environments. These objects are **not** part of standard Salesforce demo orgs or typical customer environments, making them ideal for quickly setting up proof-of-concepts with sample data:

**Sales/Field Activities:**
- **Meeting__c** - Purpose-built for pharmaceutical and medical device field sales scenarios
- **Account_Intel__c** - Pre-gathered account intelligence for research and daily briefings
- **Customer Order Line Item Enhancements** - Additional fields (Status, Distribution Center, Shipping Address) for order fulfillment demos

**Patient Services:**
- **Program_Candidate__c** - Patient enrollment tracking with Lightning Path for status
- **Missing_Information__c** - Tracks documents/data needed from patients (insurance cards, consent forms, income verification, etc.)
- **Diagnostic_Test_Order__c** - Lab and diagnostic test orders with status tracking

**Compliance:**
- **Potential_Adverse_Event__c** - Captures structured reports of potential adverse events for pharmacovigilance-style workflows

These custom objects come with sample data population scripts to accelerate demo setup.

### ⚡ Lightning Web Components

- **recordBrief** - AI-powered record summary with streaming markdown display. Works on Account, Case, and Program_Candidate__c. Auto-generates on page load.
- **dailyBrief** - Podcast-style morning briefing generator for field sales reps
- **agentforceDealReview** - MEDDPICC deal coaching with adjustable intensity (1-5 scale) and session feedback
- **dealReviewLauncher** - Launcher button for deal review sessions

### 🔐 Security & Permissions

- **Agentforce SDO Custom Asset Permissions** (`AgentCourseSDOCustomAssetPermissions`) - Grants full access to all Apex classes, custom objects, and fields in the repository. **This permission set is critical** - assign it to users who will use Agentforce actions.
- **Page Layouts** - Updated with all custom fields for Meeting__c and CustomerOrders__c objects

### 📊 Sample Data Scripts

Apex scripts for populating demo environments with realistic data for Med Tech/Pharma use cases.

## ✨ Key Features

### 🎯 Ambiguous Relationship Handling
When an agent encounters multiple matching records (e.g., two "Bob Smith" contacts), the system:
1. Detects the ambiguity
2. Returns a list of candidates with distinguishing details
3. Prompts the agent to ask the user for clarification
4. Prevents silent errors from picking the wrong record

### 🏷️ Name-Based Record Resolution
Update records without knowing their ID:
- `"Update the Acme Corp account status to Active"` ✅
- No need to lookup IDs first - the system resolves by name

### 🔄 Consolidated Operations
Customer Orders demonstrate nested operations:
- Create orders with line items in one call
- Update orders and manage line items simultaneously
- Read operations automatically include related line items
- Smart line item handling (full details for single, counts for multiple)

### 🎭 Preview Mode
All create/update operations support preview mode:
- Set `confirm=false` to see what would be created
- Agent can collect additional fields based on suggestions
- Call again with `confirm=true` to commit

### 📋 Field Enrichment
System suggests commonly-used fields when minimal data is provided:
- Agent asks user for additional context
- Better data quality from the start
- Configurable per object type

## 🚀 Getting Started

### Prerequisites
- Salesforce org (Developer, Sandbox, or Production)
- Salesforce DX CLI installed
- Admin or System Administrator access

### Deployment

1. **Clone the repository:**
```bash
git clone https://github.com/PatrickDennisSFDC/pat-dennis-agentforce-sdo-assets.git
cd pat-dennis-agentforce-sdo-assets
```

2. **Authenticate with your org:**
```bash
sf org login web --alias myorg
```

3. **Deploy the metadata:**
```bash
sf project deploy start --source-dir force-app/main/default --target-org myorg
```

4. **Assign the permission set:**
```bash
sf org assign permset --name AgentCourseSDOCustomAssetPermissions --target-org myorg
```

5. **Configure Agentforce:**
- Navigate to Setup → Agentforce Agents
- Create or edit your agent
- Go to Actions tab (or Topics → General CRM Updates)
- Add the deployed actions to your agent's action library
- Search for actions with "Agentforce" prefix:
  - "Agentforce Account Action"
  - "Agentforce Contact Action"
  - "Agentforce Lead Action"
  - "Agentforce Case Action"
  - "Agentforce Opportunity Action"
  - "Agentforce Task Action"
  - "Agentforce Meeting Action"
  - "Agentforce Customer Order Action"
  - "Agentforce Potential Adverse Event Action"
  - "Agentforce Program Candidate Action"
  - "Agentforce Analytics Query"

### Optional: Populate Sample Data
```bash
sf apex run --file scripts/apex/populate-line-item-fields.apex --target-org myorg
```

## 📚 Usage Examples

### Creating a Contact with Ambiguity Handling
Agent prompt: *"Create a contact named John Smith for Acme Corp"*

If multiple "Acme Corp" accounts exist:
- System returns candidates: "Acme Corp (San Francisco, Technology)" vs "Acme Corp (Austin, Manufacturing)"
- Agent asks user: "I found 2 Acme Corp accounts. Which one?"
- User clarifies, agent creates with correct account

### Updating an Opportunity by Name
Agent prompt: *"Change Q4 Enterprise Deal to Closed Won"*

System:
1. Finds opportunity by name "Q4 Enterprise Deal"
2. Updates StageName to "Closed Won"
3. Returns success with updated details

### Managing Customer Orders with Line Items
Agent prompt: *"Create an order for Acme Corp with 3 items: Widget A (qty 10), Widget B (qty 5), Widget C (qty 20)"*

System:
1. Creates CustomerOrder record
2. Creates 3 line items in same transaction
3. Returns order ID and line item details
4. Agent can reference "line item 2" in future operations

## 🏗️ Architecture

### Design Patterns
- **Invocable Actions** - All actions use `@InvocableMethod` for agent compatibility
- **Shared Utility Pattern** - Core logic in `AFUniversalCrmRecordAction` to reduce duplication
- **Exception-Based Ambiguity** - Custom exceptions for special handling
- **Transaction Safety** - Savepoint/rollback for atomic operations

### Object Support Matrix

| Object | Create | Read | Update | Delete | Find | Special Features |
|--------|--------|------|--------|--------|------|------------------|
| Account | ✅ | ✅ | ✅ | ✅ | ✅ | Parent account resolution |
| Contact | ✅ | ✅ | ✅ | ✅ | ✅ | Email/name search, account-scoped resolution |
| Lead | ✅ | ✅ | ✅ | ✅ | ✅ | Name/email/company search; LastName + Company required on create |
| Opportunity | ✅ | ✅ | ✅ | ✅ | ✅ | Stage tracking, aggregate queries |
| Case | ✅ | ✅ | ✅ | ✅ | ✅ | Priority handling, summarize operation |
| Task | ✅ | ✅ | ✅ | ✅ | ✅ | WhoId/WhatId support |
| Meeting__c | ✅ | ✅ | ✅ | ✅ | ✅ | Pharma field sales, semantic picklist inference |
| CustomerOrders__c | ✅ | ✅ | ✅ | ✅ | ✅ | Nested line items, bulk line item operations |
| Program_Candidate__c | ✅ | ✅ | ✅ | ✅ | ✅ | Patient enrollment with Lightning Path status tracking |
| Missing_Information__c | ✅ | ✅ | ✅ | ✅ | ✅ | Track documents/data needed from patients, status counts |
| Diagnostic_Test_Order__c | ✅ | ✅ | ✅ | ✅ | ✅ | Lab test orders with status tracking |
| Potential_Adverse_Event__c | ✅ | ✅ | ✅ | ✅ | ✅ | Pharmacovigilance reporting |
| Analytics | ✅ | ✅ | N/A | N/A | ✅ | Aggregate queries (SUM, COUNT, AVG, MIN, MAX, GROUP BY) |

## 🤝 Contributing

This repository will continue to grow with additional Agentforce assets and use cases. Contributions and feedback are welcome!

### Roadmap
- [ ] Additional industry-specific custom objects
- [ ] Test classes for all actions
- [ ] Advanced analytics patterns
- [ ] Integration with external systems
- [ ] Multi-language support
- [ ] Enhanced error handling patterns

## 📝 Use Cases & Topic Architecture

### Target Industry: Pharmaceutical & Medical Technology

This repository is optimized for field sales teams in pharma, life sciences, and medical device companies. The AI agent ("Hank") supports reps who are mobile, time-constrained, and need fast, low-friction interactions.

### Agent Topic Architecture

The agent is organized into **intent-based topics** that map to how sales reps naturally think about their work:

| Topic | Purpose | Example Triggers | Test Pass Rate |
|-------|---------|------------------|----------------|
| **Pipeline & Deals** | Manage sales opportunities | "Update the Memorial deal to proposal", "What's closing this month?" | 100% ✅ |
| **Activity Logging** | Record meetings, calls, tasks | "Log my meeting with Dr. Smith", "Create a task to follow up" | 80% |
| **Account Research** | Get background/intel on companies + daily briefings | "Tell me about Memorial Hospital", "Give me my daily brief" | 80% |
| **CRM Data Management** | Create/update accounts, contacts | "Create a contact for Dr. Jones", "Update Acme's phone number" | 85% |
| **Orders & Fulfillment** | Manage customer orders | "Check order status for Acme", "Create an order with 3 products" | **100%** ✅ |
| **Cases & Support** | Handle support tickets | "How many tickets for Omega?", "Close case 00001186" | 95% |
| **Product & SOP Knowledge** | RAG-based product documentation | "How does Prolia work?", "What are the side effects?" | **95%** ✅ |

### Key Use Cases

| Use Case | Description | Key Actions |
|----------|-------------|-------------|
| **Quick Deal Updates** | Update stage, amount, close date on opportunities | Opportunity Action |
| **Meeting Logging** | Log calls/visits with HCPs after appointments | Meeting Action |
| **Pipeline Review** | Query deals by stage, forecast category, close date | Opportunity Action (find) |
| **Account Preparation** | Research an account before a meeting | Account Intelligence |
| **Follow-up Tasks** | Create tasks for action items | Task Action |
| **Contact Management** | Add new HCPs to the CRM | Contact Action |

### Routing Philosophy

The agent routes based on **user intent**, not CRM objects. A sales rep says "update my deal" (not "update an Opportunity record"). Key routing rules:

- **"deal", "opportunity", "pipeline", "stage", "amount"** → Pipeline & Deals
- **"order", "fulfillment", "ship", "order status"** → Orders & Fulfillment
- **"case", "ticket", "support", "escalation"** → Cases & Support
- **"log", "record", "meeting", "called", "visited"** → Activity Logging
- **"tell me about", "background on", "research"** → Account Research (Account Intelligence action)
- **"daily brief", "morning briefing", "catch me up", "market update"** → Account Research (Daily Brief action)
- **"how does [product] work", "side effects", "SOP"** → Product & SOP Knowledge (RAG)

**The "Say the Object Name" Rule**: When users include the object keyword ("order", "deal", "case"), routing is nearly 100% accurate. Terse inputs without context (e.g., just a company name) are inherently ambiguous - this is expected and acceptable.

> 📖 See `USE_CASES.md` for detailed personas, use cases, and the complete routing decision framework.

## 🔧 Technical Details

- **API Version:** 65.0
- **Language:** Apex
- **Pattern:** Invocable Actions with `@InvocableMethod` annotation
- **Security:** Action classes in this repo currently run `without sharing` (system mode) to simplify demo environments. For production implementations, we recommend switching to `with sharing` and tightening object/field permissions.
- **Error Handling:** Debug emails automatically sent to org owner (falls back to running user)
- **Test Coverage:** (Coming soon)

## 📄 License

This repository is provided as-is for use by Salesforce employees, partners, and customers. Please review your organization's policies regarding use of sample code.

## 🙋 Support

For questions, issues, or feature requests, please contact Patrick Dennis or open an issue in this repository.

## 🧪 Testing & Development

### Agent Testing via CLI

Agentforce agents can be tested using the Salesforce CLI. Test specs are defined in YAML files in the `specs/` directory.

```bash
# Create a test from a spec file
sf agent test create --spec specs/Nora_Meetings_1-testSpec.yaml --target-org myorg

# Run the test with verbose output
sf agent test run --api-name Nora_Meetings_1 --wait 10 --verbose --target-org myorg
```

### Updating Agent Actions

When you update Apex action descriptions, you need to update the agent's metadata:

```bash
# 1. Deactivate the agent
sf agent deactivate --api-name Hank --target-org myorg

# 2. Retrieve, update, and deploy GenAiPlannerBundle
sf project retrieve start --metadata GenAiPlannerBundle --target-org myorg --output-dir /tmp/bundle
# Edit the bundle files...
sf project deploy start --source-dir /tmp/bundle/genAiPlannerBundles --target-org myorg

# 3. Reactivate the agent
sf agent activate --api-name Hank --target-org myorg
```

### Documentation for Developers & AI Agents

| Document | Purpose |
|----------|---------|
| `USE_CASES.md` | **User personas, use cases, and success criteria** - Sales + Patient Services |
| `AGENTS.md` | Complete guide to agent testing, metadata, CLI workflows, and patterns |
| `docs/ARIA_NOVO_PLAN.md` | Patient Services architecture plan (ARIA & Juno) |
| `docs/KNOWLEDGE_RAG_SETUP.md` | **Knowledge Articles + Files RAG Setup** - Data Cloud configuration for Knowledge-based RAG |
| `specs/README.md` | Test spec format documentation |

> **For AI Agents**: Start with `USE_CASES.md` to understand the target users and scenarios, then `AGENTS.md` for technical context on testing and modifying agent configurations. For patient services work, see `docs/ARIA_NOVO_PLAN.md`.

## 🎓 Learning Resources

- **[Build Agentforce Agents with Claude Code](https://salesforce.vidyard.com/watch/ELuVdYjBfjPKTrULmfifJa)** - 4-hour POC walkthrough covering agent building, testing at scale, RAG setup, debugging, and multi-channel deployment
- [Agentforce Documentation](https://help.salesforce.com/s/articleView?id=sf.agentforce_overview.htm&type=5)
- [Invocable Actions Guide](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_classes_annotation_InvocableMethod.htm)
- [Building AI Agents on Salesforce](https://trailhead.salesforce.com/content/learn/trails/build-ai-agents)
- [Agentforce DX Guide](https://developer.salesforce.com/docs/ai/agentforce/guide/agent-dx-overview.html)

---

**Built with ❤️ for the Agentforce community**

*Last Updated: February 5, 2026*

## 📋 Recent Updates

### January 17, 2026 - Knowledge + Files RAG Documentation

- **Knowledge RAG Setup Guide**: New comprehensive documentation (`docs/KNOWLEDGE_RAG_SETUP.md`) for building RAG solutions using Salesforce Knowledge articles and their attached files via Data Cloud
- **Alternative to S3 Approach**: Documents how to set up Data Streams, DMOs, and Einstein Search Retrievers for Knowledge-based RAG as an alternative to the existing S3 bucket approach
- **Architecture Patterns**: Includes detailed architecture diagrams, step-by-step configuration guides, and troubleshooting tips

### January 16, 2026 - ARIA & Juno Patient Services Agents

- **ARIA Agent (Internal)**: Complete patient services agent for reps with 7 topics: Program Enrollment, Benefits Verification, Appointments, Diagnostic Test Orders, Case Management, Activity Logging, Patient Information
- **Juno Enhancement**: Added Drug & Therapy Inquiries topic with knowledge retrieval
- **Missing_Information__c**: New object + `AFMissingInformationAction` to track documents needed from patients
- **Record Brief Component**: `recordBrief` LWC with AI-powered summaries for Account, Case, Program_Candidate__c
- **Test Coverage**: 50+ test cases for ARIA, 5 test specs for Juno covering happy paths, error handling, and auth failures
- **Documentation**: Consolidated `AGENT_CONTEXT.md` and `AGENT_RULES.md` into `AGENTS.md`. Updated `USE_CASES.md` with patient services personas and use cases.

### January 14, 2026 - Aggregate/Find Query Alignment

- **Pipeline Query Consistency**: Fixed issue where aggregate and find queries returned different counts. Both now default to `IsClosed = false` for pipeline queries.
- **Semantic Defaults**: `AFOpportunityAction` applies semantic defaults - "pipeline" means open deals.

### January 10, 2026 - Case Management, Orders, Product Knowledge, Daily Brief

- **Case Management**: Dedicated "Cases & Support" topic with 95% routing accuracy
- **Customer Orders**: 100% topic routing when users include "order" keyword
- **Product & SOP Knowledge**: RAG topic with 95% pass rate on drug-specific tests
- **Daily Brief**: Podcast-style morning briefings for field sales reps
- **Account Intelligence**: Expanded to 32 records across 9 accounts
- **SOSL Search**: Primary search mechanism handling "sloppy" user inputs
- **Dynamic Picklist Normalization**: Fuzzy matching to valid values at runtime
- **Aggregate Operations**: SUM/COUNT/AVG/MIN/MAX with GROUP BY

### Earlier Updates (January - December 2025)

<details>
<summary>Click to expand earlier updates...</summary>

**January 2026:**
- Added `USE_CASES.md`, `AGENTS.md`, `specs/README.md` documentation
- Enhanced AFMeetingAction with 6-step conversational flow
- Documented GenAiPlannerBundle architecture

**December 2025:**
- Added "Agentforce" prefix to all action labels
- Updated to API version 65.0
- Added AFUniversalAnalyticsAction for aggregate queries
- Added AFLeadAction, AFPotentialAdverseEventAction, AFProgramCandidateAction
- Repository cleanup - removed org-specific configurations
</details>
