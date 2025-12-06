/**
 * Account REST Resource
 * RESTful API for Account CRUD operations
 * 
 * Endpoints:
 * GET    /services/apexrest/accounts           - List accounts (with query filters)
 * GET    /services/apexrest/accounts/{id}       - Get account by ID
 * POST   /services/apexrest/accounts           - Create account(s)
 * PUT    /services/apexrest/accounts/{id}       - Update account by ID
 * DELETE /services/apexrest/accounts/{id}       - Delete account by ID
 */
@RestResource(urlMapping='/accounts/*')
global class AccountResource {
    
    /**
     * GET /accounts - List all accounts with optional filters
     * Query parameters: ?industry=Technology&billingCity=San Francisco&search=Acme&limit=10
     */
    @HttpGet
    global static void getAccounts() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        
        try {
            // Debug logging
            System.debug(LoggingLevel.INFO, '=== AccountResource.getAccounts() START ===');
            System.debug(LoggingLevel.INFO, 'Request URI: ' + req.requestURI);
            System.debug(LoggingLevel.INFO, 'Request Body size: ' + (req.requestBody != null ? req.requestBody.size() : 0));
            if (req.requestBody != null && req.requestBody.size() > 0) {
                System.debug(LoggingLevel.INFO, 'Request Body: ' + req.requestBody.toString());
            }
            
            // Check if ID is in path
            String id = RestResponseHelper.extractIdFromPath(req.requestURI);
            if (id != null) {
                System.debug(LoggingLevel.INFO, 'ID found in path: ' + id);
                // This is a GET by ID request
                getAccountById(id);
                return;
            }
            
            // Parse query parameters from URL
            Map<String, String> params = RestResponseHelper.parseQueryParameters(req.requestURI);
            System.debug(LoggingLevel.INFO, 'Query parameters from URL: ' + params);
            
            // Also check request body (Agentforce may send parameters in body)
            if (req.requestBody != null && req.requestBody.size() > 0) {
                try {
                    String requestBody = req.requestBody.toString();
                    System.debug(LoggingLevel.INFO, 'Parsing request body: ' + requestBody);
                    Map<String, Object> bodyParams = (Map<String, Object>) JSON.deserializeUntyped(requestBody);
                    System.debug(LoggingLevel.INFO, 'Body parameters parsed: ' + bodyParams);
                    for (String key : bodyParams.keySet()) {
                        if (!params.containsKey(key)) {
                            params.put(key, String.valueOf(bodyParams.get(key)));
                        }
                    }
                    System.debug(LoggingLevel.INFO, 'Final merged parameters: ' + params);
                } catch (Exception e) {
                    // If body parsing fails, continue with query params only
                    System.debug(LoggingLevel.ERROR, 'Failed to parse request body: ' + e.getMessage());
                    System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
                }
            }
            
            // Build request for UniversalCrmRecordAction
            UniversalCrmRecordAction.Request actionReq = new UniversalCrmRecordAction.Request();
            actionReq.objectApiName = 'Account';
            actionReq.operation = 'find';
            
            // Handle search parameter
            if (params.containsKey('search')) {
                actionReq.searchTerm = params.get('search');
                System.debug(LoggingLevel.INFO, 'Search term set: ' + actionReq.searchTerm);
            } else {
                System.debug(LoggingLevel.INFO, 'No search parameter found');
            }
            
            // Handle limit parameter
            if (params.containsKey('limit')) {
                try {
                    actionReq.searchLimit = Integer.valueOf(params.get('limit'));
                    System.debug(LoggingLevel.INFO, 'Search limit set: ' + actionReq.searchLimit);
                } catch (Exception e) {
                    // Invalid limit, use default
                    System.debug(LoggingLevel.WARN, 'Invalid limit value: ' + params.get('limit'));
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
                System.debug(LoggingLevel.INFO, 'Filters JSON: ' + actionReq.filtersJson);
            }
            
            System.debug(LoggingLevel.INFO, 'Calling UniversalCrmRecordAction.processRequest...');
            // Process request
            UniversalCrmRecordAction.Response actionRes = UniversalCrmRecordAction.processRequest(actionReq);
            System.debug(LoggingLevel.INFO, 'Response received - success: ' + actionRes.success);
            System.debug(LoggingLevel.INFO, 'Response message: ' + actionRes.message);
            System.debug(LoggingLevel.INFO, 'Response records count: ' + (actionRes.records != null ? actionRes.records.size() : 0));
            
            // Convert to standard response
            RestResponseHelper.StandardResponse response = RestResponseHelper.convertFromUniversalResponse(actionRes);
            System.debug(LoggingLevel.INFO, 'Standard response - success: ' + response.success);
            System.debug(LoggingLevel.INFO, 'Standard response data: ' + JSON.serialize(response.data));
            RestResponseHelper.sendResponse(res, response);
            System.debug(LoggingLevel.INFO, '=== AccountResource.getAccounts() END ===');
            
        } catch (Exception e) {
            RestResponseHelper.StandardResponse errorResponse = RestResponseHelper.error(
                'Error retrieving accounts: ' + e.getMessage(), 500
            );
            RestResponseHelper.sendResponse(res, errorResponse);
        }
    }
    
    /**
     * GET /accounts/{id} - Get account by ID
     */
    private static void getAccountById(String accountId) {
        RestResponse res = RestContext.response;
        
        try {
            UniversalCrmRecordAction.Request actionReq = new UniversalCrmRecordAction.Request();
            actionReq.objectApiName = 'Account';
            actionReq.operation = 'read';
            actionReq.recordId = accountId;
            
            UniversalCrmRecordAction.Response actionRes = UniversalCrmRecordAction.processRequest(actionReq);
            
            RestResponseHelper.StandardResponse response = RestResponseHelper.convertFromUniversalResponse(actionRes);
            if (!actionRes.success) {
                response = RestResponseHelper.error(response.message, 404);
            }
            RestResponseHelper.sendResponse(res, response);
            
        } catch (Exception e) {
            RestResponseHelper.StandardResponse errorResponse = RestResponseHelper.error(
                'Error retrieving account: ' + e.getMessage(), 500
            );
            RestResponseHelper.sendResponse(res, errorResponse);
        }
    }
    
    /**
     * POST /accounts - Create account(s)
     * Body: Single object {"Name": "Acme"} or array [{"Name": "Acme"}, {"Name": "Globex"}]
     */
    @HttpPost
    global static void createAccount() {
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
            actionReq.objectApiName = 'Account';
            
            // Check if it's an array (bulk) or single object
            if (parsed instanceof List<Object>) {
                actionReq.operation = 'bulkCreate';
                actionReq.bulkRecordsJson = requestBody;
            } else {
                actionReq.operation = 'create';
                // Convert object to fieldDataJson format
                Map<String, Object> accountData = (Map<String, Object>) parsed;
                List<Map<String, String>> fieldDataList = new List<Map<String, String>>();
                for (String key : accountData.keySet()) {
                    fieldDataList.add(new Map<String, String>{
                        'fieldApiName' => key,
                        'value' => String.valueOf(accountData.get(key))
                    });
                }
                actionReq.fieldDataJson = JSON.serialize(fieldDataList);
            }
            
            UniversalCrmRecordAction.Response actionRes = UniversalCrmRecordAction.processRequest(actionReq);
            
            RestResponseHelper.StandardResponse response = RestResponseHelper.convertFromUniversalResponse(actionRes);
            RestResponseHelper.sendResponse(res, response);
            
        } catch (Exception e) {
            RestResponseHelper.StandardResponse errorResponse = RestResponseHelper.error(
                'Error creating account: ' + e.getMessage(), 400
            );
            RestResponseHelper.sendResponse(res, errorResponse);
        }
    }
    
    /**
     * PUT /accounts/{id} - Update account by ID
     */
    @HttpPut
    global static void updateAccount() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        
        try {
            String id = RestResponseHelper.extractIdFromPath(req.requestURI);
            if (String.isBlank(id)) {
                RestResponseHelper.StandardResponse errorResponse = RestResponseHelper.error(
                    'Account ID is required in the URL path', 400
                );
                RestResponseHelper.sendResponse(res, errorResponse);
                return;
            }
            
            String requestBody = req.requestBody.toString();
            
            UniversalCrmRecordAction.Request actionReq = new UniversalCrmRecordAction.Request();
            actionReq.objectApiName = 'Account';
            actionReq.operation = 'update';
            actionReq.recordId = id;
            
            if (String.isNotBlank(requestBody)) {
                // Convert object to fieldDataJson format
                Map<String, Object> accountData = (Map<String, Object>) JSON.deserializeUntyped(requestBody);
                List<Map<String, String>> fieldDataList = new List<Map<String, String>>();
                for (String key : accountData.keySet()) {
                    fieldDataList.add(new Map<String, String>{
                        'fieldApiName' => key,
                        'value' => String.valueOf(accountData.get(key))
                    });
                }
                actionReq.fieldDataJson = JSON.serialize(fieldDataList);
            }
            // If no body, handleUpdate will return current record
            
            UniversalCrmRecordAction.Response actionRes = UniversalCrmRecordAction.processRequest(actionReq);
            
            RestResponseHelper.StandardResponse response = RestResponseHelper.convertFromUniversalResponse(actionRes);
            RestResponseHelper.sendResponse(res, response);
            
        } catch (Exception e) {
            RestResponseHelper.StandardResponse errorResponse = RestResponseHelper.error(
                'Error updating account: ' + e.getMessage(), 400
            );
            RestResponseHelper.sendResponse(res, errorResponse);
        }
    }
    
    /**
     * DELETE /accounts/{id} - Delete account by ID
     */
    @HttpDelete
    global static void deleteAccount() {
        RestResponse res = RestContext.response;
        
        try {
            String id = RestResponseHelper.extractIdFromPath(RestContext.request.requestURI);
            if (String.isBlank(id)) {
                RestResponseHelper.StandardResponse errorResponse = RestResponseHelper.error(
                    'Account ID is required in the URL path', 400
                );
                RestResponseHelper.sendResponse(res, errorResponse);
                return;
            }
            
            UniversalCrmRecordAction.Request actionReq = new UniversalCrmRecordAction.Request();
            actionReq.objectApiName = 'Account';
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
                'Error deleting account: ' + e.getMessage(), 500
            );
            RestResponseHelper.sendResponse(res, errorResponse);
        }
    }
}

