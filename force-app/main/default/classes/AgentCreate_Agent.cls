global class AgentCreate_Agent {
    
    @InvocableMethod(label='Create Agent Detail record' 
                     description='Create Agent Detail record')
    public static List<agentcreator__AgentDetail__c> createAgentDetails(List<AgentDetailRequest> requests) {
        List<agentcreator__AgentDetail__c> results = new List<agentcreator__AgentDetail__c>();
   
        for(AgentDetailRequest req : requests) {
            agentcreator__AgentDetail__c agentDetail = AgentDetailController.createAgentDetail(
                req.companyName,
                req.companyWebsite,
                req.industry,
                req.agentDescription,
                req.jobTitle,
                req.agentType
            );
            
            results.add(agentDetail);
        }
        
        return results;
        
    }
    
    public class AgentDetailRequest {
        @InvocableVariable(label='Company Name' required=true description='The name of the company')
        public String companyName;
        
        @InvocableVariable(label='Company Website' required=true description='The company\'s website')
        public String companyWebsite;
        
        @InvocableVariable(label='Industry' required=true description='The industry of the company')
        public String industry;
        
        @InvocableVariable(label='Agent Description' required=true description='Agent Description/Requirements')
        public String agentDescription;
        
        @InvocableVariable(label='Job Title' required=true description='Job Title/Usecase')
        public String jobTitle;

        @InvocableVariable(label='Agent Type' required=true description='The type of agent, internal or external, if internal add: "Internal - Employee facing", if external add:  "Customer - Consumer facing"')
        public String agentType;
        
    }
}