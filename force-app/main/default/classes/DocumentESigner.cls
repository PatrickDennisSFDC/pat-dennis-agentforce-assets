global with sharing class DocumentESigner Implements System.Callable{
    
    //private static final String ENDPOINT = 'callout:AUTOSCHEDULER/services/data/v56.0/connect/e-sign/signature-requests/a53Hp000000wlrBIAQ/envelope/send';
    public Object call(String action, Map<String, Object> args) {
        // Extract inputMap from args
        Map<String,Object> inputMap = (Map<String,Object>)args.get('input');
        //Map<String,Object> inputMap = args;
        // Extract necessary parameters from inputMap
        String namedcred = (String) inputMap.get('namedcred');
        String parentId = (String) inputMap.get('parentId');
        String email = (String) inputMap.get('email');
        String name = (String) inputMap.get('name');
        String documentName = (String) inputMap.get('documentName');
        String sourceId = (String) inputMap.get('sourceId');
        
        // Debug log the values
        System.debug('Named Creds: ' + namedcred);
        System.debug('parentId: ' + parentId);
        System.debug('email: ' + email);
        System.debug('name: ' + name);
        System.debug('documentName: ' + documentName);
        System.debug('sourceId: ' + sourceId);
        
        // Call the sendSignatureRequest method
        sendSignatureRequest(namedcred, parentId, email, name, documentName, sourceId);
        
        return 'Request sent successfully';
    }
    
    private void sendSignatureRequest(String namedcred,String parentId, String email, String name, String documentName, String sourceId ) {
        
        HttpRequest req = new HttpRequest();
        String ENDPOINT = 'callout:'+namedcred+'/services/data/v56.0/connect/e-sign/signature-requests/'+parentId+'/envelope/send';
       // system.debug('ENDPOINT' + ENDPOINT);
        req.setEndpoint(ENDPOINT);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
       // system.debug('JSON Payload:' + getJsonPayload( parentId,  email,  name,  documentName,  sourceId));
        req.setBody(getJsonPayload( parentId,  email,  name,  documentName,  sourceId));
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        
        System.debug('Response Status: ' + res.getStatus() + ' ' + res.getStatusCode());
        System.debug('Response Body: ' + res.getBody());
        if(res.getStatusCode() != 200) {
            System.debug('Failed to send request: ' + res.getStatus());
        } else {
            System.debug('Request sent successfully.');
        }
    }
    private static String getJsonPayload(String parentId, String email, String name, String documentName, String sourceId) {
        return '{'
            + '"parentId": "' + parentId + '",'
            + '"emailSettings": {'
            + '"emailSubject": "Please sign this ' + documentName + '",'
            + '"emailBody": "' + documentName + '-Sent Via DocuSign Envelope"'
            + '},'
            + '"recipients": {'
            + '"signers": ['
            + '{'
            + '"email": "' + email + '",'
            + '"signerRole": "1",'
            + '"routingOrder": "1",'
            + '"recipientId": "1",'
            + '"routingNumber": "1",'
            + '"recipientType": "signer",'
            + '"recipientLocale": "EN",'
            + '"name": "' + name + '"'
            + '}'
            + ']'
            + '},'
            + '"documents": ['
            + '{'
            + '"documentId": "1",'
            + '"name": "' + documentName + '",'
            + '"fileExtension": "docx",'
            + '"sourceType": "Content",'
            + '"sourceId": "' + sourceId + '"'
            + '}'
            + ']'
            + '}';
    }
    
    
    
}