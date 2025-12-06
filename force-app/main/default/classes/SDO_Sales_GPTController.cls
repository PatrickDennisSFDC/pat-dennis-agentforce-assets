public with sharing class SDO_Sales_GPTController {
    @AuraEnabled(cacheable=true)
    public static SDO_Einstein_GPT_Configuration__c getGPTConfiguration(String configurationId){
        SDO_Einstein_GPT_Configuration__c selectedConfiguration = [SELECT Name, Id, Suggested_Action_1__c, Suggested_Action_2__c, Suggested_Action_1_Label__c, Suggested_Action_2_Label__c, Unknown_Answer_Fallback__c FROM SDO_Einstein_GPT_Configuration__c WHERE Id =: configurationId];  
        return selectedConfiguration;
        
    }
    @AuraEnabled(cacheable=true)
    public static SDO_Einstein_GPT_Configuration__c getMobileGPTConfiguration(){
        SDO_Einstein_GPT_Configuration__c selectedConfiguration = [SELECT Name, Id, Suggested_Action_1__c, Suggested_Action_2__c, Suggested_Action_1_Label__c, Suggested_Action_2_Label__c, Unknown_Answer_Fallback__c FROM SDO_Einstein_GPT_Configuration__c WHERE Active_Mobile_Configuration__c = true LIMIT 1];  
        return selectedConfiguration;
        
    }
    @AuraEnabled(cacheable=true)
    public static User getUserDetails() {
        try {
            Id userId = UserInfo.getUserId();
            return [SELECT Id, FirstName, SmallPhotoUrl FROM USER WHERE Id = :userId LIMIT 1];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static SObject updateField(Id recordId, String fieldNameToUpdate, String updateWith){
        String sobjectType = recordId.getSObjectType().getDescribe().getName();
        String query = 'SELECT Id,' + fieldNameToUpdate + ' FROM ' + sobjectType + ' WHERE Id = \'' + recordId + '\' LIMIT 1';
        // 1. Retrieve the Record
        SObject recordToUpdate = Database.query(query);
        
        // 2. Update the Field
        recordToUpdate.put(fieldNameToUpdate, updateWith);
        
        // 3. Update the Record
        try {
            update recordToUpdate;
            return recordToUpdate;
        } catch(Exception e) {
            System.debug('Error: ' + e.getMessage()); 
            return null;
        }
    }
    @AuraEnabled(cacheable=true)
    public static List<EGPT_Reply> fetchSimulatedData(Id einsteinConfigurationId) {
        List<EGPT_Reply> replies = new List<EGPT_Reply>();
        
        // Query for related SDO_Sales_GPT_Simulated_Reply__c records
        List<SDO_Sales_GPT_Simulated_Reply__c> simulatedRepliesList = [
            SELECT Id, Name, Message_Type__c, Keyword__c, Message__c, Title__c, List_View_Icon__c, List_View_Title__c
            FROM SDO_Sales_GPT_Simulated_Reply__c
            WHERE Einstein_GPT_Configuration__c  = :einsteinConfigurationId
        ];
        
        // Build a set of SDO_Sales_GPT_Simulated_Reply__c Ids for the next query
        for (SDO_Sales_GPT_Simulated_Reply__c reply : simulatedRepliesList) {
            EGPT_Reply rep = new EGPT_Reply();
            rep.Id = reply.Id;
            rep.name = reply.Name;
            rep.keyword = reply.Keyword__c;
            rep.title = reply.Title__c;
            rep.message = reply.Message__c;
            rep.messageType = reply.Message_Type__c;
            rep.cardIcon = reply.List_View_Icon__c;
            rep.cardTitle = reply.List_View_Title__c;
            
            rep.cards = new List<EGPT_Card>();
            for (SDO_Sales_GPT_Record_Card__c card : [SELECT Id, Name, Style__c, Description__c, Card_Title__c, Card_Icon_Name__c FROM SDO_Sales_GPT_Record_Card__c WHERE Sales_GPT_Simulated_Reply__c=:reply.Id ORDER BY Order__c ASC]){
                EGPT_Card car = new EGPT_Card();
                car.id = card.Id;
                car.name = card.Card_Title__c;
                car.description = card.Description__c;
                car.iconName = card.Card_Icon_Name__c;
                car.style = card.Style__c;
                car.actions = new List<EGPT_Action>();
                rep.cards.add(car);
            }
            
            
            rep.actions = new List<EGPT_Action>();
            
            for (SDO_Sales_GPT_Simulated_Action__c action : [SELECT Id, Name, Type__c, URL__c, Flow_API_Name__c,Target_Record_Id__c,Target_Field_Api_Name__c,Update_With__c, Email_To__c, Email_Subject__c, Email_Body__c,Sales_GPT_Next_Reply__c FROM SDO_Sales_GPT_Simulated_Action__c WHERE Sales_GPT_Simulated_Reply__c=:reply.Id]){
                EGPT_Action ac = new EGPT_Action();
                ac.id = action.Id;
                ac.name = action.Name;
                ac.type = action.Type__c;
                ac.emailTo = action.Email_To__c;
                ac.emailSubject = action.Email_Subject__c;
                ac.emailBody = action.Email_Body__c;
                ac.targetRecordId = action.Target_Record_Id__c;
                ac.targetFieldApiName = action.Target_Field_Api_Name__c;
                ac.updateWith = action.Update_With__c;
                ac.nextReplyId = action.Sales_GPT_Next_Reply__c;
                ac.flowAPIName = action.Flow_API_Name__c;
                ac.url = action.URL__c;
                ac.disabled = false;
                rep.actions.add(ac);
            }
            
            
            replies.add(rep);
        }        
        // return the data
        return replies;
    }
    
    @AuraEnabled(cacheable=true)
    public static EGPT_Reply fetchReplyPreview(Id replyId) {
        
        // Query for related SDO_Sales_GPT_Simulated_Reply__c records
        SDO_Sales_GPT_Simulated_Reply__c simulatedReply = [
            SELECT Id, Name, Message_Type__c, Keyword__c, Message__c, Title__c, List_View_Icon__c, List_View_Title__c
            FROM SDO_Sales_GPT_Simulated_Reply__c
            WHERE Id = :replyId LIMIT 1
        ];
        
        // Build a set of SDO_Sales_GPT_Simulated_Reply__c Ids for the next query
        
        EGPT_Reply rep = new EGPT_Reply();
        rep.Id = simulatedReply.Id;
        rep.name = simulatedReply.Name;
        rep.keyword = simulatedReply.Keyword__c;
        rep.title = simulatedReply.Title__c;
        rep.message = simulatedReply.Message__c;
        rep.messageType = simulatedReply.Message_Type__c;
        rep.cardIcon = simulatedReply.List_View_Icon__c;
        rep.cardTitle = simulatedReply.List_View_Title__c;
        
        rep.cards = new List<EGPT_Card>();
        for (SDO_Sales_GPT_Record_Card__c card : [SELECT Id, Name, Style__c, Description__c, Card_Title__c, Card_Icon_Name__c FROM SDO_Sales_GPT_Record_Card__c WHERE Sales_GPT_Simulated_Reply__c=:simulatedReply.Id ORDER BY Order__c ASC]){
            EGPT_Card car = new EGPT_Card();
            car.id = card.Id;
            car.name = card.Card_Title__c;
            car.description = card.Description__c;
            car.iconName = card.Card_Icon_Name__c;
            car.style = card.Style__c;
            car.actions = new List<EGPT_Action>();
            rep.cards.add(car);
        }
        
        
        rep.actions = new List<EGPT_Action>();
        
        for (SDO_Sales_GPT_Simulated_Action__c action : [SELECT Id, Name, Type__c, URL__c, Flow_API_Name__c,Target_Record_Id__c,Target_Field_Api_Name__c,Update_With__c, Email_To__c, Email_Subject__c, Email_Body__c,Sales_GPT_Next_Reply__c FROM SDO_Sales_GPT_Simulated_Action__c WHERE Sales_GPT_Simulated_Reply__c=:simulatedReply.Id]){
            EGPT_Action ac = new EGPT_Action();
            ac.id = action.Id;
            ac.name = action.Name;
            ac.type = action.Type__c;
            ac.emailTo = action.Email_To__c;
            ac.emailSubject = action.Email_Subject__c;
            ac.emailBody = action.Email_Body__c;
            ac.targetRecordId = action.Target_Record_Id__c;
            ac.targetFieldApiName = action.Target_Field_Api_Name__c;
            ac.updateWith = action.Update_With__c;
            ac.nextReplyId = action.Sales_GPT_Next_Reply__c;
            ac.flowAPIName = action.Flow_API_Name__c;
            ac.url = action.URL__c;
            ac.disabled = false;
            rep.actions.add(ac);
        }
        
        
        
        // return the data
        return rep;
    }
    
    @AuraEnabled
    public static SDO_Sales_GPT_Simulated_Reply__c saveReply(SDO_Sales_GPT_Simulated_Reply__c reply){
        try {
            insert reply;
            return reply;
        } catch (Exception e) {
            System.debug('Error: '+e.getMessage());
            return null;
        }
    }
    
    @AuraEnabled
    public static List<SDO_Sales_GPT_Simulated_Action__c> saveActions(List<SDO_Sales_GPT_Simulated_Action__c> actions){
        try {
            insert actions;
            return actions;
        } catch (Exception e) {
            System.debug('Error: '+e.getMessage());
            return null;
        }
    }
    
    @AuraEnabled
    public static List<SDO_Sales_GPT_Record_Card__c> saveCards(List<SDO_Sales_GPT_Record_Card__c> cards){
        try {
            insert cards;
            return cards;
        } catch (Exception e) {
            System.debug('Error: '+e.getMessage());
            return null;
        }
    }
    
    public class EGPT_Card {
        @AuraEnabled public Id id { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String description { get; set; }
        @AuraEnabled public String iconName { get; set; }
        @AuraEnabled public String style { get; set; }
        @AuraEnabled public List<EGPT_Action> actions { get; set; }
    }    
    public class EGPT_Action {
        @AuraEnabled public Id id { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String type { get; set; }
        @AuraEnabled public String targetRecordId { get; set; }
        @AuraEnabled public String targetFieldApiName { get; set; }
        @AuraEnabled public String recordApiName { get; set; }
        @AuraEnabled public String emailTo { get; set; }
        @AuraEnabled public String emailSubject { get; set; }
        @AuraEnabled public String emailBody { get; set; }
        @AuraEnabled public String updateWith { get; set; }
        @AuraEnabled public String nextReplyId { get; set; }
        @AuraEnabled public String flowAPIName { get; set; }
        @AuraEnabled public String url { get; set; }
        @AuraEnabled public Boolean disabled { get; set; }
    }
    
    public class EGPT_Reply {
        @AuraEnabled public Id id { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String keyword { get; set; }
        @AuraEnabled public String title { get; set; }
        @AuraEnabled public String message { get; set; }
        @AuraEnabled public String messageType { get; set; }
        @AuraEnabled public String cardTitle { get; set; }
        @AuraEnabled public String cardIcon { get; set; }
        @AuraEnabled public List<EGPT_Action> actions { get; set; }
        @AuraEnabled public List<EGPT_Card> cards { get; set; }
    }
}