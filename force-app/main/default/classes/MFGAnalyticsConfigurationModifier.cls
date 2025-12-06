/** ServiceWaveConfig
* Smart Wizard - Apex class to auto scan Manufacturing org and pre-poulate wizard Questions
* Developer: Ankit Gupta
* Date: Aug, 2019
* */

public with sharing class MFGAnalyticsConfigurationModifier extends wavetemplate.WaveTemplateConfigurationModifier{

    public override void onConfigurationRetrieval(wavetemplate.WaveTemplateInfo template)
    {
        
        
        
        
        //populating the values of active currencies in the org
        setActiveCurrencies(template);

        //set the fiscal month offset
        setFiscalMonthOffset(template);
        //set the isYearEndFiscalYear bool for dataflow
        setIsYearEndFiscalYear(template);
        //set the hierarchy type for sales targets
        setTargetsHierarchy(template);
        //Try and fetch custom Lookup fields on the order object
        setOrdersLookupFields(template);
        //Try and fetch custom aggregate fields on the RebateMemberProductAggregate object
        setRebateMemberProductAggregateCustomFields(template);
    }

    //*********************Validation Before APP Creation**************************************************
    // Executes when we click on Create-APP button
    public override void beforeAppCreate(wavetemplate.WaveTemplateInfo template, wavetemplate.Answers answers)
    {
    }

    //*********************Validation Before APP Update**************************************************
    // Executes when we click on Reset or Update button
     public override void beforeAppUpdate(wavetemplate.WaveTemplateInfo template, String previousAppVersion, wavetemplate.Answers answers)
     {}

    /* private static boolean HasObject(string prefix){
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
     }*/

     private void setActiveCurrencies(wavetemplate.WaveTemplateInfo template){
        wavetemplate.VariableDefinition activeCurrenciesQuestion = template.getVariables().get('Active_Currencies');
        wavetemplate.VariableDefinition activeCurrenciesCount = template.getVariables().get('Active_Currencies_Count');
        Schema.SObjectType targetTypeP = Schema.getGlobalDescribe().get('CurrencyType');
        if (targetTypeP == null) {
            System.debug('CurrencyType doesn\'t exist in the org.');
            activeCurrenciesCount.setComputedValue(1);
            activeCurrenciesQuestion.setComputedValue(null);
            return;
        }
        String query = 'SELECT IsoCode, ConversionRate FROM CurrencyType WHERE IsActive = true';
        String query2 = 'SELECT IsoCode FROM CurrencyType WHERE IsCorporate = true';
         try {
            List<SObject> currencies = Database.query(query);
            SObject corpcurr = Database.query(query2);
            List<String> activecurrencies = new List<String>();
            List<Decimal> activeconversionrates = new List<Decimal>();
            String defaults = String.valueOf(corpcurr.get('IsoCode'));
            /*for(CurrencyType curr : currencies){
                activecurrencies.add(curr.IsoCode);
                activeconversionrates.add(curr.ConversionRate);
            }*/
            for(SObject curr : currencies){
                activecurrencies.add(String.valueOf(curr.get('IsoCode')));
                activeconversionrates.add(Decimal.valueOf(String.valueOf(curr.get('ConversionRate'))));
            }

            activeCurrenciesCount.setComputedValue(activecurrencies.size());

            system.debug('These are the active currencies: ' + activecurrencies);
            activeCurrenciesQuestion.getVariableType().setEnums(activecurrencies);
            activeCurrenciesQuestion.setComputedValue(defaults);
            ///////////

            return;
            } catch (Exception e) {
            System.debug('something went wrong, no currencies:' + e);
            return ;
            }
    }

     private void setFiscalMonthOffset(wavetemplate.WaveTemplateInfo template){
        wavetemplate.VariableDefinition FYMonthOffsetQuestion = template.getVariables().get('Fiscal_Month_Offset');
        Integer FYMonthOffset = [SELECT FiscalYearStartMonth FROM Organization].FiscalYearStartMonth-1;

        system.debug('This is the month offset: ' + FYMonthOffset);
        FYMonthOffsetQuestion.setComputedValue(FYMonthOffset);
    }

    private void setIsYearEndFiscalYear(wavetemplate.WaveTemplateInfo template){
        wavetemplate.VariableDefinition Fiscal_Year_is_End_MonthQuestion = template.getVariables().get('Fiscal_Year_is_End_Month');
        Boolean Fiscal_Year_is_End_Month = [SELECT UsesStartDateAsFiscalYearName FROM Organization].UsesStartDateAsFiscalYearName;

        system.debug('Fiscal Year is End Month: ' + !Fiscal_Year_is_End_Month);
        Fiscal_Year_is_End_MonthQuestion.setComputedValue(!Fiscal_Year_is_End_Month);
    }

    private void setTargetsHierarchy(wavetemplate.WaveTemplateInfo template){
        wavetemplate.VariableDefinition hierarchyTypeQuestion = template.getVariables().get('TargetsHierarchy');
        Schema.SObjectType targetTypeP = Schema.getGlobalDescribe().get('AcctMgrTarget');
        if (targetTypeP == null) {
            System.debug('AcctMgrTarget doesn\'t exist in the org.');
            hierarchyTypeQuestion.setComputedValue(null);
            return;
        }
        String query = 'SELECT TeamMemberHierarchyType FROM AcctMgrTarget ORDER BY CreatedDate DESC NULLS LAST LIMIT 1';
         try {
            SObject hierarchyType = Database.query(query);
            hierarchyTypeQuestion.setComputedValue(String.valueOf(hierarchyType.get('TeamMemberHierarchyType')) == 'ManagerHierarchy' ? 'Manager Hierarchy' : 'Forecasts Hierarchy');

            system.debug('This is the chosen hierarchy type : ' + hierarchyType);
            ///////////

            return;
            } catch (Exception e) {
            System.debug('something went wrong, no hierarchy type set:' + e);
            return ;
            }
    }

    private void setOrdersLookupFields(wavetemplate.WaveTemplateInfo template){
        wavetemplate.VariableDefinition CustomTargetActualsOwnerQuestion = template.getVariables().get('CustomTargetActualsOwner');
        Schema.SObjectType OrderP = Schema.getGlobalDescribe().get('Order');
        if (OrderP == null) {
            System.debug('Order doesn\'t exist in the org.');
            CustomTargetActualsOwnerQuestion.setComputedValue(null);
            return;
        }
        List<String> fieldNameToString = new List<String>();
        List<SelectOption> fieldNames = new List<SelectOption>();
        Map<String,Schema.SObjectField> orderFields = OrderP.getDescribe().fields.getMap();
        for(Schema.SObjectField sfield : orderFields.Values()) {
            schema.describefieldresult dfield = sfield.getDescribe();

            if(dfield.getName().contains('__c'))
            {
                fieldNameToString.add(dfield.getName());
            }
            if(fieldNameToString.isEmpty()){
                fieldNameToString.add(null);
            }
        }
        CustomTargetActualsOwnerQuestion.getVariableType().setEnums(fieldNameToString);
    }

    private void setRebateMemberProductAggregateCustomFields(wavetemplate.WaveTemplateInfo template){
        wavetemplate.VariableDefinition CustomRebateMemberProductAggregate = template.getVariables().get('RebatesCustomAggregateField');
        Schema.SObjectType RebateMemberProductAggregate = Schema.getGlobalDescribe().get('RebateMemberProductAggregate');
        if (RebateMemberProductAggregate == null) {
            System.debug('RebateMemberProductAggregate doesn\'t exist in the org.');
            CustomRebateMemberProductAggregate.setComputedValue(null);
            return;
        }
        List<String> fieldNameToString = new List<String>();
        List<SelectOption> fieldNames = new List<SelectOption>();
        Map<String,Schema.SObjectField> RebateMemberProductAggregateFields = RebateMemberProductAggregate.getDescribe().fields.getMap();
        for(Schema.SObjectField sfield : RebateMemberProductAggregateFields.Values()) {
            schema.describefieldresult dfield = sfield.getDescribe();

            if(dfield.getName().contains('__c'))
            {
                fieldNameToString.add(dfield.getName());
            }
            if(fieldNameToString.isEmpty()){
                fieldNameToString.add(null);
            }
        }
        CustomRebateMemberProductAggregate.getVariableType().getItemsType().setEnums(fieldNameToString);
    }

}