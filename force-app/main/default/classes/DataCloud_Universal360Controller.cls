public class DataCloud_Universal360Controller {
    public DataCloud_Universal360Controller() {

    }

    @AuraEnabled
    public static List<xdo_dc_universal_360__c> getUniversalData (string recordId) {

       
        List<xdo_dc_universal_360__c> lstSOQLrecords = [
            select Id,Name, xdo_dc_Header_Subtitle__c,xdo_dc_Icon_for_Universal_360_Name__c,xdo_dc_Field_1__c,xdo_dc_Field_2_Email__c,xdo_dc_Field_3_Phone__c,
            xdo_dc_Field_4_Address__c,xdo_dc_Field_5__c,xdo_dc_Field_6_Number__c, xdo_dc_Field_7__c, xdo_dc_Field_8__c, xdo_dc_Field_9__c, 
            xdo_dc_Field_10__c,xdo_dc_Field_11__c,xdo_dc_Field_12__c,xdo_dc_Field_13__c,xdo_dc_Field_14__c,xdo_dc_Field_15_Image__c,
            xdo_dc_Field_16_Number__c,xdo_dc_Field_17_Number__c,xdo_dc_Field_18_Number__c,xdo_dc_Field_19_Number__c,
            xdo_dc_Label_for_Field_1__c,xdo_dc_Label_for_Field_2_Email__c,xdo_dc_Label_for_Field_3_Phone__c,
            xdo_dc_Label_for_Field_4_Address__c,xdo_dc_Label_for_Field_5__c,xdo_dc_Label_for_Field_6_Number__c,
            xdo_dc_Label_for_Field_7__c,xdo_Label_for_Field_8__c,xdo_dc_Label_for_Field_9__c,xdo_dc_Label_for_Field_10__c,
            xdo_dc_Label_for_Field_11__c,xdo_dc_Label_for_Field_12__c,xdo_dc_Label_for_Field_13__c,xdo_dc_Label_for_Field_14__c,
            xdo_dc_Label_for_Field_16_Number__c,xdo_dc_Label_for_Field_17__c,xdo_dc_Label_for_Field_18__c,xdo_dc_Label_for_Field_19__c,
            xdo_dc_Icon_for_Field_1__c,xdo_dc_Icon_for_Field_2_Email__c,xdo_dc_Icon_for_Field_3_Phone__c,xdo_dc_Icon_for_Field_4_Address__c,
            xdo_dc_Icon_for_Field_5__c,xdo_dc_Icon_for_Field_6_Number__c,xdo_dc_Icon_for_Field_7__c,xdo_dc_Icon_for_Field_8__c,
            xdo_dc_Icon_for_Field_9__c,xdo_dc_Icon_For_Field_10__c,xdo_dc_Icon_for_Field_11__c,xdo_dc_Icon_for_Field_12__c,xdo_dc_Icon_for_Field_13__c,
            xdo_dc_Icon_for_Field_14__c,xdo_dc_Icon_for_Field_16_Number__c,xdo_dc_Icon_for_Field_17__c,xdo_dc_Icon_for_Field_18__c,
            xdo_dc_Icon_for_Field_19__c,xdo_dc_Section_1_Active__c,xdo_dc_Section_2_Active__c,xdo_dc_Section_3_Active__c,
            xdo_dc_Section_KPI_Active__c,xdo_dc_Progress_bar_for_Field_17__c,xdo_dc_Progress_bar_for_Field_18__c,xdo_dc_Progress_bar_for_Field_19__c
            from xdo_dc_universal_360__c where Id 
            IN
            (SELECT xdo_dc_Universal_360_Id__c FROM xdo_dc_Universal_360_Child__c  WHERE xdo_dc_Universal_Record_Id__c = :recordId) ];

       
            if (!lstSOQLrecords.isEmpty()) {
                return lstSOQLrecords;
            } else {
                return new List<xdo_dc_universal_360__c>(); // No parent record found
            }

    }
    
    
}