/**
 * Deal Review Controller
 * Backend controller for the Agentforce Deal Review LWC
 * Handles opportunity data, MEDDPICC field management, and voice features (TTS/STT)
 * 
 * Prerequisites:
 * - Poseidon_Settings__c with ElevenLabs_API_Key__c configured
 * - Remote Site Setting for https://api.elevenlabs.io
 */
public with sharing class DealReviewController {
    
    // ElevenLabs API Configuration
    private static final String ELEVENLABS_TTS_URL = 'https://api.elevenlabs.io/v1/text-to-speech/';
    private static final String ELEVENLABS_STT_URL = 'https://api.elevenlabs.io/v1/speech-to-text';
    private static final String DEFAULT_VOICE_ID = 'EXAVITQu4vr4xnSDxMaL'; // Bella
    private static final String DEFAULT_MODEL = 'eleven_turbo_v2_5';
    
    // Summarization settings
    private static final Integer SUMMARIZATION_THRESHOLD = 400; // Characters
    private static final String MODELS_API_ENDPOINT = '/services/data/v60.0/einstein/llm/prompt/generations';
    
    // MEDDPICC field API names
    private static final List<String> MEDDPICC_FIELDS = new List<String>{
        'MEDDPICC_Metrics__c', 'MEDDPICC_Metrics_Score__c',
        'MEDDPICC_Economic_Buyer__c', 'MEDDPICC_Economic_Buyer_Score__c',
        'MEDDPICC_Decision_Criteria__c', 'MEDDPICC_Decision_Criteria_Score__c',
        'MEDDPICC_Decision_Process__c', 'MEDDPICC_Decision_Process_Score__c',
        'MEDDPICC_Paper_Process__c', 'MEDDPICC_Paper_Process_Score__c',
        'MEDDPICC_Identify_Pain__c', 'MEDDPICC_Identify_Pain_Score__c',
        'MEDDPICC_Champion__c', 'MEDDPICC_Champion_Score__c',
        'MEDDPICC_Competition__c', 'MEDDPICC_Competition_Score__c',
        'MEDDPICC_Overall_Score__c', 'MEDDPICC_Qualification_Status__c'
    };
    
    /**
     * Get paginated list of opportunities sorted by LastModifiedDate ASC
     * Supports filtering by close date period and owner
     */
    @AuraEnabled(cacheable=false)
    public static OpportunityListResponse getOpportunities(Integer pageNumber, Integer pageSize, String closeDateFilter, Id ownerId) {
        OpportunityListResponse response = new OpportunityListResponse();
        
        try {
            Integer offset = (pageNumber - 1) * pageSize;
            
            // Build dynamic WHERE clause
            String whereClause = 'IsClosed = false';
            
            // Close date filter
            if (String.isNotBlank(closeDateFilter) && closeDateFilter != 'all') {
                Date startDate;
                Date endDate;
                
                if (closeDateFilter == 'thisMonth') {
                    startDate = Date.today().toStartOfMonth();
                    endDate = startDate.addMonths(1).addDays(-1);
                } else if (closeDateFilter == 'thisQuarter') {
                    Integer quarter = ((Date.today().month() - 1) / 3);
                    startDate = Date.newInstance(Date.today().year(), (quarter * 3) + 1, 1);
                    endDate = startDate.addMonths(3).addDays(-1);
                } else if (closeDateFilter == 'nextMonth') {
                    startDate = Date.today().toStartOfMonth().addMonths(1);
                    endDate = startDate.addMonths(1).addDays(-1);
                } else if (closeDateFilter == 'nextQuarter') {
                    Integer quarter = ((Date.today().month() - 1) / 3) + 1;
                    if (quarter > 3) {
                        quarter = 0;
                        startDate = Date.newInstance(Date.today().year() + 1, 1, 1);
                    } else {
                        startDate = Date.newInstance(Date.today().year(), (quarter * 3) + 1, 1);
                    }
                    endDate = startDate.addMonths(3).addDays(-1);
                } else if (closeDateFilter == 'overdue') {
                    endDate = Date.today().addDays(-1);
                }
                
                if (startDate != null && endDate != null) {
                    whereClause += ' AND CloseDate >= :startDate AND CloseDate <= :endDate';
                } else if (endDate != null) {
                    whereClause += ' AND CloseDate <= :endDate';
                }
            }
            
            // Owner filter
            if (ownerId != null) {
                whereClause += ' AND OwnerId = :ownerId';
            }
            
            // Get total count with filters
            String countQuery = 'SELECT COUNT() FROM Opportunity WHERE ' + whereClause;
            response.totalRecords = Database.countQuery(countQuery);
            response.totalPages = response.totalRecords > 0 ? (Integer) Math.ceil((Decimal) response.totalRecords / pageSize) : 1;
            response.currentPage = pageNumber;
            
            // Get opportunities with essential fields
            String query = 'SELECT Id, Name, Amount, CloseDate, StageName, Account.Name, OwnerId, Owner.Name, ' +
                          'MEDDPICC_Overall_Score__c, MEDDPICC_Qualification_Status__c, LastModifiedDate ' +
                          'FROM Opportunity WHERE ' + whereClause + ' ' +
                          'ORDER BY LastModifiedDate ASC LIMIT :pageSize OFFSET :offset';
            
            response.opportunities = Database.query(query);
            
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching opportunities: ' + e.getMessage());
        }
        
        return response;
    }
    
    /**
     * Get opportunity stages for path display
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getStageOptions() {
        List<Map<String, Object>> stages = new List<Map<String, Object>>();
        
        // Get stage picklist values with probability
        Schema.DescribeFieldResult stageField = Opportunity.StageName.getDescribe();
        List<Schema.PicklistEntry> entries = stageField.getPicklistValues();
        
        // Define stage order and metadata
        Map<String, Integer> stageOrder = new Map<String, Integer>{
            'Qualification' => 1,
            'Discovery' => 2,
            'Proposal/Quote' => 3,
            'Negotiation' => 4,
            'Closed Won' => 5,
            'Closed Lost' => 5
        };
        
        for (Schema.PicklistEntry entry : entries) {
            if (entry.isActive()) {
                Map<String, Object> stage = new Map<String, Object>{
                    'value' => entry.getValue(),
                    'label' => entry.getLabel(),
                    'order' => stageOrder.containsKey(entry.getValue()) ? stageOrder.get(entry.getValue()) : 99,
                    'isClosed' => entry.getValue().startsWith('Closed')
                };
                stages.add(stage);
            }
        }
        
        // Sort by order
        stages.sort(new StageComparator());
        
        return stages;
    }
    
    // Comparator for sorting stages
    private class StageComparator implements Comparator<Map<String, Object>> {
        public Integer compare(Map<String, Object> a, Map<String, Object> b) {
            Integer orderA = (Integer) a.get('order');
            Integer orderB = (Integer) b.get('order');
            return orderA - orderB;
        }
    }
    
    /**
     * Get review stats for launcher card on home page
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Integer> getReviewStats() {
        Map<String, Integer> stats = new Map<String, Integer>();
        
        // Count open opportunities
        stats.put('openDeals', [SELECT COUNT() FROM Opportunity WHERE IsClosed = false]);
        
        // Count opportunities needing review (low MEDDPICC score or missing data)
        stats.put('needsReview', [
            SELECT COUNT() FROM Opportunity 
            WHERE IsClosed = false 
            AND (MEDDPICC_Overall_Score__c = null OR MEDDPICC_Overall_Score__c < 3)
        ]);
        
        return stats;
    }
    
    /**
     * Get list of users who own opportunities (for filter dropdown)
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getOpportunityOwners() {
        List<Map<String, String>> owners = new List<Map<String, String>>();
        
        // Add "All Owners" option
        owners.add(new Map<String, String>{
            'value' => '',
            'label' => 'All Owners'
        });
        
        // Get distinct owners from open opportunities
        Set<Id> ownerIds = new Set<Id>();
        for (Opportunity opp : [SELECT OwnerId FROM Opportunity WHERE IsClosed = false]) {
            ownerIds.add(opp.OwnerId);
        }
        
        // Get user details
        for (User u : [SELECT Id, Name FROM User WHERE Id IN :ownerIds ORDER BY Name]) {
            owners.add(new Map<String, String>{
                'value' => u.Id,
                'label' => u.Name
            });
        }
        
        return owners;
    }
    
    /**
     * Get full opportunity detail with all MEDDPICC fields
     */
    @AuraEnabled(cacheable=false)
    public static OpportunityDetailResponse getOpportunityDetail(Id opportunityId) {
        OpportunityDetailResponse response = new OpportunityDetailResponse();
        
        try {
            // Build dynamic query with all MEDDPICC fields
            String query = 'SELECT Id, Name, Description, Amount, CloseDate, StageName, NextStep, Probability, ' +
                          'Account.Name, Owner.Name, LastModifiedDate, ' +
                          String.join(MEDDPICC_FIELDS, ', ') +
                          ' FROM Opportunity WHERE Id = :opportunityId LIMIT 1';
            
            List<Opportunity> opps = Database.query(query);
            
            if (opps.isEmpty()) {
                throw new AuraHandledException('Opportunity not found');
            }
            
            response.opportunity = opps[0];
            response.meddpiccSummary = buildMeddpiccSummary(opps[0]);
            
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching opportunity detail: ' + e.getMessage());
        }
        
        return response;
    }
    
    /**
     * Get opportunity's last modified timestamp for polling
     */
    @AuraEnabled(cacheable=false)
    public static Datetime getOpportunityLastModified(Id opportunityId) {
        List<Opportunity> opps = [
            SELECT LastModifiedDate FROM Opportunity WHERE Id = :opportunityId LIMIT 1
        ];
        return opps.isEmpty() ? null : opps[0].LastModifiedDate;
    }
    
    /**
     * Save opportunity updates (after user edits)
     */
    @AuraEnabled
    public static Opportunity saveOpportunity(Id opportunityId, Map<String, Object> fieldUpdates) {
        try {
            Opportunity opp = new Opportunity(Id = opportunityId);
            
            // Apply field updates
            for (String fieldName : fieldUpdates.keySet()) {
                Object value = fieldUpdates.get(fieldName);
                opp.put(fieldName, value);
            }
            
            update opp;
            
            // Return updated record
            return getOpportunityDetail(opportunityId).opportunity;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error saving opportunity: ' + e.getMessage());
        }
    }
    
    /**
     * Build MEDDPICC summary for agent context
     */
    private static MeddpiccSummary buildMeddpiccSummary(Opportunity opp) {
        MeddpiccSummary summary = new MeddpiccSummary();
        summary.overallScore = opp.MEDDPICC_Overall_Score__c;
        summary.qualificationStatus = opp.MEDDPICC_Qualification_Status__c;
        
        // Analyze each dimension
        summary.dimensions = new List<MeddpiccDimension>();
        summary.emptyFields = new List<String>();
        summary.weakFields = new List<String>();
        
        // Metrics
        addDimension(summary, 'Metrics', 
            (String) opp.get('MEDDPICC_Metrics__c'),
            (String) opp.get('MEDDPICC_Metrics_Score__c'));
        
        // Economic Buyer
        addDimension(summary, 'Economic Buyer',
            (String) opp.get('MEDDPICC_Economic_Buyer__c'),
            (String) opp.get('MEDDPICC_Economic_Buyer_Score__c'));
        
        // Decision Criteria
        addDimension(summary, 'Decision Criteria',
            (String) opp.get('MEDDPICC_Decision_Criteria__c'),
            (String) opp.get('MEDDPICC_Decision_Criteria_Score__c'));
        
        // Decision Process
        addDimension(summary, 'Decision Process',
            (String) opp.get('MEDDPICC_Decision_Process__c'),
            (String) opp.get('MEDDPICC_Decision_Process_Score__c'));
        
        // Paper Process
        addDimension(summary, 'Paper Process',
            (String) opp.get('MEDDPICC_Paper_Process__c'),
            (String) opp.get('MEDDPICC_Paper_Process_Score__c'));
        
        // Identify Pain
        addDimension(summary, 'Identify Pain',
            (String) opp.get('MEDDPICC_Identify_Pain__c'),
            (String) opp.get('MEDDPICC_Identify_Pain_Score__c'));
        
        // Champion
        addDimension(summary, 'Champion',
            (String) opp.get('MEDDPICC_Champion__c'),
            (String) opp.get('MEDDPICC_Champion_Score__c'));
        
        // Competition
        addDimension(summary, 'Competition',
            (String) opp.get('MEDDPICC_Competition__c'),
            (String) opp.get('MEDDPICC_Competition_Score__c'));
        
        return summary;
    }
    
    private static void addDimension(MeddpiccSummary summary, String name, String content, String score) {
        MeddpiccDimension dim = new MeddpiccDimension();
        dim.name = name;
        dim.content = content;
        dim.score = score;
        dim.scoreNumeric = parseScore(score);
        dim.isEmpty = String.isBlank(content);
        dim.isWeak = dim.scoreNumeric != null && dim.scoreNumeric <= 2;
        
        summary.dimensions.add(dim);
        
        if (dim.isEmpty) {
            summary.emptyFields.add(name);
        } else if (dim.isWeak) {
            summary.weakFields.add(name);
        }
    }
    
    private static Integer parseScore(String scoreValue) {
        if (String.isBlank(scoreValue)) return null;
        // Extract number from "1 - Very Weak", "2 - Weak", etc.
        if (scoreValue.length() > 0 && scoreValue.substring(0, 1).isNumeric()) {
            return Integer.valueOf(scoreValue.substring(0, 1));
        }
        return null;
    }
    
    // ==================== AGENT INTERACTION ====================
    
    /**
     * Send message to Deal Review Agent
     * Uses Invocable Action to communicate with the agent
     * @param coachingIntensity 1-5 scale: 1=Very Supportive, 3=Balanced, 5=Very Challenging
     */
    @AuraEnabled
    public static AgentResponse sendAgentMessage(String opportunityId, String userMessage, String sessionId, Integer sequenceId, Integer coachingIntensity) {
        AgentResponse response = new AgentResponse();
        
        try {
            if (String.isBlank(userMessage)) {
                throw new AuraHandledException('Message is required');
            }
            
            // Default coaching intensity to balanced
            if (coachingIntensity == null || coachingIntensity < 1 || coachingIntensity > 5) {
                coachingIntensity = 3;
            }
            
            // Get opportunity context
            String opportunityContext = '';
            if (String.isNotBlank(opportunityId)) {
                opportunityContext = buildOpportunityContext(opportunityId);
            }
            
            // Get coaching style instructions
            String coachingInstructions = getCoachingInstructions(coachingIntensity);
            
            // Build the message with context and coaching style
            String fullMessage = userMessage;
            if (String.isNotBlank(opportunityContext) || String.isNotBlank(coachingInstructions)) {
                fullMessage = '';
                if (String.isNotBlank(coachingInstructions)) {
                    fullMessage += coachingInstructions + '\n\n';
                }
                if (String.isNotBlank(opportunityContext)) {
                    fullMessage += opportunityContext + '\n\n';
                }
                fullMessage += 'User message: ' + userMessage;
            }
            
            // Agent configuration - Deal_Review_Agent
            String agentName = 'Deal_Review_Agent@1.0.0';
            String actionType = 'generateAiAgentResponse';
            
            // ========== TIMING DEBUG ==========
            Long startTime = System.currentTimeMillis();
            System.debug('=== DEAL REVIEW AGENT TIMING ===');
            System.debug('START: ' + startTime);
            System.debug('Agent: ' + agentName);
            System.debug('Context length: ' + (opportunityContext != null ? opportunityContext.length() : 0) + ' chars');
            System.debug('User message length: ' + userMessage.length() + ' chars');
            System.debug('Total message length: ' + fullMessage.length() + ' chars');
            
            // Create the Invocable Action
            Long actionCreateStart = System.currentTimeMillis();
            Invocable.Action action = Invocable.Action.createCustomAction(actionType, agentName);
            System.debug('Action created in: ' + (System.currentTimeMillis() - actionCreateStart) + 'ms');
            
            // Set parameters
            Long paramStart = System.currentTimeMillis();
            action.setInvocationParameter('userMessage', fullMessage);
            
            if (String.isNotBlank(sessionId)) {
                try {
                    action.setInvocationParameter('sessionId', sessionId);
                    System.debug('Set sessionId: ' + sessionId);
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
            
            // Add record context
            if (String.isNotBlank(opportunityId)) {
                try {
                    action.setInvocationParameter('recordId', opportunityId);
                    action.setInvocationParameter('objectType', 'Opportunity');
                } catch (Exception e) {
                    System.debug('Record context parameters not supported');
                }
            }
            
            // Invoke the action
            System.debug('Parameters set in: ' + (System.currentTimeMillis() - paramStart) + 'ms');
            Long invokeStart = System.currentTimeMillis();
            System.debug('Invoking agent action...');
            
            List<Invocable.Action.Result> results = action.invoke();
            
            Long invokeTime = System.currentTimeMillis() - invokeStart;
            System.debug('=== AGENT INVOKE COMPLETED ===');
            System.debug('Agent response time: ' + invokeTime + 'ms (' + (invokeTime/1000.0) + ' seconds)');
            System.debug('Total elapsed: ' + (System.currentTimeMillis() - startTime) + 'ms');
            
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
            System.debug('Agent output parameters: ' + JSON.serialize(outputParams));
            
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
            // Agent may return {"type":"Text","value":"actual message"}
            agentResponseText = parseAgentResponseText(agentResponseText);
            
            // Final timing log
            System.debug('=== DEAL REVIEW COMPLETE ===');
            System.debug('Response length: ' + agentResponseText.length() + ' chars');
            System.debug('Response word count: ~' + agentResponseText.split('\\s+').size() + ' words');
            System.debug('TOTAL TIME: ' + (System.currentTimeMillis() - startTime) + 'ms');
            System.debug('=============================');
            
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
     * Build opportunity context string for agent
     */
    private static String buildOpportunityContext(Id opportunityId) {
        try {
            String query = 'SELECT Id, Name, StageName, Amount, CloseDate, Probability, NextStep, ' +
                          'Account.Name, Owner.Name, Description, ' +
                          String.join(MEDDPICC_FIELDS, ', ') +
                          ' FROM Opportunity WHERE Id = :opportunityId LIMIT 1';
            
            List<Opportunity> opps = Database.query(query);
            
            if (opps.isEmpty()) {
                return '';
            }
            
            Opportunity opp = opps[0];
            
            List<String> contextParts = new List<String>();
            contextParts.add('=== Current Opportunity Context ===');
            contextParts.add('Opportunity ID: ' + opp.Id + ' (USE THIS ID when calling Update MEDDPICC Fields action)');
            contextParts.add('Name: ' + opp.Name);
            contextParts.add('Account: ' + (opp.Account != null ? opp.Account.Name : 'N/A'));
            contextParts.add('Stage: ' + opp.StageName);
            contextParts.add('Amount: $' + (opp.Amount != null ? String.valueOf(opp.Amount.format()) : 'N/A'));
            contextParts.add('Close Date: ' + (opp.CloseDate != null ? String.valueOf(opp.CloseDate) : 'N/A'));
            contextParts.add('Probability: ' + (opp.Probability != null ? String.valueOf(opp.Probability) + '%' : 'N/A'));
            contextParts.add('Next Step: ' + (String.isNotBlank(opp.NextStep) ? opp.NextStep : '[Not defined]'));
            
            if (String.isNotBlank(opp.Description)) {
                contextParts.add('Description: ' + opp.Description.abbreviate(500));
            }
            
            // Add MEDDPICC current state
            contextParts.add('');
            contextParts.add('=== Current MEDDPICC Status ===');
            
            addMeddpiccContext(contextParts, 'Metrics', (String) opp.get('MEDDPICC_Metrics__c'), (String) opp.get('MEDDPICC_Metrics_Score__c'));
            addMeddpiccContext(contextParts, 'Economic Buyer', (String) opp.get('MEDDPICC_Economic_Buyer__c'), (String) opp.get('MEDDPICC_Economic_Buyer_Score__c'));
            addMeddpiccContext(contextParts, 'Decision Criteria', (String) opp.get('MEDDPICC_Decision_Criteria__c'), (String) opp.get('MEDDPICC_Decision_Criteria_Score__c'));
            addMeddpiccContext(contextParts, 'Decision Process', (String) opp.get('MEDDPICC_Decision_Process__c'), (String) opp.get('MEDDPICC_Decision_Process_Score__c'));
            addMeddpiccContext(contextParts, 'Paper Process', (String) opp.get('MEDDPICC_Paper_Process__c'), (String) opp.get('MEDDPICC_Paper_Process_Score__c'));
            addMeddpiccContext(contextParts, 'Identify Pain', (String) opp.get('MEDDPICC_Identify_Pain__c'), (String) opp.get('MEDDPICC_Identify_Pain_Score__c'));
            addMeddpiccContext(contextParts, 'Champion', (String) opp.get('MEDDPICC_Champion__c'), (String) opp.get('MEDDPICC_Champion_Score__c'));
            addMeddpiccContext(contextParts, 'Competition', (String) opp.get('MEDDPICC_Competition__c'), (String) opp.get('MEDDPICC_Competition_Score__c'));
            
            Decimal overallScore = (Decimal) opp.get('MEDDPICC_Overall_Score__c');
            if (overallScore != null) {
                contextParts.add('Overall MEDDPICC Score: ' + overallScore.setScale(1) + '/5');
            }
            
            return String.join(contextParts, '\n');
            
        } catch (Exception e) {
            System.debug('Error building opportunity context: ' + e.getMessage());
            return '';
        }
    }
    
    private static void addMeddpiccContext(List<String> parts, String label, String content, String score) {
        String status = String.isBlank(content) ? '[EMPTY]' : content.abbreviate(200);
        String scoreDisplay = String.isNotBlank(score) ? ' (Score: ' + score + ')' : '';
        parts.add(label + scoreDisplay + ': ' + status);
    }
    
    /**
     * Get coaching style instructions based on intensity level
     * @param intensity 1-5 scale: 1=Very Supportive, 3=Balanced, 5=Very Challenging
     */
    private static String getCoachingInstructions(Integer intensity) {
        String instructions = '=== COACHING STYLE FOR THIS SESSION ===\n';
        
        switch on intensity {
            when 1 {
                // Very Supportive
                instructions += 'COACHING MODE: Very Supportive\n';
                instructions += '- Lead with encouragement and positive reinforcement\n';
                instructions += '- Ask gentle, open-ended questions\n';
                instructions += '- Celebrate every piece of information shared\n';
                instructions += '- Avoid challenging or questioning their assessment\n';
                instructions += '- Focus on building their confidence in the deal\n';
                instructions += '- If gaps exist, offer help rather than point out problems\n';
                instructions += 'TONE: Warm, encouraging, patient - like a supportive mentor';
            }
            when 2 {
                // Supportive
                instructions += 'COACHING MODE: Supportive\n';
                instructions += '- Balance encouragement with occasional suggestions\n';
                instructions += '- Ask clarifying questions without being demanding\n';
                instructions += '- Acknowledge their efforts before suggesting improvements\n';
                instructions += '- Phrase concerns as opportunities, not problems\n';
                instructions += '- Give positive feedback frequently\n';
                instructions += 'TONE: Friendly, helpful - like a collaborative peer';
            }
            when 3 {
                // Balanced (default)
                instructions += 'COACHING MODE: Balanced\n';
                instructions += '- Mix encouragement with constructive challenge\n';
                instructions += '- Ask probing questions to get specifics\n';
                instructions += '- Point out gaps and risks directly but tactfully\n';
                instructions += '- Challenge assumptions when warranted\n';
                instructions += '- Suggest stage/close date changes when appropriate\n';
                instructions += 'TONE: Professional, direct but fair - like a good sales manager';
            }
            when 4 {
                // Challenging
                instructions += 'COACHING MODE: Challenging\n';
                instructions += '- Push for clarity and specifics on every answer\n';
                instructions += '- Challenge vague or weak responses\n';
                instructions += '- Point out risks and gaps directly\n';
                instructions += '- Ask "why" and "how" follow-up questions\n';
                instructions += '- Do not accept "I think" or "probably" - demand evidence\n';
                instructions += '- Proactively suggest stage/close date/next step changes\n';
                instructions += 'TONE: Direct, demanding - like a VP reviewing a forecast';
            }
            when 5 {
                // Very Challenging
                instructions += 'COACHING MODE: Very Challenging\n';
                instructions += '- Be relentlessly rigorous - this deal must prove itself\n';
                instructions += '- Challenge every assumption and claim made\n';
                instructions += '- Ask hard questions: "What makes you think they will actually buy?"\n';
                instructions += '- Point out every gap, weakness, and risk immediately\n';
                instructions += '- Demand quantified evidence for all claims\n';
                instructions += '- If MEDDPICC is weak, say so bluntly: "This deal is not qualified"\n';
                instructions += '- Aggressively recommend close date pushes or stage downgrades if warranted\n';
                instructions += '- Do not coddle - the rep needs honest feedback\n';
                instructions += 'TONE: Intense, demanding - like a CRO in a deal review before quarter-end';
            }
            when else {
                // Default to balanced
                return getCoachingInstructions(3);
            }
        }
        
        return instructions;
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
                // Not valid JSON, return as-is
                System.debug('Response is not JSON or failed to parse: ' + e.getMessage());
            }
        }
        
        return responseText;
    }
    
    /**
     * Agent response wrapper
     */
    public class AgentResponse {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String message;
        @AuraEnabled public String sessionId;
        @AuraEnabled public String error;
    }
    
    // ==================== VOICE FEATURES ====================
    
    /**
     * Synthesize speech from text using ElevenLabs TTS
     */
    @AuraEnabled
    public static String synthesizeSpeech(String text, String voiceId, Map<String, Decimal> voiceSettings) {
        if (String.isBlank(text)) {
            throw new AuraHandledException('Text is required for speech synthesis');
        }
        
        String apiKey = getElevenLabsApiKey();
        if (String.isBlank(apiKey)) {
            throw new AuraHandledException('ElevenLabs API key not configured in Poseidon Settings');
        }
        
        try {
            String voice = String.isNotBlank(voiceId) ? voiceId : DEFAULT_VOICE_ID;
            String endpoint = ELEVENLABS_TTS_URL + voice + '?output_format=mp3_22050_32';
            
            // Voice settings with defaults
            Decimal stability = voiceSettings?.get('stability') ?? 0.5;
            Decimal similarity = voiceSettings?.get('similarity') ?? 0.75;
            Decimal speed = voiceSettings?.get('speed') ?? 1.0;
            Decimal style = voiceSettings?.get('style') ?? 0.0;
            
            Map<String, Object> requestBody = new Map<String, Object>{
                'text' => text,
                'model_id' => DEFAULT_MODEL,
                'voice_settings' => new Map<String, Object>{
                    'stability' => stability,
                    'similarity_boost' => similarity,
                    'style' => style,
                    'use_speaker_boost' => true
                }
            };
            
            if (speed != 1.0) {
                requestBody.put('speed', speed);
            }
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('POST');
            req.setHeader('xi-api-key', apiKey);
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Accept', 'audio/mpeg');
            req.setBody(JSON.serialize(requestBody));
            req.setTimeout(60000);
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                Blob audioBlob = res.getBodyAsBlob();
                return EncodingUtil.base64Encode(audioBlob);
            } else {
                throw new AuraHandledException('TTS failed: ' + res.getStatusCode() + ' - ' + res.getBody().abbreviate(200));
            }
            
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException('Speech synthesis error: ' + e.getMessage());
        }
    }
    
    /**
     * Get ElevenLabs STT configuration for WebSocket streaming
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, String> getSTTConfig() {
        String apiKey = getElevenLabsApiKey();
        if (String.isBlank(apiKey)) {
            return new Map<String, String>{
                'configured' => 'false',
                'fallback' => 'webSpeechApi'
            };
        }
        
        return new Map<String, String>{
            'configured' => 'true',
            'apiKey' => apiKey,
            'wsEndpoint' => 'wss://api.elevenlabs.io/v1/speech-to-text'
        };
    }
    
    /**
     * Get available ElevenLabs voices
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getAvailableVoices() {
        return new List<Map<String, String>>{
            new Map<String, String>{'value' => 'EXAVITQu4vr4xnSDxMaL', 'label' => 'Bella', 'description' => 'Female • Clear & Friendly'},
            new Map<String, String>{'value' => '21m00Tcm4TlvDq8ikWAM', 'label' => 'Rachel', 'description' => 'Female • Calm & Professional'},
            new Map<String, String>{'value' => 'pNInz6obpgDQGcFmaJgB', 'label' => 'Adam', 'description' => 'Male • Deep & Professional'},
            new Map<String, String>{'value' => 'TxGEqnHWrfWFTfGW9XjX', 'label' => 'Josh', 'description' => 'Male • Deep & Authoritative'},
            new Map<String, String>{'value' => 'VR6AewLTigWG4xSOukaG', 'label' => 'Arnold', 'description' => 'Male • Crisp & Clear'},
            new Map<String, String>{'value' => 'yoZ06aMxZJJ28mfd3POQ', 'label' => 'Sam', 'description' => 'Male • Dynamic & Engaging'},
            new Map<String, String>{'value' => 'AZnzlk1XvdvUeBnXmlld', 'label' => 'Domi', 'description' => 'Female • Strong & Confident'},
            new Map<String, String>{'value' => 'MF3mGyEYCl7XYWbV9V6O', 'label' => 'Elli', 'description' => 'Female • Warm & Emotional'}
        };
    }
    
    // ==================== VOICE OPTIMIZATION ====================
    
    /**
     * Check if text should be summarized for TTS
     */
    @AuraEnabled(cacheable=false)
    public static Boolean shouldSummarize(String text) {
        return String.isNotBlank(text) && text.length() > SUMMARIZATION_THRESHOLD;
    }
    
    /**
     * Summarize long text for voice-optimized TTS
     */
    @AuraEnabled
    public static String summarizeForVoice(String text) {
        if (String.isBlank(text) || text.length() <= SUMMARIZATION_THRESHOLD) {
            return text;
        }
        
        try {
            String prompt = 'You are a sales manager assistant summarizing deal review information for audio playback. ' +
                           'Create a natural, conversational summary that sounds good when spoken aloud.\n\n' +
                           'RULES:\n' +
                           '- Keep it to 3-4 sentences maximum\n' +
                           '- Use natural speech patterns (contractions, conversational tone)\n' +
                           '- Focus on: key updates made, current deal status, and the most important next step\n' +
                           '- Start with a brief intro like "Here\'s the update:" or "Quick summary:"\n' +
                           '- Do NOT use bullet points, asterisks, markdown, or formatting\n' +
                           '- Do NOT say "the text says" or reference that you are summarizing\n' +
                           '- Sound like a helpful colleague giving a quick verbal update\n\n' +
                           'TEXT TO SUMMARIZE:\n' + text;
            
            String summary = callModelsAPI(prompt);
            return String.isNotBlank(summary) ? summary : truncateForVoice(text);
            
        } catch (Exception e) {
            System.debug('Summarization failed: ' + e.getMessage());
            return truncateForVoice(text);
        }
    }
    
    private static String callModelsAPI(String prompt) {
        try {
            String sessionId = UserInfo.getSessionId();
            String baseUrl = URL.getOrgDomainUrl().toExternalForm();
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint(baseUrl + MODELS_API_ENDPOINT);
            req.setMethod('POST');
            req.setHeader('Authorization', 'Bearer ' + sessionId);
            req.setHeader('Content-Type', 'application/json');
            req.setTimeout(15000); // 15 second timeout for fast turbo model
            
            Map<String, Object> requestBody = new Map<String, Object>{
                'promptTextorId' => prompt,
                'provider' => 'OpenAI',
                'additionalConfig' => new Map<String, Object>{
                    'maxTokens' => 500,  // ~375 words - enough for comprehensive 4-5 sentence summaries
                    'temperature' => 0.5,
                    'applicationName' => 'DealReview'
                }
            };
            
            req.setBody(JSON.serialize(requestBody));
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
                Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                
                if (response.containsKey('generations')) {
                    List<Object> generations = (List<Object>) response.get('generations');
                    if (!generations.isEmpty()) {
                        Map<String, Object> generation = (Map<String, Object>) generations[0];
                        if (generation.containsKey('text')) {
                            return String.valueOf(generation.get('text')).trim();
                        }
                    }
                }
            }
            
        } catch (Exception e) {
            System.debug('Models API error: ' + e.getMessage());
        }
        
        return null;
    }
    
    private static String truncateForVoice(String text) {
        // For fallback, try to capture 5-6 complete sentences (generous limit)
        if (text.length() <= 800) return text;
        
        String truncated = text.substring(0, 800);
        
        // Find the last complete sentence
        Integer lastPeriod = truncated.lastIndexOf('. ');
        Integer lastQuestion = truncated.lastIndexOf('? ');
        Integer lastExclaim = truncated.lastIndexOf('! ');
        
        Integer cutPoint = Math.max(Math.max(lastPeriod, lastQuestion), lastExclaim);
        
        if (cutPoint > 200) {
            return text.substring(0, cutPoint + 1);
        }
        
        // If no good sentence break, find a natural pause point
        return truncated.trim() + '...';
    }
    
    /**
     * Get ElevenLabs API key from Poseidon Settings
     */
    private static String getElevenLabsApiKey() {
        try {
            Poseidon_Settings__c settings = Poseidon_Settings__c.getOrgDefaults();
            if (settings != null && String.isNotBlank(settings.ElevenLabs_API_Key__c)) {
                return settings.ElevenLabs_API_Key__c.trim();
            }
        } catch (Exception e) {
            System.debug('Error getting Poseidon Settings: ' + e.getMessage());
        }
        return null;
    }
    
    // ==================== FEEDBACK ====================
    
    /**
     * Save session feedback
     * Stores feedback data for AI improvement and analysis
     * Note: Uses GenAiFeedback if available, otherwise stores in custom object/log
     */
    @AuraEnabled
    public static FeedbackResponse saveFeedback(
        String sessionId,
        String opportunityId,
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
            
            // Try to use GenAiFeedback object (standard AI feedback data model)
            // If it doesn't exist or user doesn't have access, log alternatively
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
                    if (feedbackFields.containsKey('RecordId') && String.isNotBlank(opportunityId)) {
                        feedback.put('RecordId', opportunityId);
                    }
                    if (feedbackFields.containsKey('Source')) {
                        feedback.put('Source', 'Agentforce Deal Review');
                    }
                    if (feedbackFields.containsKey('GenerativeModelName')) {
                        feedback.put('GenerativeModelName', 'Deal_Review_Agent');
                    }
                    
                    insert feedback;
                    feedbackSaved = true;
                    System.debug('Feedback saved to GenAiFeedback: ' + feedback.Id);
                }
            } catch (Exception genAiEx) {
                System.debug('GenAiFeedback not available: ' + genAiEx.getMessage());
                // Fall through to alternative logging
            }
            
            // If GenAiFeedback didn't work, log the feedback for analysis
            if (!feedbackSaved) {
                // Create a platform event or log entry for the feedback
                System.debug('=== DEAL REVIEW FEEDBACK ===');
                System.debug('Session ID: ' + sessionId);
                System.debug('Opportunity ID: ' + opportunityId);
                System.debug('Rating: ' + rating);
                System.debug('Comment: ' + comment);
                System.debug('Message Count: ' + messageCount);
                System.debug('Timestamp: ' + System.now());
                System.debug('User: ' + UserInfo.getUserId());
                System.debug('============================');
                
                // Mark as saved (logged) even if not in GenAiFeedback
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
    
    public class OpportunityListResponse {
        @AuraEnabled public List<Opportunity> opportunities;
        @AuraEnabled public Integer totalRecords;
        @AuraEnabled public Integer totalPages;
        @AuraEnabled public Integer currentPage;
    }
    
    public class OpportunityDetailResponse {
        @AuraEnabled public Opportunity opportunity;
        @AuraEnabled public MeddpiccSummary meddpiccSummary;
    }
    
    public class MeddpiccSummary {
        @AuraEnabled public Decimal overallScore;
        @AuraEnabled public String qualificationStatus;
        @AuraEnabled public List<MeddpiccDimension> dimensions;
        @AuraEnabled public List<String> emptyFields;
        @AuraEnabled public List<String> weakFields;
    }
    
    public class MeddpiccDimension {
        @AuraEnabled public String name;
        @AuraEnabled public String content;
        @AuraEnabled public String score;
        @AuraEnabled public Integer scoreNumeric;
        @AuraEnabled public Boolean isEmpty;
        @AuraEnabled public Boolean isWeak;
    }
}

