global class AgentSpecUpdater {

    @InvocableMethod(label='Update Agent Spec' description='Updates the agent specification for a given agent ID.')
    public static List<String> updateAgentSpecs(List<UpdateSpecRequest> requests) {
        List<agentcreator__AgentDetail__c> updatedAgents = new List<agentcreator__AgentDetail__c>();
        
        for (UpdateSpecRequest request : requests) {
            // Fetch existing agent details
            agentcreator__AgentDetail__c agentDetail = [SELECT Id, agentcreator__AgentType__c, agentcreator__CompanyName__c, agentcreator__Spec__c, agentcreator__Description__c, agentcreator__Role__c, agentcreator__CompanyWebsite__c
                                                                             FROM agentcreator__AgentDetail__c 
                                                                             WHERE Id = :request.agentId LIMIT 1];
            
            // Prepare request for AgentJobSpecGenerator
            agentcreator.AgentJobSpecGenerator.Request generatorRequest = new agentcreator.AgentJobSpecGenerator.Request();
            generatorRequest.role = agentDetail.agentcreator__Role__c;
            generatorRequest.companyName = agentDetail.agentcreator__CompanyName__c;
            generatorRequest.domain = agentDetail.agentcreator__AgentType__c;
            generatorRequest.companyWebsite = agentDetail.agentcreator__CompanyWebsite__c;
            generatorRequest.agentType = agentDetail.agentcreator__AgentType__c;
            generatorRequest.description = agentDetail.agentcreator__Description__c + ', requirements included later: ' + request.newSpec;

            // Generate new job specifications using the managed package namespace
            List<agentcreator.AgentJobSpecGenerator.Response> responses = agentcreator.AgentJobSpecGenerator.generateJobSpecs(new List<agentcreator.AgentJobSpecGenerator.Request>{generatorRequest});
            
            if (!responses.isEmpty()) {
                // Update agent specification with new job specs
                agentDetail.agentcreator__Spec__c = responses[0].generatedJobSpecs;
                updatedAgents.add(agentDetail);
            }
        }
        
        // Update the agent details in the database
        update updatedAgents;
        List<String> responseSpec = new List<String>();
        responseSpec.add(updatedAgents[0].agentcreator__Spec__c);
        return responseSpec;
    }
    
    public class UpdateSpecRequest {
        @InvocableVariable(required=true description='The ID of the agent to update.')
        public Id agentId;
        
        @InvocableVariable(required=true description='The new requirements for the agent.')
        public String newSpec;
    }
}