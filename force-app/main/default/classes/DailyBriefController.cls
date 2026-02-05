/**
 * Daily Brief Controller
 * Invokes the Daily_Brief prompt template using ConnectApi and synthesizes audio via ElevenLabs
 * 
 * Prerequisites:
 * - Prompt Template with API name 'Daily_Brief' created in Prompt Builder
 * - ElevenLabs API key stored in Poseidon_Settings__c.ElevenLabs_API_Key__c
 * - Remote Site Setting for https://api.elevenlabs.io
 */
public with sharing class DailyBriefController {
    
    // ElevenLabs API Configuration
    private static final String ELEVENLABS_API_URL = 'https://api.elevenlabs.io/v1/text-to-speech/';
    private static final String DEFAULT_VOICE_ID = 'EXAVITQu4vr4xnSDxMaL'; // Bella - clear female voice
    private static final String DEFAULT_MODEL = 'eleven_turbo_v2_5'; // Uses fewer credits than multilingual_v2
    
    // Prompt Template API Name
    private static final String PROMPT_TEMPLATE_NAME = 'Daily_Brief';
    
    /**
     * Generate Daily Brief content by invoking the prompt template via ConnectApi
     * @return The generated brief text content
     */
    @AuraEnabled
    public static String generateDailyBrief() {
        try {
            // Create input parameters for the prompt template
            // Empty map since Daily_Brief doesn't require record context
            Map<String, ConnectApi.WrappedValue> inputParams = new Map<String, ConnectApi.WrappedValue>();
            
            // Configure the generation input
            ConnectApi.EinsteinPromptTemplateGenerationsInput generationInput = new ConnectApi.EinsteinPromptTemplateGenerationsInput();
            generationInput.inputParams = inputParams;
            generationInput.isPreview = false;
            
            // Additional config
            ConnectApi.EinsteinLlmAdditionalConfigInput additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
            additionalConfig.applicationName = 'PromptTemplateGenerationsInvocable';
            generationInput.additionalConfig = additionalConfig;
            
            System.debug('[DailyBrief] Invoking prompt template: ' + PROMPT_TEMPLATE_NAME);
            
            // Invoke the prompt template using ConnectApi
            ConnectApi.EinsteinPromptTemplateGenerationsRepresentation response = 
                ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate(
                    PROMPT_TEMPLATE_NAME,
                    generationInput
                );
            
            // Extract the generated text
            if (response.generations != null && !response.generations.isEmpty()) {
                ConnectApi.EinsteinLLMGenerationItemOutput firstGen = response.generations[0];
                String generatedText = firstGen.text;
                
                if (String.isNotBlank(generatedText)) {
                    System.debug('[DailyBrief] Generated content length: ' + generatedText.length());
                    return generatedText;
                }
            }
            
            throw new AuraHandledException('No content was generated from the prompt template');
            
        } catch (ConnectApi.ConnectApiException e) {
            System.debug('[DailyBrief] ConnectApi Error: ' + e.getMessage());
            String userMessage = parseConnectApiError(e.getMessage());
            throw new AuraHandledException(userMessage);
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            System.debug('[DailyBrief] Error: ' + e.getMessage() + '\n' + e.getStackTraceString());
            throw new AuraHandledException('Error generating daily brief: ' + e.getMessage());
        }
    }
    
    /**
     * Synthesize speech from text using ElevenLabs API
     * @param text The text to convert to speech
     * @param voiceId Optional ElevenLabs voice ID
     * @param voiceSettings Optional map with stability, similarity, speed, style
     * @return Base64-encoded MP3 audio data
     */
    @AuraEnabled
    public static String synthesizeSpeech(String text, String voiceId, Map<String, Decimal> voiceSettings) {
        if (String.isBlank(text)) {
            throw new AuraHandledException('Text is required for speech synthesis');
        }
        
        // Get ElevenLabs API key from Poseidon Settings
        String apiKey = getElevenLabsApiKey();
        if (String.isBlank(apiKey)) {
            throw new AuraHandledException('ElevenLabs API key not configured. Please configure it in Poseidon Settings.');
        }
        
        try {
            String voice = String.isNotBlank(voiceId) ? voiceId : DEFAULT_VOICE_ID;
            // Use lower quality output to stay under Salesforce's 6MB callout response limit
            // Options: mp3_44100_128 (default), mp3_44100_96, mp3_44100_64, mp3_22050_32
            String endpoint = ELEVENLABS_API_URL + voice + '?output_format=mp3_22050_32';
            
            // Extract voice settings with defaults
            Decimal stability = 0.5;
            Decimal similarity = 0.75;
            Decimal speed = 1.0;
            Decimal style = 0.0;
            
            if (voiceSettings != null) {
                stability = voiceSettings.get('stability') != null ? voiceSettings.get('stability') : 0.5;
                similarity = voiceSettings.get('similarity') != null ? voiceSettings.get('similarity') : 0.75;
                speed = voiceSettings.get('speed') != null ? voiceSettings.get('speed') : 1.0;
                style = voiceSettings.get('style') != null ? voiceSettings.get('style') : 0.0;
            }
            
            // Build request body - speed goes at top level, not in voice_settings
            Map<String, Object> requestBody = new Map<String, Object>{
                'text' => text,
                'model_id' => DEFAULT_MODEL,
                'voice_settings' => new Map<String, Object>{
                    'stability' => stability,
                    'similarity_boost' => similarity,
                    'style' => style,
                    'use_speaker_boost' => true
                }
            };
            
            // Add speed at top level if not default (1.0)
            if (speed != 1.0) {
                requestBody.put('speed', speed);
            }
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('POST');
            req.setHeader('xi-api-key', apiKey);
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Accept', 'audio/mpeg');
            req.setBody(JSON.serialize(requestBody));
            req.setTimeout(120000); // 2 minute timeout for long text
            
            System.debug('[DailyBrief] Making ElevenLabs API call to: ' + endpoint);
            System.debug('[DailyBrief] API Key used (first 5 chars): ' + (apiKey != null && apiKey.length() > 5 ? apiKey.substring(0, 5) : 'N/A'));
            System.debug('[DailyBrief] Request body: ' + JSON.serialize(requestBody));
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            System.debug('[DailyBrief] Response status: ' + res.getStatusCode());
            
            if (res.getStatusCode() == 200) {
                // ElevenLabs returns raw audio bytes
                Blob audioBlob = res.getBodyAsBlob();
                return EncodingUtil.base64Encode(audioBlob);
            } else {
                String errorBody = res.getBody();
                System.debug('[DailyBrief] ElevenLabs Error: ' + res.getStatusCode() + ' - ' + errorBody);
                System.debug('[DailyBrief] API Key used had length: ' + (apiKey != null ? apiKey.length() : 0));
                
                String errorMessage = 'Speech synthesis failed (' + res.getStatusCode() + '): ';
                if (res.getStatusCode() == 401) {
                    // Include details about the API key for debugging
                    errorMessage += 'Invalid API key. Key length: ' + (apiKey != null ? apiKey.length() : 0);
                    errorMessage += ', starts with: ' + (apiKey != null && apiKey.length() > 5 ? apiKey.substring(0, 5) : 'N/A');
                    // Parse ElevenLabs error if possible
                    if (String.isNotBlank(errorBody)) {
                        try {
                            Map<String, Object> errJson = (Map<String, Object>) JSON.deserializeUntyped(errorBody);
                            Map<String, Object> detail = (Map<String, Object>) errJson.get('detail');
                            if (detail != null) {
                                errorMessage += '. ElevenLabs: ' + detail.get('message');
                            }
                        } catch (Exception e) {
                            errorMessage += '. Response: ' + errorBody.abbreviate(100);
                        }
                    }
                } else if (res.getStatusCode() == 429) {
                    errorMessage += 'Rate limit exceeded';
                } else {
                    errorMessage += errorBody.abbreviate(200);
                }
                
                throw new AuraHandledException(errorMessage);
            }
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            System.debug('[DailyBrief] ElevenLabs Exception: ' + e.getMessage());
            throw new AuraHandledException('Speech synthesis error: ' + e.getMessage());
        }
    }
    
    /**
     * Get available ElevenLabs voices for selection
     * @return List of voice options with id, name, description
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getAvailableVoices() {
        return new List<Map<String, String>>{
            // Female voices
            new Map<String, String>{'value' => 'EXAVITQu4vr4xnSDxMaL', 'label' => 'Bella', 'description' => 'Female • Clear & Friendly'},
            new Map<String, String>{'value' => '21m00Tcm4TlvDq8ikWAM', 'label' => 'Rachel', 'description' => 'Female • Calm & Professional'},
            new Map<String, String>{'value' => 'AZnzlk1XvdvUeBnXmlld', 'label' => 'Domi', 'description' => 'Female • Strong & Confident'},
            new Map<String, String>{'value' => 'MF3mGyEYCl7XYWbV9V6O', 'label' => 'Elli', 'description' => 'Female • Emotional & Warm'},
            new Map<String, String>{'value' => 'jBpfuIE2acCO8z3wKNLl', 'label' => 'Gigi', 'description' => 'Female • Energetic & Youthful'},
            new Map<String, String>{'value' => 'oWAxZDx7w5VEj9dCyTzz', 'label' => 'Grace', 'description' => 'Female • Warm & Welcoming'},
            // Male voices
            new Map<String, String>{'value' => 'TxGEqnHWrfWFTfGW9XjX', 'label' => 'Josh', 'description' => 'Male • Deep & Authoritative'},
            new Map<String, String>{'value' => 'pNInz6obpgDQGcFmaJgB', 'label' => 'Adam', 'description' => 'Male • Deep & Professional'},
            new Map<String, String>{'value' => 'VR6AewLTigWG4xSOukaG', 'label' => 'Arnold', 'description' => 'Male • Crisp & Clear'},
            new Map<String, String>{'value' => 'yoZ06aMxZJJ28mfd3POQ', 'label' => 'Sam', 'description' => 'Male • Dynamic & Engaging'},
            new Map<String, String>{'value' => 'ErXwobaYiN019PkySvjV', 'label' => 'Antoni', 'description' => 'Male • Well-Rounded & Smooth'},
            new Map<String, String>{'value' => 'ODq5zmih8GrVes37Dizd', 'label' => 'Patrick', 'description' => 'Male • Friendly & Conversational'},
            new Map<String, String>{'value' => 'ZQe5CZNOzWyzPSCn5a3c', 'label' => 'James', 'description' => 'Male • British & Refined'}
        };
    }
    
    /**
     * Check if Daily Brief is properly configured
     * @return Map with configuration status
     */
    @AuraEnabled
    public static Map<String, Object> checkConfiguration() {
        Map<String, Object> config = new Map<String, Object>();
        
        // Check ElevenLabs API key
        String apiKey = getElevenLabsApiKey();
        config.put('elevenLabsConfigured', String.isNotBlank(apiKey));
        
        // Don't check prompt template - the preview API is unreliable
        // Let the actual generation be the test
        config.put('promptTemplateConfigured', true);
        
        return config;
    }
    
    /**
     * Get ElevenLabs API key from Poseidon Settings
     * Uses the same method as PoseidonSpeechFoundationsService for consistency
     */
    private static String getElevenLabsApiKey() {
        try {
            // Use getOrgDefaults() - same as PoseidonSpeechFoundationsService
            Poseidon_Settings__c settings = Poseidon_Settings__c.getOrgDefaults();
            System.debug('[DailyBrief] Poseidon_Settings__c retrieved: ' + (settings != null ? 'YES' : 'NO'));
            if (settings != null) {
                String apiKey = settings.ElevenLabs_API_Key__c;
                System.debug('[DailyBrief] API Key field present: ' + (apiKey != null ? 'YES' : 'NO'));
                System.debug('[DailyBrief] API Key length: ' + (apiKey != null ? apiKey.length() : 0));
                System.debug('[DailyBrief] API Key starts with: ' + (apiKey != null && apiKey.length() > 5 ? apiKey.substring(0, 5) : 'N/A'));
                if (String.isNotBlank(apiKey)) {
                    // Trim any whitespace that might have been accidentally included
                    return apiKey.trim();
                }
            }
        } catch (Exception e) {
            System.debug('[DailyBrief] Error getting Poseidon Settings: ' + e.getMessage());
        }
        return null;
    }
    
    /**
     * Parse ConnectApi error messages into user-friendly text
     */
    private static String parseConnectApiError(String errorMessage) {
        if (errorMessage.containsIgnoreCase('not found') || errorMessage.containsIgnoreCase('does not exist')) {
            return 'Prompt template "' + PROMPT_TEMPLATE_NAME + '" not found. Please create it in Prompt Builder.';
        }
        if (errorMessage.containsIgnoreCase('INSUFFICIENT_ACCESS') || errorMessage.containsIgnoreCase('permission')) {
            return 'Insufficient permissions to invoke prompt templates. Check your user permissions.';
        }
        if (errorMessage.containsIgnoreCase('model') || errorMessage.containsIgnoreCase('LLM')) {
            return 'LLM generation failed. Ensure a model is selected in the prompt template.';
        }
        return 'Failed to generate brief: ' + errorMessage;
    }
}
