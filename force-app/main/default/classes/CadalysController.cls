public with sharing class CadalysController {

    @AuraEnabled
    public static string getCurrentUserFullName(){
        return UserInfo.getFirstName() + ' ' + UserInfo.getLastName();   
    }
}