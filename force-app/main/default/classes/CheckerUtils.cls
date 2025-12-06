global with sharing class CheckerUtils {


    /*
     * Checks whether the list of objects exists or not.
     * objectNames - This contains the list of name of object to check.
     */
    global static boolean hasListOfObjects(String[] objectNames)
        {
              try {
                  Schema.DescribeSObjectResult[] descResult = Schema.describeSObjects(objectNames);
                  return (objectNames.size() == descResult.size());
              }
              catch(Exception e){
                  return false;
              }
              
                
        }
        
        
}