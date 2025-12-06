/**
 * This custom Apex class retrieves the field audit trail based on the object and the case id.  Pass the values from an Omniscript Remote Action step using the Extra Payload of the Remote Options.
 * Extra Payload example
 *   objectname   CareDiagnoses
 *
 * @author Jack Reilly
 *
 * @version 1.0
 *
 * History
 * =======
 * 1.0 - Dec 6, 2021 - Initial Version
 */

Global without sharing class jjr_getCareRequestItemsFAT implements Callable {

    public Object call(String action, Map<String, Object> args) {

        Map<String, Object> input = (Map<String, Object>)args.get('input');
        Map<String, Object> output = (Map<String, Object>)args.get('output');
        Map<String, Object> options = (Map<String, Object>)args.get('options');

        return invokeMethod(action, input, output, options);
    }



public Boolean invokeMethod(String methodName, Map < String, Object > input, Map < String, Object > outMap, Map < String, Object > options) {
        if (methodName.equals('getFieldAuditTrailForCareRequestItems')) {
            getFieldAuditTrailForCareRequestItems(input, outMap, options);
        }
        return true;
    }
public void getFieldAuditTrailForCareRequestItems(Map<String,Object> inputMap, Map<String,Object> outMap, Map<String,Object> options){
       Id caseId = (Id) inputMap.get('caseId');

       List<CareRequestItem> carerequestitems = [SELECT Id FROM CareRequestItem WHERE CareRequestCaseId = :caseId];
       List<Id> carerequestitemids = new List<Id>();
       for (CareRequestItem cri : carerequestitems){
          carerequestitemids.add(cri.Id);
       }
       List<FeedItem> feeds = [SELECT Id, body, Type,CreatedById, CreatedBy.FirstName, CreatedBy.LastName, CreatedDate, ParentId, Parent.Name,  (SELECT Id, FieldName, NewValue, OldValue FROM FeedTrackedChanges)                       
                                  FROM feeditem WHERE ParentId IN :carerequestitemids];

        outMap.put('results',feeds);
    }
}