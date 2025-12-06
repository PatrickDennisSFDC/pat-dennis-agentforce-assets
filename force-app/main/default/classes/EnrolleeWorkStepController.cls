public with sharing class EnrolleeWorkStepController {
    @AuraEnabled
    public static String getEnrolleeWorkSteps(String stepId) {
        String objName;
        List<CarePgmEnrolleeWkOrdStep> objects =  [SELECT Id, Name, ParentEnrolleeWorkOrder.Id FROM CarePgmEnrolleeWkOrdStep Where Id = :stepId];
        if (objects.size() > 0) {
            objName = objects[0].ParentEnrolleeWorkOrder.Id;
        }
        
        return getEnrolleeId(objName);
    }
    
    private static String getEnrolleeId(String workOrderId) {
        String objName;
        List<CarePgmEnrolleeWorkOrder> objects =  [SELECT Id, Name, CareProgramEnrollee.Id FROM CarePgmEnrolleeWorkOrder Where Id = :workOrderId];
        if (objects.size() > 0) {
            objName = objects[0].CareProgramEnrollee.Id;
        }
        return objName;       
    }
    
    @AuraEnabled
    public static void updateRecordField(Id recordId, String fieldName, Object fieldValue) {
        try {
            SObject record = Database.query('SELECT Id, ' + fieldName + ' FROM ' + recordId.getSObjectType().getDescribe().getName() + ' WHERE Id = :recordId');
            record.put(fieldName, fieldValue);
            update record;
        } catch (DMLException e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}