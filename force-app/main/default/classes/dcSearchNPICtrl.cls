public with sharing class dcSearchNPICtrl {
 
 @AuraEnabled
 public static List < account > fetchAccount(String searchKeyWord) {
  String searchKey = searchKeyWord + '%';
  List < Account > returnList = new List < Account > ();
  List < Account > lstOfAccount = [select id, Name, Type, Billing_NPI__c, Industry, Phone, Fax from account where Billing_NPI__c LIKE: searchKey];
 
  for (Account acc: lstOfAccount) {
   returnList.add(acc);
  }
  return returnList;
 }
}