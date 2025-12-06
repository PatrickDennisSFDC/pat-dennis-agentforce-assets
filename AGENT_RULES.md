# Agentforce SDO Assets - Agent Rules & Vibe

## Project Purpose
This repository is a store of Agentforce assets that make Agentforce better and help showcase its full potential. These assets are designed for use in Salesforce SDO (Salesforce Digital Office) environments and other Salesforce environments. The repository contains reusable components for building intelligent AI agents on Salesforce, with a focus on key use cases that continue to expand.

## Core Philosophy
- **Agent Intelligence Over Rigid Rules**: Empower AI agents to use semantic understanding rather than hardcoded mappings
- **Guardrails Without Handcuffs**: Provide guidance and structure while allowing agents to reason intelligently
- **Natural Language First**: All actions should accept natural language input and infer appropriate structured values
- **Ambiguity is Expected**: Always handle cases where multiple records match - never silently pick the first one

## Why Apex for Agentforce?

### Methodology & Framework
We've chosen to build Agentforce agents using Apex invocable actions for several key reasons:

**1. Native Salesforce Integration**
- Apex actions are first-class citizens in Salesforce
- Direct access to Salesforce data and metadata
- No external API calls or authentication overhead
- Leverages existing Salesforce security model

**2. Performance & Reliability**
- Executes within Salesforce's infrastructure
- Low latency for agent interactions
- Transaction safety with savepoint/rollback
- Handles bulk operations efficiently

**3. Flexibility & Extensibility**
- Can access any Salesforce object or field
- Supports complex business logic
- Dynamic SOQL generation for flexible queries
- Can integrate with other Salesforce features (flows, triggers, etc.)

**4. Agent-Friendly Patterns**
- `@InvocableMethod` annotation makes methods discoverable by agents
- Rich metadata (labels, descriptions) guides agent behavior
- Structured Request/Response classes provide clear contracts
- JSON parameters enable dynamic data construction

**5. Maintainability**
- Version controlled with Salesforce DX
- Testable with Apex test classes
- Reusable across multiple agents
- Centralized logic reduces duplication

### Theory Behind the Approach
The core theory is that **agents should interact with structured, intelligent actions** rather than raw APIs or complex queries. By wrapping business logic in invocable actions:
- Agents get semantic, purpose-built operations (Create Account, Find Contact)
- Complex logic is abstracted away (ambiguity handling, field enrichment)
- Agents can focus on understanding user intent, not technical implementation
- Actions can evolve independently without breaking agent behavior

## Common Objects for Agent Interactions

These assets focus on the most common Salesforce objects that customers use when interacting with agents:

**Standard CRM Objects:**
- **Account** - Company/organization management
- **Contact** - Person/individual management  
- **Opportunity** - Sales pipeline and deal tracking
- **Case** - Customer service and support
- **Task** - Activity and to-do management

**Custom Objects (Demo/POC):**
- **Meeting__c** - Field sales activities (pharmaceutical/medical device)
- **CustomerOrders__c** - Order management with line items

These objects represent the core use cases we've begun with, but the framework is designed to expand to additional objects and use cases.

## Key Design Patterns

### 1. Invocable Action Pattern
All action classes follow this structure:
- `AF[Object][Operation]Action` naming (e.g., `AFAccountCreateAction`)
- Request/Response inner classes with comprehensive labels and descriptions
- `@InvocableMethod` with detailed descriptions that guide agent behavior
- Delegate to `AFUniversalCrmRecordAction` for core logic

### 2. Semantic Intelligence Pattern
When handling picklist values or field mappings:
- **DO**: Instruct agents to use semantic understanding in @InvocableMethod descriptions
- **DO**: Query `availableFieldsJson` to see valid options dynamically
- **DO**: Allow agents to infer from context (e.g., "lunch" → "In-Person Visit")
- **DON'T**: Create hardcoded phrase-to-value mappings
- **DON'T**: Force agents to use exact phrases
- **DON'T**: Leave fields blank only as last resort - if unclear, leave blank

Example from Meeting actions:
```
AGENT INTELLIGENCE: Use your semantic understanding to map natural language to structured fields.
For Meeting_Type__c, analyze context (lunch, office visit, zoom call) and select the most 
appropriate value. If input does not clearly map, leave the field blank.
```

### 3. Ambiguity Handling Pattern
When resolving relationships (Account, Contact, etc.):
- Always check for multiple matches
- Throw `AmbiguousRelationshipException` with candidate list
- Return candidates with distinguishing details (Account: Name + City + Industry)
- Let the agent prompt the user for clarification
- Support ID detection at the start of resolution methods (user may provide ID directly)

### 4. Name-Based Resolution Pattern
- Support resolving records by name, not just ID
- Update operations can accept Subject/Name in fieldDataJson for automatic resolution
- Search conditions are object-specific and defined in `buildSearchConditions()`

### 5. Field Enrichment Pattern
- When minimal data provided, suggest commonly-used fields via `suggestedFields`
- Agent can ask user for additional context
- Preview mode (`confirm=false`) allows agent to see what would be created before committing

## Critical Classes

### AFUniversalCrmRecordAction
The backbone utility class. Contains:
- All CRUD operation logic
- Relationship resolution (Account, Contact by name)
- Ambiguity detection
- Field enrichment suggestions
- Transaction management (savepoint/rollback)
- Line item helpers for Customer Orders

**When extending**: Add new objects to `SUPPORTED_OBJECTS`, update `buildSearchConditions()`, `enforceCreateRequirements()`, `getRequiredFields()`, `getSuggestedFields()`, and `resolveRelatedRecords()`.

### AmbiguousRelationshipException
Custom exception for multiple matching records. Contains:
- `relationshipType` (e.g., "Account", "Contact")
- `searchCriteria` (what was searched)
- `candidates` (list of matching records with details)

## Adding New Objects

1. Add to `SUPPORTED_OBJECTS` in `AFUniversalCrmRecordAction`
2. Update `buildSearchConditions()` with object-specific search fields
3. Update `enforceCreateRequirements()` with required field validation
4. Update `getRequiredFields()` and `getSuggestedFields()`
5. Update `resolveRelatedRecords()` if object has lookups
6. Create 5 action classes: Create, Read, Update, Delete, Find
7. Add to `AgentCourseSDOCustomAssetPermissions` permission set
8. Update README.md

## Important Notes

- All classes use `with sharing` for security
- All invocable variables must have `label` and `description` for agent understanding
- Use JSON parameters (`fieldDataJson`, `filtersJson`) as preferred method (easier for agents)
- Support both single and bulk operations where applicable
- Customer Orders have special nested line item handling - see `handleLineItemsOnCreate()`, etc.
- Meeting actions have semantic intelligence instructions for picklist inference
- Never commit without user confirmation unless `confirm=true` (default)

