public class ProductItemAccess {
    
    public static void insertAccess(List<ProductItem> productItems, List<Id> users, String access) {

        if(productItems==null || productItems.isEmpty() || users==null || users.isEmpty()) {
            return;
        }
        productItems = getProductItemsWithId(productItems);
        List<ProductItemShare> shareList = new List<ProductItemShare>();
        for(Id user: users) {
            if(user==null)
                continue;
            for(ProductItem item : productItems) {
                ProductItemShare share = New ProductItemShare();
                share.ParentId=item.Id;
                share.UserOrGroupID = user;
                share.AccessLevel = access;
                shareList.add(share);
            }
        }
        try{
            Database.insert(shareList);
        } catch (Exception e) {
            System.debug(e);
        }
    }
    
    public static void deleteAccess(List<ProductItem> productItems, List<Id> users) {
        List<ProductItemShare> shareList = new List<ProductItemShare>();
        for(Id userId : users) {
            for(ProductItem productItem : productItems) {
                List<ProductItemShare> shares = [select Id from ProductItemShare where ParentId = :productItem.Id and UserOrGroupID = :userId and RowCause='Manual'];
                if(!shares.isEmpty()) {
                    shareList.addAll(shares);
                }
            } 
        }
        delete shareList;
    }
    
    public static List<ProductItem> getProductItems(ProductFulfillmentLocation fulfillLocation) {
        return [select Id from ProductItem where Product2Id=:fulfillLocation.ProductId and LocationId=:fulfillLocation.FulfillmentLocationId];
    }
    
    private static List<ProductItem> getProductItemsWithId(List<ProductItem> productItems) {
        List<ProductItem> productItemsWithId = new List<ProductItem>();
        for(ProductItem item : productItems) {
            if(item==null)
                continue;
            if(item.id==null) {
                List<ProductItem> itemList = [select Id from ProductItem where Product2Id=:item.Product2Id and LocationId=:item.locationId];
                productItemsWithId.addAll(itemList);
            }
        }
        return productItemsWithId;
    }
}