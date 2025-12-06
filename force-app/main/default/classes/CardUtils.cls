global with sharing class CardUtils {


    /*
     * Checks objects and records for the cards.
     * objectName : the name of object.
     * query: The SOQL query to check records for the object.
     */
    public static Map<string, object> checkObjectWithRecords(String objectName)
    {
            Boolean isObject = false;
            try {
                isObject = CheckerUtils.hasListOfObjects(new String[] {objectName});
                
                if(!isObject){
                    return new Map<String, Object>{
                           'success' => true,
                           'object' => objectName,
                           'isObjectExist' => isObject,
                           'isRecordExist' => false,
                           'messages' => 'Object does not exist.'
                    };
                }
                
                List<Object> Records = database.query('SELECT Id FROM '+ objectName + ' Order by CreatedDate DESC limit 2');
                Boolean isRecordExist = Records.isEmpty();
                
                String messageText = isRecordExist ? 'No records exist.' : 'Object exists and has at least one record';
                return new Map<String, Object>{
                           'success' => true,
                           'object' => objectName,
                           'isObjectExist' => isObject,
                           'isRecordExist' => !isRecordExist,
                           'messages' => messageText
                    };
            }
            catch(Exception e) {
                return new Map<String, Object>{
                           'success' => true,
                           'object' => objectName,
                           'isObjectExist' => isObject,
                           'isRecordExist' => false,
                           'messages' => 'No object and records exist for this object.'
                    };
            }                                                
    }

}