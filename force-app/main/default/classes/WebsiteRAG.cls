global class WebsiteRAG {
    @AuraEnabled
    global static String generateChat(String prompt) {
        String responseText = braveSearch(prompt);
        System.debug(responseText);
        return responseText;
    }


    @AuraEnabled
    global static String braveSearch(String prompt) {
        String endpoint = 'https://api.search.brave.com/res/v1/web/search';
        String apiKey = 'BSAC_xI72NweBPBQjAyw2cG-7NZZGtX';
        String siteURL = 'https://clinicaltrials.gov/';

        if (apiKey.length() == 0) {
            return '';
        }

        String query = prompt;

        if (siteURL.length() > 0) {
            String domain = extractMainDomain(siteURL);
            query = query + ' site:' + domain;
        }
   
        // Create an HTTP request
        HttpRequest req = new HttpRequest();

        req.setHeader('Accept', 'application/json');
        req.setHeader('X-Subscription-Token', apiKey);
        req.setEndpoint(endpoint + '?q=' + EncodingUtil.urlEncode(query, 'UTF-8') + '&text_decorations=1&extra_snippets=1&summary=1');
        req.setMethod('GET');

        // Send the request and get the response
        Http http = new Http();
        HttpResponse res = http.send(req);

        // Process the response
        if (res.getStatusCode() == 200) {
            // Parse the response body as JSON
            SearchResponse searchResponse = (SearchResponse)JSON.deserialize(res.getBody(), SearchResponse.class);

            String responseText = getCollectSearchInfo(searchResponse);

            System.debug(responseText);

            return responseText;
        } else {
            // Handle errors based on status code
            throw new CalloutException(res.getStatus() + ': ' + res.getBody());
        }
    }

    public static String extractMainDomain(String url) {
        // Check if the URL starts with "http://" or "https://"
        if (!url.startsWith('http://') && !url.startsWith('https://')) {
            // Prepend "http://" if no protocol is present
            url = 'https://' + url;
        }

        Url urlObj = new Url(url);
        // Get the host from the URL object, which is the domain
        String domain = urlObj.getHost();

        System.debug('Domain: ' + domain);  // Output: subdomain.example.com


        // Split the domain into parts by '.'
        List<String> domainParts = domain.split('\\.');

        String finalResult = '';

        // Check if domain has at least two parts (e.g., example.com)
        if (domainParts.size() > 2) {
            // Return the last two parts (second-level domain and top-level domain)
            finalResult = domainParts[domainParts.size() - 2] + '.' + domainParts[domainParts.size() - 1];
        } else if (domainParts.size() == 2) {
            // Return if domain is already in the format 'example.com'
            finalResult = domain;
        }

        System.debug(finalResult);

        return finalResult;
    }

    public static String getCollectSearchInfo(SearchResponse searchResponse) {
        String collectSearchInfo = '';
        if (searchResponse.web != null && searchResponse.web.results != null) {
            Integer counter = 0;
            for (Result r : searchResponse.web.results) {
                if (counter++ >= 50) break; // Limit to 50 entries
                String snippetSection = '';

                collectSearchInfo += '  - url: ' + r.url 
                + '\n    title: ' + r.title 
                + '\n    description: ' + r.description
                + '\n    result_type: ' + r.type;


                // The top results to bring more content than the last results
                if (r.extra_snippets != null && !r.extra_snippets.isEmpty() && counter < 20) {
                    Integer deepLinkCounter = 0;
                    for (String snippet : r.extra_snippets) {
                        if (deepLinkCounter++ >= 20) break; // Limit to 20 deep links
                        snippetSection += '      - ' + snippet + '\n';
                    }
                    if (!snippetSection.equals('')) {
                        snippetSection = '    snippets:\n' + snippetSection;
                    }
                }

                collectSearchInfo += (snippetSection.equals('') ? '' : '\n' + snippetSection);
            }
        }

        return collectSearchInfo;
    }

    

    private class SearchResponse {
        public Web web;
        public Summarizer summarizer;
    }

    private class Web {
        public List<Result> results;
    }
    
    private class Result {
        public String title;
        public String type;
        public String url;
        public String description;
        public List<String> extra_snippets;
        
    }

    private class Summarizer {
        public String type;
        public String key;
    }
    
    // Invocable Action that calls the original generateChat method
    @InvocableMethod(label='Answer Questions with Website' description='Answers questions about company policies and procedures, troubleshooting steps, or product information. For example: “What is your return policy?” “How do I fix an issue?” or “What features does a product have?”')
    public static List<Output> generateChatAction(List<Input> inputParams) {
        List<Output> outputList = new List<Output>();

        for (Input input : inputParams) {
            Output output = new Output();

            try {
                // Call the original generateChat method
                // output.WebsiteAnswer = generateChat(input.query);
                output.WebsiteAnswer = braveSearch(input.query);
            } catch (Exception e) {
                output.WebsiteAnswer = 'Error: ' + e.getMessage();
            }

            outputList.add(output);
        }

        return outputList;
    }

    // Input class for the invocable action
    public class Input {
        @InvocableVariable(required=true description='Required. A string created by generative AI to be used in the Website article search.')
        public String query;
    }

    // Output class for the invocable action
    public class Output {
        @InvocableVariable(description='A string formatted as rich text that includes a summary of the information retrieved from the Website articles and citations to those articles.')
        public String WebsiteAnswer;
    }

}