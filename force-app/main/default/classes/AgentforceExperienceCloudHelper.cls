// File: AgentforceExperienceCloudHelper.cls
public with sharing class AgentforceExperienceCloudHelper {

    private static final String COPILOT_ACTION_TYPE = 'generateAiAgentResponse';

    public class MessageRequest {
        @AuraEnabled public String contextId { get; set; }
        @AuraEnabled public String formattedTranscriptLine { get; set; }
        @AuraEnabled public String currentSessionId { get; set; }
        @AuraEnabled public String channel { get; set; }
        @AuraEnabled public String actionNameFromLwc { get; set; }
    }

    public class AgentforceConversationResponseWrapper {
        @AuraEnabled public String agentResponse { get; set; }
        @AuraEnabled public String sessionId { get; set; }
        @AuraEnabled public String error { get; set; }
        @AuraEnabled public Boolean isSuccess { get; set; }
        public AgentforceConversationResponseWrapper() {
            this.isSuccess = false; this.agentResponse = ''; this.sessionId = null; this.error = '';
        }
    }

    @AuraEnabled
    public static AgentforceConversationResponseWrapper sendMessage(MessageRequest request) {
        AgentforceConversationResponseWrapper responseWrapper = new AgentforceConversationResponseWrapper();
        String agentActionName = request.actionNameFromLwc;

        if (String.isBlank(agentActionName)) {
            responseWrapper.error = 'Agentforce Action Name from LWC is not configured or missing.';
            System.debug(LoggingLevel.ERROR, 'AgentforceExperienceCloudHelper.sendMessage: ' + responseWrapper.error);
            return responseWrapper;
        }
        System.debug(LoggingLevel.INFO, 'AgentforceExperienceCloudHelper.sendMessage: Calling Action=' + agentActionName + 
            ', ContextId=' + request.contextId + ', Session=' + request.currentSessionId);

        try {
            Invocable.Action action = Invocable.Action.createCustomAction(COPILOT_ACTION_TYPE, agentActionName);
            action.setInvocationParameter('userMessage', request.formattedTranscriptLine);
            if (String.isNotBlank(request.currentSessionId)) action.setInvocationParameter('sessionId', request.currentSessionId);
            if (String.isNotBlank(request.contextId)) action.setInvocationParameter('recordId', request.contextId);
            
            List<Invocable.Action.Result> results = action.invoke();

            if (results != null && !results.isEmpty()) {
                Invocable.Action.Result result = results[0];
                if (result.isSuccess()) {
                    Map<String, Object> outputParams = result.getOutputParameters();
                    responseWrapper.agentResponse = (String)outputParams.get('agentResponse');
                    responseWrapper.sessionId = (String)outputParams.get('sessionId');
                    responseWrapper.isSuccess = true;
                } else {
                    responseWrapper.error = 'Agentforce action failed: ' + JSON.serialize(result.getErrors());
                    System.debug(LoggingLevel.ERROR, 'AgentforceExperienceCloudHelper: Invocable Action error: ' + responseWrapper.error);
                }
            } else {
                responseWrapper.error = 'Agentforce action returned no result.';
                System.debug(LoggingLevel.ERROR, 'AgentforceExperienceCloudHelper: ' + responseWrapper.error);
            }
        } catch (Exception e) {
            responseWrapper.error = 'System error calling Agentforce: ' + e.getMessage();
            System.debug(LoggingLevel.ERROR, 'AgentforceExperienceCloudHelper: Exception: ' + e.getMessage() + '\n' + e.getStackTraceString());
        }
        return responseWrapper;
    }

    public class FlowDetailsWrapper {
        @AuraEnabled public String label { get; set; } @AuraEnabled public String description { get; set; }
        @AuraEnabled public String error { get; set; } @AuraEnabled public Boolean isSuccess { get; set; }
        public FlowDetailsWrapper() { this.isSuccess = false; }
    }

    @AuraEnabled(cacheable=true)
    public static FlowDetailsWrapper getFlowDetails(String flowApiName) {
        FlowDetailsWrapper result = new FlowDetailsWrapper();
        if (String.isBlank(flowApiName)) { result.error = 'Flow API Name was not provided.'; return result; }
        try {
            List<FlowDefinitionView> flows = [
                SELECT Label, Description FROM FlowDefinitionView
                WHERE ApiName = :flowApiName AND IsActive = TRUE WITH SECURITY_ENFORCED LIMIT 1
            ];
            if (!flows.isEmpty()) {
                result.label = flows[0].Label; result.description = flows[0].Description; result.isSuccess = true;
            } else { result.error = 'Active flow definition not found: ' + flowApiName; }
        } catch (Exception e) {
            result.error = 'Error fetching flow details: ' + e.getMessage();
            System.debug(LoggingLevel.ERROR, 'getFlowDetails Exception: ' + e.getMessage());
        }
        return result;
    }

    @AuraEnabled
    public static void updateConversationHistory(String recordId, String messageToLog) {
        if (String.isBlank(recordId) || String.isBlank(messageToLog)) { return; }
        Id actualId; 
        try { actualId = Id.valueOf(recordId); } 
        catch (System.StringException e) { System.debug(LoggingLevel.WARN, 'updateConversationHistory: Invalid recordId: ' + recordId); return; }

        SObjectType objectType = actualId.getSObjectType();
        String sObjectName = objectType.getDescribe().getName();
        if (sObjectName != 'VoiceCall' && sObjectName != 'MessagingSession') { 
            System.debug(LoggingLevel.INFO, 'updateConversationHistory: Unsupported SObject for this history logging: ' + sObjectName);
            return; 
        }
        
        String historyFieldName = 'Conversation_Assistant_History__c';
        DescribeSObjectResult objDesc = objectType.getDescribe();
        Map<String, Schema.SObjectField> fieldMap = objDesc.fields.getMap();

        if (!objDesc.isUpdateable() || !fieldMap.containsKey(historyFieldName.toLowerCase()) || !fieldMap.get(historyFieldName.toLowerCase()).getDescribe().isUpdateable()) {
            System.debug(LoggingLevel.ERROR, 'updateConversationHistory: FLS/CRUD check failed for ' + sObjectName + '.' + historyFieldName);
            return;
        }
        
        String query = 'SELECT ' + String.escapeSingleQuotes(historyFieldName) + 
                       ' FROM ' + String.escapeSingleQuotes(sObjectName) + 
                       ' WHERE Id = :actualId LIMIT 1'; // Changed :recordId to :actualId
        try {
            SObject record = Database.query(query);
            String currentHistory = (String)record.get(historyFieldName);
            currentHistory = (currentHistory == null) ? '' : currentHistory;
            record.put(historyFieldName, currentHistory + messageToLog + '<br></br>');
            
            SObjectAccessDecision decision = Security.stripInaccessible(AccessType.UPDATABLE, new List<SObject>{record});
            if (!decision.getRecords().isEmpty()) { update decision.getRecords(); }
        } catch (Exception e) { System.debug(LoggingLevel.ERROR, 'updateConversationHistory Error for ' + recordId + ': ' + e.getMessage()); }
    }

    public abstract class RecordWrapper {
        @AuraEnabled public String id { get; set; } @AuraEnabled public String title { get; set; }
        @AuraEnabled public String summary { get; set; } @AuraEnabled public String recordType { get; set; }
        @AuraEnabled public String errorMessage {get; set;}
    }
    public class KnowledgeArticleWrapper extends RecordWrapper {
        @AuraEnabled public String urlName { get; set; }
        public KnowledgeArticleWrapper(){ this.recordType = 'Knowledge'; }
    }
    public class CaseWrapper extends RecordWrapper { public CaseWrapper(){ this.recordType = 'Case'; } }
    public class OrderWrapper extends RecordWrapper { public OrderWrapper(){ this.recordType = 'Order'; } }

    private static Boolean canAccessFields(SObjectType objType, List<String> fieldsToCheck) {
        if (objType == null || !objType.getDescribe().isAccessible()) {
             System.debug(LoggingLevel.WARN, 'FLS: Cannot access SObject Type: ' + (objType != null ? objType.getDescribe().getName() : 'null'));
            return false;
        }
        Map<String, Schema.SObjectField> fieldMap = objType.getDescribe().fields.getMap();
        for (String fieldName : fieldsToCheck) {
            if (!fieldMap.containsKey(fieldName.toLowerCase()) || !fieldMap.get(fieldName.toLowerCase()).getDescribe().isAccessible()) {
                System.debug(LoggingLevel.WARN, 'FLS: No access to ' + objType.getDescribe().getName() + '.' + fieldName);
                return false;
            }
        }
        return true;
    }

    @AuraEnabled(cacheable=true)
    public static List<KnowledgeArticleWrapper> getKnowledgeArticleDetails(List<String> articleVersionIds) {
        List<KnowledgeArticleWrapper> results = new List<KnowledgeArticleWrapper>();
        if (articleVersionIds == null || articleVersionIds.isEmpty()) return results;

        String objApiName = 'Knowledge__kav'; 
        List<String> fields = new List<String>{'Title', 'Summary', 'UrlName', 'PublishStatus', 'Language'};
        
        SObjectType kavType = Schema.getGlobalDescribe().get(objApiName);
        if (!canAccessFields(kavType, fields)) return results;

        String userLanguage = UserInfo.getLanguage();
        Set<Id> validIds = new Set<Id>();
        for(String sId : articleVersionIds) if(String.isNotBlank(sId)) try{validIds.add(Id.valueOf(sId.trim()));}catch(Exception e){ System.debug(LoggingLevel.WARN, 'Invalid KA ID: ' + sId);}
        if(validIds.isEmpty()) return results;
        
        String titleField = 'Title', summaryField = 'Summary', urlNameField = 'UrlName';
        String publishStatusField = 'PublishStatus', languageField = 'Language';
        
        String SOQL = 'SELECT Id, ' + titleField + ', ' + summaryField + ', ' + urlNameField +
                      ' FROM ' + objApiName + ' WHERE Id IN :validIds ' + 
                      ' AND ' + publishStatusField + ' = \'Online\'' + 
                      ' AND ' + languageField + ' = :userLanguage WITH SECURITY_ENFORCED';
        try {
            for (SObject sObj : Database.query(SOQL)) {
                KnowledgeArticleWrapper w = new KnowledgeArticleWrapper();
                w.id = String.valueOf(sObj.get('Id')); w.title = (String)sObj.get(titleField);
                w.summary = (String)sObj.get(summaryField); w.urlName = (String)sObj.get(urlNameField);
                results.add(w);
            }
        } catch (Exception e) { System.debug(LoggingLevel.ERROR, 'GetKA Exc: ' + e.getMessage() + ' | Q: ' + SOQL.replace(':validIds', JSON.serialize(new List<Id>(validIds))).replace(':userLanguage', userLanguage) );}
        return results;
    }

    @AuraEnabled(cacheable=true)
    public static List<CaseWrapper> getCaseDetails(List<String> caseIds) {
        List<CaseWrapper> results = new List<CaseWrapper>();
        if (caseIds == null || caseIds.isEmpty()) return results;
        if (!canAccessFields(Case.SObjectType, new List<String>{'Id', 'Subject', 'Description'})) return results;
        
        Set<Id> validIds = new Set<Id>();
        for(String sId : caseIds) if(String.isNotBlank(sId)) try{validIds.add(Id.valueOf(sId.trim()));}catch(Exception e){ System.debug(LoggingLevel.WARN, 'Invalid Case ID: ' + sId);}
        if(validIds.isEmpty()) return results;

        try {
            for (Case c : [SELECT Id, Subject, Description FROM Case WHERE Id IN :validIds WITH SECURITY_ENFORCED]) {
                CaseWrapper w = new CaseWrapper();
                w.id = c.Id; w.title = c.Subject; w.summary = c.Description;
                results.add(w);
            }
        } catch (Exception e) { System.debug(LoggingLevel.ERROR, 'GetCase Exc: ' + e.getMessage());}
        return results;
    }

    @AuraEnabled(cacheable=true)
    public static List<OrderWrapper> getOrderDetails(List<String> orderIds) {
        List<OrderWrapper> results = new List<OrderWrapper>();
        if (orderIds == null || orderIds.isEmpty()) return results;
        if (!canAccessFields(Order.SObjectType, new List<String>{'Id', 'OrderNumber', 'Status'})) return results;

        Set<Id> validIds = new Set<Id>();
        for(String sId : orderIds) if(String.isNotBlank(sId)) try{validIds.add(Id.valueOf(sId.trim()));}catch(Exception e){ System.debug(LoggingLevel.WARN, 'Invalid Order ID: ' + sId);}
        if(validIds.isEmpty()) return results;

        try {
            for (Order o : [SELECT Id, OrderNumber, Status FROM Order WHERE Id IN :validIds WITH SECURITY_ENFORCED]) {
                OrderWrapper w = new OrderWrapper();
                w.id = o.Id; w.title = o.OrderNumber; w.summary = o.Status;
                results.add(w);
            }
        } catch (Exception e) { System.debug(LoggingLevel.ERROR, 'GetOrder Exc: ' + e.getMessage());}
        return results;
    }
}