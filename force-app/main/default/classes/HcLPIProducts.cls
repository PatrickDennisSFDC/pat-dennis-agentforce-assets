public class HcLPIProducts {
    /*
    * Checks for Product availability in RegulatoryAuthorizationTypeProduct and returns true or false
    */
    @InvocableMethod(label='Is Product Available' description='Checks for Product availability in RegulatoryAuthorizationTypeProduct.')
    public static List<Boolean> isRegulatoryAuthorizationTypeProductAvailable(List<String> productIds) {
        List<Boolean> availablePermSets = new List<Boolean>();
        availablePermSets.add(isProductAvailable(productIds));
        return availablePermSets;
    }
    
    @TestVisible
    private static Boolean isProductAvailable(List<String> productIds) {
         Boolean isAvailable = false;
         try {
            if(productIds.size() > 0) {
                String sql = constructQuery(productIds);
                List<SObject> products = Database.query(sql);
                
                if(products != null && products.size() > 0) {
                    isAvailable = true;
                }
            }
         } catch(Exception e) {
            System.assert(true, 'Seems like the user does not have PSL');
            return null;
        }
        return isAvailable;
    }
   
    @TestVisible    
    private static String constructQuery(List<String> productIds) {
        String sql = 'select Id from RegAuthorizationTypeProduct where ProductId in :productIds and isDeleted = false';
        return sql;
    }
}