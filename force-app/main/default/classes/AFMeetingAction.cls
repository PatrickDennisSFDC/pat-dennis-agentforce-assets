/**
 * AF Meeting Action
 * Consolidated invocable action for all Meeting__c CRUD operations (Create, Read, Update, Delete, Find)
 * Designed for Agentforce AI agents
 */
public without sharing class AFMeetingAction {
    
    public class Request {
        @InvocableVariable(
            label='Operation'
            description='Explicit operation: "create", "read", "update", "delete", "find", or "aggregate". AGGREGATE for meeting analytics like "how many meetings this month", "meetings by type".'
        )
        public String operation;
        
        // ========== AGGREGATE OPERATION PARAMETERS ==========
        @InvocableVariable(label='Aggregate Function' description='For aggregate: SUM, COUNT, AVG, MIN, MAX. Example: COUNT for "how many meetings".')
        public String aggregateFunction;
        
        @InvocableVariable(label='Aggregate Field' description='For aggregate: Field to aggregate. Use "Id" for COUNT.')
        public String aggregateField;
        
        @InvocableVariable(label='Group By Fields JSON' description='For aggregate: JSON array of fields to group by. Example: ["Meeting_Type__c"] for meetings by type.')
        public String groupByFieldsJson;
        
        @InvocableVariable(label='Date Range Field' description='For aggregate: Date field to filter. Use "Meeting_Date__c".')
        public String dateRangeField;
        
        @InvocableVariable(label='Date Range Predefined' description='For aggregate: TODAY, THIS_WEEK, THIS_MONTH, THIS_QUARTER, etc.')
        public String dateRangePredefined;
        
        @InvocableVariable(label='Date Range Days' description='For aggregate with LAST_N_DAYS or NEXT_N_DAYS.')
        public Integer dateRangeDays;
        
        @InvocableVariable(
            label='Field Data JSON'
            description='JSON string containing Meeting field data. YOUR GOAL: Create meeting records that are genuinely useful to the sales team. A meeting with just a subject and date is almost worthless. A meeting with outcome, next steps, description, and product context is VALUABLE. Every meeting you create should answer: What happened, how did it go, and what needs to happen next? DATE INFERENCE (CRITICAL): If no date mentioned, DEFAULT TO TODAY. Do NOT ask for meeting date - infer it: today/this morning/this afternoon/just now/earlier -> today, yesterday/last night -> yesterday, last week/last Monday -> calculate the date. NEVER block meeting creation just because date is missing - use today as default. MINIMUM VIABLE MEETING - Do NOT create until you have: (1) Contact or Account - required (but proceed if neither found, capture name in description), (2) Meeting Date - default to today if not specified, (3) Subject - required, (4) Meeting Type - required via inference or asking, (5) Meeting Outcome - infer from context or default to Neutral, (6) Next Steps - strongly encouraged and ALWAYS ask if not mentioned, (7) Description - strongly encouraged and synthesize from conversation. SPARSE INPUT RULE: If user message does NOT contain at least TWO of: outcome sentiment, next steps, meeting type context - then STOP and ask follow-up questions. Do not create sparse records. Examples requiring probing: Log a meeting with X, I called X about their ticket. Example ready for inference: Stopped by X office, great chat about renewal, they want proposal next week. MANDATORY DESCRIPTION: Always populate Description__c with a 2-3 sentence narrative capturing: what was discussed, key outcomes or decisions, context that helps colleagues understand this meeting. Never leave Description__c blank. INTELLIGENT INFERENCE FOR MEETING TYPE: lunch/dinner/coffee/office/stopped by/visited -> In-Person Visit, zoom/teams/virtual/video/webex -> Virtual Meeting, called/phone/rang/dialed -> Phone Call, conference/trade show/event/expo -> Conference. INTELLIGENT INFERENCE FOR OUTCOME: great/excellent/amazing/really well/excited/love it -> Very Productive, good/productive/positive/on track/solid -> Productive, fine/okay/standard/routine/uneventful/quick/check-in -> Neutral, tough/challenging/concerns/issues/pushback/worried -> Needs Follow-up, disaster/rejected/not interested/dead end/lost/killed -> Unsuccessful. SAMPLES/MATERIALS: dropped off samples/left samples/gave samples -> Samples_Dropped_Off__c Yes, left brochures/marketing materials/collateral -> Marketing_Materials_Provided__c Yes. FOLLOW-UP DETECTION: follow up/next steps/action items/need to schedule/send proposal/get back to them -> Follow_Up_Required__c true and capture in Next_Steps__c. Use accountName or contactNameOrEmail to resolve lookups. FUZZY MATCHING: Account names use fuzzy matching so Accusage Inc matches Accusage, Inc and variations with different suffixes like Corp, LLC etc are handled automatically. DEMO MODE: This is a demo environment - prioritize creating records over asking clarifying questions. When in doubt, make a reasonable assumption and proceed.'
            required=false
        )
        public String fieldDataJson;
        
        @InvocableVariable(
            label='Record ID'
            description='The Salesforce record ID of the Meeting. Required for read/update/delete. Format: 18-character ID.'
        )
        public Id recordId;
        
        @InvocableVariable(
            label='Search Term'
            description='Text to search for in Meeting fields (Subject__c, Description__c, etc.). Used for find operations. IMPORTANT: If the user wants to find a meeting but hasn\'t provided a search term, ask them for the meeting subject, account/contact name, or other identifying information BEFORE calling this action. Do not call find operation without a searchTerm or filtersJson.'
        )
        public String searchTerm;
        
        @InvocableVariable(
            label='Filters JSON'
            description='JSON string of exact-match filters for find operations. IMPORTANT: If the user wants to find a meeting but hasn\'t provided specific filters, ask them for details like account/contact name, meeting date, or meeting type BEFORE calling this action. Do not call find operation without a searchTerm or filtersJson.'
        )
        public String filtersJson;
        
        @InvocableVariable(
            label='Search Limit'
            description='Maximum number of records to return for find operations (default: 5, max: 20).'
        )
        public Integer searchLimit;
        
        @InvocableVariable(
            label='Account Name'
            description='Account name to resolve to Account__c lookup. Use this when you know the company/organization but not a specific contact. If the user says they met with someone at Acme Corp or had a meeting at General Hospital, you can use accountName even without a contact. The Account will be linked to the meeting. Note: If you provide contactNameOrEmail, the Account is auto-populated from the Contact record so you usually do not need both.'
        )
        public String accountName;
        
        @InvocableVariable(
            label='Contact Name or Email'
            description='Contact name or email to resolve to Contact__c lookup. IMPORTANT: When a Contact is resolved, their Account is AUTOMATICALLY populated on the Meeting. You do NOT need to separately provide accountName if you have the contact. Example: If user says I met with Joe Dennis, just provide contactNameOrEmail and both Contact and Account will be linked. Only use accountName separately if you ONLY know the company, not a specific person.'
        )
        public String contactNameOrEmail;
        
        @InvocableVariable(
            label='Confirm'
            description='For create/update: Set to false to preview only. For delete: Set to true to actually delete.'
        )
        public Boolean confirm;
    }
    
    public class Response {
        @InvocableVariable(
            label='Success'
            description='True if operation completed successfully.'
        )
        public Boolean success;
        
        @InvocableVariable(
            label='Record'
            description='The Meeting record (for single record operations).'
        )
        public Meeting__c record;
        
        @InvocableVariable(
            label='Records'
            description='List of Meeting records (for bulk or find operations).'
        )
        public List<Meeting__c> records;
        
        @InvocableVariable(
            label='Record ID'
            description='The Salesforce ID of the record.'
        )
        public Id recordId;
        
        @InvocableVariable(
            label='Message'
            description='Human-readable message describing the operation result.'
        )
        public String message;
        
        @InvocableVariable(
            label='Error Message'
            description='If success is false, this contains a user-friendly error message.'
        )
        public String errorMessage;
        
        @InvocableVariable(
            label='Object Type'
            description='The Salesforce object type, always "Meeting__c" for Meeting operations.'
        )
        public String objectType;
        
        @InvocableVariable(
            label='Operation'
            description='The operation that was performed.'
        )
        public String operation;
        
        @InvocableVariable(
            label='Preview Only'
            description='True if this is a preview response.'
        )
        public Boolean previewOnly;
        
        @InvocableVariable(
            label='Enrichment Suggested'
            description='True if additional fields are suggested.'
        )
        public Boolean enrichmentSuggested;
        
        @InvocableVariable(
            label='Suggested Fields'
            description='List of commonly-used field API names.'
        )
        public List<String> suggestedFields;
        
        @InvocableVariable(
            label='Preview Data'
            description='A JSON string representation of what would be created/updated.'
        )
        public String previewData;
        
        @InvocableVariable(
            label='Available Fields JSON'
            description='JSON string containing metadata for all available fields.'
        )
        public String availableFieldsJson;
        
        @InvocableVariable(
            label='Ambiguous Relationship'
            description='True if a parent lookup found multiple matches.'
        )
        public Boolean ambiguousRelationship;
        
        @InvocableVariable(
            label='Ambiguous Relationship Type'
            description='The type of relationship that has multiple matches.'
        )
        public String ambiguousRelationshipType;
        
        @InvocableVariable(
            label='Relationship Candidates JSON'
            description='JSON array of candidate records when ambiguousRelationship is true.'
        )
        public String relationshipCandidatesJson;
        
        @InvocableVariable(
            label='Ambiguous Result'
            description='True if multiple records were found in a find/search operation.'
        )
        public Boolean ambiguous;
        
        @InvocableVariable(
            label='Total Matches'
            description='Number of Meeting records found in a find/search operation.'
        )
        public Integer totalMatches;
        
        @InvocableVariable(
            label='More Results Available'
            description='True if the search returned the maximum number of results but there are more matching records available.'
        )
        public Boolean moreResultsAvailable;
        
        @InvocableVariable(
            label='Confirmation Required'
            description='True if this is a confirmation request for delete operation.'
        )
        public Boolean confirmationRequired;
        
        // ========== AGGREGATE OPERATION RESPONSE FIELDS ==========
        @InvocableVariable(label='Aggregate Results JSON' description='For aggregate: JSON array of results.')
        public String aggregateResultsJson;
        
        @InvocableVariable(label='Total Value' description='For aggregate: Total value across all groups.')
        public Decimal totalValue;
        
        @InvocableVariable(label='Group Count' description='For aggregate: Number of groups in results.')
        public Integer groupCount;
        
        @InvocableVariable(label='Query Description' description='For aggregate: Human-readable query description.')
        public String queryDescription;
    }
    
    private static String inferOperation(Request req) {
        if (!String.isBlank(req.operation)) {
            return req.operation.trim().toLowerCase();
        }
        
        Boolean hasRecordId = req.recordId != null;
        Boolean hasFieldData = !String.isBlank(req.fieldDataJson);
        Boolean hasSearchTerm = !String.isBlank(req.searchTerm);
        Boolean hasFilters = !String.isBlank(req.filtersJson);
        Boolean hasAggregateParams = !String.isBlank(req.aggregateFunction);
        
        if (hasAggregateParams) return 'aggregate';
        if (hasRecordId && hasFieldData) return 'update';
        else if (hasRecordId && !hasFieldData && !hasSearchTerm && !hasFilters) return 'read';
        else if (hasFieldData && !hasRecordId) return 'create';
        else if (hasSearchTerm || hasFilters) return 'find';
        else if (hasRecordId && req.confirm != null && req.confirm == true) return 'delete';
        
        throw new AFUniversalCrmRecordAction.ActionException('Cannot infer operation. Please specify operation parameter or provide sufficient context.');
    }
    
    @InvocableMethod(
        label='Agentforce Meeting Action'
        description='Performs CRUD operations on Meeting__c records. DEMO MODE: This is a demo environment - prioritize creating records quickly over asking many questions. Make reasonable assumptions and proceed. ROUTING CLAIM: If user says I had a meeting, log a meeting, record a meeting, or any variation mentioning meeting explicitly, this is ALWAYS a meeting logging request regardless of sentiment or topic. Even tough meetings, bad meetings, or meetings with concerns should be logged here - do NOT redirect to Account Intelligence. DATE HANDLING (CRITICAL): If no date mentioned, DEFAULT TO TODAY. Infer dates: today/this morning/this afternoon/just now -> today, yesterday -> yesterday. NEVER ask for meeting date - just use today if unclear. CONVERSATIONAL FLOW: (1) GATHER - Get who and basic context. Date defaults to today. (2) INFER - Extract Meeting_Type__c, Meeting_Outcome__c from context clues. (3) CREATE - Proceed with inferred values. Only ask follow-ups if truly critical info missing (like who they met with). (4) POST-CREATE TASK OFFER - If next steps mentioned, offer task creation. DATA GOAL: Create useful records quickly. MINIMUM: Contact/Account (or capture name in description if lookup fails), Subject, Meeting Type (infer or default to In-Person Visit), Outcome (infer or default to Neutral). GRACEFUL LOOKUP: When contact or account lookup fails, create the meeting anyway with available info. Capture the name in the description. Do NOT block the user. NEGATIVE MEETING HANDLING: Tough/difficult/challenging meetings should STILL be logged here with Outcome as Needs Follow-up or Unsuccessful. OPERATIONS: CREATE needs fieldDataJson, READ needs recordId, UPDATE needs recordId plus fieldDataJson, DELETE needs recordId plus confirm true, FIND needs searchTerm or filtersJson. PICKLIST SAFETY: Query availableFieldsJson for valid values. Supports accountName and contactNameOrEmail for lookup resolution - system uses fuzzy matching so Accusage Inc will match Accusage, Inc.'
        category='CRM Actions'
    )
    public static List<Response> meetingAction(List<Request> requests) {
        List<Response> responses = new List<Response>();
        
        for (Request req : requests) {
            Response res = new Response();
            res.objectType = 'Meeting__c';
            res.success = false;
            res.records = new List<Meeting__c>();
            res.totalMatches = 0;
            res.ambiguous = false;
            res.moreResultsAvailable = false;
            res.confirmationRequired = false;
            
            try {
                String op = inferOperation(req);
                res.operation = op;
                
                if (op == 'delete' && (req.confirm == null || req.confirm == false)) {
                    res.confirmationRequired = true;
                    res.recordId = req.recordId;
                    
                    if (req.recordId == null) {
                        res.success = false;
                        res.errorMessage = 'Record ID is required for delete operation.';
                        responses.add(res);
                        continue;
                    }
                    
                    try {
                        List<Meeting__c> meetings = [SELECT Id, Subject__c FROM Meeting__c WHERE Id = :req.recordId LIMIT 1];
                        if (!meetings.isEmpty()) {
                            res.message = 'This will delete Meeting \'' + meetings[0].Subject__c + '\' and all related records. Call again with confirm=true to proceed.';
                            res.success = true;
                        } else {
                            res.message = 'Meeting not found with ID ' + req.recordId + '.';
                            res.errorMessage = res.message;
                            res.success = false;
                        }
                    } catch (Exception e) {
                        res.message = 'This will delete the Meeting. Call again with confirm=true to proceed.';
                        res.success = true;
                    }
                    responses.add(res);
                    continue;
                }
                
                AFUniversalCrmRecordAction.Request actionReq = new AFUniversalCrmRecordAction.Request();
                actionReq.objectApiName = 'Meeting__c';
                actionReq.operation = op;
                actionReq.recordId = req.recordId;
                actionReq.fieldDataJson = req.fieldDataJson;
                actionReq.accountName = req.accountName;
                actionReq.contactNameOrEmail = req.contactNameOrEmail;
                actionReq.confirm = req.confirm;
                actionReq.searchTerm = req.searchTerm;
                actionReq.filtersJson = req.filtersJson;
                actionReq.searchLimit = req.searchLimit;
                
                // NOTE: Aggregate operations for meetings should be handled separately
                // by delegating to AFUniversalAnalyticsAction (similar to AFOpportunityAction)
                // For now, aggregate params are defined in Request but not passed to CRM action
                
                if ((op == 'create' || op == 'update') && !String.isBlank(req.fieldDataJson)) {
                    try {
                        Object parsed = JSON.deserializeUntyped(req.fieldDataJson);
                        Boolean isBulk = parsed instanceof List<Object>;
                        if (isBulk) {
                            actionReq.operation = op == 'create' ? 'bulkCreate' : 'bulkUpdate';
                            actionReq.bulkRecordsJson = req.fieldDataJson;
                            actionReq.fieldDataJson = null;
                        }
                    } catch (Exception e) {
                        System.debug(LoggingLevel.DEBUG, 'AFMeetingAction: fieldDataJson is not a bulk array, treating as single record');
                    }
                }
                
                AFUniversalCrmRecordAction.Response actionRes = AFUniversalCrmRecordAction.processRequest(actionReq);
                
                if (actionRes.success) {
                    res.success = true;
                    res.message = actionRes.message != null ? actionRes.message : 'Operation completed successfully.';
                    res.previewOnly = actionRes.previewOnly != null ? actionRes.previewOnly : false;
                    res.enrichmentSuggested = actionRes.enrichmentSuggested != null ? actionRes.enrichmentSuggested : false;
                    res.suggestedFields = actionRes.suggestedFields;
                    res.previewData = actionRes.previewData;
                    res.availableFieldsJson = actionRes.availableFieldsJson;
                    res.ambiguousRelationship = actionRes.ambiguousRelationship != null ? actionRes.ambiguousRelationship : false;
                    res.ambiguousRelationshipType = actionRes.ambiguousRelationshipType;
                    res.relationshipCandidatesJson = actionRes.relationshipCandidatesJson;
                    res.ambiguous = actionRes.ambiguous != null ? actionRes.ambiguous : false;
                    res.totalMatches = actionRes.totalMatches != null ? actionRes.totalMatches : 0;
                    
                    // NOTE: Aggregate response fields would be populated here if aggregate operations
                    // were delegated to AFUniversalAnalyticsAction. For now, they remain null.
                    
                    if (actionRes.record != null) {
                        res.record = (Meeting__c) actionRes.record;
                        res.recordId = res.record.Id;
                        res.records = new List<Meeting__c>{ res.record };
                    } else if (actionRes.records != null && !actionRes.records.isEmpty()) {
                        res.records = new List<Meeting__c>();
                        for (SObject so : actionRes.records) {
                            res.records.add((Meeting__c) so);
                        }
                        if (res.records.size() == 1) {
                            res.record = res.records[0];
                            res.recordId = res.records[0].Id;
                        } else if (!res.records.isEmpty()) {
                            res.ambiguous = true;
                        }
                    } else if (actionRes.recordId != null) {
                        res.recordId = actionRes.recordId;
                    }
                    
                    if (op == 'find' || op == 'search') {
                        Integer searchLimit = req.searchLimit != null ? req.searchLimit : 5;
                        if (res.totalMatches >= searchLimit) {
                            res.moreResultsAvailable = true;
                        }
                    }
                } else {
                    res.success = false;
                    res.errorMessage = actionRes.message != null ? actionRes.message : 'Operation failed.';
                }
                
            } catch (AFUniversalCrmRecordAction.ActionException ae) {
                res.success = false;
                res.errorMessage = ae.getMessage();
                System.debug(LoggingLevel.ERROR, 'AFMeetingAction: ActionException - ' + ae.getMessage());
            } catch (Exception e) {
                res.success = false;
                res.errorMessage = 'Error performing Meeting operation: ' + e.getMessage();
                System.debug(LoggingLevel.ERROR, 'AFMeetingAction: Exception - ' + e.getMessage());
            }
            
            responses.add(res);
        }
        
        return responses;
    }
}

