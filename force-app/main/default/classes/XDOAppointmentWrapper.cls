public class XDOAppointmentWrapper {
    @AuraEnabled
    public String appointmentId{get;set;}

    @AuraEnabled
    public String personAccountId{get;set;}

    @AuraEnabled
    public String meetingWithName{get;set;}

    @AuraEnabled
    public String meetingWithFirstName{get;set;}

    @AuraEnabled
    public String meetingWithLastName{get;set;}

    @AuraEnabled
    public String meetingWithPreferredFirstName{get;set;}

    @AuraEnabled
    public String meetingWithPreferredLastName{get;set;}

    @AuraEnabled
    public String meetingWithImageURL{get;set;}

    @AuraEnabled
    public Date meetingWithDOB{get;set;}

    @AuraEnabled
    public String subject{get;set;}

    @AuraEnabled
    public String description{get;set;}

    @AuraEnabled
    public DateTime schedStartTime{get;set;}

    @AuraEnabled
    public DateTime schedEndTime{get;set;}

    @AuraEnabled
    public Date appointmentDate{get;set;}

    @AuraEnabled
    public Boolean appointmentWithin24Hours{get;set;}

    @AuraEnabled
    public Boolean appointmentStarted{get;set;}

    @AuraEnabled
    public Boolean appointmentEnded{get;set;}

    @AuraEnabled
    public Boolean appointmentToday{get;set;}

    @AuraEnabled
    public String formattedDate{get;set;}

    @AuraEnabled
    public String formattedStartTime{get;set;}

    @AuraEnabled
    public String timeZone{get;set;}
}