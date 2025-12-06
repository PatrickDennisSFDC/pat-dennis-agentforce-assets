/**
 * This class provides utilities to register a Community/Experience Cloud user
 *
 *
 * History
 * -------
 * v1.0 - Apr 26, 2021 - Initial Version for Multiplay Demo
 * v1.1 - Jul 20, 2021 - Added ability to generate Integration Procedure Platform Events
 * v1.2 - Sep 21, 2021 - Updated to supress welcome emails, moved publishIPEvent to DemoOrgUtils class
 * v1.3 - Apr 27, 2022 - Added assignPermissionSet() and assignLicense() functions
 * v1.4 - Jun 30, 2022 - Added assignPermissionSetLicenses() function
 * v1.5 - Aug  8, 2022 - Added support for portal user creation from Salesforce Console
 */
global without sharing class DemoUserRegistration implements Callable {

public Object call(String action, Map<String, Object> args) {
      return invokeMethod(action, (Map<String, Object>)args.get('input'), (Map<String, Object>)args.get('output'), (Map<String, Object>)args.get('options'));
    }

    // We will track explicit Salesforce Org Identifiers where we absolutely do not want to create
    // new community user accounts (to avoid polluting the Trialforce Source Orgs we create spins from)
    public final List<Id> TSO_ORGS = new List<Id>{
        '00D5e0000011gdXEAQ'  // Multiplay CDO
    };  

    public class UserRegistrationException extends Exception {}

    /**
     * Top level call by a Remote Action
     *
     * @param method  The method to execute
     * @param input   The input data provided in the call to this method
     * @param output  The output object where any results will be stored
     * @param options Any options to aid in the execution of this class
     *
     * @return true if the method completes successfully, false otherwise
     */ 
    global Boolean invokeMethod(String methodName, Map<String,Object> input, Map<String,Object> output, Map<String,Object> options) {
        
        try {      
            if (methodName == 'createCommunityUser') return createCommunityUser(input, output, options);
            else if (methodName == 'getCommunityUrl') return getCommunityUrl(input, output, options);
            else if (methodName == 'assignPermissionSet') return assignPermissionSet(input, output, options);
            else if (methodName == 'assignLicense') return assignLicense(input, output, options);
            else if (methodName == 'assignPermissionSetLicense') return assignPermissionSetLicense(input, output, options);
        }
        catch (Exception e) {
                        
            output.put('error', e.getMessage() + ':' + e.getStackTraceString());
        }
        return false;
    }

    /**
     * Attempts to create a new Community user
     * 
     * @param input   The input data provided in the call to this method
     * @param output  The output object where any results will be stored
     * @param options Any options to aid in the execution of this class
     * 
     * @return true if the function completed successfully, false otherwise
     */
    private Boolean createCommunityUser(Map<String,Object> input, Map<String,Object> output, Map<String,Object> options) {

        // Validate the input
        String username   = (String)input.get('Username');
        String email      = (String)input.get('Email');
        String firstName  = (String)input.get('FirstName');
        String lastName   = (String)input.get('LastName');
        String contactId  = (String)input.get('ContactId');
        String profileId  = (String)input.get('ProfileId');
        String password   = (String)input.get('Password');
        String accountId  = (String)input.get('AccountId');

        if (username == null || username == '')   throw new UserRegistrationException('Missing Username');
        if (email == null || email == '')         throw new UserRegistrationException('Missing Email');
        if (firstName == null || firstName == '') throw new UserRegistrationException('Missing FirstName');
        if (lastName == null || lastName == '')   throw new UserRegistrationException('Missing LastName');
        if (contactId == null || contactId == '') throw new UserRegistrationException('Missing ContactId');
        if (profileId == null || profileId == '') throw new UserRegistrationException('Missing ProfileId');
        if (accountId == null || accountId == '') throw new UserRegistrationException('Missing AccountId');

        // Create the Community User if this isn't a registered Trialforce Source Org
        if (!TSO_ORGS.contains(UserInfo.getOrganizationId())) {       

            User user = new User();
            user.FirstName         = firstname;
            user.LastName          = lastName;
            user.Email             = email;
            user.Alias             = (firstName.deleteWhitespace().toLowerCase().substring(0, 1) + lastName.deleteWhitespace().toLowerCase()).left(8);
            user.Username          = username;
            user.CommunityNickname = username.left(username.indexOf('@'));
            user.ContactId         = contactId;
            user.LocaleSidKey      = 'en_US';
            user.TimeZoneSidKey    = 'GMT';
            user.ProfileID         = profileId;
            user.LanguageLocaleKey = 'en_US';
            user.EmailEncodingKey  = 'UTF-8';
            user.IsActive          = true;

            Id userId = null;
            // If we are the guest user within a community create the new user via the Site class
            // Otherwise, create via the User class
            if (Auth.CommunitiesUtil.isGuestUser()) userId = Site.createExternalUser(user, accountId, password, false);            
            else {

                insert user;
                userId = user.Id;

                System.resetPassword(userId, true);
            }

            // Suppress Email if a password was provided
            //if (password != null && !password.equals('')) {
            //    Database.DMLOptions dmlOptions = new Database.DMLOptions();
            //    dmlOptions.EmailHeader.TriggerUserEmail = false;
            //    dmlOptions.EmailHeader.TriggerAutoResponseEmail = false;
            //    user.setOptions(dmlOptions);
            //}
            //insert user;

            // Set the password if one has been provided
            //if (password != null && !password.equals('')) {
            //    setPasswordFuture(user.Id, password);
            //}

            // Set the Account & Contact record ownership
            // Note: This is currently disabled as either update will throw the following error: portal users cannot own partner accounts
            //Account account = [SELECT Id, OwnerId FROM Account WHERE Id=:accountId][0];
            //account.OwnerId = userId;
            //update account;

            //Contact contact = [SELECT Id, OwnerId FROM Contact WHERE Id=:contactId][0];
            //contact.OwnerId = userId;
            //update contact;

            // Add the User Id to the output
            output.put('UserId', userId);           
        }
        else System.debug(LoggingLevel.WARN, 'User not created as we are in a Trialforce Source Org!');

        return true;
    }

    /**
     * Attempts to set the user's password.  This is done using an @future method
     * to be sure it works properly.
     * 
     * NOTE: This is still tempermental ... works great sometimes and other times the user
     *       cannot login.  I recommend NOT using this for now!
     * 
     * @see https://salesforce.stackexchange.com/questions/219114/system-setpassword-during-user-creation-sets-password-but-user-cannot-login
     * 
     * @param userId    The user Id
     * @param password  The text password to set
     */
    @future
    private static void setPasswordFuture(String userId, String password) {

        System.setPassword(userId, password);
    }

    /**
     * Returns the Community Login URL for the given community
     * 
     * @param input   The input data provided in the call to this method
     * @param output  The output object where any results will be stored
     * @param options Any options to aid in the execution of this class
     * 
     * @return true if the function completed successfully, false otherwise
     */
    private Boolean getCommunityUrl(Map<String,Object> input, Map<String,Object> output, Map<String,Object> options) {

        String errorMsg  = null;
        String communityName = (String)input.get('CommunityName');

        if (communityName != null && !communityName.deleteWhitespace().equals('')) {
            
            Network[] networks = [SELECT Id FROM Network WHERE Name=:communityName LIMIT 1];
            if (!networks.isEmpty()) {

                output.put('CommunityLoginUrl', Network.getLoginUrl(networks[0].Id));
            }
            else errorMsg = 'Community "' + communityName + '" not found';
        }
        else errorMsg = 'Missing CommunityName';
        
        // Return an error if we have an input data issues
        if (errorMsg != null) {
            output.put('error', true);
            output.put('errorMsg', errorMsg);
            return false;
        }

        return true;
    }

    /**
     * Assigns a Permission Set to the User
     * 
     * @param input   The input data provided in the call to this method
     * @param output  The output object where any results will be stored
     * @param options Any options to aid in the execution of this class
     * 
     * @return true if the function completed successfully, false otherwise
     */
    private Boolean assignPermissionSet(Map<String,Object> input, Map<String,Object> output, Map<String,Object> options) {

        String permSet  = (String)input.get('PermissionSetName');
        String userId   = (String)input.get('UserId');

        if (userId == null || userId == '') throw new UserRegistrationException('Missing UserId');
        if (permSet == null || permSet == '') throw new UserRegistrationException('Missing PermissionSetName');

        PermissionSet[] pms = [ SELECT Id FROM PermissionSet WHERE Label=:permSet LIMIT 1 ];

        // Add a Permission Set if we found one
        if (!pms.isEmpty()) {
                
            PermissionSetAssignment psa = new PermissionSetAssignment();
            psa.PermissionSetId = pms[0].Id;
            psa.AssigneeId = userId;

            insert psa;      
        }
        else throw new UserRegistrationException('Permission Set (' + permSet + ') not found!');

        return true;
    }
    
    /**
     * Assigns a Managed Package License to the User
     * 
     * @param input   The input data provided in the call to this method
     * @param output  The output object where any results will be stored
     * @param options Any options to aid in the execution of this class
     * 
     * @return true if the function completed successfully, false otherwise
     */
    private Boolean assignLicense(Map<String,Object> input, Map<String,Object> output, Map<String,Object> options) {

        String userId  = (String)input.get('UserId');
        String license = (String)input.get('License');

        if (userId == null || userId == '') throw new UserRegistrationException('Missing UserId');
        if (license == null || license == '') throw new UserRegistrationException('Missing License');

        // Get the Package by Namespace (i.e. vlocity_cmt, etc.)
        List<PackageLicense> pkgs = [ SELECT Id FROM PackageLicense WHERE NamespacePrefix=:license LIMIT 1 ];

        // Assign the User to the License
        if (!pkgs.isEmpty()) {

            UserPackageLicense newLic = new UserPackageLicense();
            newLic.UserId = userId;
            newLic.PackageLicenseId = pkgs.get(0).Id;

            insert newLic;
        }
        else throw new UserRegistrationException('Package License (' + license + ') not found!');

        return true;
    }

    /**
     * Assigns a Permission Set License (PSL) to the User
     * 
     * @param input   The input data provided in the call to this method
     * @param output  The output object where any results will be stored
     * @param options Any options to aid in the execution of this class
     * 
     * @return true if the function completed successfully, false otherwise
     */
    private Boolean assignPermissionSetLicense(Map<String,Object> input, Map<String,Object> output, Map<String,Object> options) {

        String pslName = (String)input.get('PermissionSetLicenseName');
        String userId  = (String)input.get('UserId');

        if (userId == null || userId == '') throw new UserRegistrationException('Missing UserId');
        if (pslName == null || pslName == '') throw new UserRegistrationException('Missing PermissionSetLicenseName');

        PermissionSetLicense[] licenses = [ SELECT Id FROM PermissionSetLicense WHERE DeveloperName=:pslName LIMIT 1 ];

        // Add a Permission Set License if we found it
        if (!licenses.isEmpty()) {
                
            PermissionSetLicenseAssign assignment = new PermissionSetLicenseAssign();
            assignment.PermissionSetLicenseId = licenses[0].Id;
            assignment.AssigneeId = userId;

            insert assignment;      
        }
        else throw new UserRegistrationException('Permission Set License (' + pslName + ') not found!');

        return true;
    }    
}