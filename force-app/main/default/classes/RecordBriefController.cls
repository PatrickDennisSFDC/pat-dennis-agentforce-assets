/**
 * Record Brief Controller
 * Generates AI-powered summaries of records (Account, Case, Program_Candidate__c) 
 * including all related child records for comprehensive context.
 * 
 * Uses a prompt template to generate natural language summaries that help
 * reps quickly understand the full picture of a patient/enrollment/case.
 */
public with sharing class RecordBriefController {
    
    // Prompt Template API Name
    private static final String PROMPT_TEMPLATE_NAME = 'Record_Brief_Generator';
    
    /**
     * Generate a brief summary for any supported record type
     * @param recordId The ID of the record to summarize (Account, Case, or Program_Candidate__c)
     * @return The generated brief text content
     */
    @AuraEnabled
    public static String generateRecordBrief(String recordId) {
        if (String.isBlank(recordId)) {
            throw new AuraHandledException('Record ID is required');
        }
        
        try {
            // Determine object type from ID
            String sObjectType = Id.valueOf(recordId).getSobjectType().getDescribe().getName();
            System.debug('[RecordBrief] Object type: ' + sObjectType);
            
            // Gather comprehensive record context
            String recordContext = gatherRecordContext(recordId, sObjectType);
            System.debug('[RecordBrief] Context gathered, length: ' + recordContext.length());
            
            // Invoke the prompt template with the context
            String generatedBrief = invokePromptTemplate(recordContext, sObjectType);
            
            return generatedBrief;
            
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            System.debug('[RecordBrief] Error: ' + e.getMessage() + '\n' + e.getStackTraceString());
            throw new AuraHandledException('Error generating record brief: ' + e.getMessage());
        }
    }
    
    /**
     * Gather comprehensive context for a record including all child records
     */
    private static String gatherRecordContext(String recordId, String sObjectType) {
        Map<String, Object> contextData = new Map<String, Object>();
        contextData.put('objectType', sObjectType);
        contextData.put('recordId', recordId);
        
        if (sObjectType == 'Account') {
            contextData.put('record', gatherAccountContext(recordId));
        } else if (sObjectType == 'Case') {
            contextData.put('record', gatherCaseContext(recordId));
        } else if (sObjectType == 'Program_Candidate__c') {
            contextData.put('record', gatherProgramCandidateContext(recordId));
        } else {
            throw new AuraHandledException('Unsupported object type: ' + sObjectType + '. Supported: Account, Case, Program_Candidate__c');
        }
        
        return JSON.serializePretty(contextData);
    }
    
    /**
     * Gather Account record and all related child records
     */
    private static Map<String, Object> gatherAccountContext(String recordId) {
        Map<String, Object> context = new Map<String, Object>();
        
        // Main Account record
        Account acc = [
            SELECT Id, Name, Type, Industry, Phone, Website, BillingCity, BillingState,
                   Description, OwnerId, Owner.Name, CreatedDate, LastModifiedDate,
                   // Person Account fields (may be null for business accounts)
                   IsPersonAccount, PersonEmail, PersonMobilePhone, PersonBirthdate,
                   PersonMailingCity, PersonMailingState
            FROM Account
            WHERE Id = :recordId
            LIMIT 1
        ];
        context.put('account', acc);
        
        // Related Contacts (for business accounts)
        List<Contact> contacts = [
            SELECT Id, Name, Title, Email, Phone, Department, CreatedDate
            FROM Contact
            WHERE AccountId = :recordId
            ORDER BY CreatedDate DESC
            LIMIT 10
        ];
        if (!contacts.isEmpty()) {
            context.put('contacts', contacts);
        }
        
        // Related Cases
        List<Case> cases = [
            SELECT Id, CaseNumber, Subject, Status, Priority, Type, 
                   Description, CreatedDate, ClosedDate
            FROM Case
            WHERE AccountId = :recordId
            ORDER BY CreatedDate DESC
            LIMIT 10
        ];
        if (!cases.isEmpty()) {
            context.put('cases', cases);
        }
        
        // Related Program Candidates
        List<Program_Candidate__c> candidates = [
            SELECT Id, Name, FirstName__c, LastName__c, Email__c, Phone__c,
                   Program_Name__c, Enrollment_Status__c, CreatedDate
            FROM Program_Candidate__c
            WHERE Account__c = :recordId
            ORDER BY CreatedDate DESC
            LIMIT 10
        ];
        if (!candidates.isEmpty()) {
            context.put('programCandidates', candidates);
        }
        
        // Related Tasks
        List<Task> tasks = [
            SELECT Id, Subject, Status, Priority, ActivityDate, Description, CreatedDate
            FROM Task
            WHERE WhatId = :recordId OR AccountId = :recordId
            ORDER BY CreatedDate DESC
            LIMIT 10
        ];
        if (!tasks.isEmpty()) {
            context.put('tasks', tasks);
        }
        
        // Related Missing Information (via Program Candidates)
        if (!candidates.isEmpty()) {
            Set<Id> candidateIds = new Set<Id>();
            for (Program_Candidate__c pc : candidates) {
                candidateIds.add(pc.Id);
            }
            List<Missing_Information__c> missingInfo = [
                SELECT Id, Name, Information_Type__c, Status__c, Notes__c, 
                       Program_Candidate__r.Name, CreatedDate
                FROM Missing_Information__c
                WHERE Program_Candidate__c IN :candidateIds
                ORDER BY CreatedDate DESC
                LIMIT 20
            ];
            if (!missingInfo.isEmpty()) {
                context.put('missingInformation', missingInfo);
            }
        }
        
        return context;
    }
    
    /**
     * Gather Case record and all related records
     */
    private static Map<String, Object> gatherCaseContext(String recordId) {
        Map<String, Object> context = new Map<String, Object>();
        
        // Main Case record
        Case c = [
            SELECT Id, CaseNumber, Subject, Status, Priority, Type, Origin,
                   Description, ClosedDate, CreatedDate, LastModifiedDate,
                   AccountId, Account.Name, ContactId, Contact.Name, Contact.Email,
                   OwnerId, Owner.Name
            FROM Case
            WHERE Id = :recordId
            LIMIT 1
        ];
        context.put('case', c);
        
        // Parent Account info
        if (c.AccountId != null) {
            Account acc = [
                SELECT Id, Name, Phone, IsPersonAccount, PersonEmail, PersonMobilePhone
                FROM Account
                WHERE Id = :c.AccountId
                LIMIT 1
            ];
            context.put('account', acc);
        }
        
        // Related Tasks
        List<Task> tasks = [
            SELECT Id, Subject, Status, Priority, ActivityDate, Description, CreatedDate
            FROM Task
            WHERE WhatId = :recordId
            ORDER BY CreatedDate DESC
            LIMIT 10
        ];
        if (!tasks.isEmpty()) {
            context.put('tasks', tasks);
        }
        
        // Related Missing Information
        List<Missing_Information__c> missingInfo = [
            SELECT Id, Name, Information_Type__c, Status__c, Notes__c, CreatedDate
            FROM Missing_Information__c
            WHERE Case__c = :recordId
            ORDER BY CreatedDate DESC
            LIMIT 20
        ];
        if (!missingInfo.isEmpty()) {
            context.put('missingInformation', missingInfo);
        }
        
        // Case Comments / Email Messages
        List<EmailMessage> emails = [
            SELECT Id, Subject, TextBody, FromAddress, ToAddress, MessageDate, Incoming
            FROM EmailMessage
            WHERE ParentId = :recordId
            ORDER BY MessageDate DESC
            LIMIT 10
        ];
        if (!emails.isEmpty()) {
            context.put('emailMessages', emails);
        }
        
        return context;
    }
    
    /**
     * Gather Program Candidate record and all related records
     */
    private static Map<String, Object> gatherProgramCandidateContext(String recordId) {
        Map<String, Object> context = new Map<String, Object>();
        
        // Main Program Candidate record
        Program_Candidate__c pc = [
            SELECT Id, Name, FirstName__c, LastName__c, Date_of_Birth__c,
                   Email__c, Phone__c, Preferred_Contact_Method__c, Language_Preference__c,
                   Street__c, City__c, State__c, Postal_Code__c, Country__c,
                   Program_Name__c, Enrollment_Status__c,
                   Insurance_Provider__c, Insurance_Policy_Number__c, Insurance_Group_Number__c,
                   Household_Size__c, Annual_Income__c, Notes__c,
                   Account__c, Account__r.Name, Contact__c, Contact__r.Name,
                   OwnerId, Owner.Name, CreatedDate, LastModifiedDate
            FROM Program_Candidate__c
            WHERE Id = :recordId
            LIMIT 1
        ];
        context.put('programCandidate', pc);
        
        // Parent Account info
        if (pc.Account__c != null) {
            Account acc = [
                SELECT Id, Name, Phone, IsPersonAccount, PersonEmail, PersonMobilePhone
                FROM Account
                WHERE Id = :pc.Account__c
                LIMIT 1
            ];
            context.put('account', acc);
        }
        
        // Related Missing Information
        List<Missing_Information__c> missingInfo = [
            SELECT Id, Name, Information_Type__c, Status__c, Notes__c, CreatedDate
            FROM Missing_Information__c
            WHERE Program_Candidate__c = :recordId
            ORDER BY CreatedDate DESC
            LIMIT 20
        ];
        if (!missingInfo.isEmpty()) {
            context.put('missingInformation', missingInfo);
        }
        
        // Related Tasks
        List<Task> tasks = [
            SELECT Id, Subject, Status, Priority, ActivityDate, Description, CreatedDate
            FROM Task
            WHERE WhatId = :recordId
            ORDER BY CreatedDate DESC
            LIMIT 10
        ];
        if (!tasks.isEmpty()) {
            context.put('tasks', tasks);
        }
        
        // Related Cases (via Account)
        if (pc.Account__c != null) {
            List<Case> cases = [
                SELECT Id, CaseNumber, Subject, Status, Priority, Type, CreatedDate
                FROM Case
                WHERE AccountId = :pc.Account__c
                ORDER BY CreatedDate DESC
                LIMIT 5
            ];
            if (!cases.isEmpty()) {
                context.put('relatedCases', cases);
            }
        }
        
        // Related Diagnostic Test Orders
        List<Diagnostic_Test_Order__c> testOrders = [
            SELECT Id, Name, Test_Type__c, Status__c, Order_Date__c, Account__r.Name
            FROM Diagnostic_Test_Order__c
            WHERE Account__c = :pc.Account__c
            ORDER BY Order_Date__c DESC
            LIMIT 10
        ];
        if (!testOrders.isEmpty()) {
            context.put('diagnosticTestOrders', testOrders);
        }
        
        return context;
    }
    
    /**
     * Invoke the prompt template with gathered context
     */
    private static String invokePromptTemplate(String recordContext, String objectType) {
        try {
            // Create input parameters for the prompt template
            Map<String, ConnectApi.WrappedValue> inputParams = new Map<String, ConnectApi.WrappedValue>();
            
            // Add record context as a string parameter
            ConnectApi.WrappedValue contextValue = new ConnectApi.WrappedValue();
            contextValue.value = recordContext;
            inputParams.put('Input:RecordContext', contextValue);
            
            // Add object type for context
            ConnectApi.WrappedValue objectTypeValue = new ConnectApi.WrappedValue();
            objectTypeValue.value = objectType;
            inputParams.put('Input:ObjectType', objectTypeValue);
            
            // Configure the generation input
            ConnectApi.EinsteinPromptTemplateGenerationsInput generationInput = new ConnectApi.EinsteinPromptTemplateGenerationsInput();
            generationInput.inputParams = inputParams;
            generationInput.isPreview = false;
            
            // Additional config
            ConnectApi.EinsteinLlmAdditionalConfigInput additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
            additionalConfig.applicationName = 'PromptTemplateGenerationsInvocable';
            generationInput.additionalConfig = additionalConfig;
            
            System.debug('[RecordBrief] Invoking prompt template: ' + PROMPT_TEMPLATE_NAME);
            
            // Invoke the prompt template using ConnectApi
            ConnectApi.EinsteinPromptTemplateGenerationsRepresentation response = 
                ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate(
                    PROMPT_TEMPLATE_NAME,
                    generationInput
                );
            
            // Extract the generated text
            if (response.generations != null && !response.generations.isEmpty()) {
                ConnectApi.EinsteinLLMGenerationItemOutput firstGen = response.generations[0];
                String generatedText = firstGen.text;
                
                if (String.isNotBlank(generatedText)) {
                    System.debug('[RecordBrief] Generated content length: ' + generatedText.length());
                    return generatedText;
                }
            }
            
            throw new AuraHandledException('No content was generated from the prompt template');
            
        } catch (ConnectApi.ConnectApiException e) {
            System.debug('[RecordBrief] ConnectApi Error: ' + e.getMessage());
            String userMessage = parseConnectApiError(e.getMessage());
            throw new AuraHandledException(userMessage);
        }
    }
    
    /**
     * Get brief metadata for UI display (record name, type, etc.)
     */
    @AuraEnabled
    public static Map<String, Object> getRecordMetadata(String recordId) {
        if (String.isBlank(recordId)) {
            throw new AuraHandledException('Record ID is required');
        }
        
        Map<String, Object> metadata = new Map<String, Object>();
        
        try {
            String sObjectType = Id.valueOf(recordId).getSobjectType().getDescribe().getName();
            metadata.put('objectType', sObjectType);
            metadata.put('objectLabel', Id.valueOf(recordId).getSobjectType().getDescribe().getLabel());
            
            if (sObjectType == 'Account') {
                Account acc = [SELECT Id, Name, IsPersonAccount FROM Account WHERE Id = :recordId LIMIT 1];
                metadata.put('recordName', acc.Name);
                metadata.put('isPersonAccount', acc.IsPersonAccount);
            } else if (sObjectType == 'Case') {
                Case c = [SELECT Id, CaseNumber, Subject FROM Case WHERE Id = :recordId LIMIT 1];
                metadata.put('recordName', c.CaseNumber + ': ' + c.Subject);
            } else if (sObjectType == 'Program_Candidate__c') {
                Program_Candidate__c pc = [SELECT Id, Name, FirstName__c, LastName__c FROM Program_Candidate__c WHERE Id = :recordId LIMIT 1];
                String fullName = (String.isNotBlank(pc.FirstName__c) ? pc.FirstName__c + ' ' : '') + 
                                  (String.isNotBlank(pc.LastName__c) ? pc.LastName__c : pc.Name);
                metadata.put('recordName', fullName);
            }
            
            return metadata;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error getting record metadata: ' + e.getMessage());
        }
    }
    
    /**
     * Parse ConnectApi error messages into user-friendly text
     */
    private static String parseConnectApiError(String errorMessage) {
        if (errorMessage.containsIgnoreCase('not found') || errorMessage.containsIgnoreCase('does not exist')) {
            return 'Prompt template "' + PROMPT_TEMPLATE_NAME + '" not found. Please create it in Prompt Builder.';
        }
        if (errorMessage.containsIgnoreCase('INSUFFICIENT_ACCESS') || errorMessage.containsIgnoreCase('permission')) {
            return 'Insufficient permissions to invoke prompt templates. Check your user permissions.';
        }
        if (errorMessage.containsIgnoreCase('model') || errorMessage.containsIgnoreCase('LLM')) {
            return 'LLM generation failed. Ensure a model is selected in the prompt template.';
        }
        return 'Failed to generate brief: ' + errorMessage;
    }
}
