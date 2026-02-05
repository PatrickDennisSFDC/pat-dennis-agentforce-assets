/**
 * AF Universal CRM Record Action
 * Shared utility class for AI agents to perform CRUD operations on Account, Contact, Case, and Opportunity records.
 * This class provides the core business logic that is reused by object-specific invocable action classes.
 * 
 * Supported Operations:
 * - read: Retrieve a single record by ID
 * - find: Search for records using filters and/or search terms
 * - search: Alias for find operation
 * - create: Create a new record
 * - update: Update an existing record
 * - bulkCreate: Create multiple records at once
 * - bulkUpdate: Update multiple records at once
 * - delete: Delete a record
 * 
 * Features:
 * - Related record resolution (e.g., specify Account by name instead of ID)
 * - Picklist validation
 * - Partial success handling for bulk operations
 */
public without sharing class AFUniversalCrmRecordAction {
    
    // Supported objects
    private static final Set<String> SUPPORTED_OBJECTS = new Set<String>{'account', 'contact', 'case', 'opportunity', 'task', 'meeting__c', 'customerorders__c', 'customer_order_line_item__c', 'diagnostic_test_order__c', 'program_candidate__c'};
    private static final Integer DEFAULT_SEARCH_LIMIT = 5;
    private static final Integer MAX_SEARCH_LIMIT = 20;
    
    /**
     * Input: Field value for create/update operations
     */
    public class FieldValue {
        @InvocableVariable(label='Field API Name' description='The API name of the field (e.g., Name, Email, Subject)' required=true)
        public String fieldApiName;
        
        @InvocableVariable(label='Field Value' description='The value to set for this field' required=true)
        public String value;
    }
    
    /**
     * Input: Filter for find/search operations
     */
    public class Filter {
        @InvocableVariable(label='Field API Name' description='The API name of the field to filter on' required=true)
        public String fieldApiName;
        
        @InvocableVariable(label='Filter Value' description='The value to match (exact match)' required=true)
        public String value;
    }
    
    /**
     * Input: Request parameters for the operation
     */
    public class Request {
        @InvocableVariable(label='Object API Name' description='The Salesforce object: Account, Contact, Case, or Opportunity' required=true)
        public String objectApiName;
        
        @InvocableVariable(label='Operation' description='The operation to perform: read, find, search, create, update, bulkCreate, or bulkUpdate' required=true)
        public String operation;
        
        @InvocableVariable(label='Record ID' description='The ID of the record (required for read and update operations)')
        public Id recordId;
        
        @InvocableVariable(label='Field Data JSON' description='JSON string for field data (create/update operations). Preferred method for AI agents. Can be array [{"fieldApiName":"Name","value":"Acme"}] or single object {"fieldApiName":"Name","value":"Acme"}. Example: {"fieldApiName":"Name","value":"Acme Corp"}')
        public String fieldDataJson;
        
        @InvocableVariable(label='Filters JSON' description='JSON string for filters (find/search operations). Preferred method for AI agents. Can be array [{"fieldApiName":"Name","value":"Acme"}] or single object {"fieldApiName":"Name","value":"Acme"}. Example: {"fieldApiName":"Name","value":"Acme Corp"}')
        public String filtersJson;
        
        @InvocableVariable(label='Search Term' description='Text to search for in key fields (used with find/search operations)')
        public String searchTerm;
        
        @InvocableVariable(label='Field Data' description='List of field names and values for create/update operations (legacy - use fieldDataJson instead)')
        public List<FieldValue> fieldData;
        
        @InvocableVariable(label='Filters' description='List of exact-match filters for find/search operations (legacy - use filtersJson instead)')
        public List<Filter> filters;
        
        @InvocableVariable(label='Search Limit' description='Maximum number of records to return (default: 5, max: 20)')
        public Integer searchLimit;
        
        @InvocableVariable(label='Bulk Records JSON' description='JSON array of record objects for bulkCreate/bulkUpdate operations. Example: [{"Name":"Acme"},{"Name":"Globex"}]')
        public String bulkRecordsJson;
        
        @InvocableVariable(label='Account Name' description='Account name to resolve to AccountId (for Contact or Case creation/update)')
        public String accountName;
        
        @InvocableVariable(label='Contact Name or Email' description='Contact name or email to resolve to ContactId (for Case creation/update)')
        public String contactNameOrEmail;
        
        @InvocableVariable(label='Debug Email' description='Email address to send debug information on failures (leave blank to disable)')
        public String debugEmail;
        
        @InvocableVariable(label='Confirm' description='Optional: Set to false to preview only without committing changes. Default (true): Creates/updates the record immediately. When user says "create" or "update", omit this field or set to true to commit immediately. Only set to false if user explicitly asks to preview first.')
        public Boolean confirm;
    }
    
    /**
     * Output: Error detail for a single record in bulk operations
     */
    public class BulkRecordError {
        @InvocableVariable(label='Record Index' description='The index of the failed record in the input array')
        public Integer recordIndex;
        
        @InvocableVariable(label='Error Message' description='Description of what went wrong')
        public String errorMessage;
        
        @InvocableVariable(label='Record Data' description='The input data that failed')
        public String recordData;
    }
    
    /**
     * Output: Response from the operation
     */
    public class Response {
        @InvocableVariable(label='Success' description='Whether the operation completed successfully')
        public Boolean success;
        
        @InvocableVariable(label='Operation' description='The operation that was performed')
        public String operation;
        
        @InvocableVariable(label='Object API Name' description='The object type that was operated on')
        public String objectApiName;
        
        @InvocableVariable(label='Record ID' description='The ID of the record (for single record operations)')
        public Id recordId;
        
        @InvocableVariable(label='Record' description='The single record returned (for read or single-match find)')
        public SObject record;
        
        @InvocableVariable(label='Records' description='List of records returned (for find/search operations)')
        public List<SObject> records;
        
        @InvocableVariable(label='Ambiguous Result' description='True if multiple records were found (user needs to clarify)')
        public Boolean ambiguous;
        
        @InvocableVariable(label='Total Matches' description='Number of records found in search')
        public Integer totalMatches;
        
        @InvocableVariable(label='Message' description='Human-readable message about the operation result')
        public String message;
        
        @InvocableVariable(label='Error Details' description='Detailed error information if the operation failed')
        public String errorDetails;
        
        // Bulk operation response fields
        @InvocableVariable(label='Success Count' description='Number of records successfully processed (bulk operations)')
        public Integer successCount;
        
        @InvocableVariable(label='Failure Count' description='Number of records that failed (bulk operations)')
        public Integer failureCount;
        
        @InvocableVariable(label='Success Record IDs' description='List of IDs for successfully created/updated records')
        public List<Id> successRecordIds;
        
        @InvocableVariable(label='Errors' description='List of errors for failed records in bulk operations')
        public List<BulkRecordError> errors;
        
        // Preview and enrichment fields
        @InvocableVariable(label='Preview Only' description='True if this is a preview response (confirm=false). The record has not been created/updated yet. The agent should present the preview to the user, collect additional field data if enrichment is suggested, then call again with confirm=true to commit.')
        public Boolean previewOnly;
        
        @InvocableVariable(label='Enrichment Suggested' description='True if the provided data is minimal and additional fields are suggested. When true, check suggestedFields for commonly-used fields that could be populated to enrich the record.')
        public Boolean enrichmentSuggested;
        
        @InvocableVariable(label='Suggested Fields' description='List of commonly-used field API names that could be populated to enrich this record. Examples for Account: Industry, BillingCity, Phone, Website. The agent should ask the user about these fields and add them to fieldDataJson before calling again with confirm=true.')
        public List<String> suggestedFields;
        
        @InvocableVariable(label='Preview Data' description='A JSON string representation of what would be created/updated. Use this to show the user a preview before committing. Format: {"Name":"Test 1","Industry":null,"BillingCity":null,...}')
        public String previewData;
        
        @InvocableVariable(label='Available Fields JSON' description='JSON string containing metadata for all available fields that can be set on this record. Includes API name, label, type, required status, picklist values, help text, and more. Use this to understand what fields are available and their constraints. Format: [{"apiName":"Name","label":"Account Name","type":"STRING","required":true,"createable":true,"updateable":true,"picklistValues":null,"helpText":"Name of the account","maxLength":255},...]')
        public String availableFieldsJson;
        
        // Related object context (for Task and other objects with relationships)
        @InvocableVariable(label='Related Account Name' description='Name of the related Account if applicable. For Tasks, this is the Account linked via WhatId. Use this to provide context to the user about what the record is related to.')
        public String relatedAccountName;
        
        @InvocableVariable(label='Related Contact Name' description='Name of the related Contact if applicable. For Tasks, this is the Contact linked via WhoId. Use this to provide context to the user about who the record is related to.')
        public String relatedContactName;
        
        @InvocableVariable(label='Related Opportunity Name' description='Name of the related Opportunity if applicable. For Tasks, this is the Opportunity linked via WhatId. Use this to provide context to the user.')
        public String relatedOpportunityName;
        
        // Ambiguity detection fields
        @InvocableVariable(label='Ambiguous Relationship' description='True if a related record lookup (Account, Contact, Opportunity) found multiple matches (2+). The agent MUST present the candidates to the user and ask for clarification before proceeding. DO NOT create/update the record until the user clarifies which related record to use.')
        public Boolean ambiguousRelationship;
        
        @InvocableVariable(label='Ambiguous Relationship Type' description='Type of ambiguous relationship: Account, Contact, or Opportunity. Use this to know what kind of candidates are in relationshipCandidatesJson.')
        public String ambiguousRelationshipType;
        
        @InvocableVariable(label='Relationship Candidates JSON' description='JSON array of up to 5 candidate records with disambiguating details. For Account: Name, BillingCity, Phone, Industry. For Contact: Name, Email, Phone, AccountName, Title. For Opportunity: Name, StageName, Amount, AccountName. Agent should present these options to the user: "I found X records: 1) Name at Company (email), 2) Name at Company2 (email2)... Which one?" Then call again with specific email, phone, or company name.')
        public String relationshipCandidatesJson;
    }
    
    /**
     * Process a single request
     * Public method to be called by object-specific invocable action classes
     */
    public static Response processRequest(Request req) {
        Response res = new Response();
        res.operation = req != null && req.operation != null ? req.operation : 'unknown';
        res.objectApiName = req != null && req.objectApiName != null ? req.objectApiName : 'unknown';
        res.success = false;
        res.records = new List<SObject>();
        res.totalMatches = 0;
        
        try {
            // Log the raw request for debugging
            System.debug(LoggingLevel.INFO, 'AFUniversalCrmRecordAction: Processing request - Object: ' + (req != null ? req.objectApiName : 'null') + ', Operation: ' + (req != null ? req.operation : 'null'));
            System.debug(LoggingLevel.INFO, 'AFUniversalCrmRecordAction: Filters type: ' + (req != null && req.filters != null ? String.valueOf(req.filters) : 'null'));
            System.debug(LoggingLevel.INFO, 'AFUniversalCrmRecordAction: Filters is ' + (req != null && req.filters != null ? 'not null' : 'null'));
            
            // Validate required inputs
            validateRequest(req);
            
            String obj = req.objectApiName.trim().toLowerCase();
            String op = req.operation.trim().toLowerCase();
            
            System.debug(LoggingLevel.INFO, 'AFUniversalCrmRecordAction: Normalized object: ' + obj + ', operation: ' + op);
            
            // Get object metadata
            Schema.SObjectType sType = Schema.getGlobalDescribe().get(obj);
            if (sType == null) {
                throw new ActionException('Invalid object: ' + obj);
            }
            
            Schema.DescribeSObjectResult objDescribe = sType.getDescribe();
            Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();
            
            System.debug(LoggingLevel.INFO, 'AFUniversalCrmRecordAction: Object metadata retrieved, field count: ' + fieldMap.size());
            
            // Route to appropriate handler
            switch on op {
                when 'read' {
                    handleRead(req, res, obj, fieldMap);
                }
                when 'create' {
                    handleCreate(req, res, sType, fieldMap);
                }
                when 'update' {
                    handleUpdate(req, res, sType, fieldMap);
                }
                when 'find', 'search' {
                    handleFindSearch(req, res, obj, fieldMap);
                }
                when 'bulkcreate' {
                    handleBulkCreate(req, res, sType, fieldMap);
                }
                when 'bulkupdate' {
                    handleBulkUpdate(req, res, sType, fieldMap);
                }
                when 'delete' {
                    handleDelete(req, res, sType, fieldMap);
                }
                when else {
                    throw new ActionException('Unsupported operation: ' + req.operation + '. Use: read, find, search, create, update, bulkCreate, bulkUpdate, or delete.');
                }
            }
            
            res.success = true;
            
        } catch (MissingParentException mpe) {
            res.success = false;
            res.message = mpe.parentType + ' \'' + mpe.parentName + '\' not found. To create it, I need: ' + 
                         String.join(mpe.requiredFields, ', ') + 
                         (mpe.optionalFields != null && !mpe.optionalFields.isEmpty() ? 
                             '. Optional fields: ' + String.join(mpe.optionalFields, ', ') : '');
            res.errorDetails = JSON.serialize(new Map<String, Object>{
                'missingParent' => mpe.parentType,
                'parentName' => mpe.parentName,
                'requiredFields' => mpe.requiredFields,
                'optionalFields' => mpe.optionalFields
            });
            res.records = new List<SObject>();
            res.totalMatches = 0;
            System.debug(LoggingLevel.INFO, 'AFUniversalCrmRecordAction: MissingParentException - ' + res.message);
        } catch (QueryException qe) {
            res.success = false;
            res.message = 'Record not found or query failed.';
            res.errorDetails = qe.getMessage();
            res.records = new List<SObject>();
            res.totalMatches = 0;
            System.debug(LoggingLevel.ERROR, 'AFUniversalCrmRecordAction: QueryException - ' + qe.getMessage());
            System.debug(LoggingLevel.ERROR, 'AFUniversalCrmRecordAction: Stack trace - ' + qe.getStackTraceString());
            sendDebugEmail(req, res, qe);
        } catch (DmlException dmlEx) {
            res.success = false;
            res.message = 'Database operation failed: ' + dmlEx.getDmlMessage(0);
            res.errorDetails = dmlEx.getStackTraceString();
            res.records = new List<SObject>();
            res.totalMatches = 0;
            System.debug(LoggingLevel.ERROR, 'AFUniversalCrmRecordAction: DmlException - ' + dmlEx.getMessage());
            System.debug(LoggingLevel.ERROR, 'AFUniversalCrmRecordAction: Stack trace - ' + dmlEx.getStackTraceString());
            sendDebugEmail(req, res, dmlEx);
        } catch (Exception e) {
            res.success = false;
            res.message = e.getMessage();
            res.errorDetails = e.getStackTraceString();
            res.records = new List<SObject>();
            res.totalMatches = 0;
            System.debug(LoggingLevel.ERROR, 'AFUniversalCrmRecordAction: Exception - ' + e.getTypeName() + ': ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'AFUniversalCrmRecordAction: Stack trace - ' + e.getStackTraceString());
            sendDebugEmail(req, res, e);
        }
        
        System.debug(LoggingLevel.INFO, 'AFUniversalCrmRecordAction: Returning response - Success: ' + res.success + ', Message: ' + res.message);
        return res;
    }
    
    /**
     * Validate the request has required fields
     */
    private static void validateRequest(Request req) {
        if (String.isBlank(req.objectApiName)) {
            throw new ActionException('objectApiName is required. Specify: Account, Contact, Case, or Opportunity.');
        }
        
        if (String.isBlank(req.operation)) {
            throw new ActionException('operation is required. Use: read, find, search, create, update, bulkCreate, bulkUpdate, or delete.');
        }
        
        String obj = req.objectApiName.trim().toLowerCase();
        if (!SUPPORTED_OBJECTS.contains(obj)) {
            throw new ActionException('Unsupported object: ' + req.objectApiName + '. Only Account, Contact, Case, and Opportunity are supported.');
        }
    }
    
    /**
     * Handle READ operation
     */
    private static void handleRead(
        Request req,
        Response res,
        String objectApiName,
        Map<String, Schema.SObjectField> fieldMap
    ) {
        if (req.recordId == null) {
            throw new ActionException('recordId is required for read operation. Provide the 18-character Salesforce ID.');
        }
        
        // Build dynamic SOQL
        String soql = 'SELECT ' + String.join(new List<String>(fieldMap.keySet()), ', ') +
                      ' FROM ' + objectApiName +
                      ' WHERE Id = :recordId' +
                      ' LIMIT 1';
        
        Id recordId = req.recordId;
        List<SObject> results = Database.query(soql);
        
        if (results.isEmpty()) {
            throw new ActionException('No record found with ID: ' + req.recordId);
        }
        
        SObject record = results[0];
        res.record = record;
        res.recordId = (Id) record.get('Id');
        res.message = objectApiName + ' record retrieved successfully.';
        
        // Populate related object names for Task
        if (objectApiName.toLowerCase() == 'task') {
            populateTaskRelatedNames(res, (Task) record);
        }
    }
    
    /**
     * Handle CREATE operation
     */
    private static void handleCreate(
        Request req,
        Response res,
        Schema.SObjectType sType,
        Map<String, Schema.SObjectField> fieldMap
    ) {
        // Parse fieldData - check fieldDataJson first (for AI agent compatibility), then fieldData
        List<FieldValue> normalizedFieldData = new List<FieldValue>();
        
        if (!String.isBlank(req.fieldDataJson)) {
            System.debug(LoggingLevel.INFO, 'AFUniversalCrmRecordAction: Parsing fieldDataJson: ' + req.fieldDataJson);
            normalizedFieldData = parseFieldDataJson(req.fieldDataJson);
        } else if (req.fieldData != null) {
            // Fall back to fieldData field if fieldDataJson is not provided
            System.debug(LoggingLevel.INFO, 'AFUniversalCrmRecordAction: Using fieldData field');
            normalizedFieldData = normalizeFieldData(req.fieldData);
        }
        
        if (normalizedFieldData == null || normalizedFieldData.isEmpty()) {
            throw new ActionException('fieldData is required for create operation. Provide fieldDataJson or fieldData with at least the required fields.');
        }
        
        System.debug(LoggingLevel.INFO, 'AFUniversalCrmRecordAction: Normalized fieldData count: ' + normalizedFieldData.size());
        
        Map<String, Object> fieldDataMap = convertFieldData(normalizedFieldData);
        
        // Resolve related records - may throw AmbiguousRelationshipException
        try {
            resolveRelatedRecords(req, fieldDataMap);
        } catch (AmbiguousRelationshipException are) {
            // Return ambiguity info to agent for user clarification
            res.success = false;
            res.ambiguousRelationship = true;
            res.ambiguousRelationshipType = are.relationshipType;
            res.relationshipCandidatesJson = JSON.serialize(are.candidates);
            res.message = 'Multiple ' + are.relationshipType + ' records found matching "' + are.searchCriteria + '". ' +
                         'Please ask the user to specify which one by providing additional details like email, phone, company name, or city. ' +
                         'Then call this action again with more specific criteria in the accountName or contactNameOrEmail parameter.';
            System.debug(LoggingLevel.INFO, 'AFUniversalCrmRecordAction: Ambiguous ' + are.relationshipType + ' - ' + are.candidates.size() + ' candidates');
            return;
        }
        
        // Enforce minimum required fields
        enforceCreateRequirements(req.objectApiName, fieldDataMap);
        
        // Check if this is a preview (confirm=false explicitly set)
        // Default behavior: commit the change (confirm=true by default)
        Boolean shouldCommit = (req.confirm == null || req.confirm == true);
        
        // Detect enrichment opportunity (count optional fields)
        Integer optionalFieldCount = countOptionalFields(fieldDataMap, req.objectApiName);
        Boolean suggestEnrichment = (optionalFieldCount < 2);
        
        // If preview mode, return preview without creating
        if (!shouldCommit) {
            res.previewOnly = true;
            res.enrichmentSuggested = suggestEnrichment;
            res.previewData = JSON.serialize(fieldDataMap);
            res.availableFieldsJson = getAllAvailableFields(req.objectApiName, fieldMap, true);
            
            if (suggestEnrichment) {
                res.suggestedFields = getSuggestedFields(req.objectApiName, fieldMap);
            }
            
            res.message = buildPreviewMessage(req.objectApiName, fieldDataMap, suggestEnrichment);
            res.success = true; // Preview is successful
            return;
        }
        
        // Validate picklist values
        validatePicklistValues(fieldDataMap, fieldMap);
        
        // Create and populate the record
        SObject record = sType.newSObject();
        applyFieldData(record, fieldMap, fieldDataMap);
        
        // Insert the record
        insert record;
        
        // Ensure record has an ID after insert
        if (record.Id == null) {
            throw new ActionException('Record was created but ID was not assigned. This should not happen.');
        }
        
        res.record = record;
        res.recordId = record.Id;
        res.message = req.objectApiName + ' record created successfully.';
        System.debug(LoggingLevel.INFO, 'AFUniversalCrmRecordAction: Created record with ID: ' + record.Id);
    }
    
    /**
     * Handle UPDATE operation
     */
    private static void handleUpdate(
        Request req,
        Response res,
        Schema.SObjectType sType,
        Map<String, Schema.SObjectField> fieldMap
    ) {
        // Parse fieldData first to extract identifying fields for name resolution
        List<FieldValue> normalizedFieldData = new List<FieldValue>();
        
        if (!String.isBlank(req.fieldDataJson)) {
            System.debug(LoggingLevel.INFO, 'AFUniversalCrmRecordAction: Parsing fieldDataJson: ' + req.fieldDataJson);
            normalizedFieldData = parseFieldDataJson(req.fieldDataJson);
        } else if (req.fieldData != null) {
            // Fall back to fieldData field if fieldDataJson is not provided
            System.debug(LoggingLevel.INFO, 'AFUniversalCrmRecordAction: Using fieldData field');
            normalizedFieldData = normalizeFieldData(req.fieldData);
        }
        
        Map<String, Object> fieldDataMap = convertFieldData(normalizedFieldData);
        
        // Handle Account__c/Contact__c as name strings for CustomerOrders__c
        if (req.objectApiName.toLowerCase() == 'customerorders__c') {
            // If Account__c is provided as a name string, resolve it
            if (fieldDataMap.containsKey('Account__c') && fieldDataMap.get('Account__c') != null) {
                String accountValue = String.valueOf(fieldDataMap.get('Account__c'));
                // Check if it's not already an ID (18 chars starting with 001)
                if (accountValue.length() != 18 || !accountValue.startsWith('001')) {
                    try {
                        Id accountId = resolveAccountByName(accountValue);
                        if (accountId != null) {
                            fieldDataMap.put('Account__c', accountId);
                        } else {
                            fieldDataMap.remove('Account__c'); // Remove invalid value
                        }
                    } catch (Exception e) {
                        System.debug(LoggingLevel.WARN, 'AFUniversalCrmRecordAction: Could not resolve Account__c name: ' + e.getMessage());
                        fieldDataMap.remove('Account__c');
                    }
                }
            }
            // If Contact__c is provided as a name string, resolve it
            if (fieldDataMap.containsKey('Contact__c') && fieldDataMap.get('Contact__c') != null) {
                String contactValue = String.valueOf(fieldDataMap.get('Contact__c'));
                // Check if it's not already an ID (18 chars starting with 003)
                if (contactValue.length() != 18 || !contactValue.startsWith('003')) {
                    try {
                        Id contactId = resolveContactByNameOrEmail(contactValue, req.accountName);
                        if (contactId != null) {
                            fieldDataMap.put('Contact__c', contactId);
                        } else {
                            fieldDataMap.remove('Contact__c'); // Remove invalid value
                        }
                    } catch (Exception e) {
                        System.debug(LoggingLevel.WARN, 'AFUniversalCrmRecordAction: Could not resolve Contact__c name: ' + e.getMessage());
                        fieldDataMap.remove('Contact__c');
                    }
                }
            }
        }
        
        // Resolve recordId if not provided (name-based resolution)
        if (req.recordId == null) {
            System.debug(LoggingLevel.INFO, 'AFUniversalCrmRecordAction: recordId not provided, attempting name-based resolution');
            req.recordId = resolveRecordIdForUpdate(req, fieldDataMap);
            
            if (req.recordId == null) {
                String obj = req.objectApiName.toLowerCase();
                String identifierHint = '';
                switch on obj {
                    when 'account' { identifierHint = 'Name field in fieldDataJson (e.g., {"Name":"Test 10","Industry":"Tech"})'; }
                    when 'contact' { identifierHint = 'LastName (and optionally FirstName or Email) in fieldDataJson'; }
                    when 'opportunity' { identifierHint = 'Name field in fieldDataJson'; }
                    when 'task' { identifierHint = 'Task ID (name resolution not supported for Tasks)'; }
                    when 'meeting__c' { identifierHint = 'Subject__c field in fieldDataJson'; }
                    when 'customerorders__c' { identifierHint = 'Name or Order_Number__c field in fieldDataJson'; }
                    when 'customer_order_line_item__c' { identifierHint = 'Line Item ID (name resolution not supported for Line Items)'; }
                }
                throw new ActionException('recordId is required for update operation, or provide ' + identifierHint + ' to resolve the record automatically. Could not find a matching record with the provided information.');
            }
        }
        
        // Get current record data (needed for both preview and update)
        String objectApiName = sType.getDescribe().getName();
        String soql = 'SELECT ' + String.join(new List<String>(fieldMap.keySet()), ', ') +
                      ' FROM ' + objectApiName +
                      ' WHERE Id = :recordId' +
                      ' LIMIT 1';
        Id recordId = req.recordId;
        List<SObject> currentRecords = Database.query(soql);
        
        if (currentRecords.isEmpty()) {
            throw new ActionException('No ' + objectApiName + ' record found with ID: ' + req.recordId);
        }
        
        SObject currentRecord = currentRecords[0];
        
        // If no field data provided, return current record and available fields
        if (normalizedFieldData == null || normalizedFieldData.isEmpty()) {
            res.record = currentRecord;
            res.recordId = (Id) currentRecord.get('Id');
            res.availableFieldsJson = getAllAvailableFields(req.objectApiName, fieldMap, false);
            res.message = 'Here\'s the current ' + objectApiName + ' record data. Provide fields to update in fieldDataJson. Check availableFieldsJson for all fields that can be updated.';
            res.success = true;
            return;
        }
        
        System.debug(LoggingLevel.INFO, 'AFUniversalCrmRecordAction: Normalized fieldData count: ' + normalizedFieldData.size());
        
        // Resolve related records - may throw AmbiguousRelationshipException
        try {
            resolveRelatedRecords(req, fieldDataMap);
        } catch (AmbiguousRelationshipException are) {
            // Return ambiguity info to agent for user clarification
            res.success = false;
            res.ambiguousRelationship = true;
            res.ambiguousRelationshipType = are.relationshipType;
            res.relationshipCandidatesJson = JSON.serialize(are.candidates);
            res.message = 'Multiple ' + are.relationshipType + ' records found matching "' + are.searchCriteria + '". ' +
                         'Please ask the user to specify which one by providing additional details like email, phone, company name, or city. ' +
                         'Then call this action again with more specific criteria in the accountName or contactNameOrEmail parameter.';
            System.debug(LoggingLevel.INFO, 'AFUniversalCrmRecordAction: Ambiguous ' + are.relationshipType + ' - ' + are.candidates.size() + ' candidates');
            return;
        }
        
        // Check if this is a preview (confirm=false explicitly set)
        // Default behavior: commit the change (confirm=true by default)
        Boolean shouldCommit = (req.confirm == null || req.confirm == true);
        
        // Build preview data showing what would change
        Map<String, Object> previewDataMap = new Map<String, Object>();
        for (String fieldName : fieldDataMap.keySet()) {
            if (fieldName != 'Id' && !fieldName.startsWith('_')) {
                Object currentValue = currentRecord.get(fieldName);
                Object newValue = fieldDataMap.get(fieldName);
                previewDataMap.put(fieldName, new Map<String, Object>{
                    'current' => currentValue,
                    'new' => newValue
                });
            }
        }
        
        // If preview mode, return preview without updating
        if (!shouldCommit) {
            res.previewOnly = true;
            res.previewData = JSON.serialize(previewDataMap);
            res.availableFieldsJson = getAllAvailableFields(req.objectApiName, fieldMap, false);
            res.record = currentRecord; // Return current record for context
            res.recordId = req.recordId;
            res.message = 'Preview: This will update the ' + objectApiName + ' record with the following changes:\n' + 
                         JSON.serialize(previewDataMap) + 
                         '\n\nCall again with confirm=true to apply these changes.';
            res.success = true; // Preview is successful
            return;
        }
        
        // Validate picklist values
        validatePicklistValues(fieldDataMap, fieldMap);
        
        // Create record stub with ID and apply changes
        SObject record = sType.newSObject(req.recordId);
        applyFieldData(record, fieldMap, fieldDataMap);
        
        // Update the record
        update record;
        
        res.record = record;
        res.recordId = record.Id;
        res.message = req.objectApiName + ' record updated successfully.';
    }
    
    /**
     * Handle DELETE operation
     */
    private static void handleDelete(
        Request req,
        Response res,
        Schema.SObjectType sType,
        Map<String, Schema.SObjectField> fieldMap
    ) {
        if (req.recordId == null) {
            throw new ActionException('recordId is required for delete operation.');
        }
        
        // First verify the record exists
        String objectApiName = sType.getDescribe().getName();
        String soql = 'SELECT Id FROM ' + objectApiName + ' WHERE Id = :recordId LIMIT 1';
        Id recordId = req.recordId;
        List<SObject> results = Database.query(soql);
        
        if (results.isEmpty()) {
            throw new ActionException('No ' + objectApiName + ' record found with ID: ' + req.recordId);
        }
        
        // Delete the record
        delete results[0];
        
        res.recordId = req.recordId;
        res.message = objectApiName + ' record deleted successfully.';
    }
    
    /**
     * Handle FIND/SEARCH operation
     */
    private static void handleFindSearch(
        Request req,
        Response res,
        String objectApiName,
        Map<String, Schema.SObjectField> fieldMap
    ) {
        Integer limitToUse = normalizeLimit(req.searchLimit);
        
        // Build base query - include related object names for Task
        String selectClause = String.join(new List<String>(fieldMap.keySet()), ', ');
        if (objectApiName.toLowerCase() == 'task') {
            selectClause += ', What.Name, Who.Name';
        }
        else if (objectApiName.toLowerCase() == 'customerorders__c') {
            selectClause += ', Account__r.Name, Contact__r.Name';
        }
        else if (objectApiName.toLowerCase() == 'diagnostic_test_order__c') {
            selectClause += ', Account__r.Name, Contact__r.Name, Contact__r.Email';
        }
        String soql = 'SELECT ' + selectClause + ' FROM ' + objectApiName;
        
        // Build WHERE clause
        List<String> whereClauses = new List<String>();
        
        // Add filter conditions - check filtersJson first (for AI agent compatibility), then filters
        List<Filter> normalizedFilters = new List<Filter>();
        
        // If filtersJson is provided, parse it (handles both single object and array)
        if (!String.isBlank(req.filtersJson)) {
            System.debug(LoggingLevel.INFO, 'AFUniversalCrmRecordAction: Parsing filtersJson: ' + req.filtersJson);
            normalizedFilters = parseFiltersJson(req.filtersJson);
        } else if (req.filters != null) {
            // Fall back to filters field if filtersJson is not provided
            System.debug(LoggingLevel.INFO, 'AFUniversalCrmRecordAction: Raw filters input: ' + req.filters);
            normalizedFilters = normalizeFilters(req.filters);
        }
        
        System.debug(LoggingLevel.INFO, 'AFUniversalCrmRecordAction: Normalized filters count: ' + (normalizedFilters != null ? normalizedFilters.size() : 0));
        
        // Handle special filters for Task (open tasks only)
        Boolean addOpenTasksFilter = false;
        if (objectApiName.toLowerCase() == 'task' && normalizedFilters != null) {
            for (Integer i = normalizedFilters.size() - 1; i >= 0; i--) {
                if (normalizedFilters[i].fieldApiName == '_openTasksOnly') {
                    addOpenTasksFilter = true;
                    normalizedFilters.remove(i);
                }
            }
        }
        
        if (normalizedFilters != null && !normalizedFilters.isEmpty()) {
            whereClauses.addAll(buildFilterConditions(normalizedFilters, fieldMap));
        }
        
        // Add open tasks filter if requested
        if (addOpenTasksFilter) {
            whereClauses.add('(Status != \'Completed\' AND Status != \'Deferred\')');
        }
        
        // Add search term conditions
        if (!String.isBlank(req.searchTerm)) {
            String searchClause = buildSearchConditions(objectApiName, req.searchTerm, fieldMap);
            if (!String.isBlank(searchClause)) {
                whereClauses.add('(' + searchClause + ')');
            }
        }
        
        // Filter by accountName for CustomerOrders__c
        if (objectApiName.toLowerCase() == 'customerorders__c' && !String.isBlank(req.accountName)) {
            try {
                Id accountId = resolveAccountByName(req.accountName);
                if (accountId != null) {
                    String escapedAccountId = String.escapeSingleQuotes(String.valueOf(accountId));
                    whereClauses.add('Account__c = \'' + escapedAccountId + '\'');
                }
            } catch (Exception e) {
                System.debug(LoggingLevel.WARN, 'AFUniversalCrmRecordAction: Could not resolve account name for filter: ' + e.getMessage());
            }
        }
        
        // Filter by contactNameOrEmail for CustomerOrders__c
        if (objectApiName.toLowerCase() == 'customerorders__c' && !String.isBlank(req.contactNameOrEmail)) {
            try {
                Id contactId = resolveContactByNameOrEmail(req.contactNameOrEmail, req.accountName);
                if (contactId != null) {
                    String escapedContactId = String.escapeSingleQuotes(String.valueOf(contactId));
                    whereClauses.add('Contact__c = \'' + escapedContactId + '\'');
                }
            } catch (Exception e) {
                System.debug(LoggingLevel.WARN, 'AFUniversalCrmRecordAction: Could not resolve contact name for filter: ' + e.getMessage());
            }
        }
        
        // Assemble query
        if (!whereClauses.isEmpty()) {
            soql += ' WHERE ' + String.join(whereClauses, ' AND ');
        }
        
        soql += ' ORDER BY LastModifiedDate DESC';
        soql += ' LIMIT ' + limitToUse;
        
        System.debug(LoggingLevel.INFO, 'AFUniversalCrmRecordAction: Executing SOQL: ' + soql);
        
        // Execute query
        List<SObject> foundRecords = Database.query(soql);
        
        System.debug(LoggingLevel.INFO, 'AFUniversalCrmRecordAction: Query returned ' + foundRecords.size() + ' records');
        
        // Populate response
        res.records = foundRecords;
        res.totalMatches = foundRecords.size();
        res.ambiguous = (foundRecords.size() > 1);
        
        if (foundRecords.isEmpty()) {
            res.message = 'No ' + objectApiName + ' records found matching the criteria. Ask the user for more specific information.';
        } else if (foundRecords.size() == 1) {
            res.record = foundRecords[0];
            res.recordId = (Id) foundRecords[0].get('Id');
            res.message = 'Found exactly one matching ' + objectApiName + ' record.';
            
            // Populate related object names for Task
            if (objectApiName.toLowerCase() == 'task') {
                populateTaskRelatedNames(res, (Task) foundRecords[0]);
            }
        } else {
            // Multiple matches - provide guidance on what additional information would help
            String additionalInfo = getAdditionalInfoGuidance(objectApiName, fieldMap);
            res.message = 'Found ' + foundRecords.size() + ' matching ' + objectApiName + 
                         ' records. Please provide more details to narrow down the selection, such as: ' + additionalInfo + 
                         '. Or present the options for the user to choose from.';
        }
    }
    
    /**
     * Handle BULK CREATE operation
     */
    private static void handleBulkCreate(
        Request req,
        Response res,
        Schema.SObjectType sType,
        Map<String, Schema.SObjectField> fieldMap
    ) {
        if (String.isBlank(req.bulkRecordsJson)) {
            throw new ActionException('bulkRecordsJson is required for bulkCreate operation. Provide a JSON array of record objects.');
        }
        
        List<Object> recordDataList = parseBulkRecordsJson(req.bulkRecordsJson);
        
        if (recordDataList.isEmpty()) {
            throw new ActionException('bulkRecordsJson must contain at least one record.');
        }
        
        List<SObject> recordsToInsert = new List<SObject>();
        List<BulkRecordError> validationErrors = new List<BulkRecordError>();
        Map<Integer, Integer> insertIndexToOriginalIndex = new Map<Integer, Integer>();
        
        // Validate and prepare each record
        for (Integer i = 0; i < recordDataList.size(); i++) {
            Object recordDataObj = recordDataList[i];
            
            if (!(recordDataObj instanceof Map<String, Object>)) {
                BulkRecordError err = new BulkRecordError();
                err.recordIndex = i;
                err.errorMessage = 'Invalid record format. Each record must be a JSON object.';
                err.recordData = String.valueOf(recordDataObj);
                validationErrors.add(err);
                continue;
            }
            
            Map<String, Object> fieldDataMap = (Map<String, Object>) recordDataObj;
            
            try {
                // Resolve related records for bulk - may throw AmbiguousRelationshipException
                try {
                    resolveRelatedRecordsForBulk(req.objectApiName, fieldDataMap);
                } catch (AmbiguousRelationshipException are) {
                    // For bulk operations, add as validation error with candidate details
                    BulkRecordError err = new BulkRecordError();
                    err.recordIndex = i;
                    err.errorMessage = 'Ambiguous ' + are.relationshipType + ': Multiple matches for "' + are.searchCriteria + '". ' +
                                      'Candidates: ' + JSON.serialize(are.candidates).left(500) + '... Please specify using email, phone, or company.';
                    err.recordData = JSON.serialize(fieldDataMap);
                    validationErrors.add(err);
                    continue;
                }
                
                // Enforce required fields
                enforceCreateRequirements(req.objectApiName, fieldDataMap);
                
                // Validate picklist values
                validatePicklistValues(fieldDataMap, fieldMap);
                
                // Create and populate the record
                SObject record = sType.newSObject();
                applyFieldData(record, fieldMap, fieldDataMap);
                
                insertIndexToOriginalIndex.put(recordsToInsert.size(), i);
                recordsToInsert.add(record);
                
            } catch (Exception e) {
                BulkRecordError err = new BulkRecordError();
                err.recordIndex = i;
                err.errorMessage = e.getMessage();
                err.recordData = JSON.serialize(fieldDataMap);
                validationErrors.add(err);
            }
        }
        
        // Perform bulk insert with partial success
        List<Id> successIds = new List<Id>();
        List<BulkRecordError> dmlErrors = new List<BulkRecordError>();
        
        if (!recordsToInsert.isEmpty()) {
            Database.SaveResult[] saveResults = Database.insert(recordsToInsert, false);
            
            for (Integer i = 0; i < saveResults.size(); i++) {
                Database.SaveResult sr = saveResults[i];
                Integer originalIndex = insertIndexToOriginalIndex.get(i);
                
                if (sr.isSuccess()) {
                    successIds.add(sr.getId());
                } else {
                    BulkRecordError err = new BulkRecordError();
                    err.recordIndex = originalIndex;
                    err.errorMessage = sr.getErrors()[0].getMessage();
                    err.recordData = JSON.serialize(recordsToInsert[i]);
                    dmlErrors.add(err);
                }
            }
        }
        
        // Combine all errors
        List<BulkRecordError> allErrors = new List<BulkRecordError>();
        allErrors.addAll(validationErrors);
        allErrors.addAll(dmlErrors);
        
        // Populate response
        res.successCount = successIds.size();
        res.failureCount = allErrors.size();
        res.successRecordIds = successIds;
        res.errors = allErrors;
        
        if (allErrors.isEmpty()) {
            res.message = 'Successfully created ' + successIds.size() + ' ' + req.objectApiName + ' record(s).';
        } else if (successIds.isEmpty()) {
            res.message = 'All ' + recordDataList.size() + ' records failed to create. Check errors for details.';
            res.success = false;
        } else {
            res.message = 'Partially successful: ' + successIds.size() + ' record(s) created, ' + allErrors.size() + ' failed. Check errors for details.';
        }
    }
    
    /**
     * Handle BULK UPDATE operation
     */
    private static void handleBulkUpdate(
        Request req,
        Response res,
        Schema.SObjectType sType,
        Map<String, Schema.SObjectField> fieldMap
    ) {
        if (String.isBlank(req.bulkRecordsJson)) {
            throw new ActionException('bulkRecordsJson is required for bulkUpdate operation. Provide a JSON array of record objects with Id field.');
        }
        
        List<Object> recordDataList = parseBulkRecordsJson(req.bulkRecordsJson);
        
        if (recordDataList.isEmpty()) {
            throw new ActionException('bulkRecordsJson must contain at least one record.');
        }
        
        List<SObject> recordsToUpdate = new List<SObject>();
        List<BulkRecordError> validationErrors = new List<BulkRecordError>();
        Map<Integer, Integer> updateIndexToOriginalIndex = new Map<Integer, Integer>();
        
        // Validate and prepare each record
        for (Integer i = 0; i < recordDataList.size(); i++) {
            Object recordDataObj = recordDataList[i];
            
            if (!(recordDataObj instanceof Map<String, Object>)) {
                BulkRecordError err = new BulkRecordError();
                err.recordIndex = i;
                err.errorMessage = 'Invalid record format. Each record must be a JSON object.';
                err.recordData = String.valueOf(recordDataObj);
                validationErrors.add(err);
                continue;
            }
            
            Map<String, Object> fieldDataMap = (Map<String, Object>) recordDataObj;
            
            try {
                // Check for Id field or resolve by name
                Id recordId = null;
                
                if (fieldDataMap.containsKey('Id') && !String.isBlank(String.valueOf(fieldDataMap.get('Id')))) {
                    recordId = (Id) fieldDataMap.get('Id');
                    fieldDataMap.remove('Id'); // Remove Id from field data since we pass it separately
                } else {
                    // Try name-based resolution
                    AFUniversalCrmRecordAction.Request tempReq = new AFUniversalCrmRecordAction.Request();
                    tempReq.objectApiName = req.objectApiName;
                    recordId = resolveRecordIdForUpdate(tempReq, fieldDataMap);
                    
                    if (recordId == null) {
                        throw new ActionException('Each record must include an Id field OR a Name field (Account/Opportunity) or LastName field (Contact) for name-based resolution.');
                    }
                }
                
                // Resolve related records for bulk - may throw AmbiguousRelationshipException
                try {
                    resolveRelatedRecordsForBulk(req.objectApiName, fieldDataMap);
                } catch (AmbiguousRelationshipException are) {
                    // For bulk operations, add as validation error with candidate details
                    BulkRecordError err = new BulkRecordError();
                    err.recordIndex = i;
                    err.errorMessage = 'Ambiguous ' + are.relationshipType + ': Multiple matches for "' + are.searchCriteria + '". ' +
                                      'Candidates: ' + JSON.serialize(are.candidates).left(500) + '... Please specify using email, phone, or company.';
                    err.recordData = JSON.serialize(fieldDataMap);
                    validationErrors.add(err);
                    continue;
                }
                
                // Validate picklist values
                validatePicklistValues(fieldDataMap, fieldMap);
                
                // Create record stub with ID and apply changes
                SObject record = sType.newSObject(recordId);
                applyFieldData(record, fieldMap, fieldDataMap);
                
                updateIndexToOriginalIndex.put(recordsToUpdate.size(), i);
                recordsToUpdate.add(record);
                
            } catch (Exception e) {
                BulkRecordError err = new BulkRecordError();
                err.recordIndex = i;
                err.errorMessage = e.getMessage();
                err.recordData = JSON.serialize(fieldDataMap);
                validationErrors.add(err);
            }
        }
        
        // Perform bulk update with partial success
        List<Id> successIds = new List<Id>();
        List<BulkRecordError> dmlErrors = new List<BulkRecordError>();
        
        if (!recordsToUpdate.isEmpty()) {
            Database.SaveResult[] saveResults = Database.update(recordsToUpdate, false);
            
            for (Integer i = 0; i < saveResults.size(); i++) {
                Database.SaveResult sr = saveResults[i];
                Integer originalIndex = updateIndexToOriginalIndex.get(i);
                
                if (sr.isSuccess()) {
                    successIds.add(sr.getId());
                } else {
                    BulkRecordError err = new BulkRecordError();
                    err.recordIndex = originalIndex;
                    err.errorMessage = sr.getErrors()[0].getMessage();
                    err.recordData = JSON.serialize(recordsToUpdate[i]);
                    dmlErrors.add(err);
                }
            }
        }
        
        // Combine all errors
        List<BulkRecordError> allErrors = new List<BulkRecordError>();
        allErrors.addAll(validationErrors);
        allErrors.addAll(dmlErrors);
        
        // Populate response
        res.successCount = successIds.size();
        res.failureCount = allErrors.size();
        res.successRecordIds = successIds;
        res.errors = allErrors;
        
        if (allErrors.isEmpty()) {
            res.message = 'Successfully updated ' + successIds.size() + ' ' + req.objectApiName + ' record(s).';
        } else if (successIds.isEmpty()) {
            res.message = 'All ' + recordDataList.size() + ' records failed to update. Check errors for details.';
            res.success = false;
        } else {
            res.message = 'Partially successful: ' + successIds.size() + ' record(s) updated, ' + allErrors.size() + ' failed. Check errors for details.';
        }
    }
    
    /**
     * Parse bulk records JSON string into list of objects
     */
    private static List<Object> parseBulkRecordsJson(String jsonString) {
        try {
            Object parsed = JSON.deserializeUntyped(jsonString);
            
            if (parsed instanceof List<Object>) {
                return (List<Object>) parsed;
            } else {
                throw new ActionException('bulkRecordsJson must be a JSON array, e.g., [{"Name":"Acme"},{"Name":"Globex"}]');
            }
        } catch (JSONException je) {
            throw new ActionException('Invalid JSON in bulkRecordsJson: ' + je.getMessage());
        }
    }
    
    /**
     * Resolve related records (accountName, contactNameOrEmail) to IDs
     * Used for single create/update operations
     */
    private static void resolveRelatedRecords(Request req, Map<String, Object> fieldDataMap) {
        String obj = req.objectApiName.toLowerCase();
        
        // Resolve Account for Contact, Case, or Opportunity
        if ((obj == 'contact' || obj == 'case' || obj == 'opportunity') && !String.isBlank(req.accountName)) {
            Id accountId = resolveAccountByName(req.accountName);
            fieldDataMap.put('AccountId', accountId);
        }
        
        // Resolve Contact for Case
        if (obj == 'case' && !String.isBlank(req.contactNameOrEmail)) {
            Id contactId = resolveContactByNameOrEmail(req.contactNameOrEmail, req.accountName);
            fieldDataMap.put('ContactId', contactId);
        }
        
        // Resolve WhatId (Account) for Task
        if (obj == 'task' && !String.isBlank(req.accountName)) {
            Id accountId = resolveAccountByName(req.accountName);
            fieldDataMap.put('WhatId', accountId);
        }
        
        // Resolve WhoId (Contact) for Task
        if (obj == 'task' && !String.isBlank(req.contactNameOrEmail)) {
            Id contactId = resolveContactByNameOrEmail(req.contactNameOrEmail, req.accountName);
            fieldDataMap.put('WhoId', contactId);
        }
        
        // Resolve Contact__c for Meeting__c
        if (obj == 'meeting__c' && !String.isBlank(req.contactNameOrEmail)) {
            Id contactId = resolveContactByNameOrEmail(req.contactNameOrEmail, req.accountName);
            fieldDataMap.put('Contact__c', contactId);
        }
        
        // Resolve Account__c for Meeting__c
        if (obj == 'meeting__c' && !String.isBlank(req.accountName)) {
            Id accountId = resolveAccountByName(req.accountName);
            fieldDataMap.put('Account__c', accountId);
        }
        
        // Resolve Contact__c for CustomerOrders__c
        if (obj == 'customerorders__c' && !String.isBlank(req.contactNameOrEmail)) {
            Id contactId = resolveContactByNameOrEmail(req.contactNameOrEmail, req.accountName);
            fieldDataMap.put('Contact__c', contactId);
        }
        
        // Resolve Account__c for CustomerOrders__c
        if (obj == 'customerorders__c' && !String.isBlank(req.accountName)) {
            Id accountId = resolveAccountByName(req.accountName);
            fieldDataMap.put('Account__c', accountId);
        }
    }
    
    /**
     * Resolve related records for bulk operations
     * Looks for special fields: _accountName, _contactNameOrEmail
     */
    private static void resolveRelatedRecordsForBulk(String objectApiName, Map<String, Object> fieldDataMap) {
        String obj = objectApiName.toLowerCase();
        
        // Resolve Account for Contact, Case, or Opportunity
        if ((obj == 'contact' || obj == 'case' || obj == 'opportunity') && fieldDataMap.containsKey('_accountName')) {
            String accountName = String.valueOf(fieldDataMap.get('_accountName'));
            fieldDataMap.remove('_accountName');
            
            if (!String.isBlank(accountName)) {
                Id accountId = resolveAccountByName(accountName);
                fieldDataMap.put('AccountId', accountId);
            }
        }
        
        // Resolve Contact for Case
        if (obj == 'case' && fieldDataMap.containsKey('_contactNameOrEmail')) {
            String contactNameOrEmail = String.valueOf(fieldDataMap.get('_contactNameOrEmail'));
            fieldDataMap.remove('_contactNameOrEmail');
            
            // Check if accountName is also provided for scoping
            String accountNameForScope = null;
            if (fieldDataMap.containsKey('_accountName')) {
                accountNameForScope = String.valueOf(fieldDataMap.get('_accountName'));
            }
            
            if (!String.isBlank(contactNameOrEmail)) {
                Id contactId = resolveContactByNameOrEmail(contactNameOrEmail, accountNameForScope);
                fieldDataMap.put('ContactId', contactId);
            }
        }
        
        // Resolve WhatId (Account) for Task
        if (obj == 'task' && fieldDataMap.containsKey('_accountName')) {
            String accountName = String.valueOf(fieldDataMap.get('_accountName'));
            fieldDataMap.remove('_accountName');
            
            if (!String.isBlank(accountName)) {
                Id accountId = resolveAccountByName(accountName);
                fieldDataMap.put('WhatId', accountId);
            }
        }
        
        // Resolve WhoId (Contact) for Task
        if (obj == 'task' && fieldDataMap.containsKey('_contactNameOrEmail')) {
            String contactNameOrEmail = String.valueOf(fieldDataMap.get('_contactNameOrEmail'));
            fieldDataMap.remove('_contactNameOrEmail');
            
            // Check if accountName is also provided for scoping (WhatId)
            String accountNameForScope = null;
            if (fieldDataMap.containsKey('_accountName')) {
                accountNameForScope = String.valueOf(fieldDataMap.get('_accountName'));
            }
            
            if (!String.isBlank(contactNameOrEmail)) {
                Id contactId = resolveContactByNameOrEmail(contactNameOrEmail, accountNameForScope);
                fieldDataMap.put('WhoId', contactId);
            }
        }
        
        // Resolve Contact__c for Meeting__c
        if (obj == 'meeting__c' && fieldDataMap.containsKey('_contactNameOrEmail')) {
            String contactNameOrEmail = String.valueOf(fieldDataMap.get('_contactNameOrEmail'));
            fieldDataMap.remove('_contactNameOrEmail');
            
            // Check if accountName is also provided for scoping (Account__c)
            String accountNameForScope = null;
            if (fieldDataMap.containsKey('_accountName')) {
                accountNameForScope = String.valueOf(fieldDataMap.get('_accountName'));
            }
            
            if (!String.isBlank(contactNameOrEmail)) {
                Id contactId = resolveContactByNameOrEmail(contactNameOrEmail, accountNameForScope);
                fieldDataMap.put('Contact__c', contactId);
            }
        }
        
        // Resolve Account__c for Meeting__c
        if (obj == 'meeting__c' && fieldDataMap.containsKey('_accountName')) {
            String accountName = String.valueOf(fieldDataMap.get('_accountName'));
            fieldDataMap.remove('_accountName');
            
            if (!String.isBlank(accountName)) {
                Id accountId = resolveAccountByName(accountName);
                fieldDataMap.put('Account__c', accountId);
            }
        }
        
        // Resolve Contact__c for CustomerOrders__c
        if (obj == 'customerorders__c' && fieldDataMap.containsKey('_contactNameOrEmail')) {
            String contactNameOrEmail = String.valueOf(fieldDataMap.get('_contactNameOrEmail'));
            fieldDataMap.remove('_contactNameOrEmail');
            
            // Check if accountName is also provided for scoping
            String accountNameForScope = null;
            if (fieldDataMap.containsKey('_accountName')) {
                accountNameForScope = String.valueOf(fieldDataMap.get('_accountName'));
            }
            
            if (!String.isBlank(contactNameOrEmail)) {
                Id contactId = resolveContactByNameOrEmail(contactNameOrEmail, accountNameForScope);
                fieldDataMap.put('Contact__c', contactId);
            }
        }
        
        // Resolve Account__c for CustomerOrders__c
        if (obj == 'customerorders__c' && fieldDataMap.containsKey('_accountName')) {
            String accountName = String.valueOf(fieldDataMap.get('_accountName'));
            fieldDataMap.remove('_accountName');
            
            if (!String.isBlank(accountName)) {
                Id accountId = resolveAccountByName(accountName);
                fieldDataMap.put('Account__c', accountId);
            }
        }
    }
    
    /**
     * Resolve Account by name - returns most recently modified if multiple matches
     * Throws MissingParentException with field metadata if not found
     */
    private static Id resolveAccountByName(String accountName) {
        // Check if input is already a Salesforce ID (15 or 18 characters starting with 001)
        if (accountName != null && (accountName.length() == 15 || accountName.length() == 18)) {
            try {
                Id accountId = Id.valueOf(accountName);
                // Verify it's an Account ID (starts with 001)
                if (String.valueOf(accountId).startsWith('001')) {
                    // Verify the account exists
                    List<Account> existingAccount = [
                        SELECT Id FROM Account WHERE Id = :accountId LIMIT 1
                    ];
                    if (!existingAccount.isEmpty()) {
                        System.debug(LoggingLevel.INFO, 'AFUniversalCrmRecordAction: Input was already a valid Account ID: ' + accountId);
                        return accountId;
                    }
                }
            } catch (Exception e) {
                // Not a valid ID, continue with name lookup
                System.debug(LoggingLevel.DEBUG, 'AFUniversalCrmRecordAction: Input not a valid Account ID, treating as name: ' + accountName);
            }
        }
        
        String escapedName = String.escapeSingleQuotes(accountName);
        
        // Query for up to 6 matches to detect ambiguity (limit 5 for candidates + 1 to know if more exist)
        // Try exact match first
        List<Account> accounts = [
            SELECT Id, Name, BillingCity, BillingState, Phone, Industry
            FROM Account 
            WHERE Name = :accountName 
            ORDER BY LastModifiedDate DESC 
            LIMIT 6
        ];
        
        // FALLBACK: If no exact match, try fuzzy match with LIKE
        if (accounts.isEmpty()) {
            System.debug(LoggingLevel.INFO, 'AFUniversalCrmRecordAction: No exact account match, trying fuzzy match for: ' + accountName);
            String likePattern = '%' + escapedName + '%';
            accounts = [
                SELECT Id, Name, BillingCity, BillingState, Phone, Industry
                FROM Account 
                WHERE Name LIKE :likePattern 
                ORDER BY LastModifiedDate DESC 
                LIMIT 6
            ];
        }
        
        if (accounts.isEmpty()) {
            // Get field metadata for Account
            Map<String, List<String>> fieldMetadata = getObjectFieldMetadata('Account');
            throw new MissingParentException('Account', accountName, fieldMetadata.get('required'), fieldMetadata.get('optional'));
        }
        
        // If multiple matches found, throw ambiguity exception
        if (accounts.size() > 1) {
            List<Map<String, Object>> candidates = new List<Map<String, Object>>();
            Integer candidateCount = Math.min(5, accounts.size());
            
            for (Integer i = 0; i < candidateCount; i++) {
                Account acc = accounts[i];
                Map<String, Object> candidate = new Map<String, Object>();
                candidate.put('Id', acc.Id);
                candidate.put('Name', acc.Name);
                candidate.put('BillingCity', acc.BillingCity);
                candidate.put('BillingState', acc.BillingState);
                candidate.put('Phone', acc.Phone);
                candidate.put('Industry', acc.Industry);
                candidates.add(candidate);
            }
            
            throw new AmbiguousRelationshipException('Account', accountName, candidates);
        }
        
        return accounts[0].Id;
    }
    
    /**
     * Resolve Contact by name or email with optional Account scope
     * Overloaded version that accepts account name to narrow down contact search
     */
    private static Id resolveContactByNameOrEmail(String nameOrEmail, String accountName) {
        // Check if input is already a Salesforce ID (15 or 18 characters starting with 003)
        if (nameOrEmail != null && (nameOrEmail.length() == 15 || nameOrEmail.length() == 18)) {
            try {
                Id contactId = Id.valueOf(nameOrEmail);
                if (String.valueOf(contactId).startsWith('003')) {
                    List<Contact> existingContact = [
                        SELECT Id FROM Contact WHERE Id = :contactId LIMIT 1
                    ];
                    if (!existingContact.isEmpty()) {
                        System.debug(LoggingLevel.INFO, 'AFUniversalCrmRecordAction: Input was already a valid Contact ID: ' + contactId);
                        return contactId;
                    }
                }
            } catch (Exception e) {
                System.debug(LoggingLevel.DEBUG, 'AFUniversalCrmRecordAction: Input not a valid Contact ID: ' + nameOrEmail);
            }
        }
        
        String searchTerm = String.escapeSingleQuotes(nameOrEmail);
        String accountSearchTerm = !String.isBlank(accountName) ? String.escapeSingleQuotes(accountName) : null;
        
        // Try email first (more specific)
        List<Contact> contacts;
        if (!String.isBlank(accountSearchTerm)) {
            // Search with account filter
            String accountLikePattern = '%' + accountSearchTerm + '%';
            contacts = [
                SELECT Id, Name, Email, Phone, Account.Name, Title, Department
                FROM Contact 
                WHERE Email = :nameOrEmail 
                  AND Account.Name LIKE :accountLikePattern
                ORDER BY LastModifiedDate DESC 
                LIMIT 2
            ];
        } else {
            contacts = [
                SELECT Id, Name, Email, Phone, Account.Name, Title, Department
                FROM Contact 
                WHERE Email = :nameOrEmail 
                ORDER BY LastModifiedDate DESC 
                LIMIT 2
            ];
        }
        
        if (!contacts.isEmpty()) {
            if (contacts.size() > 1) {
                List<Map<String, Object>> candidates = new List<Map<String, Object>>();
                for (Contact con : contacts) {
                    Map<String, Object> candidate = new Map<String, Object>();
                    candidate.put('Id', con.Id);
                    candidate.put('Name', con.Name);
                    candidate.put('Email', con.Email);
                    candidate.put('Phone', con.Phone);
                    candidate.put('AccountName', con.Account != null ? con.Account.Name : null);
                    candidate.put('Title', con.Title);
                    candidate.put('Department', con.Department);
                    candidates.add(candidate);
                }
                throw new AmbiguousRelationshipException('Contact', nameOrEmail, candidates);
            }
            return contacts[0].Id;
        }
        
        // Try name match with optional account filter
        String likePattern = '%' + searchTerm + '%';
        if (!String.isBlank(accountSearchTerm)) {
            // Search with account filter first
            String accountLikePattern = '%' + accountSearchTerm + '%';
            contacts = [
                SELECT Id, Name, Email, Phone, Account.Name, Title, Department
                FROM Contact 
                WHERE (Name LIKE :likePattern
                   OR FirstName LIKE :likePattern
                   OR LastName LIKE :likePattern)
                  AND Account.Name LIKE :accountLikePattern
                ORDER BY LastModifiedDate DESC 
                LIMIT 6
            ];
            
            // FALLBACK: If no contact found at specified account, search without account filter
            // This handles cases where user mentions meeting at Account A with Contact from Account B
            if (contacts.isEmpty()) {
                System.debug(LoggingLevel.INFO, 'AFUniversalCrmRecordAction: Contact not found at specified account, searching without account filter');
                contacts = [
                    SELECT Id, Name, Email, Phone, Account.Name, Title, Department
                    FROM Contact 
                    WHERE Name LIKE :likePattern
                       OR FirstName LIKE :likePattern
                       OR LastName LIKE :likePattern
                    ORDER BY LastModifiedDate DESC 
                    LIMIT 6
                ];
            }
        } else {
            contacts = [
                SELECT Id, Name, Email, Phone, Account.Name, Title, Department
                FROM Contact 
                WHERE Name LIKE :likePattern
                   OR FirstName LIKE :likePattern
                   OR LastName LIKE :likePattern
                ORDER BY LastModifiedDate DESC 
                LIMIT 6
            ];
        }
        
        if (contacts.isEmpty()) {
            Map<String, List<String>> fieldMetadata = getObjectFieldMetadata('Contact');
            String searchContext = !String.isBlank(accountSearchTerm) ? nameOrEmail + ' (Account: ' + accountName + ')' : nameOrEmail;
            throw new MissingParentException('Contact', searchContext, fieldMetadata.get('required'), fieldMetadata.get('optional'));
        }
        
        if (contacts.size() > 1) {
            List<Map<String, Object>> candidates = new List<Map<String, Object>>();
            Integer candidateCount = Math.min(5, contacts.size());
            
            for (Integer i = 0; i < candidateCount; i++) {
                Contact con = contacts[i];
                Map<String, Object> candidate = new Map<String, Object>();
                candidate.put('Id', con.Id);
                candidate.put('Name', con.Name);
                candidate.put('Email', con.Email);
                candidate.put('Phone', con.Phone);
                candidate.put('AccountName', con.Account != null ? con.Account.Name : null);
                candidate.put('Title', con.Title);
                candidate.put('Department', con.Department);
                candidates.add(candidate);
            }
            
            throw new AmbiguousRelationshipException('Contact', nameOrEmail, candidates);
        }
        
        return contacts[0].Id;
    }
    
    /**
     * Resolve Contact by name or email - returns most recently modified if multiple matches
     */
    private static Id resolveContactByNameOrEmail(String nameOrEmail) {
        // Check if input is already a Salesforce ID (15 or 18 characters starting with 003)
        if (nameOrEmail != null && (nameOrEmail.length() == 15 || nameOrEmail.length() == 18)) {
            try {
                Id contactId = Id.valueOf(nameOrEmail);
                // Verify it's a Contact ID (starts with 003)
                if (String.valueOf(contactId).startsWith('003')) {
                    // Verify the contact exists
                    List<Contact> existingContact = [
                        SELECT Id FROM Contact WHERE Id = :contactId LIMIT 1
                    ];
                    if (!existingContact.isEmpty()) {
                        System.debug(LoggingLevel.INFO, 'AFUniversalCrmRecordAction: Input was already a valid Contact ID: ' + contactId);
                        return contactId;
                    }
                }
            } catch (Exception e) {
                // Not a valid ID, continue with name/email lookup
                System.debug(LoggingLevel.DEBUG, 'AFUniversalCrmRecordAction: Input not a valid Contact ID, treating as name/email: ' + nameOrEmail);
            }
        }
        
        String searchTerm = String.escapeSingleQuotes(nameOrEmail);
        
        // Try email first (more specific) - should be unique
        List<Contact> contacts = [
            SELECT Id, Name, Email, Phone, Account.Name, Title, Department
            FROM Contact 
            WHERE Email = :nameOrEmail 
            ORDER BY LastModifiedDate DESC 
            LIMIT 2
        ];
        
        if (!contacts.isEmpty()) {
            // Email match should be unique, but check for duplicates
            if (contacts.size() > 1) {
                List<Map<String, Object>> candidates = new List<Map<String, Object>>();
                for (Contact con : contacts) {
                    Map<String, Object> candidate = new Map<String, Object>();
                    candidate.put('Id', con.Id);
                    candidate.put('Name', con.Name);
                    candidate.put('Email', con.Email);
                    candidate.put('Phone', con.Phone);
                    candidate.put('AccountName', con.Account != null ? con.Account.Name : null);
                    candidate.put('Title', con.Title);
                    candidate.put('Department', con.Department);
                    candidates.add(candidate);
                }
                throw new AmbiguousRelationshipException('Contact', nameOrEmail, candidates);
            }
            return contacts[0].Id;
        }
        
        // Try name match (could be first name, last name, or full name)
        String likePattern = '%' + searchTerm + '%';
        contacts = [
            SELECT Id, Name, Email, Phone, Account.Name, Title, Department
            FROM Contact 
            WHERE Name LIKE :likePattern
               OR FirstName LIKE :likePattern
               OR LastName LIKE :likePattern
            ORDER BY LastModifiedDate DESC 
            LIMIT 6
        ];
        
        if (contacts.isEmpty()) {
            // Get field metadata for Contact
            Map<String, List<String>> fieldMetadata = getObjectFieldMetadata('Contact');
            throw new MissingParentException('Contact', nameOrEmail, fieldMetadata.get('required'), fieldMetadata.get('optional'));
        }
        
        // If multiple name matches found, throw ambiguity exception
        if (contacts.size() > 1) {
            List<Map<String, Object>> candidates = new List<Map<String, Object>>();
            Integer candidateCount = Math.min(5, contacts.size());
            
            for (Integer i = 0; i < candidateCount; i++) {
                Contact con = contacts[i];
                Map<String, Object> candidate = new Map<String, Object>();
                candidate.put('Id', con.Id);
                candidate.put('Name', con.Name);
                candidate.put('Email', con.Email);
                candidate.put('Phone', con.Phone);
                candidate.put('AccountName', con.Account != null ? con.Account.Name : null);
                candidate.put('Title', con.Title);
                candidate.put('Department', con.Department);
                candidates.add(candidate);
            }
            
            throw new AmbiguousRelationshipException('Contact', nameOrEmail, candidates);
        }
        
        return contacts[0].Id;
    }
    
    /**
     * Validate picklist field values
     */
    private static void validatePicklistValues(
        Map<String, Object> fieldDataMap,
        Map<String, Schema.SObjectField> fieldMap
    ) {
        for (String apiName : fieldDataMap.keySet()) {
            if (!fieldMap.containsKey(apiName)) {
                continue;
            }
            
            Schema.DescribeFieldResult fieldDescribe = fieldMap.get(apiName).getDescribe();
            Schema.DisplayType fieldType = fieldDescribe.getType();
            
            // Check if it's a picklist or multipicklist
            if (fieldType == Schema.DisplayType.PICKLIST || fieldType == Schema.DisplayType.MULTIPICKLIST) {
                Object value = fieldDataMap.get(apiName);
                
                if (value == null) {
                    continue;
                }
                
                String strValue = String.valueOf(value);
                
                if (String.isBlank(strValue)) {
                    continue;
                }
                
                // Get valid picklist values
                Set<String> validValues = new Set<String>();
                for (Schema.PicklistEntry ple : fieldDescribe.getPicklistValues()) {
                    if (ple.isActive()) {
                        validValues.add(ple.getValue());
                    }
                }
                
                // For multipicklist, check each value
                if (fieldType == Schema.DisplayType.MULTIPICKLIST) {
                    List<String> selectedValues = strValue.split(';');
                    for (String sv : selectedValues) {
                        String trimmedValue = sv.trim();
                        if (!validValues.contains(trimmedValue)) {
                            throw new ActionException(
                                'Invalid value "' + trimmedValue + '" for picklist field ' + apiName + 
                                '. Valid values are: ' + String.join(new List<String>(validValues), ', ')
                            );
                        }
                    }
                } else {
                    // Single picklist
                    if (!validValues.contains(strValue)) {
                        throw new ActionException(
                            'Invalid value "' + strValue + '" for picklist field ' + apiName + 
                            '. Valid values are: ' + String.join(new List<String>(validValues), ', ')
                        );
                    }
                }
            }
        }
    }
    
    /**
     * Normalize fieldData to handle deserialization issues from JSON
     * Handles cases where fieldData might be a single object, a list, or null
     */
    private static List<FieldValue> normalizeFieldData(Object fieldData) {
        if (fieldData == null) {
            return new List<FieldValue>();
        }
        
        // Already a List<FieldValue>
        if (fieldData instanceof List<FieldValue>) {
            return (List<FieldValue>) fieldData;
        }
        
        // Single FieldValue object
        if (fieldData instanceof FieldValue) {
            return new List<FieldValue>{ (FieldValue) fieldData };
        }
        
        // Handle Map<String, Object> from JSON deserialization (when single object passed instead of array)
        if (fieldData instanceof Map<String, Object>) {
            Map<String, Object> fieldDataMap = (Map<String, Object>) fieldData;
            FieldValue fv = new FieldValue();
            if (fieldDataMap.containsKey('fieldApiName')) {
                fv.fieldApiName = String.valueOf(fieldDataMap.get('fieldApiName'));
            }
            if (fieldDataMap.containsKey('value')) {
                fv.value = String.valueOf(fieldDataMap.get('value'));
            }
            if (!String.isBlank(fv.fieldApiName)) {
                return new List<FieldValue>{ fv };
            }
        }
        
        // If we can't normalize it, return empty list
        System.debug(LoggingLevel.WARN, 'UniversalCrmRecordAction: Could not normalize fieldData: ' + fieldData);
        return new List<FieldValue>();
    }
    
    /**
     * Convert FieldValue list to Map
     */
    private static Map<String, Object> convertFieldData(List<FieldValue> fieldValues) {
        Map<String, Object> result = new Map<String, Object>();
        
        if (fieldValues == null) {
            return result;
        }
        
        for (FieldValue fv : fieldValues) {
            if (fv != null && !String.isBlank(fv.fieldApiName)) {
                result.put(fv.fieldApiName, fv.value);
            }
        }
        
        return result;
    }
    
    /**
     * Apply field data to an SObject
     */
    private static void applyFieldData(
        SObject record,
        Map<String, Schema.SObjectField> fieldMap,
        Map<String, Object> fieldData
    ) {
        for (String apiName : fieldData.keySet()) {
            if (fieldMap.containsKey(apiName)) {
                Object value = fieldData.get(apiName);
                
                // Convert string values to appropriate types
                Schema.DescribeFieldResult fieldDescribe = fieldMap.get(apiName).getDescribe();
                Object typedValue = convertValueToFieldType(value, fieldDescribe);
                
                record.put(apiName, typedValue);
            }
        }
    }
    
    /**
     * Convert string value to appropriate field type
     */
    private static Object convertValueToFieldType(Object value, Schema.DescribeFieldResult fieldDescribe) {
        if (value == null) {
            return null;
        }
        
        String strValue = String.valueOf(value);
        Schema.DisplayType fieldType = fieldDescribe.getType();
        
        try {
            switch on fieldType {
                when BOOLEAN {
                    return Boolean.valueOf(strValue);
                }
                when INTEGER {
                    return Integer.valueOf(strValue);
                }
                when DOUBLE, CURRENCY, PERCENT {
                    return Decimal.valueOf(strValue);
                }
                when DATE {
                    return Date.valueOf(strValue);
                }
                when DATETIME {
                    return Datetime.valueOf(strValue);
                }
                when else {
                    return strValue;
                }
            }
        } catch (Exception e) {
            // If conversion fails, return original value
            return value;
        }
    }
    
    /**
     * Parse fieldData from JSON string (handles both single object and array)
     * Supports two formats:
     * 1. Structured format: {"fieldApiName":"Name","value":"Test 1"} or [{"fieldApiName":"Name","value":"Test 1"}]
     * 2. Direct field mapping: {"Name":"Test 1"} or [{"Name":"Test 1","Industry":"Tech"}]
     * This is used when AI agents pass fieldData as a JSON string
     */
    private static List<FieldValue> parseFieldDataJson(String fieldDataJson) {
        if (String.isBlank(fieldDataJson)) {
            return new List<FieldValue>();
        }
        
        try {
            Object parsed = JSON.deserializeUntyped(fieldDataJson);
            
            // If it's an array
            if (parsed instanceof List<Object>) {
                List<Object> fieldDataList = (List<Object>) parsed;
                List<FieldValue> result = new List<FieldValue>();
                for (Object item : fieldDataList) {
                    if (item instanceof Map<String, Object>) {
                        Map<String, Object> fieldDataMap = (Map<String, Object>) item;
                        
                        // Check if it's structured format (has fieldApiName and value keys)
                        if (fieldDataMap.containsKey('fieldApiName') && fieldDataMap.containsKey('value')) {
                            FieldValue fv = new FieldValue();
                            fv.fieldApiName = String.valueOf(fieldDataMap.get('fieldApiName'));
                            fv.value = String.valueOf(fieldDataMap.get('value'));
                            if (!String.isBlank(fv.fieldApiName)) {
                                result.add(fv);
                            }
                        } else {
                            // Direct field mapping format: convert each key-value pair to FieldValue
                            for (String fieldName : fieldDataMap.keySet()) {
                                // Skip special fields that are handled separately
                                if (fieldName == 'Id' || fieldName.startsWith('_')) {
                                    continue;
                                }
                                FieldValue fv = new FieldValue();
                                fv.fieldApiName = fieldName;
                                Object fieldValue = fieldDataMap.get(fieldName);
                                fv.value = fieldValue != null ? String.valueOf(fieldValue) : null;
                                if (!String.isBlank(fv.fieldApiName)) {
                                    result.add(fv);
                                }
                            }
                        }
                    }
                }
                System.debug(LoggingLevel.INFO, 'AFUniversalCrmRecordAction: Parsed ' + result.size() + ' field values from JSON array');
                return result;
            }
            // If it's a single object
            else if (parsed instanceof Map<String, Object>) {
                Map<String, Object> fieldDataMap = (Map<String, Object>) parsed;
                List<FieldValue> result = new List<FieldValue>();
                
                // Check if it's structured format (has fieldApiName and value keys)
                if (fieldDataMap.containsKey('fieldApiName') && fieldDataMap.containsKey('value')) {
                    FieldValue fv = new FieldValue();
                    fv.fieldApiName = String.valueOf(fieldDataMap.get('fieldApiName'));
                    fv.value = String.valueOf(fieldDataMap.get('value'));
                    if (!String.isBlank(fv.fieldApiName)) {
                        result.add(fv);
                    }
                } else {
                    // Direct field mapping format: convert each key-value pair to FieldValue
                    for (String fieldName : fieldDataMap.keySet()) {
                        // Skip special fields that are handled separately
                        if (fieldName == 'Id' || fieldName.startsWith('_')) {
                            continue;
                        }
                        FieldValue fv = new FieldValue();
                        fv.fieldApiName = fieldName;
                        Object fieldValue = fieldDataMap.get(fieldName);
                        fv.value = fieldValue != null ? String.valueOf(fieldValue) : null;
                        if (!String.isBlank(fv.fieldApiName)) {
                            result.add(fv);
                        }
                    }
                }
                
                if (!result.isEmpty()) {
                    System.debug(LoggingLevel.INFO, 'AFUniversalCrmRecordAction: Parsed ' + result.size() + ' field value(s) from JSON object');
                    return result;
                }
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'AFUniversalCrmRecordAction: Failed to parse fieldDataJson: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'AFUniversalCrmRecordAction: fieldDataJson content: ' + fieldDataJson);
        }
        
        return new List<FieldValue>();
    }
    
    /**
     * Resolve record ID by name for update operations
     * Returns null if not found (caller handles error)
     */
    private static Id resolveRecordIdForUpdate(Request req, Map<String, Object> fieldDataMap) {
        String obj = req.objectApiName.toLowerCase();
        Id resolvedId = null;
        
        switch on obj {
            when 'account' {
                if (fieldDataMap.containsKey('Name')) {
                    String accountName = String.valueOf(fieldDataMap.get('Name'));
                    if (!String.isBlank(accountName)) {
                        List<Account> accounts = [
                            SELECT Id FROM Account 
                            WHERE Name = :accountName 
                            ORDER BY LastModifiedDate DESC 
                            LIMIT 1
                        ];
                        resolvedId = accounts.isEmpty() ? null : accounts[0].Id;
                        if (resolvedId != null) {
                            System.debug(LoggingLevel.INFO, 'AFUniversalCrmRecordAction: Resolved Account "' + accountName + '" to ID: ' + resolvedId);
                        }
                    }
                }
            }
            when 'contact' {
                String lastName = fieldDataMap.containsKey('LastName') ? String.valueOf(fieldDataMap.get('LastName')) : null;
                String firstName = fieldDataMap.containsKey('FirstName') ? String.valueOf(fieldDataMap.get('FirstName')) : null;
                String email = fieldDataMap.containsKey('Email') ? String.valueOf(fieldDataMap.get('Email')) : null;
                
                if (!String.isBlank(lastName)) {
                    String soql = 'SELECT Id FROM Contact WHERE LastName = :lastName';
                    List<Contact> contacts;
                    
                    if (!String.isBlank(email)) {
                        contacts = Database.query(soql + ' AND Email = :email ORDER BY LastModifiedDate DESC LIMIT 1');
                    } else if (!String.isBlank(firstName)) {
                        contacts = Database.query(soql + ' AND FirstName = :firstName ORDER BY LastModifiedDate DESC LIMIT 1');
                    } else {
                        contacts = Database.query(soql + ' ORDER BY LastModifiedDate DESC LIMIT 1');
                    }
                    
                    resolvedId = contacts.isEmpty() ? null : contacts[0].Id;
                    if (resolvedId != null) {
                        System.debug(LoggingLevel.INFO, 'AFUniversalCrmRecordAction: Resolved Contact to ID: ' + resolvedId);
                    }
                }
            }
            when 'opportunity' {
                if (fieldDataMap.containsKey('Name')) {
                    String oppName = String.valueOf(fieldDataMap.get('Name'));
                    if (!String.isBlank(oppName)) {
                        List<Opportunity> opps = [
                            SELECT Id FROM Opportunity 
                            WHERE Name = :oppName 
                            ORDER BY LastModifiedDate DESC 
                            LIMIT 1
                        ];
                        resolvedId = opps.isEmpty() ? null : opps[0].Id;
                        if (resolvedId != null) {
                            System.debug(LoggingLevel.INFO, 'AFUniversalCrmRecordAction: Resolved Opportunity "' + oppName + '" to ID: ' + resolvedId);
                        }
                    }
                }
            }
            when 'meeting__c' {
                if (fieldDataMap.containsKey('Subject__c')) {
                    String subject = String.valueOf(fieldDataMap.get('Subject__c'));
                    if (!String.isBlank(subject)) {
                        List<Meeting__c> meetings = [
                            SELECT Id FROM Meeting__c 
                            WHERE Subject__c = :subject 
                            ORDER BY LastModifiedDate DESC 
                            LIMIT 1
                        ];
                        resolvedId = meetings.isEmpty() ? null : meetings[0].Id;
                        if (resolvedId != null) {
                            System.debug(LoggingLevel.INFO, 'AFUniversalCrmRecordAction: Resolved Meeting__c "' + subject + '" to ID: ' + resolvedId);
                        }
                    }
                }
            }
            when 'customerorders__c' {
                // Try Name first
                if (fieldDataMap.containsKey('Name')) {
                    String orderName = String.valueOf(fieldDataMap.get('Name'));
                    if (!String.isBlank(orderName)) {
                        List<CustomerOrders__c> orders = [
                            SELECT Id FROM CustomerOrders__c 
                            WHERE Name = :orderName 
                            ORDER BY LastModifiedDate DESC 
                            LIMIT 1
                        ];
                        resolvedId = orders.isEmpty() ? null : orders[0].Id;
                        if (resolvedId != null) {
                            System.debug(LoggingLevel.INFO, 'AFUniversalCrmRecordAction: Resolved CustomerOrders__c "' + orderName + '" to ID: ' + resolvedId);
                        }
                    }
                }
                // Try Order_Number__c as fallback
                if (resolvedId == null && fieldDataMap.containsKey('Order_Number__c')) {
                    String orderNumber = String.valueOf(fieldDataMap.get('Order_Number__c'));
                    if (!String.isBlank(orderNumber)) {
                        List<CustomerOrders__c> orders = [
                            SELECT Id FROM CustomerOrders__c 
                            WHERE Order_Number__c = :orderNumber 
                            ORDER BY LastModifiedDate DESC 
                            LIMIT 1
                        ];
                        resolvedId = orders.isEmpty() ? null : orders[0].Id;
                        if (resolvedId != null) {
                            System.debug(LoggingLevel.INFO, 'AFUniversalCrmRecordAction: Resolved CustomerOrders__c by Order_Number "' + orderNumber + '" to ID: ' + resolvedId);
                        }
                    }
                }
            }
        }
        
        return resolvedId;
    }
    
    /**
     * Parse filters from JSON string (handles both single object and array)
     * This is used when AI agents pass filters as a JSON string
     */
    private static List<Filter> parseFiltersJson(String filtersJson) {
        if (String.isBlank(filtersJson)) {
            return new List<Filter>();
        }
        
        try {
            Object parsed = JSON.deserializeUntyped(filtersJson);
            
            // If it's an array
            if (parsed instanceof List<Object>) {
                List<Object> filterList = (List<Object>) parsed;
                List<Filter> result = new List<Filter>();
                for (Object item : filterList) {
                    if (item instanceof Map<String, Object>) {
                        Map<String, Object> filterMap = (Map<String, Object>) item;
                        Filter f = new Filter();
                        if (filterMap.containsKey('fieldApiName')) {
                            f.fieldApiName = String.valueOf(filterMap.get('fieldApiName'));
                        }
                        if (filterMap.containsKey('value')) {
                            f.value = String.valueOf(filterMap.get('value'));
                        }
                        if (!String.isBlank(f.fieldApiName) && !String.isBlank(f.value)) {
                            result.add(f);
                        }
                    }
                }
                System.debug(LoggingLevel.INFO, 'AFUniversalCrmRecordAction: Parsed ' + result.size() + ' filters from JSON array');
                return result;
            }
            // If it's a single object
            else if (parsed instanceof Map<String, Object>) {
                Map<String, Object> filterMap = (Map<String, Object>) parsed;
                Filter f = new Filter();
                if (filterMap.containsKey('fieldApiName')) {
                    f.fieldApiName = String.valueOf(filterMap.get('fieldApiName'));
                }
                if (filterMap.containsKey('value')) {
                    f.value = String.valueOf(filterMap.get('value'));
                }
                if (!String.isBlank(f.fieldApiName) && !String.isBlank(f.value)) {
                    System.debug(LoggingLevel.INFO, 'AFUniversalCrmRecordAction: Parsed single filter from JSON object');
                    return new List<Filter>{ f };
                }
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'AFUniversalCrmRecordAction: Failed to parse filtersJson: ' + e.getMessage());
        }
        
        return new List<Filter>();
    }
    
    /**
     * Normalize filters to handle deserialization issues from JSON
     * Handles cases where filters might be a single object, a list, or null
     */
    private static List<Filter> normalizeFilters(Object filters) {
        if (filters == null) {
            System.debug(LoggingLevel.INFO, 'AFUniversalCrmRecordAction: Filters is null');
            return new List<Filter>();
        }
        
        System.debug(LoggingLevel.INFO, 'AFUniversalCrmRecordAction: Filters type: ' + String.valueOf(filters));
        
        // Already a List<Filter> - check by trying to cast
        try {
            List<Filter> filterList = (List<Filter>) filters;
            if (filterList != null) {
                System.debug(LoggingLevel.INFO, 'AFUniversalCrmRecordAction: Filters is already List<Filter>, size: ' + filterList.size());
                return filterList;
            }
        } catch (TypeException te) {
            // Not a List<Filter>, continue to other checks
        }
        
        // Single Filter object
        if (filters instanceof Filter) {
            System.debug(LoggingLevel.INFO, 'AFUniversalCrmRecordAction: Filters is single Filter object');
            return new List<Filter>{ (Filter) filters };
        }
        
        // Handle Map<String, Object> from JSON deserialization (when single object passed instead of array)
        if (filters instanceof Map<String, Object>) {
            System.debug(LoggingLevel.INFO, 'AFUniversalCrmRecordAction: Filters is Map<String, Object>, attempting to convert');
            Map<String, Object> filterMap = (Map<String, Object>) filters;
            Filter f = new Filter();
            if (filterMap.containsKey('fieldApiName')) {
                f.fieldApiName = String.valueOf(filterMap.get('fieldApiName'));
            }
            if (filterMap.containsKey('value')) {
                f.value = String.valueOf(filterMap.get('value'));
            }
            if (!String.isBlank(f.fieldApiName) && !String.isBlank(f.value)) {
                System.debug(LoggingLevel.INFO, 'AFUniversalCrmRecordAction: Successfully converted Map to Filter: ' + f.fieldApiName + ' = ' + f.value);
                return new List<Filter>{ f };
            } else {
                System.debug(LoggingLevel.WARN, 'AFUniversalCrmRecordAction: Map conversion failed - missing fieldApiName or value');
            }
        }
        
        // Try to handle as a generic Object (might be a Map from JSON)
        try {
            Map<String, Object> genericMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(filters));
            if (genericMap.containsKey('fieldApiName') || genericMap.containsKey('value')) {
                Filter f = new Filter();
                if (genericMap.containsKey('fieldApiName')) {
                    f.fieldApiName = String.valueOf(genericMap.get('fieldApiName'));
                }
                if (genericMap.containsKey('value')) {
                    f.value = String.valueOf(genericMap.get('value'));
                }
                if (!String.isBlank(f.fieldApiName) && !String.isBlank(f.value)) {
                    System.debug(LoggingLevel.INFO, 'AFUniversalCrmRecordAction: Successfully converted generic object to Filter via JSON');
                    return new List<Filter>{ f };
                }
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'AFUniversalCrmRecordAction: JSON conversion attempt failed: ' + e.getMessage());
        }
        
        // If we can't normalize it, return empty list
        System.debug(LoggingLevel.WARN, 'AFUniversalCrmRecordAction: Could not normalize filters: ' + filters);
        return new List<Filter>();
    }
    
    /**
     * Build filter conditions from Filter list
     */
    private static List<String> buildFilterConditions(
        List<Filter> filters,
        Map<String, Schema.SObjectField> fieldMap
    ) {
        List<String> conditions = new List<String>();
        
        if (filters == null || filters.isEmpty()) {
            return conditions;
            }
        
        for (Filter f : filters) {
                if (f != null && !String.isBlank(f.fieldApiName) && fieldMap.containsKey(f.fieldApiName)) {
                    String escapedValue = String.escapeSingleQuotes(f.value);
                    conditions.add(f.fieldApiName + ' = \'' + escapedValue + '\'');
            }
        }
        
        return conditions;
    }
    
    /**
     * Build search conditions based on object type
     */
    private static String buildSearchConditions(
        String objectApiName,
        String searchTerm,
        Map<String, Schema.SObjectField> fieldMap
    ) {
        String obj = objectApiName.toLowerCase();
        String escapedTerm = String.escapeSingleQuotes(searchTerm);
        String likePattern = '%' + escapedTerm + '%';
        
        List<String> orConditions = new List<String>();
        
        // Define searchable fields per object
        if (obj == 'account') {
            addLikeCondition('Name', likePattern, fieldMap, orConditions);
            addLikeCondition('BillingStreet', likePattern, fieldMap, orConditions);
            addLikeCondition('BillingCity', likePattern, fieldMap, orConditions);
            addLikeCondition('BillingState', likePattern, fieldMap, orConditions);
            addLikeCondition('BillingPostalCode', likePattern, fieldMap, orConditions);
        } else if (obj == 'contact') {
            // Name is the compound full name field - critical for "Joe Dennis" type searches
            addLikeCondition('Name', likePattern, fieldMap, orConditions);
            addLikeCondition('FirstName', likePattern, fieldMap, orConditions);
            addLikeCondition('LastName', likePattern, fieldMap, orConditions);
            addLikeCondition('Email', likePattern, fieldMap, orConditions);
            addLikeCondition('Phone', likePattern, fieldMap, orConditions);
        } else if (obj == 'case') {
            addLikeCondition('CaseNumber', likePattern, fieldMap, orConditions);
            addLikeCondition('Subject', likePattern, fieldMap, orConditions);
            addLikeCondition('Description', likePattern, fieldMap, orConditions);
        } else if (obj == 'opportunity') {
            addLikeCondition('Name', likePattern, fieldMap, orConditions);
            addLikeCondition('StageName', likePattern, fieldMap, orConditions);
            addLikeCondition('NextStep', likePattern, fieldMap, orConditions);
            // Also search by Account name for better matching
            orConditions.add('Account.Name LIKE \'' + likePattern + '\'');
        } else if (obj == 'task') {
            addLikeCondition('Subject', likePattern, fieldMap, orConditions);
            addLikeCondition('Description', likePattern, fieldMap, orConditions);
            addLikeCondition('Status', likePattern, fieldMap, orConditions);
        } else if (obj == 'meeting__c') {
            addLikeCondition('Subject__c', likePattern, fieldMap, orConditions);
            addLikeCondition('Description__c', likePattern, fieldMap, orConditions);
            addLikeCondition('Meeting_Status__c', likePattern, fieldMap, orConditions);
        } else if (obj == 'customerorders__c') {
            addLikeCondition('Name', likePattern, fieldMap, orConditions);
            addLikeCondition('Order_Number__c', likePattern, fieldMap, orConditions);
            addLikeCondition('PO_Number__c', likePattern, fieldMap, orConditions);
            addLikeCondition('Status__c', likePattern, fieldMap, orConditions);
            orConditions.add('Account__r.Name LIKE \'' + likePattern + '\'');
            orConditions.add('Contact__r.Name LIKE \'' + likePattern + '\'');
        } else if (obj == 'customer_order_line_item__c') {
            addLikeCondition('Product_Name__c', likePattern, fieldMap, orConditions);
            addLikeCondition('SKU__c', likePattern, fieldMap, orConditions);
        } else if (obj == 'diagnostic_test_order__c') {
            // Diagnostic Test Order search - supports patient name, order numbers, tracking, physician
            addLikeCondition('Name', likePattern, fieldMap, orConditions);
            addLikeCondition('Order_Number__c', likePattern, fieldMap, orConditions);
            addLikeCondition('Requisition_Number__c', likePattern, fieldMap, orConditions);
            addLikeCondition('Lab_Reference_Number__c', likePattern, fieldMap, orConditions);
            addLikeCondition('Tracking_Number__c', likePattern, fieldMap, orConditions);
            addLikeCondition('Physician_Name__c', likePattern, fieldMap, orConditions);
            addLikeCondition('Test_Name__c', likePattern, fieldMap, orConditions);
            addLikeCondition('Test_Provider__c', likePattern, fieldMap, orConditions);
            orConditions.add('Account__r.Name LIKE \'' + likePattern + '\'');
            orConditions.add('Contact__r.Name LIKE \'' + likePattern + '\'');
        } else if (obj == 'program_candidate__c') {
            // Program Candidate search - supports patient name, email, program name
            addLikeCondition('Name', likePattern, fieldMap, orConditions);
            addLikeCondition('FirstName__c', likePattern, fieldMap, orConditions);
            addLikeCondition('LastName__c', likePattern, fieldMap, orConditions);
            addLikeCondition('Email__c', likePattern, fieldMap, orConditions);
            addLikeCondition('Phone__c', likePattern, fieldMap, orConditions);
            addLikeCondition('Program_Name__c', likePattern, fieldMap, orConditions);
            addLikeCondition('Insurance_Provider__c', likePattern, fieldMap, orConditions);
            
            // Handle "FirstName LastName" pattern - split and search both fields
            List<String> nameParts = searchTerm.trim().split('\\s+');
            if (nameParts.size() >= 2) {
                String firstName = String.escapeSingleQuotes(nameParts[0]);
                String lastName = String.escapeSingleQuotes(nameParts[nameParts.size() - 1]);
                orConditions.add('(FirstName__c LIKE \'%' + firstName + '%\' AND LastName__c LIKE \'%' + lastName + '%\')');
            }
        }
        
        return orConditions.isEmpty() ? '' : String.join(orConditions, ' OR ');
    }
    
    /**
     * Add a LIKE condition if the field exists
     */
    private static void addLikeCondition(
        String fieldApiName,
        String likePattern,
        Map<String, Schema.SObjectField> fieldMap,
        List<String> orConditions
    ) {
        if (fieldMap.containsKey(fieldApiName)) {
            orConditions.add(fieldApiName + ' LIKE \'' + likePattern + '\'');
        }
    }
    
    /**
     * Normalize search limit
     */
    private static Integer normalizeLimit(Integer requested) {
        if (requested == null || requested <= 0) {
            return DEFAULT_SEARCH_LIMIT;
        }
        return Math.min(requested, MAX_SEARCH_LIMIT);
    }
    
    /**
     * Count optional (non-required) fields in the provided data
     */
    private static Integer countOptionalFields(Map<String, Object> fieldData, String objectApiName) {
        if (fieldData == null || fieldData.isEmpty()) {
            return 0;
        }
        
        Set<String> requiredFields = getRequiredFields(objectApiName);
        Integer count = 0;
        
        for (String fieldName : fieldData.keySet()) {
            // Skip required fields, Id, and special fields (prefixed with _)
            if (!requiredFields.contains(fieldName) && 
                fieldName != 'Id' && 
                !fieldName.startsWith('_')) {
                count++;
            }
        }
        
        return count;
    }
    
    /**
     * Get required fields for an object
     */
    private static Set<String> getRequiredFields(String objectApiName) {
        Set<String> required = new Set<String>();
        String obj = objectApiName.toLowerCase();
        
        switch on obj {
            when 'account' {
                required.add('Name');
            }
            when 'contact' {
                required.add('LastName');
            }
            when 'case' {
                required.add('Subject');
            }
            when 'opportunity' {
                required.add('Name');
                required.add('StageName');
                required.add('CloseDate');
            }
            when 'task' {
                // Task has no strictly required fields in our implementation
                // Status defaults in org, Subject/Description from agent
            }
            when 'meeting__c' {
                required.add('Meeting_Date__c');
                required.add('Subject__c');
            }
            when 'customerorders__c' {
                required.add('Name');
            }
            when 'customer_order_line_item__c' {
                required.add('Customer_Order__c');
                required.add('Product_Name__c');
                required.add('Quantity__c');
                required.add('Unit_Price__c');
            }
        }
        
        return required;
    }
    
    /**
     * Get suggested fields for enrichment based on object type
     */
    private static List<String> getSuggestedFields(String objectApiName, Map<String, Schema.SObjectField> fieldMap) {
        List<String> suggestions = new List<String>();
        String obj = objectApiName.toLowerCase();
        
        // Define commonly-used fields per object
        Map<String, List<String>> commonFields = new Map<String, List<String>>{
            'account' => new List<String>{'Industry', 'BillingCity', 'BillingState', 'Phone', 'Website', 'Description', 'AnnualRevenue', 'NumberOfEmployees'},
            'contact' => new List<String>{'FirstName', 'Email', 'Phone', 'Title', 'Department', 'MailingCity', 'MailingState'},
            'case' => new List<String>{'Status', 'Priority', 'Type', 'Origin', 'Description'},
            'opportunity' => new List<String>{'Amount', 'Description', 'Type', 'LeadSource'},
            'task' => new List<String>{'Priority', 'ActivityDate', 'Description'},
            'meeting__c' => new List<String>{'Meeting_Type__c', 'Meeting_Outcome__c', 'Description__c', 'Product_Discussed__c', 'Attendees_Count__c'},
            'customerorders__c' => new List<String>{'Status__c', 'Order_Date__c', 'Priority__c', 'Requested_Delivery_Date__c', 'Shipping_Method__c', 'Order_Notes__c', 'PO_Number__c'},
            'customer_order_line_item__c' => new List<String>{'SKU__c', 'Fulfillment_Notes__c'}
        };
        
        List<String> fieldsForObject = commonFields.get(obj);
        if (fieldsForObject != null) {
            // Only include fields that exist and are accessible
            for (String fieldName : fieldsForObject) {
                if (fieldMap.containsKey(fieldName)) {
                    Schema.DescribeFieldResult fieldDesc = fieldMap.get(fieldName).getDescribe();
                    if (fieldDesc.isCreateable() && fieldDesc.isUpdateable()) {
                        suggestions.add(fieldName);
                    }
                }
            }
        }
        
        // Return up to 8 suggestions
        if (suggestions.size() > 8) {
            List<String> limited = new List<String>();
            for (Integer i = 0; i < 8 && i < suggestions.size(); i++) {
                limited.add(suggestions[i]);
            }
            return limited;
        }
        return suggestions;
    }
    
    /**
     * Get all available fields with detailed metadata for an object
     */
    private static String getAllAvailableFields(String objectApiName, Map<String, Schema.SObjectField> fieldMap, Boolean isCreate) {
        List<Map<String, Object>> fieldMetadata = new List<Map<String, Object>>();
        
        for (String fieldName : fieldMap.keySet()) {
            Schema.DescribeFieldResult fieldDesc = fieldMap.get(fieldName).getDescribe();
            
            // Only include createable/updateable fields (depending on operation)
            if ((isCreate && !fieldDesc.isCreateable()) || (!isCreate && !fieldDesc.isUpdateable())) {
                continue;
            }
            
            // Skip system fields and formula fields
            if (fieldDesc.isCalculated() || fieldDesc.isAutoNumber() || fieldName == 'Id') {
                continue;
            }
            
            Map<String, Object> fieldInfo = new Map<String, Object>();
            fieldInfo.put('apiName', fieldName);
            fieldInfo.put('label', fieldDesc.getLabel());
            fieldInfo.put('type', String.valueOf(fieldDesc.getType()));
            fieldInfo.put('required', !fieldDesc.isNillable() && !fieldDesc.isDefaultedOnCreate());
            fieldInfo.put('createable', fieldDesc.isCreateable());
            fieldInfo.put('updateable', fieldDesc.isUpdateable());
            fieldInfo.put('helpText', fieldDesc.getInlineHelpText());
            fieldInfo.put('maxLength', fieldDesc.getLength());
            fieldInfo.put('precision', fieldDesc.getPrecision());
            fieldInfo.put('scale', fieldDesc.getScale());
            
            // Add picklist values if it's a picklist
            if (fieldDesc.getType() == Schema.DisplayType.PICKLIST || 
                fieldDesc.getType() == Schema.DisplayType.MULTIPICKLIST) {
                List<Map<String, Object>> picklistValues = new List<Map<String, Object>>();
                for (Schema.PicklistEntry ple : fieldDesc.getPicklistValues()) {
                    if (ple.isActive()) {
                        picklistValues.add(new Map<String, Object>{
                            'value' => ple.getValue(),
                            'label' => ple.getLabel(),
                            'defaultValue' => ple.isDefaultValue()
                        });
                    }
                }
                fieldInfo.put('picklistValues', picklistValues);
            } else {
                fieldInfo.put('picklistValues', null);
            }
            
            fieldMetadata.add(fieldInfo);
        }
        
        return JSON.serialize(fieldMetadata);
    }
    
    /**
     * Populate related object names for Task records
     */
    private static void populateTaskRelatedNames(Response res, Task taskRecord) {
        try {
            if (taskRecord.What != null) {
                res.relatedAccountName = taskRecord.What.Name;
            }
            if (taskRecord.Who != null) {
                res.relatedContactName = taskRecord.Who.Name;
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'AFUniversalCrmRecordAction: Could not populate Task related names: ' + e.getMessage());
        }
    }
    
    /**
     * Build preview message for the user
     */
    private static String buildPreviewMessage(String objectApiName, Map<String, Object> fieldData, Boolean suggestEnrichment) {
        String obj = objectApiName.toLowerCase();
        String message = 'Preview: This will create a ' + obj + ' record with the following data:\n';
        
        // List provided fields
        for (String fieldName : fieldData.keySet()) {
            if (fieldName != 'Id' && !fieldName.startsWith('_')) {
                Object value = fieldData.get(fieldName);
                message += '  - ' + fieldName + ': ' + (value != null ? String.valueOf(value) : '(empty)') + '\n';
            }
        }
        
        if (suggestEnrichment) {
            message += '\nConsider adding more details to enrich this record. Check suggestedFields for commonly-used fields.';
        } else {
            message += '\nCall again with confirm=true to create this record.';
        }
        
        return message;
    }
    
    /**
     * Enforce minimum required fields for create
     */
    private static void enforceCreateRequirements(String objectApiName, Map<String, Object> fieldData) {
        String obj = objectApiName.toLowerCase();
        
        switch on obj {
            when 'account' {
                if (!hasValidField(fieldData, 'Name')) {
                    throw new ActionException('To create an Account, the Name field is required.');
                }
            }
            when 'contact' {
                if (!hasValidField(fieldData, 'LastName')) {
                    throw new ActionException('To create a Contact, the LastName field is required.');
                }
            }
            when 'case' {
                if (!hasValidField(fieldData, 'Subject')) {
                    throw new ActionException('To create a Case, the Subject field is required.');
                }
            }
            when 'opportunity' {
                if (!hasValidField(fieldData, 'Name')) {
                    throw new ActionException('To create an Opportunity, the Name field is required.');
                }
                if (!hasValidField(fieldData, 'StageName')) {
                    throw new ActionException('To create an Opportunity, the StageName field is required.');
                }
                if (!hasValidField(fieldData, 'CloseDate')) {
                    throw new ActionException('To create an Opportunity, the CloseDate field is required.');
                }
            }
            when 'customerorders__c' {
                if (!hasValidField(fieldData, 'Name')) {
                    throw new ActionException('To create a Customer Order, the Name field is required.');
                }
            }
            when 'customer_order_line_item__c' {
                if (!hasValidField(fieldData, 'Customer_Order__c')) {
                    throw new ActionException('To create a Line Item, the Customer_Order__c (parent order ID) field is required.');
                }
                if (!hasValidField(fieldData, 'Product_Name__c')) {
                    throw new ActionException('To create a Line Item, the Product_Name__c field is required.');
                }
                if (!hasValidField(fieldData, 'Quantity__c')) {
                    throw new ActionException('To create a Line Item, the Quantity__c field is required.');
                }
                if (!hasValidField(fieldData, 'Unit_Price__c')) {
                    throw new ActionException('To create a Line Item, the Unit_Price__c field is required.');
                }
            }
        }
    }
    
    /**
     * Check if field has a valid non-empty value
     */
    private static Boolean hasValidField(Map<String, Object> data, String apiName) {
        if (data == null || !data.containsKey(apiName)) {
            return false;
        }
        
        Object value = data.get(apiName);
        
        if (value == null) {
            return false;
        }
        
        if (value instanceof String && String.isBlank((String) value)) {
            return false;
        }
        
        return true;
    }
    
    /**
     * Send debug email on failure
     * Uses org owner's email, falls back to running user's email if org owner cannot be determined
     */
    private static void sendDebugEmail(Request req, Response res, Exception e) {
        // Priority: 1) req.debugEmail parameter, 2) org owner's email, 3) running user's email
        String debugEmail = null;
        
        // First, check if debugEmail was explicitly provided in the request
        if (String.isNotBlank(req.debugEmail)) {
            debugEmail = req.debugEmail;
        } else {
            // Try to get org owner's email (user who created the org)
            try {
                Organization org = [SELECT CreatedBy.Email FROM Organization LIMIT 1];
                if (String.isNotBlank(org.CreatedBy.Email)) {
                    debugEmail = org.CreatedBy.Email;
                }
            } catch (Exception orgEx) {
                // If we can't get org owner, fall through to running user
                System.debug(LoggingLevel.WARN, 'Could not retrieve org owner email: ' + orgEx.getMessage());
            }
            
            // Fall back to running user's email if org owner not available
            if (String.isBlank(debugEmail)) {
                debugEmail = UserInfo.getUserEmail();
            }
        }
        
        // If we still don't have an email, skip sending
        if (String.isBlank(debugEmail)) {
            System.debug(LoggingLevel.WARN, 'No debug email address available - skipping debug email send');
            return;
        }
        
        try {
            String subject = 'AFUniversalCrmRecordAction FAILURE: ' + req.operation + ' on ' + req.objectApiName;
            
            String body = '=== AF UNIVERSAL CRM RECORD ACTION DEBUG ===\n\n';
            body += 'Timestamp: ' + Datetime.now().format('yyyy-MM-dd HH:mm:ss z') + '\n';
            body += 'Running User: ' + UserInfo.getUserName() + '\n\n';
            
            body += '=== REQUEST DETAILS ===\n';
            body += 'Object: ' + req.objectApiName + '\n';
            body += 'Operation: ' + req.operation + '\n';
            body += 'Record ID: ' + (req.recordId != null ? String.valueOf(req.recordId) : '(none)') + '\n';
            body += 'Account Name: ' + (String.isNotBlank(req.accountName) ? req.accountName : '(none)') + '\n';
            body += 'Contact Name/Email: ' + (String.isNotBlank(req.contactNameOrEmail) ? req.contactNameOrEmail : '(none)') + '\n';
            body += 'Search Term: ' + (String.isNotBlank(req.searchTerm) ? req.searchTerm : '(none)') + '\n';
            body += 'Search Limit: ' + (req.searchLimit != null ? String.valueOf(req.searchLimit) : '(default)') + '\n\n';
            
            if (req.fieldData != null && !req.fieldData.isEmpty()) {
                body += '=== FIELD DATA ===\n';
                for (FieldValue fv : req.fieldData) {
                    body += '  ' + fv.fieldApiName + ' = "' + fv.value + '"\n';
                }
                body += '\n';
            }
            
            if (req.filters != null && !req.filters.isEmpty()) {
                body += '=== FILTERS ===\n';
                for (Filter f : req.filters) {
                    body += '  ' + f.fieldApiName + ' = "' + f.value + '"\n';
                }
                body += '\n';
            }
            
            if (String.isNotBlank(req.bulkRecordsJson)) {
                body += '=== BULK RECORDS JSON ===\n';
                body += req.bulkRecordsJson + '\n\n';
            }
            
            body += '=== ERROR DETAILS ===\n';
            body += 'Message: ' + res.message + '\n';
            body += 'Exception Type: ' + e.getTypeName() + '\n';
            body += 'Exception Message: ' + e.getMessage() + '\n\n';
            body += '=== STACK TRACE ===\n';
            body += e.getStackTraceString() + '\n\n';
            
            if (res.errors != null && !res.errors.isEmpty()) {
                body += '=== BULK OPERATION ERRORS ===\n';
                for (BulkRecordError err : res.errors) {
                    body += 'Index ' + err.recordIndex + ': ' + err.errorMessage + '\n';
                    body += '  Data: ' + err.recordData + '\n';
                }
                body += '\n';
            }
            
            body += '=== END DEBUG ===';
            
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new List<String>{ debugEmail });
            email.setSubject(subject);
            email.setPlainTextBody(body);
            email.setSaveAsActivity(false);
            
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
            
        } catch (Exception emailEx) {
            // Silently fail - don't let debug email issues break the main operation
            System.debug(LoggingLevel.ERROR, 'Failed to send debug email: ' + emailEx.getMessage());
        }
    }
    
    /**
     * Custom exception class
     */
    public class ActionException extends Exception {}
    
    /**
     * Normalize JSON string to handle common LLM mistakes like using single quotes instead of double quotes.
     * JSON spec requires double quotes, but LLMs often generate Python-style single quotes.
     */
    private static String normalizeJsonQuotes(String jsonStr) {
        if (String.isBlank(jsonStr)) {
            return jsonStr;
        }
        // Replace single quotes with double quotes for JSON keys and string values
        // This handles: {'key': 'value'} -> {"key": "value"}
        // Be careful not to replace apostrophes inside strings - this is a simple fix
        // that works for the common case of LLM-generated JSON
        return jsonStr.replace('\'', '"');
    }
    
    /**
     * Exception for missing parent records with field metadata
     */
    public class MissingParentException extends Exception {
        public String parentType;
        public String parentName;
        public List<String> requiredFields;
        public List<String> optionalFields;
        
        public MissingParentException(String parentType, String parentName, List<String> requiredFields, List<String> optionalFields) {
            this.parentType = parentType;
            this.parentName = parentName;
            this.requiredFields = requiredFields != null ? requiredFields : new List<String>();
            this.optionalFields = optionalFields != null ? optionalFields : new List<String>();
            this.setMessage(parentType + ' \'' + parentName + '\' not found.');
        }
    }
    
    /**
     * Get field metadata (required and optional) for an object
     */
    private static Map<String, List<String>> getObjectFieldMetadata(String objectApiName) {
        Map<String, List<String>> metadata = new Map<String, List<String>>();
        List<String> requiredFields = new List<String>();
        List<String> optionalFields = new List<String>();
        
        Schema.SObjectType sType = Schema.getGlobalDescribe().get(objectApiName.toLowerCase());
        if (sType == null) {
            return metadata;
        }
        
        Schema.DescribeSObjectResult objDescribe = sType.getDescribe();
        Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();
        
        // Define common identifying fields per object
        Set<String> identifyingFields = new Set<String>();
        if (objectApiName.toLowerCase() == 'account') {
            identifyingFields.add('Name');
            identifyingFields.add('Industry');
            identifyingFields.add('BillingCity');
            identifyingFields.add('BillingState');
            identifyingFields.add('Phone');
        } else if (objectApiName.toLowerCase() == 'contact') {
            identifyingFields.add('LastName');
            identifyingFields.add('FirstName');
            identifyingFields.add('Email');
            identifyingFields.add('Phone');
        } else if (objectApiName.toLowerCase() == 'case') {
            identifyingFields.add('Subject');
            identifyingFields.add('Status');
            identifyingFields.add('Priority');
        } else if (objectApiName.toLowerCase() == 'opportunity') {
            identifyingFields.add('Name');
            identifyingFields.add('StageName');
            identifyingFields.add('CloseDate');
            identifyingFields.add('Amount');
        }
        
        for (String fieldApiName : identifyingFields) {
            if (fieldMap.containsKey(fieldApiName)) {
                Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldApiName).getDescribe();
                if (fieldDescribe.isNillable() && !fieldDescribe.isDefaultedOnCreate()) {
                    optionalFields.add(fieldApiName);
                } else {
                    requiredFields.add(fieldApiName);
                }
            }
        }
        
        metadata.put('required', requiredFields);
        metadata.put('optional', optionalFields);
        return metadata;
    }
    
    /**
     * Get guidance on what additional information would help narrow down ambiguous searches
     */
    private static String getAdditionalInfoGuidance(String objectApiName, Map<String, Schema.SObjectField> fieldMap) {
        String obj = objectApiName.toLowerCase();
        List<String> suggestions = new List<String>();
        
        if (obj == 'account') {
            if (fieldMap.containsKey('Industry')) suggestions.add('industry');
            if (fieldMap.containsKey('BillingCity')) suggestions.add('city');
            if (fieldMap.containsKey('BillingState')) suggestions.add('state');
            if (fieldMap.containsKey('Phone')) suggestions.add('phone number');
        } else if (obj == 'contact') {
            if (fieldMap.containsKey('Email')) suggestions.add('email');
            if (fieldMap.containsKey('Phone')) suggestions.add('phone number');
            if (fieldMap.containsKey('AccountId')) suggestions.add('account name');
        } else if (obj == 'case') {
            if (fieldMap.containsKey('Status')) suggestions.add('status');
            if (fieldMap.containsKey('Priority')) suggestions.add('priority');
            if (fieldMap.containsKey('AccountId')) suggestions.add('account name');
        } else if (obj == 'opportunity') {
            if (fieldMap.containsKey('StageName')) suggestions.add('stage');
            if (fieldMap.containsKey('CloseDate')) suggestions.add('close date');
            if (fieldMap.containsKey('AccountId')) suggestions.add('account name');
        } else if (obj == 'customerorders__c') {
            if (fieldMap.containsKey('Status__c')) suggestions.add('status');
            if (fieldMap.containsKey('Order_Number__c')) suggestions.add('order number');
            if (fieldMap.containsKey('Order_Date__c')) suggestions.add('order date');
            if (fieldMap.containsKey('Account__c')) suggestions.add('account name');
        }
        
        if (suggestions.isEmpty()) {
            return 'additional identifying information';
        }
        
        if (suggestions.size() == 1) {
            return suggestions[0];
        } else if (suggestions.size() == 2) {
            return suggestions[0] + ' or ' + suggestions[1];
        } else {
            String last = suggestions[suggestions.size() - 1];
            List<String> rest = new List<String>();
            for (Integer i = 0; i < suggestions.size() - 1; i++) {
                rest.add(suggestions[i]);
            }
            return String.join(rest, ', ') + ', or ' + last;
        }
    }
    
    /**
     * Line Item Wrapper - adds lineNumber for agent reference
     */
    public class LineItemWrapper {
        public Customer_Order_Line_Item__c lineItem;
        public Integer lineNumber;
        
        public LineItemWrapper(Customer_Order_Line_Item__c item, Integer num) {
            this.lineItem = item;
            this.lineNumber = num;
        }
    }
    
    /**
     * Handle line items on create - process optional LineItems array
     * Called after parent order is created
     */
    public static List<Customer_Order_Line_Item__c> handleLineItemsOnCreate(
        Id orderId,
        String lineItemsJson
    ) {
        if (String.isBlank(lineItemsJson)) {
            return new List<Customer_Order_Line_Item__c>();
        }
        
        try {
            List<Object> lineItemsList = (List<Object>) JSON.deserializeUntyped(lineItemsJson);
            List<Customer_Order_Line_Item__c> lineItemsToInsert = new List<Customer_Order_Line_Item__c>();
            
            for (Object lineItemObj : lineItemsList) {
                if (lineItemObj instanceof Map<String, Object>) {
                    Map<String, Object> lineItemMap = (Map<String, Object>) lineItemObj;
                    Customer_Order_Line_Item__c lineItem = new Customer_Order_Line_Item__c();
                    lineItem.Customer_Order__c = orderId;
                    
                    // Map fields
                    for (String fieldName : lineItemMap.keySet()) {
                        Object fieldValue = lineItemMap.get(fieldName);
                        if (fieldValue != null) {
                            lineItem.put(fieldName, fieldValue);
                        }
                    }
                    
                    lineItemsToInsert.add(lineItem);
                }
            }
            
            if (!lineItemsToInsert.isEmpty()) {
                insert lineItemsToInsert;
                System.debug(LoggingLevel.INFO, 'AFUniversalCrmRecordAction: Created ' + lineItemsToInsert.size() + ' line items for order ' + orderId);
            }
            
            return lineItemsToInsert;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'AFUniversalCrmRecordAction: Error creating line items: ' + e.getMessage());
            throw new ActionException('Error creating line items: ' + e.getMessage());
        }
    }
    
    /**
     * Handle line items on read - query and return with lineNumber
     */
    public static List<Customer_Order_Line_Item__c> handleLineItemsOnRead(Id orderId) {
        try {
            List<Customer_Order_Line_Item__c> lineItems = [
                SELECT Id, Name, Product_Name__c, SKU__c, Quantity__c, Unit_Price__c, Total__c, Fulfillment_Notes__c
                FROM Customer_Order_Line_Item__c
                WHERE Customer_Order__c = :orderId
                ORDER BY CreatedDate ASC
            ];
            
            System.debug(LoggingLevel.INFO, 'AFUniversalCrmRecordAction: Retrieved ' + lineItems.size() + ' line items for order ' + orderId);
            return lineItems;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'AFUniversalCrmRecordAction: Error reading line items: ' + e.getMessage());
            return new List<Customer_Order_Line_Item__c>();
        }
    }
    
    /**
     * Handle line items on update - add, update, delete operations
     * Returns updated list of all line items
     */
    public static List<Customer_Order_Line_Item__c> handleLineItemsOnUpdate(
        Id orderId,
        String addLineItemsJson,
        String updateLineItemsJson,
        String deleteLineItemIds
    ) {
        try {
            // Add new line items
            if (!String.isBlank(addLineItemsJson)) {
                String normalizedAddJson = normalizeJsonQuotes(addLineItemsJson);
                List<Object> addList = (List<Object>) JSON.deserializeUntyped(normalizedAddJson);
                List<Customer_Order_Line_Item__c> lineItemsToInsert = new List<Customer_Order_Line_Item__c>();
                
                for (Object itemObj : addList) {
                    if (itemObj instanceof Map<String, Object>) {
                        Map<String, Object> itemMap = (Map<String, Object>) itemObj;
                        Customer_Order_Line_Item__c lineItem = new Customer_Order_Line_Item__c();
                        lineItem.Customer_Order__c = orderId;
                        
                        for (String fieldName : itemMap.keySet()) {
                            Object fieldValue = itemMap.get(fieldName);
                            if (fieldValue != null && fieldName != 'Id') {
                                lineItem.put(fieldName, fieldValue);
                            }
                        }
                        
                        lineItemsToInsert.add(lineItem);
                    }
                }
                
                if (!lineItemsToInsert.isEmpty()) {
                    insert lineItemsToInsert;
                    System.debug(LoggingLevel.INFO, 'AFUniversalCrmRecordAction: Added ' + lineItemsToInsert.size() + ' line items');
                }
            }
            
            // Update existing line items
            if (!String.isBlank(updateLineItemsJson)) {
                String normalizedUpdateJson = normalizeJsonQuotes(updateLineItemsJson);
                System.debug(LoggingLevel.INFO, 'AFUniversalCrmRecordAction: Normalized updateLineItemsJson: ' + normalizedUpdateJson);
                List<Object> updateList = (List<Object>) JSON.deserializeUntyped(normalizedUpdateJson);
                List<Customer_Order_Line_Item__c> lineItemsToUpdate = new List<Customer_Order_Line_Item__c>();
                
                for (Object itemObj : updateList) {
                    if (itemObj instanceof Map<String, Object>) {
                        Map<String, Object> itemMap = (Map<String, Object>) itemObj;
                        
                        if (!itemMap.containsKey('Id')) {
                            throw new ActionException('Each line item in updateLineItemsJson must include an Id field.');
                        }
                        
                        Id lineItemId = (Id) itemMap.get('Id');
                        Customer_Order_Line_Item__c lineItem = new Customer_Order_Line_Item__c(Id = lineItemId);
                        
                        for (String fieldName : itemMap.keySet()) {
                            if (fieldName != 'Id') {
                                Object fieldValue = itemMap.get(fieldName);
                                if (fieldValue != null) {
                                    lineItem.put(fieldName, fieldValue);
                                }
                            }
                        }
                        
                        lineItemsToUpdate.add(lineItem);
                    }
                }
                
                if (!lineItemsToUpdate.isEmpty()) {
                    update lineItemsToUpdate;
                    System.debug(LoggingLevel.INFO, 'AFUniversalCrmRecordAction: Updated ' + lineItemsToUpdate.size() + ' line items');
                }
            }
            
            // Delete line items
            if (!String.isBlank(deleteLineItemIds)) {
                String normalizedDeleteJson = normalizeJsonQuotes(deleteLineItemIds);
                List<Object> deleteList = (List<Object>) JSON.deserializeUntyped(normalizedDeleteJson);
                List<Id> idsToDelete = new List<Id>();
                
                for (Object idObj : deleteList) {
                    if (idObj instanceof String) {
                        idsToDelete.add((Id) idObj);
                    }
                }
                
                if (!idsToDelete.isEmpty()) {
                    List<Customer_Order_Line_Item__c> lineItemsToDelete = [
                        SELECT Id FROM Customer_Order_Line_Item__c WHERE Id IN :idsToDelete
                    ];
                    delete lineItemsToDelete;
                    System.debug(LoggingLevel.INFO, 'AFUniversalCrmRecordAction: Deleted ' + lineItemsToDelete.size() + ' line items');
                }
            }
            
            // Return all line items for the order
            return handleLineItemsOnRead(orderId);
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'AFUniversalCrmRecordAction: Error handling line items on update: ' + e.getMessage());
            throw new ActionException('Error handling line items: ' + e.getMessage());
        }
    }
    
    /**
     * Get line item count for an order
     */
    public static Integer getLineItemCount(Id orderId) {
        try {
            return [SELECT COUNT() FROM Customer_Order_Line_Item__c WHERE Customer_Order__c = :orderId];
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'AFUniversalCrmRecordAction: Error counting line items: ' + e.getMessage());
            return 0;
        }
    }
    
    /**
     * Get line item counts for multiple orders
     * Returns Map<OrderId, LineItemCount>
     */
    public static Map<Id, Integer> getLineItemCounts(List<Id> orderIds) {
        Map<Id, Integer> counts = new Map<Id, Integer>();
        
        try {
            List<AggregateResult> aggResults = [
                SELECT Customer_Order__c, COUNT(Id) itemCount
                FROM Customer_Order_Line_Item__c
                WHERE Customer_Order__c IN :orderIds
                GROUP BY Customer_Order__c
            ];
            
            for (AggregateResult ar : aggResults) {
                Id orderId = (Id) ar.get('Customer_Order__c');
                Integer count = ((Decimal) ar.get('itemCount')).intValue();
                counts.put(orderId, count);
            }
            
            // Fill in zeros for orders with no line items
            for (Id orderId : orderIds) {
                if (!counts.containsKey(orderId)) {
                    counts.put(orderId, 0);
                }
            }
            
            System.debug(LoggingLevel.INFO, 'AFUniversalCrmRecordAction: Retrieved line item counts for ' + orderIds.size() + ' orders');
            return counts;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'AFUniversalCrmRecordAction: Error getting line item counts: ' + e.getMessage());
            return counts;
        }
    }
}
