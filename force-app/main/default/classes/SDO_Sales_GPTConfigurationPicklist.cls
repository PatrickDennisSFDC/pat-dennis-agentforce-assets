global with sharing class SDO_Sales_GPTConfigurationPicklist extends VisualEditor.DynamicPickList{
    
    global override VisualEditor.DataRow getDefaultValue() {
        Id recordTypeId =
            Schema.SObjectType.SDO_Einstein_GPT_Configuration__c.getRecordTypeInfosByDeveloperName()
            .get('SDO_Einstein_Sales').getRecordTypeId();
        SDO_Einstein_GPT_Configuration__c defaultConfig = [SELECT Id, Name FROM SDO_Einstein_GPT_Configuration__c WHERE RecordTypeId = :recordTypeId limit 1];
        VisualEditor.DataRow defaultValue = new VisualEditor.DataRow(defaultConfig.Name, defaultConfig.Id);
        return defaultValue;
    }
    
    global override VisualEditor.DynamicPickListRows getValues() {
        Id recordTypeId =
            Schema.SObjectType.SDO_Einstein_GPT_Configuration__c.getRecordTypeInfosByDeveloperName()
            .get('SDO_Einstein_Sales').getRecordTypeId();
        VisualEditor.DynamicPickListRows myValues = new VisualEditor.DynamicPickListRows();
        //myValues.addRow(getDefaultValue());
        
        List <SDO_Einstein_GPT_Configuration__c> allConfigurations = [SELECT Id, Name FROM SDO_Einstein_GPT_Configuration__c WHERE RecordTypeId = :recordTypeId];
        for (SDO_Einstein_GPT_Configuration__c i : allConfigurations){
            myValues.addRow(new VisualEditor.DataRow(i.Name, String.valueOf(i.Id)));
        }        
        return myValues;  
        
    }
}