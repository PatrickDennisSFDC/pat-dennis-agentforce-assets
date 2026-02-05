/**
 * AF Deal Review Action
 * Invocable action for the Deal Review Agent to update MEDDPICC qualification fields,
 * and optionally recommend/update stage and close date.
 * 
 * The agent uses this action to:
 * 1. Analyze user input about the deal
 * 2. Update relevant MEDDPICC text fields with new/consolidated information
 * 3. Assign appropriate scores (1-5) based on qualification strength
 * 4. Recommend or apply stage changes based on deal progression signals
 * 5. Recommend or apply close date changes based on timeline discussions
 * 6. Return what was updated for visual highlighting in the UI
 * 
 * STAGE PROGRESSION SIGNALS (for agent reference):
 *   Qualification → Discovery: Initial interest confirmed, exploring needs
 *   Discovery → Proposal/Quote: Pain identified, requirements understood, ready to propose
 *   Proposal/Quote → Negotiation: Proposal delivered, discussing terms/pricing
 *   Negotiation → Closed Won: Agreement reached, contracts signed
 * 
 * CLOSE DATE SIGNALS:
 *   - Explicit timeline mentions: "aiming to close by end of Q1", "need solution by March"
 *   - Paper process timelines: "procurement takes 30 days", "legal review 2 weeks"
 *   - Compelling events: "budget expires June 30", "go-live deadline April 1"
 *   - If current close date seems unrealistic given deal state, suggest adjustment
 * 
 * MEDDPICC Scoring Criteria (embedded in action for agent reference):
 * 
 * METRICS (Quantifiable business outcomes)
 *   1 - Very Weak: No metrics identified
 *   2 - Weak: Vague outcomes mentioned, not quantified
 *   3 - Moderate: Some metrics identified but not validated
 *   4 - Strong: Clear metrics agreed upon by customer
 *   5 - Very Strong: Metrics documented with ROI calculations, customer sign-off
 * 
 * ECONOMIC BUYER (Person with budget authority)
 *   1 - Very Weak: Unknown who controls budget
 *   2 - Weak: Suspected but not confirmed
 *   3 - Moderate: Identified but no direct access
 *   4 - Strong: Identified with direct engagement
 *   5 - Very Strong: Active sponsor, committed to success
 * 
 * DECISION CRITERIA (Requirements for selection)
 *   1 - Very Weak: Unknown what they're evaluating
 *   2 - Weak: General criteria mentioned
 *   3 - Moderate: Criteria documented, some alignment
 *   4 - Strong: Criteria mapped to our strengths
 *   5 - Very Strong: We helped define criteria, strong fit
 * 
 * DECISION PROCESS (Steps to purchase)
 *   1 - Very Weak: Unknown approval process
 *   2 - Weak: Vague understanding of steps
 *   3 - Moderate: Process documented, timeline unclear
 *   4 - Strong: Clear process with timeline
 *   5 - Very Strong: Mutual action plan agreed, milestones tracking
 * 
 * PAPER PROCESS (Procurement/legal/contracts)
 *   1 - Very Weak: Unknown procurement requirements
 *   2 - Weak: General awareness of legal/procurement
 *   3 - Moderate: Key requirements identified
 *   4 - Strong: Procurement engaged, terms discussed
 *   5 - Very Strong: Contract terms agreed, in final review
 * 
 * IDENTIFY PAIN (Business problems driving purchase)
 *   1 - Very Weak: No pain identified
 *   2 - Weak: Surface-level pain mentioned
 *   3 - Moderate: Pain documented with some impact
 *   4 - Strong: Quantified pain with business impact
 *   5 - Very Strong: Compelling event, urgent need documented
 * 
 * CHAMPION (Internal advocate selling on your behalf)
 *   1 - Very Weak: No internal advocate
 *   2 - Weak: Friendly contact, no advocacy
 *   3 - Moderate: Supporter with some influence
 *   4 - Strong: Active advocate with access to power
 *   5 - Very Strong: Coaching you on politics, selling internally
 * 
 * COMPETITION (Competitive landscape)
 *   1 - Very Weak: Unknown competitive situation
 *   2 - Weak: Aware of competition, no strategy
 *   3 - Moderate: Competition identified, some differentiation
 *   4 - Strong: Clear competitive positioning
 *   5 - Very Strong: Preferred vendor, competition minimized
 */
public without sharing class AFDealReviewAction {
    
    // Score picklist values matching the Opportunity field definition
    private static final Map<Integer, String> SCORE_VALUES = new Map<Integer, String>{
        1 => '1 - Very Weak',
        2 => '2 - Weak',
        3 => '3 - Moderate',
        4 => '4 - Strong',
        5 => '5 - Very Strong'
    };
    
    // MEDDPICC field mappings (dimension name -> field API names)
    private static final Map<String, Map<String, String>> MEDDPICC_FIELDS = new Map<String, Map<String, String>>{
        'metrics' => new Map<String, String>{'text' => 'MEDDPICC_Metrics__c', 'score' => 'MEDDPICC_Metrics_Score__c'},
        'economic_buyer' => new Map<String, String>{'text' => 'MEDDPICC_Economic_Buyer__c', 'score' => 'MEDDPICC_Economic_Buyer_Score__c'},
        'decision_criteria' => new Map<String, String>{'text' => 'MEDDPICC_Decision_Criteria__c', 'score' => 'MEDDPICC_Decision_Criteria_Score__c'},
        'decision_process' => new Map<String, String>{'text' => 'MEDDPICC_Decision_Process__c', 'score' => 'MEDDPICC_Decision_Process_Score__c'},
        'paper_process' => new Map<String, String>{'text' => 'MEDDPICC_Paper_Process__c', 'score' => 'MEDDPICC_Paper_Process_Score__c'},
        'identify_pain' => new Map<String, String>{'text' => 'MEDDPICC_Identify_Pain__c', 'score' => 'MEDDPICC_Identify_Pain_Score__c'},
        'champion' => new Map<String, String>{'text' => 'MEDDPICC_Champion__c', 'score' => 'MEDDPICC_Champion_Score__c'},
        'competition' => new Map<String, String>{'text' => 'MEDDPICC_Competition__c', 'score' => 'MEDDPICC_Competition_Score__c'}
    };
    
    public class Request {
        @InvocableVariable(
            label='Opportunity ID'
            description='REQUIRED. The ID of the opportunity being reviewed. This should be passed from the Deal Review UI context.'
            required=true
        )
        public Id opportunityId;
        
        @InvocableVariable(
            label='Updates JSON'
            description='JSON object containing MEDDPICC field updates. Format: {"metrics": {"text": "content", "score": 4}, "champion": {"text": "content", "score": 3}}. Dimension keys: metrics, economic_buyer, decision_criteria, decision_process, paper_process, identify_pain, champion, competition. Each dimension has "text" (string content) and "score" (integer 1-5). Only include dimensions that need updating.'
            required=true
        )
        public String updatesJson;
        
        @InvocableVariable(
            label='Consolidate with Existing'
            description='If true, new text content will be intelligently merged with existing content. If false, existing content will be replaced. Default: true.'
            required=false
        )
        public Boolean consolidateWithExisting;
        
        @InvocableVariable(
            label='New Stage Name'
            description='Optional. If the conversation suggests the deal should move to a different stage, specify the new stage. Valid values: Qualification, Discovery, Proposal/Quote, Negotiation. Only set this when user confirms they want to change the stage. Example: "Negotiation"'
            required=false
        )
        public String newStageName;
        
        @InvocableVariable(
            label='New Close Date'
            description='Optional. If the conversation reveals a new target close date, specify it in YYYY-MM-DD format. Only set this when user confirms or provides explicit timeline. Example: "2026-03-31"'
            required=false
        )
        public String newCloseDate;
        
        @InvocableVariable(
            label='New Next Step'
            description='Optional. The next action item or milestone for this deal. Capture specific next steps discussed in the conversation. Examples: "Schedule demo with IT team", "Send proposal by Friday", "Get legal review of MSA", "Follow up with CFO after budget meeting". Update this when the rep mentions upcoming actions or when you identify a logical next step based on the deal stage.'
            required=false
        )
        public String newNextStep;
    }
    
    public class Response {
        @InvocableVariable(label='Success' description='Whether the MEDDPICC update completed successfully. True if fields were updated, false if an error occurred.')
        public Boolean success;
        
        @InvocableVariable(label='Message' description='Human-readable summary of what was updated. Example: Updated Champion, Economic Buyer. Scores: Champion (4/5 - strong).')
        public String message;
        
        @InvocableVariable(label='Updated Fields' description='List of MEDDPICC dimension names that had their text content updated. Example: Champion, Economic Buyer, Identify Pain.')
        public List<String> updatedFields;
        
        @InvocableVariable(label='Updated Scores JSON' description='JSON map of dimension names to their new numeric scores (1-5). Example: {"Champion": 4, "Economic Buyer": 3}.')
        public String updatedScoresJson;
        
        @InvocableVariable(label='New Overall Score' description='The recalculated overall MEDDPICC score (1.0-5.0 average) after the update. Use this to report deal qualification strength.')
        public Decimal newOverallScore;
        
        @InvocableVariable(label='Error Message' description='If success is false, contains the error details. Null when successful. Report this to the user if present.')
        public String errorMessage;
        
        @InvocableVariable(label='Opportunity JSON' description='Full JSON of the updated Opportunity record with all MEDDPICC fields. Use for detailed field inspection if needed.')
        public String opportunityJson;
        
        @InvocableVariable(label='Stage Updated' description='True if the opportunity stage was changed in this update. Use this to inform the user about stage progression.')
        public Boolean stageUpdated;
        
        @InvocableVariable(label='New Stage Name' description='If stage was updated, contains the new stage name. Example: "Negotiation"')
        public String newStageName;
        
        @InvocableVariable(label='Previous Stage Name' description='If stage was updated, contains the previous stage name for reference.')
        public String previousStageName;
        
        @InvocableVariable(label='Close Date Updated' description='True if the close date was changed in this update.')
        public Boolean closeDateUpdated;
        
        @InvocableVariable(label='New Close Date' description='If close date was updated, contains the new date in YYYY-MM-DD format.')
        public String newCloseDate;
        
        @InvocableVariable(label='Previous Close Date' description='If close date was updated, contains the previous date in YYYY-MM-DD format.')
        public String previousCloseDate;
        
        @InvocableVariable(label='Next Step Updated' description='True if the next step was changed in this update.')
        public Boolean nextStepUpdated;
        
        @InvocableVariable(label='New Next Step' description='If next step was updated, contains the new next step text.')
        public String newNextStep;
        
        @InvocableVariable(label='Previous Next Step' description='If next step was updated, contains the previous next step for reference.')
        public String previousNextStep;
    }
    
    @InvocableMethod(
        label='Update MEDDPICC Fields'
        description='Updates MEDDPICC qualification fields on an opportunity based on deal review conversation. The agent should analyze user input to identify relevant MEDDPICC dimensions, determine appropriate content and scores, and call this action. SCORING GUIDE: 1=Very Weak (unknown/none), 2=Weak (vague/suspected), 3=Moderate (identified but not validated), 4=Strong (confirmed with evidence), 5=Very Strong (fully validated, active engagement). When consolidating content, synthesize new information with existing to create a complete picture. Always update scores to reflect the cumulative strength of information.'
        category='Deal Review'
    )
    public static List<Response> updateMeddpiccFields(List<Request> requests) {
        List<Response> responses = new List<Response>();
        
        for (Request req : requests) {
            Response res = new Response();
            res.success = false;
            res.updatedFields = new List<String>();
            Map<String, Integer> updatedScoresMap = new Map<String, Integer>();
            
            try {
                // Validate request
                if (req.opportunityId == null) {
                    throw new ActionException('Opportunity ID is required');
                }
                
                if (String.isBlank(req.updatesJson)) {
                    throw new ActionException('Updates JSON is required');
                }
                
                // Parse updates
                Map<String, Object> updates = (Map<String, Object>) JSON.deserializeUntyped(req.updatesJson);
                
                if (updates.isEmpty()) {
                    res.success = true;
                    res.message = 'No updates provided.';
                    responses.add(res);
                    continue;
                }
                
                // Get current opportunity
                Opportunity opp = getOpportunity(req.opportunityId);
                
                // Apply updates
                Boolean consolidate = req.consolidateWithExisting != false; // Default true
                
                for (String dimension : updates.keySet()) {
                    String dimLower = dimension.toLowerCase().replace(' ', '_');
                    
                    if (!MEDDPICC_FIELDS.containsKey(dimLower)) {
                        System.debug('Unknown MEDDPICC dimension: ' + dimension);
                        continue;
                    }
                    
                    Map<String, String> fieldNames = MEDDPICC_FIELDS.get(dimLower);
                    Map<String, Object> dimUpdates = (Map<String, Object>) updates.get(dimension);
                    
                    // Update text field
                    if (dimUpdates.containsKey('text')) {
                        String newText = String.valueOf(dimUpdates.get('text'));
                        String textField = fieldNames.get('text');
                        String existingText = (String) opp.get(textField);
                        
                        if (consolidate && String.isNotBlank(existingText) && String.isNotBlank(newText)) {
                            // Consolidate: append with separator
                            String consolidated = existingText + '\n\n[Updated ' + Date.today().format() + ']\n' + newText;
                            opp.put(textField, consolidated);
                        } else if (String.isNotBlank(newText)) {
                            opp.put(textField, newText);
                        }
                        
                        res.updatedFields.add(formatDimensionName(dimLower));
                    }
                    
                    // Update score field
                    if (dimUpdates.containsKey('score')) {
                        Integer scoreNum = Integer.valueOf(dimUpdates.get('score'));
                        if (scoreNum >= 1 && scoreNum <= 5) {
                            String scoreField = fieldNames.get('score');
                            opp.put(scoreField, SCORE_VALUES.get(scoreNum));
                            updatedScoresMap.put(formatDimensionName(dimLower), scoreNum);
                        }
                    }
                }
                
                // Process stage update
                if (String.isNotBlank(req.newStageName)) {
                    String normalizedStage = normalizeStage(req.newStageName);
                    if (normalizedStage != null && normalizedStage != opp.StageName) {
                        res.previousStageName = opp.StageName;
                        opp.StageName = normalizedStage;
                        res.newStageName = normalizedStage;
                        res.stageUpdated = true;
                    }
                }
                
                // Process close date update
                if (String.isNotBlank(req.newCloseDate)) {
                    try {
                        Date newDate = Date.valueOf(req.newCloseDate);
                        if (newDate != opp.CloseDate) {
                            res.previousCloseDate = opp.CloseDate != null ? String.valueOf(opp.CloseDate) : null;
                            opp.CloseDate = newDate;
                            res.newCloseDate = req.newCloseDate;
                            res.closeDateUpdated = true;
                        }
                    } catch (Exception e) {
                        System.debug('Invalid close date format: ' + req.newCloseDate);
                    }
                }
                
                // Process next step update
                if (String.isNotBlank(req.newNextStep)) {
                    String trimmedNextStep = req.newNextStep.trim();
                    if (trimmedNextStep != opp.NextStep) {
                        res.previousNextStep = opp.NextStep;
                        opp.NextStep = trimmedNextStep;
                        res.newNextStep = trimmedNextStep;
                        res.nextStepUpdated = true;
                    }
                }
                
                // Save opportunity
                Boolean hasUpdates = !res.updatedFields.isEmpty() || !updatedScoresMap.isEmpty() || 
                                     res.stageUpdated == true || res.closeDateUpdated == true ||
                                     res.nextStepUpdated == true;
                
                if (hasUpdates) {
                    update opp;
                    
                    // Refresh to get computed fields
                    opp = getOpportunity(req.opportunityId);
                    res.newOverallScore = opp.MEDDPICC_Overall_Score__c;
                    res.opportunityJson = JSON.serialize(opp);
                }
                
                res.updatedScoresJson = JSON.serialize(updatedScoresMap);
                res.success = true;
                res.message = buildSuccessMessage(res.updatedFields, updatedScoresMap, res);
                
            } catch (ActionException ae) {
                res.success = false;
                res.errorMessage = ae.getMessage();
            } catch (Exception e) {
                res.success = false;
                res.errorMessage = 'Error updating MEDDPICC fields: ' + e.getMessage();
                System.debug('AFDealReviewAction error: ' + e.getMessage() + '\n' + e.getStackTraceString());
            }
            
            responses.add(res);
        }
        
        return responses;
    }
    
    private static Opportunity getOpportunity(Id oppId) {
        List<Opportunity> opps = [
            SELECT Id, Name, StageName, CloseDate, Probability, Amount, NextStep,
                   MEDDPICC_Metrics__c, MEDDPICC_Metrics_Score__c,
                   MEDDPICC_Economic_Buyer__c, MEDDPICC_Economic_Buyer_Score__c,
                   MEDDPICC_Decision_Criteria__c, MEDDPICC_Decision_Criteria_Score__c,
                   MEDDPICC_Decision_Process__c, MEDDPICC_Decision_Process_Score__c,
                   MEDDPICC_Paper_Process__c, MEDDPICC_Paper_Process_Score__c,
                   MEDDPICC_Identify_Pain__c, MEDDPICC_Identify_Pain_Score__c,
                   MEDDPICC_Champion__c, MEDDPICC_Champion_Score__c,
                   MEDDPICC_Competition__c, MEDDPICC_Competition_Score__c,
                   MEDDPICC_Overall_Score__c, MEDDPICC_Qualification_Status__c
            FROM Opportunity
            WHERE Id = :oppId
            LIMIT 1
        ];
        
        if (opps.isEmpty()) {
            throw new ActionException('Opportunity not found: ' + oppId);
        }
        
        return opps[0];
    }
    
    // Valid open stages (excluding Closed Won/Lost)
    private static final Set<String> VALID_STAGES = new Set<String>{
        'Qualification', 'Discovery', 'Proposal/Quote', 'Negotiation'
    };
    
    private static String formatDimensionName(String apiName) {
        // Convert api_name to "Api Name"
        List<String> parts = apiName.split('_');
        List<String> formatted = new List<String>();
        for (String part : parts) {
            if (String.isNotBlank(part)) {
                formatted.add(part.capitalize());
            }
        }
        return String.join(formatted, ' ');
    }
    
    private static String normalizeStage(String stageName) {
        if (String.isBlank(stageName)) return null;
        
        String normalized = stageName.trim();
        
        // Direct match check
        if (VALID_STAGES.contains(normalized)) {
            return normalized;
        }
        
        // Case-insensitive match
        for (String validStage : VALID_STAGES) {
            if (validStage.equalsIgnoreCase(normalized)) {
                return validStage;
            }
        }
        
        // Fuzzy matching for common variations
        String lower = normalized.toLowerCase();
        if (lower.contains('qualif')) return 'Qualification';
        if (lower.contains('discov')) return 'Discovery';
        if (lower.contains('propos') || lower.contains('quote')) return 'Proposal/Quote';
        if (lower.contains('negot')) return 'Negotiation';
        
        return null; // Invalid stage
    }
    
    private static String buildSuccessMessage(List<String> updatedFields, Map<String, Integer> updatedScores, Response res) {
        List<String> parts = new List<String>();
        
        if (!updatedFields.isEmpty()) {
            parts.add('Updated ' + String.join(updatedFields, ', '));
        }
        
        if (!updatedScores.isEmpty()) {
            List<String> scoreParts = new List<String>();
            for (String field : updatedScores.keySet()) {
                Integer score = updatedScores.get(field);
                String strength = score <= 2 ? 'needs work' : (score >= 4 ? 'strong' : 'moderate');
                scoreParts.add(field + ' (' + score + '/5 - ' + strength + ')');
            }
            parts.add('Scores: ' + String.join(scoreParts, ', '));
        }
        
        if (res.stageUpdated == true) {
            parts.add('Stage moved from ' + res.previousStageName + ' to ' + res.newStageName);
        }
        
        if (res.closeDateUpdated == true) {
            parts.add('Close date updated to ' + res.newCloseDate);
        }
        
        if (res.nextStepUpdated == true) {
            parts.add('Next step updated to: ' + res.newNextStep);
        }
        
        return parts.isEmpty() ? 'No changes made.' : String.join(parts, '. ') + '.';
    }
    
    public class ActionException extends Exception {}
}

