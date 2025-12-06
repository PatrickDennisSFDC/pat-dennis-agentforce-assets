# Pat Dennis Agentforce SDO Assets

A comprehensive library of production-ready Agentforce components for building intelligent AI agents on Salesforce. This repository provides reusable Apex actions, utilities, and configurations that accelerate Agentforce implementations for Salesforce employees, implementation partners, and customers.

## 🎯 Purpose

This repository serves as a hub for high-quality Agentforce technology assets. Whether you're a Salesforce employee building demos, an implementation partner deploying customer solutions, or a customer exploring Agentforce capabilities, these components provide battle-tested patterns for common AI agent use cases.

## 👥 Who This Is For

- **Salesforce Employees** - Accelerate demos, POCs, and customer implementations
- **Implementation Partners** - Leverage pre-built components for faster project delivery
- **Customers** - Access enterprise-grade patterns for Agentforce deployments
- **Developers** - Learn best practices for building Agentforce actions

## 📦 What's Included

### 🤖 CRUD Action Classes (35 Total)

Complete Create, Read, Update, Delete, and Find operations for core CRM objects:

- **Account Actions** (5 classes) - Full account management with ambiguity handling
- **Contact Actions** (5 classes) - Contact operations with email/name resolution
- **Opportunity Actions** (5 classes) - Sales pipeline management
- **Case Actions** (5 classes) - Customer service case handling
- **Task Actions** (5 classes) - Activity and to-do management
- **Meeting Actions** (5 classes) - Custom Meeting object for field sales (pharmaceutical/medical)
- **Customer Order Actions** (5 classes) - Order management with nested line items

Each action set provides:
- ✅ **Create** - Single or bulk record creation with field enrichment
- ✅ **Read** - Retrieve complete record details with related data
- ✅ **Update** - Modify existing records with name-based resolution
- ✅ **Delete** - Safe record deletion with cascade handling
- ✅ **Find** - Intelligent search with disambiguation

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
Dynamic aggregate query engine for analytics use cases:
- SUM, COUNT, AVG, MIN, MAX operations
- Dynamic GROUP BY support
- Date range filtering
- Multi-object querying

#### AmbiguousRelationshipException
Custom exception class for handling scenarios where AI agents encounter multiple matching records (e.g., multiple contacts named "John Smith"). Returns candidate list for user clarification.

### 🎨 Custom Objects & Fields

This repository includes custom objects designed for demo and POC environments. These objects are **not** part of standard Salesforce demo orgs or typical customer environments, making them ideal for quickly setting up proof-of-concepts with sample data:

- **Meeting__c** - Purpose-built for pharmaceutical and medical device field sales scenarios
- **Customer Order Line Item Enhancements** - Additional fields (Status, Distribution Center, Shipping Address) for order fulfillment demos

These custom objects come with sample data population scripts to accelerate demo setup.

### 🔐 Security & Permissions

- **Agent_Actions Permission Set** - Grants access to all Apex classes, objects, and fields
- **System Admin Profile** - Configured with explicit field permissions
- **Page Layouts** - Updated with all custom fields

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
sf org assign permset --name Agent_Actions --target-org myorg
```

5. **Configure Agentforce:**
- Navigate to Setup → Agentforce Agents
- Create or edit your agent
- Add the deployed actions to your agent's action library

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
| Contact | ✅ | ✅ | ✅ | ✅ | ✅ | Email/name search |
| Opportunity | ✅ | ✅ | ✅ | ✅ | ✅ | Stage tracking |
| Case | ✅ | ✅ | ✅ | ✅ | ✅ | Priority handling |
| Task | ✅ | ✅ | ✅ | ✅ | ✅ | WhoId/WhatId support |
| Meeting__c | ✅ | ✅ | ✅ | ✅ | ✅ | Pharma field sales |
| CustomerOrders__c | ✅ | ✅ | ✅ | ✅ | ✅ | Nested line items |

## 🤝 Contributing

This repository will continue to grow with additional Agentforce assets and use cases. Contributions and feedback are welcome!

### Roadmap
- [ ] Additional industry-specific custom objects
- [ ] Test classes for all actions
- [ ] Advanced analytics patterns
- [ ] Integration with external systems
- [ ] Multi-language support
- [ ] Enhanced error handling patterns

## 📝 Use Cases

### Pharmaceutical Field Sales
Meeting management, sample tracking, marketing material distribution, and follow-up scheduling for doctor visits.

### Order Management
Customer order creation with line items, distribution center assignment, fulfillment tracking, and status management.

### CRM Operations
Complete account, contact, opportunity management with task/activity tracking, case management for support, and intelligent relationship disambiguation.

## 🔧 Technical Details

- **API Version:** 62.0
- **Language:** Apex
- **Pattern:** Invocable Actions
- **Security:** with sharing enforced
- **Test Coverage:** (Coming soon)

## 📄 License

This repository is provided as-is for use by Salesforce employees, partners, and customers. Please review your organization's policies regarding use of sample code.

## 🙋 Support

For questions, issues, or feature requests, please contact Patrick Dennis or open an issue in this repository.

## 🎓 Learning Resources

- [Agentforce Documentation](https://help.salesforce.com/s/articleView?id=sf.agentforce_overview.htm&type=5)
- [Invocable Actions Guide](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_classes_annotation_InvocableMethod.htm)
- [Building AI Agents on Salesforce](https://trailhead.salesforce.com/content/learn/trails/build-ai-agents)

---

**Built with ❤️ for the Agentforce community**

*Last Updated: December 2024*
