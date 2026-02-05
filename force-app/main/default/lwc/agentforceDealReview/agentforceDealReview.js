/**
 * Agentforce Deal Review
 * AI-powered deal qualification and MEDDPICC review tool
 * 
 * Features:
 * - 3-panel layout: Opportunity list | Deal details | Chat
 * - Three interaction modes: Text, Whisper (voice input + text output), Voice (full voice)
 * - ElevenLabs TTS/STT integration
 * - Real-time MEDDPICC field highlighting when agent updates
 * - Polling for agent updates via Apex
 */

import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// Apex methods
import getOpportunities from '@salesforce/apex/DealReviewController.getOpportunities';
import getOpportunityOwners from '@salesforce/apex/DealReviewController.getOpportunityOwners';
import getStageOptions from '@salesforce/apex/DealReviewController.getStageOptions';
import getOpportunityDetail from '@salesforce/apex/DealReviewController.getOpportunityDetail';
import getOpportunityLastModified from '@salesforce/apex/DealReviewController.getOpportunityLastModified';
import saveOpportunity from '@salesforce/apex/DealReviewController.saveOpportunity';
import synthesizeSpeech from '@salesforce/apex/DealReviewController.synthesizeSpeech';
import getSTTConfig from '@salesforce/apex/DealReviewController.getSTTConfig';
import getAvailableVoices from '@salesforce/apex/DealReviewController.getAvailableVoices';
import shouldSummarize from '@salesforce/apex/DealReviewController.shouldSummarize';
import summarizeForVoice from '@salesforce/apex/DealReviewController.summarizeForVoice';
import sendAgentMessage from '@salesforce/apex/DealReviewController.sendAgentMessage';
import saveFeedback from '@salesforce/apex/DealReviewController.saveFeedback';

// Close date filter options
const CLOSE_DATE_OPTIONS = [
    { label: 'All Dates', value: 'all' },
    { label: 'Overdue', value: 'overdue' },
    { label: 'This Month', value: 'thisMonth' },
    { label: 'This Quarter', value: 'thisQuarter' },
    { label: 'Next Month', value: 'nextMonth' },
    { label: 'Next Quarter', value: 'nextQuarter' }
];

// MEDDPICC field configuration
const MEDDPICC_CONFIG = [
    { key: 'MEDDPICC_Metrics__c', scoreKey: 'MEDDPICC_Metrics_Score__c', label: 'Metrics', letter: 'M' },
    { key: 'MEDDPICC_Economic_Buyer__c', scoreKey: 'MEDDPICC_Economic_Buyer_Score__c', label: 'Economic Buyer', letter: 'E' },
    { key: 'MEDDPICC_Decision_Criteria__c', scoreKey: 'MEDDPICC_Decision_Criteria_Score__c', label: 'Decision Criteria', letter: 'D' },
    { key: 'MEDDPICC_Decision_Process__c', scoreKey: 'MEDDPICC_Decision_Process_Score__c', label: 'Decision Process', letter: 'D' },
    { key: 'MEDDPICC_Paper_Process__c', scoreKey: 'MEDDPICC_Paper_Process_Score__c', label: 'Paper Process', letter: 'P' },
    { key: 'MEDDPICC_Identify_Pain__c', scoreKey: 'MEDDPICC_Identify_Pain_Score__c', label: 'Identify Pain', letter: 'I' },
    { key: 'MEDDPICC_Champion__c', scoreKey: 'MEDDPICC_Champion_Score__c', label: 'Champion', letter: 'C' },
    { key: 'MEDDPICC_Competition__c', scoreKey: 'MEDDPICC_Competition_Score__c', label: 'Competition', letter: 'C' }
];

// Score options for editing
const SCORE_OPTIONS = [
    { label: '1 - Very Weak', value: '1 - Very Weak' },
    { label: '2 - Weak', value: '2 - Weak' },
    { label: '3 - Moderate', value: '3 - Moderate' },
    { label: '4 - Strong', value: '4 - Strong' },
    { label: '5 - Very Strong', value: '5 - Very Strong' }
];

// Coaching intensity configuration
const COACHING_LEVELS = {
    1: { 
        label: 'Very Supportive', 
        description: 'Gentle guidance with lots of encouragement. Great for building confidence.',
        style: 'supportive'
    },
    2: { 
        label: 'Supportive', 
        description: 'Encouraging with occasional suggestions. Balanced positive feedback.',
        style: 'supportive-balanced'
    },
    3: { 
        label: 'Balanced', 
        description: 'Mix of encouragement and constructive challenge. Standard coaching.',
        style: 'balanced'
    },
    4: { 
        label: 'Challenging', 
        description: 'Direct feedback with probing questions. Pushes for clarity and action.',
        style: 'challenging'
    },
    5: { 
        label: 'Very Challenging', 
        description: 'High-pressure coaching like a demanding sales leader. Challenges assumptions.',
        style: 'very-challenging'
    }
};

export default class AgentforceDealReview extends LightningElement {
    // ==================== STATE ====================
    
    // List panel
    @track opportunities = [];
    @track currentPage = 1;
    @track totalPages = 1;
    @track totalRecords = 0;
    @track isLoadingList = true;
    pageSize = 15;
    
    // Filters
    @track closeDateFilter = 'all';
    @track ownerFilter = '';
    @track ownerOptions = [{ label: 'All Owners', value: '' }];
    closeDateOptions = CLOSE_DATE_OPTIONS;
    
    // Stage path
    @track stageOptions = [];
    
    // Detail panel
    @track selectedOpportunity = null;
    @track selectedOpportunityId = null;
    @track isLoadingDetail = false;
    @track updatedFields = new Set(); // Fields updated by agent
    @track previousValues = {}; // For change detection
    @track editedValues = {}; // User edits
    @track isEditing = false;
    @track isSaving = false;
    
    // Chat panel
    @track messages = [];
    @track userInput = '';
    @track isProcessing = false;
    @track mode = 'text'; // text, whisper, voice
    @track isRecording = false;
    @track isListeningActive = false; // Continuous listening session active
    @track isSpeaking = false; // Agent is currently speaking
    
    // Silence detection
    silenceTimeout = null;
    SILENCE_DURATION = 3500; // 3.5 seconds of silence before auto-submit
    
    // Voice settings
    @track showSettings = false;
    @track selectedVoice = 'EXAVITQu4vr4xnSDxMaL';
    @track voiceOptions = [];
    @track stability = 50;
    @track speed = 100;
    sttConfig = null;
    currentAudio = null;
    
    // Coaching intensity (1-5: Supportive to Challenging)
    @track coachingIntensity = 3;
    
    // Feedback modal
    @track showFeedbackModal = false;
    @track feedbackRating = null; // 'positive' or 'negative'
    @track feedbackComment = '';
    @track isSubmittingFeedback = false;
    pendingOpportunityId = null; // Used when switching deals with feedback
    
    // Browser Speech Recognition (fallback when ElevenLabs STT fails due to CSP)
    recognition = null;
    currentTranscript = '';
    accumulatedTranscript = ''; // Only final results accumulated here
    
    // Polling
    pollInterval = null;
    lastModifiedDate = null;
    
    // Agent session
    agentSessionId = null;
    sequenceId = 0;
    
    // ==================== LIFECYCLE ====================
    
    connectedCallback() {
        this.loadOpportunities();
        this.loadOwnerOptions();
        this.loadStageOptions();
        this.loadVoiceConfig();
        this.initializeBrowserSpeechRecognition();
    }
    
    // Initialize browser Web Speech API as fallback for voice input
    initializeBrowserSpeechRecognition() {
        if ('webkitSpeechRecognition' in window || 'SpeechRecognition' in window) {
            const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
            this.recognition = new SpeechRecognition();
            this.recognition.continuous = true; // Keep listening
            this.recognition.interimResults = true;
            this.recognition.lang = 'en-US';
            this.recognition.maxAlternatives = 1;
            
            this.recognition.onresult = (event) => {
                let interimTranscript = '';
                let finalTranscript = '';
                
                for (let i = event.resultIndex; i < event.results.length; i++) {
                    const transcript = event.results[i][0].transcript;
                    if (event.results[i].isFinal) {
                        finalTranscript += transcript + ' ';
                    } else {
                        interimTranscript += transcript;
                    }
                }
                
                // IMPORTANT: Only accumulate FINAL results
                // Interim results are evolving guesses - show for display but don't add to accumulated text
                if (finalTranscript) {
                    // Add final transcript to accumulated text
                    this.accumulatedTranscript = (this.accumulatedTranscript || '') + finalTranscript;
                    this.currentTranscript = this.accumulatedTranscript.trim();
                    // Reset silence timer on final results
                    this.resetSilenceTimer();
                } else if (interimTranscript) {
                    // Show interim for display only (accumulated + current interim guess)
                    this.currentTranscript = ((this.accumulatedTranscript || '') + interimTranscript).trim();
                    // Reset silence timer - user is still speaking
                    this.resetSilenceTimer();
                }
            };
            
            this.recognition.onerror = (event) => {
                console.error('Browser speech recognition error:', event.error);
                if (event.error === 'no-speech') {
                    // No speech detected - if we have accumulated text, submit it
                    if (this.currentTranscript.trim()) {
                        this.submitVoiceInput();
                    }
                } else if (event.error !== 'aborted') {
                    this.showError('Voice input error', event.error);
                }
                this.isRecording = false;
            };
            
            this.recognition.onend = () => {
                console.log('Browser speech recognition ended');
                this.isRecording = false;
                
                // If listening session is still active and not processing, restart
                if (this.isListeningActive && !this.isProcessing && !this.isSpeaking) {
                    console.log('Restarting recognition for continuous listening');
                    setTimeout(() => this.startRecording(), 300);
                }
            };
            
            console.log('Browser Web Speech API initialized (fallback STT)');
        } else {
            console.warn('Browser Web Speech API not available');
        }
    }
    
    disconnectedCallback() {
        this.stopPolling();
        this.stopAudio();
        this.stopRecording();
        // Clean up browser recognition
        if (this.recognition) {
            this.recognition.stop();
        }
    }
    
    // ==================== DATA LOADING ====================
    
    async loadOpportunities() {
        this.isLoadingList = true;
        try {
            const result = await getOpportunities({ 
                pageNumber: this.currentPage, 
                pageSize: this.pageSize,
                closeDateFilter: this.closeDateFilter,
                ownerId: this.ownerFilter || null
            });
            
            this.opportunities = result.opportunities.map(opp => ({
                ...opp,
                itemClass: 'opp-item' + (opp.Id === this.selectedOpportunityId ? ' selected' : ''),
                formattedAmount: this.formatCurrency(opp.Amount),
                formattedCloseDate: this.formatDate(opp.CloseDate),
                // Formula returns 0-100, convert to 5-point scale for display
                scoreLabel: opp.MEDDPICC_Overall_Score__c ? 
                    `${(opp.MEDDPICC_Overall_Score__c / 20).toFixed(1)}` : null,
                scoreClass: this.getScoreBadgeClass(opp.MEDDPICC_Overall_Score__c / 20)
            }));
            
            this.totalRecords = result.totalRecords;
            this.totalPages = result.totalPages;
            this.currentPage = result.currentPage;
            
        } catch (error) {
            this.showError('Failed to load opportunities', error);
        } finally {
            this.isLoadingList = false;
        }
    }
    
    async loadOwnerOptions() {
        try {
            const owners = await getOpportunityOwners();
            this.ownerOptions = owners;
        } catch (error) {
            console.error('Failed to load owners:', error);
        }
    }
    
    async loadStageOptions() {
        try {
            const stages = await getStageOptions();
            // Filter out closed stages for path display
            this.stageOptions = stages.filter(s => !s.isClosed);
        } catch (error) {
            console.error('Failed to load stages:', error);
        }
    }
    
    async loadOpportunityDetail(oppId) {
        this.isLoadingDetail = true;
        this.updatedFields = new Set();
        
        try {
            const result = await getOpportunityDetail({ opportunityId: oppId });
            this.selectedOpportunity = result.opportunity;
            this.lastModifiedDate = result.opportunity.LastModifiedDate;
            
            // Store previous values for change detection
            this.previousValues = this.extractMeddpiccValues(result.opportunity);
            
            // Start polling for updates
            this.startPolling();
            
            // Generate initial agent message with status summary
            this.generateInitialAgentMessage(result.meddpiccSummary);
            
        } catch (error) {
            this.showError('Failed to load opportunity details', error);
        } finally {
            this.isLoadingDetail = false;
        }
    }
    
    async loadVoiceConfig() {
        try {
            const [sttResult, voicesResult] = await Promise.all([
                getSTTConfig(),
                getAvailableVoices()
            ]);
            
            this.sttConfig = sttResult;
            console.log('Voice config loaded:', this.sttConfig);
            
            this.voiceOptions = voicesResult.map(v => ({
                label: `${v.label} - ${v.description}`,
                value: v.value
            }));
            
            // Check if ElevenLabs is configured
            if (this.sttConfig?.configured === 'true') {
                console.log('ElevenLabs STT is configured and ready');
            } else {
                console.warn('ElevenLabs STT is not configured. Voice input will not be available.');
                // Note: Web Speech API doesn't work in Salesforce LWC due to Locker Service
            }
            
        } catch (error) {
            console.error('Failed to load voice config:', error);
        }
    }
    
    // ==================== POLLING FOR AGENT UPDATES ====================
    
    startPolling() {
        this.stopPolling();
        this.pollInterval = setInterval(() => this.checkForUpdates(), 2000);
    }
    
    stopPolling() {
        if (this.pollInterval) {
            clearInterval(this.pollInterval);
            this.pollInterval = null;
        }
    }
    
    async checkForUpdates() {
        if (!this.selectedOpportunityId || this.isLoadingDetail) return;
        
        try {
            const currentModified = await getOpportunityLastModified({ 
                opportunityId: this.selectedOpportunityId 
            });
            
            if (currentModified && currentModified !== this.lastModifiedDate) {
                this.lastModifiedDate = currentModified;
                await this.refreshOpportunityDetail();
            }
        } catch (error) {
            console.error('Polling error:', error);
        }
    }
    
    async refreshOpportunityDetail() {
        try {
            const result = await getOpportunityDetail({ 
                opportunityId: this.selectedOpportunityId 
            });
            
            // Detect which fields changed
            const newValues = this.extractMeddpiccValues(result.opportunity);
            
            for (const field of Object.keys(newValues)) {
                if (newValues[field] !== this.previousValues[field]) {
                    this.updatedFields.add(field);
                }
            }
            
            this.selectedOpportunity = result.opportunity;
            this.previousValues = newValues;
            
        } catch (error) {
            console.error('Refresh error:', error);
        }
    }
    
    extractMeddpiccValues(opp) {
        const values = {};
        for (const config of MEDDPICC_CONFIG) {
            values[config.key] = opp[config.key];
            values[config.scoreKey] = opp[config.scoreKey];
        }
        return values;
    }
    
    // ==================== AGENT MESSAGING ====================
    
    async generateInitialAgentMessage(summary) {
        // Clear previous messages and reset session for new opportunity
        this.messages = [];
        this.agentSessionId = null;
        this.sequenceId = 0;
        
        // Add a loading indicator
        const typingId = this.addTypingIndicator();
        
        try {
            // Call the agent with an initial prompt to analyze the deal
            const initialPrompt = "Please provide your initial assessment of this opportunity. Review the current MEDDPICC status, identify information gaps and weaknesses, and ask me a coaching question to help strengthen the deal qualification.";
            
            await this.callAgent(initialPrompt);
            
        } catch (error) {
            console.error('Error getting initial agent message:', error);
            // Fallback to local message if agent fails
            this.addAgentMessage(this.generateFallbackInitialMessage(summary));
        } finally {
            this.removeTypingIndicator(typingId);
        }
    }
    
    generateFallbackInitialMessage(summary) {
        let content = `Great, let's review this deal together. `;
        
        // Overall status
        if (summary.overallScore) {
            const status = summary.overallScore >= 3.5 ? 'looking solid' : 
                          summary.overallScore >= 2.5 ? 'needs some work' : 'needs significant attention';
            content += `Your overall MEDDPICC score is ${summary.overallScore.toFixed(1)}/5 - ${status}.\n\n`;
        } else {
            content += `I see we're just getting started with MEDDPICC qualification on this deal.\n\n`;
        }
        
        // Highlight gaps and weaknesses
        if (summary.emptyFields && summary.emptyFields.length > 0) {
            content += `**Information gaps:** ${summary.emptyFields.join(', ')}\n`;
        }
        
        if (summary.weakFields && summary.weakFields.length > 0) {
            content += `**Needs strengthening:** ${summary.weakFields.join(', ')}\n`;
        }
        
        content += `\n`;
        
        // Generate targeted question based on biggest gap
        if (summary.emptyFields && summary.emptyFields.length > 0) {
            const firstGap = summary.emptyFields[0];
            content += this.generateQuestionForDimension(firstGap);
        } else if (summary.weakFields && summary.weakFields.length > 0) {
            const firstWeak = summary.weakFields[0];
            content += this.generateStrengtheningQuestion(firstWeak);
        } else {
            content += `This deal looks well-qualified! Walk me through any recent developments and I'll help keep everything current.`;
        }
        
        return content;
    }
    
    generateQuestionForDimension(dimension) {
        const questions = {
            'Metrics': `Let's start with Metrics - what quantifiable business outcomes is the customer expecting from this deal? Any ROI calculations or success metrics they've shared?`,
            'Economic Buyer': `Who controls the budget for this purchase? Have you identified and engaged with the economic buyer directly?`,
            'Decision Criteria': `What criteria are they using to evaluate solutions? Do you know what's most important to them in making this decision?`,
            'Decision Process': `Walk me through their decision process - what steps do they need to go through, and what's the timeline?`,
            'Paper Process': `What does their procurement process look like? Any legal or contract requirements I should know about?`,
            'Identify Pain': `What business pain is driving this purchase? How is the current situation impacting them?`,
            'Champion': `Do you have an internal champion at the account? Someone who's actively advocating for your solution?`,
            'Competition': `What's the competitive landscape look like? Who else are they evaluating?`
        };
        
        return questions[dimension] || `Tell me more about ${dimension} for this opportunity.`;
    }
    
    generateStrengtheningQuestion(dimension) {
        const questions = {
            'Metrics': `You have some metrics identified but they could be stronger. Can you get more specific quantified outcomes or ROI validation from the customer?`,
            'Economic Buyer': `You've identified an economic buyer but the engagement seems limited. How can we get deeper access or commitment?`,
            'Decision Criteria': `The decision criteria are somewhat defined. Have you mapped these to your solution's strengths? Any criteria we should try to influence?`,
            'Decision Process': `The process is documented but could be clearer. Can you get more specific on timeline and next steps?`,
            'Paper Process': `Procurement awareness is there but needs more detail. Have you engaged their legal/procurement team directly?`,
            'Identify Pain': `The pain is identified but could be more compelling. Can you quantify the business impact more specifically?`,
            'Champion': `You have a supporter but they could be a stronger advocate. How actively are they selling internally for you?`,
            'Competition': `You're aware of competition but positioning could be sharper. What's your specific differentiation strategy?`
        };
        
        return questions[dimension] || `Let's strengthen your position on ${dimension}. What additional details can you share?`;
    }
    
    addAgentMessage(content, options = {}) {
        const id = Date.now().toString();
        this.messages = [...this.messages, {
            id,
            content,
            isAgent: true,
            isUser: false,
            isTyping: false,
            wrapperClass: 'message-wrapper agent',
            bubbleClass: 'message-bubble agent',
            canSpeak: this.mode !== 'text',
            speakIcon: 'utility:volume_high',
            isPlaying: false
        }];
        
        this.scrollToBottom();
        
        // Handle voice modes - auto-speak and/or auto-listen
        if (!options.silent && this.isListeningActive) {
            if (this.mode === 'voice') {
                // Voice mode: speak response, then auto-listen
                this.isSpeaking = true;
                setTimeout(() => this.speakMessageThenListen(id, content), 100);
            } else if (this.mode === 'whisper') {
                // Whisper mode: just auto-listen (no TTS)
                setTimeout(() => this.startRecording(), 500);
            }
        }
    }
    
    addUserMessage(content) {
        const id = Date.now().toString();
        this.messages = [...this.messages, {
            id,
            content,
            isAgent: false,
            isUser: true,
            wrapperClass: 'message-wrapper user',
            bubbleClass: 'message-bubble user'
        }];
        
        this.scrollToBottom();
    }
    
    addTypingIndicator() {
        const id = 'typing-' + Date.now();
        this.messages = [...this.messages, {
            id,
            isAgent: true,
            isTyping: true,
            wrapperClass: 'message-wrapper agent',
            bubbleClass: 'message-bubble agent',
            canSpeak: false,
            speakIcon: 'utility:volume_high'
        }];
        this.scrollToBottom();
        return id;
    }
    
    removeTypingIndicator(id) {
        this.messages = this.messages.filter(m => m.id !== id);
    }
    
    scrollToBottom() {
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        setTimeout(() => {
            const container = this.refs.chatContainer;
            if (container) {
                container.scrollTop = container.scrollHeight;
            }
        }, 50);
    }
    
    // ==================== AGENT INTERACTION ====================
    // Note: This is a placeholder implementation. In production, integrate with
    // Agentforce ConnectApi or the proper agent runtime.
    
    async sendToAgent(userMessage) {
        this.isProcessing = true;
        const typingId = this.addTypingIndicator();
        
        try {
            // For demo purposes, simulate agent response
            // In production, this would call the Agentforce API
            await this.callAgent(userMessage);
            
        } catch (error) {
            this.showError('Failed to communicate with agent', error);
            this.addAgentMessage('I apologize, but I encountered an error. Please try again.', { silent: true });
        } finally {
            this.removeTypingIndicator(typingId);
            this.isProcessing = false;
        }
    }
    
    async callAgent(userMessage) {
        try {
            this.sequenceId++;
            
            const result = await sendAgentMessage({
                opportunityId: this.selectedOpportunityId,
                userMessage: userMessage,
                sessionId: this.agentSessionId,
                sequenceId: this.sequenceId,
                coachingIntensity: this.coachingIntensity
            });
            
            if (result.success) {
                // Update session ID if returned
                if (result.sessionId) {
                    this.agentSessionId = result.sessionId;
                }
                
                // Add agent response - addAgentMessage handles voice/speech automatically
                // DO NOT call speakResponse separately - that causes duplicate audio!
                this.addAgentMessage(result.message);
                
                // Poll for opportunity updates (agent may have updated MEDDPICC fields)
                await this.checkForUpdates();
            } else {
                // Add error message but silent (don't speak errors)
                this.addAgentMessage('I apologize, but I encountered an error: ' + (result.error || 'Unknown error'), { silent: true });
            }
            
        } catch (error) {
            console.error('Agent error:', error);
            // Provide user-friendly error message - silent (don't speak errors)
            let errorMsg = 'I apologize, but I encountered an error communicating with the agent.';
            if (error.body && error.body.message) {
                errorMsg += ' ' + error.body.message;
            }
            this.addAgentMessage(errorMsg, { silent: true });
        }
    }
    
    // ==================== VOICE FEATURES ====================
    // Continuous listening with silence detection
    
    elevenLabsSTTSocket = null;
    sttAudioContext = null;
    sttAudioProcessor = null;
    sttAudioSource = null;
    microphoneStream = null;
    
    // Toggle continuous listening mode
    toggleListening() {
        if (this.isListeningActive) {
            // Stop listening session
            console.log('Stopping continuous listening session');
            this.isListeningActive = false;
            this.stopRecording();
            this.clearSilenceTimer();
            this.currentTranscript = '';
            this.accumulatedTranscript = '';
        } else {
            // Start listening session
            console.log('Starting continuous listening session');
            this.isListeningActive = true;
            this.currentTranscript = '';
            this.accumulatedTranscript = '';
            this.startRecording();
        }
    }
    
    // Reset silence timer when user speaks
    resetSilenceTimer() {
        this.clearSilenceTimer();
        
        // Only set timer if we have accumulated text
        if (this.currentTranscript.trim()) {
            this.silenceTimeout = setTimeout(() => {
                console.log('Silence detected, submitting voice input');
                this.submitVoiceInput();
            }, this.SILENCE_DURATION);
        }
    }
    
    clearSilenceTimer() {
        if (this.silenceTimeout) {
            clearTimeout(this.silenceTimeout);
            this.silenceTimeout = null;
        }
    }
    
    // Submit accumulated voice input
    submitVoiceInput() {
        this.clearSilenceTimer();
        
        // Use accumulated transcript (only final results)
        const textToSend = (this.accumulatedTranscript || this.currentTranscript || '').trim();
        
        if (textToSend) {
            this.userInput = textToSend;
            this.currentTranscript = '';
            this.accumulatedTranscript = '';
            
            // Stop recording while processing
            this.stopRecording();
            
            // Send to agent
            this.handleSend();
        }
    }
    
    async startRecording() {
        console.log('=== startRecording called ===');
        console.log('sttConfig:', this.sttConfig);
        
        // Don't start if already recording
        if (this.isRecording) {
            console.log('Already recording, stopping first...');
            this.stopRecording();
            return;
        }
        
        try {
            // Request microphone permission first
            console.log('Requesting microphone access...');
            this.microphoneStream = await navigator.mediaDevices.getUserMedia({ audio: true });
            console.log('Microphone access granted');
            
            // Try ElevenLabs WebSocket STT first (if configured)
            if (this.sttConfig && this.sttConfig.configured === 'true') {
                console.log('Attempting ElevenLabs WebSocket STT...');
                const connected = await this.connectElevenLabsSTT();
                if (connected) {
                    this.isRecording = true;
                    console.log('ElevenLabs STT connected successfully');
                    return;
                }
                // Fall through to browser STT if ElevenLabs fails
                console.warn('ElevenLabs STT failed (likely CSP block), falling back to browser Web Speech API');
            }
            
            // Fallback: Use browser Web Speech API
            if (this.recognition) {
                console.log('Using browser Web Speech API for voice input');
                try {
                    this.recognition.start();
                    this.isRecording = true;
                } catch (e) {
                    // Recognition might already be running from a previous attempt
                    if (e.name === 'InvalidStateError') {
                        console.log('Recognition already running, aborting and restarting...');
                        this.recognition.abort();
                        // Wait a moment then restart
                        await new Promise(resolve => setTimeout(resolve, 100));
                        this.recognition.start();
                        this.isRecording = true;
                    } else {
                        throw e;
                    }
                }
            } else {
                throw new Error('Voice input not available - no STT provider configured');
            }
            
        } catch (error) {
            console.error('Error starting recording:', error);
            this.isRecording = false;
            this.showError('Voice input error', error.message || 'Failed to start recording');
        }
    }
    
    async connectElevenLabsSTT() {
        const { apiKey, wsEndpoint } = this.sttConfig;
        const wsUrl = `${wsEndpoint}?model_id=scribe_v1&xi-api-key=${apiKey}`;
        
        console.log('Connecting to ElevenLabs STT WebSocket...');
        console.log('WebSocket URL:', wsUrl.replace(apiKey, 'API_KEY_HIDDEN'));
        console.log('wsEndpoint:', wsEndpoint);
        
        return new Promise((resolve) => {
            try {
                this.elevenLabsSTTSocket = new WebSocket(wsUrl);
            } catch (e) {
                console.error('WebSocket creation failed (likely CSP block):', e);
                resolve(false);
                return;
            }
            
            // Connection timeout
            const connectionTimeout = setTimeout(() => {
                console.warn('ElevenLabs STT connection timeout');
                if (this.elevenLabsSTTSocket) {
                    this.elevenLabsSTTSocket.close();
                    this.elevenLabsSTTSocket = null;
                }
                resolve(false);
            }, 5000);
            
            this.elevenLabsSTTSocket.onopen = () => {
                clearTimeout(connectionTimeout);
                console.log('ElevenLabs STT WebSocket connected');
                
                // Send initial config
                const config = {
                    type: 'config',
                    transcription_config: {
                        language: 'en',
                        punctuate: true,
                        format_text: true
                    }
                };
                this.elevenLabsSTTSocket.send(JSON.stringify(config));
                
                // Start audio capture
                this.startAudioCapture();
                resolve(true);
            };
            
            this.elevenLabsSTTSocket.onmessage = (event) => {
                try {
                    const data = JSON.parse(event.data);
                    this.handleSTTMessage(data);
                } catch (error) {
                    console.error('Error parsing STT message:', error);
                }
            };
            
            this.elevenLabsSTTSocket.onerror = (error) => {
                clearTimeout(connectionTimeout);
                console.error('ElevenLabs STT WebSocket error:', error);
                this.isRecording = false;
                resolve(false);
            };
            
            this.elevenLabsSTTSocket.onclose = (event) => {
                clearTimeout(connectionTimeout);
                console.log('ElevenLabs STT WebSocket closed:', event.code, event.reason);
                this.isRecording = false;
            };
        });
    }
    
    handleSTTMessage(data) {
        console.log('STT message:', JSON.stringify(data));
        
        let transcript = '';
        let isFinal = false;
        
        // Handle various ElevenLabs message formats
        if (data.type === 'transcript') {
            transcript = data.text || data.transcript || '';
            isFinal = data.is_final || data.isFinal || data.final || false;
        } else if (data.text || data.transcript) {
            transcript = data.text || data.transcript || '';
            isFinal = data.is_final || data.isFinal || data.final || false;
        }
        
        if (transcript) {
            this.userInput = transcript;
            console.log(`Transcript: "${transcript}" (final: ${isFinal})`);
            
            if (isFinal) {
                this.handleVoiceInputComplete();
            }
        }
    }
    
    startAudioCapture() {
        try {
            // Create AudioContext at 16kHz (required by ElevenLabs)
            const audioContext = new (window.AudioContext || window.webkitAudioContext)({
                sampleRate: 16000
            });
            
            const source = audioContext.createMediaStreamSource(this.microphoneStream);
            const processor = audioContext.createScriptProcessor(4096, 1, 1);
            
            processor.onaudioprocess = (event) => {
                if (this.elevenLabsSTTSocket && this.elevenLabsSTTSocket.readyState === WebSocket.OPEN) {
                    const inputData = event.inputBuffer.getChannelData(0);
                    
                    // Convert Float32 to Int16 PCM
                    const pcmData = new Int16Array(inputData.length);
                    for (let i = 0; i < inputData.length; i++) {
                        const s = Math.max(-1, Math.min(1, inputData[i]));
                        pcmData[i] = s < 0 ? s * 0x8000 : s * 0x7FFF;
                    }
                    
                    // Send as binary
                    this.elevenLabsSTTSocket.send(pcmData.buffer);
                }
            };
            
            source.connect(processor);
            processor.connect(audioContext.destination);
            
            // Store for cleanup
            this.sttAudioContext = audioContext;
            this.sttAudioProcessor = processor;
            this.sttAudioSource = source;
            
            console.log('Audio capture started for STT');
        } catch (error) {
            console.error('Failed to start audio capture:', error);
        }
    }
    
    stopRecording() {
        console.log('=== stopRecording called ===');
        this.isRecording = false;
        
        // Stop browser speech recognition (fallback)
        if (this.recognition) {
            try {
                this.recognition.abort(); // Use abort() for cleaner state reset
            } catch (e) {
                // Ignore errors when stopping recognition
                console.log('Recognition stop error (safe to ignore):', e);
            }
        }
        
        // Stop audio capture (ElevenLabs)
        if (this.sttAudioProcessor) {
            this.sttAudioProcessor.disconnect();
            this.sttAudioProcessor = null;
        }
        if (this.sttAudioSource) {
            this.sttAudioSource.disconnect();
            this.sttAudioSource = null;
        }
        if (this.sttAudioContext) {
            this.sttAudioContext.close();
            this.sttAudioContext = null;
        }
        
        // Stop microphone
        if (this.microphoneStream) {
            this.microphoneStream.getTracks().forEach(track => track.stop());
            this.microphoneStream = null;
        }
        
        // Close WebSocket (ElevenLabs)
        if (this.elevenLabsSTTSocket) {
            // Send empty string to signal end of audio
            if (this.elevenLabsSTTSocket.readyState === WebSocket.OPEN) {
                this.elevenLabsSTTSocket.send('');
            }
            this.elevenLabsSTTSocket.close();
            this.elevenLabsSTTSocket = null;
        }
        
        this.currentTranscript = '';
        console.log('Recording stopped');
    }
    
    handleVoiceInputComplete() {
        console.log('Voice input complete:', this.userInput);
        this.stopRecording();
        if (this.userInput.trim()) {
            this.handleSend();
        }
    }
    
    async speakMessage(messageId, text) {
        try {
            // Check if summarization is needed
            let textToSpeak = text;
            const needsSummarization = await shouldSummarize({ text });
            
            if (needsSummarization) {
                textToSpeak = await summarizeForVoice({ text });
            }
            
            // Update message state to playing
            this.messages = this.messages.map(m => 
                m.id === messageId ? { ...m, isPlaying: true, speakIcon: 'utility:pause' } : m
            );
            
            // Try ElevenLabs TTS first
            let audioPlayed = false;
            try {
                const audioBase64 = await synthesizeSpeech({
                    text: textToSpeak,
                    voiceId: this.selectedVoice,
                    voiceSettings: {
                        stability: this.stability / 100,
                        similarity: 0.75,
                        speed: this.speed / 100
                    }
                });
                
                // Create blob URL instead of data URL (CSP-friendly)
                const binaryString = atob(audioBase64);
                const bytes = new Uint8Array(binaryString.length);
                for (let i = 0; i < binaryString.length; i++) {
                    bytes[i] = binaryString.charCodeAt(i);
                }
                const blob = new Blob([bytes], { type: 'audio/mp3' });
                const blobUrl = URL.createObjectURL(blob);
                
                this.stopAudio();
                const audio = new Audio(blobUrl);
                this.currentAudio = audio;
                
                audio.onended = () => {
                    URL.revokeObjectURL(blobUrl);
                    this.messages = this.messages.map(m => 
                        m.id === messageId ? { ...m, isPlaying: false, speakIcon: 'utility:volume_high' } : m
                    );
                    this.currentAudio = null;
                };
                
                audio.onerror = () => {
                    URL.revokeObjectURL(blobUrl);
                    console.warn('ElevenLabs audio failed, falling back to browser TTS');
                    this.speakWithBrowserTTS(messageId, textToSpeak);
                };
                
                await audio.play();
                audioPlayed = true;
                
            } catch (elevenLabsError) {
                console.warn('ElevenLabs TTS failed, using browser fallback:', elevenLabsError);
            }
            
            // Fallback to browser Web Speech Synthesis
            if (!audioPlayed) {
                this.speakWithBrowserTTS(messageId, textToSpeak);
            }
            
        } catch (error) {
            console.error('TTS error:', error);
            // Reset playing state
            this.messages = this.messages.map(m => 
                m.id === messageId ? { ...m, isPlaying: false, speakIcon: 'utility:volume_high' } : m
            );
            this.showError('Speech synthesis failed', error.body?.message || error.message);
        }
    }
    
    speakWithBrowserTTS(messageId, text, autoListenAfter = false) {
        if ('speechSynthesis' in window) {
            const utterance = new SpeechSynthesisUtterance(text);
            utterance.rate = this.speed / 100;
            
            utterance.onend = () => {
                this.messages = this.messages.map(m => 
                    m.id === messageId ? { ...m, isPlaying: false, speakIcon: 'utility:volume_high' } : m
                );
                this.isSpeaking = false;
                // Auto-listen after TTS completes in voice mode if session active
                if (autoListenAfter && this.isListeningActive && this.mode === 'voice') {
                    setTimeout(() => this.startRecording(), 300);
                }
            };
            
            utterance.onerror = (e) => {
                console.error('Browser TTS error:', e);
                this.messages = this.messages.map(m => 
                    m.id === messageId ? { ...m, isPlaying: false, speakIcon: 'utility:volume_high' } : m
                );
                // Still try to auto-listen even if TTS fails
                if (autoListenAfter && this.mode === 'voice') {
                    setTimeout(() => this.startRecording(), 300);
                }
            };
            
            window.speechSynthesis.speak(utterance);
        } else {
            console.error('Browser speech synthesis not supported');
            this.messages = this.messages.map(m => 
                m.id === messageId ? { ...m, isPlaying: false, speakIcon: 'utility:volume_high' } : m
            );
            // Still try to auto-listen
            if (autoListenAfter && this.mode === 'voice') {
                setTimeout(() => this.startRecording(), 300);
            }
        }
    }
    
    // Speak message then auto-listen (for voice mode)
    async speakMessageThenListen(messageId, text) {
        try {
            // Check if summarization is needed
            let textToSpeak = text;
            const needsSummarization = await shouldSummarize({ text });
            
            if (needsSummarization) {
                textToSpeak = await summarizeForVoice({ text });
            }
            
            // Update message state to playing
            this.messages = this.messages.map(m => 
                m.id === messageId ? { ...m, isPlaying: true, speakIcon: 'utility:pause' } : m
            );
            
            // Try ElevenLabs TTS first
            let audioPlayed = false;
            try {
                const audioBase64 = await synthesizeSpeech({
                    text: textToSpeak,
                    voiceId: this.selectedVoice,
                    voiceSettings: {
                        stability: this.stability / 100,
                        similarity: 0.75,
                        speed: this.speed / 100
                    }
                });
                
                // Create blob URL instead of data URL (CSP-friendly)
                const binaryString = atob(audioBase64);
                const bytes = new Uint8Array(binaryString.length);
                for (let i = 0; i < binaryString.length; i++) {
                    bytes[i] = binaryString.charCodeAt(i);
                }
                const blob = new Blob([bytes], { type: 'audio/mp3' });
                const blobUrl = URL.createObjectURL(blob);
                
                this.stopAudio();
                const audio = new Audio(blobUrl);
                this.currentAudio = audio;
                
                audio.onended = () => {
                    URL.revokeObjectURL(blobUrl);
                    this.messages = this.messages.map(m => 
                        m.id === messageId ? { ...m, isPlaying: false, speakIcon: 'utility:volume_high' } : m
                    );
                    this.currentAudio = null;
                    this.isSpeaking = false;
                    // Auto-listen after audio completes if session still active
                    if (this.isListeningActive && this.mode === 'voice') {
                        setTimeout(() => this.startRecording(), 300);
                    }
                };
                
                audio.onerror = () => {
                    URL.revokeObjectURL(blobUrl);
                    console.warn('ElevenLabs audio failed, falling back to browser TTS');
                    this.speakWithBrowserTTS(messageId, textToSpeak, true);
                };
                
                await audio.play();
                audioPlayed = true;
                
            } catch (elevenLabsError) {
                console.warn('ElevenLabs TTS failed, using browser fallback:', elevenLabsError);
            }
            
            // Fallback to browser Web Speech Synthesis
            if (!audioPlayed) {
                this.speakWithBrowserTTS(messageId, textToSpeak, true);
            }
            
        } catch (error) {
            console.error('TTS error:', error);
            this.messages = this.messages.map(m => 
                m.id === messageId ? { ...m, isPlaying: false, speakIcon: 'utility:volume_high' } : m
            );
            this.isSpeaking = false;
            // Still auto-listen even if TTS fails
            if (this.isListeningActive && this.mode === 'voice') {
                setTimeout(() => this.startRecording(), 300);
            }
        }
    }
    
    stopAudio() {
        if (this.currentAudio) {
            this.currentAudio.pause();
            this.currentAudio = null;
        }
        // Also stop browser TTS if running
        if ('speechSynthesis' in window) {
            window.speechSynthesis.cancel();
        }
    }
    
    handlePlayMessage(event) {
        const messageId = event.currentTarget.dataset.id;
        const message = this.messages.find(m => m.id === messageId);
        
        if (message) {
            if (message.isPlaying) {
                this.stopAudio();
                this.messages = this.messages.map(m => 
                    m.id === messageId ? { ...m, isPlaying: false, speakIcon: 'utility:volume_high' } : m
                );
            } else {
                this.speakMessage(messageId, message.content);
            }
        }
    }
    
    // ==================== EVENT HANDLERS ====================
    
    handleOpportunityClick(event) {
        const oppId = event.currentTarget.dataset.id;
        
        // Don't do anything if clicking the same opportunity
        if (oppId === this.selectedOpportunityId) {
            return;
        }
        
        // Check if we had an active conversation and should ask for feedback
        const hadConversation = this.messages.filter(m => !m.isTyping).length > 1;
        
        if (hadConversation) {
            // Store the pending navigation and show feedback modal
            this.pendingOpportunityId = oppId;
            this.openFeedbackModal();
        } else {
            // No conversation, just switch directly
            this.switchToOpportunity(oppId);
        }
    }
    
    switchToOpportunity(oppId) {
        // Check for unsaved changes
        if (this.hasChanges) {
            // For simplicity, auto-discard. In production, show confirmation.
            this.handleDiscardChanges();
        }
        
        this.selectedOpportunityId = oppId;
        
        // Update list selection state
        this.opportunities = this.opportunities.map(opp => ({
            ...opp,
            itemClass: 'opp-item' + (opp.Id === oppId ? ' selected' : '')
        }));
        
        // Reset chat state for new opportunity
        this.messages = [];
        this.updatedFields = new Set();
        this.isEditing = false;
        this.editedValues = {};
        this.agentSessionId = null;
        this.sequenceId = 0;
        
        // Reset update flags
        this.stageUpdatedByAgent = false;
        this.closeDateUpdatedByAgent = false;
        this.nextStepUpdatedByAgent = false;
        
        this.loadOpportunityDetail(oppId);
    }
    
    handlePrevPage() {
        if (this.currentPage > 1) {
            this.currentPage--;
            this.loadOpportunities();
        }
    }
    
    handleNextPage() {
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
            this.loadOpportunities();
        }
    }
    
    handleCloseDateFilterChange(event) {
        this.closeDateFilter = event.detail.value;
        this.currentPage = 1; // Reset to first page on filter change
        this.loadOpportunities();
    }
    
    handleOwnerFilterChange(event) {
        this.ownerFilter = event.detail.value;
        this.currentPage = 1; // Reset to first page on filter change
        this.loadOpportunities();
    }
    
    handleInputChange(event) {
        this.userInput = event.target.value;
    }
    
    handleKeyPress(event) {
        if (event.key === 'Enter' && !this.isSendDisabled) {
            this.handleSend();
        }
    }
    
    handleKeyDown(event) {
        // Enter without Shift sends the message
        // Shift+Enter allows new line
        if (event.key === 'Enter' && !event.shiftKey && !this.isSendDisabled) {
            event.preventDefault();
            this.handleSend();
        }
    }
    
    handleSend() {
        const message = this.userInput.trim();
        if (!message) return;
        
        this.addUserMessage(message);
        this.userInput = '';
        this.sendToAgent(message);
    }
    
    // Mode selection
    setTextMode() { this.mode = 'text'; }
    setWhisperMode() { this.mode = 'whisper'; }
    setVoiceMode() { this.mode = 'voice'; }
    
    // Settings
    toggleSettings() {
        this.showSettings = !this.showSettings;
    }
    
    handleVoiceChange(event) {
        this.selectedVoice = event.detail.value;
    }
    
    handleStabilityChange(event) {
        this.stability = parseInt(event.target.value, 10);
    }
    
    handleSpeedChange(event) {
        this.speed = parseInt(event.target.value, 10);
    }
    
    // Coaching intensity
    handleCoachingIntensityChange(event) {
        this.coachingIntensity = parseInt(event.target.value, 10);
    }
    
    // Feedback modal handlers
    openFeedbackModal() {
        this.feedbackRating = null;
        this.feedbackComment = '';
        this.showFeedbackModal = true;
    }
    
    closeFeedbackModal() {
        this.showFeedbackModal = false;
    }
    
    handleThumbsUp() {
        this.feedbackRating = 'positive';
    }
    
    handleThumbsDown() {
        this.feedbackRating = 'negative';
    }
    
    handleFeedbackCommentChange(event) {
        this.feedbackComment = event.detail.value;
    }
    
    skipFeedback() {
        this.closeFeedbackModal();
        this.proceedAfterFeedback();
    }
    
    async submitFeedback() {
        if (!this.feedbackRating) return;
        
        this.isSubmittingFeedback = true;
        try {
            const messageCount = this.messages.filter(m => !m.isTyping).length;
            
            const result = await saveFeedback({
                sessionId: this.agentSessionId,
                opportunityId: this.selectedOpportunityId,
                rating: this.feedbackRating,
                comment: this.feedbackComment,
                messageCount: messageCount
            });
            
            if (result.success) {
                this.showToast('Thank you!', 'Your feedback has been recorded.', 'success');
            } else {
                console.warn('Feedback save warning:', result.error);
                // Still show thank you - we don't want to frustrate users
                this.showToast('Thank you!', 'Your feedback has been noted.', 'success');
            }
            
            this.closeFeedbackModal();
            this.proceedAfterFeedback();
        } catch (error) {
            console.error('Error submitting feedback:', error);
            // Don't block the user on feedback errors
            this.showToast('Thank you!', 'Your feedback has been noted.', 'success');
            this.closeFeedbackModal();
            this.proceedAfterFeedback();
        } finally {
            this.isSubmittingFeedback = false;
        }
    }
    
    proceedAfterFeedback() {
        // Navigate to pending opportunity if one was set
        if (this.pendingOpportunityId) {
            if (this.pendingOpportunityId === '__NEXT_PAGE__') {
                this.pendingOpportunityId = null;
                this.handleNextPage();
            } else {
                const oppId = this.pendingOpportunityId;
                this.pendingOpportunityId = null;
                this.switchToOpportunity(oppId);
            }
        }
    }
    
    // Editing
    handleToggleEdit() {
        this.isEditing = true;
        // Initialize edited values from current opportunity
        this.editedValues = {};
        for (const config of MEDDPICC_CONFIG) {
            this.editedValues[config.key] = this.selectedOpportunity[config.key] || '';
            this.editedValues[config.scoreKey] = this.selectedOpportunity[config.scoreKey] || '';
        }
        this.editedValues.Description = this.selectedOpportunity.Description || '';
    }
    
    handleCancelEdit() {
        this.isEditing = false;
        this.editedValues = {};
    }
    
    handleDescriptionChange(event) {
        this.editedValues.Description = event.target.value;
    }
    
    handleFieldEdit(event) {
        const field = event.currentTarget.dataset.field;
        this.editedValues[field] = event.target.value;
    }
    
    handleScoreEdit(event) {
        const field = event.currentTarget.dataset.field;
        this.editedValues[field] = event.detail.value;
    }
    
    async handleAcceptAll() {
        this.isSaving = true;
        try {
            // Clear updated indicators and move to next
            this.updatedFields = new Set();
            this.previousValues = this.extractMeddpiccValues(this.selectedOpportunity);
            this.showToast('Success', 'Changes accepted', 'success');
            
            // Auto-advance to next opportunity
            this.advanceToNextOpportunity();
            
        } finally {
            this.isSaving = false;
        }
    }
    
    async handleSaveEdits() {
        this.isSaving = true;
        try {
            await saveOpportunity({
                opportunityId: this.selectedOpportunityId,
                fieldUpdates: this.editedValues
            });
            
            // Refresh the opportunity
            await this.loadOpportunityDetail(this.selectedOpportunityId);
            
            this.isEditing = false;
            this.editedValues = {};
            this.updatedFields = new Set();
            
            this.showToast('Success', 'Changes saved', 'success');
            
            // Auto-advance to next opportunity
            this.advanceToNextOpportunity();
            
        } catch (error) {
            this.showError('Failed to save', error);
        } finally {
            this.isSaving = false;
        }
    }
    
    handleDiscardChanges() {
        this.updatedFields = new Set();
        this.isEditing = false;
        this.editedValues = {};
    }
    
    advanceToNextOpportunity() {
        const currentIndex = this.opportunities.findIndex(o => o.Id === this.selectedOpportunityId);
        if (currentIndex < this.opportunities.length - 1) {
            const nextOpp = this.opportunities[currentIndex + 1];
            // After save, show feedback then advance
            this.pendingOpportunityId = nextOpp.Id;
            this.openFeedbackModal();
        } else if (this.currentPage < this.totalPages) {
            // Go to next page (feedback modal will be shown)
            this.pendingOpportunityId = '__NEXT_PAGE__';
            this.openFeedbackModal();
        }
    }
    
    // ==================== GETTERS ====================
    
    get containerClass() {
        return 'deal-review-container';
    }
    
    get isPrevDisabled() {
        return this.currentPage <= 1;
    }
    
    get isNextDisabled() {
        return this.currentPage >= this.totalPages;
    }
    
    get hasChanges() {
        return this.updatedFields.size > 0;
    }
    
    get descriptionDisplay() {
        return this.selectedOpportunity?.Description || 'No description provided.';
    }
    
    get isEditingDescription() {
        return this.isEditing;
    }
    
    get editedDescription() {
        return this.editedValues.Description || '';
    }
    
    get formattedSelectedAmount() {
        return this.formatCurrency(this.selectedOpportunity?.Amount);
    }
    
    get formattedSelectedCloseDate() {
        return this.formatDate(this.selectedOpportunity?.CloseDate);
    }
    
    get probabilityDisplay() {
        const prob = this.selectedOpportunity?.Probability;
        return prob != null ? `${prob}% Probability` : '';
    }
    
    get closeDateClass() {
        let classes = 'deal-close';
        if (this.updatedFields.has('CloseDate')) {
            classes += ' updated';
        }
        return classes;
    }
    
    get pathContainerClass() {
        let classes = 'path-container';
        if (this.updatedFields.has('StageName')) {
            classes += ' updated';
        }
        return classes;
    }
    
    get hasNextStep() {
        return this.selectedOpportunity && this.selectedOpportunity.NextStep;
    }
    
    get nextStepContainerClass() {
        let classes = 'next-step-section';
        if (this.updatedFields.has('NextStep')) {
            classes += ' updated';
        }
        return classes;
    }
    
    get nextStepUpdated() {
        return this.updatedFields.has('NextStep');
    }
    
    get stagePathItems() {
        if (!this.stageOptions.length || !this.selectedOpportunity) {
            return [];
        }
        
        const currentStage = this.selectedOpportunity.StageName;
        let reachedCurrent = false;
        
        return this.stageOptions.map(stage => {
            const isCurrent = stage.value === currentStage;
            if (isCurrent) reachedCurrent = true;
            
            let itemClass = 'path-item';
            if (isCurrent) {
                itemClass += ' current';
            } else if (!reachedCurrent) {
                itemClass += ' complete';
            }
            
            return {
                ...stage,
                itemClass
            };
        });
    }
    
    get formattedOverallScore() {
        const score = this.selectedOpportunity?.MEDDPICC_Overall_Score__c;
        // Formula returns 0-100, convert to 5-point scale for display
        const fivePointScore = score ? score / 20 : 0;
        return score ? `${fivePointScore.toFixed(1)}/5` : 'N/A';
    }
    
    get overallScoreClass() {
        const score = this.selectedOpportunity?.MEDDPICC_Overall_Score__c;
        // Convert 0-100 to 0-5 scale for class determination
        const fivePointScore = score ? score / 20 : 0;
        if (!score) return 'overall-score-value';
        if (fivePointScore >= 3.5) return 'overall-score-value high';
        if (fivePointScore >= 2.5) return 'overall-score-value medium';
        return 'overall-score-value low';
    }
    
    get meddpiccFields() {
        if (!this.selectedOpportunity) return [];
        
        return MEDDPICC_CONFIG.map(config => {
            const value = this.selectedOpportunity[config.key];
            const scoreRaw = this.selectedOpportunity[config.scoreKey];
            const scoreNum = this.extractScoreNumber(scoreRaw);
            const wasUpdated = this.updatedFields.has(config.key) || this.updatedFields.has(config.scoreKey);
            
            return {
                ...config,
                displayValue: value || 'No information captured yet.',
                score: scoreRaw ? scoreRaw.split(' - ')[0] : null,
                scoreClass: scoreNum ? `field-score score-${scoreNum}` : 'field-score',
                wrapperClass: 'meddpicc-field' + (wasUpdated ? ' updated' : ''),
                wasUpdated,
                isEditing: this.isEditing,
                editValue: this.editedValues[config.key] || '',
                editScore: this.editedValues[config.scoreKey] || ''
            };
        });
    }
    
    get scoreOptions() {
        return SCORE_OPTIONS;
    }
    
    // Mode getters
    get textModeVariant() {
        return this.mode === 'text' ? 'brand' : 'neutral';
    }
    
    get whisperModeVariant() {
        return this.mode === 'whisper' ? 'brand' : 'neutral';
    }
    
    get voiceModeVariant() {
        return this.mode === 'voice' ? 'brand' : 'neutral';
    }
    
    get isTextMode() {
        return this.mode === 'text';
    }
    
    get isVoiceInputMode() {
        return this.mode === 'whisper' || this.mode === 'voice';
    }
    
    get voiceModeHint() {
        return this.mode === 'voice' 
            ? 'Agent will respond with voice' 
            : 'Agent will respond with text';
    }
    
    get voiceStatusLabel() {
        if (this.isProcessing) return 'Agent thinking...';
        if (this.isSpeaking) return 'Agent speaking...';
        if (this.isRecording) return 'Listening...';
        return 'Ready to listen';
    }
    
    get voiceActiveClass() {
        let cls = 'voice-toggle active';
        if (this.isProcessing) cls += ' processing';
        if (this.isRecording) cls += ' recording';
        if (this.isSpeaking) cls += ' speaking';
        return cls;
    }
    
    get voiceToggleInactiveClass() {
        let cls = 'voice-toggle inactive';
        if (this.isProcessing) cls += ' processing';
        return cls;
    }
    
    get voiceButtonLabel() {
        if (this.isProcessing) return 'Agent thinking...';
        return 'Start Conversation';
    }
    
    get voiceActiveHint() {
        if (this.isProcessing) return 'Please wait...';
        return 'Click to end conversation';
    }
    
    handleVoiceActiveClick() {
        // Don't allow toggling while processing
        if (!this.isProcessing) {
            this.toggleListening();
        }
    }
    
    get inputPlaceholder() {
        return this.mode === 'whisper' ? 
            'Type or click mic to speak...' : 
            'Share deal updates with the AI...';
    }
    
    get isSendDisabled() {
        return !this.userInput.trim() || this.isProcessing;
    }
    
    // Voice settings
    get stabilityValue() {
        return this.stability;
    }
    
    get stabilityPercent() {
        return this.stability;
    }
    
    get speedValue() {
        return this.speed;
    }
    
    get speedPercent() {
        return (this.speed / 100).toFixed(1);
    }
    
    // Coaching intensity getters
    get coachingIntensityLabel() {
        return COACHING_LEVELS[this.coachingIntensity]?.label || 'Balanced';
    }
    
    get coachingDescription() {
        return COACHING_LEVELS[this.coachingIntensity]?.description || '';
    }
    
    get coachingStyle() {
        return COACHING_LEVELS[this.coachingIntensity]?.style || 'balanced';
    }
    
    // Feedback modal getters
    get thumbsUpClass() {
        return 'feedback-btn' + (this.feedbackRating === 'positive' ? ' selected' : '');
    }
    
    get thumbsDownClass() {
        return 'feedback-btn' + (this.feedbackRating === 'negative' ? ' selected' : '');
    }
    
    get isFeedbackSubmitDisabled() {
        return this.feedbackRating === null || this.isSubmittingFeedback;
    }
    
    // ==================== UTILITIES ====================
    
    formatCurrency(amount) {
        if (amount == null) return '-';
        return new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: 'USD',
            minimumFractionDigits: 0,
            maximumFractionDigits: 0
        }).format(amount);
    }
    
    formatDate(dateStr) {
        if (!dateStr) return '-';
        const date = new Date(dateStr);
        return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
    }
    
    extractScoreNumber(scoreValue) {
        if (!scoreValue) return null;
        const match = scoreValue.match(/^(\d)/);
        return match ? parseInt(match[1], 10) : null;
    }
    
    getScoreBadgeClass(score) {
        if (!score) return '';
        const rounded = Math.round(score);
        return `score-badge-${Math.min(5, Math.max(1, rounded))}`;
    }
    
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
    
    showError(title, error) {
        console.error(title, error);
        const message = error?.body?.message || error?.message || 'An unexpected error occurred';
        this.showToast(title, message, 'error');
    }
}

