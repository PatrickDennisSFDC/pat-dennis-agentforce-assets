/**
 * AF Diagnostic Test Order Action
 * Consolidated invocable action for all Diagnostic_Test_Order__c CRUD operations (Create, Read, Update, Delete, Find)
 * Designed for Agentforce AI agents to manage diagnostic test orders
 * 
 * This class provides comprehensive CRUD operations for Diagnostic Test Orders, including:
 * - Creating new test orders with all relevant diagnostic information
 * - Reading test order details including status, dates, and test results
 * - Updating test order information as orders progress through their lifecycle
 * - Finding test orders by order number, tracking number, requisition number, or related account/contact
 * - Deleting test orders when needed
 * 
 * Key features:
 * - Automatic Account and Contact lookup resolution by name/email
 * - Flexible search across multiple fields (order number, tracking number, requisition number, etc.)
 * - Support for all test order fields including dates, status, test provider, test results, and notes
 * - Comprehensive error handling and user-friendly messages
 */
public without sharing class AFDiagnosticTestOrderAction {
    
    /**
     * Request class for Diagnostic Test Order operations
     * All parameters are designed to be clear and self-documenting for AI agents
     */
    public class Request {
        @InvocableVariable(
            label='Operation'
            description='Explicit operation: "create", "read", "update", "delete", or "find". If not specified, operation will be inferred from context. CREATE: Use when user wants to create a new diagnostic test order. READ: Use when user wants to view details of a specific test order. UPDATE: Use when user wants to modify an existing test order (e.g., update status, add results date, change test result). FIND: Use when user wants to search for test orders (e.g., "find orders for account X" or "find order by tracking number"). DELETE: Use when user wants to remove a test order.'
        )
        public String operation;
        
        @InvocableVariable(
            label='Field Data JSON'
            description='JSON string containing Diagnostic Test Order field data. For CREATE: {"Name":"DTO-026","Order_Number__c":"ORD-2024-026","Status__c":"Ordered","Test_Provider__c":"Genomic Diagnostics Inc","Test_Name__c":"Comprehensive Genomic Panel","Test_Type__c":"Genetic Testing","Order_Date__c":"2024-02-25","Priority__c":"High","Cost__c":2500.00,"Insurance_Covered__c":true}. For UPDATE: {"Status__c":"Sample Collected","Sample_Collection_Date__c":"2024-02-27","Results_Date__c":"2024-03-10","Test_Result__c":"Negative"}. For bulk operations: [{"Name":"DTO-026"},{"Name":"DTO-027"}]. Required field: Name. IMPORTANT: For picklist fields (Status__c, Test_Provider__c, Test_Name__c, Test_Type__c, Priority__c, Test_Result__c), query availableFieldsJson from a previous read operation to see valid values. Do NOT ask the user for picklist options - query availableFieldsJson to get them automatically. Date fields (Order_Date__c, Sample_Collection_Date__c, Results_Date__c) should be in YYYY-MM-DD format. If the user wants to update the Contact or Account on the order, use the contactNameOrEmail or accountName parameters instead of putting Contact__c or Account__c in fieldDataJson.'
            required=false
        )
        public String fieldDataJson;
        
        @InvocableVariable(
            label='Record ID'
            description='The Diagnostic Test Order ID (Salesforce record ID). Required for read/update/delete operations. Example: "a0xKj00000ABC123". When user provides an order number (e.g., "ORD-2024-001"), use FIND operation with searchTerm instead of this parameter.'
        )
        public Id recordId;
        
        @InvocableVariable(
            label='Search Term'
            description='Text to search for Diagnostic Test Orders. Searches across: Order Name, Order Number (Order_Number__c), Requisition Number (Requisition_Number__c), Lab Reference Number (Lab_Reference_Number__c), Tracking Number (Tracking_Number__c), Account Name (via Account__r.Name), Contact Name (via Contact__r.Name), and Physician Name (Physician_Name__c). Flexible matching with LIKE - spaces and punctuation variations work (e.g., "ORD 2024-001" or "ORD-2024-001" both match). Pass the search term exactly as the user provides it. Examples: "ORD-2024-001" finds by order number, "TRK-1Z23456789" finds by tracking number, "Dr. Sarah Mitchell" finds by physician name, "Acme Corp" finds orders for that account.'
        )
        public String searchTerm;
        
        @InvocableVariable(
            label='Filters JSON'
            description='JSON string of exact-match filters for find operations. Use for precise filtering by field values. Example: {"Status__c":"Completed","Test_Provider__c":"Genomic Diagnostics Inc"} or {"Priority__c":"High","Insurance_Covered__c":true}. Can be combined with searchTerm for refined results. Prefer searchTerm for name-based lookups (order number, tracking number, account name, contact name, physician name). Date filters: {"Order_Date__c":"2024-02-01"} or use date ranges with SOQL operators if needed.'
        )
        public String filtersJson;
        
        @InvocableVariable(
            label='Search Limit'
            description='Maximum number of records to return for find operations (default: 5, max: 20). Use lower limits (3-5) when searching for a specific order, higher limits (10-20) when user wants to see multiple orders.'
        )
        public Integer searchLimit;
        
        @InvocableVariable(
            label='Account Name'
            description='Account name to resolve to Account__c lookup. If provided, system searches for an Account and links the Diagnostic Test Order to it. IMPORTANT: When the user wants to add or update the account on a test order (e.g., "update the account to Acme Corporation" or "set the account to Omega Technologies"), use this parameter with the account name. Do NOT put Account__c in fieldDataJson - use this parameter instead. The system will automatically resolve the account name to an Account ID. If multiple accounts match, the system will return candidates for user clarification.'
        )
        public String accountName;
        
        @InvocableVariable(
            label='Contact Name or Email'
            description='Contact name or email to resolve to Contact__c lookup. If provided, system searches for a Contact and links the Diagnostic Test Order to them. IMPORTANT: When the user wants to add or update the contact on a test order (e.g., "add the contact as John Smith" or "update the contact to jane.doe@example.com"), use this parameter with the contact name or email. Do NOT put Contact__c in fieldDataJson - use this parameter instead. The system will automatically resolve the contact name/email to a Contact ID. If multiple contacts match, the system will return candidates for user clarification.'
        )
        public String contactNameOrEmail;
        
        @InvocableVariable(
            label='Confirm'
            description='For CREATE/UPDATE: Set to false to preview only (shows what would be created/updated without actually doing it). Set to true or omit to perform the operation. For DELETE: Set to true to actually delete the record. Set to false or omit to show a confirmation message without deleting.'
        )
        public Boolean confirm;
    }
    
    /**
     * Response class for Diagnostic Test Order operations
     * Provides comprehensive information about the operation result
     */
    public class Response {
        @InvocableVariable(
            label='Success'
            description='True if operation completed successfully, false if there was an error.'
        )
        public Boolean success;
        
        @InvocableVariable(
            label='Record'
            description='The Diagnostic Test Order record (for single record operations: create, read, update). Contains all fields including Name, Order_Number__c, Status__c, Test_Provider__c, Test_Name__c, Test_Type__c, dates (Order_Date__c, Sample_Collection_Date__c, Results_Date__c), Priority__c, Test_Result__c, Cost__c, Insurance_Covered__c, tracking numbers, physician information, and Notes__c.'
        )
        public Diagnostic_Test_Order__c record;
        
        @InvocableVariable(
            label='Records'
            description='List of Diagnostic Test Order records (for bulk or find operations). Use when multiple orders match the search criteria.'
        )
        public List<Diagnostic_Test_Order__c> records;
        
        @InvocableVariable(
            label='Record ID'
            description='The Salesforce ID of the Diagnostic Test Order record. Use this ID for subsequent read/update/delete operations.'
        )
        public Id recordId;
        
        @InvocableVariable(
            label='Message'
            description='Human-readable message describing the operation result. Examples: "Diagnostic Test Order created successfully", "Found 3 matching test orders", "Test order status updated from Ordered to Sample Collected".'
        )
        public String message;
        
        @InvocableVariable(
            label='Error Message'
            description='If success is false, this contains a user-friendly error message explaining what went wrong. Examples: "Test order not found with ID a0xKj00000ABC123", "Invalid picklist value for Status__c: use Ordered, Sample Collected, In Transit, Processing, Results Ready, Completed, or Cancelled".'
        )
        public String errorMessage;
        
        @InvocableVariable(
            label='Object Type'
            description='The Salesforce object type, always "Diagnostic_Test_Order__c" for Diagnostic Test Order operations.'
        )
        public String objectType;
        
        @InvocableVariable(
            label='Operation'
            description='The operation that was performed: "create", "read", "update", "delete", or "find".'
        )
        public String operation;
        
        @InvocableVariable(
            label='Preview Only'
            description='True if this is a preview response (when confirm=false for create/update). Shows what would be created/updated without actually performing the operation.'
        )
        public Boolean previewOnly;
        
        @InvocableVariable(
            label='Enrichment Suggested'
            description='True if additional fields are suggested to be filled in (e.g., when creating a test order with minimal information).'
        )
        public Boolean enrichmentSuggested;
        
        @InvocableVariable(
            label='Suggested Fields'
            description='List of commonly-used field API names that could be populated. Examples: ["Order_Date__c", "Priority__c", "Test_Provider__c", "Test_Name__c"].'
        )
        public List<String> suggestedFields;
        
        @InvocableVariable(
            label='Preview Data'
            description='A JSON string representation of what would be created/updated (when previewOnly=true).'
        )
        public String previewData;
        
        @InvocableVariable(
            label='Available Fields JSON'
            description='JSON string containing metadata for all available fields on Diagnostic_Test_Order__c, including field types, picklist values, and whether fields are required. IMPORTANT: Use this to get valid picklist values for Status__c, Test_Provider__c, Test_Name__c, Test_Type__c, Priority__c, and Test_Result__c. Do NOT ask the user for picklist options - query this field to get them automatically.'
        )
        public String availableFieldsJson;
        
        @InvocableVariable(
            label='Ambiguous Relationship'
            description='True if a parent lookup (Account or Contact) found multiple matches. When true, check relationshipCandidatesJson for the list of candidates.'
        )
        public Boolean ambiguousRelationship;
        
        @InvocableVariable(
            label='Ambiguous Relationship Type'
            description='The type of relationship that has multiple matches: "Account" or "Contact".'
        )
        public String ambiguousRelationshipType;
        
        @InvocableVariable(
            label='Relationship Candidates JSON'
            description='JSON array of candidate records when ambiguousRelationship is true. Format: [{"Id":"001xxx...","Name":"Acme Corp"},{"Id":"001yyy...","Name":"Acme Corporation"}]. Present these candidates to the user for clarification before proceeding.'
        )
        public String relationshipCandidatesJson;
        
        @InvocableVariable(
            label='Ambiguous Result'
            description='True if multiple records were found in a find/search operation. When true, present the records list to the user for selection.'
        )
        public Boolean ambiguous;
        
        @InvocableVariable(
            label='Total Matches'
            description='Number of Diagnostic Test Order records found in a find/search operation.'
        )
        public Integer totalMatches;
        
        @InvocableVariable(
            label='More Results Available'
            description='True if the search returned the maximum number of results but there are more matching records available. Suggest refining the search criteria or increasing searchLimit.'
        )
        public Boolean moreResultsAvailable;
        
        @InvocableVariable(
            label='Confirmation Required'
            description='True if this is a confirmation request for delete operation. Call again with confirm=true to actually delete.'
        )
        public Boolean confirmationRequired;
        
        @InvocableVariable(
            label='Related Account Name'
            description='Name of the related Account if the Diagnostic Test Order is linked to an Account (via Account__c lookup).'
        )
        public String relatedAccountName;
        
        @InvocableVariable(
            label='Related Contact Name'
            description='Name of the related Contact if the Diagnostic Test Order is linked to a Contact (via Contact__c lookup).'
        )
        public String relatedContactName;
    }
    
    /**
     * Infers the operation type from the request parameters if not explicitly specified
     * This helps AI agents by allowing them to omit the operation parameter when context is clear
     */
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
    
    /**
     * Main invocable method for Diagnostic Test Order CRUD operations
     * This is the entry point for all Diagnostic Test Order operations from AI agents
     * 
     * Usage examples:
     * - CREATE: fieldDataJson={"Name":"DTO-026","Order_Number__c":"ORD-2024-026","Status__c":"Ordered"}
     * - READ: recordId="a0xKj00000ABC123"
     * - UPDATE: recordId="a0xKj00000ABC123", fieldDataJson={"Status__c":"Sample Collected","Sample_Collection_Date__c":"2024-02-27"}
     * - FIND: searchTerm="ORD-2024-001" or searchTerm="Acme Corp"
     * - DELETE: recordId="a0xKj00000ABC123", confirm=true
     */
    @InvocableMethod(
        label='Agentforce Diagnostic Test Order Action'
        description='Performs CRUD operations on Diagnostic_Test_Order__c records. FIND/SEARCH: Use searchTerm to find test orders. Searches Order Name, Order Number (ORD-2024-001), Requisition Number, Lab Reference Number, Tracking Number, Account Name, Contact Name, and Physician Name. Flexible matching - "ORD 2024-001" or "ORD-2024-001" both work. Examples: "ORD-2024-001" finds by order number, "TRK-1Z23456789" finds by tracking number, "Dr. Sarah Mitchell" finds by physician name, "Acme Corp" finds orders for that account. READ: Provide recordId to get test order details including all fields (status, dates, test provider, test results, cost, tracking numbers, physician info, notes). UPDATE: recordId + fieldDataJson. Common updates: status changes (Ordered -> Sample Collected -> In Transit -> Processing -> Results Ready -> Completed), adding dates (Sample_Collection_Date__c, Results_Date__c), updating test results (Test_Result__c: Positive/Negative/Inconclusive/Pending), updating cost or insurance coverage. CREATE: fieldDataJson with test order details. Required: Name. Common fields: Order_Number__c, Status__c (default: Ordered), Test_Provider__c, Test_Name__c, Test_Type__c, Order_Date__c, Priority__c, Cost__c, Insurance_Covered__c. DELETE: recordId + confirm=true. ACCOUNT/CONTACT: Use accountName or contactNameOrEmail parameters to link by name/email - do NOT put Account__c or Contact__c in fieldDataJson.'
        category='CRM Actions'
    )
    public static List<Response> diagnosticTestOrderAction(List<Request> requests) {
        List<Response> responses = new List<Response>();
        
        for (Request req : requests) {
            Response res = new Response();
            res.objectType = 'Diagnostic_Test_Order__c';
            res.success = false;
            res.records = new List<Diagnostic_Test_Order__c>();
            res.totalMatches = 0;
            res.ambiguous = false;
            res.moreResultsAvailable = false;
            res.confirmationRequired = false;
            
            try {
                String op = inferOperation(req);
                res.operation = op;
                
                // Handle delete confirmation
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
                        List<Diagnostic_Test_Order__c> orders = [SELECT Id, Name, Order_Number__c FROM Diagnostic_Test_Order__c WHERE Id = :req.recordId LIMIT 1];
                        if (!orders.isEmpty()) {
                            String orderName = String.isNotBlank(orders[0].Order_Number__c) ? orders[0].Order_Number__c : orders[0].Name;
                            res.message = 'This will delete Diagnostic Test Order \'' + orderName + '\' (ID: ' + req.recordId + '). Call again with confirm=true to proceed.';
                            res.success = true;
                        } else {
                            res.message = 'Diagnostic Test Order not found with ID ' + req.recordId + '.';
                            res.errorMessage = res.message;
                            res.success = false;
                        }
                    } catch (Exception e) {
                        res.message = 'This will delete the Diagnostic Test Order. Call again with confirm=true to proceed.';
                        res.success = true;
                    }
                    responses.add(res);
                    continue;
                }
                
                // Delegate to AFUniversalCrmRecordAction for all operations
                AFUniversalCrmRecordAction.Request actionReq = new AFUniversalCrmRecordAction.Request();
                actionReq.objectApiName = 'Diagnostic_Test_Order__c';
                actionReq.operation = op;
                actionReq.fieldDataJson = req.fieldDataJson;
                actionReq.recordId = req.recordId;
                actionReq.searchTerm = req.searchTerm;
                actionReq.filtersJson = req.filtersJson;
                actionReq.searchLimit = req.searchLimit;
                actionReq.accountName = req.accountName;
                actionReq.contactNameOrEmail = req.contactNameOrEmail;
                actionReq.confirm = req.confirm;
                
                // For find operations, enhance search to include diagnostic test order specific fields
                if (op == 'find' || op == 'search') {
                    // AFUniversalCrmRecordAction will handle the search, but we'll enhance the response
                }
                
                AFUniversalCrmRecordAction.Response actionRes = AFUniversalCrmRecordAction.processRequest(actionReq);
                
                // Map the response
                res.success = actionRes.success;
                res.message = actionRes.message;
                res.errorMessage = actionRes.errorDetails;
                res.recordId = actionRes.recordId;
                res.previewOnly = actionRes.previewOnly != null ? actionRes.previewOnly : false;
                res.availableFieldsJson = actionRes.availableFieldsJson;
                res.ambiguousRelationship = actionRes.ambiguousRelationship != null ? actionRes.ambiguousRelationship : false;
                res.ambiguousRelationshipType = actionRes.ambiguousRelationshipType;
                res.relationshipCandidatesJson = actionRes.relationshipCandidatesJson;
                res.ambiguous = actionRes.ambiguous != null ? actionRes.ambiguous : false;
                res.totalMatches = actionRes.totalMatches != null ? actionRes.totalMatches : 0;
                // Calculate moreResultsAvailable based on totalMatches and searchLimit
                Integer searchLimit = req.searchLimit != null ? req.searchLimit : 5;
                res.moreResultsAvailable = (res.totalMatches >= searchLimit);
                res.enrichmentSuggested = actionRes.enrichmentSuggested != null ? actionRes.enrichmentSuggested : false;
                res.suggestedFields = actionRes.suggestedFields;
                res.previewData = actionRes.previewData;
                
                if (actionRes.success) {
                    if (actionRes.record != null) {
                        res.record = (Diagnostic_Test_Order__c) actionRes.record;
                        res.records = new List<Diagnostic_Test_Order__c>{ res.record };
                        
                        // Get related account/contact names
                        try {
                            Diagnostic_Test_Order__c order = [
                                SELECT Account__r.Name, Contact__r.Name 
                                FROM Diagnostic_Test_Order__c 
                                WHERE Id = :res.recordId 
                                LIMIT 1
                            ];
                            res.relatedAccountName = order.Account__r != null ? order.Account__r.Name : null;
                            res.relatedContactName = order.Contact__r != null ? order.Contact__r.Name : null;
                        } catch (Exception e) {
                            System.debug(LoggingLevel.DEBUG, 'AFDiagnosticTestOrderAction: Could not fetch related account/contact names');
                        }
                    } else if (actionRes.records != null && !actionRes.records.isEmpty()) {
                        res.records = new List<Diagnostic_Test_Order__c>();
                        for (SObject so : actionRes.records) {
                            res.records.add((Diagnostic_Test_Order__c) so);
                        }
                        if (res.records.size() == 1) {
                            res.record = res.records[0];
                            res.recordId = res.records[0].Id;
                        } else if (!res.records.isEmpty()) {
                            res.ambiguous = true;
                        }
                    }
                }
                
            } catch (AFUniversalCrmRecordAction.ActionException ae) {
                res.success = false;
                res.errorMessage = ae.getMessage();
                System.debug(LoggingLevel.ERROR, 'AFDiagnosticTestOrderAction: ActionException - ' + ae.getMessage());
            } catch (Exception e) {
                res.success = false;
                res.errorMessage = 'Error performing Diagnostic Test Order operation: ' + e.getMessage();
                System.debug(LoggingLevel.ERROR, 'AFDiagnosticTestOrderAction: Exception - ' + e.getMessage());
            }
            
            responses.add(res);
        }
        
        return responses;
    }
}

