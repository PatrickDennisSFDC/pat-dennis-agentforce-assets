/**
 * AF Task Action
 * Consolidated invocable action for all Task CRUD operations (Create, Read, Update, Delete, Find)
 * Designed for Agentforce AI agents
 */
public with sharing class AFTaskAction {
    
    public class Request {
        @InvocableVariable(
            label='Operation'
            description='Explicit operation: "create", "read", "update", "delete", or "find". If not specified, inferred from context.'
        )
        public String operation;
        
        @InvocableVariable(
            label='Field Data JSON'
            description='JSON string containing Task field data. For create: {"Subject":"Follow up with John","Priority":"High","ActivityDate":"2024-12-10"}. For update: {"Status":"Completed"}. For bulk: [{"Subject":"Task 1"},{"Subject":"Task 2"}].'
        )
        public String fieldDataJson;
        
        @InvocableVariable(
            label='Record ID'
            description='The Salesforce record ID of the Task. Required for read/update/delete. Format: 18-character ID like "00Txx000003DGbYAAW".'
        )
        public Id recordId;
        
        @InvocableVariable(
            label='Search Term'
            description='Text to search for in Task fields (Subject, Description, etc.). Used for find operations.'
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
            description='Account name to resolve to WhatId for the Task. Links task to Account via WhatId.'
        )
        public String accountName;
        
        @InvocableVariable(
            label='Contact Name or Email'
            description='Contact name or email to resolve to WhoId for the Task. Links task to Contact via WhoId.'
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
            description='The Task record (for single record operations).'
        )
        public Task record;
        
        @InvocableVariable(
            label='Records'
            description='List of Task records (for bulk or find operations).'
        )
        public List<Task> records;
        
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
            description='The Salesforce object type, always "Task" for Task operations.'
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
            description='Number of Task records found in a find/search operation.'
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
        label='Task Action'
        description='Performs CRUD operations on Task records. Operation can be explicitly specified (create, read, update, delete, find) or inferred from context. CREATE: Provide fieldDataJson. READ: Provide recordId. UPDATE: Provide recordId + fieldDataJson. DELETE: Provide recordId + confirm=true. FIND: Provide searchTerm and/or filtersJson. Supports accountName (WhatId) and contactNameOrEmail (WhoId) parameters to link Task to Account/Contact. Supports bulk operations.'
        category='CRM Actions'
    )
    public static List<Response> taskAction(List<Request> requests) {
        List<Response> responses = new List<Response>();
        
        for (Request req : requests) {
            Response res = new Response();
            res.objectType = 'Task';
            res.success = false;
            res.records = new List<Task>();
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
                        List<Task> tasks = [SELECT Id, Subject FROM Task WHERE Id = :req.recordId LIMIT 1];
                        if (!tasks.isEmpty()) {
                            res.message = 'This will delete Task \'' + tasks[0].Subject + '\' and all related records. Call again with confirm=true to proceed.';
                            res.success = true;
                        } else {
                            res.message = 'Task not found with ID ' + req.recordId + '.';
                            res.errorMessage = res.message;
                            res.success = false;
                        }
                    } catch (Exception e) {
                        res.message = 'This will delete the Task. Call again with confirm=true to proceed.';
                        res.success = true;
                    }
                    responses.add(res);
                    continue;
                }
                
                AFUniversalCrmRecordAction.Request actionReq = new AFUniversalCrmRecordAction.Request();
                actionReq.objectApiName = 'Task';
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
                        System.debug(LoggingLevel.DEBUG, 'AFTaskAction: fieldDataJson is not a bulk array, treating as single record');
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
                        res.record = (Task) actionRes.record;
                        res.recordId = res.record.Id;
                        res.records = new List<Task>{ res.record };
                    } else if (actionRes.records != null && !actionRes.records.isEmpty()) {
                        res.records = new List<Task>();
                        for (SObject so : actionRes.records) {
                            res.records.add((Task) so);
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
                System.debug(LoggingLevel.ERROR, 'AFTaskAction: ActionException - ' + ae.getMessage());
            } catch (Exception e) {
                res.success = false;
                res.errorMessage = 'Error performing Task operation: ' + e.getMessage();
                System.debug(LoggingLevel.ERROR, 'AFTaskAction: Exception - ' + e.getMessage());
            }
            
            responses.add(res);
        }
        
        return responses;
    }
}

