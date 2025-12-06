/*
Author: Radif Masud
Usage: Checks if the TrialTemplate object is present in the org. Hence this is a TSO
*/
global class DEOrgCheck implements vlocity_ins.VlocityOpenInterface, Callable
{
 public Object call(String action, Map<String, Object> args) {
     Map<String,Object> inputMap = (Map<String,Object>)args.get('input');
     Map<String,Object> outputMap = (Map<String,Object>)args.get('output');
     Map<String,Object> options = (Map<String,Object>)args.get('options');
     return invokeMethod(action, inputMap, outputMap, options);
   }
    global boolean InvokeMethod(String methodName,
            Map<String,Object> inputs,
            Map<String,Object> output,
            Map<String,Object> options)
    {
        if (methodName == 'istso')
        {
            output.put('isTSO',isTSO());
            return true;
        }
        return false;
    }
    boolean isTSO()
    {
        string soql ='select id from TrialTemplate LIMIT 1';
        try
        {
            List<SObject> data = Database.query('select id from TrialTemplate LIMIT 1');
            if(data != null && data.size()>=0)
                return true;
        }
        catch(Exception ex)
        {
        }
        return false;
    }
}