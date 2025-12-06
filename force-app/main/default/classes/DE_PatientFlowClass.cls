global class DE_PatientFlowClass {
    global class InvocClass{ 
        @InvocableVariable
        global string accountId;
        @invocableVariable
        global List<String> Alergies;
        @invocableVariable
        global List<String> Conditions;
        @invocableVariable
        global List<String> Medications;
    }
    @InvocableMethod
    public static Void getSelectAllergies(List<InvocClass> AlergiesList) {
        List<HealthCloudGA__EhrAllergyIntolerance__c> NHA= new List<HealthCloudGA__EhrAllergyIntolerance__c>();
        List<HealthCloudGA__EhrCondition__c> NHC= new List<HealthCloudGA__EhrCondition__c>();
        List<HealthCloudGA__EhrMedicationPrescription__c> NHM= new List<HealthCloudGA__EhrMedicationPrescription__c>();
        for(InvocClass ivc:AlergiesList) {
            //Allergy Records
            if(ivc.Alergies[0]!='' && ivc.Alergies[0]!=null){
                System.debug('Alergies.size'+ivc.Alergies[0]);
                List<String> alergyList = new List<String>();
                alergyList=ivc.Alergies[0].split(';');
                for(integer i=0;i<alergyList.size();i++){
                    HealthCloudGA__EhrAllergyIntolerance__c HA= new HealthCloudGA__EhrAllergyIntolerance__c();
                    HA.HealthCloudGA__Substance255__c=alergyList[i];
                    HA.HealthCloudGA__Account__c=ivc.accountId;
                    NHA.add(HA);
                }
            }
            System.debug('ivc.Medications'+ivc.Medications[0]);
            if(ivc.Medications[0]!='' && ivc.Medications[0]!=null){
                //Medication Records                
                List<String> MedicationList = new List<String>();
                MedicationList=ivc.Medications[0].split(';');
                for(integer i=0;i<MedicationList.size();i++){
                    HealthCloudGA__EhrMedicationPrescription__c HM= new HealthCloudGA__EhrMedicationPrescription__c();
                    HM.HealthCloudGA__MedicationName__c = MedicationList[i];                    
                    HM.HealthCloudGA__Account__c = ivc.accountId;
                    HM.HealthCloudGA__MedicationExpiration__c = Date.today() + 30;
                    HM.HealthCloudGA__StatusLabel__c ='Completed';
                    
                    HM.HealthCloudGA__DispenseMedicationName__c = MedicationList[i];                    
                    HM.HealthCloudGA__DispenseExpectedSupplyDuration__c = 12;
                    HM.HealthCloudGA__DateWritten__c = Datetime.now();
                    HM.HealthCloudGA__DispenseValidityPeriodEnd__c = Datetime.now() + 90;
                    
                    NHM.add(HM);
                }
            }
            //Condition Records
            System.debug('Conditions.size'+ivc.Conditions[0]);
            if(ivc.Conditions[0]!='' && ivc.Conditions[0]!=null){
                List<String> ConditionList = new List<String>();
                ConditionList=ivc.Conditions[0].split(';');
                for(integer i=0;i<ConditionList.size();i++){
                    HealthCloudGA__EhrCondition__c HC= new HealthCloudGA__EhrCondition__c();
                    HC.HealthCloudGA__CodeLabel__c=ConditionList[i];
                    HC.HealthCloudGA__Account__c=ivc.accountId;
                    NHC.add(HC);
                }                
            }
        }
        System.debug('### NHA - ' + NHA);
        System.debug('### NHM - ' + NHM);
        System.debug('### NHC - ' + NHC);
        
        Insert NHA;
        Insert NHM;
        Insert NHC;        
    }
}