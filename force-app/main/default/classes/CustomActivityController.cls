public class CustomActivityController {
	
    @AuraEnabled
    public static List <SDO_Customer360_Custom_Activity__c> getActivitiesForContact(Id recordId) {
        
                
        List<SDO_Customer360_Custom_Activity__c> a = [
            SELECT Id,Name,message__c,icon__c,Icon_Color__c,days_ago__c,time__c,order__c
            FROM SDO_Customer360_Custom_Activity__c
            WHERE contact__c = :recordId
            ORDER BY days_ago__c,order__c DESC
            
        ];
        
        return a;
    }
    
    @AuraEnabled
    public static List <SDO_Customer360_Custom_Activity__c> getActivitiesForAccount(Id recordId) {
                        
        List<SDO_Customer360_Custom_Activity__c> a = [
            SELECT Id,Name,message__c,icon__c,Icon_Color__c,days_ago__c,time__c,order__c
            FROM SDO_Customer360_Custom_Activity__c
            WHERE contact__c in (SELECT PersonContactId FROM Account WHERE Id = :recordId)
            ORDER BY days_ago__c,order__c DESC
            
        ];
        
        return a;
    }
    
    @AuraEnabled
    public static Account getContactForAccount (Id recordId) {
        
        Account a = [SELECT PersonContactId FROM Account where Id = :recordId ];
       	return a;
                
        
    }
    
   
}