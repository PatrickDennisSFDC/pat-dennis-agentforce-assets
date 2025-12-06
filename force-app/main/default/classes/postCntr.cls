public class postCntr {
    
    @AuraEnabled
    public static List<Account> makeChatterPost(String recordId)
    {
         List<Account> c1 = [SELECT Id,Name,FirstName,LastName,OwnerId
                     FROM Account 
                     WHERE Id=:recordId];
        String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
       // system.debug('URL'+baseUrl);
        string contactURL = baseUrl + '/' + c1[0].Id;
        string contactName = c1[0].FirstName + ' ' + c1[0].LastName;
        FeedItem post = new FeedItem();
        post.ParentId = c1[0].OwnerId; // Record Id eg. Opportunity id, custom object id..
        post.Body = 'ALERT: Blood Glucose out of range  <p>&nbsp;</p> <a href="'+ contactURL +'">'+ contactName +'</a> Smart Glucometer generated a reading of 210 mg/dL.';
        post.IsRichText = true;
        insert post;
        return c1;
    }
}