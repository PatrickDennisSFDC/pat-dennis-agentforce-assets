# AF Controllers for Agentforce - Setup Guide

## ✅ What's Been Created

Three new AuraEnabled controller classes with the "AF" prefix for Agentforce integration:

1. **AFAccountController** - Account CRUD operations
2. **AFContactController** - Contact CRUD operations
3. **AFCaseController** - Case CRUD operations

All classes:
- ✅ Use `@AuraEnabled` methods for native Agentforce integration
- ✅ Have `with sharing` modifier (required for Agentforce)
- ✅ Reuse existing `UniversalCrmRecordAction.processRequest()` logic
- ✅ Include proper error handling with `AuraHandledException`
- ✅ Support all CRUD operations (Create, Read, Update, Delete, List)

## 📋 Available Methods

### AFAccountController
- `listAccounts(search, industry, billingCity, billingState, phone, recordLimit)` - List accounts
- `getAccountById(accountId)` - Get account by ID
- `createAccount(accountData)` - Create account(s) - supports bulk
- `updateAccount(accountId, accountData)` - Update account
- `deleteAccount(accountId)` - Delete account

### AFContactController
- `listContacts(search, email, accountId, recordLimit)` - List contacts
- `getContactById(contactId)` - Get contact by ID
- `createContact(contactData)` - Create contact(s) - supports bulk and `accountName` resolution
- `updateContact(contactId, contactData)` - Update contact - supports `accountName` resolution
- `deleteContact(contactId)` - Delete contact

### AFCaseController
- `listCases(search, status, priority, accountId, recordLimit)` - List cases
- `getCaseById(caseId)` - Get case by ID
- `createCase(caseData)` - Create case(s) - supports bulk, `accountName`, and `contactNameOrEmail` resolution
- `updateCase(caseId, caseData)` - Update case - supports `accountName` and `contactNameOrEmail` resolution
- `deleteCase(caseId)` - Delete case

## 🚀 Next Steps: Generate OpenAPI Specs

Now that the classes are deployed, you need to generate OpenAPI specifications using the VS Code extension:

### Step 1: Generate OpenAPI for Each Class

1. **Open VS Code** in your project directory
2. **For each class**, run the command:
   - Open `AFAccountController.cls`
   - Press `Cmd+Shift+P` (Mac) or `Ctrl+Shift+P` (Windows/Linux)
   - Type: `SFDX: Create OpenAPI Document from this Class (Beta)`
   - Select the `externalServicesRegistrations` folder
   - Repeat for `AFContactController.cls` and `AFCaseController.cls`

This will generate:
- `AFAccountController.yaml`
- `AFAccountController.externalServiceRegistration-meta.xml`
- (and same for Contact and Case)

### Step 2: Add Agentforce Extensions

The generated OpenAPI specs will need Agentforce-specific extensions. You can:

1. **Manually add** `x-sfdc` extensions to each YAML file, or
2. **Use the helper script** (if we create one) to add them automatically

Key extensions needed:
```yaml
x-sfdc:
  topics:
    - name: Account Management
      description: Operations for managing Account records
      instructions: Use this API when the user wants to find, create, update, or delete accounts.
  agentInstructions:
    listAccounts: "When retrieving accounts, if multiple matches are found, present all options and ask for more details."
    # ... etc
```

### Step 3: Deploy OpenAPI Specs

1. Deploy the generated XML files:
   ```bash
   sf project deploy start --source-dir force-app/main/default/externalServicesRegistrations --target-org storm.779a9cfd695270@salesforce.com
   ```

2. **Register in API Catalog:**
   - Go to Setup → API Catalog
   - Select "AuraEnabled (Beta)" tab
   - Your APIs should appear there

3. **Create Agent Actions:**
   - Go to Setup → Agentforce Assets → Actions tab
   - Click "New Agent Action"
   - Select "Apex Reference" type
   - Choose your AF controllers and their methods

## 🎯 Benefits of This Approach

1. **Native Integration** - Built specifically for Agentforce
2. **Auto-Generated Specs** - VS Code extension handles OpenAPI generation
3. **Type Safety** - Strongly-typed parameters and return values
4. **Clear Naming** - "AF" prefix makes it obvious these are for Agentforce
5. **Reuses Logic** - All business logic stays in `UniversalCrmRecordAction`
6. **Better Error Handling** - `AuraHandledException` provides clear error messages

## 📝 Notes

- The `limit` parameter was renamed to `recordLimit` because `limit` is a reserved keyword in Apex
- All methods support the same features as the REST API (search, filters, bulk operations, related record resolution)
- The classes maintain the same business logic and behavior as the REST endpoints

## 🔄 Migration Path

You can keep both approaches:
- **REST API** (`AccountResource`, etc.) - For external integrations
- **AF Controllers** (`AFAccountController`, etc.) - For Agentforce

Both call the same `UniversalCrmRecordAction.processRequest()` method, so you maintain a single source of truth for business logic.





