public class ResetDemo2{
    @AuraEnabled
    public static String resetDemoMethod() {
        // This is the ownerID from Tier 1 Queue    
        //String caseOwner = '3D00G6A000001dPOb' ; 
        List<Group> g = [select id, ownerId, name from group where name = 'Tier 1 Queue'] ; 
        String caseOwner =  g[0].Id; 
        system.debug('id, owner id , name ' + g[0].id + '  ' + g[0].ownerId + ' ' + g[0].name);
        
        try {
            
            // Clone the Case
            List<Case> originalCases = [SELECT Subject,OwnerId,Origin,Status,Priority,AccountId,ContactId,EntitlementId,RecordTypeId FROM Case
                                        WHERE Subject = 'Pre-Surgical Consultation for Total Hip Replacement'];
            
            system.debug('--- Original Case --- ' + originalCases[0]);
            Case clonedCase = originalCases[0].clone(false, true);
            // Set the new fields and insert
            clonedCase.Status = 'New';
            clonedCase.OwnerId = caseOwner; 
            insert clonedCase;
            system.debug('--- New Case inserted ---');  
            delete originalCases;
            system.debug('--- Case Deleted ---');   

            // Delete chatter feed for User who has logged in 
             
            DateTime NOW = dateTime.now();
            system.debug('now- ' + NOW);
            DateTime earlier = NOW.addMinutes(-30);
            system.debug('30 mins before - ' + earlier);
            String tempDate = earlier.format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ','America/Los_Angeles');
           
             // String userId = UserInfo.getUserId();
            
           
            List<User> u = [select id from user where name='Melinda Smith'] ; 
            String melindaSmith = u[0].id; 
            
            system.debug('melindaSmith:' + melindaSmith); 
            String query = 'select Id from FeedItem  WHERE InsertedById = \'' + melindaSmith +  '\' ' + ' AND createdDate > ' + tempDate;
            system.debug('--- query --- ' + query);
            List<FeedItem> item = database.query(query);
            system.debug('--- items ---- ' + item);
            delete item; 
            
            system.debug('Deleted Item '  + item ); 
            return 'Success';
            
        } catch (exception e) {
            return e.getMessage();
        }
    }
    
    @AuraEnabled 
    public static void deleteFeed()
    {
        DateTime NOW = dateTime.now();
        system.debug('now- ' + NOW);
        DateTime earlier = NOW.addMinutes(-30);
        system.debug('30 mins before - ' + earlier);
        String tempDate = earlier.format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ','America/Los_Angeles');
        String userId = '0050a00000J2RKsAAN';
        String query = 'select id from FeedItem  WHERE InsertedById = \'' + userId +  '\' ' + ' AND createdDate > ' + tempDate;
        system.debug('--- query --- ' + query);
        List<FeedItem> item = database.query(query);
        system.debug('--- items ---- ' + item);
        delete item; 
        // List<FeedItem> item = [select id from FeedItem  WHERE InsertedById = :userId AND createdDate > :tempDate ] ;
    }
    
}