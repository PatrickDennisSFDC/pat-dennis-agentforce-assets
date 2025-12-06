public class XDO_CreateOrderSummaryController {

    @future
    public static void createOrderSummary(Set<Id> orderIds){
        
        //Connect API Handles Order Summary Creations one at a time.
        for(Id oid: orderIds){
            ConnectApi.OrderSummaryInputRepresentation input = new ConnectApi.OrderSummaryInputRepresentation();
            input.OrderId = oid;
            ConnectApi.OrderSummaryOutputRepresentation output = ConnectApi.OrderSummaryCreation.createOrderSummary(input);
            
            System.debug(output);
        }
    }
}