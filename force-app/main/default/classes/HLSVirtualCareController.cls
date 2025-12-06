public class HLSVirtualCareController {
    @AuraEnabled
    public static List<XDOAppointmentWrapper> getAppointments(){
        Id currentUserId = UserInfo.getUserId();
        List<XDOAppointmentWrapper> currentAppointments = null;
        DateTime aDayFromNow = System.now().addDays(1);
        try{
            List<Contact> contacts = [SELECT Id,
                                             Name,
                                             Birthdate,
                                             xDO_Preferred_First_Name__c,
                                             xDO_Preferred_Last_Name__c,
                                             xDO_Image_URL__c
                                             FROM Contact];
            List<ServiceAppointment> serviceAppointments = [SELECT Id,
                                                                    ParentRecordId,
                                                                    ParentRecord.Name,
                                                                    ParentRecord.FirstName,
                                                                    ParentRecord.LastName,
                                                                    Status,
                                                                    Subject,
                                                                    Description,
                                                                    SchedStartTime,
                                                                    SchedEndTime,
                                                            		EarliestStartTime,
                                                            		DueDate
                                                                    FROM ServiceAppointment
                                                                    WHERE AppointmentType = 'Virtual Care Appointment'
                                                                    AND ParentRecordId <> ''
                                                                    AND OwnerId = :currentUserId
                                                                    ORDER BY EarliestStartTime ASC
                                                                    LIMIT 100];
            currentAppointments = new List<XDOAppointmentWrapper>();
            if(serviceAppointments == null || serviceAppointments.size() == 0){
                return currentAppointments;
            }
            for(ServiceAppointment appt : serviceAppointments){
                Boolean appointmentWithin24Hours = false;
                Boolean appointmentToday = false;
                
                Datetime startTime;
                Datetime endTime;
                if(appt.SchedStartTime != null){
                    startTime = appt.SchedStartTime;
                } else{
                    startTime = appt.EarliestStartTime;
                }
                if(appt.SchedEndTime != null){
                    endTime = appt.SchedEndTime;
                } else{
                    endTime = appt.DueDate;
                }
               
                if(startTime < aDayFromNow){
                    appointmentWithin24Hours = true;
                }
                if(startTime.day() == System.now().day()){
                    appointmentToday = true;
                }

                XDOAppointmentWrapper appointmentWrapper = new XDOAppointmentWrapper();
                appointmentWrapper.appointmentId = appt.Id;
                appointmentWrapper.personAccountId = appt.ParentRecordId;
                appointmentWrapper.meetingWithName = appt.ParentRecord.Name;
                appointmentWrapper.meetingWithFirstName = appt.ParentRecord.FirstName;
                appointmentWrapper.meetingWithLastName = appt.ParentRecord.LastName;
                
                for (Integer i = 0; i < contacts.size(); i++) {
                    Contact contact = contacts.get(i);
                    if(contact.Name == appt.ParentRecord.Name){
                        appointmentWrapper.meetingWithDOB = contact.Birthdate;
                        appointmentWrapper.meetingWithPreferredFirstName = contact.xDO_Preferred_First_Name__c;
                        appointmentWrapper.meetingWithPreferredLastName = contact.xDO_Preferred_Last_Name__c;
                        appointmentWrapper.meetingWithImageURL = contact.xDO_Image_URL__c;
                        break;
                    }
                }

                appointmentWrapper.subject = appt.Subject;
                appointmentWrapper.description = appt.Description;
                appointmentWrapper.schedStartTime = startTime;
                appointmentWrapper.schedEndTime = endTime;

                Date apptDate = date.newinstance(startTime.year(), startTime.month(), startTime.day());

                appointmentWrapper.appointmentDate = apptDate;
                appointmentWrapper.appointmentWithin24Hours = appointmentWithin24Hours;
                if(startTime < System.now()){
                    appointmentWrapper.appointmentStarted = true;
                } else{
                    appointmentWrapper.appointmentStarted = false;
                }
                if(endTime < System.now()){
                    appointmentWrapper.appointmentEnded = true;
                } else if(appt.Status == 'Completed'){
                    appointmentWrapper.appointmentEnded = true;
                } else{
                    appointmentWrapper.appointmentEnded = false;
                }
                appointmentWrapper.appointmentToday = appointmentToday;
                appointmentWrapper.formattedDate = getMonthName(startTime.month()) + ' ' + startTime.day() + ', ' + startTime.year();

                Integer startHour = startTime.hour();
                String amPM = 'AM';
                if(startHour >= 12){
                    startHour -= 12;
                    if(startHour == 0){
                        startHour = 12;
                    }
                    amPM = 'PM';
                }
                if(startHour == 0){
                    startHour = 12;
                }
                String minutes = String.valueOf(startTime.minute());
                if(startTime.minute() == 0){
                    minutes = 0 + minutes;
                }
                appointmentWrapper.formattedStartTime = startHour + ':' + minutes + ' ' + amPM;

                String fullTimeZone = UserInfo.getTimeZone().getDisplayName();
                String timeZone;
                if(fullTimeZone.contains('Eastern Standard Time')){
                    timeZone = 'EST';
                } else if(fullTimeZone.contains('Central Standard Time')){
                    timeZone = 'CST';
                }
                else if(fullTimeZone.contains('Mountain Standard Time')){
                    timeZone = 'MST';
                }
                else if(fullTimeZone.contains('Pacific Standard Time')){
                    timeZone = 'PST';
                }
                else{
                    timeZone = 'Other time zone';
                }
                appointmentWrapper.timeZone = timeZone;
                currentAppointments.add(appointmentWrapper);
            }
        }
        catch(QueryException e){
            System.debug('error: ' + e);
        }
        return currentAppointments;
    }

    @AuraEnabled
    public static String endVideoCall(String appointmentId){
        ServiceAppointment appt = [SELECT Id, Status FROM ServiceAppointment WHERE Id = :appointmentId LIMIT 1];
        appt.Status = 'Completed';
        String apptUpdated = 'Appointment updated!';
        try{
            update appt;
        } catch(DmlException e){
            apptUpdated = 'Error updating event: ' + e.getMessage();
            System.debug('Error updating event: ' + e.getMessage());
        }
        return apptUpdated;
    }

    public static String getMonthName(Integer monthNumber){
        if(monthNumber == 1){
            return 'January';
        } else if (monthNumber == 2){
            return 'February';
        }
        else if (monthNumber == 3){
            return 'March';
        }
        else if (monthNumber == 4){
            return 'April';
        }
        else if (monthNumber == 5){
            return 'May';
        }
        else if (monthNumber == 6){
            return 'June';
        }
        else if (monthNumber == 7){
            return 'July';
        }
        else if (monthNumber == 8){
            return 'August';
        }
        else if (monthNumber == 9){
            return 'September';
        }
        else if (monthNumber == 10){
            return 'October';
        }
        else if (monthNumber == 11){
            return 'November';
        }
        else if (monthNumber == 12){
            return 'December';
        }
        return null;
    }
}