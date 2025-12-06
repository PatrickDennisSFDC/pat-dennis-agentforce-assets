/**
 * Case REST Resource
 * RESTful API for Case CRUD operations
 * 
 * Endpoints:
 * GET    /services/apexrest/cases              - List cases (with query filters)
 * GET    /services/apexrest/cases/{id}          - Get case by ID
 * POST   /services/apexrest/cases               - Create case(s)
 * PUT    /services/apexrest/cases/{id}          - Update case by ID
 * DELETE /services/apexrest/cases/{id}           - Delete case by ID
 */
@RestResource(urlMapping='/cases/*')
global class CaseResource {
    
    /**
     * GET /cases - List all cases with optional filters
     * Query parameters: ?status=Open&accountId=001xx000003DGbYAAW&search=Support&limit=10
     */
    @HttpGet
    global static void getCases() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        
        try {
            // Check if ID is in path
            String id = RestResponseHelper.extractIdFromPath(req.requestURI);
            if (id != null) {
                // This is a GET by ID request
                getCaseById(id);
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
            actionReq.objectApiName = 'Case';
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
                'Error retrieving cases: ' + e.getMessage(), 500
            );
            RestResponseHelper.sendResponse(res, errorResponse);
        }
    }
    
    /**
     * GET /cases/{id} - Get case by ID
     */
    private static void getCaseById(String caseId) {
        RestResponse res = RestContext.response;
        
        try {
            UniversalCrmRecordAction.Request actionReq = new UniversalCrmRecordAction.Request();
            actionReq.objectApiName = 'Case';
            actionReq.operation = 'read';
            actionReq.recordId = caseId;
            
            UniversalCrmRecordAction.Response actionRes = UniversalCrmRecordAction.processRequest(actionReq);
            
            RestResponseHelper.StandardResponse response = RestResponseHelper.convertFromUniversalResponse(actionRes);
            if (!actionRes.success) {
                response = RestResponseHelper.error(response.message, 404);
            }
            RestResponseHelper.sendResponse(res, response);
            
        } catch (Exception e) {
            RestResponseHelper.StandardResponse errorResponse = RestResponseHelper.error(
                'Error retrieving case: ' + e.getMessage(), 500
            );
            RestResponseHelper.sendResponse(res, errorResponse);
        }
    }
    
    /**
     * POST /cases - Create case(s)
     * Body: Single object {"Subject": "Support Request", "accountName": "Acme Corp", "contactNameOrEmail": "john@example.com"}
     *       or array for bulk create
     * Note: Supports "accountName" and "contactNameOrEmail" fields to resolve related records by name
     */
    @HttpPost
    global static void createCase() {
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
            actionReq.objectApiName = 'Case';
            
            // Check if it's an array (bulk) or single object
            if (parsed instanceof List<Object>) {
                actionReq.operation = 'bulkCreate';
                actionReq.bulkRecordsJson = requestBody;
            } else {
                actionReq.operation = 'create';
                Map<String, Object> caseData = (Map<String, Object>) parsed;
                
                // Extract accountName and contactNameOrEmail if present (for related record resolution)
                if (caseData.containsKey('accountName')) {
                    actionReq.accountName = String.valueOf(caseData.get('accountName'));
                    caseData.remove('accountName');
                }
                if (caseData.containsKey('contactNameOrEmail')) {
                    actionReq.contactNameOrEmail = String.valueOf(caseData.get('contactNameOrEmail'));
                    caseData.remove('contactNameOrEmail');
                }
                
                // Convert object to fieldDataJson format
                List<Map<String, String>> fieldDataList = new List<Map<String, String>>();
                for (String key : caseData.keySet()) {
                    fieldDataList.add(new Map<String, String>{
                        'fieldApiName' => key,
                        'value' => String.valueOf(caseData.get(key))
                    });
                }
                actionReq.fieldDataJson = JSON.serialize(fieldDataList);
            }
            
            UniversalCrmRecordAction.Response actionRes = UniversalCrmRecordAction.processRequest(actionReq);
            
            RestResponseHelper.StandardResponse response = RestResponseHelper.convertFromUniversalResponse(actionRes);
            RestResponseHelper.sendResponse(res, response);
            
        } catch (Exception e) {
            RestResponseHelper.StandardResponse errorResponse = RestResponseHelper.error(
                'Error creating case: ' + e.getMessage(), 400
            );
            RestResponseHelper.sendResponse(res, errorResponse);
        }
    }
    
    /**
     * PUT /cases/{id} - Update case by ID
     */
    @HttpPut
    global static void updateCase() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        
        try {
            String id = RestResponseHelper.extractIdFromPath(req.requestURI);
            if (String.isBlank(id)) {
                RestResponseHelper.StandardResponse errorResponse = RestResponseHelper.error(
                    'Case ID is required in the URL path', 400
                );
                RestResponseHelper.sendResponse(res, errorResponse);
                return;
            }
            
            String requestBody = req.requestBody.toString();
            
            UniversalCrmRecordAction.Request actionReq = new UniversalCrmRecordAction.Request();
            actionReq.objectApiName = 'Case';
            actionReq.operation = 'update';
            actionReq.recordId = id;
            
            if (String.isNotBlank(requestBody)) {
                Map<String, Object> caseData = (Map<String, Object>) JSON.deserializeUntyped(requestBody);
                
                // Extract accountName and contactNameOrEmail if present
                if (caseData.containsKey('accountName')) {
                    actionReq.accountName = String.valueOf(caseData.get('accountName'));
                    caseData.remove('accountName');
                }
                if (caseData.containsKey('contactNameOrEmail')) {
                    actionReq.contactNameOrEmail = String.valueOf(caseData.get('contactNameOrEmail'));
                    caseData.remove('contactNameOrEmail');
                }
                
                // Convert object to fieldDataJson format
                List<Map<String, String>> fieldDataList = new List<Map<String, String>>();
                for (String key : caseData.keySet()) {
                    fieldDataList.add(new Map<String, String>{
                        'fieldApiName' => key,
                        'value' => String.valueOf(caseData.get(key))
                    });
                }
                actionReq.fieldDataJson = JSON.serialize(fieldDataList);
            }
            
            UniversalCrmRecordAction.Response actionRes = UniversalCrmRecordAction.processRequest(actionReq);
            
            RestResponseHelper.StandardResponse response = RestResponseHelper.convertFromUniversalResponse(actionRes);
            RestResponseHelper.sendResponse(res, response);
            
        } catch (Exception e) {
            RestResponseHelper.StandardResponse errorResponse = RestResponseHelper.error(
                'Error updating case: ' + e.getMessage(), 400
            );
            RestResponseHelper.sendResponse(res, errorResponse);
        }
    }
    
    /**
     * DELETE /cases/{id} - Delete case by ID
     */
    @HttpDelete
    global static void deleteCase() {
        RestResponse res = RestContext.response;
        
        try {
            String id = RestResponseHelper.extractIdFromPath(RestContext.request.requestURI);
            if (String.isBlank(id)) {
                RestResponseHelper.StandardResponse errorResponse = RestResponseHelper.error(
                    'Case ID is required in the URL path', 400
                );
                RestResponseHelper.sendResponse(res, errorResponse);
                return;
            }
            
            UniversalCrmRecordAction.Request actionReq = new UniversalCrmRecordAction.Request();
            actionReq.objectApiName = 'Case';
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
                'Error deleting case: ' + e.getMessage(), 500
            );
            RestResponseHelper.sendResponse(res, errorResponse);
        }
    }
}

