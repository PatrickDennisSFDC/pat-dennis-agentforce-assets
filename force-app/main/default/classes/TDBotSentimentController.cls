// TDBotSentimentController
public with sharing class TDBotSentimentController {
    @AuraEnabled(cacheable=true)
    public static string getTranscriptStatus(string recordId, string obj, string field, string username, string model) {

        System.debug(recordId);
        System.debug(obj);
        System.debug(field);
        sObject transcript = Schema.getGlobalDescribe().get(obj).newSObject();
        String query = 'SELECT Id, ' + field + '  FROM ' + obj + ' WHERE Id = \'' + String.escapeSingleQuotes(recordId) + '\' LIMIT 1';

        System.debug(query);

        transcript = Database.query(query);

        // LiveChatTranscript transcript = [SELECT Id , CaseId, Neutral_Sentiment__c, Positive_Sentiment__c, Negative_Sentiment__c, Body FROM LiveChatTranscript WHERE Id =: liveChatTranscriptId][0];

        string text = (String) transcript.get(field);

        System.debug(transcript);
        System.debug(text);

        // text = text.replace('\"','');
        // text = text.replace('\'','');

        string body = getSentiment(text, username, model);
        System.debug(body);

        // string test =  getAccessToken('tdunlop@salesforce.com');
        // System.debug(test);

        return body;
    }

    @AuraEnabled
    public static String getSentiment(String text, string username, string model) {
        string bod = (String) text;

        bod = bod.replace('\"', '');
        bod = bod.replace('\'', '');
        bod = bod.replace('\r\n', ' ');
        bod = bod.replace('\n', ' ');
        bod = bod.replace('\r', ' ');


        System.debug(text);
        System.debug(username);
        System.debug(model);


        string token = getAccessToken(username);

        System.debug(text);

        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint('https://api.einstein.ai/v2/language/sentiment');
        req.setHeader('Authorization', 'Bearer ' + token); //J5HEQWKSIJKVENSUJRDU2VBSLFKVAQSFKFIDEWBSJJHUQV2FI5CE4NKOIJMEIUZVG5GE2VSHLFNEKUCFGMZVORCDLBMUSVZTJEZFMRKJJRETKWSHI5ATIUSSKJGUINCPGI3FUWSXGNNEQRJUI5EFOQSJJJBEUR2PJM3ES7COIE
        req.setHeader('Content-type', 'application/json');

        String body = '{\"modelId\":\"' + model + '\",\"document\":\"' + bod + '\"}';
        // req.setBody('{"modelId":"sentimentModelId","document":"'+text+'"}');
        req.setBody(body);
        HTTPResponse res = http.send(req);

        System.debug(bod);

        Map<String, Object> meta = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        List<Map<String, Object>> myMaps = new List<Map<String, Object>>();
        List<Object> myMapObjects = (List<Object>) meta.get('probabilities');

        for (Object obj : myMapObjects) {

            myMaps.add((Map<String, Object>) obj);
        }
        System.debug(res.getBody());
        // LiveChatTranscript transcript = [SELECT Id , CaseId, Neutral_Sentiment__c, Positive_Sentiment__c, Negative_Sentiment__c, Body FROM LiveChatTranscript WHERE Id =: liveChatTranscriptId][0];

        return res.getBody();
    }


    @AuraEnabled
    public static string updateProbability(string recordId, string obj, string pos, string neg, string neut) {
        sObject transcript = Schema.getGlobalDescribe().get(obj).newSObject();
        String query = 'SELECT Id, Neutral_Sentiment__c, Positive_Sentiment__c, Negative_Sentiment__c  FROM ' + obj + ' WHERE Id = \'' + String.escapeSingleQuotes(recordId) + '\' LIMIT 1 ';
        System.debug(query);
        transcript = Database.query(query);
        //  LiveChatTranscript transcript = [SELECT Id , CaseId, Neutral_Sentiment__c, Positive_Sentiment__c, Negative_Sentiment__c, Body FROM LiveChatTranscript WHERE Id =: recordId][0];
        SObject so = Schema.getGlobalDescribe().get(OBJ).newSObject();
        System.debug(so.getSobjectType().getDescribe().fields.getMap().containsKey('Neutral_Sentiment__c'));

        Boolean posField = so.getSobjectType().getDescribe().fields.getMap().containsKey('Positive_Sentiment__c');
        Boolean negField = so.getSobjectType().getDescribe().fields.getMap().containsKey('Negative_Sentiment__c');
        Boolean neutField = so.getSobjectType().getDescribe().fields.getMap().containsKey('Neutral_Sentiment__c');

        if (posField && negField && neutField) {
            Decimal positive = decimal.valueOf(pos);
            Decimal negative = decimal.valueOf(neg);
            Decimal neutral = decimal.valueOf(neut);

            System.debug(positive);
            System.debug(negative);
            System.debug(neutral);

            transcript.put('Neutral_Sentiment__c', neutral);
            transcript.put('Positive_Sentiment__c', positive);
            transcript.put('Negative_Sentiment__c', negative);

            update transcript;
        }
        return 'success';
    }

    @AuraEnabled(cacheable=true)
    public static List<EmailMessage> emailAggregator(String recordId) {
        // public static Contact emailAggregator(String recordId){
        Contact con = [
                SELECT Id, Name, Email
                FROM Contact
                WHERE Id = :recordId
                LIMIT 1
        ];

        List<EmailMessage> emails = [
                SELECT Id, FromName,ParentId, Subject,TextBody,FromAddress, Positive_Sentiment__c, Neutral_Sentiment__c, Negative_Sentiment__c
                FROM EmailMessage
                WHERE FromAddress = :con.Email
        ];
        return emails;
    }


    @AuraEnabled
    public static string saveEmailSentiment(string recordId, decimal positive, decimal negative, decimal neutral) {

        List<EmailMessage> conts = [SELECT Id, FromAddress, Neutral_Sentiment__c, Positive_Sentiment__c, Negative_Sentiment__c FROM EmailMessage WHERE Id = :recordId LIMIT 1];

        System.debug(positive * 100);
        System.debug(negative * 100);
        System.debug(neutral * 100);
        System.debug(recordId);
        System.debug(conts[0].FromAddress);

        if (!conts.isEmpty()) {
            EmailMessage cont = conts[0];
            cont.Neutral_Sentiment__c = (neutral * 100);
            cont.Positive_Sentiment__c = (positive * 100);
            cont.Negative_Sentiment__c = (negative * 100);
            update cont;
        }

        return 'success';
    }

    public static String getAccessToken(String sub) {

        System.debug(sub);

        ContentVersion base64Content = [SELECT Title, VersionData FROM ContentVersion WHERE Title = 'einstein_private_key' LIMIT 1];
        String payloadBlob = EncodingUtil.base64Encode(base64Content.VersionData);

        String keyContents = base64Content.VersionData.toString();
        System.debug(keyContents);


        keycontents = keyContents.substringBefore('-----END RSA PRIVATE KEY-----');
        keycontents = keyContents.substringAfter('-----BEGIN RSA PRIVATE KEY-----');


        keyContents = keyContents.replace('\n', '');
        keyContents = keyContents.replace('\\', '');

        System.debug('KEY HERE');
        System.debug(keyContents);


        JWT jwt = new JWT('RS256');
        jwt.pkcs8 = keyContents;

        jwt.iss = 'developer.force.com';
        jwt.sub = sub;
        jwt.aud = 'https://api.einstein.ai/v2/oauth2/token';
        jwt.exp = '3600';
        String access_token = JWTBearerFlow.getAccessToken('https://api.einstein.ai/v2/oauth2/token', jwt);

        System.debug('TOKEN HERE');
        System.debug(access_token);
        return access_token;
    }


    @AuraEnabled(cacheable=true)
    public static sObject getSentimentStatus(string recordId, string obj) {

        sObject scores = Schema.getGlobalDescribe().get(obj).newSObject();
        String query = 'SELECT Neutral_Sentiment__c, Positive_Sentiment__c, Negative_Sentiment__c  FROM ' + obj + ' WHERE Id = \'' + String.escapeSingleQuotes(recordId) + '\' LIMIT 1';
        scores = Database.query(query);
        System.debug(scores);
        return scores;
    }


    @AuraEnabled
    public static Sentiment_Analysis__c addRealTimeSentiment(string recordId, string obj, string message, string username, string model) {

        string s = getSentiment(message, username, model);
        System.debug(s);
        // sObject scores = Schema.getGlobalDescribe().get(obj).newSObject();
        Sentiment_Analysis__c scores = new Sentiment_Analysis__c();

        Map<String, Object> meta = (Map<String, Object>) JSON.deserializeUntyped(s);
        System.debug(meta);

        List<Object> myMapObjects = (List<Object>) meta.get('probabilities');


        for (Object o : myMapObjects) {
            System.debug(o);
            String JSONString = JSON.serialize(o);
            // Object meta2 = JSON.deserializeUntyped(o);
            System.debug(JSONString);


            Map<String, Object> probabilityMeta = (Map<String, Object>) JSON.deserializeUntyped(JSONString);
            System.debug(probabilityMeta);


            String label = (String) probabilityMeta.get('label');
            System.debug(label);


            Decimal probability = (Decimal) probabilityMeta.get('probability');
            // System.debug(probability); 


            if (label == 'positive') {
                scores.Positive_Sentiment__c = probability ;
                System.debug(probability);
            } else if (label == 'negative') {
                scores.Negative_Sentiment__c = probability ;
                System.debug(probability);
            } else if (label == 'neutral') {
                scores.Neutral_Sentiment__c = probability ;
                System.debug(probability);
            }

        }

        scores.Message__c = message;
        if (obj == 'LiveChatTranscript') {
            scores.Chat_Transcript__c = recordId;
        } else if (obj == 'VoiceCall') {
            scores.Voice_Call__c = recordId;
        }
        System.debug(scores);


        try {
            insert scores;
        } catch (DmlException e) {
            System.debug('A DML exception has occurred: ' +
                    e.getMessage());
        }

        return scores;
    }

}