/**
 * Contact REST Resource
 * RESTful API for Contact CRUD operations
 * 
 * Endpoints:
 * GET    /services/apexrest/contacts           - List contacts (with query filters)
 * GET    /services/apexrest/contacts/{id}      - Get contact by ID
 * POST   /services/apexrest/contacts           - Create contact(s)
 * PUT    /services/apexrest/contacts/{id}       - Update contact by ID
 * DELETE /services/apexrest/contacts/{id}      - Delete contact by ID
 */
@RestResource(urlMapping='/contacts/*')
global class ContactResource {
    
    /**
     * GET /contacts - List all contacts with optional filters
     * Query parameters: ?email=john@example.com&accountId=001xx000003DGbYAAW&search=John&limit=10
     */
    @HttpGet
    global static void getContacts() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        
        try {
            // Check if ID is in path
            String id = RestResponseHelper.extractIdFromPath(req.requestURI);
            if (id != null) {
                // This is a GET by ID request
                getContactById(id);
                return;
            }
            
            // Parse query parameters from URL
            Map<String, String> params = RestResponseHelper.parseQueryParameters(req.requestURI);
            
            // Also check request body (Agentforce may send parameters in body)
            if (req.requestBody != null && req.requestBody.size() > 0) {
                try {
                    String requestBody = req.requestBody.toString();
                    Map<String, Object> bodyParams = (Map<String, Object>) JSON.deserializeUntyped(requestBody);
                    for (String key : bodyParams.keySet()) {
                        if (!params.containsKey(key)) {
                            params.put(key, String.valueOf(bodyParams.get(key)));
                        }
                    }
                } catch (Exception e) {
                    // If body parsing fails, continue with query params only
                    System.debug(LoggingLevel.WARN, 'Failed to parse request body: ' + e.getMessage());
                }
            }
            
            // Build request for UniversalCrmRecordAction
            UniversalCrmRecordAction.Request actionReq = new UniversalCrmRecordAction.Request();
            actionReq.objectApiName = 'Contact';
            actionReq.operation = 'find';
            
            // Handle search parameter
            if (params.containsKey('search')) {
                actionReq.searchTerm = params.get('search');
            }
            
            // Handle limit parameter
            if (params.containsKey('limit')) {
                try {
                    actionReq.searchLimit = Integer.valueOf(params.get('limit'));
                } catch (Exception e) {
                    // Invalid limit, use default
                }
            }
            
            // Convert query parameters to filters (exclude special params)
            Set<String> specialParams = new Set<String>{ 'search', 'limit' };
            List<UniversalCrmRecordAction.Filter> filters = new List<UniversalCrmRecordAction.Filter>();
            for (String key : params.keySet()) {
                if (!specialParams.contains(key.toLowerCase())) {
                    UniversalCrmRecordAction.Filter filter = new UniversalCrmRecordAction.Filter();
                    filter.fieldApiName = key;
                    filter.value = params.get(key);
                    filters.add(filter);
                }
            }
            
            if (!filters.isEmpty()) {
                actionReq.filtersJson = JSON.serialize(filters);
            }
            
            // Process request
            UniversalCrmRecordAction.Response actionRes = UniversalCrmRecordAction.processRequest(actionReq);
            
            // Convert to standard response
            RestResponseHelper.StandardResponse response = RestResponseHelper.convertFromUniversalResponse(actionRes);
            RestResponseHelper.sendResponse(res, response);
            
        } catch (Exception e) {
            RestResponseHelper.StandardResponse errorResponse = RestResponseHelper.error(
                'Error retrieving contacts: ' + e.getMessage(), 500
            );
            RestResponseHelper.sendResponse(res, errorResponse);
        }
    }
    
    /**
     * GET /contacts/{id} - Get contact by ID
     */
    private static void getContactById(String contactId) {
        RestResponse res = RestContext.response;
        
        try {
            UniversalCrmRecordAction.Request actionReq = new UniversalCrmRecordAction.Request();
            actionReq.objectApiName = 'Contact';
            actionReq.operation = 'read';
            actionReq.recordId = contactId;
            
            UniversalCrmRecordAction.Response actionRes = UniversalCrmRecordAction.processRequest(actionReq);
            
            RestResponseHelper.StandardResponse response = RestResponseHelper.convertFromUniversalResponse(actionRes);
            if (!actionRes.success) {
                response = RestResponseHelper.error(response.message, 404);
            }
            RestResponseHelper.sendResponse(res, response);
            
        } catch (Exception e) {
            RestResponseHelper.StandardResponse errorResponse = RestResponseHelper.error(
                'Error retrieving contact: ' + e.getMessage(), 500
            );
            RestResponseHelper.sendResponse(res, errorResponse);
        }
    }
    
    /**
     * POST /contacts - Create contact(s)
     * Body: Single object {"LastName": "Smith", "Email": "john@example.com", "accountName": "Acme Corp"}
     *       or array for bulk create
     * Note: Supports "accountName" field to resolve Account by name
     */
    @HttpPost
    global static void createContact() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        
        try {
            String requestBody = req.requestBody.toString();
            if (String.isBlank(requestBody)) {
                RestResponseHelper.StandardResponse errorResponse = RestResponseHelper.error(
                    'Request body is required', 400
                );
                RestResponseHelper.sendResponse(res, errorResponse);
                return;
            }
            
            // Parse request body
            Object parsed = JSON.deserializeUntyped(requestBody);
            
            UniversalCrmRecordAction.Request actionReq = new UniversalCrmRecordAction.Request();
            actionReq.objectApiName = 'Contact';
            
            // Check if it's an array (bulk) or single object
            if (parsed instanceof List<Object>) {
                actionReq.operation = 'bulkCreate';
                actionReq.bulkRecordsJson = requestBody;
            } else {
                actionReq.operation = 'create';
                Map<String, Object> contactData = (Map<String, Object>) parsed;
                
                // Extract accountName if present (for related record resolution)
                if (contactData.containsKey('accountName')) {
                    actionReq.accountName = String.valueOf(contactData.get('accountName'));
                    contactData.remove('accountName');
                }
                
                // Convert object to fieldDataJson format
                List<Map<String, String>> fieldDataList = new List<Map<String, String>>();
                for (String key : contactData.keySet()) {
                    fieldDataList.add(new Map<String, String>{
                        'fieldApiName' => key,
                        'value' => String.valueOf(contactData.get(key))
                    });
                }
                actionReq.fieldDataJson = JSON.serialize(fieldDataList);
            }
            
            UniversalCrmRecordAction.Response actionRes = UniversalCrmRecordAction.processRequest(actionReq);
            
            RestResponseHelper.StandardResponse response = RestResponseHelper.convertFromUniversalResponse(actionRes);
            RestResponseHelper.sendResponse(res, response);
            
        } catch (Exception e) {
            RestResponseHelper.StandardResponse errorResponse = RestResponseHelper.error(
                'Error creating contact: ' + e.getMessage(), 400
            );
            RestResponseHelper.sendResponse(res, errorResponse);
        }
    }
    
    /**
     * PUT /contacts/{id} - Update contact by ID
     */
    @HttpPut
    global static void updateContact() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        
        try {
            String id = RestResponseHelper.extractIdFromPath(req.requestURI);
            if (String.isBlank(id)) {
                RestResponseHelper.StandardResponse errorResponse = RestResponseHelper.error(
                    'Contact ID is required in the URL path', 400
                );
                RestResponseHelper.sendResponse(res, errorResponse);
                return;
            }
            
            String requestBody = req.requestBody.toString();
            
            UniversalCrmRecordAction.Request actionReq = new UniversalCrmRecordAction.Request();
            actionReq.objectApiName = 'Contact';
            actionReq.operation = 'update';
            actionReq.recordId = id;
            
            if (String.isNotBlank(requestBody)) {
                Map<String, Object> contactData = (Map<String, Object>) JSON.deserializeUntyped(requestBody);
                
                // Extract accountName if present
                if (contactData.containsKey('accountName')) {
                    actionReq.accountName = String.valueOf(contactData.get('accountName'));
                    contactData.remove('accountName');
                }
                
                // Convert object to fieldDataJson format
                List<Map<String, String>> fieldDataList = new List<Map<String, String>>();
                for (String key : contactData.keySet()) {
                    fieldDataList.add(new Map<String, String>{
                        'fieldApiName' => key,
                        'value' => String.valueOf(contactData.get(key))
                    });
                }
                actionReq.fieldDataJson = JSON.serialize(fieldDataList);
            }
            
            UniversalCrmRecordAction.Response actionRes = UniversalCrmRecordAction.processRequest(actionReq);
            
            RestResponseHelper.StandardResponse response = RestResponseHelper.convertFromUniversalResponse(actionRes);
            RestResponseHelper.sendResponse(res, response);
            
        } catch (Exception e) {
            RestResponseHelper.StandardResponse errorResponse = RestResponseHelper.error(
                'Error updating contact: ' + e.getMessage(), 400
            );
            RestResponseHelper.sendResponse(res, errorResponse);
        }
    }
    
    /**
     * DELETE /contacts/{id} - Delete contact by ID
     */
    @HttpDelete
    global static void deleteContact() {
        RestResponse res = RestContext.response;
        
        try {
            String id = RestResponseHelper.extractIdFromPath(RestContext.request.requestURI);
            if (String.isBlank(id)) {
                RestResponseHelper.StandardResponse errorResponse = RestResponseHelper.error(
                    'Contact ID is required in the URL path', 400
                );
                RestResponseHelper.sendResponse(res, errorResponse);
                return;
            }
            
            UniversalCrmRecordAction.Request actionReq = new UniversalCrmRecordAction.Request();
            actionReq.objectApiName = 'Contact';
            actionReq.operation = 'delete';
            actionReq.recordId = id;
            
            UniversalCrmRecordAction.Response actionRes = UniversalCrmRecordAction.processRequest(actionReq);
            
            RestResponseHelper.StandardResponse response = RestResponseHelper.convertFromUniversalResponse(actionRes);
            if (!actionRes.success) {
                response = RestResponseHelper.error(response.message, 404);
            }
            RestResponseHelper.sendResponse(res, response);
            
        } catch (Exception e) {
            RestResponseHelper.StandardResponse errorResponse = RestResponseHelper.error(
                'Error deleting contact: ' + e.getMessage(), 500
            );
            RestResponseHelper.sendResponse(res, errorResponse);
        }
    }
}

