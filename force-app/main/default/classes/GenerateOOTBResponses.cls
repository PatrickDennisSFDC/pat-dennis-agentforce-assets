public class GenerateOOTBResponses {
    public static void updateOpptyRichText() {
        List<Opportunity> opps = [SELECT Id, Name, StageName, Account.Id, Account.Name, FORMAT(Amount) dollarAmount, CloseDate FROM Opportunity LIMIT 3];
        SDO_Sales_GPT_Record_Card__c card = [SELECT Id, Name, Description__c, External_ID__c FROM SDO_Sales_GPT_Record_Card__c WHERE External_ID__c = 'SDO_Sales_GPT_Card.003' LIMIT 1];
        String description = '';
        Integer i = 0;
        for (Opportunity opp : opps) {
            i++;
            String ele = '<p>Name: <a href=\"/lightning/r/Opportunity/' + opp.Id + '/view\" target=\"_self\"><strong>' + opp.Name + '</strong></a></p><p>Account Name: <a href=\"/lightning/r/Account/' + opp.Account.Id + '/view\" target=\"_self\"><strong>' + opp.Account.Name + '</strong></a></p><p>Stage: <strong>' + opp.StageName + '</strong></p><p>Amount: <strong>' + opp.get('dollarAmount') + '</strong></p><p>Close Date: <strong>' + opp.CloseDate.format() + '</strong></p>';
			if(i < (opps.size())){
                ele += '<hr></hr>';
            }
            description += ele;
        }
        card.Description__c = description;
        System.debug('Desc: '+description);
        ListView lv = [SELECT Id,Name,DeveloperName FROM ListView WHERE DeveloperName LIKE 'Opportunities_Closing%' LIMIT 1];
       /* SDO_Sales_GPT_Record_Card_Action__c cardAction = [SELECT Id, Name, URL__c FROM SDO_Sales_GPT_Record_Card_Action__c WHERE Sales_GPT_Record_Card__c = :card.Id LIMIT 1];
        cardAction.URL__c = '/lightning/o/Opportunity/list?filterName=' + lv.Id;*/
        try {
            update card;
            //update cardAction;
        } catch(Exception e) {
            System.debug('Error: ' + e.getMessage());
        }
    }
    public static void updateContactRichText() {
        Contact con = [SELECT Id, FirstName, LastName, Name FROM Contact WHERE FirstName = 'Lauren' LIMIT 1];
        SDO_Sales_GPT_Simulated_Reply__c reply = [SELECT Id, Name, Title__c, External_ID__c FROM SDO_Sales_GPT_Simulated_Reply__c WHERE External_ID__c = 'SDO_Sales_GPT_Reply.002' LIMIT 1];
        reply.Title__c = '<p><span style=\"color: rgb(68, 68, 68);\">Sure, here&#39;s </span><a href=\"/lightning/r/Contact/' + con.Id + '/view\" target=\"_self\" style="color: rgb(11, 92, 171);\">' + con.Name + '</a><span style=\"color: rgb(68, 68, 68);\">.</span></p>';
        //SDO_Sales_GPT_Record_Card_Action__c action = [SELECT Id, Target_Record_Id__c, External_ID__c FROM SDO_Sales_GPT_Record_Card_Action__c WHERE External_ID__c = 'SDO_Sales_GPT_Card_Action.001' LIMIT 1];
        //action.Target_Record_Id__c = con.Id;
         try {
            update reply;
            //update action;
        } catch(Exception e) {
            System.debug('Error: ' + e.getMessage());
        }
    }
}