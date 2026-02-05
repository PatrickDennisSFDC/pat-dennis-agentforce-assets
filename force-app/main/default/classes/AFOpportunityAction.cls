/**
 * AF Opportunity Action
 * Consolidated invocable action for all Opportunity CRUD operations (Create, Read, Update, Delete, Find)
 * Supports OpportunityLineItem management within opportunity operations
 * Designed for Agentforce AI agents - optimized for sales rep pipeline management
 */
public without sharing class AFOpportunityAction {
    
    public class Request {
        @InvocableVariable(
            label='Operation'
            description='REQUIRED for summaries: "aggregate" for ANY question about totals, counts, averages, sums, or grouped data. "find" ONLY for listing individual deals. Other: "create", "read", "update", "delete". AGGREGATE TRIGGERS: total, sum, how many, count, average, biggest, smallest, by stage, pipeline breakdown. EXAMPLE: "whats my total pipeline" -> operation="aggregate" NOT "find".'
        )
        public String operation;
        
        // ========== AGGREGATE OPERATION PARAMETERS ==========
        @InvocableVariable(
            label='Aggregate Function'
            description='For aggregate operation: SUM (total pipeline), COUNT (how many deals), AVG (average deal size), MIN, MAX. Example: "SUM" for "what is my total pipeline", "COUNT" for "how many deals in negotiation".'
        )
        public String aggregateFunction;
        
        @InvocableVariable(
            label='Aggregate Field'
            description='For aggregate operation: Field to aggregate. Use "Amount" for pipeline totals, "Id" for counts. Example: "Amount" for SUM pipeline, "Id" for COUNT deals.'
        )
        public String aggregateField;
        
        @InvocableVariable(
            label='Group By Fields JSON'
            description='For aggregate operation: JSON array of fields to group by. Example: ["StageName"] for pipeline by stage, ["StageName","OwnerId"] for pipeline by stage and owner.'
        )
        public String groupByFieldsJson;
        
        @InvocableVariable(
            label='Date Range Field'
            description='For aggregate operation: Date field to filter on. Use "CloseDate" for opportunity close dates. Example: "CloseDate" for "deals closing this month".'
        )
        public String dateRangeField;
        
        @InvocableVariable(
            label='Date Range Predefined'
            description='For aggregate operation: Predefined date range - TODAY, THIS_WEEK, THIS_MONTH, THIS_QUARTER, THIS_YEAR, LAST_MONTH, LAST_QUARTER, LAST_N_DAYS, NEXT_N_DAYS. Example: "THIS_MONTH" for "closing this month", "THIS_QUARTER" for "this quarter".'
        )
        public String dateRangePredefined;
        
        @InvocableVariable(
            label='Date Range Days'
            description='For aggregate operation with LAST_N_DAYS or NEXT_N_DAYS: Number of days. Example: 30 for "last 30 days".'
        )
        public Integer dateRangeDays;
        
        @InvocableVariable(
            label='Date Range Start'
            description='For aggregate operation with SPECIFIC MONTH: Start date in YYYY-MM-DD format. Use INSTEAD OF dateRangePredefined for specific months. Example: "2026-03-01" for "opportunities closing in March". Must be used with dateRangeEnd.'
        )
        public String dateRangeStart;
        
        @InvocableVariable(
            label='Date Range End'
            description='For aggregate operation with SPECIFIC MONTH: End date in YYYY-MM-DD format. Use INSTEAD OF dateRangePredefined for specific months. Example: "2026-03-31" for "opportunities closing in March". Must be used with dateRangeStart.'
        )
        public String dateRangeEnd;
        
        @InvocableVariable(
            label='Field Data JSON'
            description='JSON string containing Opportunity field data. PIPELINE MANAGEMENT FOCUS: This action helps sales reps quickly update their deals. STAGE UPDATES: When user says "move to proposal" or "advance the deal" or "we are in negotiation now", map to StageName. Valid stages typically: Prospecting, Qualification, Needs Analysis, Value Proposition, Id. Decision Makers, Perception Analysis, Proposal/Price Quote, Negotiation/Review, Closed Won, Closed Lost. AMOUNT UPDATES: When user mentions dollar amounts like "$150K" or "deal is now worth 200 thousand", update Amount field. CLOSE DATE (CRITICAL FORMAT): When user says "pushing to next quarter", "end of February", "closing end of month", or "slipping to March", YOU MUST convert to YYYY-MM-DD format. Examples: "end of February" -> "2026-02-28", "end of March" -> "2026-03-31", "next Friday" -> calculate the actual date. NEVER pass natural language dates - always convert to YYYY-MM-DD. NEXT STEPS: Capture action items in NextStep field - "send proposal", "schedule demo", "get legal review". FORECAST: ForecastCategoryName values: Pipeline, Best Case, Commit, Omitted, Closed. For create: {"Name":"Memorial Hospital - Cardiology Expansion","StageName":"Qualification","CloseDate":"2026-03-31","Amount":150000}. For update: {"StageName":"Proposal/Price Quote","Amount":175000,"CloseDate":"2026-02-28","NextStep":"Send final proposal by Friday"}. IMPORTANT: For picklist fields, query availableFieldsJson from a previous read operation to see valid values.'
        )
        public String fieldDataJson;
        
        @InvocableVariable(
            label='Record ID'
            description='The Opportunity ID. Required for read/update/delete operations. When updating line items, this must be the OPPORTUNITY ID (starts with 006), NOT the line item ID. Line item IDs go in updateLineItemsJson.'
        )
        public Id recordId;
        
        @InvocableVariable(
            label='Search Term'
            description='Text to search for Opportunities. Searches: Opportunity Name, Account Name, Description. Flexible matching - partial names work. Examples: "Memorial Hospital" finds opps for that account, "Cardiology" finds opps with that in the name, "oncology treatment" finds related deals. For pipeline reviews, combine with filtersJson for stage filtering.'
        )
        public String searchTerm;
        
        @InvocableVariable(
            label='Filters JSON'
            description='JSON filters for find operations. PIPELINE USE CASES: {"StageName":"Proposal/Price Quote"} finds deals in proposal stage. {"ForecastCategoryName":"Commit"} finds committed deals. {"IsClosed":false} finds open deals only. Combine with searchTerm for refined results like "show me Memorial Hospital deals in negotiation".'
        )
        public String filtersJson;
        
        @InvocableVariable(
            label='Search Limit'
            description='Maximum records to return for find operations (default: 5, max: 20). For pipeline reviews, consider higher limits.'
        )
        public Integer searchLimit;
        
        @InvocableVariable(
            label='Account Name'
            description='Account name to resolve to AccountId. Use when creating opportunities or filtering by account. Fuzzy matching supported - "Memorial" will match "Memorial Regional Hospital".'
        )
        public String accountName;
        
        @InvocableVariable(
            label='Line Items JSON'
            description='JSON array of line items to create WITH a new opportunity. Format: [{"Product2Id":"01tXXX...","Quantity":10,"UnitPrice":450.00},{"PricebookEntryId":"01uXXX...","Quantity":5}]. Can use Product2Id or PricebookEntryId. If using Product2Id, system will find the Standard Pricebook entry.'
            required=false
        )
        public String lineItemsJson;
        
        @InvocableVariable(
            label='Add Line Items JSON'
            description='JSON array of NEW line items to add to an existing opportunity. Format: [{"Product2Id":"01tXXX...","Quantity":10,"UnitPrice":450.00}]. For product names, use productName parameter or include in JSON. Example with product name: [{"productName":"Cardiomax 100mg","Quantity":50,"UnitPrice":650}].'
            required=false
        )
        public String addLineItemsJson;
        
        @InvocableVariable(
            label='Update Line Items JSON'
            description='JSON array of line items to update. Put OPPORTUNITY ID in recordId, LINE ITEM IDs here. Format: [{"Id":"00kXXX...","Quantity":150},{"Id":"00kYYY...","UnitPrice":500}]. Get line item IDs from a previous read operation.'
            required=false
        )
        public String updateLineItemsJson;
        
        @InvocableVariable(
            label='Delete Line Item IDs'
            description='JSON array of line item IDs to remove from the opportunity. Format: ["00kXXX...","00kYYY..."]. Use for removing products from a deal.'
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
            description='The Opportunity record (for single record operations).'
        )
        public Opportunity record;
        
        @InvocableVariable(
            label='Records'
            description='List of Opportunity records (for bulk or find operations).'
        )
        public List<Opportunity> records;
        
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
            description='The Salesforce object type, always "Opportunity" for Opportunity operations.'
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
            description='JSON string containing metadata for all available fields including picklist values.'
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
            description='Number of Opportunity records found in a find/search operation.'
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
            description='List of OpportunityLineItem records for the opportunity. Includes Product name, quantity, price, and totals.'
        )
        public List<OpportunityLineItem> lineItems;
        
        @InvocableVariable(
            label='Line Item Count'
            description='Number of line items (products) on the opportunity.'
        )
        public Integer lineItemCount;
        
        @InvocableVariable(
            label='Total Line Item Amount'
            description='Sum of all line item totals. May differ from Opportunity Amount if manually overridden.'
        )
        public Decimal totalLineItemAmount;
        
        @InvocableVariable(
            label='Related Account Name'
            description='Name of the Account associated with this Opportunity.'
        )
        public String relatedAccountName;
        
        // ========== AGGREGATE OPERATION RESPONSE FIELDS ==========
        @InvocableVariable(
            label='Aggregate Results JSON'
            description='For aggregate operation: JSON array of results. Format: [{"groupByFields":{"StageName":"Negotiation"},"aggregateValue":500000,"recordCount":5},...]. Use to present pipeline breakdown to user.'
        )
        public String aggregateResultsJson;
        
        @InvocableVariable(
            label='Total Value'
            description='For aggregate operation: Total aggregate value across all groups. For SUM Amount, this is total pipeline. For COUNT, this is total number of deals.'
        )
        public Decimal totalValue;
        
        @InvocableVariable(
            label='Group Count'
            description='For aggregate operation: Number of groups in results. Example: If grouping by stage and there are 5 stages with data, groupCount is 5.'
        )
        public Integer groupCount;
        
        @InvocableVariable(
            label='Query Description'
            description='For aggregate operation: Human-readable description of the analytics query executed.'
        )
        public String queryDescription;
    }
    
    private static String inferOperation(Request req) {
        if (!String.isBlank(req.operation)) {
            return req.operation.trim().toLowerCase();
        }
        
        Boolean hasRecordId = req.recordId != null;
        Boolean hasFieldData = !String.isBlank(req.fieldDataJson);
        Boolean hasSearchTerm = !String.isBlank(req.searchTerm);
        Boolean hasFilters = !String.isBlank(req.filtersJson);
        Boolean hasLineItemOps = !String.isBlank(req.addLineItemsJson) || !String.isBlank(req.updateLineItemsJson) || !String.isBlank(req.deleteLineItemIds);
        Boolean hasAggregateParams = !String.isBlank(req.aggregateFunction);
        
        // Aggregate operation detected by presence of aggregateFunction
        if (hasAggregateParams) return 'aggregate';
        
        // UPDATE: recordId + fieldData, OR searchTerm + fieldData (find-then-update pattern)
        if (hasRecordId && (hasFieldData || hasLineItemOps)) return 'update';
        if (hasSearchTerm && hasFieldData) return 'update';  // Find by name, then update
        if (hasSearchTerm && hasLineItemOps) return 'update'; // Find by name, update line items
        
        // READ: recordId only
        if (hasRecordId && !hasFieldData && !hasSearchTerm && !hasFilters) return 'read';
        
        // CREATE: fieldData without recordId or searchTerm (brand new record)
        if (hasFieldData && !hasRecordId && !hasSearchTerm) return 'create';
        
        // FIND: searchTerm or filters
        if (hasSearchTerm || hasFilters) return 'find';
        
        // DELETE: recordId with confirm
        if (hasRecordId && req.confirm != null && req.confirm == true) return 'delete';
        
        throw new AFUniversalCrmRecordAction.ActionException('Cannot infer operation. Please specify operation parameter or provide sufficient context.');
    }
    
    @InvocableMethod(
        label='Agentforce Opportunity Action'
        description='PIPELINE MANAGEMENT for sales reps. PIPELINE = OPEN DEALS: By default, all pipeline queries (aggregate and find) filter to IsClosed=false. This ensures aggregate counts match find results. To include closed deals, explicitly add filtersJson with IsClosed. CRITICAL ROUTING: For SUMMARY/TOTAL/COUNT questions, use AGGREGATE operation (not FIND). AGGREGATE TRIGGERS: "total pipeline", "how many deals", "how much", "average deal", "biggest deal", "pipeline by stage", "count", "sum", "number of" -> operation=aggregate. AGGREGATE SETUP: aggregateFunction=SUM for totals, COUNT for counts, AVG for averages, MAX for biggest, MIN for smallest. aggregateField=Amount for dollar values, Id for counting records. groupByFieldsJson=["StageName"] for "by stage". DATE FILTERING: ALWAYS set dateRangeField=CloseDate when user mentions dates. For "this month/quarter" use dateRangePredefined=THIS_MONTH or THIS_QUARTER. FOR SPECIFIC MONTHS like "March" or "January 2026": use dateRangeStart and dateRangeEnd with YYYY-MM-DD format. EXAMPLE: "March 2026" -> dateRangeField=CloseDate dateRangeStart=2026-03-01 dateRangeEnd=2026-03-31. "February" -> dateRangeStart=2026-02-01 dateRangeEnd=2026-02-28. AGGREGATE EXAMPLES: "Total pipeline" -> aggregateFunction=SUM aggregateField=Amount. "Pipeline for March" -> aggregateFunction=SUM aggregateField=Amount dateRangeField=CloseDate dateRangeStart=2026-03-01 dateRangeEnd=2026-03-31. "How many deals closing in Q1" -> aggregateFunction=COUNT aggregateField=Id dateRangeField=CloseDate dateRangePredefined=THIS_QUARTER. CLOSED DEALS: For "closed won this quarter" or "all deals including closed", add filtersJson=[{"fieldApiName":"IsClosed","value":"true"}] or filtersJson=[{"fieldApiName":"StageName","value":"Closed Won"}]. FIND TRIGGERS (list individual records): "show me deals", "list opportunities", "what deals are in...", "find deals". OTHER: CREATE new deals, UPDATE changes, DELETE remove. LINE ITEMS: addLineItemsJson to add products.'
        category='CRM Actions'
    )
    public static List<Response> opportunityAction(List<Request> requests) {
        List<Response> responses = new List<Response>();
        
        for (Request req : requests) {
            Response res = new Response();
            res.objectType = 'Opportunity';
            res.success = false;
            res.records = new List<Opportunity>();
            res.totalMatches = 0;
            res.ambiguous = false;
            res.moreResultsAvailable = false;
            res.confirmationRequired = false;
            res.lineItems = new List<OpportunityLineItem>();
            res.lineItemCount = 0;
            res.totalLineItemAmount = 0;
            
            try {
                String op = inferOperation(req);
                res.operation = op;
                
                // Handle delete confirmation
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
                        List<Opportunity> opps = [SELECT Id, Name, Amount, StageName FROM Opportunity WHERE Id = :req.recordId LIMIT 1];
                        if (!opps.isEmpty()) {
                            Opportunity opp = opps[0];
                            String amtStr = opp.Amount != null ? ' ($' + opp.Amount.format() + ')' : '';
                            res.message = 'This will delete Opportunity "' + opp.Name + '"' + amtStr + ' in stage ' + opp.StageName + ' and all related records including line items. Call again with confirm=true to proceed.';
                            res.success = true;
                        } else {
                            res.message = 'Opportunity not found with ID ' + req.recordId + '.';
                            res.errorMessage = res.message;
                            res.success = false;
                        }
                    } catch (Exception e) {
                        res.message = 'This will delete the Opportunity and all related records. Call again with confirm=true to proceed.';
                        res.success = true;
                    }
                    responses.add(res);
                    continue;
                }
                
                // Handle AGGREGATE operation - delegates to AFUniversalAnalyticsAction
                if (op == 'aggregate') {
                    AFUniversalAnalyticsAction.Request analyticsReq = new AFUniversalAnalyticsAction.Request();
                    analyticsReq.objectApiName = 'Opportunity';
                    
                    // Apply intelligent defaults for Opportunity aggregations
                    // Default to SUM Amount if no aggregate function specified (common "total pipeline" query)
                    String aggFunc = req.aggregateFunction;
                    String aggField = req.aggregateField;
                    
                    if (String.isBlank(aggFunc)) {
                        aggFunc = 'SUM';  // Default to SUM for opportunities
                    }
                    if (String.isBlank(aggField)) {
                        // Default field based on function
                        if (aggFunc.equalsIgnoreCase('COUNT')) {
                            aggField = 'Id';
                        } else {
                            aggField = 'Amount';  // SUM, AVG, MIN, MAX default to Amount
                        }
                    }
                    
                    analyticsReq.aggregateFunction = aggFunc;
                    analyticsReq.aggregateField = aggField;
                    analyticsReq.groupByFieldsJson = req.groupByFieldsJson;
                    analyticsReq.dateRangeField = req.dateRangeField;
                    analyticsReq.dateRangePredefined = req.dateRangePredefined;
                    analyticsReq.dateRangeDays = req.dateRangeDays;
                    analyticsReq.dateRangeStart = req.dateRangeStart;
                    analyticsReq.dateRangeEnd = req.dateRangeEnd;
                    
                    // PIPELINE DEFAULT: "Pipeline" semantically means OPEN opportunities.
                    // Default to IsClosed = false unless explicitly specified in filtersJson.
                    // This ensures aggregate counts match find results for pipeline queries.
                    String filtersToUse = req.filtersJson;
                    Boolean hasIsClosedFilter = !String.isBlank(filtersToUse) && 
                                                 filtersToUse.toLowerCase().contains('isclosed');
                    
                    if (!hasIsClosedFilter) {
                        // Add IsClosed = false filter for pipeline queries
                        if (String.isBlank(filtersToUse)) {
                            filtersToUse = '[{"fieldApiName":"IsClosed","value":"false"}]';
                        } else {
                            // Merge with existing filters
                            try {
                                Object parsed = JSON.deserializeUntyped(filtersToUse);
                                List<Object> filterList;
                                if (parsed instanceof List<Object>) {
                                    filterList = (List<Object>) parsed;
                                } else {
                                    filterList = new List<Object>{ parsed };
                                }
                                Map<String, Object> isClosedFilter = new Map<String, Object>{
                                    'fieldApiName' => 'IsClosed',
                                    'value' => 'false'
                                };
                                filterList.add(isClosedFilter);
                                filtersToUse = JSON.serialize(filterList);
                            } catch (Exception e) {
                                // If parsing fails, just use the IsClosed filter alone
                                System.debug(LoggingLevel.WARN, 'AFOpportunityAction: Could not parse filtersJson, using IsClosed filter only: ' + e.getMessage());
                                filtersToUse = '[{"fieldApiName":"IsClosed","value":"false"}]';
                            }
                        }
                        System.debug(LoggingLevel.INFO, 'AFOpportunityAction: Added default IsClosed=false filter for pipeline aggregate');
                    }
                    
                    analyticsReq.filtersJson = filtersToUse;
                    
                    List<AFUniversalAnalyticsAction.Response> analyticsResponses = 
                        AFUniversalAnalyticsAction.executeAnalytics(new List<AFUniversalAnalyticsAction.Request>{ analyticsReq });
                    
                    if (!analyticsResponses.isEmpty()) {
                        AFUniversalAnalyticsAction.Response analyticsRes = analyticsResponses[0];
                        res.success = analyticsRes.success;
                        res.message = analyticsRes.message;
                        res.errorMessage = analyticsRes.errorMessage;
                        res.aggregateResultsJson = analyticsRes.aggregateResultsJson;
                        res.totalValue = analyticsRes.totalValue;
                        res.groupCount = analyticsRes.groupCount;
                        res.totalMatches = analyticsRes.recordCount;
                        res.queryDescription = analyticsRes.queryDescription;
                    } else {
                        res.success = false;
                        res.errorMessage = 'Analytics query returned no response.';
                    }
                    responses.add(res);
                    continue;
                }
                
                // Handle CREATE operation
                if (op == 'create') {
                    AFUniversalCrmRecordAction.Request actionReq = new AFUniversalCrmRecordAction.Request();
                    actionReq.objectApiName = 'Opportunity';
                    actionReq.operation = 'create';
                    actionReq.fieldDataJson = req.fieldDataJson;
                    actionReq.accountName = req.accountName;
                    actionReq.confirm = req.confirm;
                    
                    AFUniversalCrmRecordAction.Response actionRes = AFUniversalCrmRecordAction.processRequest(actionReq);
                    
                    if (actionRes.success && actionRes.recordId != null) {
                        res.success = true;
                        res.message = actionRes.message != null ? actionRes.message : 'Opportunity created successfully.';
                        res.record = (Opportunity) actionRes.record;
                        res.recordId = actionRes.recordId;
                        res.records = new List<Opportunity>{ res.record };
                        res.previewOnly = actionRes.previewOnly != null ? actionRes.previewOnly : false;
                        res.availableFieldsJson = actionRes.availableFieldsJson;
                        res.ambiguousRelationship = actionRes.ambiguousRelationship != null ? actionRes.ambiguousRelationship : false;
                        res.ambiguousRelationshipType = actionRes.ambiguousRelationshipType;
                        res.relationshipCandidatesJson = actionRes.relationshipCandidatesJson;
                        
                        // Handle line items creation if provided
                        if (!String.isBlank(req.lineItemsJson) && res.recordId != null && !res.previewOnly) {
                            try {
                                List<OpportunityLineItem> createdItems = createLineItems(res.recordId, req.lineItemsJson);
                                res.lineItems = createdItems;
                                res.lineItemCount = createdItems.size();
                                res.message = res.message + ' Added ' + createdItems.size() + ' product' + (createdItems.size() > 1 ? 's' : '') + ' to the opportunity.';
                                
                                // Calculate total
                                Decimal total = 0;
                                for (OpportunityLineItem item : createdItems) {
                                    if (item.TotalPrice != null) total += item.TotalPrice;
                                }
                                res.totalLineItemAmount = total;
                            } catch (Exception e) {
                                System.debug(LoggingLevel.ERROR, 'AFOpportunityAction: Error creating line items: ' + e.getMessage());
                                res.message = res.message + ' Note: Could not add line items - ' + e.getMessage();
                            }
                        }
                        
                        // Get account name
                        if (res.record != null && res.record.AccountId != null) {
                            try {
                                Account acc = [SELECT Name FROM Account WHERE Id = :res.record.AccountId LIMIT 1];
                                res.relatedAccountName = acc.Name;
                            } catch (Exception e) {
                                // Ignore
                            }
                        }
                    } else {
                        res.success = false;
                        res.errorMessage = actionRes.message != null ? actionRes.message : 'Failed to create Opportunity.';
                    }
                    responses.add(res);
                    continue;
                }
                
                // Handle READ operation
                if (op == 'read') {
                    AFUniversalCrmRecordAction.Request actionReq = new AFUniversalCrmRecordAction.Request();
                    actionReq.objectApiName = 'Opportunity';
                    actionReq.operation = 'read';
                    actionReq.recordId = req.recordId;
                    
                    AFUniversalCrmRecordAction.Response actionRes = AFUniversalCrmRecordAction.processRequest(actionReq);
                    
                    if (actionRes.success && actionRes.record != null) {
                        res.success = true;
                        res.record = (Opportunity) actionRes.record;
                        res.recordId = actionRes.recordId;
                        res.availableFieldsJson = actionRes.availableFieldsJson;
                        
                        // Fetch line items with product details
                        try {
                            List<OpportunityLineItem> items = [
                                SELECT Id, Name, Product2Id, Product2.Name, Product2.ProductCode, 
                                       Quantity, UnitPrice, TotalPrice, Description,
                                       ServiceDate, ListPrice, Discount
                                FROM OpportunityLineItem 
                                WHERE OpportunityId = :res.recordId 
                                ORDER BY SortOrder, CreatedDate
                            ];
                            res.lineItems = items;
                            res.lineItemCount = items.size();
                            
                            // Calculate total
                            Decimal total = 0;
                            for (OpportunityLineItem item : items) {
                                if (item.TotalPrice != null) total += item.TotalPrice;
                            }
                            res.totalLineItemAmount = total;
                            
                            res.message = 'Opportunity retrieved. ' + items.size() + ' product' + (items.size() != 1 ? 's' : '') + ' on this deal.';
                        } catch (Exception e) {
                            res.message = 'Opportunity retrieved.';
                            System.debug(LoggingLevel.ERROR, 'AFOpportunityAction: Error fetching line items: ' + e.getMessage());
                        }
                        
                        // Get account name
                        try {
                            Opportunity opp = [SELECT Account.Name FROM Opportunity WHERE Id = :res.recordId LIMIT 1];
                            res.relatedAccountName = opp.Account != null ? opp.Account.Name : null;
                        } catch (Exception e) {
                            // Ignore
                        }
                    } else {
                        res.success = false;
                        res.errorMessage = actionRes.message != null ? actionRes.message : 'Opportunity not found.';
                    }
                    responses.add(res);
                    continue;
                }
                
                // Handle UPDATE operation
                if (op == 'update') {
                    Id targetRecordId = req.recordId;
                    
                    // Find-then-update pattern: resolve record by search term if no recordId provided
                    if (targetRecordId == null && !String.isBlank(req.searchTerm)) {
                        AFUniversalCrmRecordAction.Request findReq = new AFUniversalCrmRecordAction.Request();
                        findReq.objectApiName = 'Opportunity';
                        findReq.operation = 'find';
                        findReq.searchTerm = req.searchTerm;
                        findReq.searchLimit = 5;
                        
                        AFUniversalCrmRecordAction.Response findRes = AFUniversalCrmRecordAction.processRequest(findReq);
                        
                        if (findRes.success && findRes.records != null && !findRes.records.isEmpty()) {
                            if (findRes.records.size() == 1) {
                                // Exactly one match - proceed with update
                                targetRecordId = findRes.records[0].Id;
                            } else {
                                // Multiple matches - ask for clarification
                                res.success = false;
                                res.ambiguous = true;
                                List<String> names = new List<String>();
                                for (SObject rec : findRes.records) {
                                    names.add((String)rec.get('Name'));
                                }
                                res.errorMessage = 'Found multiple matching opportunities: ' + String.join(names, ', ') + '. Please be more specific.';
                                responses.add(res);
                                continue;
                            }
                        } else {
                            res.success = false;
                            res.errorMessage = 'Could not find an opportunity matching "' + req.searchTerm + '". Please check the name and try again.';
                            responses.add(res);
                            continue;
                        }
                    }
                    
                    if (targetRecordId == null) {
                        res.success = false;
                        res.errorMessage = 'Record ID or search term is required for update operation.';
                        responses.add(res);
                        continue;
                    }
                    
                    AFUniversalCrmRecordAction.Request actionReq = new AFUniversalCrmRecordAction.Request();
                    actionReq.objectApiName = 'Opportunity';
                    actionReq.operation = 'update';
                    actionReq.recordId = targetRecordId;
                    actionReq.fieldDataJson = req.fieldDataJson;
                    actionReq.accountName = req.accountName;
                    actionReq.confirm = req.confirm;
                    
                    AFUniversalCrmRecordAction.Response actionRes = AFUniversalCrmRecordAction.processRequest(actionReq);
                    
                    if (actionRes.success) {
                        res.success = true;
                        res.message = actionRes.message != null ? actionRes.message : 'Opportunity updated successfully.';
                        res.record = (Opportunity) actionRes.record;
                        res.recordId = actionRes.recordId;
                        res.previewOnly = actionRes.previewOnly != null ? actionRes.previewOnly : false;
                        res.availableFieldsJson = actionRes.availableFieldsJson;
                        res.ambiguousRelationship = actionRes.ambiguousRelationship != null ? actionRes.ambiguousRelationship : false;
                        res.ambiguousRelationshipType = actionRes.ambiguousRelationshipType;
                        res.relationshipCandidatesJson = actionRes.relationshipCandidatesJson;
                        
                        // Handle line item operations if provided
                        if (res.recordId != null && !res.previewOnly) {
                            List<String> lineItemMessages = new List<String>();
                            
                            // Add new line items
                            if (!String.isBlank(req.addLineItemsJson)) {
                                try {
                                    List<OpportunityLineItem> addedItems = createLineItems(res.recordId, req.addLineItemsJson);
                                    lineItemMessages.add('Added ' + addedItems.size() + ' product' + (addedItems.size() > 1 ? 's' : ''));
                                } catch (Exception e) {
                                    lineItemMessages.add('Could not add products: ' + e.getMessage());
                                }
                            }
                            
                            // Update existing line items
                            if (!String.isBlank(req.updateLineItemsJson)) {
                                try {
                                    Integer updated = updateLineItems(req.updateLineItemsJson);
                                    lineItemMessages.add('Updated ' + updated + ' product' + (updated > 1 ? 's' : ''));
                                } catch (Exception e) {
                                    lineItemMessages.add('Could not update products: ' + e.getMessage());
                                }
                            }
                            
                            // Delete line items
                            if (!String.isBlank(req.deleteLineItemIds)) {
                                try {
                                    Integer deleted = deleteLineItems(req.deleteLineItemIds);
                                    lineItemMessages.add('Removed ' + deleted + ' product' + (deleted > 1 ? 's' : ''));
                                } catch (Exception e) {
                                    lineItemMessages.add('Could not remove products: ' + e.getMessage());
                                }
                            }
                            
                            if (!lineItemMessages.isEmpty()) {
                                res.message = res.message + ' ' + String.join(lineItemMessages, '. ') + '.';
                            }
                        }
                        
                        // Fetch current line items
                        if (res.recordId != null) {
                            try {
                                List<OpportunityLineItem> items = [
                                    SELECT Id, Name, Product2Id, Product2.Name, Product2.ProductCode, 
                                           Quantity, UnitPrice, TotalPrice, Description
                                    FROM OpportunityLineItem 
                                    WHERE OpportunityId = :res.recordId 
                                    ORDER BY SortOrder, CreatedDate
                                ];
                                res.lineItems = items;
                                res.lineItemCount = items.size();
                                
                                Decimal total = 0;
                                for (OpportunityLineItem item : items) {
                                    if (item.TotalPrice != null) total += item.TotalPrice;
                                }
                                res.totalLineItemAmount = total;
                            } catch (Exception e) {
                                System.debug(LoggingLevel.DEBUG, 'AFOpportunityAction: Could not fetch line items');
                            }
                        }
                    } else {
                        res.success = false;
                        res.errorMessage = actionRes.message != null ? actionRes.message : 'Failed to update Opportunity.';
                    }
                    responses.add(res);
                    continue;
                }
                
                // Handle FIND operation
                if (op == 'find' || op == 'search') {
                    // Check if date range parameters are provided - use direct query for date-filtered finds
                    Boolean hasDateFilter = !String.isBlank(req.dateRangePredefined) || 
                                           !String.isBlank(req.dateRangeStart) || 
                                           !String.isBlank(req.dateRangeEnd);
                    
                    if (hasDateFilter) {
                        // Handle date-filtered find directly with custom SOQL
                        try {
                            List<Opportunity> results = executeDateFilteredFind(req);
                            res.success = true;
                            res.totalMatches = results.size();
                            
                            if (results.isEmpty()) {
                                res.message = 'No opportunities found matching your criteria.';
                                res.records = new List<Opportunity>();
                            } else if (results.size() == 1) {
                                res.record = results[0];
                                res.recordId = results[0].Id;
                                res.records = results;
                                res.message = 'Found 1 opportunity.';
                                res.relatedAccountName = results[0].Account != null ? results[0].Account.Name : null;
                                
                                // Fetch line items for single result
                                try {
                                    List<OpportunityLineItem> items = [
                                        SELECT Id, Name, Product2Id, Product2.Name, Product2.ProductCode, 
                                               Quantity, UnitPrice, TotalPrice
                                        FROM OpportunityLineItem 
                                        WHERE OpportunityId = :res.recordId 
                                        ORDER BY SortOrder, CreatedDate
                                    ];
                                    res.lineItems = items;
                                    res.lineItemCount = items.size();
                                    Decimal total = 0;
                                    for (OpportunityLineItem item : items) {
                                        if (item.TotalPrice != null) total += item.TotalPrice;
                                    }
                                    res.totalLineItemAmount = total;
                                } catch (Exception e) {
                                    System.debug(LoggingLevel.DEBUG, 'AFOpportunityAction: Could not fetch line items');
                                }
                            } else {
                                res.records = results;
                                res.ambiguous = true;
                                res.message = 'Found ' + results.size() + ' opportunities.';
                                Integer searchLimit = req.searchLimit != null ? req.searchLimit : 10;
                                res.moreResultsAvailable = results.size() >= searchLimit;
                            }
                        } catch (Exception e) {
                            res.success = false;
                            res.errorMessage = 'Error searching opportunities: ' + e.getMessage();
                            System.debug(LoggingLevel.ERROR, 'AFOpportunityAction: Date-filtered find error: ' + e.getMessage());
                        }
                        responses.add(res);
                        continue;
                    }
                    
                    // Standard find without date filtering - delegate to AFUniversalCrmRecordAction
                    AFUniversalCrmRecordAction.Request actionReq = new AFUniversalCrmRecordAction.Request();
                    actionReq.objectApiName = 'Opportunity';
                    actionReq.operation = 'find';
                    actionReq.searchTerm = req.searchTerm;
                    actionReq.filtersJson = req.filtersJson;
                    actionReq.searchLimit = req.searchLimit;
                    actionReq.accountName = req.accountName;
                    
                    AFUniversalCrmRecordAction.Response actionRes = AFUniversalCrmRecordAction.processRequest(actionReq);
                    
                    if (actionRes.success) {
                        res.success = true;
                        res.message = actionRes.message != null ? actionRes.message : 'Search completed.';
                        res.ambiguous = actionRes.ambiguous != null ? actionRes.ambiguous : false;
                        res.totalMatches = actionRes.totalMatches != null ? actionRes.totalMatches : 0;
                        
                        if (actionRes.record != null) {
                            res.record = (Opportunity) actionRes.record;
                            res.recordId = res.record.Id;
                            res.records = new List<Opportunity>{ res.record };
                            
                            // Fetch line items for single result
                            try {
                                List<OpportunityLineItem> items = [
                                    SELECT Id, Name, Product2Id, Product2.Name, Product2.ProductCode, 
                                           Quantity, UnitPrice, TotalPrice
                                    FROM OpportunityLineItem 
                                    WHERE OpportunityId = :res.recordId 
                                    ORDER BY SortOrder, CreatedDate
                                ];
                                res.lineItems = items;
                                res.lineItemCount = items.size();
                                
                                Decimal total = 0;
                                for (OpportunityLineItem item : items) {
                                    if (item.TotalPrice != null) total += item.TotalPrice;
                                }
                                res.totalLineItemAmount = total;
                            } catch (Exception e) {
                                System.debug(LoggingLevel.DEBUG, 'AFOpportunityAction: Could not fetch line items for find result');
                            }
                            
                            // Get account name
                            try {
                                Opportunity opp = [SELECT Account.Name FROM Opportunity WHERE Id = :res.recordId LIMIT 1];
                                res.relatedAccountName = opp.Account != null ? opp.Account.Name : null;
                            } catch (Exception e) {
                                // Ignore
                            }
                        } else if (actionRes.records != null && !actionRes.records.isEmpty()) {
                            res.records = new List<Opportunity>();
                            for (SObject so : actionRes.records) {
                                res.records.add((Opportunity) so);
                            }
                            if (res.records.size() == 1) {
                                res.record = res.records[0];
                                res.recordId = res.records[0].Id;
                            } else if (!res.records.isEmpty()) {
                                res.ambiguous = true;
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
                
                // Handle DELETE operation (confirmed)
                if (op == 'delete' && req.confirm == true) {
                    AFUniversalCrmRecordAction.Request actionReq = new AFUniversalCrmRecordAction.Request();
                    actionReq.objectApiName = 'Opportunity';
                    actionReq.operation = 'delete';
                    actionReq.recordId = req.recordId;
                    
                    AFUniversalCrmRecordAction.Response actionRes = AFUniversalCrmRecordAction.processRequest(actionReq);
                    
                    if (actionRes.success) {
                        res.success = true;
                        res.recordId = actionRes.recordId;
                        res.message = actionRes.message != null ? actionRes.message : 'Opportunity deleted successfully.';
                    } else {
                        res.success = false;
                        res.errorMessage = actionRes.message != null ? actionRes.message : 'Failed to delete Opportunity.';
                    }
                    responses.add(res);
                    continue;
                }
                
            } catch (AFUniversalCrmRecordAction.ActionException ae) {
                res.success = false;
                res.errorMessage = ae.getMessage();
                System.debug(LoggingLevel.ERROR, 'AFOpportunityAction: ActionException - ' + ae.getMessage());
            } catch (Exception e) {
                res.success = false;
                res.errorMessage = 'Error performing Opportunity operation: ' + e.getMessage();
                System.debug(LoggingLevel.ERROR, 'AFOpportunityAction: Exception - ' + e.getMessage());
            }
            
            responses.add(res);
        }
        
        return responses;
    }
    
    /**
     * Execute a date-filtered find query for opportunities.
     * This handles THIS_MONTH, THIS_QUARTER, and custom date ranges for find operations.
     * PIPELINE DEFAULT: Defaults to IsClosed = false unless explicitly specified.
     */
    private static List<Opportunity> executeDateFilteredFind(Request req) {
        // Build the SOQL query
        String soql = 'SELECT Id, Name, StageName, Amount, CloseDate, Probability, ' +
                     'ForecastCategoryName, NextStep, Description, Account.Name, AccountId, ' +
                     'IsClosed, IsWon, Type, CreatedDate, LastModifiedDate ' +
                     'FROM Opportunity';
        
        List<String> whereClauses = new List<String>();
        
        // Build date filter clause
        String dateField = String.isBlank(req.dateRangeField) ? 'CloseDate' : req.dateRangeField;
        
        if (!String.isBlank(req.dateRangePredefined)) {
            String predefined = req.dateRangePredefined.toUpperCase();
            
            // Validate predefined range
            Set<String> validRanges = new Set<String>{
                'TODAY', 'YESTERDAY', 'THIS_WEEK', 'LAST_WEEK', 'THIS_MONTH', 
                'LAST_MONTH', 'THIS_QUARTER', 'LAST_QUARTER', 'THIS_YEAR', 'LAST_YEAR',
                'LAST_N_DAYS', 'NEXT_N_DAYS'
            };
            
            if (predefined == 'LAST_N_DAYS' || predefined == 'NEXT_N_DAYS') {
                Integer days = req.dateRangeDays != null ? req.dateRangeDays : 30;
                whereClauses.add(dateField + ' = ' + predefined + ':' + days);
            } else if (validRanges.contains(predefined)) {
                whereClauses.add(dateField + ' = ' + predefined);
            } else {
                throw new AFUniversalCrmRecordAction.ActionException('Invalid date range: ' + req.dateRangePredefined);
            }
        } else if (!String.isBlank(req.dateRangeStart) && !String.isBlank(req.dateRangeEnd)) {
            // Custom date range
            Date startDate = Date.valueOf(req.dateRangeStart);
            Date endDate = Date.valueOf(req.dateRangeEnd);
            whereClauses.add(dateField + ' >= ' + String.valueOf(startDate));
            whereClauses.add(dateField + ' <= ' + String.valueOf(endDate));
        }
        
        // Track if IsClosed filter is explicitly provided
        Boolean hasExplicitIsClosedFilter = false;
        
        // Process filtersJson for explicit filters
        if (!String.isBlank(req.filtersJson)) {
            try {
                Object parsed = JSON.deserializeUntyped(req.filtersJson);
                if (parsed instanceof Map<String, Object>) {
                    Map<String, Object> filters = (Map<String, Object>) parsed;
                    for (String fieldName : filters.keySet()) {
                        Object value = filters.get(fieldName);
                        if (fieldName.equalsIgnoreCase('IsClosed')) {
                            whereClauses.add('IsClosed = ' + (Boolean.valueOf(String.valueOf(value)) ? 'true' : 'false'));
                            hasExplicitIsClosedFilter = true;
                        } else if (fieldName.equalsIgnoreCase('StageName')) {
                            whereClauses.add('StageName = \'' + String.escapeSingleQuotes(String.valueOf(value)) + '\'');
                        } else if (fieldName.equalsIgnoreCase('ForecastCategoryName')) {
                            whereClauses.add('ForecastCategoryName = \'' + String.escapeSingleQuotes(String.valueOf(value)) + '\'');
                        }
                    }
                }
            } catch (Exception e) {
                System.debug(LoggingLevel.WARN, 'AFOpportunityAction: Could not parse filtersJson: ' + e.getMessage());
            }
        }
        
        // PIPELINE DEFAULT: Add IsClosed = false if not explicitly specified.
        // This ensures find results match aggregate counts for pipeline queries.
        if (!hasExplicitIsClosedFilter) {
            whereClauses.add('IsClosed = false');
            System.debug(LoggingLevel.INFO, 'AFOpportunityAction: Added default IsClosed=false filter for pipeline find');
        }
        
        // Add search term filter if provided
        if (!String.isBlank(req.searchTerm)) {
            String searchTerm = '%' + String.escapeSingleQuotes(req.searchTerm) + '%';
            whereClauses.add('(Name LIKE \'' + searchTerm + '\' OR Account.Name LIKE \'' + searchTerm + '\')');
        }
        
        // Combine WHERE clauses
        if (!whereClauses.isEmpty()) {
            soql += ' WHERE ' + String.join(whereClauses, ' AND ');
        }
        
        // Add ORDER BY and LIMIT
        soql += ' ORDER BY CloseDate ASC, Amount DESC';
        Integer limitVal = req.searchLimit != null ? Math.min(req.searchLimit, 20) : 10;
        soql += ' LIMIT ' + limitVal;
        
        System.debug(LoggingLevel.INFO, 'AFOpportunityAction: Date-filtered find query: ' + soql);
        
        return Database.query(soql);
    }
    
    /**
     * Create OpportunityLineItems from JSON array
     */
    private static List<OpportunityLineItem> createLineItems(Id opportunityId, String lineItemsJson) {
        List<Object> itemsData = (List<Object>) JSON.deserializeUntyped(lineItemsJson);
        List<OpportunityLineItem> itemsToCreate = new List<OpportunityLineItem>();
        
        // Get the opportunity's pricebook
        Opportunity opp = [SELECT Pricebook2Id FROM Opportunity WHERE Id = :opportunityId LIMIT 1];
        Id pricebookId = opp.Pricebook2Id;
        
        // If no pricebook, use standard
        if (pricebookId == null) {
            Pricebook2 stdPb = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
            pricebookId = stdPb.Id;
            opp.Pricebook2Id = pricebookId;
            update opp;
        }
        
        // Collect product names/IDs for lookup
        Set<String> productNames = new Set<String>();
        Set<Id> productIds = new Set<Id>();
        Set<Id> pbeIds = new Set<Id>();
        
        for (Object itemObj : itemsData) {
            Map<String, Object> itemMap = (Map<String, Object>) itemObj;
            if (itemMap.containsKey('productName')) {
                productNames.add((String) itemMap.get('productName'));
            }
            if (itemMap.containsKey('Product2Id')) {
                try {
                    productIds.add((Id) itemMap.get('Product2Id'));
                } catch (Exception e) {
                    // Invalid ID format
                }
            }
            if (itemMap.containsKey('PricebookEntryId')) {
                try {
                    pbeIds.add((Id) itemMap.get('PricebookEntryId'));
                } catch (Exception e) {
                    // Invalid ID format
                }
            }
        }
        
        // Build maps for lookups - load ALL active products for fuzzy matching
        Map<String, PricebookEntry> pbeByProductNameExact = new Map<String, PricebookEntry>();
        Map<String, PricebookEntry> pbeByProductNameNormalized = new Map<String, PricebookEntry>();
        Map<Id, PricebookEntry> pbeByProductId = new Map<Id, PricebookEntry>();
        List<PricebookEntry> allPricebookEntries = new List<PricebookEntry>();
        
        // Load all active pricebook entries for fuzzy matching
        for (PricebookEntry pbe : [
            SELECT Id, Product2Id, Product2.Name, Product2.ProductCode, UnitPrice 
            FROM PricebookEntry 
            WHERE Pricebook2Id = :pricebookId AND IsActive = true
        ]) {
            String exactName = pbe.Product2.Name.toLowerCase();
            String normalizedName = normalizeProductName(pbe.Product2.Name);
            pbeByProductNameExact.put(exactName, pbe);
            pbeByProductNameNormalized.put(normalizedName, pbe);
            pbeByProductId.put(pbe.Product2Id, pbe);
            allPricebookEntries.add(pbe);
        }
        
        // Create line items
        for (Object itemObj : itemsData) {
            Map<String, Object> itemMap = (Map<String, Object>) itemObj;
            OpportunityLineItem item = new OpportunityLineItem();
            item.OpportunityId = opportunityId;
            
            // Resolve PricebookEntryId with fuzzy matching
            if (itemMap.containsKey('PricebookEntryId')) {
                item.PricebookEntryId = (Id) itemMap.get('PricebookEntryId');
            } else if (itemMap.containsKey('Product2Id')) {
                Id prodId = (Id) itemMap.get('Product2Id');
                if (pbeByProductId.containsKey(prodId)) {
                    item.PricebookEntryId = pbeByProductId.get(prodId).Id;
                }
            } else if (itemMap.containsKey('productName')) {
                String prodName = ((String) itemMap.get('productName'));
                PricebookEntry matchedPbe = findProductByFuzzyName(prodName, pbeByProductNameExact, pbeByProductNameNormalized, allPricebookEntries);
                if (matchedPbe != null) {
                    item.PricebookEntryId = matchedPbe.Id;
                }
            }
            
            if (item.PricebookEntryId == null) {
                String requestedProduct = itemMap.containsKey('productName') ? (String) itemMap.get('productName') : 'unknown';
                throw new AFUniversalCrmRecordAction.ActionException('Could not find product "' + requestedProduct + '" in pricebook. Please verify the product name.');
            }
            
            // Set quantity and price
            if (itemMap.containsKey('Quantity')) {
                item.Quantity = Decimal.valueOf(String.valueOf(itemMap.get('Quantity')));
            } else {
                item.Quantity = 1; // Default
            }
            
            if (itemMap.containsKey('UnitPrice')) {
                item.UnitPrice = Decimal.valueOf(String.valueOf(itemMap.get('UnitPrice')));
            }
            
            if (itemMap.containsKey('Description')) {
                item.Description = (String) itemMap.get('Description');
            }
            
            if (itemMap.containsKey('ServiceDate')) {
                item.ServiceDate = Date.valueOf((String) itemMap.get('ServiceDate'));
            }
            
            if (itemMap.containsKey('Discount')) {
                item.Discount = Decimal.valueOf(String.valueOf(itemMap.get('Discount')));
            }
            
            itemsToCreate.add(item);
        }
        
        if (!itemsToCreate.isEmpty()) {
            insert itemsToCreate;
        }
        
        return itemsToCreate;
    }
    
    /**
     * Update existing OpportunityLineItems from JSON array
     */
    private static Integer updateLineItems(String updateLineItemsJson) {
        List<Object> itemsData = (List<Object>) JSON.deserializeUntyped(updateLineItemsJson);
        List<OpportunityLineItem> itemsToUpdate = new List<OpportunityLineItem>();
        
        for (Object itemObj : itemsData) {
            Map<String, Object> itemMap = (Map<String, Object>) itemObj;
            
            if (!itemMap.containsKey('Id')) {
                continue; // Skip items without ID
            }
            
            OpportunityLineItem item = new OpportunityLineItem();
            item.Id = (Id) itemMap.get('Id');
            
            if (itemMap.containsKey('Quantity')) {
                item.Quantity = Decimal.valueOf(String.valueOf(itemMap.get('Quantity')));
            }
            if (itemMap.containsKey('UnitPrice')) {
                item.UnitPrice = Decimal.valueOf(String.valueOf(itemMap.get('UnitPrice')));
            }
            if (itemMap.containsKey('Description')) {
                item.Description = (String) itemMap.get('Description');
            }
            if (itemMap.containsKey('ServiceDate')) {
                item.ServiceDate = Date.valueOf((String) itemMap.get('ServiceDate'));
            }
            if (itemMap.containsKey('Discount')) {
                item.Discount = Decimal.valueOf(String.valueOf(itemMap.get('Discount')));
            }
            
            itemsToUpdate.add(item);
        }
        
        if (!itemsToUpdate.isEmpty()) {
            update itemsToUpdate;
        }
        
        return itemsToUpdate.size();
    }
    
    /**
     * Delete OpportunityLineItems by ID
     */
    private static Integer deleteLineItems(String deleteLineItemIds) {
        List<Object> idsData = (List<Object>) JSON.deserializeUntyped(deleteLineItemIds);
        List<OpportunityLineItem> itemsToDelete = new List<OpportunityLineItem>();
        
        for (Object idObj : idsData) {
            OpportunityLineItem item = new OpportunityLineItem();
            item.Id = (Id) idObj;
            itemsToDelete.add(item);
        }
        
        if (!itemsToDelete.isEmpty()) {
            delete itemsToDelete;
        }
        
        return itemsToDelete.size();
    }
    
    /**
     * Normalize product name for fuzzy matching
     * Removes spaces, converts to lowercase, strips common words
     */
    private static String normalizeProductName(String productName) {
        if (String.isBlank(productName)) {
            return '';
        }
        String normalized = productName.toLowerCase().trim();
        // Remove common words and punctuation
        normalized = normalized.replaceAll('[^a-z0-9]', '');
        return normalized;
    }
    
    /**
     * Singularize a word - basic plural removal
     * Handles common English plural patterns
     */
    private static String singularize(String word) {
        if (String.isBlank(word) || word.length() < 3) {
            return word;
        }
        String lower = word.toLowerCase();
        
        // Handle common plural endings
        if (lower.endsWith('ies') && lower.length() > 4) {
            return lower.substring(0, lower.length() - 3) + 'y';
        }
        if (lower.endsWith('es') && lower.length() > 3) {
            // Check for -ses, -xes, -zes, -ches, -shes
            if (lower.endsWith('ses') || lower.endsWith('xes') || lower.endsWith('zes') ||
                lower.endsWith('ches') || lower.endsWith('shes')) {
                return lower.substring(0, lower.length() - 2);
            }
            return lower.substring(0, lower.length() - 1); // Just remove 's' for -es
        }
        if (lower.endsWith('s') && !lower.endsWith('ss')) {
            return lower.substring(0, lower.length() - 1);
        }
        return lower;
    }
    
    /**
     * Find a product by fuzzy name matching
     * Enhanced with:
     * - Pluralization handling (cardiomonitors → CardioMonitor)
     * - Word tokenization (matches all key words)
     * - Levenshtein distance for typo tolerance
     * - Product code matching
     * - Scored matching to return best result
     */
    private static PricebookEntry findProductByFuzzyName(
        String searchName,
        Map<String, PricebookEntry> exactMap,
        Map<String, PricebookEntry> normalizedMap,
        List<PricebookEntry> allEntries
    ) {
        if (String.isBlank(searchName)) {
            return null;
        }
        
        String lowerSearch = searchName.toLowerCase().trim();
        String normalizedSearch = normalizeProductName(searchName);
        
        // 1. Try exact match (case-insensitive) - highest priority
        if (exactMap.containsKey(lowerSearch)) {
            System.debug(LoggingLevel.INFO, 'AFOpportunityAction: Product exact match: ' + searchName);
            return exactMap.get(lowerSearch);
        }
        
        // 2. Try normalized match (no spaces/punctuation)
        if (normalizedMap.containsKey(normalizedSearch)) {
            System.debug(LoggingLevel.INFO, 'AFOpportunityAction: Product normalized match: ' + searchName);
            return normalizedMap.get(normalizedSearch);
        }
        
        // 3. Try singularized normalized match (cardiomonitors → cardiomonitor)
        String singularizedSearch = singularize(normalizedSearch);
        for (PricebookEntry pbe : allEntries) {
            String normalizedProduct = normalizeProductName(pbe.Product2.Name);
            String singularizedProduct = singularize(normalizedProduct);
            if (singularizedSearch.equals(singularizedProduct)) {
                System.debug(LoggingLevel.INFO, 'AFOpportunityAction: Product singularized match: ' + searchName + ' -> ' + pbe.Product2.Name);
                return pbe;
            }
        }
        
        // Track best scored match
        PricebookEntry bestMatch = null;
        Integer bestScore = 0;
        
        // Split search into words for tokenized matching
        List<String> searchWords = new List<String>();
        for (String word : lowerSearch.split('[\\s\\-\\_]+')) {
            if (word.length() >= 2) {
                searchWords.add(singularize(word));
            }
        }
        
        for (PricebookEntry pbe : allEntries) {
            String productLower = pbe.Product2.Name.toLowerCase();
            String normalizedProduct = normalizeProductName(pbe.Product2.Name);
            Integer score = 0;
            
            // 4. Contains match - search term in product name
            if (productLower.contains(lowerSearch)) {
                score = Math.max(score, lowerSearch.length() * 10);
            }
            
            // 5. Reverse contains - product name in search term
            if (lowerSearch.contains(productLower)) {
                score = Math.max(score, productLower.length() * 10);
            }
            
            // 6. Normalized contains match
            if (normalizedProduct.contains(normalizedSearch) || normalizedSearch.contains(normalizedProduct)) {
                score = Math.max(score, Math.min(normalizedSearch.length(), normalizedProduct.length()) * 8);
            }
            
            // 7. Word tokenization match - check if all search words appear in product
            if (searchWords.size() > 0) {
                Integer wordsFound = 0;
                for (String searchWord : searchWords) {
                    // Check both exact word and singularized
                    if (productLower.contains(searchWord) || normalizedProduct.contains(searchWord)) {
                        wordsFound++;
                    } else {
                        // Check if singularized product words match
                        for (String prodWord : productLower.split('[\\s\\-\\_]+')) {
                            if (singularize(prodWord).equals(searchWord) || prodWord.startsWith(searchWord)) {
                                wordsFound++;
                                break;
                            }
                        }
                    }
                }
                if (wordsFound == searchWords.size()) {
                    // All words matched - strong signal
                    score = Math.max(score, wordsFound * 15);
                } else if (wordsFound > 0) {
                    // Partial word match
                    score = Math.max(score, wordsFound * 5);
                }
            }
            
            // 8. Product code match
            if (pbe.Product2.ProductCode != null) {
                String codeLower = pbe.Product2.ProductCode.toLowerCase();
                if (codeLower.equals(lowerSearch)) {
                    score = Math.max(score, 100); // Exact code match is very strong
                } else if (codeLower.contains(lowerSearch) || lowerSearch.contains(codeLower)) {
                    score = Math.max(score, 50);
                }
            }
            
            // 9. Levenshtein distance for typo tolerance on normalized names
            if (Math.abs(normalizedSearch.length() - normalizedProduct.length()) <= 3) {
                Integer dist = getProductLevenshteinDistance(normalizedSearch, normalizedProduct);
                // Accept if edit distance is reasonable relative to string length
                Integer maxDist = Math.max(2, normalizedSearch.length() / 4);
                if (dist <= maxDist) {
                    Integer levScore = (maxDist - dist + 1) * 12;
                    score = Math.max(score, levScore);
                }
            }
            
            // Update best match
            if (score > bestScore) {
                bestScore = score;
                bestMatch = pbe;
            }
        }
        
        if (bestMatch != null) {
            System.debug(LoggingLevel.INFO, 'AFOpportunityAction: Product fuzzy match: ' + searchName + ' -> ' + bestMatch.Product2.Name + ' (score: ' + bestScore + ')');
        } else {
            System.debug(LoggingLevel.WARN, 'AFOpportunityAction: No product match found for: ' + searchName);
        }
        
        return bestMatch;
    }
    
    /**
     * Calculate Levenshtein distance between two strings
     * Used for typo tolerance in product matching
     */
    private static Integer getProductLevenshteinDistance(String s, String t) {
        if (String.isBlank(s)) return String.isBlank(t) ? 0 : t.length();
        if (String.isBlank(t)) return s.length();
        
        Integer sLen = s.length();
        Integer tLen = t.length();
        
        // Use two-row optimization
        List<Integer> prevRow = new List<Integer>();
        List<Integer> currRow = new List<Integer>();
        
        for (Integer j = 0; j <= tLen; j++) {
            prevRow.add(j);
        }
        
        for (Integer i = 1; i <= sLen; i++) {
            currRow = new List<Integer>();
            currRow.add(i);
            
            for (Integer j = 1; j <= tLen; j++) {
                Integer cost = s.substring(i-1, i).equals(t.substring(j-1, j)) ? 0 : 1;
                Integer insert_op = currRow[j-1] + 1;
                Integer delete_op = prevRow[j] + 1;
                Integer replace_op = prevRow[j-1] + cost;
                currRow.add(Math.min(Math.min(insert_op, delete_op), replace_op));
            }
            
            prevRow = currRow;
        }
        
        return prevRow[tLen];
    }
}
