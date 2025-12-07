/**
 * AF Universal Analytics Action
 * Invocable action for performing aggregate SOQL queries (SUM, COUNT, AVG, MIN, MAX, GROUP BY)
 * Designed for Agentforce AI agents to dynamically construct analytics queries
 * 
 * Supports:
 * - Aggregate functions: SUM, COUNT, AVG, MIN, MAX
 * - Multi-level GROUP BY
 * - Date range filtering (predefined and custom)
 * - Standard filters
 * - ORDER BY
 * 
 * Example Use Cases:
 * - "How much pipeline do I have this quarter?" → SUM Amount, GROUP BY StageName, WHERE CloseDate THIS_QUARTER
 * - "How many accounts by industry?" → COUNT Id, GROUP BY Industry
 * - "Average deal size by stage" → AVG Amount, GROUP BY StageName
 */
public with sharing class AFUniversalAnalyticsAction {
    
    // Supported objects (same as AFUniversalCrmRecordAction)
    private static final Set<String> SUPPORTED_OBJECTS = new Set<String>{
        'account', 'contact', 'case', 'opportunity', 'task', 'meeting__c'
    };
    
    // Supported aggregate functions
    private static final Set<String> SUPPORTED_AGGREGATE_FUNCTIONS = new Set<String>{
        'SUM', 'COUNT', 'AVG', 'MIN', 'MAX'
    };
    
    // Predefined date ranges
    private static final Map<String, String> DATE_RANGE_PREDEFINED = new Map<String, String>{
        'TODAY' => 'TODAY',
        'YESTERDAY' => 'YESTERDAY',
        'THIS_WEEK' => 'THIS_WEEK',
        'LAST_WEEK' => 'LAST_WEEK',
        'THIS_MONTH' => 'THIS_MONTH',
        'LAST_MONTH' => 'LAST_MONTH',
        'THIS_QUARTER' => 'THIS_QUARTER',
        'LAST_QUARTER' => 'LAST_QUARTER',
        'THIS_YEAR' => 'THIS_YEAR',
        'LAST_YEAR' => 'LAST_YEAR',
        'LAST_N_DAYS' => 'LAST_N_DAYS',
        'NEXT_N_DAYS' => 'NEXT_N_DAYS'
    };
    
    /**
     * Custom exception for analytics errors
     */
    public class AnalyticsException extends Exception {}
    
    /**
     * Request input for analytics operation
     */
    public class Request {
        @InvocableVariable(
            label='Object API Name'
            description='The Salesforce object to query: Account, Contact, Case, Opportunity, Task, or Meeting__c. Example: "Opportunity" for pipeline analysis, "Account" for account metrics.'
            required=true
        )
        public String objectApiName;
        
        @InvocableVariable(
            label='Aggregate Function'
            description='The aggregate function to apply: SUM (for numeric fields like Amount), COUNT (for counting records - use "Id" or null for aggregateField), AVG (average), MIN (minimum), MAX (maximum). Example: "SUM" for total pipeline, "COUNT" for number of records.'
            required=true
        )
        public String aggregateFunction;
        
        @InvocableVariable(
            label='Aggregate Field'
            description='The field to aggregate (API name). For SUM/AVG/MIN/MAX, use a numeric field (e.g., "Amount" for Opportunity). For COUNT, use "Id" or leave null to count all records. Example: "Amount" for SUM Amount, "Id" for COUNT Id.'
            required=false
        )
        public String aggregateField;
        
        @InvocableVariable(
            label='Group By Fields'
            description='JSON array of field API names to group results by. Supports multi-level grouping. Example: ["StageName"] for grouping by stage, ["StageName","OwnerId"] for grouping by stage and owner. Leave empty for overall totals.'
            required=false
        )
        public String groupByFieldsJson;
        
        @InvocableVariable(
            label='Date Range Field'
            description='The date/datetime field to filter on (API name). Used with dateRangePredefined or dateRangeStart/dateRangeEnd. Example: "CloseDate" for Opportunity, "Meeting_Date__c" for Meeting__c, "ActivityDate" for Task.'
            required=false
        )
        public String dateRangeField;
        
        @InvocableVariable(
            label='Date Range Predefined'
            description='Predefined date range: TODAY, YESTERDAY, THIS_WEEK, LAST_WEEK, THIS_MONTH, LAST_MONTH, THIS_QUARTER, LAST_QUARTER, THIS_YEAR, LAST_YEAR, LAST_N_DAYS, NEXT_N_DAYS. Use this OR dateRangeStart/dateRangeEnd, not both. Example: "THIS_QUARTER" for current quarter.'
            required=false
        )
        public String dateRangePredefined;
        
        @InvocableVariable(
            label='Date Range Start'
            description='Start date for custom date range (YYYY-MM-DD format). Use with dateRangeEnd. Example: "2024-01-01".'
            required=false
        )
        public String dateRangeStart;
        
        @InvocableVariable(
            label='Date Range End'
            description='End date for custom date range (YYYY-MM-DD format). Use with dateRangeStart. Example: "2024-12-31".'
            required=false
        )
        public String dateRangeEnd;
        
        @InvocableVariable(
            label='Date Range Days'
            description='Number of days for LAST_N_DAYS or NEXT_N_DAYS predefined ranges. Example: 30 for "last 30 days".'
            required=false
        )
        public Integer dateRangeDays;
        
        @InvocableVariable(
            label='Filters JSON'
            description='JSON string of exact-match filters. Can be single object {"fieldApiName":"StageName","value":"Closed Won"} or array [{"fieldApiName":"StageName","value":"Closed Won"},{"fieldApiName":"Type","value":"New Business"}]. Use this to filter results before aggregation.'
            required=false
        )
        public String filtersJson;
        
        @InvocableVariable(
            label='Order By'
            description='Field and direction to order results by. Format: "FieldName ASC" or "FieldName DESC". For aggregate queries, use the aggregate alias (e.g., "expr0 DESC" for first aggregate, "StageName ASC" for group by field). Example: "expr0 DESC" to sort by aggregate value descending.'
            required=false
        )
        public String orderBy;
        
        @InvocableVariable(
            label='Record Limit'
            description='Maximum number of grouped results to return (default: 100, max: 200). Use this to limit the number of groups returned.'
            required=false
        )
        public Integer recordLimit;
    }
    
    /**
     * Response output for analytics operation
     */
    public class Response {
        @InvocableVariable(
            label='Success'
            description='True if operation completed successfully, false if an error occurred. Check this before using other output variables.'
        )
        public Boolean success;
        
        @InvocableVariable(
            label='Aggregate Results JSON'
            description='JSON string representation of aggregate results for easier parsing. Format: [{"groupByFields":{"StageName":"Prospecting"},"aggregateValue":500000,"recordCount":15},...]. Use this to extract specific values programmatically and present to the user.'
        )
        public String aggregateResultsJson;
        
        @InvocableVariable(
            label='Total Value'
            description='The total aggregate value across all groups (sum of all aggregate results). For COUNT queries, this is the total record count. For SUM queries, this is the sum of all groups. Useful for "total pipeline" or "total accounts" metrics.'
        )
        public Decimal totalValue;
        
        @InvocableVariable(
            label='Record Count'
            description='Total number of records that were aggregated (before grouping). This is the count of all records matching the filters, regardless of grouping.'
        )
        public Integer recordCount;
        
        @InvocableVariable(
            label='Group Count'
            description='Number of groups returned (number of rows in aggregateResults). Example: If grouping by StageName and there are 5 stages, groupCount is 5.'
        )
        public Integer groupCount;
        
        @InvocableVariable(
            label='Message'
            description='Human-readable summary of the analytics results. Use this exact message to inform the user. Example: "Total pipeline: $2.5M across 45 opportunities, grouped by 5 stages" or "Found 120 accounts grouped by 8 industries".'
        )
        public String message;
        
        @InvocableVariable(
            label='Error Message'
            description='If success is false, this contains a user-friendly error message to relay directly to the user.'
        )
        public String errorMessage;
        
        @InvocableVariable(
            label='Object Type'
            description='The Salesforce object type that was queried. Useful for agent context and logging.'
        )
        public String objectType;
        
        @InvocableVariable(
            label='Query Description'
            description='Human-readable description of the query that was executed. Useful for debugging and agent context. Example: "SUM Amount GROUP BY StageName WHERE CloseDate = THIS_QUARTER".'
        )
        public String queryDescription;
    }
    
    /**
     * Perform aggregate analytics query
     */
    @InvocableMethod(
        label='Agentforce Analytics Query'
        description='Performs aggregate SOQL queries (SUM, COUNT, AVG, MIN, MAX) with optional GROUP BY and date range filtering. Use this to answer questions like "How much pipeline do I have?", "How many accounts by industry?", "Average deal size by stage", etc. The agent can construct any aggregate query by specifying the object, aggregate function, field, grouping, and filters. Supports all standard Salesforce objects (Account, Contact, Case, Opportunity, Task, Meeting__c).'
        category='CRM Analytics'
    )
    public static List<Response> executeAnalytics(List<Request> requests) {
        List<Response> responses = new List<Response>();
        
        for (Request req : requests) {
            Response res = new Response();
            res.success = false;
            res.totalValue = 0;
            res.recordCount = 0;
            res.groupCount = 0;
            
            try {
                // Validate object
                String objectApiName = req.objectApiName;
                if (String.isBlank(objectApiName)) {
                    throw new AnalyticsException('objectApiName is required.');
                }
                
                String objLower = objectApiName.toLowerCase();
                if (!SUPPORTED_OBJECTS.contains(objLower)) {
                    throw new AnalyticsException('Unsupported object: ' + objectApiName + '. Supported objects: Account, Contact, Case, Opportunity, Task, Meeting__c.');
                }
                
                res.objectType = objectApiName;
                
                // Validate aggregate function
                String aggFunc = req.aggregateFunction != null ? req.aggregateFunction.toUpperCase() : null;
                if (String.isBlank(aggFunc) || !SUPPORTED_AGGREGATE_FUNCTIONS.contains(aggFunc)) {
                    throw new AnalyticsException('aggregateFunction is required and must be one of: SUM, COUNT, AVG, MIN, MAX.');
                }
                
                // Validate aggregate field (not required for COUNT)
                String aggField = req.aggregateField;
                if (aggFunc != 'COUNT' && String.isBlank(aggField)) {
                    throw new AnalyticsException('aggregateField is required for ' + aggFunc + ' function. For COUNT, you can use "Id" or leave null.');
                }
                
                // Get field metadata
                Schema.SObjectType sType = Schema.getGlobalDescribe().get(objectApiName);
                if (sType == null) {
                    throw new AnalyticsException('Object not found: ' + objectApiName);
                }
                Map<String, Schema.SObjectField> fieldMap = sType.getDescribe().fields.getMap();
                
                // Validate aggregate field exists and is numeric (if provided)
                if (!String.isBlank(aggField)) {
                    if (!fieldMap.containsKey(aggField.toLowerCase())) {
                        throw new AnalyticsException('Field not found: ' + aggField + ' on object ' + objectApiName);
                    }
                    Schema.DescribeFieldResult fieldDesc = fieldMap.get(aggField.toLowerCase()).getDescribe();
                    if (aggFunc != 'COUNT' && fieldDesc.getType() != Schema.DisplayType.CURRENCY && 
                        fieldDesc.getType() != Schema.DisplayType.DOUBLE && 
                        fieldDesc.getType() != Schema.DisplayType.INTEGER &&
                        fieldDesc.getType() != Schema.DisplayType.PERCENT) {
                        throw new AnalyticsException('Field ' + aggField + ' must be numeric (Currency, Number, Percent) for ' + aggFunc + ' function.');
                    }
                }
                
                // Parse group by fields
                List<String> groupByFields = new List<String>();
                if (!String.isBlank(req.groupByFieldsJson)) {
                    try {
                        List<Object> groupByList = (List<Object>) JSON.deserializeUntyped(req.groupByFieldsJson);
                        for (Object fieldObj : groupByList) {
                            if (fieldObj instanceof String) {
                                String fieldName = (String) fieldObj;
                                if (fieldMap.containsKey(fieldName.toLowerCase())) {
                                    groupByFields.add(fieldName);
                                } else {
                                    throw new AnalyticsException('Group by field not found: ' + fieldName);
                                }
                            }
                        }
                    } catch (Exception e) {
                        throw new AnalyticsException('Invalid groupByFieldsJson format. Expected JSON array of field names: ["StageName","OwnerId"]. Error: ' + e.getMessage());
                    }
                }
                
                // Validate group by fields
                for (String groupField : groupByFields) {
                    if (!fieldMap.containsKey(groupField.toLowerCase())) {
                        throw new AnalyticsException('Group by field not found: ' + groupField);
                    }
                }
                
                // Build SOQL query
                String soql = buildAggregateQuery(req, objectApiName, fieldMap, aggFunc, aggField, groupByFields);
                
                res.queryDescription = buildQueryDescription(req, aggFunc, aggField, groupByFields);
                
                System.debug(LoggingLevel.INFO, 'AFUniversalAnalyticsAction: Executing SOQL: ' + soql);
                
                // Execute query
                List<AggregateResult> salesforceAggResults = Database.query(soql);
                
                // Process results
                processAggregateResults(salesforceAggResults, res, aggFunc, groupByFields);
                
                // Build human-readable message
                res.message = buildResultMessage(res, aggFunc, aggField, groupByFields, objectApiName);
                
                res.success = true;
                
            } catch (Exception e) {
                res.success = false;
                res.errorMessage = 'Error executing analytics query: ' + e.getMessage();
                System.debug(LoggingLevel.ERROR, 'AFUniversalAnalyticsAction: Exception - ' + e.getMessage());
                System.debug(LoggingLevel.ERROR, 'AFUniversalAnalyticsAction: Stack trace - ' + e.getStackTraceString());
            }
            
            responses.add(res);
        }
        
        return responses;
    }
    
    /**
     * Build aggregate SOQL query
     */
    private static String buildAggregateQuery(
        Request req,
        String objectApiName,
        Map<String, Schema.SObjectField> fieldMap,
        String aggFunc,
        String aggField,
        List<String> groupByFields
    ) {
        // Build SELECT clause
        String selectClause = '';
        
        if (aggFunc == 'COUNT' && String.isBlank(aggField)) {
            selectClause = 'COUNT()';
        } else if (aggFunc == 'COUNT') {
            selectClause = 'COUNT(' + aggField + ')';
        } else {
            selectClause = aggFunc + '(' + aggField + ')';
        }
        
        // Add GROUP BY fields
        if (!groupByFields.isEmpty()) {
            selectClause += ', ' + String.join(groupByFields, ', ');
        }
        
        String soql = 'SELECT ' + selectClause + ' FROM ' + objectApiName;
        
        // Build WHERE clause
        List<String> whereClauses = new List<String>();
        
        // Add date range filter
        if (!String.isBlank(req.dateRangeField)) {
            String dateClause = buildDateRangeClause(req, fieldMap);
            if (!String.isBlank(dateClause)) {
                whereClauses.add(dateClause);
            }
        }
        
        // Add standard filters
        if (!String.isBlank(req.filtersJson)) {
            List<AFUniversalCrmRecordAction.Filter> filters = parseFiltersJson(req.filtersJson);
            if (filters != null && !filters.isEmpty()) {
                whereClauses.addAll(buildFilterConditions(filters, fieldMap));
            }
        }
        
        // Assemble WHERE clause
        if (!whereClauses.isEmpty()) {
            soql += ' WHERE ' + String.join(whereClauses, ' AND ');
        }
        
        // Add GROUP BY clause
        if (!groupByFields.isEmpty()) {
            soql += ' GROUP BY ' + String.join(groupByFields, ', ');
        }
        
        // Add ORDER BY clause
        if (!String.isBlank(req.orderBy)) {
            soql += ' ORDER BY ' + req.orderBy;
        } else if (!groupByFields.isEmpty()) {
            // Default: order by aggregate value descending
            soql += ' ORDER BY expr0 DESC';
        }
        
        // Add LIMIT
        Integer limitToUse = (req.recordLimit != null && req.recordLimit > 0) ? 
            Math.min(req.recordLimit, 200) : 100;
        soql += ' LIMIT ' + limitToUse;
        
        return soql;
    }
    
    /**
     * Build date range WHERE clause
     */
    private static String buildDateRangeClause(Request req, Map<String, Schema.SObjectField> fieldMap) {
        String dateField = req.dateRangeField;
        
        // Validate date field exists
        if (!fieldMap.containsKey(dateField.toLowerCase())) {
            throw new AnalyticsException('Date range field not found: ' + dateField);
        }
        
        Schema.DescribeFieldResult fieldDesc = fieldMap.get(dateField.toLowerCase()).getDescribe();
        if (fieldDesc.getType() != Schema.DisplayType.DATE && 
            fieldDesc.getType() != Schema.DisplayType.DATETIME) {
            throw new AnalyticsException('Date range field must be a Date or DateTime field: ' + dateField);
        }
        
        // Handle predefined ranges
        if (!String.isBlank(req.dateRangePredefined)) {
            String predefined = req.dateRangePredefined.toUpperCase();
            
            if (predefined == 'LAST_N_DAYS' || predefined == 'NEXT_N_DAYS') {
                Integer days = req.dateRangeDays != null ? req.dateRangeDays : 30;
                if (predefined == 'LAST_N_DAYS') {
                    return dateField + ' = LAST_N_DAYS:' + days;
                } else {
                    return dateField + ' = NEXT_N_DAYS:' + days;
                }
            } else if (DATE_RANGE_PREDEFINED.containsKey(predefined)) {
                return dateField + ' = ' + predefined;
            } else {
                throw new AnalyticsException('Invalid dateRangePredefined: ' + req.dateRangePredefined + '. Supported: TODAY, YESTERDAY, THIS_WEEK, LAST_WEEK, THIS_MONTH, LAST_MONTH, THIS_QUARTER, LAST_QUARTER, THIS_YEAR, LAST_YEAR, LAST_N_DAYS, NEXT_N_DAYS.');
            }
        }
        
        // Handle custom date range
        if (!String.isBlank(req.dateRangeStart) || !String.isBlank(req.dateRangeEnd)) {
            if (String.isBlank(req.dateRangeStart) || String.isBlank(req.dateRangeEnd)) {
                throw new AnalyticsException('Both dateRangeStart and dateRangeEnd are required for custom date ranges.');
            }
            
            // Parse dates (YYYY-MM-DD format)
            try {
                Date startDate = Date.valueOf(req.dateRangeStart);
                Date endDate = Date.valueOf(req.dateRangeEnd);
                
                if (fieldDesc.getType() == Schema.DisplayType.DATETIME) {
                    // For DateTime fields, use >= and < (next day)
                    DateTime startDateTime = DateTime.newInstance(startDate, Time.newInstance(0, 0, 0, 0));
                    DateTime endDateTime = DateTime.newInstance(endDate.addDays(1), Time.newInstance(0, 0, 0, 0));
                    return dateField + ' >= ' + startDateTime.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'') + 
                           ' AND ' + dateField + ' < ' + endDateTime.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
                } else {
                    // For Date fields, use >= and <=
                    return dateField + ' >= ' + String.valueOf(startDate) + 
                           ' AND ' + dateField + ' <= ' + String.valueOf(endDate);
                }
            } catch (Exception e) {
                throw new AnalyticsException('Invalid date format. Use YYYY-MM-DD format. Error: ' + e.getMessage());
            }
        }
        
        return null;
    }
    
    /**
     * Parse filters JSON (reuse logic from AFUniversalCrmRecordAction)
     */
    private static List<AFUniversalCrmRecordAction.Filter> parseFiltersJson(String filtersJson) {
        if (String.isBlank(filtersJson)) {
            return new List<AFUniversalCrmRecordAction.Filter>();
        }
        
        try {
            Object parsed = JSON.deserializeUntyped(filtersJson);
            List<AFUniversalCrmRecordAction.Filter> filters = new List<AFUniversalCrmRecordAction.Filter>();
            
            if (parsed instanceof List<Object>) {
                List<Object> filterList = (List<Object>) parsed;
                for (Object filterObj : filterList) {
                    if (filterObj instanceof Map<String, Object>) {
                        Map<String, Object> filterMap = (Map<String, Object>) filterObj;
                        AFUniversalCrmRecordAction.Filter filter = new AFUniversalCrmRecordAction.Filter();
                        filter.fieldApiName = (String) filterMap.get('fieldApiName');
                        filter.value = String.valueOf(filterMap.get('value'));
                        filters.add(filter);
                    }
                }
            } else if (parsed instanceof Map<String, Object>) {
                Map<String, Object> filterMap = (Map<String, Object>) parsed;
                AFUniversalCrmRecordAction.Filter filter = new AFUniversalCrmRecordAction.Filter();
                filter.fieldApiName = (String) filterMap.get('fieldApiName');
                filter.value = String.valueOf(filterMap.get('value'));
                filters.add(filter);
            }
            
            return filters;
        } catch (Exception e) {
            throw new AnalyticsException('Invalid filtersJson format. Error: ' + e.getMessage());
        }
    }
    
    /**
     * Build filter conditions (reuse logic from AFUniversalCrmRecordAction)
     */
    private static List<String> buildFilterConditions(
        List<AFUniversalCrmRecordAction.Filter> filters,
        Map<String, Schema.SObjectField> fieldMap
    ) {
        List<String> conditions = new List<String>();
        
        for (AFUniversalCrmRecordAction.Filter filter : filters) {
            String fieldName = filter.fieldApiName;
            String value = filter.value;
            
            if (String.isBlank(fieldName) || String.isBlank(value)) {
                continue;
            }
            
            if (!fieldMap.containsKey(fieldName.toLowerCase())) {
                throw new AnalyticsException('Filter field not found: ' + fieldName);
            }
            
            Schema.DescribeFieldResult fieldDesc = fieldMap.get(fieldName.toLowerCase()).getDescribe();
            String escapedValue = String.escapeSingleQuotes(value);
            
            if (fieldDesc.getType() == Schema.DisplayType.STRING || 
                fieldDesc.getType() == Schema.DisplayType.PICKLIST ||
                fieldDesc.getType() == Schema.DisplayType.EMAIL ||
                fieldDesc.getType() == Schema.DisplayType.PHONE ||
                fieldDesc.getType() == Schema.DisplayType.URL) {
                conditions.add(fieldName + ' = \'' + escapedValue + '\'');
            } else if (fieldDesc.getType() == Schema.DisplayType.BOOLEAN) {
                conditions.add(fieldName + ' = ' + (Boolean.valueOf(value) ? 'true' : 'false'));
            } else if (fieldDesc.getType() == Schema.DisplayType.DATE) {
                try {
                    Date dateValue = Date.valueOf(value);
                    conditions.add(fieldName + ' = ' + String.valueOf(dateValue));
                } catch (Exception e) {
                    throw new AnalyticsException('Invalid date format for filter field ' + fieldName + ': ' + value);
                }
            } else if (fieldDesc.getType() == Schema.DisplayType.DATETIME) {
                try {
                    DateTime dateTimeValue = DateTime.valueOf(value);
                    conditions.add(fieldName + ' = ' + dateTimeValue.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''));
                } catch (Exception e) {
                    throw new AnalyticsException('Invalid datetime format for filter field ' + fieldName + ': ' + value);
                }
            } else if (fieldDesc.getType() == Schema.DisplayType.ID) {
                conditions.add(fieldName + ' = \'' + escapedValue + '\'');
            } else {
                // Numeric fields
                conditions.add(fieldName + ' = ' + escapedValue);
            }
        }
        
        return conditions;
    }
    
    /**
     * Process Salesforce AggregateResult objects into our response format
     */
    private static void processAggregateResults(
        List<AggregateResult> salesforceAggResults,
        Response res,
        String aggFunc,
        List<String> groupByFields
    ) {
        Decimal totalValue = 0;
        Integer totalRecordCount = 0;
        List<Map<String, Object>> jsonResults = new List<Map<String, Object>>();
        
        for (AggregateResult aggResult : salesforceAggResults) {
            Map<String, Object> groupByFieldsMap = new Map<String, Object>();
            Integer recordCount = 0;
            
            // Extract group by field values
            if (!groupByFields.isEmpty()) {
                for (String groupField : groupByFields) {
                    Object fieldValue = aggResult.get(groupField);
                    groupByFieldsMap.put(groupField, fieldValue);
                }
            }
            
            // Extract aggregate value (Salesforce uses expr0, expr1, etc. for aggregates)
            Decimal aggValue = 0;
            if (aggFunc == 'COUNT') {
                aggValue = (Decimal) aggResult.get('expr0');
                recordCount = aggValue.intValue();
            } else {
                Object aggObj = aggResult.get('expr0');
                aggValue = aggObj != null ? (Decimal) aggObj : 0;
                // For non-COUNT, we don't have easy access to record count per group
                recordCount = 1; // Placeholder
            }
            
            totalValue += aggValue;
            totalRecordCount += recordCount;
            
            // Build JSON representation
            Map<String, Object> jsonResult = new Map<String, Object>();
            jsonResult.put('groupByFields', groupByFieldsMap);
            jsonResult.put('aggregateValue', aggValue);
            jsonResult.put('recordCount', recordCount);
            jsonResults.add(jsonResult);
        }
        
        res.aggregateResultsJson = JSON.serialize(jsonResults);
        res.totalValue = totalValue;
        res.recordCount = totalRecordCount;
        res.groupCount = jsonResults.size();
    }
    
    /**
     * Build human-readable query description
     */
    private static String buildQueryDescription(
        Request req,
        String aggFunc,
        String aggField,
        List<String> groupByFields
    ) {
        String description = aggFunc;
        if (!String.isBlank(aggField)) {
            description += ' ' + aggField;
        } else {
            description += '(*)';
        }
        
        if (!groupByFields.isEmpty()) {
            description += ' GROUP BY ' + String.join(groupByFields, ', ');
        }
        
        if (!String.isBlank(req.dateRangeField)) {
            description += ' WHERE ' + req.dateRangeField;
            if (!String.isBlank(req.dateRangePredefined)) {
                description += ' = ' + req.dateRangePredefined;
            } else if (!String.isBlank(req.dateRangeStart)) {
                description += ' BETWEEN ' + req.dateRangeStart + ' AND ' + req.dateRangeEnd;
            }
        }
        
        return description;
    }
    
    /**
     * Build human-readable result message
     */
    private static String buildResultMessage(
        Response res,
        String aggFunc,
        String aggField,
        List<String> groupByFields,
        String objectApiName
    ) {
        String message = '';
        
        if (res.groupCount == 0) {
            return 'No ' + objectApiName + ' records found matching the criteria.';
        }
        
        // Build aggregate description
        String aggDesc = aggFunc;
        if (!String.isBlank(aggField)) {
            aggDesc += ' of ' + aggField;
        } else {
            aggDesc += ' of records';
        }
        
        if (!groupByFields.isEmpty()) {
            message = aggDesc + ' grouped by ' + String.join(groupByFields, ', ') + ': ';
        } else {
            message = 'Total ' + aggDesc + ': ';
        }
        
        // Format total value
        if (aggFunc == 'COUNT') {
            message += res.totalValue.intValue() + ' records';
        } else if (aggFunc == 'AVG') {
            message += '$' + res.totalValue.setScale(2).toPlainString();
        } else {
            message += '$' + res.totalValue.setScale(2).toPlainString();
        }
        
        if (res.groupCount > 1) {
            message += ' across ' + res.groupCount + ' groups';
        }
        
        if (res.recordCount > 0 && res.recordCount != res.totalValue.intValue()) {
            message += ' (from ' + res.recordCount + ' total records)';
        }
        
        return message;
    }
}

