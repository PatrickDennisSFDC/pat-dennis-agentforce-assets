public class DE_RY_KnowledgeArticle_Flow {
    
    @AuraEnabled
    public static List<FlowDefinitionView> getFlowNames(Boolean showActivesOnly) {
        if(network.getNetworkId() == null){
            showActivesOnly = true;
            
            List<FlowDefinitionView> curFlows;
            
            if (showActivesOnly){
                curFlows = [SELECT Id,ApiName,Label FROM FlowDefinitionView WHERE ActiveVersionId!=NULL];
            } else {
                curFlows = [SELECT Id,ApiName,Label FROM FlowDefinitionView];
            }
            
            System.debug('curFlows is: ' + curFlows);
            return curFlows;
        }else{
            return null;
        }
    }
    
    
    @AuraEnabled
    public static string getFlowLabel(string flowAPIName) {
		FlowDefinitionView fdv = [Select Id, Label from FlowDefinitionView where ApiName =: flowAPIName];
        return fdv.Label;
    }
    
    @AuraEnabled
    public static boolean getIsCommunity(){
        return network.getNetworkId() != null;
    }
    
}