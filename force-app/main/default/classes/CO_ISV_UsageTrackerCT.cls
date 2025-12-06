public class CO_ISV_UsageTrackerCT {
    private static final String USAGE_EMAIL_FIELD = 'CO_ISV_UsageEmailSent__c';
    private static final String DEMO_COMPONENT_NAME = 'Integration Status Viewer';
    private static final String ORG_HANDLER_EMAIL = 'democomponentinstalls@k-1ijl2wihwyjfu41krv0gjp9djpi36mzk0nkbv3sozwh3zgr230.5w-vhobeas.na172.apex.salesforce.com';
    
    @AuraEnabled
    public static void checkAndsendUsageEmail(Boolean isTest){
        try{
            String userId = UserInfo.getUserId();
            User currentUser = Database.query('SELECT ' + USAGE_EMAIL_FIELD + ' FROM User WHERE Id = :userId');
            
            //Checks if email has already been sent
            if(currentUser.get(USAGE_EMAIL_FIELD) == false){
                
                //Attempts to update all users to avoid sending more than 1 email per org
                List<User> users = Database.query('SELECT ' + USAGE_EMAIL_FIELD + ' FROM User');
                for(User u : users){
                    u.put(USAGE_EMAIL_FIELD, true);
                }
                Database.update(users, false);
                
                Messaging.reserveSingleEmailCapacity(2);
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                String[] toAddresses = new String[] {ORG_HANDLER_EMAIL}; 
                    mail.setToAddresses(toAddresses);
                mail.setSenderDisplayName(UserInfo.getName());
                mail.setSubject('Demo Component Installed');
                
                Map<String,String> body = new Map<String,String>();
                
                body.put('orgName', UserInfo.getOrganizationName());
                body.put('orgId', UserInfo.getOrganizationId());
                body.put('locale', UserInfo.getLocale());
                body.put('language', UserInfo.getLanguage());
                body.put('demoComponentName', DEMO_COMPONENT_NAME);
                
                mail.setPlainTextBody(JSON.serialize(body));
                
                if(!isTest){
                    Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
                }
            }
        }
        catch(Exception e){
            System.debug(e.getMessage());
        }  
    }
}