/**
 * AF Meeting Action
 * Consolidated invocable action for all Meeting__c CRUD operations (Create, Read, Update, Delete, Find)
 * Designed for Agentforce AI agents
 */
public with sharing class AFMeetingAction {
    
    public class Request {
        @InvocableVariable(
            label='Operation'
            description='Explicit operation: "create", "read", "update", "delete", or "find". If not specified, inferred from context.'
        )
        public String operation;
        
        @InvocableVariable(
            label='Field Data JSON'
            description='JSON string containing Meeting field data. Required fields: Meeting_Date__c, Subject__c. INTELLIGENT FIELD MAPPING: Use your semantic understanding to map natural language to structured fields. When user describes a meeting conversationally (e.g., "had lunch with Dr. Smith, discussed Product X, went well, need to follow up"), extract and infer the appropriate values: Parse meeting type from context (lunch→In-Person Visit, zoom→Virtual Meeting, etc.), infer outcome from sentiment (optimistic/good→Productive, excellent→Very Productive), detect follow-up needs from language (mentions of "next steps" or "follow up"→Follow_Up_Required__c:true), extract product names, sample/material info, and other structured data from description. Query availableFieldsJson to see valid picklist options, then use your best judgment to map. If unclear, leave field blank. Example: {"Subject__c":"Lunch with Dr. Smith","Meeting_Date__c":"2024-12-10","Meeting_Type__c":"In-Person Visit","Meeting_Outcome__c":"Productive","Follow_Up_Required__c":true,"Description__c":"Discussed Product X proposal"}. Use accountName or contactNameOrEmail to resolve lookups by name.'
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
            description='Text to search for in Meeting fields (Subject__c, Description__c, etc.). Used for find operations.'
        )
        public String searchTerm;
        
        @InvocableVariable(
            label='Filters JSON'
            description='JSON string of exact-match filters for find operations.'
        )
        public String filtersJson;
        
        @InvocableVariable(
            label='Search Limit'
            description='Maximum number of records to return for find operations (default: 5, max: 20).'
        )
        public Integer searchLimit;
        
        @InvocableVariable(
            label='Account Name'
            description='Account name to resolve to Account__c lookup. If provided, system searches for an Account and links the Meeting to it.'
        )
        public String accountName;
        
        @InvocableVariable(
            label='Contact Name or Email'
            description='Contact name or email to resolve to Contact__c lookup. If provided, system searches for a Contact and links the Meeting to them.'
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
    }
    
    private static String inferOperation(Request req) {
        if (!String.isBlank(req.operation)) {
            return req.operation.trim().toLowerCase();
        }
        
        Boolean hasRecordId = req.recordId != null;
        Boolean hasFieldData = !String.isBlank(req.fieldDataJson);
        Boolean hasSearchTerm = !String.isBlank(req.searchTerm);
        Boolean hasFilters = !String.isBlank(req.filtersJson);
        
        if (hasRecordId && hasFieldData) return 'update';
        else if (hasRecordId && !hasFieldData && !hasSearchTerm && !hasFilters) return 'read';
        else if (hasFieldData && !hasRecordId) return 'create';
        else if (hasSearchTerm || hasFilters) return 'find';
        else if (hasRecordId && req.confirm != null && req.confirm == true) return 'delete';
        
        throw new AFUniversalCrmRecordAction.ActionException('Cannot infer operation. Please specify operation parameter or provide sufficient context.');
    }
    
    @InvocableMethod(
        label='Meeting Action'
        description='Performs CRUD operations on Meeting__c records. Operation can be explicitly specified (create, read, update, delete, find) or inferred from context. CREATE: Provide fieldDataJson. READ: Provide recordId. UPDATE: Provide recordId + fieldDataJson. DELETE: Provide recordId + confirm=true. FIND: Provide searchTerm and/or filtersJson. AGENT INTELLIGENCE: Use your semantic understanding to map natural language to structured fields. For picklist fields like Meeting_Type__c, Meeting_Status__c, Meeting_Outcome__c, analyze the context (e.g., "lunch", "office visit", "zoom call" for type; "went well", "productive" for outcome; "completed", "scheduled" for status) and select the most appropriate value from available options. Query availableFieldsJson to see valid picklist values. If input does not clearly map, leave the field blank. For boolean fields like Samples_Dropped_Off__c, Marketing_Materials_Provided__c, Follow_Up_Required__c, Signature_Obtained__c, infer true/false from user intent (e.g., "dropped samples" -> true, "no follow up" -> false). For date fields like Meeting_Date__c, infer from temporal cues (e.g., "today", "tomorrow", "last week"). Supports accountName and contactNameOrEmail parameters to link Meeting to Account/Contact. Supports bulk operations.'
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

