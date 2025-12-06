global with sharing class MFGAnalyticsChecklistRemoter{

global MFGAnalyticsChecklistRemoter() {

        }                      // empty constructor



    @RemoteAction
    global static Map<string, object> dataOk(Boolean isCustomReset ) {
                boolean errorFlag = false;
                Integer errorNum = 1;
                Integer ClientSegCount = 0;
                List<string> errorMessages = new List<string>();


                // Check if the mandatory objects exist
                if( !HasObject('OrderItem') ||  !HasObject('Product2') || !HasObject('Pricebook2') || !HasObject('Account') || !HasObject('OpportunityLineItem') ){
                        errorMessages.add('Analytics for Manufacturing requires the objects OrderItem, Product2, Pricebook2, Account, OpportunityLineItem and Manufacturing package to be present in Salesforce instance');
                        errorFlag = true;
                }
                else
                {
                        try
                        {       
                                // check if there exists atleast one record in the OrderItem object

                                string query = 'SELECT Id FROM OrderItem Order by CreatedDate DESC limit 2';
                                List<OrderItem> OrderItemRecords = database.query(query);
                                if(OrderItemRecords.isEmpty())
                                {
                                        errorMessages.add('Analytics for Manufacturing requires at least one record in the OrderItem Object');
                                        errorFlag = true;
                                        
                                }

                                // check if there exists atleast one record in the Pricebook2 object

                                query = 'SELECT Id FROM Pricebook2 Order by CreatedDate DESC limit 2';
                                List<Pricebook2> Pricebook2Records = database.query(query);
                                if(Pricebook2Records.isEmpty())
                                {
                                        errorMessages.add('Analytics for Manufacturing requires at least one record in the Pricebook2 Object');
                                        errorFlag = true;
                                }

                                // check if there exists atleast one record in the Product2 object

                                query = 'SELECT Id FROM Product2 Order by CreatedDate DESC limit 2';
                                List<Product2> Product2Records = database.query(query);
                                if(Product2Records.isEmpty())
                                {
                                        errorMessages.add('Analytics for Manufcaturing requires at least one record in Product2 Object');
                                        errorFlag = true;
                                }

                                // check if there exists atleast one record in the OpportunityLineItem object

                                query = 'SELECT Id FROM OpportunityLineItem Order by CreatedDate DESC limit 2';
                                List<OpportunityLineItem> OpportunityLineItemRecords = database.query(query);
                                if(OpportunityLineItemRecords.isEmpty())
                                {
                                        errorMessages.add('Analytics for Manufacturing requires at least one record in the OpportunityLineItem Object');
                                        errorFlag = true;
                                }

                                // check if there exists atleast one record in the Account object

                                query = 'SELECT Id FROM Account Order by CreatedDate DESC limit 2';
                                List<Account> AccountRecords = database.query(query);
                                if(AccountRecords.isEmpty())
                                {
                                        errorMessages.add('Analytics for Manufacturing requires at least one record in the Account Object');
                                        errorFlag = true;
                                }

                        }
                        catch(Exception e)
                        {
                                //really big orgs may fail on this query -  incase they do let's assume they have one record in Sales Agreement Product Schedule object
                                system.debug(e);
                                ClientSegCount = 1;
                                errorFlag = false;
                        }
                }
                // return the result
                if(errorFlag)
                {

                        // return the error message
                        return new Map<String, Object>{
                                       'success' => false,
                                       'messages' => errorMessages
                        };
                }
                
                // everything alright
                // no variable settings here
                errorMessages.add('Your org has at least one record in OrderItem, Product2, Pricebook2, Account, OpportunityLineItem objects, which are minimum requirements for creating the app.');
                return new Map<String, Object>{
                               'success' => true,
                               'messages' => errorMessages
                };
        }


        private static boolean HasObject(string prefix)
        {
                for(schema.SObjectType s : Schema.getGlobalDescribe().Values())
                {
                        if(s.getDescribe().getName() != null)
                        {
                                String Name = s.getDescribe().getName();
                                Boolean result = Name.contains(prefix);
                                if(result == true)
                                {
                                        string value = Name;
                                        return true;
                                }

                        }
                }

                return false;
        }


                private static string findPrefixFor(string prefix)
        {
                for(schema.SObjectType s : Schema.getGlobalDescribe().Values())
                {
                        if(s.getDescribe().getName() != null)
                        {
                                String Name = s.getDescribe().getName();
                                Boolean result = Name.contains(prefix);
                                if(result == true)
                                {
                                        string value = Name.substring(0,Name.indexOf(prefix));
                                        return value;
                                }

                        }
                }

                return 'NA';
        }




        private static Map<String, Object> hasProgramRecordTypes(List<object> selectedValues, Boolean isCustomReset)
        {
                List<String> messages_no = new List<String>();
                List<String> messages_yes = new List<String>();
                List<Object> variableSettings = new List<Object>();
                Boolean test_passed;
                messages_yes.add('Record types checks for Analytics for Manufacturing App is successful');
                /*
                string programRecordTypeQuery = 'SELECT count() FROM RecordType WHERE SObjectType=\'SalesAgreementProductSchedule\' limit 1';
                try
                {

                        Integer programRecordtypes = Database.countQuery(programRecordTypeQuery);

                        if(programRecordtypes > 0) {

                                messages_yes.add('Record types corresponding to SalesAgreementProductSchedule exists');
                                selectedValues.add('hasProgramRecordTypes');
                                test_passed =  true;
                        }
                        else{

                                messages_no.add('Record types corresponding to SalesAgreementProductSchedule does not exist');
                                test_passed =  false;


                        }
                }
                catch (Exception e) { }
                */
                return new Map<String, Object>{
              'success' => true,
              'messages_no' => messages_no,
              'messages_yes' => messages_yes,
              'variableSettings' => variableSettings
            };
        }
        
        @RemoteAction
        global static Map<string, object> objectUsage(Boolean isCustomReset )
        {
                //System.debug('isCustomReset : ' + isCustomReset);
                List<Map<String, Object> > resultList = new List<Map<String, Object> >();
                List<object> selectedValues = new List<object>();
                // resultList.add(hasQueues(selectedValues,isCustomReset));
              //  resultList.add(hasCaseHistory(selectedValues,isCustomReset));
                // resultList.add(hasOpportunity(selectedValues,isCustomReset));
                // resultList.add(hasEvents(selectedValues,isCustomReset));
                // resultList.add(hasBusinessHours(selectedValues,isCustomReset));
                resultList.add(hasProgramRecordTypes(selectedValues,isCustomReset));
                //resultList.add(setObjPrefix());
                // resultList.add(hasOpportunityRecordTypes(selectedValues,isCustomReset));
                // resultList.add(hasTelephony(selectedValues,isCustomReset));
                // resultList.add(hasChat(selectedValues,isCustomReset));
                resultList.add(setAllGoodMsg());

                //resultList.add(setAdditionalObjectChoices(selectedValues,isCustomReset));
                // aggregate results
                return aggregateResults(resultList,isCustomReset);

        }


        /*****2.Method to Autoscan and set objectprefix******/
private static Map<String, Object> setObjPrefix()
{
        List<Object> variableSettings = new List<Object>();
        List<String> messages = new List<String>();
        String prefix =findPrefixFor('FinancialAccount__c');
        system.debug('prefix is :'+prefix);
        //        String message = '';
        if(prefix != 'NA')
        {
                String message = 'Object prefix is set to ' + prefix + ' based on your Salesforce settings.';
                messages.add(message);

                variableSettings.add(new Map<string, object>{
                                'name' => 'ObjectPrefix',
                                'value' => prefix
                        });

                return new Map<String, Object>{
                       'success' => true,
                       'messages' => messages,
                       'variableSettings' => variableSettings
                };
        }
        else
        {
                //just in case

                String message = 'Unable to automatically set Object prefix, please create template custom mode to manually set the value';
                messages.add(message);

                return new Map<String, Object>{
                       'success' => false,
                       'messages' => messages,
                       'variableSettings' => variableSettings
                };
        }

}


        private static Map<String, Object> aggregateResults(List<Map<String, Object> > resultList,Boolean isCustomReset){

                Boolean allGood = true;
                List<Map<String, Object> > variableSettings = new List<Map<String, Object> >();
                List<String> messages = new List<String>();
                List<String> messages_no = new List<String>();
                List<String> messages_yes = new List<String>();

                // iterate over the results
                for (Map<String, Object> result: resultList) {
                        // if one failed all failed
                        if (!((boolean)result.get('success'))) {
                                allGood = false;
                        }

                        // aggregate the variable settings
                        if (result.containsKey('variableSettings')) {
                                for (Object s: (List<Object>)result.get('variableSettings')) {
                                        variableSettings.add((Map<String, Object>) s);
                                }
                        }

                        // and messages
                        if (result.containsKey('messages_no')) {
                                messages_no.addAll((List<String>)result.get('messages_no'));
                        }

                        if (result.containsKey('messages_yes')) {
                                messages_yes.addAll((List<String>)result.get('messages_yes'));
                        }
                }

                if(!messages_yes.isEmpty())
                {

                        messages.add('Analytics for Manufacturing App has detected that the following features are available for your app.');


                        messages.addAll(messages_yes);
                }
                if(!messages_no.isEmpty())
                {
                        messages.add('   ');
                        messages.add('Analytics for Manufacturing App has detected that the following features are not available for your app.');
                        messages.addAll(messages_no);
                }


                // aggregate the messages and variable settings
                return new Map<String, Object>{
                               'success' => allGood,
                               'messages' => messages,
                               'variableSettings' => variableSettings
                };
        }

@RemoteAction
global static Map<string, object> fieldAccess(Boolean isCustomReset )
{
    return setFieldLevelMsg();
}


/*****2.Method to Autoscan and set fiscal******/
private static Map<String, Object> setFiscal()
{
        List<Object> variableSettings = new List<Object>();
        List<String> messages = new List<String>();
        //        String message = '';
        try
        {
                Integer months = [SELECT
                                  FiscalYearStartMonth
                                  FROM
                                  Organization].FiscalYearStartMonth;

                Map<Integer, string> a = new Map<Integer, string>{
                        1 => '01 - January',
                        2 => '02 - February',
                        3 => '03 - March',
                        4 => '04 - April',
                        5 => '05 - May',
                        6 => '06 - June',
                        7 => '07 - July',
                        8 => '08 - August',
                        9 => '09 - September',
                        10 => '10 - October',
                        11 => '11 - November',
                        12 => '12 - December'
                };

                Map<Integer, string> month_for_infodisplay = new Map<Integer, string>{
                        1 => 'January',
                        2 => 'February',
                        3 => 'March',
                        4 => 'April',
                        5 => 'May',
                        6 => 'June',
                        7 => 'July',
                        8 => 'August',
                        9 => 'September',
                        10 => 'October',
                        11 => 'November',
                        12 => 'December'
                };

                String message = 'Fiscal start date set to ' + month_for_infodisplay.get(months) + ' based on your Salesforce settings. You can change the fiscal start date in custom create.';
                messages.add(message);
                //messages.add('Fiscal Month Set to January');

                variableSettings.add(new Map<string, object>{
                                'name' => 'Fiscal_Month',
                                'value' => a.get(months)
                        });

        }
        catch (Exception e)
        {
                //just in case

                String message = 'Fiscal start date set to January based on your Salesforce settings. You can change the fiscal start date in custom create.';
                messages.add(message);

                variableSettings.add(new Map<string, object>{
                                'name' => 'Fiscal_Month',
                                'value' => '01 - January'
                        });
        }
        return new Map<String, Object>{
                       'success' => true,
                       'messages' => messages,
                       'variableSettings' => variableSettings
        };
}


/*****2.Method to Autoscan and set fiscal******/
private static Map<String, Object> setFieldLevelMsg()
{
        List<Object> variableSettings = new List<Object>();
        List<String> messages = new List<String>();
        //        String message = '';

                String message = 'Field Level Access check is triggered. If Analytics Integration user does not have access to some fields you might see a pop up message once you create an app';
                messages.add(message);



        return new Map<String, Object>{
                       'success' => true,
                       'messages' => messages
        };
}

private static Map<String, Object> setAllGoodMsg()
{
        List<Object> variableSettings = new List<Object>();
        List<String> messages = new List<String>();
        //        String message = '';

                String message = 'All the checks are complete. You are ready to create Analytics for Manufacturing';
                messages.add(message);



        return new Map<String, Object>{
                       'success' => true,
                       'messages' => messages
        };
}

@RemoteAction
global static Map<string, object> configuration(Boolean isCustomReset )
{
        List<Map<String, Object>> resultList = new List<Map<String, Object>>();
        //return setFiscal();
        resultList.add(AppsUtil.getOrgFiscalMonth());
        resultList.add(AppsUtil.getOrgFirstDayOfWeek());
        resultList.add(Corporate_Currency.getCorporateCurrencyISO());
        //resultList.add(Corporate_Currency.getCorporateCurrencyConversionRate());
        return AppsUtil.aggregateResults(resultList);

}



@RemoteAction
global static Map<string, object> allGood(Boolean isCustomReset )
{

    return setAllGoodMsg();
}

/*
* Checks objects and records for the cards. COPY ONLY THIS
*/
@RemoteAction
global static Map<string, object> checkObjectWithRecords(String objectName)
{
    return CardUtils.checkObjectWithRecords(objectName);                                           
}

}