public with sharing class SDO_Service_GPTController {

    @AuraEnabled(cacheable=true)
    public static SDO_Einstein_GPT_Configuration__c getGPTConfiguration(String configurationId){
        SDO_Einstein_GPT_Configuration__c selectedConfiguration = [SELECT Name, Id, Service_Contact_Name__c, Service_Agent_Name__c 
                                                      FROM SDO_Einstein_GPT_Configuration__c WHERE Id =: configurationId];  
        return selectedConfiguration;
        
    }
 
    @AuraEnabled(cacheable=true)
    public static List<SDO_Service_GPT_Simulated_Replies__c> getSimulatedReplies(String configurationId) {        
        try {
            return [
                SELECT Id, Message_Type__c, Keyword__c, Message__c, End_Messaging_Session__c
                FROM SDO_Service_GPT_Simulated_Replies__c
                WHERE Einstein_GPT_Configuration__c =: configurationId];    
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
}