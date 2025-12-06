public class SecureMessageController {
    
    
    @auraEnabled
    public static void setMessageRead(string messageID){
        system.debug ('SecureMessageController setMessageRead - Read. Id: ' + messageId);
        List<Secure_Message__c> msgList = [select Id, Unread__c from Secure_Message__c where Id = :messageID];
        
        if (msgList.size() > 0){
            msgList[0].Unread__c = false;
            
            update msgList;
            system.debug ('Message marked as Read. Id: ' + messageId);
        }
    }
    
    
    @AuraEnabled
      public static List <Secure_Message__c> getMessages() {
        List<Secure_Message__c> msgList =  [SELECT Id, Unread__c, Body__c, Name, Contact__c, CreatedDate, LastModifiedDate FROM Secure_Message__c ORDER BY createdDate ASC];
          system.debug('Message List: ' + msgList);
          
          return msgList;
      }
}