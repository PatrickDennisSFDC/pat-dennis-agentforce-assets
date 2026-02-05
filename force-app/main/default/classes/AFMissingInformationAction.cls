/**
 * AF Missing Information Action
 * Consolidated invocable action for all Missing_Information__c CRUD operations (Create, Read, Update, Delete, Find)
 * Designed for Agentforce AI agents
 * 
 * Use Case: Tracks specific pieces of information needed from patients during enrollment or case resolution.
 * Each record represents one item that needs to be collected (like a to-do list for information collection).
 * Links to Program_Candidate__c for enrollment-related missing info, or Case for support-related missing info.
 */
public without sharing class AFMissingInformationAction {
    
    public class Request {
        @InvocableVariable(
            label='Operation'
            description='Explicit operation: "create", "read", "update", "delete", or "find". If not specified, inferred from context.'
        )
        public String operation;
        
        @InvocableVariable(
            label='Field Data JSON'
            description='JSON string containing Missing Information field data. Fields: Information_Type__c (picklist: Insurance Card, Member ID, Income Verification, Date of Birth, Prescription, Consent Form, ID Document, Address Verification, Contact Information, Other), Status__c (picklist: Missing, Received - defaults to Missing), Program_Candidate__c (lookup ID to Program Candidate record), Case__c (lookup ID to Case record), Notes__c (optional notes about what is needed). Example: {"Information_Type__c":"Insurance Card","Status__c":"Missing","Program_Candidate__c":"a0Xxx000003DGbYAAW","Notes__c":"Need front and back of insurance card"}'
            required=false
        )
        public String fieldDataJson;
        
        @InvocableVariable(
            label='Record ID'
            description='The Salesforce record ID (15 or 18 character) of the Missing Information record. Required for read/update/delete operations.'
        )
        public Id recordId;
        
        @InvocableVariable(
            label='Program Candidate ID'
            description='Program Candidate record ID to filter by or link to. Use for finding all missing information items for a specific enrollment.'
        )
        public Id programCandidateId;
        
        @InvocableVariable(
            label='Case ID'
            description='Case record ID to filter by or link to. Use for finding all missing information items for a specific support case.'
        )
        public Id caseId;
        
        @InvocableVariable(
            label='Search Term'
            description='Text to search for in Missing Information records (searches Information_Type__c, Notes__c). Example: "insurance", "consent".'
        )
        public String searchTerm;
        
        @InvocableVariable(
            label='Filters JSON'
            description='JSON string of exact-match filters for find operations. Example: {"Status__c":"Missing"} to find all items still needed, or {"Information_Type__c":"Insurance Card"} to find specific types.'
        )
        public String filtersJson;
        
        @InvocableVariable(
            label='Search Limit'
            description='Maximum number of records to return for find operations (default: 10, max: 50).'
        )
        public Integer searchLimit;
        
        @InvocableVariable(
            label='Status Only Missing'
            description='If true, only returns Missing Information records with Status__c = "Missing". Useful shorthand for finding outstanding items.'
        )
        public Boolean statusOnlyMissing;
        
        @InvocableVariable(
            label='Confirm'
            description='For delete: Set to true to actually delete. Default (false): Returns confirmation message first.'
        )
        public Boolean confirm;
    }
    
    public class Response {
        @InvocableVariable(
            label='Success'
            description='True if operation completed successfully, false if an error occurred.'
        )
        public Boolean success;
        
        @InvocableVariable(
            label='Record'
            description='The Missing Information record (for single record operations).'
        )
        public Missing_Information__c record;
        
        @InvocableVariable(
            label='Records'
            description='List of Missing Information records (for find operations or bulk results).'
        )
        public List<Missing_Information__c> records;
        
        @InvocableVariable(
            label='Record ID'
            description='The Salesforce ID of the record created or operated on.'
        )
        public Id recordId;
        
        @InvocableVariable(
            label='Message'
            description='Human-readable message describing the operation result.'
        )
        public String message;
        
        @InvocableVariable(
            label='Error Message'
            description='If success is false, contains a user-friendly error message.'
        )
        public String errorMessage;
        
        @InvocableVariable(
            label='Object Type'
            description='Always "Missing_Information__c" for this action.'
        )
        public String objectType;
        
        @InvocableVariable(
            label='Operation'
            description='The operation that was performed: create, read, update, delete, or find.'
        )
        public String operation;
        
        @InvocableVariable(
            label='Total Matches'
            description='Number of records found in a find operation.'
        )
        public Integer totalMatches;
        
        @InvocableVariable(
            label='Missing Count'
            description='Count of items with Status = Missing (for context when finding items for a Program Candidate or Case).'
        )
        public Integer missingCount;
        
        @InvocableVariable(
            label='Received Count'
            description='Count of items with Status = Received (for context when finding items for a Program Candidate or Case).'
        )
        public Integer receivedCount;
        
        @InvocableVariable(
            label='Confirmation Required'
            description='True if this is a confirmation request for delete operation.'
        )
        public Boolean confirmationRequired;
        
        @InvocableVariable(
            label='Available Information Types'
            description='List of valid Information_Type__c picklist values for reference.'
        )
        public List<String> availableInformationTypes;
    }
    
    private static String inferOperation(Request req) {
        if (!String.isBlank(req.operation)) {
            return req.operation.trim().toLowerCase();
        }
        
        Boolean hasRecordId = req.recordId != null;
        Boolean hasFieldData = !String.isBlank(req.fieldDataJson);
        Boolean hasSearchTerm = !String.isBlank(req.searchTerm);
        Boolean hasFilters = !String.isBlank(req.filtersJson);
        Boolean hasParentId = req.programCandidateId != null || req.caseId != null;
        Boolean hasStatusFilter = req.statusOnlyMissing != null && req.statusOnlyMissing;
        
        if (hasRecordId && hasFieldData) return 'update';
        else if (hasRecordId && !hasFieldData && !hasSearchTerm && !hasFilters) return 'read';
        else if (hasFieldData && !hasRecordId) return 'create';
        else if (hasSearchTerm || hasFilters || hasParentId || hasStatusFilter) return 'find';
        else if (hasRecordId && req.confirm != null && req.confirm == true) return 'delete';
        
        throw new AFUniversalCrmRecordAction.ActionException('Cannot infer operation. Please specify operation parameter or provide sufficient context.');
    }
    
    private static List<String> getPicklistValues() {
        List<String> values = new List<String>();
        Schema.DescribeFieldResult fieldResult = Missing_Information__c.Information_Type__c.getDescribe();
        for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
            if (entry.isActive()) {
                values.add(entry.getValue());
            }
        }
        return values;
    }
    
    @InvocableMethod(
        label='Agentforce Missing Information Action'
        description='Manages Missing Information records that track what documents or data are needed from patients. Use to: (1) CREATE new missing info items when you discover something is needed, (2) FIND all missing items for a Program Candidate or Case, (3) UPDATE status to "Received" when information is collected, (4) DELETE items that are no longer needed. Common Information Types: Insurance Card, Member ID, Income Verification, Date of Birth, Prescription, Consent Form, ID Document, Address Verification, Contact Information, Other. Tip: Use statusOnlyMissing=true to quickly find all outstanding items for a patient.'
        category='CRM Actions'
    )
    public static List<Response> missingInformationAction(List<Request> requests) {
        List<Response> responses = new List<Response>();
        
        for (Request req : requests) {
            Response res = new Response();
            res.objectType = 'Missing_Information__c';
            res.success = false;
            res.records = new List<Missing_Information__c>();
            res.totalMatches = 0;
            res.missingCount = 0;
            res.receivedCount = 0;
            res.confirmationRequired = false;
            res.availableInformationTypes = getPicklistValues();
            
            try {
                String op = inferOperation(req);
                res.operation = op;
                
                // Handle delete confirmation flow
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
                        List<Missing_Information__c> items = [
                            SELECT Id, Name, Information_Type__c 
                            FROM Missing_Information__c 
                            WHERE Id = :req.recordId 
                            LIMIT 1
                        ];
                        if (!items.isEmpty()) {
                            res.message = 'This will delete Missing Information item \'' + items[0].Name + '\' (' + items[0].Information_Type__c + '). Call again with confirm=true to proceed.';
                            res.success = true;
                        } else {
                            res.message = 'Record not found with ID ' + req.recordId + '.';
                            res.errorMessage = res.message;
                            res.success = false;
                        }
                    } catch (Exception e) {
                        res.message = 'This will delete the Missing Information item. Call again with confirm=true to proceed.';
                        res.success = true;
                    }
                    responses.add(res);
                    continue;
                }
                
                // Route to appropriate handler
                if (op == 'create') {
                    handleCreate(req, res);
                } else if (op == 'read') {
                    handleRead(req, res);
                } else if (op == 'update') {
                    handleUpdate(req, res);
                } else if (op == 'delete') {
                    handleDelete(req, res);
                } else if (op == 'find') {
                    handleFind(req, res);
                } else {
                    res.success = false;
                    res.errorMessage = 'Unknown operation: ' + op;
                }
                
            } catch (AFUniversalCrmRecordAction.ActionException ae) {
                res.success = false;
                res.errorMessage = ae.getMessage();
                System.debug(LoggingLevel.ERROR, 'AFMissingInformationAction: ActionException - ' + ae.getMessage());
            } catch (Exception e) {
                res.success = false;
                res.errorMessage = 'Error performing Missing Information operation: ' + e.getMessage();
                System.debug(LoggingLevel.ERROR, 'AFMissingInformationAction: Exception - ' + e.getMessage() + ' | Stack: ' + e.getStackTraceString());
            }
            
            responses.add(res);
        }
        
        return responses;
    }
    
    private static void handleCreate(Request req, Response res) {
        Missing_Information__c newRecord = new Missing_Information__c();
        
        // Default status to Missing
        newRecord.Status__c = 'Missing';
        
        // Parse field data JSON
        if (!String.isBlank(req.fieldDataJson)) {
            Map<String, Object> fieldData = (Map<String, Object>) JSON.deserializeUntyped(req.fieldDataJson);
            
            if (fieldData.containsKey('Information_Type__c')) {
                newRecord.Information_Type__c = String.valueOf(fieldData.get('Information_Type__c'));
            }
            if (fieldData.containsKey('Status__c')) {
                newRecord.Status__c = String.valueOf(fieldData.get('Status__c'));
            }
            if (fieldData.containsKey('Notes__c')) {
                newRecord.Notes__c = String.valueOf(fieldData.get('Notes__c'));
            }
            if (fieldData.containsKey('Program_Candidate__c')) {
                newRecord.Program_Candidate__c = Id.valueOf(String.valueOf(fieldData.get('Program_Candidate__c')));
            }
            if (fieldData.containsKey('Case__c')) {
                newRecord.Case__c = Id.valueOf(String.valueOf(fieldData.get('Case__c')));
            }
        }
        
        // Override with direct parameters if provided
        if (req.programCandidateId != null) {
            newRecord.Program_Candidate__c = req.programCandidateId;
        }
        if (req.caseId != null) {
            newRecord.Case__c = req.caseId;
        }
        
        // Validate
        if (String.isBlank(newRecord.Information_Type__c)) {
            res.success = false;
            res.errorMessage = 'Information_Type__c is required. Valid values: ' + String.join(res.availableInformationTypes, ', ');
            return;
        }
        
        insert newRecord;
        
        // Re-query to get auto-number Name
        newRecord = [
            SELECT Id, Name, Information_Type__c, Status__c, Notes__c, 
                   Program_Candidate__c, Program_Candidate__r.Name,
                   Case__c, Case__r.CaseNumber,
                   CreatedDate
            FROM Missing_Information__c 
            WHERE Id = :newRecord.Id
        ];
        
        res.success = true;
        res.record = newRecord;
        res.recordId = newRecord.Id;
        res.records = new List<Missing_Information__c>{ newRecord };
        res.message = 'Created missing information item: ' + newRecord.Information_Type__c + ' (' + newRecord.Name + ')';
    }
    
    private static void handleRead(Request req, Response res) {
        if (req.recordId == null) {
            res.success = false;
            res.errorMessage = 'Record ID is required for read operation.';
            return;
        }
        
        List<Missing_Information__c> items = [
            SELECT Id, Name, Information_Type__c, Status__c, Notes__c, 
                   Program_Candidate__c, Program_Candidate__r.Name, Program_Candidate__r.FirstName__c, Program_Candidate__r.LastName__c,
                   Case__c, Case__r.CaseNumber, Case__r.Subject,
                   CreatedDate, LastModifiedDate
            FROM Missing_Information__c 
            WHERE Id = :req.recordId
            LIMIT 1
        ];
        
        if (items.isEmpty()) {
            res.success = false;
            res.errorMessage = 'Missing Information record not found with ID: ' + req.recordId;
            return;
        }
        
        res.success = true;
        res.record = items[0];
        res.recordId = items[0].Id;
        res.records = items;
        res.message = 'Found missing information item: ' + items[0].Information_Type__c + ' - Status: ' + items[0].Status__c;
    }
    
    private static void handleUpdate(Request req, Response res) {
        if (req.recordId == null) {
            res.success = false;
            res.errorMessage = 'Record ID is required for update operation.';
            return;
        }
        
        Missing_Information__c existingRecord = [
            SELECT Id, Name, Information_Type__c, Status__c, Notes__c, 
                   Program_Candidate__c, Case__c
            FROM Missing_Information__c 
            WHERE Id = :req.recordId
            LIMIT 1
        ];
        
        String oldStatus = existingRecord.Status__c;
        
        // Parse field data JSON
        if (!String.isBlank(req.fieldDataJson)) {
            Map<String, Object> fieldData = (Map<String, Object>) JSON.deserializeUntyped(req.fieldDataJson);
            
            if (fieldData.containsKey('Information_Type__c')) {
                existingRecord.Information_Type__c = String.valueOf(fieldData.get('Information_Type__c'));
            }
            if (fieldData.containsKey('Status__c')) {
                existingRecord.Status__c = String.valueOf(fieldData.get('Status__c'));
            }
            if (fieldData.containsKey('Notes__c')) {
                existingRecord.Notes__c = String.valueOf(fieldData.get('Notes__c'));
            }
            if (fieldData.containsKey('Program_Candidate__c')) {
                existingRecord.Program_Candidate__c = Id.valueOf(String.valueOf(fieldData.get('Program_Candidate__c')));
            }
            if (fieldData.containsKey('Case__c')) {
                existingRecord.Case__c = Id.valueOf(String.valueOf(fieldData.get('Case__c')));
            }
        }
        
        update existingRecord;
        
        // Re-query
        existingRecord = [
            SELECT Id, Name, Information_Type__c, Status__c, Notes__c, 
                   Program_Candidate__c, Program_Candidate__r.Name,
                   Case__c, Case__r.CaseNumber,
                   CreatedDate, LastModifiedDate
            FROM Missing_Information__c 
            WHERE Id = :existingRecord.Id
        ];
        
        res.success = true;
        res.record = existingRecord;
        res.recordId = existingRecord.Id;
        res.records = new List<Missing_Information__c>{ existingRecord };
        
        if (oldStatus != existingRecord.Status__c) {
            res.message = 'Updated ' + existingRecord.Information_Type__c + ' status from ' + oldStatus + ' to ' + existingRecord.Status__c;
        } else {
            res.message = 'Updated missing information item: ' + existingRecord.Information_Type__c;
        }
    }
    
    private static void handleDelete(Request req, Response res) {
        if (req.recordId == null) {
            res.success = false;
            res.errorMessage = 'Record ID is required for delete operation.';
            return;
        }
        
        List<Missing_Information__c> items = [
            SELECT Id, Name, Information_Type__c 
            FROM Missing_Information__c 
            WHERE Id = :req.recordId 
            LIMIT 1
        ];
        
        if (items.isEmpty()) {
            res.success = false;
            res.errorMessage = 'Missing Information record not found with ID: ' + req.recordId;
            return;
        }
        
        String itemName = items[0].Name;
        String itemType = items[0].Information_Type__c;
        
        delete items;
        
        res.success = true;
        res.recordId = req.recordId;
        res.message = 'Deleted missing information item: ' + itemType + ' (' + itemName + ')';
    }
    
    private static void handleFind(Request req, Response res) {
        Integer searchLimit = req.searchLimit != null ? Math.min(req.searchLimit, 50) : 10;
        
        String query = 'SELECT Id, Name, Information_Type__c, Status__c, Notes__c, ' +
                      'Program_Candidate__c, Program_Candidate__r.Name, Program_Candidate__r.FirstName__c, Program_Candidate__r.LastName__c, ' +
                      'Case__c, Case__r.CaseNumber, Case__r.Subject, ' +
                      'CreatedDate, LastModifiedDate ' +
                      'FROM Missing_Information__c WHERE ';
        
        List<String> conditions = new List<String>();
        
        // Parent ID filters
        if (req.programCandidateId != null) {
            conditions.add('Program_Candidate__c = \'' + String.escapeSingleQuotes(String.valueOf(req.programCandidateId)) + '\'');
        }
        if (req.caseId != null) {
            conditions.add('Case__c = \'' + String.escapeSingleQuotes(String.valueOf(req.caseId)) + '\'');
        }
        
        // Status filter
        if (req.statusOnlyMissing != null && req.statusOnlyMissing) {
            conditions.add('Status__c = \'Missing\'');
        }
        
        // Search term
        if (!String.isBlank(req.searchTerm)) {
            String searchTerm = '%' + String.escapeSingleQuotes(req.searchTerm) + '%';
            conditions.add('(Information_Type__c LIKE \'' + searchTerm + '\' OR Notes__c LIKE \'' + searchTerm + '\')');
        }
        
        // Parse filters JSON
        if (!String.isBlank(req.filtersJson)) {
            try {
                Map<String, Object> filters = (Map<String, Object>) JSON.deserializeUntyped(req.filtersJson);
                for (String field : filters.keySet()) {
                    String value = String.valueOf(filters.get(field));
                    conditions.add(String.escapeSingleQuotes(field) + ' = \'' + String.escapeSingleQuotes(value) + '\'');
                }
            } catch (Exception e) {
                System.debug(LoggingLevel.DEBUG, 'AFMissingInformationAction: Could not parse filtersJson - ' + e.getMessage());
            }
        }
        
        // Default condition if none provided
        if (conditions.isEmpty()) {
            conditions.add('Id != null');
        }
        
        query += String.join(conditions, ' AND ');
        query += ' ORDER BY CreatedDate DESC LIMIT ' + searchLimit;
        
        System.debug(LoggingLevel.INFO, 'AFMissingInformationAction SOQL: ' + query);
        
        List<Missing_Information__c> results = Database.query(query);
        
        res.success = true;
        res.records = results;
        res.totalMatches = results.size();
        
        // Count missing vs received
        for (Missing_Information__c item : results) {
            if (item.Status__c == 'Missing') {
                res.missingCount++;
            } else if (item.Status__c == 'Received') {
                res.receivedCount++;
            }
        }
        
        if (results.isEmpty()) {
            res.message = 'No missing information items found matching the criteria.';
        } else if (results.size() == 1) {
            res.record = results[0];
            res.recordId = results[0].Id;
            res.message = 'Found 1 missing information item: ' + results[0].Information_Type__c + ' - Status: ' + results[0].Status__c;
        } else {
            res.message = 'Found ' + results.size() + ' missing information items (' + res.missingCount + ' missing, ' + res.receivedCount + ' received).';
        }
    }
}
