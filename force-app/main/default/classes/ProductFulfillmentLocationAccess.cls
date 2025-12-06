public class ProductFulfillmentLocationAccess {
    
    static Set<String> accessLevels = new Set<String>{'read', 'edit'};
    
     /**
     * Gives access to users on all product fulfillment locations
     */
    public static void insertAccessToAllLocations(ProductFulfillmentLocation locationToInsert, String accessType) {
        List<ProductFulfillmentLocation> fulfillLocations = [select Id, ProductId, FulfillmentLocationId from ProductFulfillmentLocation];
        insertAccess(fulfillLocations, getAllResponsibleUsers(), accessType);
        insertProductItemAccess(new List<ProductFulfillmentLocation>{locationToInsert}, new List<Id>{locationToInsert.UserId}, accessType);
    }
    
    public static void insertAccess(List<ProductFulfillmentLocation> fulfillLocations, List<Id> users, String accessType) {
        if(fulfillLocations==null || fulfillLocations.isEmpty() || users==null || users.isEmpty()) {
            return;
        }
        List<ProductFulfillmentLocationShare> shareList = new List<ProductFulfillmentLocationShare>();
        for(Id user: users) {
            if(user==null)
                continue;
            for(ProductFulfillmentLocation location : fulfillLocations) {
                if(location==null || location.Id==null)
                    continue;
                ProductFulfillmentLocationShare share = New ProductFulfillmentLocationShare();
                share.ParentId=location.Id;
                share.UserOrGroupID = user;
                share.AccessLevel = accessType;
                shareList.add(share);
            }
        }
        try{
            Database.insert(shareList);
        } catch (Exception e) {
            System.debug(e);
        }
    }

    public static void updateAccess(ProductFulfillmentLocation oldLocation, ProductFulfillmentLocation updatedLocation, String access) {
         deleteAccess(oldLocation);
         insertAccessToAllLocations(updatedLocation, access);
    }
    
    public static void deleteAccess(List<Id> users) {
        List<ProductFulfillmentLocationShare> shareList = new List<ProductFulfillmentLocationShare>();
        for(Id userId : users) {
            if(isUserLinkedTofulfillLocation(userId)) 
                continue;
            List<ProductFulfillmentLocationShare> shares = [select Id from ProductFulfillmentLocationShare where UserOrGroupID = :userId and RowCause='Manual'];
            if(!shares.isEmpty()) {
                shareList.addAll(shares);
            }
        }
        delete shareList;
    }
    
    public static void deleteAccess(ProductFulfillmentLocation fulfillLocation) {
        deleteAccess(new List<Id>{fulfillLocation.UserId});
        deleteProductItemAccess(fulfillLocation);
    }
    
    public static Boolean isUserLinkedTofulfillLocation(Id userId) {
        List<ProductFulfillmentLocation> fulfillLocations = [select Id from ProductFulfillmentLocation where UserId = :userId];
        return !fulfillLocations.isEmpty();
    }
    
    public static void deleteProductItemAccess(ProductFulfillmentLocation fulfillLocation) {
       ProductItemAccess.deleteAccess(ProductItemAccess.getProductItems(fulfillLocation), new List<id>{fulfillLocation.UserId});
    }

    public static void insertProductItemAccess(List<ProductFulfillmentLocation> fulfillLocations, List<Id> users, String access) {
        List<ProductItem> productItems = new List<ProductItem>();
        for(ProductFulfillmentLocation location : fulfillLocations) {
            productItems.add(new ProductItem(Product2Id=location.ProductId, LocationId=location.FulfillmentLocationId));
        }
        ProductItemAccess.insertAccess(productItems, users, access);
    }
    
    public static List<Id> getAllResponsibleUsers() {
        List<Id> users = new List<Id>();
        List<ProductFulfillmentLocation> fulfillLocations = [select UserId from ProductFulfillmentLocation];
        for(ProductFulfillmentLocation location : fulfillLocations) {
            users.add(location.UserId);
        }
        return users;
    }
}