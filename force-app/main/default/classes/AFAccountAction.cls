/**
 * AF Account Action
 * Consolidated invocable action for all Account CRUD operations (Create, Read, Update, Delete, Find)
 * Designed for Agentforce AI agents
 */
public with sharing class AFAccountAction {
    
    /**
     * Request input for Account operations
     * Supports all CRUD operations: create, read, update, delete, find
     */
    public class Request {
        @InvocableVariable(
            label='Operation'
            description='Explicit operation to perform: "create", "read", "update", "delete", or "find". If not specified, operation will be inferred from context: has fieldDataJson + recordId = update, has fieldDataJson only = create, has recordId only = read, has searchTerm/filtersJson = find, has recordId only (no data/search) = delete.'
            required=false
        )
        public String operation;
        
        @InvocableVariable(
            label='Field Data JSON'
            description='JSON string containing Account field data. For create: {"Name":"Acme Corp","Industry":"Technology"}. For update: {"Industry":"Technology","BillingCity":"San Francisco"}. For bulk operations: [{"Name":"Acme"},{"Name":"Globex"}]. Required for create/update operations.'
            required=false
        )
        public String fieldDataJson;
        
        @InvocableVariable(
            label='Record ID'
            description='The Salesforce record ID (15 or 18 character) of the Account. Required for read/update/delete operations. Format: 18-character ID like "001xx000003DGbYAAW". For update, can be omitted if Name is provided in fieldDataJson for automatic resolution.'
            required=false
        )
        public Id recordId;
        
        @InvocableVariable(
            label='Search Term'
            description='Text to search for in Account fields (Name, BillingCity, BillingState, etc.). Used for find operations. Example: "Acme" or "San Francisco".'
            required=false
        )
        public String searchTerm;
        
        @InvocableVariable(
            label='Filters JSON'
            description='JSON string of exact-match filters for find operations. Can be single object {"fieldApiName":"Industry","value":"Technology"} or array [{"fieldApiName":"Industry","value":"Technology"}].'
            required=false
        )
        public String filtersJson;
        
        @InvocableVariable(
            label='Search Limit'
            description='Maximum number of records to return for find operations (default: 5, max: 20).'
            required=false
        )
        public Integer searchLimit;
        
        @InvocableVariable(
            label='Account Name'
            description='Account name to resolve to AccountId for related records (not typically used for Account operations, but available for consistency)'
            required=false
        )
        public String accountName;
        
        @InvocableVariable(
            label='Confirm'
            description='For create/update: Set to false to preview only without committing. Default (true): Commits immediately. For delete: Set to true to actually delete. Default (false): Returns confirmation message first. The agent should first call delete with confirm=false, ask the user, then call again with confirm=true if confirmed.'
            required=false
        )
        public Boolean confirm;
    }
    
    /**
     * Response output for Account operations
     * Comprehensive response that handles all operation types
     */
    public class Response {
        @InvocableVariable(
            label='Success'
            description='True if operation completed successfully, false if an error occurred. Check this before using other output variables.'
        )
        public Boolean success;
        
        @InvocableVariable(
            label='Record'
            description='The Account record (for single record operations: create, read, update). Use the record.Id field from this record for follow-up operations. This is null for bulk operations or when multiple records are found.'
        )
        public Account record;
        
        @InvocableVariable(
            label='Records'
            description='List of Account records (for bulk operations or find operations with multiple results). Use record.Id from each record for subsequent operations.'
        )
        public List<Account> records;
        
        @InvocableVariable(
            label='Record ID'
            description='The Salesforce ID of the record (18-character format like "001xx000003DGbYAAW"). Use this ID for subsequent operations. This is the primary identifier for follow-up operations in the conversation.'
        )
        public Id recordId;
        
        @InvocableVariable(
            label='Message'
            description='Human-readable message describing the operation result. Use this exact message to inform the user. Examples: "Account created successfully", "Found 3 matching Account records", "Account deleted successfully".'
        )
        public String message;
        
        @InvocableVariable(
            label='Error Message'
            description='If success is false, this contains a user-friendly error message to relay directly to the user. Example: "To create an Account, the Name field is required."'
        )
        public String errorMessage;
        
        @InvocableVariable(
            label='Object Type'
            description='The Salesforce object type, always "Account" for Account operations. Useful for agent context and logging.'
        )
        public String objectType;
        
        @InvocableVariable(
            label='Operation'
            description='The operation that was performed: "create", "read", "update", "delete", or "find". Useful for agent context and logging.'
        )
        public String operation;
        
        @InvocableVariable(
            label='Preview Only'
            description='True if this is a preview response (confirm=false for create/update). The record has not been committed yet. The agent should present the preview to the user, then call again with confirm=true to commit.'
        )
        public Boolean previewOnly;
        
        @InvocableVariable(
            label='Enrichment Suggested'
            description='True if the provided data is minimal and additional fields are suggested (for create operations). When true, check suggestedFields for commonly-used fields that could be populated.'
        )
        public Boolean enrichmentSuggested;
        
        @InvocableVariable(
            label='Suggested Fields'
            description='List of commonly-used field API names that could be populated to enrich this Account. Examples: Industry, BillingCity, Phone, Website. The agent should ask the user about these fields and add them to fieldDataJson before calling again with confirm=true.'
        )
        public List<String> suggestedFields;
        
        @InvocableVariable(
            label='Preview Data'
            description='A JSON string representation of what would be created/updated. Use this to show the user a preview before committing. Format: {"Name":"Test 1","Industry":null,"BillingCity":null,...}'
        )
        public String previewData;
        
        @InvocableVariable(
            label='Available Fields JSON'
            description='JSON string containing metadata for all available fields that can be set on Account records. Includes API name, label, type, required status, picklist values, help text, and more. Use this to understand what fields are available and their constraints.'
        )
        public String availableFieldsJson;
        
        @InvocableVariable(
            label='Ambiguous Relationship'
            description='True if a parent Account lookup found multiple matches (2+). When true, DO NOT tell the user the Account was created/updated. Instead, you MUST present the candidates from relationshipCandidatesJson to the user and ask which parent Account they meant.'
        )
        public Boolean ambiguousRelationship;
        
        @InvocableVariable(
            label='Ambiguous Relationship Type'
            description='The type of relationship that has multiple matches, typically "Account" for parent Account lookups. Use this to know what kind of candidates are provided in relationshipCandidatesJson.'
        )
        public String ambiguousRelationshipType;
        
        @InvocableVariable(
            label='Relationship Candidates JSON'
            description='JSON array of candidate Account records when ambiguousRelationship is true. Each candidate includes disambiguating details: Name, BillingCity, BillingState, Phone, Industry. Present these options to the user in a clear, numbered list with the distinguishing details, then ask them to clarify which one they meant.'
        )
        public String relationshipCandidatesJson;
        
        @InvocableVariable(
            label='Ambiguous Result'
            description='True if multiple records were found in a find/search operation. When true, present all records to the user and ask for clarification using additional identifying fields like Industry, BillingCity, BillingState, or Phone to narrow down the selection.'
        )
        public Boolean ambiguous;
        
        @InvocableVariable(
            label='Total Matches'
            description='Number of Account records found in a find/search operation. Use this to inform the user: "Found X matching accounts" or "No accounts found matching your criteria".'
        )
        public Integer totalMatches;
        
        @InvocableVariable(
            label='More Results Available'
            description='True if the search returned the maximum number of results (searchLimit) but there are more matching records available. When true, suggest the user provide more specific search criteria or increase the searchLimit.'
        )
        public Boolean moreResultsAvailable;
        
        @InvocableVariable(
            label='Confirmation Required'
            description='True if this is a confirmation request for delete operation (confirm=false). The agent should present the message to the user and call again with confirm=true if the user confirms the deletion.'
        )
        public Boolean confirmationRequired;
    }
    
    /**
     * Infer operation from request context if not explicitly provided
     */
    private static String inferOperation(Request req) {
        // If explicitly provided, use it
        if (!String.isBlank(req.operation)) {
            return req.operation.trim().toLowerCase();
        }
        
        // Infer from context
        Boolean hasRecordId = req.recordId != null;
        Boolean hasFieldData = !String.isBlank(req.fieldDataJson);
        Boolean hasSearchTerm = !String.isBlank(req.searchTerm);
        Boolean hasFilters = !String.isBlank(req.filtersJson);
        
        if (hasRecordId && hasFieldData) {
            return 'update';  // Has ID + data = update
        } else if (hasRecordId && !hasFieldData && !hasSearchTerm && !hasFilters) {
            // Check if this is a delete (confirm might be set) or read
            // For now, default to read if no other indicators
            // Delete will typically have confirm parameter set
            return 'read';    // Has ID only = read (delete requires explicit operation or confirm=true)
        } else if (hasFieldData && !hasRecordId) {
            return 'create';  // Has data, no ID = create
        } else if (hasSearchTerm || hasFilters) {
            return 'find';    // Has search criteria = find
        } else if (hasRecordId && req.confirm != null && req.confirm == true) {
            return 'delete';  // Has ID + confirm=true = delete
        }
        
        throw new AFUniversalCrmRecordAction.ActionException('Cannot infer operation. Please specify operation parameter (create, read, update, delete, find) or provide sufficient context (fieldDataJson for create, recordId for read, recordId+fieldDataJson for update, searchTerm/filtersJson for find, recordId+confirm=true for delete).');
    }
    
    /**
     * Account Action - Performs all CRUD operations on Account records
     * Operation can be explicitly specified or inferred from context
     */
    @InvocableMethod(
        label='Account Action'
        description='Performs CRUD operations on Account records. Operation can be explicitly specified (create, read, update, delete, find) or inferred from context. CREATE: Provide fieldDataJson. READ: Provide recordId. UPDATE: Provide recordId + fieldDataJson. DELETE: Provide recordId + confirm=true (first call with confirm=false for confirmation). FIND: Provide searchTerm and/or filtersJson. The agent should intelligently infer the operation from user intent, but can explicitly specify if needed. Supports bulk operations for create/update by providing JSON array in fieldDataJson.'
        category='CRM Actions'
    )
    public static List<Response> accountAction(List<Request> requests) {
        List<Response> responses = new List<Response>();
        
        for (Request req : requests) {
            Response res = new Response();
            res.objectType = 'Account';
            res.success = false;
            res.records = new List<Account>();
            res.totalMatches = 0;
            res.ambiguous = false;
            res.moreResultsAvailable = false;
            res.confirmationRequired = false;
            
            try {
                // Infer or use explicit operation
                String op = inferOperation(req);
                res.operation = op;
                
                // Handle delete confirmation separately (before calling AFUniversalCrmRecordAction)
                if (op == 'delete' && (req.confirm == null || req.confirm == false)) {
                    // Return confirmation message with impact info
                    res.confirmationRequired = true;
                    res.recordId = req.recordId;
                    
                    if (req.recordId == null) {
                        res.success = false;
                        res.errorMessage = 'Record ID is required for delete operation. Provide the 18-character Salesforce Account ID.';
                        responses.add(res);
                        continue;
                    }
                    
                    // Get account info for confirmation message
                    try {
                        List<Account> accounts = [SELECT Id, Name, (SELECT Id FROM Contacts), (SELECT Id FROM Cases WHERE Status != 'Closed') 
                                                  FROM Account WHERE Id = :req.recordId LIMIT 1];
                        if (!accounts.isEmpty()) {
                            Account acc = accounts[0];
                            Integer contactCount = acc.Contacts != null ? acc.Contacts.size() : 0;
                            Integer openCaseCount = acc.Cases != null ? acc.Cases.size() : 0;
                            
                            String impactInfo = '';
                            if (contactCount > 0 || openCaseCount > 0) {
                                List<String> impacts = new List<String>();
                                if (contactCount > 0) impacts.add(contactCount + ' Contact' + (contactCount > 1 ? 's' : ''));
                                if (openCaseCount > 0) impacts.add(openCaseCount + ' open Case' + (openCaseCount > 1 ? 's' : ''));
                                impactInfo = ' This Account has ' + String.join(impacts, ' and ') + '.';
                            }
                            
                            res.message = 'This will delete Account \'' + acc.Name + '\' and all related records.' + impactInfo + ' Call again with confirm=true to proceed.';
                            res.success = true; // Confirmation request is successful
                        } else {
                            res.message = 'Account not found with ID ' + req.recordId + '.';
                            res.errorMessage = res.message;
                            res.success = false;
                        }
                    } catch (Exception e) {
                        res.message = 'This will delete the Account. Call again with confirm=true to proceed.';
                        res.success = true;
                    }
                    responses.add(res);
                    continue;
                }
                
                // Build request for AFUniversalCrmRecordAction
                AFUniversalCrmRecordAction.Request actionReq = new AFUniversalCrmRecordAction.Request();
                actionReq.objectApiName = 'Account';
                actionReq.operation = op;
                actionReq.recordId = req.recordId;
                actionReq.fieldDataJson = req.fieldDataJson;
                actionReq.accountName = req.accountName;
                actionReq.confirm = req.confirm;
                actionReq.searchTerm = req.searchTerm;
                actionReq.filtersJson = req.filtersJson;
                actionReq.searchLimit = req.searchLimit;
                
                // Handle bulk operations for create/update
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
                        // Not valid JSON or not an array, treat as single record
                        System.debug(LoggingLevel.DEBUG, 'AFAccountAction: fieldDataJson is not a bulk array, treating as single record');
                    }
                }
                
                // Call shared business logic
                AFUniversalCrmRecordAction.Response actionRes = AFUniversalCrmRecordAction.processRequest(actionReq);
                
                // Convert response
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
                    
                    // Handle record(s)
                    if (actionRes.record != null) {
                        res.record = (Account) actionRes.record;
                        res.recordId = res.record.Id;
                        res.records = new List<Account>{ res.record };
                    } else if (actionRes.records != null && !actionRes.records.isEmpty()) {
                        res.records = new List<Account>();
                        for (SObject so : actionRes.records) {
                            res.records.add((Account) so);
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
                    
                    // Check if more results available (for find operations)
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
                System.debug(LoggingLevel.ERROR, 'AFAccountAction: ActionException - ' + ae.getMessage());
            } catch (Exception e) {
                res.success = false;
                res.errorMessage = 'Error performing Account operation: ' + e.getMessage();
                System.debug(LoggingLevel.ERROR, 'AFAccountAction: Exception - ' + e.getMessage());
            }
            
            responses.add(res);
        }
        
        return responses;
    }
}

