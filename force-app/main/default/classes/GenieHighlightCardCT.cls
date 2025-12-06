public class GenieHighlightCardCT {
    
    @AuraEnabled
    public static Genie_ContactWrapper getContact (Id currentRecord) {
    	Contact customerRecord = new Contact();
        String sObjName = currentRecord.getSObjectType().getDescribe().getName();
        DescribeSObjectResult describeResult = Contact.sObjectType.getDescribe();
        List<String> fieldNames = new List<String>(describeResult.fields.getMap().keySet());
            
        if(sObjName == 'Contact'){
            customerRecord = Database.query('Select ' + String.join(fieldNames, ',') + ' From Contact Where Id =:currentRecord');    
        } else if(sObjName == 'Account'){
            customerRecord = Database.query('Select ' + String.join(fieldNames, ',') + ' From Contact where Account.Id = :currentRecord');   
        } else if(sObjName == 'Case'){
            customerRecord = Database.query('Select ' + String.join(fieldNames, ',') + ' From Contact where Id in (Select ContactId from Case where Id = :currentRecord)');            
        } else if(sObjName == 'MessagingSession'){
            customerRecord = Database.query('Select ' + String.join(fieldNames, ',') + ' From Contact where Id in (Select EndUserContactId from MessagingSession where Id = :currentRecord)');            
        } else if(sObjName == 'VoiceCall'){
            customerRecord = Database.query('Select ' + String.join(fieldNames, ',') + ' From Contact where Id in (Select Contact__c from VoiceCall where Id = :currentRecord)');            
        } 
        
        return new Genie_ContactWrapper(customerRecord);
    }  
    
    public class Genie_ContactWrapper {
        @AuraEnabled public string contactPicture {get; set;}
        @AuraEnabled public string name {get; set;}
        @AuraEnabled public string email {get; set;}
        @AuraEnabled public string phone {get; set;}
        @AuraEnabled public string street {get; set;}
        @AuraEnabled public string city {get; set;}
        @AuraEnabled public string state {get; set;}
        @AuraEnabled public string zip {get; set;}
        @AuraEnabled public string customerId {get; set;}
        @AuraEnabled public string kpi1 {get; set;}
        @AuraEnabled public string kpi2 {get; set;}
        @AuraEnabled public string kpi3 {get; set;}
        @AuraEnabled public string kpi4 {get; set;}
        @AuraEnabled public Decimal score1 {get; set;}
        @AuraEnabled public Decimal score2 {get; set;}
        
        public Genie_ContactWrapper(Contact customerRecord) {
            String customerRecordId = customerRecord.Id;
            
            //custom fields already existing in demo org. need to grab the correct api name ignoring any field name prefixes
            String profilePicSuffix = 'Cust360_Contact_Picture_URL__c';
            String customerIdSuffix = 'Cust360_Id__c';
            String kpi1Suffix = 'Cust360_Metric1__c';
            String kpi2Suffix = 'Cust360_Metric2__c';
            
            for (SObjectField field : Contact.SObjectType.getDescribe().fields.getMap().values()) {
                
                String fieldName = String.valueOf(field); 
                if (fieldName.endsWith(profilePicSuffix)) {
                     
                    SObject temp = Database.query('Select ' + fieldName + ' From Contact Where Id =:customerRecordId')[0]; 
                    if (temp.get(fieldName) != null){
                        this.contactPicture  = temp.get(fieldName).toString();
                    } else {
                        this.contactPicture = '';
                    }

                } else if (String.valueOf(field).endsWith(customerIdSuffix)) {
                    
                    SObject temp = Database.query('Select ' + fieldName + ' From Contact Where Id =:customerRecordId')[0]; 
                    if (temp.get(fieldName) != null){
                        this.customerId  = temp.get(fieldName).toString();
                    } else {
                        this.customerId = '';
                    }
                    
                } else if (String.valueOf(field).endsWith(kpi1Suffix)) {
                    
                    SObject temp = Database.query('Select ' + fieldName + ' From Contact Where Id =:customerRecordId')[0];
                    if (temp.get(fieldName) != null){
                        this.kpi1  = temp.get(fieldName).toString();
                    } else {
                        this.kpi1 = '';
                    }
                    
                    
                } else if (String.valueOf(field).endsWith(kpi2Suffix)) {
                    
                    SObject temp = Database.query('Select ' + fieldName + ' From Contact Where Id =:customerRecordId')[0];
                    if (temp.get(fieldName) != null){
                        this.kpi2  = temp.get(fieldName).toString();
                    } else {
                        this.kpi2 = '';
                    }
                    
                }
            }
            
            //standard fields
            this.name = customerRecord.Name;
            this.email = customerRecord.Email;
            this.phone = customerRecord.Phone;
            this.street = customerRecord.MailingStreet;
            this.city = customerRecord.MailingCity;
            this.state = customerRecord.MailingState;
            this.zip = customerRecord.MailingPostalCode;
            
            //custom fields created with package
            this.kpi3 = customerRecord.Cust360_Metric3__c;
            this.kpi4 = customerRecord.Cust360_Metric4__c;
            this.score1 = customerRecord.Cust360_Purchase_Score__c;
            this.score2 = customerRecord.Cust360_Engagement_Score__c;
            
            
        }
        
    }
    
    
}