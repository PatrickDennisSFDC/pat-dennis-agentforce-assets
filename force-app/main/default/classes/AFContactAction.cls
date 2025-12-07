/**
 * AF Contact Action
 * Consolidated invocable action for all Contact CRUD operations (Create, Read, Update, Delete, Find)
 * Designed for Agentforce AI agents
 */
public with sharing class AFContactAction {
    
    /**
     * Request input for Contact operations
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
            description='JSON string containing Contact field data. For create: {"LastName":"Smith","Email":"john@example.com"}. For update: {"Email":"newemail@example.com","Phone":"555-1234"}. For bulk operations: [{"LastName":"Smith"},{"LastName":"Jones"}]. Required for create/update operations.'
            required=false
        )
        public String fieldDataJson;
        
        @InvocableVariable(
            label='Record ID'
            description='The Salesforce record ID (15 or 18 character) of the Contact. Required for read/update/delete operations. Format: 18-character ID like "003xx000003DGbYAAW". For update, can be omitted if LastName+Email is provided in fieldDataJson for automatic resolution.'
            required=false
        )
        public Id recordId;
        
        @InvocableVariable(
            label='Search Term'
            description='Text to search for in Contact fields (Name, Email, Phone, etc.). Used for find operations. Example: "John Smith" or "john@example.com". IMPORTANT: If the user wants to find a contact but hasn\'t provided a search term, ask them for the contact name, email, or other identifying information BEFORE calling this action. Do not call find operation without a searchTerm or filtersJson.'
            required=false
        )
        public String searchTerm;
        
        @InvocableVariable(
            label='Filters JSON'
            description='JSON string of exact-match filters for find operations. Can be single object {"fieldApiName":"Email","value":"john@example.com"} or array [{"fieldApiName":"Email","value":"john@example.com"}]. IMPORTANT: If the user wants to find a contact but hasn\'t provided specific filters, ask them for details like email, account name, or phone number BEFORE calling this action. Do not call find operation without a searchTerm or filtersJson.'
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
            description='Account name to resolve to AccountId for the Contact. If provided, the system will search for an Account with this name and link the Contact to it. Example: "Acme Corp".'
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
     * Response output for Contact operations
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
            description='The Contact record (for single record operations: create, read, update). Use the record.Id field from this record for follow-up operations. This is null for bulk operations or when multiple records are found.'
        )
        public Contact record;
        
        @InvocableVariable(
            label='Records'
            description='List of Contact records (for bulk operations or find operations with multiple results). Use record.Id from each record for subsequent operations.'
        )
        public List<Contact> records;
        
        @InvocableVariable(
            label='Record ID'
            description='The Salesforce ID of the record (18-character format like "003xx000003DGbYAAW"). Use this ID for subsequent operations. This is the primary identifier for follow-up operations in the conversation.'
        )
        public Id recordId;
        
        @InvocableVariable(
            label='Message'
            description='Human-readable message describing the operation result. Use this exact message to inform the user.'
        )
        public String message;
        
        @InvocableVariable(
            label='Error Message'
            description='If success is false, this contains a user-friendly error message to relay directly to the user.'
        )
        public String errorMessage;
        
        @InvocableVariable(
            label='Object Type'
            description='The Salesforce object type, always "Contact" for Contact operations. Useful for agent context and logging.'
        )
        public String objectType;
        
        @InvocableVariable(
            label='Operation'
            description='The operation that was performed: "create", "read", "update", "delete", or "find". Useful for agent context and logging.'
        )
        public String operation;
        
        @InvocableVariable(
            label='Preview Only'
            description='True if this is a preview response (confirm=false for create/update). The record has not been committed yet.'
        )
        public Boolean previewOnly;
        
        @InvocableVariable(
            label='Enrichment Suggested'
            description='True if the provided data is minimal and additional fields are suggested (for create operations). When true, check suggestedFields for commonly-used fields that could be populated.'
        )
        public Boolean enrichmentSuggested;
        
        @InvocableVariable(
            label='Suggested Fields'
            description='List of commonly-used field API names that could be populated to enrich this Contact. Examples: FirstName, Email, Phone, MailingCity.'
        )
        public List<String> suggestedFields;
        
        @InvocableVariable(
            label='Preview Data'
            description='A JSON string representation of what would be created/updated. Use this to show the user a preview before committing.'
        )
        public String previewData;
        
        @InvocableVariable(
            label='Available Fields JSON'
            description='JSON string containing metadata for all available fields that can be set on Contact records. Includes API name, label, type, required status, picklist values, help text, and more.'
        )
        public String availableFieldsJson;
        
        @InvocableVariable(
            label='Ambiguous Relationship'
            description='True if a parent Account lookup found multiple matches (2+). When true, DO NOT tell the user the Contact was created/updated. Instead, you MUST present the candidates from relationshipCandidatesJson to the user and ask which Account they meant.'
        )
        public Boolean ambiguousRelationship;
        
        @InvocableVariable(
            label='Ambiguous Relationship Type'
            description='The type of relationship that has multiple matches, typically "Account" for parent Account lookups. Use this to know what kind of candidates are provided in relationshipCandidatesJson.'
        )
        public String ambiguousRelationshipType;
        
        @InvocableVariable(
            label='Relationship Candidates JSON'
            description='JSON array of candidate Account records when ambiguousRelationship is true. Each candidate includes disambiguating details. Present these options to the user in a clear, numbered list, then ask them to clarify which one they meant.'
        )
        public String relationshipCandidatesJson;
        
        @InvocableVariable(
            label='Ambiguous Result'
            description='True if multiple records were found in a find/search operation. When true, present all records to the user and ask for clarification using additional identifying fields.'
        )
        public Boolean ambiguous;
        
        @InvocableVariable(
            label='Total Matches'
            description='Number of Contact records found in a find/search operation. Use this to inform the user: "Found X matching contacts" or "No contacts found matching your criteria".'
        )
        public Integer totalMatches;
        
        @InvocableVariable(
            label='More Results Available'
            description='True if the search returned the maximum number of results (searchLimit) but there are more matching records available.'
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
        if (!String.isBlank(req.operation)) {
            return req.operation.trim().toLowerCase();
        }
        
        Boolean hasRecordId = req.recordId != null;
        Boolean hasFieldData = !String.isBlank(req.fieldDataJson);
        Boolean hasSearchTerm = !String.isBlank(req.searchTerm);
        Boolean hasFilters = !String.isBlank(req.filtersJson);
        
        if (hasRecordId && hasFieldData) {
            return 'update';
        } else if (hasRecordId && !hasFieldData && !hasSearchTerm && !hasFilters) {
            return 'read';
        } else if (hasFieldData && !hasRecordId) {
            return 'create';
        } else if (hasSearchTerm || hasFilters) {
            return 'find';
        } else if (hasRecordId && req.confirm != null && req.confirm == true) {
            return 'delete';
        }
        
        throw new AFUniversalCrmRecordAction.ActionException('Cannot infer operation. Please specify operation parameter (create, read, update, delete, find) or provide sufficient context.');
    }
    
    /**
     * Contact Action - Performs all CRUD operations on Contact records
     */
    @InvocableMethod(
        label='Agentforce Contact Action'
        description='Performs CRUD operations on Contact records. Operation can be explicitly specified (create, read, update, delete, find) or inferred from context. CREATE: Provide fieldDataJson. READ: Provide recordId. UPDATE: Provide recordId + fieldDataJson. DELETE: Provide recordId + confirm=true (first call with confirm=false for confirmation). FIND: IMPORTANT - Before calling find operation, ensure you have search criteria. If the user asks to "find" or "look up" a contact without providing specific details (contact name, email, account name, phone, etc.), you MUST ask the user for these details FIRST before calling this action. Only call this action with find operation when you have at least a searchTerm (contact name or email) or filtersJson (specific field filters). If the user says "look up a contact" or "find a contact" without details, respond conversationally: "I\'d be happy to help you find a contact. Could you provide some details like the contact name, email, account name, or phone number?" Do NOT call the action with empty search criteria. Supports accountName parameter to link Contact to Account. Supports bulk operations for create/update by providing JSON array in fieldDataJson.'
        category='CRM Actions'
    )
    public static List<Response> contactAction(List<Request> requests) {
        List<Response> responses = new List<Response>();
        
        for (Request req : requests) {
            Response res = new Response();
            res.objectType = 'Contact';
            res.success = false;
            res.records = new List<Contact>();
            res.totalMatches = 0;
            res.ambiguous = false;
            res.moreResultsAvailable = false;
            res.confirmationRequired = false;
            
            try {
                String op = inferOperation(req);
                res.operation = op;
                
                // Handle delete confirmation separately
                if (op == 'delete' && (req.confirm == null || req.confirm == false)) {
                    res.confirmationRequired = true;
                    res.recordId = req.recordId;
                    
                    if (req.recordId == null) {
                        res.success = false;
                        res.errorMessage = 'Record ID is required for delete operation. Provide the 18-character Salesforce Contact ID.';
                        responses.add(res);
                        continue;
                    }
                    
                    try {
                        List<Contact> contacts = [SELECT Id, Name, Email FROM Contact WHERE Id = :req.recordId LIMIT 1];
                        if (!contacts.isEmpty()) {
                            Contact con = contacts[0];
                            res.message = 'This will delete Contact \'' + con.Name + '\' and all related records. Call again with confirm=true to proceed.';
                            res.success = true;
                        } else {
                            res.message = 'Contact not found with ID ' + req.recordId + '.';
                            res.errorMessage = res.message;
                            res.success = false;
                        }
                    } catch (Exception e) {
                        res.message = 'This will delete the Contact. Call again with confirm=true to proceed.';
                        res.success = true;
                    }
                    responses.add(res);
                    continue;
                }
                
                // Build request for AFUniversalCrmRecordAction
                AFUniversalCrmRecordAction.Request actionReq = new AFUniversalCrmRecordAction.Request();
                actionReq.objectApiName = 'Contact';
                actionReq.operation = op;
                actionReq.recordId = req.recordId;
                actionReq.fieldDataJson = req.fieldDataJson;
                actionReq.accountName = req.accountName;
                actionReq.confirm = req.confirm;
                actionReq.searchTerm = req.searchTerm;
                actionReq.filtersJson = req.filtersJson;
                actionReq.searchLimit = req.searchLimit;
                
                // Handle bulk operations
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
                        System.debug(LoggingLevel.DEBUG, 'AFContactAction: fieldDataJson is not a bulk array, treating as single record');
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
                    
                    if (actionRes.record != null) {
                        res.record = (Contact) actionRes.record;
                        res.recordId = res.record.Id;
                        res.records = new List<Contact>{ res.record };
                    } else if (actionRes.records != null && !actionRes.records.isEmpty()) {
                        res.records = new List<Contact>();
                        for (SObject so : actionRes.records) {
                            res.records.add((Contact) so);
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
                System.debug(LoggingLevel.ERROR, 'AFContactAction: ActionException - ' + ae.getMessage());
            } catch (Exception e) {
                res.success = false;
                res.errorMessage = 'Error performing Contact operation: ' + e.getMessage();
                System.debug(LoggingLevel.ERROR, 'AFContactAction: Exception - ' + e.getMessage());
            }
            
            responses.add(res);
        }
        
        return responses;
    }
}

