global class AgentCreate_Deploy {
    
    @InvocableMethod(label='Deploy Agent' 
                     description='Gemnerate Topics and deploy agent')
    public static List<agentcreator__AgentDetail__c> deployAgent(List<AgentDetailRequest> requests) {
        List<agentcreator__AgentDetail__c> results = new List<agentcreator__AgentDetail__c>();
        
        for(AgentDetailRequest req : requests) {
            results.add(AgentDetailController.setTopicJson(req.AgentDetailId));
        }
        return results;
    }
    
    public class AgentDetailRequest {
        @InvocableVariable(label='AgentDetailId' required=true description='The recordId of the AgentDetail Record')
        public String AgentDetailId;

    }
}