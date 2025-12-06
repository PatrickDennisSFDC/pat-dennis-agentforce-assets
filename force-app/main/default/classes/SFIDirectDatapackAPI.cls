@RestResource(urlMapping='/SFIDirectDatapackAPI/*')
global with sharing class SFIDirectDatapackAPI {
    
    @HttpPost
    global static void Deploy(string payload,string dpStep,string status)
    {
        Map<String,Object> results = new Map<String,Object>();

        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');
        Blob afterblob = EncodingUtil.base64Decode(payload);
        string decodedPayload = afterblob.toString(); 
        
        if(dpStep!=null && dpStep=='deploy')
        {
            system.debug('Decoded Deploy Payload:'+decodedPayload);
            
            Map<String, Object> currentStatus = vlocity_ins.DRDataPackRunnerController.runImport(decodedPayload);
            results.put('status',(String)currentStatus.get('Status'));
            results.put('dpStep','deploy'); // default the step as deploy if we are dealing with a larger datapack
            results.put('payload',EncodingUtil.base64Encode(blob.valueOf(JSON.serialize(currentStatus))));

            if(currentStatus.get('Status')=='Complete')
            {
                results.put('dpStep','activate'); //set the next step
            }
        }
        else if(dpStep!=null && dpStep=='activate')
        {

            Map<String,Object> currentStatus = (Map<String,Object>)JSON.deserializeUntyped(decodedPayload);
            string vlocityDataPackId = (string)currentStatus.get('VlocityDataPackId');
          	system.debug('Imported Datapack ID:'+vlocityDataPackId);
       
            Map<String, Object> activationData = new Map<String, Object>
            {
                'VlocityDataPackId' => currentStatus.get('VlocityDataPackId'),
                'VlocityDataPackKeysToActivate' => new List<String> { 'ALL' }
            };

          	currentStatus = vlocity_ins.DRDataPackRunnerController.runActivate(JSON.serialize(activationData));  
     
            results.put('status',(String)currentStatus.get('Status'));
            results.put('dpStep','activate'); //default to activate
      		results.put('payload', EncodingUtil.base64Encode(blob.valueOf(JSON.serialize(currentStatus))));

            if(currentStatus.get('Status')=='Complete')
            {
                results.put('dpStep','complete'); //update the step to complete
            }
        }
        else if(dpStep ==null || dpStep==''|| dpStep!='complete')
        {
            Map<String, Object> currentStatus = vlocity_ins.DRDataPackRunnerController.runImport(decodedPayload);
            results.put('status',(String)currentStatus.get('Status'));
      		results.put('dpStep','deploy');
            results.put('payload',EncodingUtil.base64Encode(blob.valueOf(JSON.serialize(currentStatus))));   
        }
        
        res.responseBody = blob.valueOf(JSON.serialize(results));
            
        return;
    }
    
    @HttpGet
    global static void Extract()
    {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');
        String dpType = req.params.get('dpType');
        String dpName = req.params.get('dpId');
        String dpId = req.params.get('dpId');
        String dpQueuedDPId = req.params.get('dpQueuedDPId');
        
        Map<string,Object> params = new Map<string,Object>();
        params.put('version',0);
        params.put('description','');
        params.put('name','SFI-QBRIX-EXPORT');
        params.put('VlocityDataPackId','');
        params.put('VlocityDataPackType',dpType);
        
        Map<string,Object> paramsData = new Map<string,Object>();
        paramsData.put('Id',dpId);
        
        params.put('VlocityDataPackData',paramsData);
        
        if(dpQueuedDPId!=null && dpQueuedDPId!='')
        {
            params.put('VlocityDataPackId',dpQueuedDPId);
      		params.put('maxDepth',-1);
            
            Map<String, Object> currentStatus = vlocity_ins.DRDataPackRunnerController.runExport(JSON.serialize(params));
            Map<String,Object> results = new Map<String,Object>();
            results.put('status',currentStatus.get('Status'));
            results.put('VlocityDataPackId',dpQueuedDPId);

            
            if(currentStatus.get('Status')=='Complete')
            {
                String dataPackData = vlocity_ins.DRDataPackRunnerController.getAllDataPackData(dpQueuedDPId);
              results.put('datapack', EncodingUtil.base64Encode(blob.valueOf(dataPackData)));
            }
            res.responseBody = blob.valueOf(JSON.serialize(results));
            
            return;
        }
        else
    {
            
      Map<String, Object> currentStatus = vlocity_ins.DRDataPackRunnerController.runExport(JSON.serialize(params));
      Map<String,Object> results = new Map<String,Object>();
            results.put('status',(String)currentStatus.get('Status'));
            results.put('VlocityDataPackId',(String)currentStatus.get('VlocityDataPackId'));
            String exportedDPId = (String)currentStatus.get('VlocityDataPackId');
            
       res.responseBody = blob.valueOf(JSON.serialize(results));
            return;

    }
	}
}