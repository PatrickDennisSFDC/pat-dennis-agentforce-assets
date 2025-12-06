public class SDO_Service_SCVController {

    @AuraEnabled
    public static void publishPlatformEvent(Decimal newStage) {
        SDO_Service_SCVConversationChange__e  conversationPlatformEvt = new SDO_Service_SCVConversationChange__e();
        conversationPlatformEvt.Stage__c = newStage;

        system.debug('newstage::: ' + newStage);

        EventBus.publish(conversationPlatformEvt);
    }

    @AuraEnabled
    public static SCVSimulator_ConversationWrapper fetchConversation(String conversationId, String voiceCallRecordId){
        return new SCVSimulator_ConversationWrapper(conversationId, voiceCallRecordId);
    }

    public class SCVSimulator_ConversationWrapper {
        @AuraEnabled public SDO_Service_SCVConversation__c conversation {get; set;}
        @AuraEnabled public List<SDO_Service_SCVConversationMessage__c> messages {get; set;}

        public SCVSimulator_ConversationWrapper(String conversationId, String voiceCallRecordId) {

            this.conversation = [SELECT Id FROM SDO_Service_SCVConversation__c WHERE Id = :conversationId LIMIT 1];

            this.messages = [SELECT Id, SCV_Simulator_Conversation__c, Message__c, Conversation_Order__c, Message_Type__c
                             FROM SDO_Service_SCVConversationMessage__c
                             WHERE SCV_Simulator_Conversation__c =:conversationId
                             ORDER BY Conversation_Order__c, LastModifiedDate ASC];
        }
    }

    @AuraEnabled
    public static void routeWork() {

        VoiceCall workItem = [SELECT Id FROM VoiceCall ORDER BY LastModifiedDate desc LIMIT 1];
        ServiceChannel channel = [SELECT Id FROM ServiceChannel WHERE MasterLabel ='Phone'];

        AgentWork work = new AgentWork();
        work.WorkItemId = workItem.Id;
        work.ServiceChannelId = channel.Id;
        work.UserId = UserInfo.getUserId();

        insert work;

    }

}