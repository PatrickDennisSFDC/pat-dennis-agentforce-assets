public class DE_ResetDataClass {
    
    @AuraEnabled
    public static void resetTheData(String accId){
        //Get the Enrolee ID
        String enrolleeId = [SELECT Id, AccountId, Account.Name, CareProgramId, CareProgram.Name FROM CareProgramEnrollee where AccountId =:accId].Id;
        
        //Delete Auth
        List<AuthorizationFormConsent> getAuthConsent = [SELECT Id, ConsentGiverId FROM AuthorizationFormConsent where ConsentGiverId=:enrolleeId];
        
        //Del Enrollment Card
        List<CareProgramEnrollmentCard> getEnrollCardId = [SELECT CareProgramEnrolleeId, Id FROM CareProgramEnrollmentCard where CareProgramEnrolleeId=:enrolleeId];
        
        //Del Care Prod
        List<CareProgramEnrolleeProduct> CareProgramEnrolleeProduct = [SELECT CareProgramEnrolleeId, Id FROM CareProgramEnrolleeProduct where CareProgramEnrolleeId=:enrolleeId];
        
        CareProgramEnrollee enrollee = [SELECT Id, AccountId, Account.Name, CareProgramId, CareProgram.Name FROM CareProgramEnrollee where AccountId =:accId];
        //Get Care prod 
        //
        if(getAuthConsent.size()!=0)
            deleteRecords(getAuthConsent);
        if(getEnrollCardId.size()!=0)
            deleteRecords(getEnrollCardId);
        if(CareProgramEnrolleeProduct.size()!=0)
            deleteRecords(CareProgramEnrolleeProduct);
        
        Delete enrollee;
    }
    
    
    public static void deleteRecords(List<sobject> objToDel){
        for(sobject obj:objToDel)
            Delete obj;
    }
    
}