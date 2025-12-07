# Quick Start Guide

Get up and running with Agentforce SDO Assets in minutes!

## Prerequisites

- Salesforce org (Developer, Sandbox, or Production)
- Salesforce DX CLI installed (`sf` command)
- Admin or System Administrator access

## Step 1: Clone the Repository

```bash
git clone https://github.com/PatrickDennisSFDC/pat-dennis-agentforce-sdo-assets.git
cd pat-dennis-agentforce-sdo-assets
```

## Step 2: Authenticate with Your Org

```bash
sf org login web --alias myorg
```

Replace `myorg` with your preferred alias. This will open a browser window for authentication.

## Step 3: Deploy Everything

Deploy all Agentforce assets to your org:

```bash
sf project deploy start --source-dir force-app/main/default --target-org myorg
```

This deploys:
- All 7 consolidated CRUD action classes (Account, Contact, Opportunity, Case, Task, Meeting, Customer Order)
- Core utilities (AFUniversalCrmRecordAction, AFUniversalAnalyticsAction)
- Custom objects and fields (Meeting__c, Customer Order enhancements)
- Permission sets and profiles
- Page layouts

## Step 4: Assign the Permission Set (CRITICAL!)

The `AgentCourseSDOCustomAssetPermissions` permission set is **essential** - it grants access to all Apex classes, objects, and fields. Without it, agents won't be able to use any of these actions.

### Option A: Using the Deployment Script (Recommended)

```bash
./deploy.sh myorg
```

This script will:
1. Deploy all metadata
2. Assign the `AgentCourseSDOCustomAssetPermissions` permission set to your user
3. Verify the assignment

### Option B: Manual Assignment

```bash
# Assign to your current user
sf org assign permset --name AgentCourseSDOCustomAssetPermissions --target-org myorg

# Or assign to a specific user
sf org assign permset --name AgentCourseSDOCustomAssetPermissions --on-behalf-of user@example.com --target-org myorg
```

### Option C: Via Salesforce UI

1. Go to Setup → Users → Permission Sets
2. Find "Agentforce SDO Custom Asset Permissions"
3. Click "Manage Assignments"
4. Add your user (or users who will use Agentforce)

## Step 5: Configure Agentforce

1. Navigate to **Setup → Agentforce Agents**
2. Create a new agent or edit an existing one
3. Go to the **Actions** tab
4. Add the deployed actions to your agent's action library:
   - Search for actions like "Account Action", "Contact Action", etc.
   - Each action supports all CRUD operations (create, read, update, delete, find)
   - Add the ones you want your agent to use

## Step 6: Test It Out!

Try creating a simple agent interaction:

**Example**: "Create an account called Acme Corp"

The agent should be able to:
1. Call `AFAccountAction` with operation inferred as "create" (or explicitly set)
2. Create the account
3. Return the account ID

## Optional: Populate Sample Data

If you want to test with sample data for Meeting or Customer Order objects:

```bash
# Populate Customer Order Line Item fields
sf apex run --file scripts/apex/populate-line-item-fields.apex --target-org myorg

# Populate distribution centers
sf apex run --file scripts/apex/populate-distribution-centers.apex --target-org myorg
```

## Troubleshooting

### "Permission denied" or "Insufficient access"
- **Solution**: Make sure you've assigned the `AgentCourseSDOCustomAssetPermissions` permission set (Step 4)

### "Action not found" in Agentforce
- **Solution**: Verify the deployment succeeded (Step 3) and refresh the Actions tab in Agentforce

### "Object not found" errors
- **Solution**: Ensure custom objects (Meeting__c, CustomerOrders__c) were deployed successfully

## What's Next?

- Read `AGENT_CONTEXT.md` for detailed architecture and design patterns
- Read `AGENT_RULES.md` for coding guidelines and best practices
- Read `README.md` for comprehensive documentation

## Need Help?

- Check the `README.md` for detailed documentation
- Review `AGENT_CONTEXT.md` for implementation details
- Open an issue in the GitHub repository

---

**Remember**: The `AgentCourseSDOCustomAssetPermissions` permission set is critical! Without it, none of the actions will work.
