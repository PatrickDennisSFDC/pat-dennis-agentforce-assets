# Agentforce Actions Setup Guide

## ✅ What's Included

This repository provides **7 consolidated invocable action classes** for Agentforce, each supporting all CRUD operations (Create, Read, Update, Delete, Find) in a single class:

1. **AFAccountAction** - Account management with ambiguity handling
2. **AFContactAction** - Contact operations with email/name resolution
3. **AFCaseAction** - Customer service case handling
4. **AFOpportunityAction** - Sales pipeline management
5. **AFTaskAction** - Activity and to-do management
6. **AFMeetingAction** - Custom Meeting object for field sales (pharmaceutical/medical)
7. **AFCustomerOrderAction** - Order management with nested line items

All classes:
- ✅ Use `@InvocableMethod` for native Agentforce integration
- ✅ Have `with sharing` modifier (required for Agentforce)
- ✅ Support operation inference (automatically detect create/read/update/delete/find from context)
- ✅ Include comprehensive labels and descriptions for AI agent guidance
- ✅ Delegate to `AFUniversalCrmRecordAction` for core business logic
- ✅ Handle ambiguous relationships (multiple matching records)
- ✅ Support name-based record resolution (update by name, not just ID)

## 🎯 Key Features

### Operation Inference
Operations can be explicitly specified or automatically inferred:
- **Has `fieldDataJson` + `recordId`** → Update
- **Has `fieldDataJson` only** → Create
- **Has `recordId` only** → Read
- **Has `searchTerm` or `filtersJson`** → Find
- **Has `recordId` only (no data/search)** → Delete

### Ambiguity Handling
When multiple records match (e.g., two "Bob Smith" contacts):
- System detects the ambiguity
- Returns a list of candidates with distinguishing details
- Agent prompts user for clarification
- Prevents silent errors from picking the wrong record

### Name-Based Resolution
Update records without knowing their ID:
- `"Update the Acme Corp account status to Active"` ✅
- System resolves "Acme Corp" to AccountId automatically
- No need to lookup IDs first

## 🚀 Deployment Steps

### Step 1: Clone and Authenticate

```bash
# Clone the repository
git clone https://github.com/PatrickDennisSFDC/pat-dennis-agentforce-sdo-assets.git
cd pat-dennis-agentforce-sdo-assets

# Authenticate with your Salesforce org
sf org login web --alias myorg
```

### Step 2: Deploy All Metadata

Deploy all Agentforce assets to your org:

```bash
sf project deploy start --source-dir force-app/main/default --target-org myorg
```

This deploys:
- All 7 consolidated action classes
- Core utilities (`AFUniversalCrmRecordAction`, `AFUniversalAnalyticsAction`)
- Custom objects and fields (`Meeting__c`, `CustomerOrders__c`, `Customer_Order_Line_Item__c`)
- Permission sets
- Page layouts

### Step 3: Assign Permission Set (CRITICAL!)

The `AgentCourseSDOCustomAssetPermissions` permission set is **essential** - it grants access to all Apex classes, objects, and fields. Without it, agents won't be able to use any of these actions.

**Option A: Using the Deployment Script (Recommended)**

```bash
./deploy.sh myorg
```

**Option B: Manual Assignment**

```bash
# Assign to your current user
sf org assign permset --name AgentCourseSDOCustomAssetPermissions --target-org myorg

# Or assign to a specific user
sf org assign permset --name AgentCourseSDOCustomAssetPermissions --on-behalf-of user@example.com --target-org myorg
```

**Option C: Via Salesforce UI**

1. Go to **Setup → Users → Permission Sets**
2. Find **"Agentforce SDO Custom Asset Permissions"**
3. Click **"Manage Assignments"**
4. Add your user (or users who will use Agentforce)

### Step 4: Configure Agentforce Agent

1. Navigate to **Setup → Agentforce Agents**
2. Create a new agent or edit an existing one
3. Go to the **Actions** tab (or **Topics** → **General CRM Updates**)
4. Click **"Add Action"** or **"New Action"**
5. Search for the deployed actions:
   - Search for "Agentforce Account Action" → Select `AFAccountAction`
   - Search for "Agentforce Contact Action" → Select `AFContactAction`
   - Search for "Agentforce Case Action" → Select `AFCaseAction`
   - Search for "Agentforce Opportunity Action" → Select `AFOpportunityAction`
   - Search for "Agentforce Task Action" → Select `AFTaskAction`
   - Search for "Agentforce Meeting Action" → Select `AFMeetingAction`
   - Search for "Agentforce Customer Order Action" → Select `AFCustomerOrderAction`
6. Add the actions you want your agent to use

**Note**: Each action supports all CRUD operations. You don't need separate actions for create/read/update/delete - the agent will infer the operation from context.

## 📋 Available Operations

Each action class supports these operations:

### Create
- Create single or multiple records
- Field enrichment suggestions
- Preview mode (`confirm=false`) to see what would be created
- Related record resolution (e.g., specify Account by name)

### Read
- Retrieve complete record details by ID
- Includes all fields and related data
- Returns structured Account/Contact/etc. object

### Update
- Update by record ID or by name (automatic resolution)
- Supports partial updates (only specify fields to change)
- Preview mode available
- Related record resolution

### Delete
- Safe deletion with two-step confirmation
- First call with `confirm=false` returns confirmation message
- Second call with `confirm=true` actually deletes
- Cascade handling for related records

### Find
- Intelligent search with `searchTerm` (searches multiple fields)
- Exact-match filters via `filtersJson`
- Returns list of matching records
- Ambiguity handling for multiple matches

## 🎯 Usage Examples

### Example 1: Create Account
**Agent prompt**: *"Create an account called Acme Corp in the Technology industry"*

**Action call**:
- Operation: `create` (or inferred)
- `fieldDataJson`: `{"Name":"Acme Corp","Industry":"Technology"}`
- `confirm`: `true`

**Result**: Account created, returns Account record with ID

### Example 2: Find Contact with Ambiguity
**Agent prompt**: *"Find Bob Smith"*

**Action call**:
- Operation: `find` (or inferred)
- `searchTerm`: `"Bob Smith"`

**If multiple matches**:
- Returns `candidates` list with details
- Agent asks: "I found 2 contacts named Bob Smith. Which one? (1) Bob Smith at Acme Corp, (2) Bob Smith at Globex Inc."

### Example 3: Update by Name
**Agent prompt**: *"Change Acme Corp's industry to Manufacturing"*

**Action call**:
- Operation: `update` (or inferred)
- `fieldDataJson`: `{"Name":"Acme Corp","Industry":"Manufacturing"}`
- System automatically resolves "Acme Corp" to AccountId
- `confirm`: `true`

**Result**: Account updated successfully

### Example 4: Create Customer Order with Line Items
**Agent prompt**: *"Create an order for Acme Corp with 3 items: Widget A (qty 10), Widget B (qty 5)"*

**Action call**:
- Operation: `create`
- `fieldDataJson`: `{"Account__c":"Acme Corp","LineItemsJson":"[{\"Product__c\":\"Widget A\",\"Quantity__c\":10},{\"Product__c\":\"Widget B\",\"Quantity__c\":5}]"}`
- `confirm`: `true`

**Result**: Order and line items created in single transaction

## 🔧 Schema Configuration

When adding actions to an agent, the system automatically generates schema files (`input/schema.json` and `output/schema.json`) based on the Apex class `@InvocableVariable` annotations. These schemas:

- Define input/output structure for the agent
- Include labels and descriptions from Apex classes
- Control UI behavior with `copilotAction` flags:
  - `copilotAction:isUserInput` - Controls whether field appears as form input (set to `false` for conversational experience)
  - `copilotAction:isDisplayable` - Controls whether output is shown directly (set to `false` for conversational responses)
  - `copilotAction:isUsedByPlanner` - Indicates if planner should use output for reasoning (set to `true`)

**Best Practice**: All input fields should have `copilotAction:isUserInput: false` to promote conversational interaction. The agent should extract parameters from natural language rather than presenting forms.

## 🎓 Best Practices

### For AI Agents

1. **Ask for Clarification First**: If a user says "look up an account" without details, ask for the account name or other identifying information BEFORE calling the find action.

2. **Use Operation Inference**: Don't always specify `operation` explicitly - let the system infer from context when possible.

3. **Handle Ambiguity**: When `candidates` are returned, present them to the user and ask for clarification rather than picking the first one.

4. **Preview Before Commit**: For create/update operations, consider using `confirm=false` first to show what would be created, then ask the user to confirm.

5. **Use Natural Language**: Extract field values from natural language (e.g., "lunch" → "In-Person Visit" for Meeting Type) rather than requiring exact picklist values.

### For Developers

1. **Read the Apex Class Descriptions**: The `@InvocableMethod` descriptions contain detailed guidance for agents. Keep them updated.

2. **Test Operation Inference**: Verify that operations are correctly inferred from various input combinations.

3. **Handle Edge Cases**: Test ambiguity scenarios, empty results, and error conditions.

4. **Monitor Agent Behavior**: Watch how agents use these actions and refine descriptions based on actual usage.

## 🐛 Troubleshooting

### "Permission denied" or "Insufficient access"
- **Solution**: Make sure you've assigned the `AgentCourseSDOCustomAssetPermissions` permission set (Step 3)

### "Action not found" in Agentforce
- **Solution**: Verify the deployment succeeded (Step 2) and refresh the Actions tab in Agentforce

### "Object not found" errors
- **Solution**: Ensure custom objects (`Meeting__c`, `CustomerOrders__c`) were deployed successfully

### Agent keeps asking for the same information
- **Solution**: Check that `copilotAction:isUserInput` is set to `false` in schema files to enable conversational extraction

### Operation inference not working
- **Solution**: Verify you're providing the correct input parameters. Check the `@InvocableMethod` description in the Apex class for guidance.

## 📚 Additional Resources

- **README.md** - Comprehensive repository documentation
- **AGENT_CONTEXT.md** - Detailed architecture and design patterns
- **AGENT_RULES.md** - Coding guidelines and best practices
- **QUICK_START.md** - Quick deployment guide

## 🔄 Architecture Overview

```
Agentforce Agent
    ↓
AFAccountAction (or other action class)
    ↓
AFUniversalCrmRecordAction (core business logic)
    ↓
Salesforce Database
```

All action classes delegate to `AFUniversalCrmRecordAction` for:
- Dynamic SOQL generation
- Field enrichment suggestions
- Ambiguous relationship detection
- Name-based record resolution
- Transaction management

This architecture ensures:
- ✅ Single source of truth for business logic
- ✅ Consistent behavior across all objects
- ✅ Easy maintenance and updates
- ✅ Reusable patterns for new objects

---

**Remember**: The `AgentCourseSDOCustomAssetPermissions` permission set is critical! Without it, none of the actions will work.

*Last Updated: December 2024*
