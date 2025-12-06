/**
 * Universal CRM Record Action REST API
 * REST endpoint for AI agents to perform CRUD operations on Account, Contact, and Case records.
 * 
 * This class provides a REST API alternative to the Invocable Action, designed specifically
 * for AI agent integrations that prefer standard HTTP/REST patterns.
 * 
 * Endpoint: /services/apexrest/UniversalCrmRecordAction
 * Method: POST
 * 
 * Request Body (JSON):
 * {
 *   "objectApiName": "Account",
 *   "operation": "find",
 *   "filters": [{"fieldApiName": "Name", "value": "Omega Financial"}],
 *   "fieldData": {"Name": "Acme Corp"},
 *   "recordId": "001...",
 *   "searchTerm": "...",
 *   "searchLimit": 5,
 *   "accountName": "...",
 *   "contactNameOrEmail": "...",
 *   "bulkRecordsJson": "[{...}]",
 *   "debugEmail": "user@example.com"
 * }
 * 
 * Response (JSON):
 * {
 *   "success": true,
 *   "operation": "find",
 *   "objectApiName": "Account",
 *   "records": [...],
 *   "totalMatches": 1,
 *   "message": "...",
 *   "errorDetails": null
 * }
 */
@RestResource(urlMapping='/UniversalCrmRecordAction')
global class UniversalCrmRecordActionRest {
    
    /**
     * Handle POST requests - all operations use POST for simplicity
     */
    @HttpPost
    global static void handlePost() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        
        // Set default response headers
        if (res != null) {
            res.addHeader('Content-Type', 'application/json');
        }
        
        try {
            // Parse request body
            String requestBody = req.requestBody.toString();
            System.debug(LoggingLevel.INFO, 'UniversalCrmRecordActionRest: Received request body: ' + requestBody);
            
            if (String.isBlank(requestBody)) {
                sendErrorResponse(400, 'Request body is required', null);
                return;
            }
            
            // Parse JSON into a map first to handle filters/fieldData conversion
            Map<String, Object> requestMap;
            try {
                requestMap = (Map<String, Object>) JSON.deserializeUntyped(requestBody);
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'UniversalCrmRecordActionRest: Failed to parse JSON: ' + e.getMessage());
                sendErrorResponse(400, 'Invalid JSON format: ' + e.getMessage(), e.getStackTraceString());
                return;
            }
            
            // Validate required fields
            if (!requestMap.containsKey('objectApiName') || !requestMap.containsKey('operation')) {
                sendErrorResponse(400, 'objectApiName and operation are required fields', null);
                return;
            }
            
            // Convert filters to filtersJson if present (for better compatibility)
            if (requestMap.containsKey('filters') && requestMap.get('filters') != null) {
                Object filtersObj = requestMap.get('filters');
                requestMap.put('filtersJson', JSON.serialize(filtersObj));
                // Remove filters to avoid deserialization issues
                requestMap.remove('filters');
            }
            
            // Convert fieldData to fieldDataJson if present (for better compatibility)
            if (requestMap.containsKey('fieldData') && requestMap.get('fieldData') != null) {
                Object fieldDataObj = requestMap.get('fieldData');
                requestMap.put('fieldDataJson', JSON.serialize(fieldDataObj));
                // Remove fieldData to avoid deserialization issues
                requestMap.remove('fieldData');
            }
            
            // Now deserialize into Request object
            UniversalCrmRecordAction.Request requestObj;
            try {
                String modifiedRequestBody = JSON.serialize(requestMap);
                requestObj = (UniversalCrmRecordAction.Request) JSON.deserialize(modifiedRequestBody, UniversalCrmRecordAction.Request.class);
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'UniversalCrmRecordActionRest: Failed to deserialize request: ' + e.getMessage());
                sendErrorResponse(400, 'Invalid request format: ' + e.getMessage(), e.getStackTraceString());
                return;
            }
            
            // Process the request using existing logic
            UniversalCrmRecordAction.Response responseObj = UniversalCrmRecordAction.processRequest(requestObj);
            
            // Set HTTP status code based on success
            Integer statusCode = responseObj.success ? 200 : 400;
            
            // Return JSON response
            if (res != null) {
                res.statusCode = statusCode;
                res.responseBody = Blob.valueOf(JSON.serialize(responseObj));
            }
            
            System.debug(LoggingLevel.INFO, 'UniversalCrmRecordActionRest: Returning response - Success: ' + responseObj.success + ', Status: ' + statusCode);
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'UniversalCrmRecordActionRest: Unexpected error: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'UniversalCrmRecordActionRest: Stack trace: ' + e.getStackTraceString());
            sendErrorResponse(500, 'Internal server error: ' + e.getMessage(), e.getStackTraceString());
        }
    }
    
    /**
     * Send error response with appropriate HTTP status code
     */
    private static void sendErrorResponse(Integer statusCode, String message, String errorDetails) {
        RestResponse res = RestContext.response;
        
        if (res != null) {
            res.statusCode = statusCode;
            
            // Create error response object
            UniversalCrmRecordAction.Response errorResponse = new UniversalCrmRecordAction.Response();
            errorResponse.success = false;
            errorResponse.message = message;
            errorResponse.errorDetails = errorDetails;
            errorResponse.records = new List<SObject>();
            errorResponse.totalMatches = 0;
            
            res.responseBody = Blob.valueOf(JSON.serialize(errorResponse));
        }
    }
}

