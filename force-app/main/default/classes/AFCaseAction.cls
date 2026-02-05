/**
 * AF Case Action
 * Consolidated invocable action for all Case CRUD operations (Create, Read, Update, Delete, Find, Summarize)
 * Designed for Agentforce AI agents
 * 
 * The SUMMARIZE operation retrieves a Case along with its related EmailMessage records,
 * providing a structured summary that the agent can use to brief users on case status
 * and communication history.
 */
public without sharing class AFCaseAction {
    
    // Maximum number of emails to include in summary
    private static final Integer MAX_EMAILS_FOR_SUMMARY = 10;
    // Maximum characters per email body to include (to avoid token limits)
    private static final Integer MAX_EMAIL_BODY_LENGTH = 1500;
    
    public class Request {
        @InvocableVariable(
            label='Operation'
            description='Explicit operation: "create", "read", "update", "delete", "find", or "summarize". If not specified, inferred from context. SUMMARIZE: Use when user asks to "summarize this case", "catch me up on this ticket", "what has been discussed", "show me the email history", or wants a TL;DR of a case with its email communications.'
        )
        public String operation;
        
        @InvocableVariable(
            label='Field Data JSON'
            description='JSON string containing Case field data. For create: {"Subject":"Support Request","Status":"New"}. For update: {"Status":"Closed","Priority":"High"}. For bulk: [{"Subject":"Request 1"},{"Subject":"Request 2"}]. IMPORTANT: For picklist fields (Status, Priority, Type, Origin, etc.), query availableFieldsJson from a previous read operation to see valid values. Do NOT ask the user for picklist options - query availableFieldsJson to get them automatically. If the user wants to update the Contact or Account on the case, use the contactNameOrEmail or accountName parameters instead of putting ContactId or AccountId in fieldDataJson.'
        )
        public String fieldDataJson;
        
        @InvocableVariable(
            label='Record ID'
            description='The Salesforce record ID of the Case. Required for read/update/delete/summarize. Format: 18-character ID like "500xx000003DGbYAAW".'
        )
        public Id recordId;
        
        @InvocableVariable(
            label='Search Term'
            description='Text to search for in Case fields (Subject, CaseNumber, Account Name, etc.). Used for find and summarize operations. For SUMMARIZE: If recordId is not provided, the system will search for a matching case using this term. Examples: "00001182", "University Medical", "billing issue".'
        )
        public String searchTerm;
        
        @InvocableVariable(
            label='Filters JSON'
            description='JSON string of exact-match filters for find operations. IMPORTANT: If the user wants to find a case but hasn\'t provided specific filters, ask them for details like case number, account name, or status BEFORE calling this action. Do not call find operation without a searchTerm or filtersJson.'
        )
        public String filtersJson;
        
        @InvocableVariable(
            label='Search Limit'
            description='Maximum number of records to return for find operations (default: 5, max: 20).'
        )
        public Integer searchLimit;
        
        @InvocableVariable(
            label='Account Name'
            description='Account name to resolve to AccountId for the Case. IMPORTANT: When the user wants to add or update the account on a case (e.g., "update the account to Acme Corp"), use this parameter with the account name. Do NOT put AccountId in fieldDataJson - use this parameter instead. The system will automatically resolve the account name to an Account ID.'
        )
        public String accountName;
        
        @InvocableVariable(
            label='Contact Name or Email'
            description='Contact name or email to resolve to ContactId for the Case. IMPORTANT: When the user wants to add or update the contact on a case (e.g., "add the contact as John Smith" or "update the contact to jane@example.com"), use this parameter with the contact name or email. Do NOT put ContactId in fieldDataJson - use this parameter instead. The system will automatically resolve the contact name/email to a Contact ID. If multiple contacts match, the system will return candidates for user clarification.'
        )
        public String contactNameOrEmail;
        
        @InvocableVariable(
            label='Confirm'
            description='For create/update: Set to false to preview only. For delete: Set to true to actually delete.'
        )
        public Boolean confirm;
        
        @InvocableVariable(
            label='Include Email Summary'
            description='Set to true to include a summary of related email messages when reading or finding a case. When true, the response will include emailSummaryJson with the most recent 10 emails on the case, along with caseSummaryData for a comprehensive briefing. Use this when user asks to "summarize", "catch me up", "what has been discussed", "email history", or wants context on case communications.'
        )
        public Boolean includeEmailSummary;
    }
    
    public class Response {
        @InvocableVariable(
            label='Success'
            description='True if operation completed successfully.'
        )
        public Boolean success;
        
        @InvocableVariable(
            label='Record'
            description='The Case record (for single record operations).'
        )
        public Case record;
        
        @InvocableVariable(
            label='Records'
            description='List of Case records (for bulk or find operations).'
        )
        public List<Case> records;
        
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
            description='The Salesforce object type, always "Case" for Case operations.'
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
            description='JSON string containing metadata for all available fields.'
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
            description='Number of Case records found in a find/search operation.'
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
        
        // ========== NEW FIELDS FOR EMAIL SUMMARY ==========
        
        @InvocableVariable(
            label='Email Summary JSON'
            description='JSON array containing the most recent email messages related to this case. Each email includes: subject, messageDate, fromAddress, toAddress, direction (Inbound/Outbound), and bodySnippet (truncated text). Use this data to summarize the communication history for the user. Present as a TL;DR with key points and potential action items.'
        )
        public String emailSummaryJson;
        
        @InvocableVariable(
            label='Email Count'
            description='Total number of email messages found on this case. If greater than 10, only the most recent 10 are included in emailSummaryJson.'
        )
        public Integer emailCount;
        
        @InvocableVariable(
            label='Case Summary Data'
            description='Comprehensive JSON containing both case details and email thread for summarization. Structure: { caseInfo: {subject, status, priority, description, account, contact, createdDate, lastModifiedDate}, emailThread: [{date, from, to, direction, subject, body}], actionItems: [suggested actions based on emails] }. Use this to provide a complete briefing: TL;DR, current status, communication history, and recommended next steps.'
        )
        public String caseSummaryData;
    }
    
    private static String inferOperation(Request req) {
        if (!String.isBlank(req.operation)) {
            return req.operation.trim().toLowerCase();
        }
        
        Boolean hasRecordId = req.recordId != null;
        Boolean hasFieldData = !String.isBlank(req.fieldDataJson);
        Boolean hasSearchTerm = !String.isBlank(req.searchTerm);
        Boolean hasFilters = !String.isBlank(req.filtersJson);
        Boolean wantsEmailSummary = req.includeEmailSummary != null && req.includeEmailSummary == true;
        
        // If user explicitly wants email summary, this is a summarize operation
        if (wantsEmailSummary && (hasRecordId || hasSearchTerm)) {
            return 'summarize';
        }
        
        // Order matters! Check find-then-update before create
        if (hasRecordId && hasFieldData) return 'update';
        else if (hasRecordId && !hasFieldData && !hasSearchTerm && !hasFilters) return 'read';
        else if ((hasSearchTerm || hasFilters) && hasFieldData) return 'update'; // find-then-update
        else if (hasFieldData && !hasRecordId) return 'create';
        else if (hasSearchTerm || hasFilters) return 'find';
        else if (hasRecordId && req.confirm != null && req.confirm == true) return 'delete';
        
        throw new AFUniversalCrmRecordAction.ActionException('Cannot infer operation. Please specify operation parameter or provide sufficient context.');
    }
    
    @InvocableMethod(
        label='Agentforce Case Action'
        description='Performs CRUD and summarize operations on Case records. Operations: CREATE, READ, UPDATE, DELETE, FIND, SUMMARIZE. SUMMARIZE OPERATION: Use when user asks to "summarize this case", "catch me up on the ticket", "what has been discussed", "show email history", "TL;DR this case", or wants context on case communications. For summarize: provide recordId OR searchTerm (case number, subject, account name). Returns case details + most recent 10 emails in structured format for briefing. The caseSummaryData field contains everything needed to provide: (1) TL;DR - quick summary, (2) Current Status - case state and priority, (3) Communication History - email thread summary, (4) Action Items - suggested next steps. FIND: Requires searchTerm or filtersJson. PICKLIST VALUES: Query availableFieldsJson for valid Status, Priority, Type values. CONTACT/ACCOUNT: Use contactNameOrEmail or accountName parameters for name-based resolution. Supports bulk operations.'
        category='CRM Actions'
    )
    public static List<Response> caseAction(List<Request> requests) {
        List<Response> responses = new List<Response>();
        
        for (Request req : requests) {
            Response res = new Response();
            res.objectType = 'Case';
            res.success = false;
            res.records = new List<Case>();
            res.totalMatches = 0;
            res.ambiguous = false;
            res.moreResultsAvailable = false;
            res.confirmationRequired = false;
            res.emailCount = 0;
            
            try {
                String op = inferOperation(req);
                res.operation = op;
                
                // Handle SUMMARIZE operation
                if (op == 'summarize') {
                    executeSummarizeOperation(req, res);
                    responses.add(res);
                    continue;
                }
                
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
                        List<Case> cases = [SELECT Id, Subject FROM Case WHERE Id = :req.recordId LIMIT 1];
                        if (!cases.isEmpty()) {
                            res.message = 'This will delete Case \'' + cases[0].Subject + '\' and all related records. Call again with confirm=true to proceed.';
                            res.success = true;
                        } else {
                            res.message = 'Case not found with ID ' + req.recordId + '.';
                            res.errorMessage = res.message;
                            res.success = false;
                        }
                    } catch (Exception e) {
                        res.message = 'This will delete the Case. Call again with confirm=true to proceed.';
                        res.success = true;
                    }
                    responses.add(res);
                    continue;
                }
                
                AFUniversalCrmRecordAction.Request actionReq = new AFUniversalCrmRecordAction.Request();
                actionReq.objectApiName = 'Case';
                actionReq.operation = op;
                actionReq.recordId = req.recordId;
                actionReq.fieldDataJson = req.fieldDataJson;
                actionReq.accountName = req.accountName;
                actionReq.contactNameOrEmail = req.contactNameOrEmail;
                actionReq.confirm = req.confirm;
                actionReq.searchTerm = req.searchTerm;
                actionReq.filtersJson = req.filtersJson;
                actionReq.searchLimit = req.searchLimit;
                
                if ((op == 'create' || op == 'update') && !String.isBlank(req.fieldDataJson)) {
                    try {
                        Object parsed = JSON.deserializeUntyped(req.fieldDataJson);
                        Boolean isBulk = parsed instanceof List<Object>;
                        if (isBulk) {
                            actionReq.operation = op == 'create' ? 'bulkCreate' : 'bulkUpdate';
                            actionReq.bulkRecordsJson = req.fieldDataJson;
                            actionReq.fieldDataJson = null;
                        }
                    } catch (Exception e) {
                        System.debug(LoggingLevel.DEBUG, 'AFCaseAction: fieldDataJson is not a bulk array, treating as single record');
                    }
                }
                
                AFUniversalCrmRecordAction.Response actionRes = AFUniversalCrmRecordAction.processRequest(actionReq);
                
                if (actionRes.success) {
                    res.success = true;
                    res.message = actionRes.message != null ? actionRes.message : 'Operation completed successfully.';
                    res.previewOnly = actionRes.previewOnly != null ? actionRes.previewOnly : false;
                    res.enrichmentSuggested = actionRes.enrichmentSuggested != null ? actionRes.enrichmentSuggested : false;
                    res.suggestedFields = actionRes.suggestedFields;
                    res.previewData = actionRes.previewData;
                    res.availableFieldsJson = actionRes.availableFieldsJson;
                    res.ambiguousRelationship = actionRes.ambiguousRelationship != null ? actionRes.ambiguousRelationship : false;
                    res.ambiguousRelationshipType = actionRes.ambiguousRelationshipType;
                    res.relationshipCandidatesJson = actionRes.relationshipCandidatesJson;
                    res.ambiguous = actionRes.ambiguous != null ? actionRes.ambiguous : false;
                    res.totalMatches = actionRes.totalMatches != null ? actionRes.totalMatches : 0;
                    
                    if (actionRes.record != null) {
                        res.record = (Case) actionRes.record;
                        res.recordId = res.record.Id;
                        res.records = new List<Case>{ res.record };
                    } else if (actionRes.records != null && !actionRes.records.isEmpty()) {
                        res.records = new List<Case>();
                        for (SObject so : actionRes.records) {
                            res.records.add((Case) so);
                        }
                        if (res.records.size() == 1) {
                            res.record = res.records[0];
                            res.recordId = res.records[0].Id;
                        } else if (!res.records.isEmpty()) {
                            res.ambiguous = true;
                        }
                    } else if (actionRes.recordId != null) {
                        res.recordId = actionRes.recordId;
                    }
                    
                    if (op == 'find' || op == 'search') {
                        Integer searchLimit = req.searchLimit != null ? req.searchLimit : 5;
                        if (res.totalMatches >= searchLimit) {
                            res.moreResultsAvailable = true;
                        }
                    }
                    
                    // If email summary was requested on a read/find operation, add it
                    if (req.includeEmailSummary == true && res.record != null) {
                        addEmailSummaryToResponse(res.record.Id, res);
                    }
                } else {
                    res.success = false;
                    res.errorMessage = actionRes.message != null ? actionRes.message : 'Operation failed.';
                }
                
            } catch (AFUniversalCrmRecordAction.ActionException ae) {
                res.success = false;
                res.errorMessage = ae.getMessage();
                System.debug(LoggingLevel.ERROR, 'AFCaseAction: ActionException - ' + ae.getMessage());
            } catch (Exception e) {
                res.success = false;
                res.errorMessage = 'Error performing Case operation: ' + e.getMessage();
                System.debug(LoggingLevel.ERROR, 'AFCaseAction: Exception - ' + e.getMessage());
            }
            
            responses.add(res);
        }
        
        return responses;
    }
    
    /**
     * Execute the summarize operation - retrieves case details and related emails
     */
    private static void executeSummarizeOperation(Request req, Response res) {
        Id caseId = req.recordId;
        
        // If no recordId provided, try to find the case by search term
        if (caseId == null && !String.isBlank(req.searchTerm)) {
            caseId = findCaseBySearchTerm(req.searchTerm);
            if (caseId == null) {
                res.success = false;
                res.errorMessage = 'Could not find a case matching "' + req.searchTerm + '". Please provide a case number, subject, or account name.';
                res.message = res.errorMessage;
                return;
            }
        }
        
        if (caseId == null) {
            res.success = false;
            res.errorMessage = 'Please provide a Case ID or search term to summarize. You can use the case number (e.g., "00001182"), subject, or account name.';
            res.message = res.errorMessage;
            return;
        }
        
        // Query the Case with full details
        List<Case> cases = [
            SELECT Id, CaseNumber, Subject, Description, Status, Priority, Type, Origin,
                   Reason, ClosedDate, CreatedDate, LastModifiedDate,
                   Account.Name, Contact.Name, Contact.Email, Owner.Name,
                   SuppliedEmail, SuppliedName, SuppliedCompany, SuppliedPhone
            FROM Case
            WHERE Id = :caseId
            LIMIT 1
        ];
        
        if (cases.isEmpty()) {
            res.success = false;
            res.errorMessage = 'Case not found with ID ' + caseId;
            res.message = res.errorMessage;
            return;
        }
        
        Case theCase = cases[0];
        res.record = theCase;
        res.recordId = theCase.Id;
        res.records = new List<Case>{ theCase };
        
        // Add email summary
        addEmailSummaryToResponse(caseId, res);
        
        // Build comprehensive summary message
        String summaryMsg = buildSummaryMessage(theCase, res.emailCount);
        res.message = summaryMsg;
        res.success = true;
    }
    
    /**
     * Find a case by search term (case number, subject, or account name)
     */
    private static Id findCaseBySearchTerm(String searchTerm) {
        String escapedTerm = String.escapeSingleQuotes(searchTerm.trim());
        String likePattern = '%' + escapedTerm + '%';
        
        // First try exact case number match
        List<Case> cases = [
            SELECT Id FROM Case 
            WHERE CaseNumber = :escapedTerm
            LIMIT 1
        ];
        
        if (!cases.isEmpty()) {
            return cases[0].Id;
        }
        
        // Try case number with different formatting (user might say "1182" instead of "00001182")
        if (escapedTerm.isNumeric()) {
            cases = [
                SELECT Id FROM Case 
                WHERE CaseNumber LIKE :('%' + escapedTerm)
                ORDER BY LastModifiedDate DESC
                LIMIT 1
            ];
            
            if (!cases.isEmpty()) {
                return cases[0].Id;
            }
        }
        
        // Try fuzzy search on Subject and Account Name
        cases = [
            SELECT Id FROM Case
            WHERE Subject LIKE :likePattern
               OR Account.Name LIKE :likePattern
            ORDER BY LastModifiedDate DESC
            LIMIT 1
        ];
        
        if (!cases.isEmpty()) {
            return cases[0].Id;
        }
        
        return null;
    }
    
    /**
     * Add email summary data to the response
     */
    private static void addEmailSummaryToResponse(Id caseId, Response res) {
        // Query total email count
        Integer totalEmailCount = [SELECT COUNT() FROM EmailMessage WHERE ParentId = :caseId];
        res.emailCount = totalEmailCount;
        
        if (totalEmailCount == 0) {
            res.emailSummaryJson = '[]';
            res.caseSummaryData = buildCaseSummaryData(res.record, new List<EmailMessage>());
            return;
        }
        
        // Query the most recent emails
        List<EmailMessage> emails = [
            SELECT Id, Subject, TextBody, HtmlBody, MessageDate, 
                   FromAddress, ToAddress, FromName, ToIds,
                   Incoming, Status
            FROM EmailMessage
            WHERE ParentId = :caseId
            ORDER BY MessageDate DESC
            LIMIT :MAX_EMAILS_FOR_SUMMARY
        ];
        
        // Build email summary JSON
        List<Map<String, Object>> emailSummaries = new List<Map<String, Object>>();
        
        for (EmailMessage email : emails) {
            Map<String, Object> emailData = new Map<String, Object>();
            emailData.put('id', email.Id);
            emailData.put('subject', email.Subject);
            emailData.put('messageDate', email.MessageDate);
            emailData.put('fromAddress', email.FromAddress);
            emailData.put('fromName', email.FromName);
            emailData.put('toAddress', email.ToAddress);
            emailData.put('direction', email.Incoming == true ? 'Inbound (from customer)' : 'Outbound (to customer)');
            
            // Get the body text, stripping HTML if necessary
            String bodyText = getEmailBodyText(email);
            // Truncate if too long
            if (bodyText != null && bodyText.length() > MAX_EMAIL_BODY_LENGTH) {
                bodyText = bodyText.substring(0, MAX_EMAIL_BODY_LENGTH) + '... [truncated]';
            }
            emailData.put('bodySnippet', bodyText);
            
            emailSummaries.add(emailData);
        }
        
        res.emailSummaryJson = JSON.serialize(emailSummaries);
        res.caseSummaryData = buildCaseSummaryData(res.record, emails);
    }
    
    /**
     * Build comprehensive case summary data for agent consumption
     */
    private static String buildCaseSummaryData(Case theCase, List<EmailMessage> emails) {
        Map<String, Object> summaryData = new Map<String, Object>();
        
        // Case information
        Map<String, Object> caseInfo = new Map<String, Object>();
        caseInfo.put('caseNumber', theCase.CaseNumber);
        caseInfo.put('subject', theCase.Subject);
        caseInfo.put('status', theCase.Status);
        caseInfo.put('priority', theCase.Priority);
        caseInfo.put('type', theCase.Type);
        caseInfo.put('origin', theCase.Origin);
        caseInfo.put('reason', theCase.Reason);
        caseInfo.put('description', theCase.Description);
        caseInfo.put('accountName', theCase.Account != null ? theCase.Account.Name : null);
        caseInfo.put('contactName', theCase.Contact != null ? theCase.Contact.Name : null);
        caseInfo.put('contactEmail', theCase.Contact != null ? theCase.Contact.Email : null);
        caseInfo.put('ownerName', theCase.Owner != null ? theCase.Owner.Name : null);
        caseInfo.put('createdDate', theCase.CreatedDate);
        caseInfo.put('lastModifiedDate', theCase.LastModifiedDate);
        caseInfo.put('closedDate', theCase.ClosedDate);
        caseInfo.put('suppliedEmail', theCase.SuppliedEmail);
        caseInfo.put('suppliedName', theCase.SuppliedName);
        caseInfo.put('suppliedCompany', theCase.SuppliedCompany);
        summaryData.put('caseInfo', caseInfo);
        
        // Email thread (chronological order for narrative)
        List<Map<String, Object>> emailThread = new List<Map<String, Object>>();
        
        // Reverse to get chronological order (oldest first) for the narrative
        for (Integer i = emails.size() - 1; i >= 0; i--) {
            EmailMessage email = emails[i];
            Map<String, Object> emailEntry = new Map<String, Object>();
            emailEntry.put('date', email.MessageDate);
            emailEntry.put('from', String.isNotBlank(email.FromName) ? email.FromName : email.FromAddress);
            emailEntry.put('to', email.ToAddress);
            emailEntry.put('direction', email.Incoming == true ? 'Inbound' : 'Outbound');
            emailEntry.put('subject', email.Subject);
            
            String bodyText = getEmailBodyText(email);
            if (bodyText != null && bodyText.length() > MAX_EMAIL_BODY_LENGTH) {
                bodyText = bodyText.substring(0, MAX_EMAIL_BODY_LENGTH) + '... [truncated]';
            }
            emailEntry.put('body', bodyText);
            
            emailThread.add(emailEntry);
        }
        summaryData.put('emailThread', emailThread);
        
        // Metadata
        Map<String, Object> metadata = new Map<String, Object>();
        metadata.put('totalEmailCount', emails.size());
        metadata.put('hasMoreEmails', emails.size() >= MAX_EMAILS_FOR_SUMMARY);
        metadata.put('summarizedAt', DateTime.now());
        summaryData.put('metadata', metadata);
        
        // Suggested action items based on case state
        List<String> suggestedActions = new List<String>();
        if (theCase.Status == 'New' || theCase.Status == 'Open') {
            suggestedActions.add('Review the case and update status to Working/In Progress');
        }
        if (theCase.Priority == 'High' || theCase.Priority == 'Critical') {
            suggestedActions.add('This is a high-priority case - consider escalating or prioritizing response');
        }
        if (emails.isEmpty()) {
            suggestedActions.add('No email communication yet - consider reaching out to the customer');
        } else if (!emails.isEmpty() && emails[0].Incoming == true) {
            suggestedActions.add('Last communication was from customer - response may be needed');
        }
        summaryData.put('suggestedActions', suggestedActions);
        
        return JSON.serialize(summaryData);
    }
    
    /**
     * Get the plain text body from an email, stripping HTML if necessary
     */
    private static String getEmailBodyText(EmailMessage email) {
        // Prefer TextBody if available
        if (String.isNotBlank(email.TextBody)) {
            return email.TextBody.trim();
        }
        
        // Fall back to stripping HTML from HtmlBody
        if (String.isNotBlank(email.HtmlBody)) {
            return stripHtmlTags(email.HtmlBody);
        }
        
        return '[No email body content]';
    }
    
    /**
     * Strip HTML tags from content to get plain text
     */
    private static String stripHtmlTags(String html) {
        if (String.isBlank(html)) {
            return '';
        }
        
        String text = html;
        
        // Remove style and script blocks entirely
        text = text.replaceAll('(?i)<style[^>]*>.*?</style>', '');
        text = text.replaceAll('(?i)<script[^>]*>.*?</script>', '');
        
        // Replace common block elements with newlines
        text = text.replaceAll('(?i)</p>', '\n\n');
        text = text.replaceAll('(?i)<br\\s*/?>','\n');
        text = text.replaceAll('(?i)</div>', '\n');
        text = text.replaceAll('(?i)</tr>', '\n');
        text = text.replaceAll('(?i)</li>', '\n');
        
        // Remove all remaining HTML tags
        text = text.replaceAll('<[^>]+>', '');
        
        // Decode common HTML entities
        text = text.replace('&nbsp;', ' ');
        text = text.replace('&amp;', '&');
        text = text.replace('&lt;', '<');
        text = text.replace('&gt;', '>');
        text = text.replace('&quot;', '"');
        text = text.replace('&#39;', '\'');
        text = text.replace('&apos;', '\'');
        
        // Clean up excessive whitespace
        text = text.replaceAll('\\n\\s*\\n\\s*\\n', '\n\n');
        text = text.replaceAll('[ \\t]+', ' ');
        
        return text.trim();
    }
    
    /**
     * Build a human-readable summary message
     */
    private static String buildSummaryMessage(Case theCase, Integer emailCount) {
        List<String> parts = new List<String>();
        
        parts.add('Case Summary for ' + theCase.CaseNumber + ': "' + theCase.Subject + '"');
        parts.add('');
        parts.add('Status: ' + theCase.Status + ' | Priority: ' + theCase.Priority);
        
        if (theCase.Account != null) {
            parts.add('Account: ' + theCase.Account.Name);
        }
        if (theCase.Contact != null) {
            parts.add('Contact: ' + theCase.Contact.Name + (theCase.Contact.Email != null ? ' (' + theCase.Contact.Email + ')' : ''));
        }
        
        parts.add('');
        parts.add('Email Communications: ' + emailCount + ' message' + (emailCount != 1 ? 's' : '') + ' found');
        
        if (emailCount > 0) {
            parts.add('');
            parts.add('Review the emailSummaryJson and caseSummaryData fields for the full email thread and to provide the user with:');
            parts.add('1. TL;DR - Quick summary of the case and key issues');
            parts.add('2. Communication History - Summary of the email thread');
            parts.add('3. Action Items - Recommended next steps');
        }
        
        return String.join(parts, '\n');
    }
}
