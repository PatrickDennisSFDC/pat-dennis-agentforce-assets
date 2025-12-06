global class AgentDetailController {
    @AuraEnabled(cacheable=true)
    public static agentcreator__AgentDetail__c getAgentDetail(Id recordId) {
        System.debug('Querying AgentDetail with ID: ' + recordId);
        
        List<agentcreator__AgentDetail__c> agents = [SELECT Id, Name, agentcreator__CompanyName__c, 
                agentcreator__CompanyWebsite__c, agentcreator__Domain__c, agentcreator__Description__c, 
                agentcreator__Role__c, agentcreator__Spec__c 
                FROM agentcreator__AgentDetail__c 
                WHERE Id = :recordId];
        
        return !agents.isEmpty() ? agents[0] : null;
    }

    @AuraEnabled
    public static agentcreator__AgentDetail__c createAgentDetail(String companyName, String companyWebsite, 
                                                  String industry, String agentDescription, 
                                                  String jobTitle, String agentType) {
        agentcreator__AgentDetail__c agentDetail = new agentcreator__AgentDetail__c(
            Name = companyName + ' Agent',
            agentcreator__CompanyName__c = companyName,
            agentcreator__CompanyWebsite__c = companyWebsite,
            agentcreator__Domain__c = industry,
            agentcreator__Description__c = agentDescription,
            agentcreator__Role__c = jobTitle,
            agentcreator__AgentType__c = agentType
        );
        
        insert agentDetail;
        agentDetail.agentcreator__Status__c = 'Metadata Generated';
        update agentDetail;
        
        return [SELECT Id, Name, agentcreator__CompanyName__c, agentcreator__CompanyWebsite__c, agentcreator__Domain__c, 
        agentcreator__Description__c, agentcreator__Role__c, agentcreator__Spec__c, agentcreator__AgentType__c, agentcreator__Status__c 
                FROM agentcreator__AgentDetail__c WHERE Id = :agentDetail.Id];
    }


    public static agentcreator__AgentDetail__c setTopicJson(Id agentId){
        List<agentcreator__AgentDetail__c> agents = (List<agentcreator__AgentDetail__c>) Database.Query(
            'SELECT Id, agentcreator__JSONMD__c, agentcreator__AgentType__c, agentcreator__Spec__c, agentcreator__Status__c, agentcreator__CompanyName__c FROM agentcreator__AgentDetail__c WHERE Id = :agentId'
          );
          if(agents.size() == 0){
            System.debug('ERROR: No agent found!');
            throw new NullPointerException();
          }
          agentcreator__AgentDetail__c agent =  agents[0];
          agentcreator.AgentJsonSpecGenerator.Request req = new agentcreator.AgentJsonSpecGenerator.Request();
          req.spec = agents[0].agentcreator__Spec__c;
          req.agentType = agents[0].agentcreator__AgentType__c;
          req.companyName = agents[0].agentcreator__CompanyName__c;
          req.autoDiscoverActions = false;
          
          // Create request list (since the invocable method expects a list)
          List<agentcreator.AgentJsonSpecGenerator.Request> requests = new List<agentcreator.AgentJsonSpecGenerator.Request>{req};
          
          // Call the method
          List<agentcreator.AgentJsonSpecGenerator.Response> responses = agentcreator.AgentJsonSpecGenerator.generateJobSpecs(requests);
          agents[0].agentcreator__JSONMD__c = responses[0].generatedJsonOutput;
          
          // Create Input object for AgentMDCreator
          agentcreator.AgentMDCreator.Input agentInput = new agentcreator.AgentMDCreator.Input();
          agentInput.agentId = agentId;
          agentInput.jsonTxt = responses[0].generatedJsonOutput;
          
          // Call createAgent with a List of Input
          agentcreator.AgentMDCreator.createAgent(new List<agentcreator.AgentMDCreator.Input>{agentInput});

          agents[0].agentcreator__Status__c = 'Deploy Pending';
          update  agents[0];
          agentcreator__AgentDetail__c updatedAgent = [SELECT Id, agentcreator__AgentType__c, agentcreator__Status__c, agentcreator__CompanyName__c FROM agentcreator__AgentDetail__c WHERE Id = :agentId];
          return updatedAgent;

    }

    @AuraEnabled
    public static String updateAgentSpec(Id agentId, String newSpec) {
        // Query the agent record
        agentcreator__AgentDetail__c agent = [SELECT Id, agentcreator__Spec__c 
                                              FROM agentcreator__AgentDetail__c 
                                              WHERE Id = :agentId LIMIT 1];
        
        // Update the spec field
        agent.agentcreator__Spec__c = newSpec;
        
        // Update the record in the database
        update agent;
        
        // Return the updated agent
        return [SELECT Id, agentcreator__Spec__c 
                FROM agentcreator__AgentDetail__c 
                WHERE Id = :agentId LIMIT 1].agentcreator__Spec__c;
    }

}