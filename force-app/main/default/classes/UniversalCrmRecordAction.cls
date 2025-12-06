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
    private static final Set<String> SUPPORTED_OBJECTS = new Set<String>{'account', 'contact', 'case', 'opportunity'};
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
        
        // Resolve related records
        resolveRelatedRecords(req, fieldDataMap);
        
        // Enforce minimum required fields
        enforceCreateRequirements(req.objectApiName, fieldDataMap);
        
        // Validate picklist values
        validatePicklistValues(fieldDataMap, fieldMap);
        
        // Create and populate the record
        SObject record = sType.newSObject();
        applyFieldData(record, fieldMap, fieldDataMap);
        
        // Insert the record
        insert record;
        
        res.record = record;
        res.recordId = record.Id;
        res.message = req.objectApiName + ' record created successfully with ID: ' + record.Id;
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
        if (req.recordId == null) {
            throw new ActionException('recordId is required for update operation.');
        }
        
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
        
        // If no field data provided, return current record and ask what to update
        if (normalizedFieldData == null || normalizedFieldData.isEmpty()) {
            // Return current record data
            String objectApiName = sType.getDescribe().getName();
            String soql = 'SELECT ' + String.join(new List<String>(fieldMap.keySet()), ', ') +
                          ' FROM ' + objectApiName +
                          ' WHERE Id = :recordId' +
                          ' LIMIT 1';
            Id recordId = req.recordId;
            List<SObject> results = Database.query(soql);
            
            if (results.isEmpty()) {
                throw new ActionException('No ' + objectApiName + ' record found with ID: ' + req.recordId);
            }
            
            res.record = results[0];
            res.recordId = (Id) results[0].get('Id');
            res.message = 'Here\'s the current ' + objectApiName + ' record data. Provide fields to update in the request body.';
            return;
        }
        
        System.debug(LoggingLevel.INFO, 'AFUniversalCrmRecordAction: Normalized fieldData count: ' + normalizedFieldData.size());
        
        Map<String, Object> fieldDataMap = convertFieldData(normalizedFieldData);
        
        // Resolve related records
        resolveRelatedRecords(req, fieldDataMap);
        
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
        
        // Build base query
        String soql = 'SELECT ' + String.join(new List<String>(fieldMap.keySet()), ', ') +
                      ' FROM ' + objectApiName;
        
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
        
        if (normalizedFilters != null && !normalizedFilters.isEmpty()) {
            whereClauses.addAll(buildFilterConditions(normalizedFilters, fieldMap));
        }
        
        // Add search term conditions
        if (!String.isBlank(req.searchTerm)) {
            String searchClause = buildSearchConditions(objectApiName, req.searchTerm, fieldMap);
            if (!String.isBlank(searchClause)) {
                whereClauses.add('(' + searchClause + ')');
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
                // Resolve related records for bulk
                resolveRelatedRecordsForBulk(req.objectApiName, fieldDataMap);
                
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
                // Check for Id field
                if (!fieldDataMap.containsKey('Id') || String.isBlank(String.valueOf(fieldDataMap.get('Id')))) {
                    throw new ActionException('Each record must include an Id field for update.');
                }
                
                Id recordId = (Id) fieldDataMap.get('Id');
                fieldDataMap.remove('Id'); // Remove Id from field data since we pass it separately
                
                // Resolve related records for bulk
                resolveRelatedRecordsForBulk(req.objectApiName, fieldDataMap);
                
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
            Id contactId = resolveContactByNameOrEmail(req.contactNameOrEmail);
            fieldDataMap.put('ContactId', contactId);
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
            
            if (!String.isBlank(contactNameOrEmail)) {
                Id contactId = resolveContactByNameOrEmail(contactNameOrEmail);
                fieldDataMap.put('ContactId', contactId);
            }
        }
    }
    
    /**
     * Resolve Account by name - returns most recently modified if multiple matches
     * Throws MissingParentException with field metadata if not found
     */
    private static Id resolveAccountByName(String accountName) {
        String escapedName = String.escapeSingleQuotes(accountName);
        
        List<Account> accounts = [
            SELECT Id, Name 
            FROM Account 
            WHERE Name = :accountName 
            ORDER BY LastModifiedDate DESC 
            LIMIT 1
        ];
        
        if (accounts.isEmpty()) {
            // Get field metadata for Account
            Map<String, List<String>> fieldMetadata = getObjectFieldMetadata('Account');
            throw new MissingParentException('Account', accountName, fieldMetadata.get('required'), fieldMetadata.get('optional'));
        }
        
        return accounts[0].Id;
    }
    
    /**
     * Resolve Contact by name or email - returns most recently modified if multiple matches
     */
    private static Id resolveContactByNameOrEmail(String nameOrEmail) {
        String searchTerm = String.escapeSingleQuotes(nameOrEmail);
        
        // Try email first (more specific)
        List<Contact> contacts = [
            SELECT Id, Name, Email 
            FROM Contact 
            WHERE Email = :nameOrEmail 
            ORDER BY LastModifiedDate DESC 
            LIMIT 1
        ];
        
        if (!contacts.isEmpty()) {
            return contacts[0].Id;
        }
        
        // Try name match (could be first name, last name, or full name)
        String likePattern = '%' + searchTerm + '%';
        contacts = [
            SELECT Id, Name, Email 
            FROM Contact 
            WHERE Name LIKE :likePattern
               OR FirstName LIKE :likePattern
               OR LastName LIKE :likePattern
            ORDER BY LastModifiedDate DESC 
            LIMIT 1
        ];
        
        if (contacts.isEmpty()) {
            // Get field metadata for Contact
            Map<String, List<String>> fieldMetadata = getObjectFieldMetadata('Contact');
            throw new MissingParentException('Contact', nameOrEmail, fieldMetadata.get('required'), fieldMetadata.get('optional'));
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
                        FieldValue fv = new FieldValue();
                        if (fieldDataMap.containsKey('fieldApiName')) {
                            fv.fieldApiName = String.valueOf(fieldDataMap.get('fieldApiName'));
                        }
                        if (fieldDataMap.containsKey('value')) {
                            fv.value = String.valueOf(fieldDataMap.get('value'));
                        }
                        if (!String.isBlank(fv.fieldApiName)) {
                            result.add(fv);
                        }
                    }
                }
                System.debug(LoggingLevel.INFO, 'AFUniversalCrmRecordAction: Parsed ' + result.size() + ' field values from JSON array');
                return result;
            }
            // If it's a single object
            else if (parsed instanceof Map<String, Object>) {
                Map<String, Object> fieldDataMap = (Map<String, Object>) parsed;
                FieldValue fv = new FieldValue();
                if (fieldDataMap.containsKey('fieldApiName')) {
                    fv.fieldApiName = String.valueOf(fieldDataMap.get('fieldApiName'));
                }
                if (fieldDataMap.containsKey('value')) {
                    fv.value = String.valueOf(fieldDataMap.get('value'));
                }
                if (!String.isBlank(fv.fieldApiName)) {
                    System.debug(LoggingLevel.INFO, 'AFUniversalCrmRecordAction: Parsed single field value from JSON object');
                    return new List<FieldValue>{ fv };
                }
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'AFUniversalCrmRecordAction: Failed to parse fieldDataJson: ' + e.getMessage());
        }
        
        return new List<FieldValue>();
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
            addLikeCondition('Description', likePattern, fieldMap, orConditions);
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
     * Send debug email on failure (hardcoded for demo purposes)
     */
    private static void sendDebugEmail(Request req, Response res, Exception e) {
        // Hardcoded debug email for demo org
        String debugEmail = 'patrick.dennis@salesforce.com';
        if (String.isBlank(debugEmail)) {
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
}
