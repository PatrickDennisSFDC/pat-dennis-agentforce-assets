public with sharing class AFTT_ClarifyContacts {
    @InvocableMethod(label='Fuzzy Contact Search')
    public static List<ContactResult> findContacts(List<SearchInput> inputs) {
        List<ContactResult> results = new List<ContactResult>();
        
        if (inputs == null || inputs.isEmpty()) return results;
        
        SearchInput input = inputs[0];
        String inputFirstName = input.firstName != null ? input.firstName.trim().toLowerCase() : '';
        String inputLastName = input.lastName != null ? input.lastName.trim().toLowerCase() : '';
        
        if (String.isBlank(inputFirstName) && String.isBlank(inputLastName)) return results;
        
        // Construct fuzzy search patterns
        String firstNamePattern = '%' + inputFirstName + '%';
        String lastNamePattern = '%' + inputLastName + '%';
        
        // Initial SOQL query to narrow down potential matches
        List<Contact> potentialContacts = [
            SELECT Id, FirstName, LastName, Account.Name, AccountId
            FROM Contact
            WHERE (FirstName LIKE :firstNamePattern OR LastName LIKE :lastNamePattern)
            LIMIT 100
        ];
        
        // List to hold contacts with their corresponding similarity scores
        List<ScoredContact> scoredContacts = new List<ScoredContact>();
        
        for (Contact c : potentialContacts) {
            Integer firstNameDistance = !String.isBlank(inputFirstName) && !String.isBlank(c.FirstName) ?
                getLevenshteinDistance(inputFirstName, c.FirstName.toLowerCase()) : null;
            Integer lastNameDistance = !String.isBlank(inputLastName) && !String.isBlank(c.LastName) ?
                getLevenshteinDistance(inputLastName, c.LastName.toLowerCase()) : null;
            
            // Calculate average distance; handle nulls appropriately
            Integer totalDistance = 0;
            Integer count = 0;
            if (firstNameDistance != null) {
                totalDistance += firstNameDistance;
                count++;
            }
            if (lastNameDistance != null) {
                totalDistance += lastNameDistance;
                count++;
            }
            if (count == 0) continue; // Skip if both distances are null
            
            Decimal averageDistance = (Decimal)totalDistance / count;
            
            scoredContacts.add(new ScoredContact(c, averageDistance));
        }
        
        // Sort contacts by ascending average distance
        scoredContacts.sort();
        
        // Select top 3 contacts
        Integer maxResults = 3;
        for (Integer i = 0; i < Math.min(maxResults, scoredContacts.size()); i++) {
            Contact c = scoredContacts[i].contact;
            ContactResult cr = new ContactResult();
            cr.contactId = c.Id;
            cr.firstName = c.FirstName;
            cr.lastName = c.LastName;
            cr.accountId = c.AccountId;
            cr.accountName = c.Account != null ? c.Account.Name : null;
            results.add(cr);
        }
        
        return results;
    }
    
    // Helper class to associate contacts with their similarity scores
    private class ScoredContact implements Comparable {
        public Contact contact;
        public Decimal score;
        
        public ScoredContact(Contact contact, Decimal score) {
            this.contact = contact;
            this.score = score;
        }
        
        public Integer compareTo(Object obj) {
            ScoredContact other = (ScoredContact)obj;
            if (this.score < other.score) return -1;
            if (this.score > other.score) return 1;
            return 0;
        }
    }
    
    // Levenshtein distance implementation
    private static Integer getLevenshteinDistance(String s, String t) {
        if (s == null || t == null) return null;
        Integer n = s.length();
        Integer m = t.length();
        
        if (n == 0) return m;
        if (m == 0) return n;
        
        // Initialize the 2D list
        List<List<Integer>> d = new List<List<Integer>>();
        for (Integer i = 0; i <= n; i++) {
            List<Integer> row = new List<Integer>();
            for (Integer j = 0; j <= m; j++) {
                row.add(0);
            }
            d.add(row);
        }
        
        for (Integer i = 0; i <= n; i++) d[i][0] = i;
        for (Integer j = 0; j <= m; j++) d[0][j] = j;
        
        for (Integer i = 1; i <= n; i++) {
            for (Integer j = 1; j <= m; j++) {
                Integer cost = (s.substring(i - 1, i) == t.substring(j - 1, j)) ? 0 : 1;
                d[i][j] = Math.min(
                    Math.min(d[i - 1][j] + 1, d[i][j - 1] + 1),
                    d[i - 1][j - 1] + cost
                );
            }
        }
        
        return d[n][m];
    }
    
    public class SearchInput {
        @InvocableVariable(label='First Name')
        public String firstName;
        
        @InvocableVariable(label='Last Name')
        public String lastName;
    }
    
    public class ContactResult {
        @InvocableVariable(label='Contact ID')
        public Id contactId;
        
        @InvocableVariable(label='First Name')
        public String firstName;
        
        @InvocableVariable(label='Last Name')
        public String lastName;
        
        @InvocableVariable(label='Account ID')
        public Id accountId;
        
        @InvocableVariable(label='Account Name')
        public String accountName;
    }
}