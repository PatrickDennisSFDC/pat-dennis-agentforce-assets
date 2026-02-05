/**
 * Agent Search Controller
 * Backend controller for the Agentic Search Experience Cloud component
 * Handles Knowledge article search and Agentforce agent messaging
 */
public without sharing class AgentSearchController {
    
    // Agent configuration
    private static final String AGENT_NAME = 'Hank@1.0.0';
    private static final String ACTION_TYPE = 'generateAiAgentResponse';
    
    /**
     * Search Knowledge articles and Files using SOSL
     * Returns combined results matching the search term
     */
    @AuraEnabled(cacheable=false)
    public static KnowledgeSearchResponse searchKnowledge(String searchTerm) {
        KnowledgeSearchResponse response = new KnowledgeSearchResponse();
        response.results = new List<SearchResult>();
        response.articles = new List<KnowledgeArticle>(); // For backward compatibility
        
        if (String.isBlank(searchTerm) || searchTerm.length() < 2) {
            response.success = true;
            response.message = 'Please enter at least 2 characters to search.';
            return response;
        }
        
        try {
            // Sanitize search term for SOSL
            String sanitizedTerm = String.escapeSingleQuotes(searchTerm.trim());
            
            // Add wildcards for partial matching
            String soslSearchTerm = sanitizedTerm + '*';
            
            // SOSL query for Knowledge articles AND Files
            String soslQuery = 'FIND \'' + soslSearchTerm + '\' IN ALL FIELDS ' +
                'RETURNING ' +
                'Knowledge__kav(' +
                    'Id, Title, Summary, UrlName, ArticleNumber, LastPublishedDate, ' +
                    'KnowledgeArticleId ' +
                    'WHERE PublishStatus = \'Online\' AND Language = \'en_US\' ' +
                    'ORDER BY LastPublishedDate DESC ' +
                    'LIMIT 15' +
                '), ' +
                'ContentVersion(' +
                    'Id, Title, Description, FileType, ContentSize, ContentDocumentId, ' +
                    'LastModifiedDate ' +
                    'WHERE IsLatest = true ' +
                    'ORDER BY LastModifiedDate DESC ' +
                    'LIMIT 10' +
                ')';
            
            System.debug('SOSL Query: ' + soslQuery);
            
            List<List<SObject>> searchResults = Search.query(soslQuery);
            
            // Process Knowledge articles (first result set)
            if (searchResults.size() > 0 && !searchResults[0].isEmpty()) {
                for (SObject record : searchResults[0]) {
                    Knowledge__kav article = (Knowledge__kav) record;
                    
                    // Add to unified results
                    SearchResult sr = new SearchResult();
                    sr.id = article.Id;
                    sr.resultType = 'article';
                    sr.title = article.Title;
                    sr.summary = article.Summary;
                    // Use Lightning Console URL for internal users
                    sr.url = '/lightning/r/Knowledge__kav/' + article.Id + '/view';
                    sr.icon = 'standard:knowledge';
                    sr.articleNumber = article.ArticleNumber;
                    sr.lastModified = article.LastPublishedDate;
                    response.results.add(sr);
                    
                    // Also add to legacy articles list
                    KnowledgeArticle ka = new KnowledgeArticle();
                    ka.id = article.Id;
                    ka.knowledgeArticleId = article.KnowledgeArticleId;
                    ka.title = article.Title;
                    ka.summary = article.Summary;
                    ka.urlName = article.UrlName;
                    ka.articleNumber = article.ArticleNumber;
                    ka.lastPublishedDate = article.LastPublishedDate;
                    ka.articleUrl = '/lightning/r/Knowledge__kav/' + article.Id + '/view';
                    response.articles.add(ka);
                }
            }
            
            // Process Files (second result set)
            if (searchResults.size() > 1 && !searchResults[1].isEmpty()) {
                for (SObject record : searchResults[1]) {
                    ContentVersion cv = (ContentVersion) record;
                    
                    SearchResult sr = new SearchResult();
                    sr.id = cv.Id;
                    sr.resultType = 'file';
                    sr.title = cv.Title;
                    sr.summary = cv.Description;
                    // Use Lightning Console URL for Files (ContentDocument)
                    sr.url = '/lightning/r/ContentDocument/' + cv.ContentDocumentId + '/view';
                    sr.icon = getFileIcon(cv.FileType);
                    sr.fileType = cv.FileType;
                    sr.fileSize = cv.ContentSize;
                    sr.lastModified = cv.LastModifiedDate;
                    response.results.add(sr);
                }
            }
            
            response.success = true;
            response.totalResults = response.results.size();
            response.message = response.totalResults > 0 
                ? 'Found ' + response.totalResults + ' result(s)' 
                : 'No results found for "' + searchTerm + '"';
            
        } catch (Exception e) {
            System.debug('Search error: ' + e.getMessage() + '\n' + e.getStackTraceString());
            response.success = false;
            response.message = 'Search error: ' + e.getMessage();
        }
        
        return response;
    }
    
    /**
     * Get appropriate SLDS icon for file type
     */
    private static String getFileIcon(String fileType) {
        if (String.isBlank(fileType)) {
            return 'doctype:unknown';
        }
        
        String ft = fileType.toLowerCase();
        
        if (ft == 'pdf') return 'doctype:pdf';
        if (ft == 'doc' || ft == 'docx' || ft == 'word_x') return 'doctype:word';
        if (ft == 'xls' || ft == 'xlsx' || ft == 'excel_x') return 'doctype:excel';
        if (ft == 'ppt' || ft == 'pptx' || ft == 'power_point_x') return 'doctype:ppt';
        if (ft == 'txt' || ft == 'text') return 'doctype:txt';
        if (ft == 'csv') return 'doctype:csv';
        if (ft == 'xml') return 'doctype:xml';
        if (ft == 'html') return 'doctype:html';
        if (ft == 'zip' || ft == 'rar' || ft == 'gzip') return 'doctype:zip';
        if (ft == 'png' || ft == 'jpg' || ft == 'jpeg' || ft == 'gif' || ft == 'bmp' || ft == 'snagit') return 'doctype:image';
        if (ft == 'mp3' || ft == 'wav' || ft == 'audio') return 'doctype:audio';
        if (ft == 'mp4' || ft == 'mov' || ft == 'avi' || ft == 'video') return 'doctype:video';
        
        return 'doctype:attachment';
    }
    
    /**
     * Send a message to the Agentforce agent
     * Uses Invocable.Action to communicate with the Hank agent
     */
    @AuraEnabled
    public static AgentResponse sendAgentMessage(String userMessage, String sessionId, Integer sequenceId) {
        AgentResponse response = new AgentResponse();
        
        try {
            if (String.isBlank(userMessage)) {
                throw new AuraHandledException('Message is required');
            }
            
            // Timing debug
            Long startTime = System.currentTimeMillis();
            System.debug('=== AGENT SEARCH - SENDING MESSAGE ===');
            System.debug('Message: ' + userMessage.abbreviate(100));
            System.debug('Session ID: ' + sessionId);
            System.debug('Sequence ID: ' + sequenceId);
            
            // Create the Invocable Action
            Invocable.Action action = Invocable.Action.createCustomAction(ACTION_TYPE, AGENT_NAME);
            
            // Set parameters
            action.setInvocationParameter('userMessage', userMessage);
            
            if (String.isNotBlank(sessionId)) {
                try {
                    action.setInvocationParameter('sessionId', sessionId);
                } catch (Exception e) {
                    System.debug('sessionId parameter not supported: ' + e.getMessage());
                }
            }
            
            if (sequenceId != null) {
                try {
                    action.setInvocationParameter('sequenceId', sequenceId);
                } catch (Exception e) {
                    System.debug('sequenceId parameter not supported');
                }
            }
            
            // Invoke the action
            Long invokeStart = System.currentTimeMillis();
            List<Invocable.Action.Result> results = action.invoke();
            Long invokeTime = System.currentTimeMillis() - invokeStart;
            
            System.debug('Agent response time: ' + invokeTime + 'ms');
            
            if (results == null || results.isEmpty()) {
                throw new AuraHandledException('No response from agent');
            }
            
            Invocable.Action.Result result = results[0];
            
            if (!result.isSuccess()) {
                List<Invocable.Action.Error> errors = result.getErrors();
                String errorMsg = 'Agent error: ';
                if (errors != null && !errors.isEmpty()) {
                    for (Invocable.Action.Error err : errors) {
                        errorMsg += err.getMessage() + ' ';
                    }
                }
                throw new AuraHandledException(errorMsg);
            }
            
            // Parse response
            Map<String, Object> outputParams = result.getOutputParameters();
            System.debug('Agent output: ' + JSON.serialize(outputParams));
            
            // Extract agent response
            String agentResponseText = null;
            if (outputParams != null) {
                if (outputParams.containsKey('agentResponse')) {
                    agentResponseText = (String) outputParams.get('agentResponse');
                } else if (outputParams.containsKey('response')) {
                    agentResponseText = (String) outputParams.get('response');
                } else if (outputParams.containsKey('message')) {
                    agentResponseText = (String) outputParams.get('message');
                }
                
                // Get returned sessionId
                if (outputParams.containsKey('sessionId')) {
                    response.sessionId = (String) outputParams.get('sessionId');
                }
            }
            
            if (String.isBlank(agentResponseText)) {
                throw new AuraHandledException('Empty response from agent');
            }
            
            // Parse JSON response format if present
            agentResponseText = parseAgentResponseText(agentResponseText);
            
            System.debug('=== AGENT SEARCH COMPLETE ===');
            System.debug('Response length: ' + agentResponseText.length() + ' chars');
            System.debug('Total time: ' + (System.currentTimeMillis() - startTime) + 'ms');
            
            response.success = true;
            response.message = agentResponseText;
            response.sessionId = String.isNotBlank(response.sessionId) ? response.sessionId : sessionId;
            
        } catch (AuraHandledException e) {
            response.success = false;
            response.error = e.getMessage();
            throw e;
        } catch (Exception e) {
            System.debug('Agent error: ' + e.getMessage() + '\n' + e.getStackTraceString());
            response.success = false;
            response.error = 'Failed to communicate with agent: ' + e.getMessage();
            throw new AuraHandledException(response.error);
        }
        
        return response;
    }
    
    /**
     * Parse agent response text - handles JSON format {"type":"Text","value":"..."}
     */
    private static String parseAgentResponseText(String responseText) {
        if (String.isBlank(responseText)) {
            return responseText;
        }
        
        String trimmed = responseText.trim();
        
        // Check if response is JSON format
        if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
            try {
                Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(trimmed);
                
                // Handle {"type":"Text","value":"..."} format
                if (parsed.containsKey('value')) {
                    Object valueObj = parsed.get('value');
                    if (valueObj != null) {
                        return String.valueOf(valueObj);
                    }
                }
                
                // Handle {"text":"..."} format
                if (parsed.containsKey('text')) {
                    Object textObj = parsed.get('text');
                    if (textObj != null) {
                        return String.valueOf(textObj);
                    }
                }
                
                // Handle {"message":"..."} format
                if (parsed.containsKey('message')) {
                    Object msgObj = parsed.get('message');
                    if (msgObj != null) {
                        return String.valueOf(msgObj);
                    }
                }
            } catch (Exception e) {
                System.debug('Response is not JSON or failed to parse: ' + e.getMessage());
            }
        }
        
        return responseText;
    }
    
    // ==================== FEEDBACK ====================
    
    /**
     * Save session feedback
     * Stores feedback data for AI improvement and analysis
     * Uses GenAiFeedback if available, otherwise logs for analysis
     */
    @AuraEnabled
    public static FeedbackResponse saveFeedback(
        String sessionId,
        String rating,
        String comment,
        Integer messageCount
    ) {
        FeedbackResponse response = new FeedbackResponse();
        
        try {
            // Validate inputs
            if (String.isBlank(rating)) {
                throw new AuraHandledException('Rating is required');
            }
            
            Boolean feedbackSaved = false;
            
            try {
                // Check if GenAiFeedback object exists and is accessible
                Schema.SObjectType feedbackType = Schema.getGlobalDescribe().get('GenAiFeedback');
                
                if (feedbackType != null && feedbackType.getDescribe().isCreateable()) {
                    // Create GenAiFeedback record
                    SObject feedback = feedbackType.newSObject();
                    
                    // Set standard fields if available
                    Map<String, Schema.SObjectField> feedbackFields = feedbackType.getDescribe().fields.getMap();
                    
                    if (feedbackFields.containsKey('FeedbackType')) {
                        feedback.put('FeedbackType', rating == 'positive' ? 'ThumbsUp' : 'ThumbsDown');
                    }
                    if (feedbackFields.containsKey('Comment__c') && String.isNotBlank(comment)) {
                        feedback.put('Comment__c', comment);
                    }
                    if (feedbackFields.containsKey('SessionId__c') && String.isNotBlank(sessionId)) {
                        feedback.put('SessionId__c', sessionId);
                    }
                    if (feedbackFields.containsKey('Source')) {
                        feedback.put('Source', 'Agent Search - Employee Portal');
                    }
                    if (feedbackFields.containsKey('GenerativeModelName')) {
                        feedback.put('GenerativeModelName', AGENT_NAME);
                    }
                    
                    insert feedback;
                    feedbackSaved = true;
                    System.debug('Feedback saved to GenAiFeedback: ' + feedback.Id);
                }
            } catch (Exception genAiEx) {
                System.debug('GenAiFeedback not available: ' + genAiEx.getMessage());
            }
            
            // If GenAiFeedback didn't work, log the feedback for analysis
            if (!feedbackSaved) {
                System.debug('=== AGENT SEARCH FEEDBACK ===');
                System.debug('Session ID: ' + sessionId);
                System.debug('Rating: ' + rating);
                System.debug('Comment: ' + comment);
                System.debug('Message Count: ' + messageCount);
                System.debug('Timestamp: ' + System.now());
                System.debug('User: ' + UserInfo.getUserId());
                System.debug('=============================');
                
                feedbackSaved = true;
            }
            
            response.success = true;
            response.message = 'Thank you for your feedback!';
            
        } catch (AuraHandledException e) {
            response.success = false;
            response.error = e.getMessage();
            throw e;
        } catch (Exception e) {
            response.success = false;
            response.error = e.getMessage();
            System.debug('Error saving feedback: ' + e.getMessage() + '\n' + e.getStackTraceString());
        }
        
        return response;
    }
    
    // ==================== WRAPPER CLASSES ====================
    
    public class FeedbackResponse {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String message;
        @AuraEnabled public String error;
    }
    
    public class KnowledgeSearchResponse {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String message;
        @AuraEnabled public Integer totalResults;
        @AuraEnabled public List<SearchResult> results;
        @AuraEnabled public List<KnowledgeArticle> articles; // Deprecated - use results
    }
    
    /**
     * Unified search result - can be a Knowledge article or a File
     */
    public class SearchResult {
        @AuraEnabled public String id;
        @AuraEnabled public String resultType; // 'article' or 'file'
        @AuraEnabled public String title;
        @AuraEnabled public String summary;
        @AuraEnabled public String url;
        @AuraEnabled public String icon; // SLDS icon name
        @AuraEnabled public String articleNumber; // For articles
        @AuraEnabled public String fileType; // For files
        @AuraEnabled public Long fileSize; // For files
        @AuraEnabled public Datetime lastModified;
    }
    
    public class KnowledgeArticle {
        @AuraEnabled public String id;
        @AuraEnabled public String knowledgeArticleId;
        @AuraEnabled public String title;
        @AuraEnabled public String summary;
        @AuraEnabled public String urlName;
        @AuraEnabled public String articleNumber;
        @AuraEnabled public Datetime lastPublishedDate;
        @AuraEnabled public String articleUrl;
    }
    
    public class AgentResponse {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String message;
        @AuraEnabled public String sessionId;
        @AuraEnabled public String error;
    }
}
