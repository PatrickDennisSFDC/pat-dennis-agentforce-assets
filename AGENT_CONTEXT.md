# Agentforce SDO Assets - AI Agent Context Guide

## 🎯 Project Overview

This repository is a **store of Agentforce assets** that make Agentforce better and help showcase its full potential. These assets are designed for use in Salesforce SDO (Salesforce Digital Office) environments and other Salesforce environments.

The repository provides reusable components for building intelligent AI agents on Salesforce, with a focus on key use cases that we've begun with, but we're always expanding to new use cases and scenarios.

## 🧠 Core Philosophy: Agent Intelligence Over Rigid Rules

### The Problem We Solved
Initially, we considered hardcoded mappings like:
```apex
if (input.contains("lunch")) return "In-Person Visit";
```

### The Better Solution
We empower AI agents to use their **semantic understanding**:
- Agents analyze context and infer appropriate values
- Agents query `availableFieldsJson` to see valid options dynamically
- Agents use natural language understanding (sentiment, temporal context, intent)
- If unclear, agents leave fields blank rather than forcing a choice

### Example: Meeting Type Inference
**User says**: "I had lunch with Dr. Smith"

**Agent intelligently infers**:
- "lunch" (semantic) → `Meeting_Type__c: "In-Person Visit"`
- "had" (past tense) → `Meeting_Status__c: "Completed"`
- Context analysis → Appropriate outcome and follow-up flags

**Not**: Hardcoded `if (contains("lunch")) return "In-Person Visit"`

## 🏗️ Methodology: Why Apex for Agentforce?

### Our Framework for Building Agents

We've chosen to build Agentforce agents using **Apex invocable actions** as our primary methodology. Here's the theory and reasoning behind this approach:

### 1. Native Salesforce Integration
**Why**: Apex actions are first-class citizens in Salesforce's platform
**Benefits**:
- Direct access to Salesforce data and metadata without external APIs
- No authentication overhead or API rate limits
- Leverages existing Salesforce security model (sharing rules, field-level security)
- Seamless integration with other Salesforce features (flows, triggers, validation rules)

### 2. Performance & Reliability
**Why**: Executes within Salesforce's infrastructure
**Benefits**:
- Low latency for agent interactions (no network calls)
- Transaction safety with savepoint/rollback capabilities
- Efficient bulk operations (up to 200 records)
- Built-in error handling and governor limits

### 3. Flexibility & Extensibility
**Why**: Apex provides full access to Salesforce's capabilities
**Benefits**:
- Can access any Salesforce object or field (standard or custom)
- Supports complex business logic and calculations
- Dynamic SOQL generation for flexible queries
- Can integrate with external systems via callouts when needed

### 4. Agent-Friendly Patterns
**Why**: `@InvocableMethod` annotation creates discoverable, self-documenting actions
**Benefits**:
- Rich metadata (labels, descriptions) guides agent behavior
- Structured Request/Response classes provide clear contracts
- JSON parameters enable dynamic data construction by agents
- Actions appear automatically in Agentforce action library

### 5. Maintainability & Version Control
**Why**: Apex code is version controlled and testable
**Benefits**:
- Version controlled with Salesforce DX and Git
- Testable with Apex test classes
- Reusable across multiple agents and orgs
- Centralized logic reduces duplication and maintenance burden

### The Theory Behind the Approach

The core theory is that **agents should interact with structured, intelligent actions** rather than raw APIs or complex queries. By wrapping business logic in invocable actions:

- **Semantic Operations**: Agents get purpose-built operations (Create Account, Find Contact) rather than generic CRUD
- **Abstraction**: Complex logic (ambiguity handling, field enrichment) is abstracted away from agents
- **Focus on Intent**: Agents can focus on understanding user intent, not technical implementation details
- **Evolution**: Actions can evolve independently without breaking agent behavior
- **Consistency**: All agents using these actions get consistent behavior and error handling

## 📋 Common Objects for Agent Interactions

These assets focus on the **most common Salesforce objects** that customers use when interacting with agents. These represent the core use cases we've begun with:

### Standard CRM Objects

**Account** - Company/organization management
- Create, read, update, delete accounts
- Parent account resolution
- Industry and billing information

**Contact** - Person/individual management
- Contact operations with email/name resolution
- Account relationship handling
- Email and phone management

**Opportunity** - Sales pipeline and deal tracking
- Opportunity management with stage tracking
- Amount and close date handling
- Account relationship

**Case** - Customer service and support
- Case creation and management
- Priority and status handling
- Account and contact relationships

**Task** - Activity and to-do management
- Task creation and tracking
- WhoId (Contact/Lead) and WhatId (Account/Opportunity/Case) support
- Status and priority management

### Custom Objects (Demo/POC)

**Meeting__c** - Field sales activities
- Purpose-built for pharmaceutical and medical device field sales
- Meeting type, outcome, and status tracking
- Sample and marketing material tracking
- Follow-up and signature management

**CustomerOrders__c** - Order management
- Order creation with nested line items
- Distribution center and shipping address tracking
- Status management for fulfillment

These objects represent our starting point, but the framework is designed to expand to additional objects and use cases as needed.

## 🏗️ Architecture Patterns

### 1. Shared Utility Pattern
**Core Logic**: `AFUniversalCrmRecordAction` contains all CRUD logic
**Action Classes**: Thin wrappers that delegate to the utility
**Benefit**: Single source of truth, consistent behavior, easier maintenance

### 2. Consolidated Invocable Action Pattern
Every action class:
- Uses `@InvocableMethod` annotation
- Supports all CRUD operations (create, read, update, delete, find) via `operation` parameter
- Operation can be explicitly specified or automatically inferred from context
- Has comprehensive Request/Response inner classes that handle all operation types
- Includes detailed labels and descriptions for all variables
- Provides guidance in `@InvocableMethod` description
- Single class per object (e.g., `AFAccountAction`) instead of 5 separate classes

### 3. Ambiguity-First Design
**Never silently pick the first match**. When multiple records match:
1. Detect ambiguity
2. Return `AmbiguousRelationshipException` with candidate list
3. Agent prompts user: "I found 2 Acme Corp accounts. Which one?"
4. User clarifies, agent retries with specific ID or additional criteria

### 4. Name-Based Resolution
Agents don't need to lookup IDs first:
- "Update Acme Corp account" → System resolves by name
- "Create contact for John Smith at Acme" → System resolves both
- Supports account-scoped contact lookups for better disambiguation

### 5. Preview & Enrichment
**Preview Mode** (`confirm=false`):
- Agent sees what would be created/updated
- System suggests additional fields
- Agent can ask user for more context
- Agent calls again with `confirm=true` to commit

**Field Enrichment**:
- When minimal data provided, system suggests commonly-used fields
- Agent proactively asks user for additional context
- Better data quality from the start

## 📋 Key Design Decisions

### Why JSON Parameters?
- `fieldDataJson` and `filtersJson` are preferred over structured lists
- Easier for AI agents to construct dynamically
- More flexible for complex nested data
- Still support legacy structured parameters for backward compatibility

### Why Semantic Intelligence?
- Scales to language variations we didn't anticipate
- Handles sentiment, context, and intent naturally
- No maintenance burden of phrase mappings
- Leverages AI's core strength: understanding language

### Why Ambiguity Exceptions?
- Prevents silent data errors
- Enables natural clarification flows
- Returns rich candidate details for user decision
- Supports account-scoped searches for better resolution

### Why Shared Utility?
- Consistency across all objects
- Single place to fix bugs or add features
- Easier to test core logic
- Reduces code duplication

## 🔧 How We Built It: Implementation Details

### Adding a New Object (e.g., Lead)

1. **Update Core Utility** (`AFUniversalCrmRecordAction.cls`):
   ```apex
   // Add to SUPPORTED_OBJECTS
   private static final Set<String> SUPPORTED_OBJECTS = new Set<String>{
       'account', 'contact', 'case', 'opportunity', 'task', 'meeting__c', 'lead'
   };
   
   // Add search conditions
   when 'lead' {
       addLikeCondition('FirstName', likePattern, fieldMap, orConditions);
       addLikeCondition('LastName', likePattern, fieldMap, orConditions);
       addLikeCondition('Email', likePattern, fieldMap, orConditions);
       addLikeCondition('Company', likePattern, fieldMap, fieldMap);
   }
   
   // Add required fields
   when 'lead' {
       required.add('LastName');
       required.add('Company');
   }
   
   // Add suggested fields
   'lead' => new List<String>{'FirstName', 'Email', 'Phone', 'Company', 'Status'}
   ```

2. **Create 1 Consolidated Action Class**:
   - `AFLeadAction.cls` (supports all CRUD operations via `operation` parameter)
   - Operation can be explicitly specified or inferred from context
   - Includes operation inference logic
   - Comprehensive Request/Response classes that handle all operation types

3. **Follow the Pattern**:
   - Copy from similar object (e.g., `AFContactAction`)
   - Update object name references
   - Update field-specific logic if needed
   - Add comprehensive labels/descriptions
   - Implement `inferOperation()` method for context-based operation detection

4. **Update Permissions**:
   - Add class access to `AgentCourseSDOCustomAssetPermissions` permission set
   - Add object permissions
   - Add field permissions (except required fields)

5. **Update Documentation**:
   - Add to README.md
   - Update object support matrix

### Adding Semantic Intelligence to Picklists

In the `@InvocableMethod` description, add:
```
AGENT INTELLIGENCE: Use your semantic understanding to map natural language to structured fields.
For [FieldName], analyze the context and select the most appropriate value from available options.
Query availableFieldsJson to see valid picklist values. If input does not clearly map, leave blank.
```

In the `fieldDataJson` variable description, add:
```
INTELLIGENT FIELD MAPPING: Use your semantic understanding to map natural language to structured fields.
Parse [field type] from context, infer [other field] from sentiment, detect [flag] from language patterns.
Query availableFieldsJson to see valid picklist options, then use your best judgment to map.
```

## 🚨 Common Pitfalls to Avoid

### ❌ Don't: Hardcode Phrase Mappings
```apex
// BAD
if (input.contains("lunch")) return "In-Person Visit";
if (input.contains("zoom")) return "Virtual Meeting";
```

### ✅ Do: Empower Agent Intelligence
```apex
// GOOD - In @InvocableMethod description
"Use your semantic understanding to map natural language. 
Analyze context (lunch, office visit, zoom call) and select 
the most appropriate value. Query availableFieldsJson for valid options."
```

### ❌ Don't: Silently Pick First Match
```apex
// BAD
List<Account> accounts = [SELECT Id FROM Account WHERE Name = :name LIMIT 1];
return accounts[0].Id; // What if there are 2?
```

### ✅ Do: Detect and Handle Ambiguity
```apex
// GOOD
List<Account> accounts = [SELECT Id, Name, BillingCity, Industry 
                          FROM Account WHERE Name = :name];
if (accounts.size() > 1) {
    throw new AmbiguousRelationshipException('Account', name, accounts);
}
```

### ❌ Don't: Require IDs for Everything
```apex
// BAD - Agent must lookup ID first
updateAccount(accountId, fieldData);
```

### ✅ Do: Support Name-Based Resolution
```apex
// GOOD - Agent can use name directly
updateAccount(null, '{"Name":"Acme Corp","Status__c":"Active"}');
// System resolves "Acme Corp" to ID automatically
```

## 📚 Key Use Cases

### Use Case 1: Natural Language Meeting Creation
**User**: "I had lunch with Dr. Smith today, discussed Product X, went really well, need to follow up"

**Agent Flow**:
1. Calls `AFMeetingCreateAction` with natural language extracted to JSON
2. Agent infers: lunch→In-Person Visit, today→Completed, went well→Productive, follow up→true
3. System suggests additional fields (Account, Contact) if not provided
4. Agent asks user for Account/Contact if needed
5. Creates meeting with rich data

### Use Case 2: Ambiguity Resolution
**User**: "Create a task for Bob Smith"

**Agent Flow**:
1. Calls `AFTaskCreateAction` with `contactNameOrEmail="Bob Smith"`
2. System finds 2 contacts named "Bob Smith"
3. Throws `AmbiguousRelationshipException` with candidates
4. Agent asks user: "I found 2 Bob Smith contacts: Bob Smith at Acme Corp (San Francisco) and Bob Smith at Globex (Austin). Which one?"
5. User clarifies: "The one at Acme Corp"
6. Agent retries with account context or specific ID
7. Task created with correct contact

### Use Case 3: Preview Before Commit
**User**: "I want to create an account called Acme Corp"

**Agent Flow**:
1. Calls `AFAccountCreateAction` with `confirm=false`
2. System returns preview with suggested fields (Industry, BillingCity, etc.)
3. Agent asks user: "I can create Acme Corp. Would you like to provide Industry, Billing City, or other details?"
4. User provides additional info
5. Agent calls again with `confirm=true` and enriched data
6. Account created with complete information

## 🎓 What Makes These Actions "Agent-Friendly"?

1. **Comprehensive Metadata**: Every variable has label and description
2. **Intelligent Guidance**: @InvocableMethod descriptions guide agent behavior
3. **Flexible Input**: JSON parameters allow dynamic construction
4. **Error Prevention**: Ambiguity detection prevents silent failures
5. **Enrichment Support**: Suggests fields to improve data quality
6. **Preview Mode**: Allows agent to verify before committing
7. **Natural Language Support**: Name-based resolution, semantic inference

### Key Takeaways for Building Agent Actions

- **Trust the Agent's Intelligence**: Don't over-constrain with rigid rules
- **Provide Rich Context**: Labels, descriptions, and guidance help agents make good decisions
- **Handle Edge Cases**: Ambiguity, missing data, and errors are common
- **Enable Iteration**: Preview mode and enrichment support conversational flows
- **Think Like an Agent**: What information does the agent need? What decisions does it need to make?

## 🔗 Related Resources

- **README.md**: User-facing documentation
- **AFUniversalCrmRecordAction.cls**: Core utility implementation
- **AmbiguousRelationshipException.cls**: Ambiguity handling pattern
- **AFMeetingCreateAction.cls**: Example of semantic intelligence pattern

