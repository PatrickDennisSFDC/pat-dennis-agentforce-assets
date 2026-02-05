# AGENTS.md - Agentforce Development Methodology & Lessons Learned

> **For AI Agents**: This document provides methodology, patterns, and lessons learned for building and testing Agentforce agents. Use this as a guide for understanding best practices, not as a feature catalog.

> ⚠️ **DOCUMENTATION IS REQUIRED**: After completing any code change, you MUST update documentation. See [Documentation Maintenance for AI Agents](#documentation-maintenance-for-ai-agents) and `.cursorrules` for requirements.

## 📋 Table of Contents

- [Core Philosophy](#core-philosophy)
- [Testing Methodology](#testing-methodology)
- [Topic Design Patterns](#topic-design-patterns)
- [Search & Fuzzy Matching Patterns](#search--fuzzy-matching-patterns)
- [Action Design Patterns](#action-design-patterns)
- [Metadata & Configuration](#metadata--configuration)
- [Debugging & Troubleshooting](#debugging--troubleshooting)
- [Lessons Learned](#lessons-learned)
- [CLI Quick Reference](#cli-quick-reference)
- [Documentation Maintenance for AI Agents](#documentation-maintenance-for-ai-agents)
- [Related Documentation](#related-documentation) (includes RAG Architecture Options)

---

## Core Philosophy

### Design for Conversation, Not CRUD

Users don't think in Salesforce objects. They don't say "create an Opportunity record" - they say "update my deal." Design your agent's topics and actions around **user intent**, not database operations.

| User Says | Wrong Mental Model | Right Mental Model |
|-----------|-------------------|-------------------|
| "Update the Memorial deal" | Opportunity.update() | Pipeline management |
| "Log my meeting with Dr. Chen" | Meeting__c.insert() | Activity tracking |
| "What do we know about Acme?" | Account.query() | Research & intel |

### Prefer Flexibility Over Precision

In demo and real-world environments:
- **Always create the record** - Don't fail on missing optional data
- **Use fuzzy matching** - "permadyne oncology" should find "Permadyne GmbH - Oncology Protocol"
- **Make reasonable defaults** - If user doesn't specify, pick sensibly
- **Ask clarifying questions sparingly** - Only when truly ambiguous

### One Action Per Object

Don't create separate actions for different operations on the same object. The agent gets confused when there are multiple actions that could handle "opportunities."

```
❌ BAD: OpportunityCreateAction, OpportunityUpdateAction, OpportunityQueryAction
✅ GOOD: AFOpportunityAction (handles all operations via operation inference)
```

---

## Testing Methodology

### The Testing Loop

```
1. Write test spec (YAML) with realistic utterances
2. Deploy: sf agent test create --spec specs/MyTest.yaml
3. Run: sf agent test run --api-name MyTest --wait 60 --verbose
4. Analyze results - focus on patterns, not individual failures
5. Fix agent config or Apex based on themes
6. Repeat
```

**⚠️ Warning:** Running tests hold database locks on agent metadata. If you get "ORA-30006: resource busy" errors when trying to deactivate or modify the agent, cancel any running tests first.

### What Metrics Actually Tell You

| Metric | What It Measures | Interpretation |
|--------|------------------|----------------|
| **Action Pass %** | Were correct actions invoked? | Most reliable - 100% means routing works |
| **Topic Pass %** | Was correct topic selected? | Often 0% even when working (framework quirk) |
| **Outcome Pass %** | Did response match expectations? | Sensitive to wording - focus on themes |
| **Metric Pass %** | Coherence, completeness scores | Generally reliable quality indicator |

**Key insight**: If Action Pass is 100% but Outcome Pass is low, the problem is usually in Apex (search, data handling) not agent config.

### Writing Effective Test Cases

#### Use Realistic, Sloppy Inputs

```yaml
# GOOD - How users actually talk
utterance: "whats on the memorial cardiac deal"
utterance: "log a meeting i had with dr chen yesterday"
utterance: "move sunrise to negotiation"

# BAD - Too clean, not realistic
utterance: "Please retrieve OpportunityLineItems for Opportunity ID 006xxx"
utterance: "Create Meeting__c record with Contact lookup to 003xxx"
```

#### Test Edge Cases

```yaml
# Terse inputs
utterance: "sunrise update"
utterance: "memorial products"

# Ambiguous inputs
utterance: "add 3 more"  # 3 more what? To which deal?

# Multi-word fuzzy
utterance: "permadyne oncology deal"  # Should find "Permadyne GmbH - Oncology Protocol"
```

#### Multi-Turn Tests Are More Realistic

Real conversations have 3-5 turns. Single-turn tests are useful but don't capture context handling:

```yaml
testCases:
  - utterance: "yes, create it"
    conversationHistory:
      - role: user
        message: "log a meeting at memorial"
      - role: agent
        message: "I found Memorial Regional Hospital. Who did you meet with?"
      - role: user
        message: "Dr. Amanda Foster, office visit this morning"
      - role: agent
        message: "Got it - office visit with Dr. Foster at Memorial. Create this meeting?"
```

### Analyzing Test Results

Don't fix individual test failures. Look for **themes**:

1. **Search failures** - Agent says "not found" when record exists → Improve fuzzy matching
2. **Topic misrouting** - Wrong action invoked → Update topic routing claims
3. **Value mismatches** - "Negotiation" vs "Negotiation/Review" → Add dynamic normalization
4. **Context loss** - Agent forgets previous turns → Check conversation history handling
5. **Ambiguity** - Agent can't distinguish intent → Add clarification logic or routing claims

### ⚠️ Tests Modify Data!

**Agent tests can CREATE, UPDATE, and DELETE records in your org.** This causes discrepancies between expected values and actual results.

```
Test says: "Total pipeline for March is $986,750"
SOQL shows: $911,750

Why? The multi-turn test CREATED a $75,000 opportunity during execution!
```

**Implications:**
- Test expected values become stale as data changes
- Running the same test twice may produce different results
- Aggregate tests are particularly sensitive to data drift

**Recommendations:**
- Use isolated test data with predictable values
- Re-verify expected values before analyzing failures
- For aggregates, use ranges instead of exact values: "approximately $900K-$1M"

### Verifying Agent Responses with Ad-Hoc SOQL

When test results seem wrong, verify directly against the database:

```bash
# Total pipeline
sf data query --query "SELECT SUM(Amount) FROM Opportunity" --target-org myorg

# March 2026 deals
sf data query --query "SELECT SUM(Amount), COUNT(Id) FROM Opportunity WHERE CloseDate >= 2026-03-01 AND CloseDate <= 2026-03-31" --target-org myorg

# Pipeline by stage
sf data query --query "SELECT StageName, SUM(Amount), COUNT(Id) FROM Opportunity GROUP BY StageName ORDER BY SUM(Amount) DESC" --target-org myorg

# Recently modified (to catch test-created records)
sf data query --query "SELECT Name, Amount, LastModifiedDate FROM Opportunity WHERE LastModifiedDate = TODAY ORDER BY LastModifiedDate DESC" --target-org myorg
```

**Pro Tip:** Always check `LastModifiedDate = TODAY` to see what the tests changed!

---

## Topic Design Patterns

### Routing Claims and Exclusions

Every topic description should have explicit routing guidance:

```xml
<description>
  Manages sales opportunities and pipeline.
  
  ROUTING CLAIMS (use this topic):
  - "deal", "opportunity", "pipeline", "stage", "amount"
  - "close date", "forecast", "commit", "best case"
  - "products on deal", "line items", "quote"
  
  ROUTING EXCLUSIONS (do NOT use):
  - Meeting/activity logging → Activity Logging topic
  - Company background/intel → Account Research topic
  - Contact/Account updates → CRM Data Management topic
</description>
```

### Common Misrouting Patterns & Fixes

| Pattern | Problem | Solution |
|---------|---------|----------|
| "Update the [company] deal" | Routes to Account Research | Add "deal" to Pipeline claims |
| "What products are on [deal]" | Routes to Product catalog | Add "products on deal" to Pipeline |
| "Memorial update" | Interpreted as CRM update verb | Add context detection for noun vs verb |
| "[Company] opportunity" | Routes to Pipeline | Add exclusion: "upsell/cross-sell opportunity" → Intel |
| "tickets" for support cases | Routes to Orders | Add "tickets" to Cases topic claims |
| "billing cases" | Routes to Billing topic | Add exclusion in Billing, claim in Cases |
| "[company name] only" | Ambiguous object | Requires object keyword (order, deal, case) |

### The "Say the Object Name" Heuristic

**Key Insight**: Ultra-terse inputs without object keywords are fundamentally ambiguous. This is acceptable.

```
✅ "Check the Plasmosis order" → Orders (100% routing)
✅ "Check the Plasmosis deal" → Pipeline (100% routing)
❌ "Check Plasmosis" → Ambiguous (could be order, deal, account intel, case)
```

**Recommendation**: Train users to include the object keyword when context is unclear:
- "order" → Orders & Fulfillment
- "deal" / "opportunity" → Pipeline & Deals
- "case" / "ticket" → Cases & Support
- "about" / "intel" → Account Research

This is a **reasonable expectation** - users naturally say "check the order" not just "check it."

### Topic Scope Definition

Be explicit about boundaries:

```xml
<scope>
  This topic handles: opportunity CRUD, stage updates, amount changes, 
  line item management, pipeline queries, forecasting.
  
  This topic does NOT handle: logging meetings (even if at an account), 
  retrieving account research, updating contact records, order fulfillment.
</scope>
```

---

## Search & Fuzzy Matching Patterns

### The Layered Search Strategy

```
1. SOSL (Full-Text Search) - Primary
   ↓ (if no results)
2. LIKE Queries - Fallback  
   ↓ (if ambiguous)
3. Disambiguation - Return candidates to user
```

### SOSL Implementation

SOSL handles tokenized, multi-word searches naturally:

```apex
// "memorial cardiac" becomes: FIND 'memorial* AND cardiac*' IN ALL FIELDS
String soslQuery = 'FIND \'' + soslSearchString + '\' IN ALL FIELDS ' +
                  'RETURNING Opportunity(Id, Name, Account.Name ' +
                  'ORDER BY LastModifiedDate DESC LIMIT 10)';
```

**When SOSL works well:**
- Multi-word searches ("permadyne oncology")
- Partial matches ("cardio" finds "CardioMonitor Pro")
- Cross-field searches (finds in Name, Account.Name, etc.)

**When SOSL fails:**
- Very short terms (< 2 chars)
- Special characters
- Needs LIKE fallback

### Search Term Normalization

Strip common words users add but aren't in records:

```apex
// "the memorial deal" → "memorial"
// "my sunrise opportunity" → "sunrise"
private static String normalizeSearchTerm(String term) {
    return term.toLowerCase()
        .replace(' deal', '')
        .replace(' opportunity', '')
        .replace(' opp', '')
        .replace('the ', '')
        .replace('my ', '')
        .trim();
}
```

### Company Name Normalization

Strip business suffixes:

```apex
// "Permadyne GmbH, LTD" → "permadyne"
// "Acme Corp." → "acme"
private static String normalizeCompanyName(String name) {
    return name.toLowerCase()
        .replaceAll(',?\\s*(inc\\.?|llc|corp\\.?|ltd\\.?|gmbh)\\s*$', '')
        .trim();
}
```

### Dynamic Picklist Normalization

Users say "negotiation" but the picklist value is "Negotiation/Review". Query valid values at runtime and fuzzy match:

```apex
// Matching strategies (in order):
// 1. Exact match
// 2. Case-insensitive
// 3. Normalized (no punctuation): "negotiation review" → "Negotiation/Review"
// 4. Prefix: "negot" → "Negotiation/Review"
// 5. Contains: "review" → "Negotiation/Review"
// 6. Levenshtein distance: "negoitation" → "Negotiation" (typo)
```

### Product Fuzzy Matching

Product names need aggressive matching:

```apex
// All should match "CardioMonitor Pro":
// - "cardiomonitor pro" (case)
// - "cardiomonitors" (pluralization)
// - "cardio monitors" (word tokenization)
// - "cardimonitor" (Levenshtein typo)
```

---

## Action Design Patterns

### @InvocableVariable Requirements

**Every @InvocableVariable MUST have a description** - Agent Builder requires descriptions for both input and output variables to generate proper schema instructions.

```apex
// ❌ BAD - Missing descriptions, Agent Builder shows empty instructions
@InvocableVariable(label='Success')
public Boolean success;

// ✅ GOOD - Full description for agent context
@InvocableVariable(label='Success' description='Whether the update completed successfully. True if fields were updated, false if an error occurred.')
public Boolean success;
```

### Unsupported @InvocableVariable Types

Some Apex types are **not supported** for @InvocableVariable. Use JSON strings as workarounds:

```apex
// ❌ BAD - Map<String, Integer> not supported
@InvocableVariable(label='Updated Scores')
public Map<String, Integer> updatedScores;

// ✅ GOOD - Use JSON string instead
@InvocableVariable(label='Updated Scores JSON' description='JSON map of field names to scores. Example: {"Champion": 4, "Economic Buyer": 3}')
public String updatedScoresJson;
```

**Unsupported types include:**
- `Map<String, Integer>` and other Map types
- Custom Apex classes (use JSON serialization)
- Complex nested objects

### Operation Inference

Let the action figure out what operation based on context:

```apex
private static String inferOperation(Request req) {
    if (hasAggregateParams(req)) return 'aggregate';
    if (hasRecordId && hasFieldData) return 'update';
    if (hasRecordId && !hasFieldData) return 'read';
    if (hasSearchTerm && hasFieldData) return 'update'; // find-then-update
    if (hasFieldData && !hasRecordId) return 'create';
    if (hasSearchTerm || hasFilters) return 'find';
    throw new ActionException('Could not infer operation');
}
```

### Aggregate Integration

Don't create separate "analytics" actions. Integrate aggregates into object actions:

```apex
// User says: "total pipeline this quarter"
// Agent calls: AFOpportunityAction with:
//   - aggregateFunction: "SUM"
//   - aggregateField: "Amount"
//   - dateRangePredefined: "THIS_QUARTER"
```

### Aggregate/Find Query Alignment

**Critical:** Aggregate and find operations MUST use identical filtering logic, or users will get inconsistent results.

**The Problem:**
```
User: "What's my total pipeline this month?"
Agent: "$613,500 across 4 opportunities"

User: "What are those 4 opportunities?"
Agent: Returns only 2 opportunities worth $402,500

Why? Aggregate counted ALL opps (open + closed), find only returned OPEN opps.
```

**The Solution:** Apply semantic defaults consistently across operations. For "pipeline" queries:

```apex
// In AFOpportunityAction - apply same default to BOTH aggregate and find
Boolean hasIsClosedFilter = !String.isBlank(filtersJson) && 
                             filtersJson.toLowerCase().contains('isclosed');

if (!hasIsClosedFilter) {
    // "Pipeline" means OPEN deals - add IsClosed = false
    filtersToUse = addIsClosedFalseFilter(filtersToUse);
}
```

**Key Principles:**
1. **Semantic defaults** - "Pipeline" means open deals, not all deals
2. **Consistent filtering** - Same defaults for aggregate AND find
3. **Escape hatch** - Users can override by explicitly specifying IsClosed

### Handling Ambiguity

When multiple records match, return candidates for clarification:

```apex
if (results.size() > 1) {
    res.success = false;
    res.ambiguous = true;
    res.message = 'Multiple matches found. Did you mean: ' + 
        formatCandidates(results);
    res.records = results;
}
```

---

## Metadata & Configuration

### GenAiPlannerBundle Structure

```
genAiPlannerBundles/{AgentName}/
├── {AgentName}.genAiPlannerBundle     # Main XML
├── localActions/{Topic}/{Action}/
│   ├── input/schema.json              # Input parameters (READ-ONLY SNAPSHOT!)
│   └── output/schema.json             # Output parameters (READ-ONLY SNAPSHOT!)
```

### ⚠️ CRITICAL: The Schema Snapshot Problem

**The input/output schema.json files are READ-ONLY snapshots that CANNOT be deployed via metadata API.**

When you add an action to an agent in Agent Builder, Salesforce creates a **snapshot** of the action's input/output schema at that moment. This snapshot determines what parameters the agent "sees" and can pass to your action.

**The Problem:**
```
1. You add AFOpportunityAction to agent (snapshot created with current params)
2. Later, you add new params to Apex: dateRangeStart, aggregateFunction, etc.
3. You deploy the updated Apex class ✅
4. BUT: Agent still has OLD schema snapshot - it doesn't know about new params!
5. Agent refuses to use new params because they're not in its schema
```

**Symptoms of Schema Mismatch:**
- Agent says "I can't do that" for functionality you know exists in Apex
- Action works for old features but not new ones
- Tests show 0% Action Pass for queries using new parameters
- Error: "Not available for deploy for this API version" when trying to deploy schema

### How to Update Action Schemas

The ONLY way to update an action's schema is to re-add the action:

```
1. In Agent Builder: Remove the action from the topic
2. Deploy updated Apex class with new @InvocableVariable params
3. In Agent Builder: Re-add the action to the topic (regenerates schema)
4. Verify: sf project retrieve start --metadata GenAiPlannerBundle
5. Check schema.json now includes new parameters
```

**Pro Tip:** When adding new parameters to an Apex action:
- Always plan for the Agent Builder step
- Document what parameters exist vs. what schema the agent has
- Consider batching parameter additions to minimize Agent Builder trips

### Batch Schema Refresh Workflow

When you've added parameters to multiple actions (e.g., Opportunity, Meeting, Customer Order), refresh all of them at once:

```bash
# 1. Deactivate agent
sf agent deactivate --api-name Hank --target-org myorg

# 2. In Agent Builder UI:
#    - Remove Agentforce Opportunity Action from Pipeline topic
#    - Remove Agentforce Meeting Action from Activity Logging topic
#    - Remove Agentforce Customer Order Action from Orders topic
#    - Re-add all three actions to their respective topics

# 3. Retrieve bundle to get new API names
sf project retrieve start --metadata GenAiPlannerBundle:Hank --target-org myorg --output-dir /tmp/bundle
grep -r "fullName>Agentforce" /tmp/bundle/

# 4. Update ALL test specs with new action API names
sed -i '' 's/Agentforce_Opportunity_Action_OLD/Agentforce_Opportunity_Action_NEW/g' specs/*.yaml
sed -i '' 's/Agentforce_Meeting_Action_OLD/Agentforce_Meeting_Action_NEW/g' specs/*.yaml
sed -i '' 's/Agentforce_Customer_Order_Action_OLD/Agentforce_Customer_Order_Action_NEW/g' specs/*.yaml

# 5. Reactivate agent
sf agent activate --api-name Hank --target-org myorg
```

**⚠️ Action API Names Change!** When you re-add an action, it gets a NEW API name (e.g., `_179Kj000000t4XF` → `_179Kj000000t668`). Always update test specs after refreshing actions.

### ⚠️ Safe Bundle Retrieval (Preventing Missing Schemas)

**The Problem:** When retrieving GenAiPlannerBundles, the CLI can sometimes only retrieve the main `.genAiPlannerBundle` XML file without the `localActions/` subdirectory containing schema.json files. This happens when:

1. Retrieving to an existing workspace without `--output-dir`
2. Incremental retrieves that don't trigger full bundle download
3. API errors that partially complete

**Symptoms:**
- Bundle folder exists but has no `localActions/` or `plannerActions/` subdirectory
- `schema.json` files are missing
- Agent actions don't work correctly

**The Solution:** Always use `--output-dir` to retrieve bundles to a clean temporary location:

```bash
# CORRECT: Retrieve to temp directory first
sf project retrieve start --metadata GenAiPlannerBundle:Hank \
  --target-org myorg \
  --output-dir /tmp/bundle

# Then verify schemas exist before copying
find /tmp/bundle -name "schema.json" | wc -l

# INCORRECT: Direct retrieve to workspace (may lose schemas)
sf project retrieve start --metadata GenAiPlannerBundle:Hank --target-org myorg
```

**Helper Scripts:**

This project includes two scripts to make this safe and easy:

```bash
# Refresh all agent bundles with verification
./scripts/refresh-agent-bundles.sh

# Refresh a specific agent
./scripts/refresh-agent-bundles.sh Hank

# Verify schemas exist (use in CI/CD)
./scripts/verify-agent-schemas.sh
```

The `refresh-agent-bundles.sh` script:
1. Retrieves each bundle to a temp directory
2. Verifies schema.json files exist
3. Only copies to project if complete
4. Reports any failures

**Recommendation:** Run `./scripts/verify-agent-schemas.sh` after any bundle retrieval or before committing GenAiPlannerBundle changes.

### Updating Action Instructions (Description Only)

Agent action **instructions** (the description text) CAN be updated via Tooling API without re-adding the action. Only the **schema** (parameter list) requires re-adding.

```bash
# 1. Deactivate agent (required!)
sf agent deactivate --api-name Hank --target-org myorg

# 2. Update description via Tooling API
sf data update record --sobject GenAiFunctionDefinition \
  --record-id <ID> \
  --values "Description='New instructions...'" \
  --target-org myorg --use-tooling-api

# 3. Reactivate
sf agent activate --api-name Hank --target-org myorg
```

### Date Filtering: A Case Study

Date filtering illustrates the schema problem perfectly:

**Apex Has:**
```apex
@InvocableVariable(label='Date Range Start')
public String dateRangeStart;  // YYYY-MM-DD format

@InvocableVariable(label='Date Range End')  
public String dateRangeEnd;    // YYYY-MM-DD format

@InvocableVariable(label='Date Range Predefined')
public String dateRangePredefined;  // THIS_MONTH, THIS_QUARTER, etc.
```

**But Agent Only Sees (old schema):**
```json
{
  "properties": {
    "searchTerm": {...},
    "recordId": {...}
    // NO dateRangeStart, dateRangeEnd, etc.!
  }
}
```

**Result:** User asks "total pipeline for March" → Agent doesn't know `dateRangeStart` exists → Agent says "I can't filter by date"

**Fix:** Remove and re-add action in Agent Builder → New schema includes date params → Date filtering works!

### Prompt Template Actions

To use a prompt template as an agent action:

1. Create a `GenAiFunction` with `invocationTargetType: generatePromptResponse`
2. The prompt template MUST have at least one input variable
3. Link the function to a topic in Agent Builder

```xml
<GenAiFunction>
    <invocationTarget>My_Prompt_Template</invocationTarget>
    <invocationTargetType>generatePromptResponse</invocationTargetType>
</GenAiFunction>
```

### Agent/Bot Deployment Order

**Agents MUST be created in Agent Builder first** - you cannot deploy Bot or GenAiPlannerBundle metadata for a new agent via CLI. The deployment will fail with missing dependencies.

**Correct order for new agents:**
```
1. Deploy Apex classes (invocable actions) via CLI
2. Deploy LWC, Tabs, FlexiPages via CLI  
3. Create agent in Agent Builder UI (this creates Bot + GenAiPlannerBundle in org)
4. Add topics and actions in Agent Builder
5. THEN retrieve metadata: sf project retrieve start --metadata GenAiPlannerBundle
6. Store retrieved bundle in source control for reference
```

**Common deployment errors:**
```
# Bot requires GenAiPlannerBundle to exist
"Required fields are missing: [PlannerId]"

# Permission set references non-existent agent
"In field: botDefinition - no Bot named My_Agent found"
```

**Workaround:** Don't include bot/agent metadata in initial deployments. Deploy Apex + LWC first, create agent in UI, then add agent access to permission sets.

### FlexiPage Configuration

When creating FlexiPages for LWC components:

```xml
<!-- ❌ BAD - Wrong template name -->
<template>
    <name>flexipage:appHomeTemplate</name>
</template>

<!-- ✅ GOOD - Use defaultAppHomeTemplate -->
<template>
    <name>flexipage:defaultAppHomeTemplate</name>
</template>
```

```xml
<!-- ❌ BAD - Missing c: namespace prefix -->
<componentName>myComponent</componentName>

<!-- ✅ GOOD - Include c: prefix for custom LWC -->
<componentName>c:myComponent</componentName>
<identifier>c_myComponent1</identifier>
```

### Agent Builder Character Limits

When creating agents in Agent Builder, be aware of field limits:

| Field | Approximate Limit |
|-------|------------------|
| Role | ~255 characters |
| Company | ~220 characters |
| Description | Longer, but keep concise |
| Topic Instructions | No hard limit, but chunked |

Keep Role and Company descriptions brief - they're included in every agent prompt.

---

## Debugging & Troubleshooting

### Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| "Can not update record as Agent is Active" | Deploying while active | Deactivate first |
| "Record not found" | Search too strict | Improve fuzzy matching |
| "field cannot be filtered in query" | LIKE on Long Text Area | Use different fields |
| Test passes but wrong behavior | Loose expectedOutcome | Tighten test assertions |
| "Not available for deploy for this API version" | Trying to deploy schema.json | Can't deploy - re-add action in Agent Builder |
| Agent says "I can't do that" for known feature | Schema mismatch | Re-add action to regenerate schema |
| New params work in Apex tests but not agent | Schema snapshot is stale | Re-add action in Agent Builder |
| "ORA-30006: resource busy" on deactivate | Running test holds DB lock | Cancel/delete running tests first |
| "InvocableVariable fields do not support type of Map<String,X>" | Unsupported @InvocableVariable type | Use JSON String instead of Map |
| "Required fields are missing: [PlannerId]" | Deploying Bot before agent exists | Create agent in Agent Builder first |
| "no Bot named X found" in PermissionSet | Agent doesn't exist in org | Create agent first, then add to permission set |
| "Template flexipage:appHomeTemplate doesn't exist" | Wrong FlexiPage template | Use `flexipage:defaultAppHomeTemplate` |
| Agent Builder shows empty Instructions for outputs | Missing @InvocableVariable description | Add description attribute to all variables |

### SOQL Gotchas

**Long Text Area fields can't be filtered:**
```apex
// ❌ BAD - Description is Long Text Area
WHERE Description LIKE '%search%'

// ✅ GOOD - Use standard text fields
WHERE Name LIKE '%search%' OR NextStep LIKE '%search%'
```

**Case Object Specifics:**
```apex
// ❌ BAD - Case.Description is Long Text Area, can't use LIKE
WHERE Description LIKE '%issue%'

// ✅ GOOD - Use CaseNumber, Subject, or Account.Name
WHERE CaseNumber LIKE '%001186%' OR Subject LIKE '%issue%' OR Account.Name LIKE '%acme%'
```

**Relationship fields must be in SELECT:**
```apex
// Must include Account.Name in SELECT to filter on it
SELECT Id, Name, Account.Name FROM Opportunity 
WHERE Account.Name LIKE '%acme%'
```

### Debug Logging

Add debug statements at key points:

```apex
System.debug(LoggingLevel.INFO, 'SOSL Query: ' + soslQuery);
System.debug(LoggingLevel.INFO, 'Found ' + results.size() + ' records');
System.debug(LoggingLevel.INFO, 'Inferred operation: ' + operation);
```

---

## Lessons Learned

### What Works Well

1. **SOSL for primary search** - Handles multi-word, partial matches naturally
2. **Dynamic picklist normalization** - Don't hardcode values, query at runtime
3. **One action per object** - Reduces agent confusion
4. **Multi-turn tests** - More realistic than single-turn
5. **Explicit topic routing claims** - Prevents misrouting
6. **Operation inference** - Let context determine the operation
7. **Semantic filter defaults** - "Pipeline" defaults to open deals (IsClosed=false), ensuring aggregate counts match find results
8. **DOB verification for healthcare** - Patients expect security; wrong DOB should block access (no fuzzy matching on identity)
9. **Natural language date parsing** - Agent handles "June 15, 1985", "6/15/85", "1985-06-15", "15th of June 1985" equally well
10. **Topic instruction updates via Tooling API** - Can update GenAiPluginDefinition.Description via REST API without re-adding actions
11. **Proactive follow-up offers** - "Would you like to make any changes?" after showing data improves UX

### What Doesn't Work

1. **Exact match searches** - Users are sloppy, data is inconsistent
2. **Hardcoded picklist values** - Orgs differ, values change
3. **Separate actions per operation** - Agent gets confused
4. **Vague topic descriptions** - Leads to misrouting
5. **Single-turn-only testing** - Misses context handling issues
6. **Adding Apex params without updating Agent Builder** - Schema mismatch breaks features
7. **Trying to deploy schema.json changes** - They're read-only snapshots
8. **Deploying Bot metadata for new agents** - Must create in Agent Builder first
9. **Map types in @InvocableVariable** - Use JSON strings instead
10. **Missing descriptions on output variables** - Agent Builder requires them
11. **Ultra-terse inputs without object names** - "[Company]" alone is ambiguous
12. **LIKE queries on Long Text Area fields** - Use standard text fields instead
13. **External service input/output schema confusion** - If action receives response data as INPUT and returns null, the OpenAPI spec has input/output fields swapped
14. **Case-sensitive email lookups** - APIs should normalize email case; patients type "LAUREN.BAILEY@EMAIL.COM" and expect it to work
15. **Generic error messages** - "There was an issue" tells patients nothing; be specific about what failed and reassure data is saved

### Common Pitfalls

1. **Over-confirming** - Asking "are you sure?" for every action annoys users
2. **Over-clarifying** - Asking for details you could infer or default
3. **Failing on missing data** - Better to create with defaults than reject
4. **Too many topics** - Harder for agent to route correctly
5. **Ignoring test themes** - Fixing individual tests vs. patterns
6. **Schema Drift** - Adding Apex params but forgetting Agent Builder step. **Always re-add action after adding new @InvocableVariable params.**
7. **Assuming deploy updates schemas** - schema.json is a snapshot, not live metadata
8. **Stale test specs** - Re-adding action changes its API name. Update test specs with new `expectedActions` values after refreshing actions.
9. **Forgetting @InvocableVariable descriptions** - Both input AND output variables need descriptions for Agent Builder to show instructions.
10. **Wrong deployment order** - Deploy Apex/LWC first, create agent in UI, then permission sets.
11. **Tests as source of truth** - Test expected values become stale as data changes. Always verify with SOQL before debugging "failures".
12. **Partial schema refresh** - When adding params to multiple actions, refresh ALL of them. An agent with mixed schema versions behaves unpredictably.
13. **Expecting magic from terse inputs** - "Plasmosis" alone can't be routed correctly; require object keywords for disambiguation.
14. **RAG topics losing to CRUD topics** - Product knowledge topics need strong, explicit routing claims to avoid being overshadowed by "products on deal" (Pipeline).
15. **Aggregate/Find filter mismatch** - When aggregate says "4 opportunities" but find returns 2, the queries have different filters. Ensure semantic defaults (like IsClosed=false for "pipeline") apply to BOTH operations.
16. **Unsafe bundle retrieval** - Retrieving GenAiPlannerBundles directly to workspace can lose schema.json files. Always use `--output-dir` to temp location first, verify schemas exist, then copy. Use `./scripts/refresh-agent-bundles.sh` for safety.
17. **Wrong test data in specs** - If all lookups fail, verify the test persona data (email, DOB) matches what's in the external system. A single wrong character causes 100% failure.
18. **Asking for format specifications** - Don't tell patients "enter DOB in YYYY-MM-DD format"; accept natural language and parse it.
19. **Robotic compliance disclaimers** - Repeating "consult your healthcare provider" after every sentence is annoying; use conditional disclaimers only for high-risk questions (dosing, interactions, side effects).
20. **Black-box errors to patients** - Never say "there was an issue" without explaining what happened and what's next. Patients are anxious; reassure them their data is saved.

### Performance Considerations

- SOSL has governor limits (2000 records)
- Aggregate queries with GROUP BY can be slow on large datasets
- Cache picklist values if called frequently
- Limit search results to 10-20 for disambiguation

---

## Patient Services Agent Design (Healthcare)

> **For Patient Services VPs**: This section captures what patients need from AI assistants in healthcare settings. Patients are often anxious, confused, or in pain. The agent must be reassuring, clear, and helpful—not clinical or robotic.

### Core Principles

1. **Patients are anxious** - They're calling about health, medications, appointments. Every interaction carries emotional weight.
2. **Security builds trust** - Verify identity (DOB) before revealing PHI. Patients expect this and feel safer.
3. **Reassurance over efficiency** - "I've saved all your information" matters more than "processing complete."
4. **Clear next steps** - Never leave patients wondering what happens next.

### What Patients Want

| Need | Good Response | Bad Response |
|------|---------------|--------------|
| **Know data is safe** | "I've saved everything you've told me so far" | (silence) |
| **Understand errors** | "I couldn't submit right now, but your info is saved. Want me to try again?" | "There was an issue" |
| **Feel heard** | "I found your appointments, Lauren" | "Query returned 2 records" |
| **Get quick answers** | "Prolia is given as an injection every 6 months" | "Prolia (denosumab) is a RANK ligand inhibitor indicated for..." (500 words) |
| **Know what's next** | "A coordinator will call within 2 business days" | "Enrollment submitted" |

### Response Guidelines

**Length**: Keep responses concise
- Simple questions: Under 300 characters
- Safety info: Up to 500 characters  
- Complex topics: 800 max, use bullet points

**Disclaimers**: Use conditionally
- ✅ Include for: side effects, dosing, drug interactions, missed doses
- ❌ Skip for: "What is Prolia?", "How does it work?", general info
- Use short form after first mention: "Check with your doctor about your specific situation"

**Errors**: Be specific and reassuring
```
❌ "There was an issue processing your request"
✅ "I couldn't complete the enrollment just now, but I've saved all your 
   information. Would you like me to try again, or would you prefer to 
   speak with a representative?"
```

**Verification**: Security without friction
- Ask for name, email, DOB together (not one at a time)
- Accept natural date formats ("June 15, 1985" not "YYYY-MM-DD")
- If verification fails, offer help: "I couldn't find a match. Would you like to check your details or speak with someone?"

### Enrollment Flow Best Practices

1. **Set expectations upfront**: "This will take about 5-10 minutes. Your information is kept private and secure."
2. **Save incrementally**: Create/update the record as information is gathered, not just at the end
3. **Acknowledge progress**: "Great, I have your contact information. Now let's get your insurance details."
4. **Handle interruptions gracefully**: If patient needs to stop, confirm what's saved and how to resume
5. **Confirm before submitting**: Summarize collected info and ask for confirmation
6. **Provide clear next steps**: "You're enrolled! A coordinator will reach out within 2 business days to discuss your benefits."

### Testing Patient Flows

Test these scenarios from the patient's perspective:

```yaml
# Anxious patient - needs reassurance
utterance: "I'm not sure I have all my insurance info right now"
expected: "No problem - I can save what we have so far and you can call back with the rest"

# Confused patient - needs clarity  
utterance: "Wait, what did you need again?"
expected: Agent repeats the specific question clearly, doesn't start over

# Error scenario - needs transparency
utterance: (after system error)
expected: "I ran into a technical issue, but your information is safely saved..."

# Security verification - needs to feel protected
utterance: (wrong DOB provided)
expected: "I couldn't verify those details. Would you like to try again or speak with a representative?"
```

---

## CLI Quick Reference

### Testing

```bash
# Create test from spec
sf agent test create --spec specs/MyTest.yaml --target-org <org>

# Run test
sf agent test run --api-name MyTest --wait 60 --verbose --target-org <org>

# Get results from job
sf agent test results --job-id <job-id> --target-org <org>

# List all tests
sf agent test list --target-org <org>
```

### Agent Management

```bash
# Activate/Deactivate
sf agent activate --api-name <AgentName> --target-org <org>
sf agent deactivate --api-name <AgentName> --target-org <org>
```

### Metadata

```bash
# Retrieve agent bundle
sf project retrieve start --metadata GenAiPlannerBundle --target-org <org> --output-dir /tmp/bundle

# Deploy Apex
sf project deploy start --source-dir force-app/main/default/classes --target-org <org>

# Deploy bundle
sf project deploy start --source-dir /tmp/bundle/genAiPlannerBundles --target-org <org>
```

---

## Documentation Maintenance for AI Agents

> **This section is enforced via `.cursorrules`** - Cursor will automatically load these requirements for every AI agent session.

### When to Update Documentation

AI agents working on this codebase MUST update documentation when:

1. **Fixing a bug that reveals a pattern** - Add to "Lessons Learned" or "Common Pitfalls"
2. **Adding new behavior** - Document the "why" not just the "what"
3. **Discovering an edge case** - Future agents need to know
4. **Changing default behavior** - Critical for understanding intent

### What to Update

| Change Type | Update Location |
|-------------|-----------------|
| New pattern/best practice | `AGENTS.md` → Action Design Patterns |
| Bug fix with lesson | `AGENTS.md` → Lessons Learned / Common Pitfalls |
| New feature | `README.md` → Recent Updates |
| API/behavior change | Both `AGENTS.md` and `README.md` |

### Documentation Checklist

Before completing a task, AI agents should ask:

- [ ] Did I discover something that would have helped me earlier?
- [ ] Did I fix an issue others might encounter?
- [ ] Did I change behavior that isn't obvious from the code?
- [ ] Would a future developer/agent be confused without this context?

If yes to any, **update the docs**.

### File Structure

```
AGENTS.md         - Methodology, patterns, lessons (for AI agents building agents)
README.md         - Project overview, setup, changelog (for humans)
USE_CASES.md      - User personas and success criteria
specs/README.md   - Test specification format
```

### Example: Documenting a Fix

When you fix an issue like "aggregate returns 4, find returns 2":

1. **Identify the pattern**: Aggregate/find filter mismatch
2. **Add to AGENTS.md**:
   - New section under "Action Design Patterns" explaining the fix
   - Entry in "What Works Well" for the solution
   - Entry in "Common Pitfalls" warning about the anti-pattern
3. **Add to README.md**: Entry in "Recent Updates" with date
4. **Update the "Last Updated" date** in AGENTS.md

---

## Related Documentation

- `README.md` - Project overview and component inventory
- `USE_CASES.md` - User personas and success criteria
- `specs/README.md` - Test spec format and examples
- `docs/KNOWLEDGE_RAG_SETUP.md` - **Knowledge Articles + Files RAG Setup** - Complete guide for Data Cloud-based RAG using Salesforce Knowledge
- `docs/ARIA_NOVO_PLAN.md` - Patient Services architecture (includes knowledge architecture discussion)

### RAG Architecture Options

This repository supports **two approaches** for RAG (Retrieval Augmented Generation):

| Approach | Source | Documentation | Best For |
|----------|--------|---------------|----------|
| **S3 Bucket** | Documents uploaded to S3 → Data Cloud | `docs/enhanced-product-sop-prompt.md` | Static documents, large libraries, external content |
| **Knowledge + Files** | Salesforce Knowledge articles + attachments | `docs/KNOWLEDGE_RAG_SETUP.md` | Dynamic content, Knowledge authors, file attachments |

Both approaches use Einstein Search Retrievers and can be used independently or combined. See the respective documentation for setup instructions.

### Official Salesforce Docs

| Topic | URL |
|-------|-----|
| Agentforce DX Overview | https://developer.salesforce.com/docs/ai/agentforce/guide/agent-dx-overview.html |
| Agent Testing | https://developer.salesforce.com/docs/ai/agentforce/guide/agent-dx-test-run.html |
| Test Spec Format | https://developer.salesforce.com/docs/ai/agentforce/guide/agent-dx-test-spec.html |
| GenAiPlannerBundle | https://developer.salesforce.com/docs/atlas.en-us.api_meta.meta/api_meta/meta_genaiplannerbundle.htm |

---

*Last Updated: February 5, 2026*

> 📝 **Reminder**: If you made changes during this session, update the documentation before finishing! See `.cursorrules` and [Documentation Maintenance](#documentation-maintenance-for-ai-agents).

---

## Appendix: Code Patterns Reference

> **Note**: This section consolidates content previously in `AGENT_CONTEXT.md` and `AGENT_RULES.md`. Those files have been deprecated.

### Schema Configuration Quick Reference

**copilotAction Flags:**
- `copilotAction:isUserInput: false` - Default for most fields (keeps experience conversational)
- `copilotAction:isDisplayable: true` - For outputs shown to users
- `copilotAction:isUsedByPlanner: true` - Required for at least one output

**Record IDs in Responses:**
- Always internal-only - never include in success messages
- Output schema should state: "DO NOT mention to users"

### Writing Effective Agent Guidance

In `@InvocableMethod` descriptions:
1. Use "IMPORTANT" or "BEFORE calling" for critical guidance
2. Use "MUST" for required behavior, "Do NOT" for prohibited actions
3. Provide conversational response templates
4. Tailor examples to each object's relevant fields

### Adding New Objects

1. Add to `SUPPORTED_OBJECTS` in `AFUniversalCrmRecordAction`
2. Update `buildSearchConditions()` with object-specific search fields
3. Update `enforceCreateRequirements()` with required field validation
4. Update `getRequiredFields()` and `getSuggestedFields()`
5. Update `resolveRelatedRecords()` if object has lookups
6. Create consolidated action class: `AF[Object]Action`
7. Add to `AgentCourseSDOCustomAssetPermissions` permission set
8. Update README.md

---

## Appendix: Dynamic Agent Personality

### Coaching Intensity Pattern

For coaching-style agents (like Deal Review), allow users to control how challenging the agent should be:

```apex
// In your controller, accept coaching intensity (1-5 scale)
@AuraEnabled
public static AgentResponse sendAgentMessage(
    String opportunityId, 
    String userMessage, 
    String sessionId, 
    Integer sequenceId, 
    Integer coachingIntensity  // 1=Very Supportive, 5=Very Challenging
) {
    // Build coaching instructions based on intensity
    String coachingInstructions = getCoachingInstructions(coachingIntensity);
    
    // Prepend to context sent to agent
    String fullMessage = coachingInstructions + '\n\n' + opportunityContext + '\n\nUser: ' + userMessage;
}
```

**Coaching Levels:**

| Level | Label | Behavior |
|-------|-------|----------|
| 1 | Very Supportive | Gentle guidance, lots of encouragement, avoid challenging |
| 2 | Supportive | Balance encouragement with suggestions, phrase concerns as opportunities |
| 3 | Balanced | Mix of encouragement and challenge, point out gaps directly but tactfully |
| 4 | Challenging | Push for clarity, challenge vague responses, demand evidence |
| 5 | Very Challenging | Relentlessly rigorous, challenge every assumption, blunt feedback |

**Key Insight:** The coaching instructions are injected into the context at runtime, not baked into the agent's static instructions. This allows per-session customization.

### Session Feedback Integration

Collect feedback when users finish conversations to improve agent quality:

```apex
@AuraEnabled
public static FeedbackResponse saveFeedback(
    String sessionId,
    String opportunityId,
    String rating,        // 'positive' or 'negative'
    String comment,
    Integer messageCount
) {
    // Try GenAiFeedback standard object first
    // Fall back to custom logging if not available
}
```

**UI Pattern:**
- Show feedback modal when switching between records (if conversation occurred)
- Show after save/accept actions
- Thumbs up/down + optional comment
- Never block user on feedback errors - always proceed

**GenAiFeedback Object:** Salesforce's standard object for AI feedback. Check availability with:
```apex
Schema.SObjectType feedbackType = Schema.getGlobalDescribe().get('GenAiFeedback');
if (feedbackType != null && feedbackType.getDescribe().isCreateable()) {
    // Use GenAiFeedback
}
```
