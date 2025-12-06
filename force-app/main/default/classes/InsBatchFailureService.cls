global with sharing class InsBatchFailureService implements Callable, vlocity_ins.VlocityOpenInterface2 {
    private static final String SET_REQUEST_ID_INS_CONTRACT = 'setRequestIdToInsuranceContract';
    private static final String CHECK_IF_REQUEST_HAS_FAILURES = 'checkIfRequestHasFailures';
    private static final String GET_BATCH_FAILURE_BY_REQUEST_ID ='getFailedBatchDataByRequestId';
    
    public Object call(String action, Map<String, Object> args) {

        Map<String, Object> input = (Map<String, Object>)args.get('input');
        Map<String, Object> output = (Map<String, Object>)args.get('output');
        Map<String, Object> options = (Map<String, Object>)args.get('options');

        return invokeMethod(action, input, output, options);
    }
    
    global Object invokeMethod(
        String methodName,
        Map<String,Object> inputs,
        Map<String,Object> output,
        Map<String,Object> options)
    {   
        Boolean response = false;
        if(SET_REQUEST_ID_INS_CONTRACT.equalsIgnoreCase(methodName))
        {
            response = setRequestIdToInsuranceContractWithElevatedAccess(inputs, output, options);
        }
        else if(CHECK_IF_REQUEST_HAS_FAILURES.equalsIgnoreCase(methodName))
        {
            response = checkIfRequestHasFailuresWithElevatedAccess(inputs, output, options);
        }
        else if(GET_BATCH_FAILURE_BY_REQUEST_ID.equalsIgnoreCase(methodName))
        {
            response = getFailedBatchDataByRequestIdWithElevatedAccess(inputs, output, options);
        }
        else
        {
            response = false;
        }
        return response;
    }
    
    /**
     * This service is used to set InsuranceAsyncBulkRequest Id to the respective lookup field in InsuranceContract.
     * inputs: 
     *  1. requestId: InsuranceAsyncBulkRequest Id that needs to be set in insurance contract entity
     *  2. contractId: ContractId of Insurance Contract. In other terms, it is the ContractId used for enrollment
    */
    private Boolean setRequestIdToInsuranceContractWithElevatedAccess(
        Map<String,Object> inputs,
        Map<String,Object> output,
        Map<String,Object> options)
    {
        try
        {
            String requestId = (String) getValueFromMap('requestId', inputs, options,false);
            String contractId = (String) getValueFromMap('contractId', inputs, options,false);
            String query = 'Select Id, vlocity_ins__InsuranceAsyncBulkRequest__c  from InsuranceContract where ContractId = \''+contractId+'\'';
            List<SObject> objects = Database.query(query, AccessLevel.SYSTEM_MODE);
            SObject insContract = objects[0];
            insContract.put('vlocity_ins__InsuranceAsyncBulkRequest__c', requestId);
            Database.update(insContract, false, AccessLevel.SYSTEM_MODE);
            output.put('status', true);
        }
        catch(Exception e)
        {
            System.debug(e);
            output.put('status', false);
        }

        return true;
    }
    
    /**
     * This service is used to check if the recent enrollment request has failures or not. 
     * If it has failures then it also returns InsuranceAsyncBulkRequestId
     * inputs: 
     *  1. accountId: Account Id for which the enrollment is initiated and status needs to ce checked.
     * This service first queries last modified Contract associated with provided accountId. And using it fetches requestId from InsuranceContract entity.
     * Using requestId it queries InsuranceAsyncBulkRequest entity and matches JobCount and SuccessfulJobCount field values to detect failures.
    */
    private Boolean checkIfRequestHasFailuresWithElevatedAccess(
        Map<String,Object> inputs,
        Map<String,Object> output,
        Map<String,Object> options)
    {
        try
        {
            String accountId = (String) getValueFromMap('accountId', inputs, options,false);
            String query = 'Select Id, name from Contract where accountId = \''+accountId+'\' and status = \'Activated\' order by LastModifiedDate desc limit 1';
            List<SObject> contracts = Database.query(query, AccessLevel.SYSTEM_MODE);
            SObject contract = contracts[0];
            query = 'Select Id, vlocity_ins__InsuranceAsyncBulkRequest__c from InsuranceContract where contractId = \''+contract.Id+'\'';
            List<SObject> insContracts = Database.query(query, AccessLevel.SYSTEM_MODE);
            String asyncRequestId = (String)insContracts[0].get('vlocity_ins__InsuranceAsyncBulkRequest__c');
            if(asyncRequestId==null ){
                output.put('status', false);
            }
            else{
                query = 'Select Id, JobCount, SuccessfulJobCount from InsuranceAsyncBulkRequest where id = \''+asyncRequestId+'\'';
                List<SObject> request = Database.query(query, AccessLevel.SYSTEM_MODE);
                if(request[0].get('JobCount') != request[0].get('SuccessfulJobCount')){
                    output.put('status', true);
                    output.put('asyncRequestId' ,asyncRequestId);
                }
                else
                    output.put('status', false);
            }
        }
        catch(Exception e)
        {
            System.debug(e);
        }

        return true;
    }
    
    private String getCensusIdFromMemberId(String memberId){
       List <GroupCensusMember> groupCensusMember = [Select GroupCensusId from GroupCensusMember where Id = :memberId];
       return groupCensusMember[0].GroupCensusId;
    }
    
    private Map <String, GroupCensusMember> getMemberIdToDetailsMap(String censusId){
       List <GroupCensusMember> groupCensusMembers = [Select FirstName, Lastname from GroupCensusMember where groupCensusId = :censusId];
       Map <String, GroupCensusMember> memberIdToDetailsMap = new Map <String, GroupCensusMember>();
       for(GroupCensusMember member: groupCensusMembers) {
           memberIdToDetailsMap.put(String.valueOf(member.Id), member);    
       }
       return memberIdToDetailsMap;
    }

    /**
     * This service is used to find errors for given requestId and create a csv and link to given accountId.
     * inputs: 
     *  1. requestId: InsuranceAsyncBulkRequest Id that needs to be queried for failures.
     *  2. accountId: Account to which error csv needs to be linked.
    */
    private Boolean getFailedBatchDataByRequestIdWithElevatedAccess(
        Map<String,Object> inputs,
        Map<String,Object> output,
        Map<String,Object> options)
    {
        try
        {
            String requestId = (String) getValueFromMap('requestId', inputs, options,false);
            String accountId = (String) getValueFromMap('accountId', inputs, options,false);
            String query = 'Select Id,BatchJobId,AdditionalInformation from InsuranceAsyncBulkRequestItem where InsuranceAsyncBulkRequestId = \''+requestId+'\'';
            List<SObject> asyncRequestItems = Database.query(query, AccessLevel.SYSTEM_MODE);
            Map<String, String> batchJobIdsToPlan = getMapOfBatchJobIdsToPlan(asyncRequestItems);
            Map <String, GroupCensusMember> memberIdToDetailsMap = new Map<String, GroupCensusMember>();
            String csvFile = null;
            System.debug('batchJobIdsToPlan size is:'+batchJobIdsToPlan);
            for(String batchJobId: batchJobIdsToPlan.keySet()){
                query = 'SELECT Id, Record, ErrorDescription FROM BatchJobPartFailedRecord WHERE BatchJobId = \''+batchJobId+'\'';
                List <SObject> batchFailedDetails = Database.query(query, AccessLevel.SYSTEM_MODE);
                System.debug('batchJobId is:'+ batchJobId);
                if(batchFailedDetails==null || batchFailedDetails.size()==0){
                    continue;
                }
                if(memberIdToDetailsMap == null || memberIdToDetailsMap.isEmpty()){
                    String groupCensusId = getCensusIdFromMemberId((String)batchFailedDetails[0].get('Record'));
                    memberIdToDetailsMap = getMemberIdToDetailsMap(groupCensusId);
                }
                String planName = batchJobIdsToPlan.get(batchJobId);
                csvFile = createCsv(planName, batchFailedDetails, memberIdToDetailsMap, csvFile);
                System.debug('csvFile is:'+ csvFile);
            }
            String contentVersionId = storeAndMailCsv(csvFile,requestId);
            createContentDocumentLink(contentVersionId,accountId);
            output.put('contentVersionId', contentVersionId);
        }
        catch(Exception e)
        {
            System.debug(e);
        }

        return true;
    }
    
    private Map<String, String> getMapOfBatchJobIdsToPlan(List<SObject> asyncRequestItems){
        Map<String, String> mapOfBatchJobToPlan = new Map<String, String>();
        for(SObject item:asyncRequestItems){
        String batchJobId= (String)item.get('BatchJobId');
        String additionalInformation = (String)item.get('AdditionalInformation');
        Map<String,Object> requestJobData = (Map<String,Object>) Json.deserializeUntyped(additionalInformation);
        String productName = String.valueOf((requestJobData).get('planName'));
        mapOfBatchJobToPlan.put(batchJobId, productName);
        }
        return mapOfBatchJobToPlan;
    }
    
    private String createCsv(String planName, List <SObject> batchFailedDetails, Map <String, GroupCensusMember> memberIdToDetailsMap, String csvFile){
        String csvColumnHeader;
        List<String> csvRowValues = new List<String>();
        for(SObject record : batchFailedDetails){
            GroupCensusMember member = memberIdToDetailsMap.get((String)record.get('Record'));
            String csvRowVal = member.FirstName + ' ' + member.Lastname + ',' + planName + ',' + record.get('ErrorDescription');
            csvRowValues.add(csvRowVal);
        }
        if(csvFile == null){
            csvColumnHeader = 'Member Name, Product Name, Error\n';
            csvFile = csvColumnHeader + String.join(csvRowValues,'\n');
        }
        else{
            csvFile += String.join(csvRowValues,'\n');
        }
        csvFile +='\n';
        return csvFile;
    }
    
    private String storeAndMailCSV(String csvFile,String requestId){
        blob b;
        if(Test.isRunningTest()) { 
            b = blob.valueOf('Unit.Test');
        } else {
            b = Blob.valueOf(csvFile);
        }                        
 
        
        ContentVersion cv = new ContentVersion();
        cv.ContentLocation = 'S'; //denotes it resides on Salesforce
        cv.Title = 'BatchFailureErrorCSV-'+requestId; //title of the file
        cv.PathOnClient = 'BatchFailureErrorCSV-'+requestId +'.csv'; // full path within Salesforce this can just be the name of file to be in the library
        cv.VersionData = b; //file data
        insert cv;   
        return cv.Id;        
    }
    
    private void createContentDocumentLink(String contentVersionId, String accountId){
        List<ContentVersion> cv = [Select Id, ContentDocumentId from ContentVersion where Id = :contentVersionId];
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = cv[0].ContentDocumentId;
        cdl.LinkedEntityId = accountId;
        insert cdl;
    }
    
    private Object getValueFromMap (
        String key,
        Map<String, Object> inputs,
        Map<String, Object> options,
        Object defaultValue)
    {
        Object returnValue = getValueFromMap(key, inputs, options);

        if (returnValue == null && defaultValue != null)
        {
            return defaultValue;
        }

        return returnValue;
    }

    private Object getValueFromMap (
        String key,
        Map<String, Object> inputs,
        Map<String, Object> options)
    {
        if (inputs != null && inputs.get(key) != null && String.isNotBlank(String.valueOf(inputs.get(key))))
        {
            return inputs.get(key);
        }
        else if (options != null && options.get(key) != null && String.isNotBlank(String.valueOf(options.get(key))))
        {
            return options.get(key);
        }

        return null;
    }
}