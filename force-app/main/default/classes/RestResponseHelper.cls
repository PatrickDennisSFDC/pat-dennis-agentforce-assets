/**
 * REST Response Helper
 * Shared utility class for consistent JSON responses and error handling across REST resources
 */
public class RestResponseHelper {
    
    /**
     * Standardized response wrapper
     */
    public class StandardResponse {
        public Boolean success;
        public Object data;
        public String error;
        public String message;
        public Map<String, Object> metadata;
        
        public StandardResponse() {
            this.success = true;
            this.data = null;
            this.error = null;
            this.message = null;
            this.metadata = new Map<String, Object>();
        }
    }
    
    /**
     * Missing parent error response
     */
    public class MissingParentError {
        public String missingParent;
        public List<String> requiredFields;
        public List<String> optionalFields;
        public String message;
    }
    
    /**
     * Create success response
     */
    public static StandardResponse success(Object data, String message) {
        StandardResponse response = new StandardResponse();
        response.success = true;
        response.data = data;
        response.message = message;
        return response;
    }
    
    /**
     * Create error response
     */
    public static StandardResponse error(String errorMessage, Integer statusCode) {
        StandardResponse response = new StandardResponse();
        response.success = false;
        response.error = errorMessage;
        response.message = errorMessage;
        if (statusCode != null) {
            response.metadata.put('statusCode', statusCode);
        }
        return response;
    }
    
    /**
     * Create missing parent error response
     */
    public static StandardResponse missingParentError(
        String parentType,
        List<String> requiredFields,
        List<String> optionalFields,
        String parentName
    ) {
        StandardResponse response = new StandardResponse();
        response.success = false;
        response.error = parentType + ' \'' + parentName + '\' not found.';
        
        MissingParentError missingParent = new MissingParentError();
        missingParent.missingParent = parentType;
        missingParent.requiredFields = requiredFields != null ? requiredFields : new List<String>();
        missingParent.optionalFields = optionalFields != null ? optionalFields : new List<String>();
        missingParent.message = 'To create it, I need: ' + 
            String.join(requiredFields != null ? requiredFields : new List<String>(), ', ') + 
            (optionalFields != null && !optionalFields.isEmpty() ? 
                '. Optional fields: ' + String.join(optionalFields, ', ') : '');
        
        response.data = missingParent;
        response.message = parentType + ' \'' + parentName + '\' not found. ' + missingParent.message;
        response.metadata.put('statusCode', 404);
        
        return response;
    }
    
    /**
     * Extract ID from URL path
     * Example: /services/apexrest/accounts/001xx000003DGbYAAW -> 001xx000003DGbYAAW
     */
    public static String extractIdFromPath(String requestUri) {
        if (String.isBlank(requestUri)) {
            return null;
        }
        
        // Remove query parameters if present
        String path = requestUri.split('\\?')[0];
        
        // Split by '/' and get the last segment
        List<String> segments = path.split('/');
        if (segments.isEmpty()) {
            return null;
        }
        
        String lastSegment = segments[segments.size() - 1];
        
        // Validate it looks like a Salesforce ID (15 or 18 characters, alphanumeric)
        if (lastSegment.length() == 15 || lastSegment.length() == 18) {
            return lastSegment;
        }
        
        return null;
    }
    
    /**
     * Parse query parameters from request
     */
    public static Map<String, String> parseQueryParameters(String requestUri) {
        Map<String, String> params = new Map<String, String>();
        
        if (String.isBlank(requestUri) || !requestUri.contains('?')) {
            return params;
        }
        
        String queryString = requestUri.split('\\?')[1];
        if (String.isBlank(queryString)) {
            return params;
        }
        
        // Handle potential fragment
        if (queryString.contains('#')) {
            queryString = queryString.split('#')[0];
        }
        
        List<String> pairs = queryString.split('&');
        for (String pair : pairs) {
            if (pair.contains('=')) {
                List<String> keyValue = pair.split('=', 2);
                if (keyValue.size() == 2) {
                    params.put(keyValue[0], keyValue[1]);
                }
            }
        }
        
        return params;
    }
    
    /**
     * Send JSON response with appropriate HTTP status code
     */
    public static void sendResponse(RestResponse restResponse, StandardResponse response) {
        if (restResponse == null) {
            return;
        }
        
        restResponse.addHeader('Content-Type', 'application/json');
        
        // Ensure data is never null before serialization
        if (response.data == null) {
            response.data = new List<SObject>();
        }
        
        Integer statusCode = 200;
        if (!response.success) {
            if (response.metadata.containsKey('statusCode')) {
                statusCode = (Integer) response.metadata.get('statusCode');
            } else {
                statusCode = 400;
            }
        }
        
        restResponse.statusCode = statusCode;
        
        try {
            String jsonResponse = JSON.serialize(response);
            System.debug(LoggingLevel.INFO, 'RestResponseHelper: Sending response: ' + jsonResponse);
            restResponse.responseBody = Blob.valueOf(jsonResponse);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'RestResponseHelper: Failed to serialize response: ' + e.getMessage());
            // Fallback to error response
            StandardResponse errorResponse = error('Failed to serialize response: ' + e.getMessage(), 500);
            restResponse.statusCode = 500;
            restResponse.responseBody = Blob.valueOf(JSON.serialize(errorResponse));
        }
    }
    
    /**
     * Convert UniversalCrmRecordAction.Response to StandardResponse
     */
    public static StandardResponse convertFromUniversalResponse(UniversalCrmRecordAction.Response universalRes) {
        StandardResponse response = new StandardResponse();
        
        if (universalRes == null) {
            response.success = false;
            response.error = 'No response received from UniversalCrmRecordAction';
            response.message = response.error;
            return response;
        }
        
        response.success = universalRes.success;
        response.message = universalRes.message;
        
        if (universalRes.success) {
            // Success case - include data
            if (universalRes.record != null) {
                response.data = universalRes.record;
            } else if (universalRes.records != null) {
                // Always set records, even if empty list
                response.data = universalRes.records.isEmpty() ? new List<SObject>() : universalRes.records;
            } else if (universalRes.recordId != null) {
                response.data = new Map<String, Object>{ 'id' => universalRes.recordId };
            } else {
                // No data found but operation succeeded - ensure data is always set
                response.data = new List<SObject>();
            }
            
            // Ensure data is never null
            if (response.data == null) {
                response.data = new List<SObject>();
            }
            
            // Add metadata
            if (universalRes.ambiguous != null && universalRes.ambiguous) {
                response.metadata.put('ambiguous', true);
                response.metadata.put('totalMatches', universalRes.totalMatches);
            }
            if (universalRes.totalMatches != null) {
                response.metadata.put('totalMatches', universalRes.totalMatches);
            }
        } else {
            // Error case
            response.error = universalRes.message;
            if (String.isNotBlank(universalRes.errorDetails)) {
                response.metadata.put('errorDetails', universalRes.errorDetails);
            }
        }
        
        return response;
    }
}

