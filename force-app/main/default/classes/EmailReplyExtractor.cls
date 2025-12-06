public class EmailReplyExtractor {
    @InvocableMethod(label='Extract Most Recent Email Reply')
    public static List<OutputWrapper> extractLatestReply(List<InputWrapper> inputs) {
        List<OutputWrapper> results = new List<OutputWrapper>();
        
        for (InputWrapper input : inputs) {
            String body = input.emailBody;
            List<String> delimiters = new List<String>{
                'From:', 'Sent:', 'On', 'wrote:', '-----Original Message-----'
            };
            
            for (String delimiter : delimiters) {
                Integer index = body.indexOf(delimiter);
                if (index > 0) {
                    body = body.substring(0, index).trim();
                    break;
                }
            }
            
            OutputWrapper result = new OutputWrapper();
            result.latestReply = body;
            results.add(result);
        }
        return results;
    }

    public class InputWrapper {
        @InvocableVariable(required=true)
        public String emailBody;
    }

    public class OutputWrapper {
        @InvocableVariable
        public String latestReply;
    }
}