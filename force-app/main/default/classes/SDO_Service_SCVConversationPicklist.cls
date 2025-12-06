global class SDO_Service_SCVConversationPicklist extends VisualEditor.DynamicPickList{

    global override VisualEditor.DataRow getDefaultValue(){

        SDO_Service_SCVConversation__c tempConversation = [SELECT Id, Name FROM SDO_Service_SCVConversation__c LIMIT 1];
        if(tempConversation != null){
            VisualEditor.DataRow defaultValue = new VisualEditor.DataRow(tempConversation.Name, tempConversation.Id);
            return defaultValue;
        } else {
            return null;
        }
    }

    global override VisualEditor.DynamicPickListRows getValues() {

        VisualEditor.DynamicPickListRows  conversationOptions = new VisualEditor.DynamicPickListRows();
        List<SDO_Service_SCVConversation__c> conversationList = [SELECT Id, Name FROM SDO_Service_SCVConversation__c];

        for(integer i = 0; i < conversationList.size(); i++){
            conversationOptions.addRow(new VisualEditor.DataRow(conversationList[i].Name, '' + conversationList[i].Id));
        }

        return conversationOptions;
    }
}