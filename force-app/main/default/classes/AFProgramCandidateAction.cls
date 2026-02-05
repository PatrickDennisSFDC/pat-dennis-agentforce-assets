/**
 * AF Program Candidate Action
 * Consolidated invocable action for all Program_Candidate__c CRUD operations (Create, Read, Update, Delete, Find)
 * Designed for Agentforce AI agents
 * 
 * Use Case: Post-prescription support enrollment where patients call in after receiving a prescription
 * and AI agents capture candidate information through conversation to enroll them in support programs.
 * Records are created incrementally as information is gathered during phone enrollment calls.
 */
public without sharing class AFProgramCandidateAction {
    
    public class Request {
        @InvocableVariable(
            label='Operation'
            description='Explicit operation: "create", "read", "update", "delete", or "find". If not specified, inferred from context.'
        )
        public String operation;
        
        @InvocableVariable(
            label='Field Data JSON'
            description='JSON string containing Program Candidate field data. All fields are optional in Salesforce, but for COMPLETE ENROLLMENT you should collect ALL information before submitting. WORKFLOW: Always call with confirm=false FIRST to preview what would be created (this does NOT create the record). Check the response for suggestedFields and previewData. The system will tell you what fields are missing. Continue asking questions and calling with confirm=false until you have collected all available information. Only call with confirm=true when ready to submit. FIELD COLLECTION GUIDE - Collect in this order but be flexible based on user responses: (1) Basic Information: "First Name" → FirstName__c, "Last Name" → LastName__c, "Date of Birth" or "DOB" → Date_of_Birth__c (format: YYYY-MM-DD, accept "July 14 1997" and convert). (2) Contact Information: "Phone" or "Phone Number" → Phone__c, "Email" or "Email Address" → Email__c, "Preferred Contact Method" → Preferred_Contact_Method__c (query availableFieldsJson for values: Phone, Email, Text, Mail), "Language" or "Language Preference" → Language_Preference__c (query availableFieldsJson for values: English (default), Spanish, French, German, Other). (3) Address: Parse full addresses into "Street" or "Street Address" → Street__c, "City" → City__c, "State" → State__c, "Postal Code" or "ZIP Code" → Postal_Code__c, "Country" → Country__c (defaults to "United States" if not specified). (4) Program Information: "Program Name" or "Medication Name" or "Drug Name" → Program_Name__c (typically the prescribed drug/medication name). (5) Eligibility (ESSENTIAL - ask before submitting): "Household Size" → Household_Size__c (query availableFieldsJson for values: 1, 2, 3, 4, 5, 6, 7, 8 or more, Prefer not to answer), "Income" or "Annual Income" → Annual_Income__c (query availableFieldsJson for income ranges). Ask: "To help determine eligibility, I\'ll need to know your household size and approximate annual income." (6) Insurance Information (ESSENTIAL - ask before submitting): "Insurance Provider" → Insurance_Provider__c, "Insurance Policy Number" or "Policy Number" or "Member ID" → Insurance_Policy_Number__c, "Insurance Group Number" or "Group Number" → Insurance_Group_Number__c. Ask: "Do you have your insurance card handy? I\'ll need your insurance provider name, policy number, and group number." If user declines to provide insurance or eligibility, you can still submit but note it in your message. (7) Notes (OPTIONAL but valuable): "Notes" → Notes__c (rich text field). Use this field to capture a summary of the enrollment conversation, any remarkable comments from the patient, overall interaction context, or notable details that would be valuable for human users reviewing the record. Do NOT recount all field values - focus on interaction summary, context, and remarkable comments. For example: "Patient mentioned they have been struggling with medication adherence in the past and are hopeful this program will help." or "Patient expressed concern about insurance coverage but was relieved to learn about the program." Account/Contact: Use accountName parameter for Account__c, contactNameOrEmail parameter for Contact__c (do NOT put Account__c or Contact__c in fieldDataJson). Example: {"LastName__c":"Smith","FirstName__c":"John","Date_of_Birth__c":"1980-05-15","Phone__c":"555-123-4567","Email__c":"john.smith@example.com","Preferred_Contact_Method__c":"Phone","Language_Preference__c":"English","Street__c":"123 Main St","City__c":"San Francisco","State__c":"CA","Postal_Code__c":"94105","Country__c":"United States","Program_Name__c":"Product XYZ","Enrollment_Status__c":"New Inquiry","Household_Size__c":"3","Annual_Income__c":"75000_to_99999","Insurance_Provider__c":"Blue Cross Blue Shield","Insurance_Policy_Number__c":"POL123456","Insurance_Group_Number__c":"GRP789","Notes__c":"Patient was very engaged during the call and asked several questions about program benefits. Mentioned previous challenges with medication adherence and is optimistic about the support program."}. Query availableFieldsJson to see valid picklist options.'
            required=false
        )
        public String fieldDataJson;
        
        @InvocableVariable(
            label='Record ID'
            description='The Salesforce record ID (15 or 18 character) of the Program Candidate. Required for read/update/delete operations. Format: 18-character ID like "a0Xxx000003DGbYAAW". For update, can be omitted if identifying fields like FirstName+LastName or Email are provided in fieldDataJson for automatic resolution.'
        )
        public Id recordId;
        
        @InvocableVariable(
            label='Search Term'
            description='Text to search for in Program Candidate fields (FirstName__c, LastName__c, Email__c). Used for find operations. Example: "John Smith", "john.smith@example.com", or "Smith". Search is case-insensitive and supports partial matches. IMPORTANT: If the user wants to find a program candidate but has not provided a search term, ask them for the candidate name or email BEFORE calling this action. Do not call find operation without a searchTerm or filtersJson.'
        )
        public String searchTerm;
        
        @InvocableVariable(
            label='Filters JSON'
            description='JSON string of exact-match filters for find operations. Supports both structured format {"fieldApiName":"Enrollment_Status__c","value":"New Inquiry"} and simple format {"Enrollment_Status__c":"New Inquiry"}. Can also be an array of filters. Example: {"Enrollment_Status__c":"New Inquiry"} or {"Program_Name__c":"Product XYZ"}. IMPORTANT: If the user wants to find a program candidate but has not provided specific filters, ask them for details like enrollment status, program name, or other identifying information BEFORE calling this action. Do not call find operation without a searchTerm or filtersJson.'
        )
        public String filtersJson;
        
        @InvocableVariable(
            label='Search Limit'
            description='Maximum number of records to return for find operations (default: 5, max: 20).'
        )
        public Integer searchLimit;
        
        @InvocableVariable(
            label='Account Name'
            description='Account name to resolve to Account__c lookup. If provided, system searches for an Account and links the record to it. System should use best judgement to match by phone/email when creating records.'
        )
        public String accountName;
        
        @InvocableVariable(
            label='Contact Name or Email'
            description='Contact name or email to resolve to Contact__c lookup. If provided, system searches for a Contact and links the record to them. System should use best judgement to match by phone/email when creating records.'
        )
        public String contactNameOrEmail;
        
        @InvocableVariable(
            label='Confirm'
            description='For create operations: CRITICAL - Always set to false FIRST to preview what would be created. This does NOT create the record. Check the response for suggestedFields and previewData to see what information is missing. Continue asking questions and calling with confirm=false until you have collected all available information. Only set to true when you have gathered all information OR the user explicitly wants to submit with incomplete information. The system will validate completeness and guide you. For update: Set to false to preview only without committing. Default (true): Commits immediately. For delete: Set to true to actually delete. Default (false): Returns confirmation message first. The agent should first call delete with confirm=false, ask the user, then call again with confirm=true if confirmed.'
        )
        public Boolean confirm;
    }
    
    public class Response {
        @InvocableVariable(
            label='Success'
            description='True if operation completed successfully, false if an error occurred. Check this before using other output variables.'
        )
        public Boolean success;
        
        @InvocableVariable(
            label='Record'
            description='The Program Candidate record (for single record operations: create, read, update). Use the record.Id field from this record for follow-up operations. This is null for bulk operations or when multiple records are found.'
        )
        public Program_Candidate__c record;
        
        @InvocableVariable(
            label='Records'
            description='List of Program Candidate records (for bulk operations or find operations with multiple results). Use record.Id from each record for subsequent operations.'
        )
        public List<Program_Candidate__c> records;
        
        @InvocableVariable(
            label='Record ID'
            description='The Salesforce ID of the record (18-character format like "a0Xxx000003DGbYAAW"). Use this ID for subsequent operations. This is the primary identifier for follow-up operations in the conversation.'
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
            description='The Salesforce object type, always "Program_Candidate__c" for Program Candidate operations. Useful for agent context and logging.'
        )
        public String objectType;
        
        @InvocableVariable(
            label='Operation'
            description='The operation that was performed: "create", "read", "update", "delete", or "find". Useful for agent context and logging.'
        )
        public String operation;
        
        @InvocableVariable(
            label='Preview Only'
            description='True if this is a preview response (confirm=false was set). When true, no data was actually saved - this shows what would be created/updated. CRITICAL: When previewOnly is true, check suggestedFields to see what fields are missing. Ask the user for missing information, especially insurance and eligibility fields. Continue collecting information and calling with confirm=false until you have all available information. Only call with confirm=true when ready to submit.'
        )
        public Boolean previewOnly;
        
        @InvocableVariable(
            label='Enrichment Suggested'
            description='True if additional fields are suggested for the record. When true, check suggestedFields for commonly-used field API names that might be relevant.'
        )
        public Boolean enrichmentSuggested;
        
        @InvocableVariable(
            label='Suggested Fields'
            description='List of commonly-used field API names that might be relevant to populate. When previewOnly is true and enrichmentSuggested is true, this list shows fields that are missing. Ask the user for these missing fields before submitting. For Program Candidate enrollment, prioritize collecting: Insurance_Provider__c, Insurance_Policy_Number__c, Insurance_Group_Number__c, Household_Size__c, Annual_Income__c, and other contact/address fields.'
        )
        public List<String> suggestedFields;
        
        @InvocableVariable(
            label='Preview Data'
            description='A JSON string representation of what would be created/updated when previewOnly is true. Use this to show the user what would happen before committing changes.'
        )
        public String previewData;
        
        @InvocableVariable(
            label='Available Fields JSON'
            description='JSON string containing metadata for all available fields including field types, picklist values, and descriptions. Use this to see valid picklist options (e.g., Enrollment_Status__c, Preferred_Contact_Method__c, Language_Preference__c) instead of asking the user. Query this from a read operation to get field metadata.'
        )
        public String availableFieldsJson;
        
        @InvocableVariable(
            label='Ambiguous Relationship'
            description='True if a parent lookup (Account__c or Contact__c) found multiple matches. When true, use relationshipCandidatesJson to show candidates to the user for clarification before proceeding.'
        )
        public Boolean ambiguousRelationship;
        
        @InvocableVariable(
            label='Ambiguous Relationship Type'
            description='The type of relationship that has multiple matches: "Account" or "Contact". Use this to inform the user which relationship needs clarification.'
        )
        public String ambiguousRelationshipType;
        
        @InvocableVariable(
            label='Relationship Candidates JSON'
            description='JSON array of candidate records when ambiguousRelationship is true. Contains Account or Contact records with distinguishing details. Use this to prompt the user to select the correct match.'
        )
        public String relationshipCandidatesJson;
        
        @InvocableVariable(
            label='Ambiguous Result'
            description='True if multiple Program Candidate records were found in a find/search operation. When true, use the records array to show candidates to the user for clarification.'
        )
        public Boolean ambiguous;
        
        @InvocableVariable(
            label='Total Matches'
            description='Number of Program Candidate records found in a find/search operation. If this equals or exceeds the searchLimit, moreResultsAvailable will be true.'
        )
        public Integer totalMatches;
        
        @InvocableVariable(
            label='More Results Available'
            description='True if the search returned the maximum number of results but there are more matching records available.'
        )
        public Boolean moreResultsAvailable;
        
        @InvocableVariable(
            label='Confirmation Required'
            description='True if this is a confirmation request for delete operation (delete was called with confirm=false). When true, call delete again with confirm=true to actually delete the record.'
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
        label='Agentforce Program Candidate Action'
        description='Performs CRUD operations on Program_Candidate__c records for post-prescription support enrollment. Operation can be explicitly specified (create, read, update, delete, find) or inferred from context. CREATE WORKFLOW - CRITICAL: For complete enrollment, you MUST collect ALL information before submitting. Use this workflow: (1) First, call with confirm=false to preview what would be created (this does NOT create the record). (2) Check the suggestedFields and previewData in the response to see what fields are missing. (3) Ask the user for missing information, especially insurance (Insurance_Provider__c, Insurance_Policy_Number__c, Insurance_Group_Number__c) and eligibility (Household_Size__c, Annual_Income__c) - these are essential. (4) Continue collecting information and calling with confirm=false until you have gathered all available information. (5) Only call with confirm=true when you have collected all information OR the user explicitly wants to submit with incomplete information. The system will validate completeness and guide you. For complete enrollment, collect: Basic Info (FirstName, LastName, DateOfBirth), Contact (Phone, Email, PreferredContactMethod, LanguagePreference), Address (Street, City, State, PostalCode, Country), Program (ProgramName), Eligibility (HouseholdSize, AnnualIncome), Insurance (Provider, PolicyNumber, GroupNumber). Records typically start in "New Inquiry" status. READ: Provide recordId. UPDATE: Provide recordId + fieldDataJson. DELETE: Provide recordId + confirm=true. FIND: IMPORTANT - Before calling find operation, ensure you have search criteria. If the user wants to find a record but hasn\'t provided a search term, ask them for details first. Search uses FirstName, LastName, and Email fields. Supports accountName and contactNameOrEmail parameters to link to Account/Contact. System uses best judgement to match by phone/email when creating records. Supports bulk operations.'
        category='CRM Actions'
    )
    public static List<Response> programCandidateAction(List<Request> requests) {
        List<Response> responses = new List<Response>();
        
        for (Request req : requests) {
            Response res = new Response();
            res.objectType = 'Program_Candidate__c';
            res.success = false;
            res.records = new List<Program_Candidate__c>();
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
                        List<Program_Candidate__c> candidates = [SELECT Id, Name FROM Program_Candidate__c WHERE Id = :req.recordId LIMIT 1];
                        if (!candidates.isEmpty()) {
                            res.message = 'This will delete Program Candidate \'' + candidates[0].Name + '\'. Call again with confirm=true to proceed.';
                            res.success = true;
                        } else {
                            res.message = 'Record not found with ID ' + req.recordId + '.';
                            res.errorMessage = res.message;
                            res.success = false;
                        }
                    } catch (Exception e) {
                        res.message = 'This will delete the Program Candidate. Call again with confirm=true to proceed.';
                        res.success = true;
                    }
                    responses.add(res);
                    continue;
                }
                
                AFUniversalCrmRecordAction.Request actionReq = new AFUniversalCrmRecordAction.Request();
                actionReq.objectApiName = 'Program_Candidate__c';
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
                        System.debug(LoggingLevel.DEBUG, 'AFProgramCandidateAction: fieldDataJson is not a bulk array, treating as single record');
                    }
                }
                
                // Execute with retry logic for transient errors
                AFUniversalCrmRecordAction.Response actionRes = executeWithRetry(actionReq, op);
                
                if (actionRes.success) {
                    res.success = true;
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
                        res.record = (Program_Candidate__c) actionRes.record;
                        res.recordId = res.record.Id;
                        res.records = new List<Program_Candidate__c>{ res.record };
                    } else if (actionRes.records != null && !actionRes.records.isEmpty()) {
                        res.records = new List<Program_Candidate__c>();
                        for (SObject so : actionRes.records) {
                            res.records.add((Program_Candidate__c) so);
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
                    
                    // Handle preview mode - validate completeness and guide agent
                    if (op == 'create' && res.previewOnly) {
                        // Parse previewData to check for missing critical fields
                        Map<String, Object> previewMap = new Map<String, Object>();
                        try {
                            if (!String.isBlank(res.previewData)) {
                                previewMap = (Map<String, Object>) JSON.deserializeUntyped(res.previewData);
                            }
                        } catch (Exception e) {
                            System.debug(LoggingLevel.DEBUG, 'AFProgramCandidateAction: Could not parse previewData');
                        }
                        
                        List<String> missingCriticalFields = new List<String>();
                        List<String> missingOtherFields = new List<String>();
                        
                        // Check for missing insurance information
                        if (String.isBlank(String.valueOf(previewMap.get('Insurance_Provider__c')))) {
                            missingCriticalFields.add('insurance provider');
                        }
                        if (String.isBlank(String.valueOf(previewMap.get('Insurance_Policy_Number__c')))) {
                            missingCriticalFields.add('insurance policy number');
                        }
                        if (String.isBlank(String.valueOf(previewMap.get('Insurance_Group_Number__c')))) {
                            missingCriticalFields.add('insurance group number');
                        }
                        
                        // Check for missing eligibility information
                        if (String.isBlank(String.valueOf(previewMap.get('Household_Size__c')))) {
                            missingCriticalFields.add('household size');
                        }
                        if (String.isBlank(String.valueOf(previewMap.get('Annual_Income__c')))) {
                            missingCriticalFields.add('annual income');
                        }
                        
                        // Check for other important fields
                        if (String.isBlank(String.valueOf(previewMap.get('Phone__c')))) {
                            missingOtherFields.add('phone number');
                        }
                        if (String.isBlank(String.valueOf(previewMap.get('Email__c')))) {
                            missingOtherFields.add('email address');
                        }
                        if (String.isBlank(String.valueOf(previewMap.get('Street__c')))) {
                            missingOtherFields.add('address');
                        }
                        if (String.isBlank(String.valueOf(previewMap.get('Date_of_Birth__c')))) {
                            missingOtherFields.add('date of birth');
                        }
                        
                        // Build guidance message
                        if (!missingCriticalFields.isEmpty()) {
                            String criticalList = String.join(missingCriticalFields, ', ');
                            res.message = 'I\'ve collected the information so far. However, to complete your enrollment, I still need your ' + criticalList + '. Please continue providing this information.';
                            res.enrichmentSuggested = true;
                        } else if (!missingOtherFields.isEmpty()) {
                            String otherList = String.join(missingOtherFields, ', ');
                            res.message = 'I\'ve collected most of the information. I could also use your ' + otherList + ' if you\'d like to provide it. Otherwise, I can submit your enrollment with what we have.';
                            res.enrichmentSuggested = true;
                        } else {
                            res.message = 'I\'ve collected all the information for your enrollment. Would you like me to submit it now?';
                        }
                    }
                    // Handle actual create (confirm=true) - user-friendly messages
                    else if (op == 'create' && res.record != null && !res.previewOnly) {
                        Program_Candidate__c candidate = res.record;
                        List<String> missingFields = new List<String>();
                        
                        // Check for missing insurance information
                        if (String.isBlank(candidate.Insurance_Provider__c)) {
                            missingFields.add('insurance information');
                        }
                        if (String.isBlank(candidate.Insurance_Policy_Number__c)) {
                            missingFields.add('insurance policy number');
                        }
                        
                        // Check for missing eligibility information
                        if (String.isBlank(candidate.Household_Size__c)) {
                            missingFields.add('household size');
                        }
                        if (String.isBlank(candidate.Annual_Income__c)) {
                            missingFields.add('annual income');
                        }
                        
                        if (missingFields.isEmpty()) {
                            res.message = 'Your enrollment has been successfully submitted! Your enrollment is in "New Inquiry" status, and someone will contact you within 24 hours to complete the process.';
                        } else {
                            String missingList = String.join(missingFields, ', ');
                            res.message = 'Your enrollment has been created! However, to complete your enrollment, we still need your ' + missingList + '. Someone will contact you within 24 hours to collect this information and finalize your enrollment.';
                            res.enrichmentSuggested = true;
                        }
                    } else {
                        res.message = actionRes.message != null ? actionRes.message : 'Operation completed successfully.';
                    }
                    
                    if (op == 'find' || op == 'search') {
                        Integer searchLimit = req.searchLimit != null ? req.searchLimit : 5;
                        if (res.totalMatches >= searchLimit) {
                            res.moreResultsAvailable = true;
                        }
                    }
                } else {
                    res.success = false;
                    // Generate user-friendly, specific error messages
                    res.errorMessage = generateUserFriendlyError(actionRes.message, op, req);
                    res.message = res.errorMessage;
                }
                
            } catch (AFUniversalCrmRecordAction.ActionException ae) {
                res.success = false;
                res.errorMessage = generateUserFriendlyError(ae.getMessage(), res.operation, req);
                res.message = res.errorMessage;
                System.debug(LoggingLevel.ERROR, 'AFProgramCandidateAction: ActionException - ' + ae.getMessage());
            } catch (Exception e) {
                res.success = false;
                res.errorMessage = generateUserFriendlyError(e.getMessage(), res.operation, req);
                res.message = res.errorMessage;
                System.debug(LoggingLevel.ERROR, 'AFProgramCandidateAction: Exception - ' + e.getMessage());
            }
            
            responses.add(res);
        }
        
        return responses;
    }
    
    /**
     * Execute action with automatic retry for transient errors
     * Retries once for DML/connection errors before returning failure
     */
    private static AFUniversalCrmRecordAction.Response executeWithRetry(
        AFUniversalCrmRecordAction.Request actionReq, 
        String operation
    ) {
        AFUniversalCrmRecordAction.Response actionRes;
        Integer maxRetries = 1;
        Integer retryCount = 0;
        Boolean shouldRetry = true;
        
        while (shouldRetry && retryCount <= maxRetries) {
            actionRes = AFUniversalCrmRecordAction.processRequest(actionReq);
            
            if (actionRes.success) {
                shouldRetry = false;
            } else {
                // Check if this is a retryable error
                String errorMsg = actionRes.message != null ? actionRes.message.toLowerCase() : '';
                Boolean isRetryable = isRetryableError(errorMsg);
                
                if (isRetryable && retryCount < maxRetries) {
                    retryCount++;
                    System.debug(LoggingLevel.INFO, 'AFProgramCandidateAction: Retrying ' + operation + ' operation (attempt ' + (retryCount + 1) + ')');
                    // Small delay before retry (simulated via debug)
                    System.debug(LoggingLevel.DEBUG, 'AFProgramCandidateAction: Retry delay...');
                } else {
                    shouldRetry = false;
                }
            }
        }
        
        if (retryCount > 0 && actionRes.success) {
            System.debug(LoggingLevel.INFO, 'AFProgramCandidateAction: Operation succeeded after ' + retryCount + ' retry(ies)');
        }
        
        return actionRes;
    }
    
    /**
     * Determine if an error is transient and worth retrying
     */
    private static Boolean isRetryableError(String errorMsg) {
        if (String.isBlank(errorMsg)) return false;
        
        // Retryable error patterns
        return errorMsg.contains('unable to lock row') ||
               errorMsg.contains('record currently unavailable') ||
               errorMsg.contains('deadlock') ||
               errorMsg.contains('timeout') ||
               errorMsg.contains('connection') ||
               errorMsg.contains('temporarily unavailable') ||
               errorMsg.contains('try again');
    }
    
    /**
     * Generate user-friendly, specific error messages
     * Avoids generic "there was an issue" messages that frustrate patients
     */
    private static String generateUserFriendlyError(String technicalError, String operation, Request req) {
        if (String.isBlank(technicalError)) {
            technicalError = 'Unknown error';
        }
        
        String errorLower = technicalError.toLowerCase();
        
        // Data validation errors - be specific about what's wrong
        if (errorLower.contains('invalid email') || errorLower.contains('email format')) {
            return 'The email address format doesn\'t look quite right. Could you double-check it? It should look like name@example.com.';
        }
        if (errorLower.contains('invalid phone') || errorLower.contains('phone format')) {
            return 'The phone number format doesn\'t look quite right. Please provide a 10-digit phone number.';
        }
        if (errorLower.contains('invalid date') || errorLower.contains('date format')) {
            return 'I couldn\'t understand that date format. Could you provide your date of birth as month/day/year (like 01/15/1990)?';
        }
        if (errorLower.contains('required field') || errorLower.contains('missing required')) {
            return 'I\'m missing some required information. Let me ask you a few more questions to complete your enrollment.';
        }
        
        // Duplicate/existing record errors
        if (errorLower.contains('duplicate') || errorLower.contains('already exists')) {
            return 'It looks like we may already have an enrollment for you. Let me check on that - can you confirm your email address?';
        }
        
        // Connection/system errors - reassure data is safe
        if (errorLower.contains('timeout') || errorLower.contains('connection') || errorLower.contains('unavailable')) {
            return 'Our system is running a bit slow right now, but don\'t worry - I\'ve saved all the information you\'ve provided. Would you like me to try submitting again, or would you prefer to speak with a representative who can complete this for you?';
        }
        
        // Permission/access errors
        if (errorLower.contains('permission') || errorLower.contains('access denied') || errorLower.contains('insufficient')) {
            return 'I\'m having trouble accessing the enrollment system right now. Let me connect you with a patient services representative who can help complete your enrollment. All the information you\'ve shared will be passed along.';
        }
        
        // Record not found (for updates/reads)
        if (errorLower.contains('not found') || errorLower.contains('no record')) {
            if (operation == 'find' || operation == 'read') {
                return 'I couldn\'t find an existing enrollment with that information. Would you like to start a new enrollment?';
            }
            return 'I couldn\'t locate that enrollment record. Let me help you start fresh or connect you with a representative.';
        }
        
        // Generic fallback - but still helpful and specific about next steps
        if (operation == 'create') {
            return 'I wasn\'t able to submit your enrollment just now, but I\'ve saved all the information you\'ve provided. Would you like me to try again, or would you prefer to speak with a representative who can complete this for you right away?';
        } else if (operation == 'update') {
            return 'I wasn\'t able to update your enrollment just now. Would you like me to try again, or would you prefer to speak with a representative?';
        } else if (operation == 'find') {
            return 'I\'m having trouble searching our records right now. Could you try providing your information again, or would you like to speak with a representative?';
        }
        
        // Ultimate fallback
        return 'I ran into a technical issue, but don\'t worry - I can connect you with a patient services representative who can help right away. Would you like me to do that?';
    }
}







