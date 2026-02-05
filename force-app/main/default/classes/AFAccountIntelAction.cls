/**
 * AF Account Intel Action
 * Invocable action for retrieving Account Intelligence records
 * Designed for use in Prompt Templates to provide context about accounts
 */
global with sharing class AFAccountIntelAction {
    
    /**
     * Request input for Prompt Builder
     */
    global class Request {
        @InvocableVariable
        public String placeholder;
    }
    
    /**
     * Response output for Prompt Builder - must have 'Prompt' variable
     */
    global class Response {
        @InvocableVariable
        public String Prompt;
    }
    
    /**
     * Get Account Intel for Prompt Templates
     */
    @InvocableMethod(label='Get Account Intel' description='Retrieves Account Intelligence records formatted for prompt templates.')
    global static List<Response> getAccountIntel(List<Request> requests) {
        List<Response> responses = new List<Response>();
        Response res = new Response();
        
        try {
            List<Account_Intel__c> records = [
                SELECT Id, Name, Account__c, Account__r.Name, Account__r.Industry, 
                       Intel_Type__c, Intel_Date__c, Last_Updated__c, Summary__c 
                FROM Account_Intel__c 
                ORDER BY Account__r.Name ASC, Intel_Date__c DESC NULLS LAST
                LIMIT 50
            ];
            
            if (records.isEmpty()) {
                res.Prompt = 'No Account Intel records found.';
            } else {
                List<String> formattedRecords = new List<String>();
                String currentAccount = '';
                
                for (Account_Intel__c intel : records) {
                    String accountName = intel.Account__r != null ? intel.Account__r.Name : 'Unknown Account';
                    String industry = intel.Account__r != null && intel.Account__r.Industry != null ? intel.Account__r.Industry : '';
                    
                    if (accountName != currentAccount) {
                        if (!String.isBlank(currentAccount)) {
                            formattedRecords.add('');
                        }
                        String accountHeader = '## ' + accountName;
                        if (!String.isBlank(industry)) {
                            accountHeader += ' (' + industry + ')';
                        }
                        formattedRecords.add(accountHeader);
                        currentAccount = accountName;
                    }
                    
                    String intelEntry = '- **' + (intel.Intel_Type__c != null ? intel.Intel_Type__c : 'General') + '**';
                    if (intel.Intel_Date__c != null) {
                        intelEntry += ' (' + intel.Intel_Date__c.format() + ')';
                    }
                    intelEntry += ': ' + (intel.Summary__c != null ? intel.Summary__c : 'No summary available.');
                    
                    formattedRecords.add(intelEntry);
                }
                
                res.Prompt = String.join(formattedRecords, '\n');
            }
            
        } catch (Exception e) {
            res.Prompt = 'Error retrieving Account Intel: ' + e.getMessage();
        }
        
        responses.add(res);
        return responses;
    }
}
