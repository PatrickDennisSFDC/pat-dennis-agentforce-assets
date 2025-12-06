public class ResetDemo {
    @AuraEnabled
    public static String resetDemoMethod() {
        // * For the Case with the Subject “Diabetes Consultation Appointment” (Record ID 500B0000002vzQiIAI)
    	// * Change Case Status back to “New”
    	// * Reset the time on the Milestones component - Milestones is entitlements
    	// * Delete the chatter for 2 users
    	// 
    	// Potentially delete the Case and reinsert potentially
    	// Jennifer Budurka 

        try {
            
            // Clone the Case
            List<Case> originalCases = [SELECT Subject,OwnerId,Origin,Status,Priority,AccountId,ContactId,EntitlementId,RecordTypeId FROM Case
                                        WHERE Subject = 'Diabetes Consultation Appointment'];
            Case clonedCase = originalCases[0].clone(false, true);
            // Set the new fields and insert
            clonedCase.Status = 'New';
            insert clonedCase;
            
            // Add the attached article
            CaseArticle ca = new CaseArticle();
            ca.CaseId = clonedCase.Id;
            ca.KnowledgeArticleId = [SELECT KnowledgeArticleId,Title FROM Knowledge__kav WHERE Title = 'Diabetes Consultation FAQ'].KnowledgeArticleId;
            insert ca;
            
            // Get rid of the old ones!
            delete originalCases;
            
            return 'Success';
        } catch (exception e) {
            return e.getMessage();
        }
    }
}