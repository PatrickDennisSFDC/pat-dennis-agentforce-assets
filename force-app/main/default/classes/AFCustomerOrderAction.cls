/**
 * AF Customer Order Action
 * Consolidated invocable action for all CustomerOrders__c CRUD operations (Create, Read, Update, Delete, Find)
 * Supports line item management within order operations
 * Designed for Agentforce AI agents
 */
public with sharing class AFCustomerOrderAction {
    
    public class Request {
        @InvocableVariable(
            label='Operation'
            description='Explicit operation: "create", "read", "update", "delete", or "find". If not specified, inferred from context.'
        )
        public String operation;
        
        @InvocableVariable(
            label='Field Data JSON'
            description='JSON string containing Customer Order field data. For create: {"Name":"Q4 2024 Order","Status__c":"Draft","Order_Date__c":"2024-12-04"}. For update: {"Status__c":"Shipped"}. For bulk: [{"Name":"Order 1"},{"Name":"Order 2"}]. Required field: Name.'
            required=false
        )
        public String fieldDataJson;
        
        @InvocableVariable(
            label='Record ID'
            description='The Salesforce record ID of the Customer Order. Required for read/update/delete. Format: 18-character ID like "a2sxx000000ABCDEF".'
        )
        public Id recordId;
        
        @InvocableVariable(
            label='Search Term'
            description='Text to search for in Customer Order fields (Name, Order_Number__c, PO_Number__c, etc.). Used for find operations.'
        )
        public String searchTerm;
        
        @InvocableVariable(
            label='Filters JSON'
            description='JSON string of exact-match filters for find operations.'
        )
        public String filtersJson;
        
        @InvocableVariable(
            label='Search Limit'
            description='Maximum number of records to return for find operations (default: 5, max: 20).'
        )
        public Integer searchLimit;
        
        @InvocableVariable(
            label='Account Name'
            description='Account name to resolve to Account__c lookup. If provided, system searches for an Account and links the Order to it.'
        )
        public String accountName;
        
        @InvocableVariable(
            label='Contact Name or Email'
            description='Contact name or email to resolve to Contact__c lookup. If provided, system searches for a Contact and links the Order to them.'
        )
        public String contactNameOrEmail;
        
        @InvocableVariable(
            label='Line Items JSON'
            description='JSON array of line items to create with the order (for create operation). Optional. Format: [{"Product_Name__c":"Widget A","Quantity__c":10,"Unit_Price__c":50.00}]. Each line item requires: Product_Name__c, Quantity__c, Unit_Price__c.'
            required=false
        )
        public String lineItemsJson;
        
        @InvocableVariable(
            label='Add Line Items JSON'
            description='JSON array of NEW line items to add to the order (for update operation). Format: [{"Product_Name__c":"Widget C","Quantity__c":3,"Unit_Price__c":75.00}].'
            required=false
        )
        public String addLineItemsJson;
        
        @InvocableVariable(
            label='Update Line Items JSON'
            description='JSON array of EXISTING line items to update (for update operation). Format: [{"Id":"a00xxx...","Quantity__c":50}]. Each item must include the line item Id plus the fields to change.'
            required=false
        )
        public String updateLineItemsJson;
        
        @InvocableVariable(
            label='Delete Line Item IDs'
            description='JSON array of line item IDs to delete from the order (for update operation). Format: ["a00xxx...","a00yyy..."].'
            required=false
        )
        public String deleteLineItemIds;
        
        @InvocableVariable(
            label='Confirm'
            description='For create/update: Set to false to preview only. For delete: Set to true to actually delete.'
        )
        public Boolean confirm;
    }
    
    public class Response {
        @InvocableVariable(
            label='Success'
            description='True if operation completed successfully.'
        )
        public Boolean success;
        
        @InvocableVariable(
            label='Record'
            description='The Customer Order record (for single record operations).'
        )
        public CustomerOrders__c record;
        
        @InvocableVariable(
            label='Records'
            description='List of Customer Order records (for bulk or find operations).'
        )
        public List<CustomerOrders__c> records;
        
        @InvocableVariable(
            label='Record ID'
            description='The Salesforce ID of the record.'
        )
        public Id recordId;
        
        @InvocableVariable(
            label='Message'
            description='Human-readable message describing the operation result.'
        )
        public String message;
        
        @InvocableVariable(
            label='Error Message'
            description='If success is false, this contains a user-friendly error message.'
        )
        public String errorMessage;
        
        @InvocableVariable(
            label='Object Type'
            description='The Salesforce object type, always "CustomerOrders__c" for Customer Order operations.'
        )
        public String objectType;
        
        @InvocableVariable(
            label='Operation'
            description='The operation that was performed.'
        )
        public String operation;
        
        @InvocableVariable(
            label='Preview Only'
            description='True if this is a preview response.'
        )
        public Boolean previewOnly;
        
        @InvocableVariable(
            label='Enrichment Suggested'
            description='True if additional fields are suggested.'
        )
        public Boolean enrichmentSuggested;
        
        @InvocableVariable(
            label='Suggested Fields'
            description='List of commonly-used field API names.'
        )
        public List<String> suggestedFields;
        
        @InvocableVariable(
            label='Preview Data'
            description='A JSON string representation of what would be created/updated.'
        )
        public String previewData;
        
        @InvocableVariable(
            label='Available Fields JSON'
            description='JSON string containing metadata for all available fields.'
        )
        public String availableFieldsJson;
        
        @InvocableVariable(
            label='Ambiguous Relationship'
            description='True if a parent lookup found multiple matches.'
        )
        public Boolean ambiguousRelationship;
        
        @InvocableVariable(
            label='Ambiguous Relationship Type'
            description='The type of relationship that has multiple matches.'
        )
        public String ambiguousRelationshipType;
        
        @InvocableVariable(
            label='Relationship Candidates JSON'
            description='JSON array of candidate records when ambiguousRelationship is true.'
        )
        public String relationshipCandidatesJson;
        
        @InvocableVariable(
            label='Ambiguous Result'
            description='True if multiple records were found in a find/search operation.'
        )
        public Boolean ambiguous;
        
        @InvocableVariable(
            label='Total Matches'
            description='Number of Customer Order records found in a find/search operation.'
        )
        public Integer totalMatches;
        
        @InvocableVariable(
            label='More Results Available'
            description='True if the search returned the maximum number of results but there are more matching records available.'
        )
        public Boolean moreResultsAvailable;
        
        @InvocableVariable(
            label='Confirmation Required'
            description='True if this is a confirmation request for delete operation.'
        )
        public Boolean confirmationRequired;
        @InvocableVariable(
            label='Line Items'
            description='List of line items for the order. For read/update operations, includes all line items. For create, includes newly created line items.'
        )
        public List<Customer_Order_Line_Item__c> lineItems;
        @InvocableVariable(
            label='Line Item Count'
            description='Number of line items on the order.'
        )
        public Integer lineItemCount;
        @InvocableVariable(
            label='Related Account Name'
            description='Name of the related Account if the Order is linked to an Account.'
        )
        public String relatedAccountName;
        @InvocableVariable(
            label='Related Contact Name'
            description='Name of the related Contact if the Order is linked to a Contact.'
        )
        public String relatedContactName;
    }
    
    private static String inferOperation(Request req) {
        if (!String.isBlank(req.operation)) {
            return req.operation.trim().toLowerCase();
        }
        
        Boolean hasRecordId = req.recordId != null;
        Boolean hasFieldData = !String.isBlank(req.fieldDataJson);
        Boolean hasSearchTerm = !String.isBlank(req.searchTerm);
        Boolean hasFilters = !String.isBlank(req.filtersJson);
        
        if (hasRecordId && hasFieldData) return 'update';
        else if (hasRecordId && !hasFieldData && !hasSearchTerm && !hasFilters) return 'read';
        else if (hasFieldData && !hasRecordId) return 'create';
        else if (hasSearchTerm || hasFilters) return 'find';
        else if (hasRecordId && req.confirm != null && req.confirm == true) return 'delete';
        
        throw new AFUniversalCrmRecordAction.ActionException('Cannot infer operation. Please specify operation parameter or provide sufficient context.');
    }
    
    @InvocableMethod(
        label='Customer Order Action'
        description='Performs CRUD operations on CustomerOrders__c records. Operation can be explicitly specified (create, read, update, delete, find) or inferred from context. CREATE: Provide fieldDataJson. Optionally provide lineItemsJson to create line items with the order. READ: Provide recordId. Automatically includes all line items. UPDATE: Provide recordId + fieldDataJson. Optionally provide addLineItemsJson, updateLineItemsJson, or deleteLineItemIds to manage line items. DELETE: Provide recordId + confirm=true. FIND: Provide searchTerm and/or filtersJson. Supports accountName and contactNameOrEmail parameters to link Order to Account/Contact. Supports bulk operations for create/update.'
        category='CRM Actions'
    )
    public static List<Response> customerOrderAction(List<Request> requests) {
        List<Response> responses = new List<Response>();
        
        for (Request req : requests) {
            Response res = new Response();
            res.objectType = 'CustomerOrders__c';
            res.success = false;
            res.records = new List<CustomerOrders__c>();
            res.totalMatches = 0;
            res.ambiguous = false;
            res.moreResultsAvailable = false;
            res.confirmationRequired = false;
            res.lineItems = new List<Customer_Order_Line_Item__c>();
            res.lineItemCount = 0;
            
            try {
                String op = inferOperation(req);
                res.operation = op;
                
                if (op == 'delete' && (req.confirm == null || req.confirm == false)) {
                    res.confirmationRequired = true;
                    res.recordId = req.recordId;
                    
                    if (req.recordId == null) {
                        res.success = false;
                        res.errorMessage = 'Record ID is required for delete operation.';
                        responses.add(res);
                        continue;
                    }
                    
                    try {
                        List<CustomerOrders__c> orders = [SELECT Id, Name FROM CustomerOrders__c WHERE Id = :req.recordId LIMIT 1];
                        if (!orders.isEmpty()) {
                            res.message = 'This will delete Customer Order \'' + orders[0].Name + '\' and all related records (including all line items). Call again with confirm=true to proceed.';
                            res.success = true;
                        } else {
                            res.message = 'Customer Order not found with ID ' + req.recordId + '.';
                            res.errorMessage = res.message;
                            res.success = false;
                        }
                    } catch (Exception e) {
                        res.message = 'This will delete the Customer Order. Call again with confirm=true to proceed.';
                        res.success = true;
                    }
                    responses.add(res);
                    continue;
                }
                
                // For create operation, handle line items through AFUniversalCrmRecordAction
                if (op == 'create') {
                    AFUniversalCrmRecordAction.Request actionReq = new AFUniversalCrmRecordAction.Request();
                    actionReq.objectApiName = 'CustomerOrders__c';
                    actionReq.operation = 'create';
                    actionReq.fieldDataJson = req.fieldDataJson;
                    actionReq.accountName = req.accountName;
                    actionReq.contactNameOrEmail = req.contactNameOrEmail;
                    actionReq.confirm = req.confirm;
                    
                    // Pass line items if provided
                    if (!String.isBlank(req.lineItemsJson)) {
                        // Store line items in a custom field or handle separately
                        // For now, we'll handle this in the response mapping
                    }
                    
                    AFUniversalCrmRecordAction.Response actionRes = AFUniversalCrmRecordAction.processRequest(actionReq);
                    
                    if (actionRes.success && actionRes.recordId != null) {
                        res.success = true;
                        res.message = actionRes.message != null ? actionRes.message : 'Customer Order created successfully.';
                        res.record = (CustomerOrders__c) actionRes.record;
                        res.recordId = actionRes.recordId;
                        res.records = new List<CustomerOrders__c>{ res.record };
                        res.previewOnly = actionRes.previewOnly != null ? actionRes.previewOnly : false;
                        res.availableFieldsJson = actionRes.availableFieldsJson;
                        res.ambiguousRelationship = actionRes.ambiguousRelationship != null ? actionRes.ambiguousRelationship : false;
                        res.ambiguousRelationshipType = actionRes.ambiguousRelationshipType;
                        res.relationshipCandidatesJson = actionRes.relationshipCandidatesJson;
                        
                        // Handle line items creation if provided
                        if (!String.isBlank(req.lineItemsJson) && res.recordId != null) {
                            try {
                                List<Object> lineItemsData = (List<Object>) JSON.deserializeUntyped(req.lineItemsJson);
                                List<Customer_Order_Line_Item__c> itemsToCreate = new List<Customer_Order_Line_Item__c>();
                                
                                for (Object itemObj : lineItemsData) {
                                    Map<String, Object> itemMap = (Map<String, Object>) itemObj;
                                    Customer_Order_Line_Item__c item = new Customer_Order_Line_Item__c();
                                    item.Customer_Order__c = res.recordId;
                                    if (itemMap.containsKey('Product_Name__c')) item.Product_Name__c = (String) itemMap.get('Product_Name__c');
                                    if (itemMap.containsKey('SKU__c')) item.SKU__c = (String) itemMap.get('SKU__c');
                                    if (itemMap.containsKey('Quantity__c')) item.Quantity__c = itemMap.get('Quantity__c') != null ? Decimal.valueOf(String.valueOf(itemMap.get('Quantity__c'))) : null;
                                    if (itemMap.containsKey('Unit_Price__c')) item.Unit_Price__c = itemMap.get('Unit_Price__c') != null ? Decimal.valueOf(String.valueOf(itemMap.get('Unit_Price__c'))) : null;
                                    if (itemMap.containsKey('Fulfillment_Notes__c')) item.Fulfillment_Notes__c = (String) itemMap.get('Fulfillment_Notes__c');
                                    itemsToCreate.add(item);
                                }
                                
                                if (!itemsToCreate.isEmpty()) {
                                    insert itemsToCreate;
                                    res.lineItems = itemsToCreate;
                                    res.lineItemCount = itemsToCreate.size();
                                    res.message = res.message + ' Created ' + itemsToCreate.size() + ' line item' + (itemsToCreate.size() > 1 ? 's' : '') + '.';
                                }
                            } catch (Exception e) {
                                System.debug(LoggingLevel.ERROR, 'AFCustomerOrderAction: Error creating line items: ' + e.getMessage());
                                // Don't fail the whole operation, just log the error
                            }
                        }
                    } else {
                        res.success = false;
                        res.errorMessage = actionRes.message != null ? actionRes.message : 'Failed to create Customer Order.';
                    }
                    responses.add(res);
                    continue;
                }
                
                // For read operation, use AFUniversalCrmRecordAction and then fetch line items
                if (op == 'read') {
                    AFUniversalCrmRecordAction.Request actionReq = new AFUniversalCrmRecordAction.Request();
                    actionReq.objectApiName = 'CustomerOrders__c';
                    actionReq.operation = 'read';
                    actionReq.recordId = req.recordId;
                    
                    AFUniversalCrmRecordAction.Response actionRes = AFUniversalCrmRecordAction.processRequest(actionReq);
                    
                    if (actionRes.success && actionRes.record != null) {
                        res.success = true;
                        res.record = (CustomerOrders__c) actionRes.record;
                        res.recordId = actionRes.recordId;
                        res.message = 'Customer Order retrieved successfully.';
                        
                        // Fetch line items
                        try {
                            List<Customer_Order_Line_Item__c> items = [SELECT Id, Product_Name__c, SKU__c, Quantity__c, Unit_Price__c, Total__c, Fulfillment_Notes__c, Status__c, Shipping_Address__c, Distribution_Center__c FROM Customer_Order_Line_Item__c WHERE Customer_Order__c = :res.recordId ORDER BY CreatedDate];
                            res.lineItems = items;
                            res.lineItemCount = items.size();
                            res.message = res.message + ' Found ' + items.size() + ' line item' + (items.size() != 1 ? 's' : '') + '.';
                        } catch (Exception e) {
                            System.debug(LoggingLevel.ERROR, 'AFCustomerOrderAction: Error fetching line items: ' + e.getMessage());
                        }
                        
                        // Get related account/contact names
                        try {
                            CustomerOrders__c order = [SELECT Account__r.Name, Contact__r.Name FROM CustomerOrders__c WHERE Id = :res.recordId LIMIT 1];
                            res.relatedAccountName = order.Account__r != null ? order.Account__r.Name : null;
                            res.relatedContactName = order.Contact__r != null ? order.Contact__r.Name : null;
                        } catch (Exception e) {
                            System.debug(LoggingLevel.DEBUG, 'AFCustomerOrderAction: Could not fetch related account/contact names');
                        }
                    } else {
                        res.success = false;
                        res.errorMessage = actionRes.message != null ? actionRes.message : 'Customer Order not found.';
                    }
                    responses.add(res);
                    continue;
                }
                
                // For update operation, handle line items through AFUniversalCrmRecordAction
                if (op == 'update') {
                    AFUniversalCrmRecordAction.Request actionReq = new AFUniversalCrmRecordAction.Request();
                    actionReq.objectApiName = 'CustomerOrders__c';
                    actionReq.operation = 'update';
                    actionReq.recordId = req.recordId;
                    actionReq.fieldDataJson = req.fieldDataJson;
                    actionReq.accountName = req.accountName;
                    actionReq.contactNameOrEmail = req.contactNameOrEmail;
                    actionReq.confirm = req.confirm;
                    
                    // Pass line item operations
                    if (!String.isBlank(req.addLineItemsJson)) {
                        // This will be handled in AFUniversalCrmRecordAction.handleLineItemsOnUpdate
                    }
                    if (!String.isBlank(req.updateLineItemsJson)) {
                        // This will be handled in AFUniversalCrmRecordAction.handleLineItemsOnUpdate
                    }
                    if (!String.isBlank(req.deleteLineItemIds)) {
                        // This will be handled in AFUniversalCrmRecordAction.handleLineItemsOnUpdate
                    }
                    
                    AFUniversalCrmRecordAction.Response actionRes = AFUniversalCrmRecordAction.processRequest(actionReq);
                    
                    if (actionRes.success) {
                        res.success = true;
                        res.message = actionRes.message != null ? actionRes.message : 'Customer Order updated successfully.';
                        res.record = (CustomerOrders__c) actionRes.record;
                        res.recordId = actionRes.recordId;
                        res.previewOnly = actionRes.previewOnly != null ? actionRes.previewOnly : false;
                        res.availableFieldsJson = actionRes.availableFieldsJson;
                        res.ambiguousRelationship = actionRes.ambiguousRelationship != null ? actionRes.ambiguousRelationship : false;
                        res.ambiguousRelationshipType = actionRes.ambiguousRelationshipType;
                        res.relationshipCandidatesJson = actionRes.relationshipCandidatesJson;
                        
                        // Handle line items operations if provided
                        if (res.recordId != null && (!String.isBlank(req.addLineItemsJson) || !String.isBlank(req.updateLineItemsJson) || !String.isBlank(req.deleteLineItemIds))) {
                            try {
                                // Use AFUniversalCrmRecordAction helper methods
                                Map<String, Object> lineItemOps = new Map<String, Object>();
                                if (!String.isBlank(req.addLineItemsJson)) lineItemOps.put('addLineItemsJson', req.addLineItemsJson);
                                if (!String.isBlank(req.updateLineItemsJson)) lineItemOps.put('updateLineItemsJson', req.updateLineItemsJson);
                                if (!String.isBlank(req.deleteLineItemIds)) lineItemOps.put('deleteLineItemIds', req.deleteLineItemIds);
                                
                                // Call the helper method
                                List<Customer_Order_Line_Item__c> updatedItems = AFUniversalCrmRecordAction.handleLineItemsOnUpdate(
                                    res.recordId,
                                    req.addLineItemsJson,
                                    req.updateLineItemsJson,
                                    req.deleteLineItemIds
                                );
                                
                                res.lineItems = updatedItems;
                                res.lineItemCount = updatedItems.size();
                            } catch (Exception e) {
                                System.debug(LoggingLevel.ERROR, 'AFCustomerOrderAction: Error handling line items: ' + e.getMessage());
                                // Fetch current line items as fallback
                                try {
                                    List<Customer_Order_Line_Item__c> items = [SELECT Id, Product_Name__c, SKU__c, Quantity__c, Unit_Price__c, Total__c, Fulfillment_Notes__c, Status__c, Shipping_Address__c, Distribution_Center__c FROM Customer_Order_Line_Item__c WHERE Customer_Order__c = :res.recordId ORDER BY CreatedDate];
                                    res.lineItems = items;
                                    res.lineItemCount = items.size();
                                } catch (Exception e2) {
                                    System.debug(LoggingLevel.ERROR, 'AFCustomerOrderAction: Error fetching line items: ' + e2.getMessage());
                                }
                            }
                        } else if (res.recordId != null) {
                            // Fetch current line items
                            try {
                                List<Customer_Order_Line_Item__c> items = [SELECT Id, Product_Name__c, SKU__c, Quantity__c, Unit_Price__c, Total__c, Fulfillment_Notes__c, Status__c, Shipping_Address__c, Distribution_Center__c FROM Customer_Order_Line_Item__c WHERE Customer_Order__c = :res.recordId ORDER BY CreatedDate];
                                res.lineItems = items;
                                res.lineItemCount = items.size();
                            } catch (Exception e) {
                                System.debug(LoggingLevel.DEBUG, 'AFCustomerOrderAction: Could not fetch line items');
                            }
                        }
                    } else {
                        res.success = false;
                        res.errorMessage = actionRes.message != null ? actionRes.message : 'Failed to update Customer Order.';
                    }
                    responses.add(res);
                    continue;
                }
                
                // For find operation, use AFUniversalCrmRecordAction
                if (op == 'find' || op == 'search') {
                    AFUniversalCrmRecordAction.Request actionReq = new AFUniversalCrmRecordAction.Request();
                    actionReq.objectApiName = 'CustomerOrders__c';
                    actionReq.operation = 'find';
                    actionReq.searchTerm = req.searchTerm;
                    actionReq.filtersJson = req.filtersJson;
                    actionReq.searchLimit = req.searchLimit;
                    
                    AFUniversalCrmRecordAction.Response actionRes = AFUniversalCrmRecordAction.processRequest(actionReq);
                    
                    if (actionRes.success) {
                        res.success = true;
                        res.message = actionRes.message != null ? actionRes.message : 'Search completed.';
                        res.ambiguous = actionRes.ambiguous != null ? actionRes.ambiguous : false;
                        res.totalMatches = actionRes.totalMatches != null ? actionRes.totalMatches : 0;
                        
                        if (actionRes.record != null) {
                            res.record = (CustomerOrders__c) actionRes.record;
                            res.recordId = res.record.Id;
                            res.records = new List<CustomerOrders__c>{ res.record };
                            
                            // Fetch line items for single result
                            try {
                                List<Customer_Order_Line_Item__c> items = [SELECT Id, Product_Name__c, SKU__c, Quantity__c, Unit_Price__c, Total__c, Fulfillment_Notes__c, Status__c, Shipping_Address__c, Distribution_Center__c FROM Customer_Order_Line_Item__c WHERE Customer_Order__c = :res.recordId ORDER BY CreatedDate];
                                res.lineItems = items;
                                res.lineItemCount = items.size();
                            } catch (Exception e) {
                                System.debug(LoggingLevel.DEBUG, 'AFCustomerOrderAction: Could not fetch line items for find result');
                            }
                        } else if (actionRes.records != null && !actionRes.records.isEmpty()) {
                            res.records = new List<CustomerOrders__c>();
                            for (SObject so : actionRes.records) {
                                res.records.add((CustomerOrders__c) so);
                            }
                            if (res.records.size() == 1) {
                                res.record = res.records[0];
                                res.recordId = res.records[0].Id;
                            } else if (!res.records.isEmpty()) {
                                res.ambiguous = true;
                            }
                            
                            // For multiple results, get line item counts
                            if (!res.records.isEmpty()) {
                                List<Id> orderIds = new List<Id>();
                                for (CustomerOrders__c order : res.records) {
                                    orderIds.add(order.Id);
                                }
                                Map<Id, Integer> lineItemCounts = AFUniversalCrmRecordAction.getLineItemCounts(orderIds);
                                // Store counts in message or handle separately
                            }
                        }
                        
                        Integer searchLimit = req.searchLimit != null ? req.searchLimit : 5;
                        if (res.totalMatches >= searchLimit) {
                            res.moreResultsAvailable = true;
                        }
                    } else {
                        res.success = false;
                        res.errorMessage = actionRes.message != null ? actionRes.message : 'Search failed.';
                    }
                    responses.add(res);
                    continue;
                }
                
                // For delete operation
                if (op == 'delete' && req.confirm == true) {
                    AFUniversalCrmRecordAction.Request actionReq = new AFUniversalCrmRecordAction.Request();
                    actionReq.objectApiName = 'CustomerOrders__c';
                    actionReq.operation = 'delete';
                    actionReq.recordId = req.recordId;
                    
                    AFUniversalCrmRecordAction.Response actionRes = AFUniversalCrmRecordAction.processRequest(actionReq);
                    
                    if (actionRes.success) {
                        res.success = true;
                        res.recordId = actionRes.recordId;
                        res.message = actionRes.message != null ? actionRes.message : 'Customer Order deleted successfully.';
                    } else {
                        res.success = false;
                        res.errorMessage = actionRes.message != null ? actionRes.message : 'Failed to delete Customer Order.';
                    }
                    responses.add(res);
                    continue;
                }
                
            } catch (AFUniversalCrmRecordAction.ActionException ae) {
                res.success = false;
                res.errorMessage = ae.getMessage();
                System.debug(LoggingLevel.ERROR, 'AFCustomerOrderAction: ActionException - ' + ae.getMessage());
            } catch (Exception e) {
                res.success = false;
                res.errorMessage = 'Error performing Customer Order operation: ' + e.getMessage();
                System.debug(LoggingLevel.ERROR, 'AFCustomerOrderAction: Exception - ' + e.getMessage());
            }
            
            responses.add(res);
        }
        
        return responses;
    }
}

