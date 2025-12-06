/*
 	* Created by Jesse Chase
 		* jchase@salesforce.com
 			* 12/05/2018.
*/
global class DemoConfigurator{
    /** Get All Demo Settings from Demo Settings Object **/
	@AuraEnabled
    global static List<DemoSettings__c> GetSettings() {
        return [SELECT Id ,Enablement_Type__c,Name,Description__c,DeveloperName__c ,Configuration_Name__c,Enablement_Description__c,Enabled__c FROM DemoSettings__c Order By Order__c ASC];
    }
    /** Get Org Base URL **/
    @AuraEnabled
    public static String getBaseURL(){
        return URL.getSalesforceBaseUrl().toExternalForm(); 
    } 
    /** Update all Tasks related to Charles Green, Daniel Lawrence, and Catherine Welch to roll forward 60 days **/
    @AuraEnabled
    global static void UpdateCareTasks(Integer numofdays,String contactID){
        System.debug('Contact ID: ' + contactID);
        System.debug('Number of days: ' + numofdays);
        String goalId;
        List<Task> TasksToUpdate = new List<Task>();
        List<HealthCloudGA__CarePlanGoal__c> GoalsPlaceholder = new List<HealthCloudGA__CarePlanGoal__c>();
        List<HealthCloudGA__CarePlanGoal__c> GoalsToUpdate = new List<HealthCloudGA__CarePlanGoal__c>();
        Set<Id> GoalIds = new Set<Id>();
        String contactName = [SELECT Name From Contact WHERE ID = :contactID].Name;
		List<User> Owners = [SELECT Id FROM User WHERE Name = :contactName];
        List<Contact> ContactIDs = [SELECT Id FROM Contact WHERE Name = :contactName];
        
        /* Update all tasks  */
        
            Task[] tasks = [SELECT Id, WhoId, WhatId,Subject, OwnerId, ActivityDate, Status 
                            FROM Task 
                            WHERE (OwnerId IN :Owners OR WhoId IN :ContactIDs) 
                            AND (Status != 'Completed')];
            for(Task t: tasks) {
                if (t.ActivityDate != NULL) {
                	t.ActivityDate = t.ActivityDate.addDays(integer.valueof(numofdays));
                    System.Debug('Updated Task ID ' + t.Id + 'With Date: ' + t.ActivityDate);
                    TasksToUpdate.add(t);
                }
                goalId = t.WhatId;
                System.Debug('Goal ID: '+ goalId);
                HealthCloudGA__CarePlanGoal__c[] goals = [SELECT Id, HealthCloudGA__ActivityDate__c,HealthCloudGA__CarePlan__c  
                                                          FROM HealthCloudGA__CarePlanGoal__c 
                                                          WHERE HealthCloudGA__CarePlan__c = :goalId];
                for(HealthCloudGA__CarePlanGoal__c g: goals) {
                	if(g.HealthCloudGA__ActivityDate__c != NULL){
                        if(!GoalIds.contains(g.Id)) { 
                            g.HealthCloudGA__ActivityDate__c = g.HealthCloudGA__ActivityDate__c.addDays(integer.valueof(numofdays));
                        	System.Debug('Updated Goal ID:  ' + g.Id + ' With Date: ' + g.HealthCloudGA__ActivityDate__c);
                        	GoalsToUpdate.add(g); 
                        }
                        GoalIds.add(g.Id);
                    }
                }  
            }
        
        try{
            update TasksToUpdate;
            update GoalsToUpdate;
        }catch(exception e){
            System.debug('Update Error Case Fields Error: ' + e);
        }
    }
    /* Update Patient Device Data Dates */
    @AuraEnabled
    global static void UpdatePatientDataDates(Integer numofdays){
       	List<Patient_Device_Dataset__c> UpdateList = new List<Patient_Device_Dataset__c>();
		List<Patient_Device_Dataset__c> deviceData = [SELECT ID, Chart_1_Date__c, Chart_2_Date__c, Chart_3_Date__c 
                                                      FROM Patient_Device_Dataset__c];
        
        for(Patient_Device_Dataset__c d: deviceData) {
            if(d.Chart_1_Date__c != NULL){
            	d.Chart_1_Date__c = d.Chart_1_Date__c.addDays(integer.valueof(numofdays));
            }
            if(d.Chart_2_Date__c != NULL){
            	d.Chart_2_Date__c = d.Chart_2_Date__c.addDays(integer.valueof(numofdays));
            }
            if(d.Chart_3_Date__c != NULL){
            	d.Chart_3_Date__c = d.Chart_3_Date__c.addDays(integer.valueof(numofdays));
            }
            UpdateList.add(d); 
        }
        try{
            update UpdateList;
        }catch(exception e){
            System.debug('Update Error Patient Data Error: ' + e);
        }
    }
    
    /* Update Secure Messaging Community URL */
    @AuraEnabled
    global static void UpdateCommunityURL(){  
        /* Rebuild the Community URL to Staged CloudCraze Cart */
        String domain = [SELECT Domain FROM Domain].domain;
        String myCommunity = [SELECT Name,UrlPathPrefix FROM Network WHERE Name = 'Makana Health Member Community'].UrlPathPrefix;
        String FullCommunity = 'https://' + domain + '/' + myCommunity;
        
        Contact[] contacts = [SELECT Id, Member_Community_URL__c FROM Contact WHERE FirstName = 'Charles' AND LastName = 'Green'];
        for(Contact c: contacts) {
        	c.Member_Community_URL__c = FullCommunity;
        }
        /** Attempt to update the Contact fields and throw error in debug log if it fails **/
        try{
            update contacts;
        }catch(exception e){
            System.debug('Update Contact Fields Error: ' + e);
        } 
    } 
        
    /* Update Patient Condition Dates */
    @AuraEnabled
    global static void UpdatePatientConditionData(Integer numofdays,String contactID){
        String AccountId = [SELECT AccountId From Contact WHERE ID = :contactID].AccountId;
        String contactName = [SELECT Name From Account WHERE ID = :AccountId].Name;
        /* Roll Forward Condition Dates */
        List<HealthCloudGA__EhrCondition__c> ConditionList = [SELECT ID, HealthCloudGA__DateAsserted__c,HealthCloudGA__DateDocumented__c 
                                                              FROM HealthCloudGA__EhrCondition__c 
                                                              WHERE HealthCloudGA__Account__r.Name = :contactName];
        for(HealthCloudGA__EhrCondition__c c: ConditionList) {
            if(c.HealthCloudGA__DateAsserted__c != NULL){
            	c.HealthCloudGA__DateAsserted__c = c.HealthCloudGA__DateAsserted__c.addDays(integer.valueof(numofdays));
            }
        }
        try{
            update ConditionList;
        }catch(exception e){
            System.debug('Update Error Patient Data Error: ' + e);
        }
    }
    /* Update Patient Encounter Dates */
    @AuraEnabled
    global static void UpdatePatientEncounterData(Integer numofdays,String contactID){
        String AccountId = [SELECT AccountId From Contact WHERE ID = :contactID].AccountId;
        String contactName = [SELECT Name From Account WHERE ID = :AccountId].Name;
        /* Roll Forward Encounter Dates */
        List<HealthCloudGA__EhrEncounter__c> EncounterList = [SELECT ID, HealthCloudGA__PeriodEnd__c ,HealthCloudGA__PeriodStart__c  
                                                              FROM HealthCloudGA__EhrEncounter__c 
                                                              WHERE HealthCloudGA__Account__r.Name = :contactName];
        for(HealthCloudGA__EhrEncounter__c e: EncounterList) {
            if(e.HealthCloudGA__PeriodEnd__c != NULL){
            	e.HealthCloudGA__PeriodEnd__c = e.HealthCloudGA__PeriodEnd__c.addDays(integer.valueof(numofdays));
            }
            if(e.HealthCloudGA__PeriodStart__c != NULL){
            	e.HealthCloudGA__PeriodStart__c = e.HealthCloudGA__PeriodStart__c.addDays(integer.valueof(numofdays));
            }
        }
        try{
            update EncounterList;
        }catch(exception e){
            System.debug('Update Error Patient Data Error: ' + e);
        }
    }
    /* Update Patient Procedure Dates*/
    @AuraEnabled
    global static void UpdatePatientProcedureData(Integer numofdays,String contactID){
        String AccountId = [SELECT AccountId From Contact WHERE ID = :contactID].AccountId;
        String contactName = [SELECT Name From Account WHERE ID = :AccountId].Name;
        List<HealthCloudGA__EHRProcedure__c> ProcedureList = [SELECT ID,HealthCloudGA__PerformedDateTime__c  
                                                              FROM HealthCloudGA__EHRProcedure__c 
                                                              WHERE HealthCloudGA__Account__r.Name = :contactName];
        for(HealthCloudGA__EHRProcedure__c p: ProcedureList) {
            if(p.HealthCloudGA__PerformedDateTime__c != NULL){
            	p.HealthCloudGA__PerformedDateTime__c = p.HealthCloudGA__PerformedDateTime__c.addDays(integer.valueof(numofdays));
            }
        }
        try{
            update ProcedureList;
        }catch(exception e){
            System.debug('Update Error Patient Data Error: ' + e);
        }
    }
    /** Update Demo Settings to Enabled **/
    @AuraEnabled
    global static List<DemoSettings__c> UpdateDemoSetting(String WhichSetting) {
        
        DemoSettings__c[] demosetting = [SELECT Id FROM DemoSettings__c WHERE DeveloperName__c = :WhichSetting];
            for(DemoSettings__c ds: demosetting) {
                ds.Enabled__c = true;
            }
        /** Attempt to update the demo setting fields and throw error in debug log if it fails **/
        try{
            update demosetting;
            return [SELECT Id, Name,Description__c,DeveloperName__c,functionName__c ,Configuration_Name__c,Enablement_Description__c,Enabled__c,AllowEnable__c FROM DemoSettings__c WHERE AllowEnable__c = true Order By Order__c ASC];
        }catch(exception e){
            System.debug('Update Demo Setting Error: ' + e);
            return null;
        }
    }
    
    /* Update patient Prescription Dates */
    @AuraEnabled
    global static void UpdatePatientPrescriptionData(Integer numofdays,String contactID){
        String AccountId = [SELECT AccountId From Contact WHERE ID = :contactID].AccountId;
        String contactName = [SELECT Name From Account WHERE ID = :AccountId].Name;
        List<HealthCloudGA__EhrMedicationPrescription__c> MedicationList = [SELECT ID,HealthCloudGA__DateWritten__c,HealthCloudGA__DispenseValidityPeriodStart__c,HealthCloudGA__DispenseValidityPeriodEnd__c  
                                                                            FROM HealthCloudGA__EhrMedicationPrescription__c 
                                                                            WHERE HealthCloudGA__Account__r.Name =:contactName];
        for(HealthCloudGA__EhrMedicationPrescription__c m: MedicationList) {
            if(m.HealthCloudGA__DateWritten__c != NULL){
            	m.HealthCloudGA__DateWritten__c = m.HealthCloudGA__DateWritten__c.addDays(integer.valueof(numofdays));
            }
            if(m.HealthCloudGA__DispenseValidityPeriodEnd__c != NULL){
            	m.HealthCloudGA__DispenseValidityPeriodEnd__c = m.HealthCloudGA__DispenseValidityPeriodEnd__c.addDays(integer.valueof(numofdays));
        	}
            if(m.HealthCloudGA__DispenseValidityPeriodStart__c != NULL){
            	m.HealthCloudGA__DispenseValidityPeriodStart__c = m.HealthCloudGA__DispenseValidityPeriodStart__c.addDays(integer.valueof(numofdays));
            }
        }
        try{
            update MedicationList; 
        }catch(exception e){
            System.debug('Update Error Patient Data Error: ' + e);
        }
    }
    
    @RemoteAction
    global static Map<String,Object> DataConnectors() {
        string sessionId = UserInfo.getSessionId();
        string base = URL.getSalesforceBaseUrl().toExternalForm();
        String url = base + '/services/data/v47.0/wave/dataConnectors';  
        
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);
        req.setMethod('GET');
        
        String authorizationHeader = 'OAuth ' + sessionId;
        req.setHeader('Authorization', authorizationHeader);
        req.setHeader('Content-Type', 'application/json');
        
        // Send the request, and return a response
        HttpResponse res = h.send(req);
        
        Map<String,Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        
        return responseMap;
        
    } 
    /** Run all Analytics Dataflows with this handy snippet **/
    @RemoteAction
    global static void RunDataConnector(String ConnectorId) {
        string sessionId = UserInfo.getSessionId();
        string base = URL.getSalesforceBaseUrl().toExternalForm();
        string ingest = '/services/data/v47.0/wave/dataConnectors/' + ConnectorId + '/ingest';
        String url = base + ingest;  
        
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);
        req.setMethod('POST');
        
        String authorizationHeader = 'OAuth ' + sessionId;
        req.setHeader('Authorization', authorizationHeader);
        req.setHeader('Content-Type', 'application/json'); 
        
        // Send the request, and return a response
        HttpResponse res = h.send(req);
        
    }
}