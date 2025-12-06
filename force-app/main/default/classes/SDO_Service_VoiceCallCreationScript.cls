/**
 * @description       :
 * @author            : Stewart Anderson
 * @group             :
 * @last modified on  : 11-13-2023
 * @last modified by  : Stewart Anderson
 **/
public class SDO_Service_VoiceCallCreationScript{
    public static void createVoiceCall(){

        CallCoachingMediaProvider mediaProvider = [Select Id
                                                   From CallCoachingMediaProvider
                                                   Where ProviderName = 'Dialer'];

        User adminUser = [Select Id
                          From User
                          Where External_Id__c = 'User.001'];

        List<Map<String, Object>> voiceCalls = new List<Map<String, Object>>();
        Map<String, Object> voiceCall = new Map<String, Object>();

        voiceCall.put('mediaProviderId', mediaProvider.Id);
        voiceCall.put('userId', adminUser.Id);
        voiceCall.put('toPhoneNumber', '4151234567');
        voiceCall.put('fromPhoneNumber', '4157654321');
        voiceCall.put('startDateTime', DateTime.now().addMinutes(-5));
        voiceCall.put('endDateTime', DateTime.now());
        voiceCall.put('callType', 'Inbound');
        voiceCall.put('recordingDuration', '300'); // Keep it as String I don't know why
        voiceCall.put('externalId', 'VoiceCall.001'); // Can be referenced by using VendorCallKey
        voiceCall.put('recordingFormat', 'mp3');

        voiceCalls.add(voiceCall);

        Map<String, List<Map<String, Object>>> wrapper = new Map<String, List<Map<String, Object>>>(); //Kinda ugly might want to create a wrapper class
        wrapper.put('calls', voiceCalls);
        System.debug(JSON.serialize(wrapper));

        sendRequest('/voicecalls', 'POST', JSON.serialize(wrapper));
    }

    public static String sendRequest(String endpoint, String method, String body){
        HttpRequest req = new HttpRequest();
        req.setTimeout(120000);
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
        req.setHeader('Content-Type', 'application/json');
        req.setEndpoint(URL.getOrgDomainUrl().toExternalForm() + '/services/data/v58.0' + endpoint);
        req.setMethod(method);
        if (method != 'GET' && method != 'DELETE'){
            req.setBody(body);
        }

        HttpResponse res = (new Http()).send(req);
        System.debug(res);
        return res.getBody();
    }

}