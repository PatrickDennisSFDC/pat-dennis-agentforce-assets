/**
 * Agent Search - Agentic Search Experience for Experience Cloud
 * 
 * Features:
 * - Initial centered search bar that expands to split view
 * - Left panel: Knowledge article search results with sub-search
 * - Right panel: AI Agent chat conversation
 * - Search query automatically seeds the agent conversation
 */

import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

// Static resources
import AMGEN_LOGO from '@salesforce/resourceUrl/AmgenLogo';

// Apex methods
import searchKnowledge from '@salesforce/apex/AgentSearchController.searchKnowledge';
import sendAgentMessage from '@salesforce/apex/AgentSearchController.sendAgentMessage';
import saveFeedback from '@salesforce/apex/AgentSearchController.saveFeedback';

export default class AgentSearch extends NavigationMixin(LightningElement) {
    // ==================== STATE ====================
    
    // Search state
    @track searchTerm = '';
    @track currentSearchTerm = '';
    @track hasSearched = false;
    @track isSearching = false;
    
    // Search results (articles + files combined)
    @track searchResults = [];
    
    // Chat state
    @track messages = [];
    @track userInput = '';
    @track isProcessing = false;
    
    // Agent session
    agentSessionId = null;
    sequenceId = 0;
    isSessionReady = false;
    sessionWarmPromise = null;
    
    // Feedback state
    @track showFeedbackModal = false;
    @track feedbackRating = null; // 'positive' or 'negative'
    @track feedbackComment = '';
    @track isSubmittingFeedback = false;
    
    // Logo URL
    amgenLogoUrl = AMGEN_LOGO;
    
    // Sample queries for typewriter effect
    sampleQueries = [
        'How many parental leave days do I get?',
        'My VPN isn\'t connecting...',
        'What\'s the per diem for NYC?',
        'What trainings do I need to complete?',
        'How do I reset my password?',
        'What are the 401k matching details?',
        'How do I book a conference room?',
        'What\'s our hybrid work policy?'
    ];
    currentQueryIndex = 0;
    currentCharIndex = 0;
    isDeleting = false;
    typewriterInterval = null;
    @track placeholderText = '';
    
    // ==================== LIFECYCLE ====================
    
    connectedCallback() {
        // Start typewriter animation
        this.startTypewriter();
        
        // Pre-warm agent session in background (don't await)
        this.prewarmAgentSession();
    }
    
    disconnectedCallback() {
        // Clean up interval
        if (this.typewriterInterval) {
            clearInterval(this.typewriterInterval);
        }
    }
    
    /**
     * Pre-warm the agent session on component load.
     * This eliminates the cold-start delay when the user actually searches.
     */
    async prewarmAgentSession() {
        console.log('[AgentSearch] Pre-warming agent session...');
        const startTime = performance.now();
        
        // Store the promise so we can await it if user searches before it completes
        this.sessionWarmPromise = (async () => {
            try {
                this.sequenceId = 1;
                const result = await sendAgentMessage({
                    userMessage: 'Hello, I am starting a new session.',
                    sessionId: null,
                    sequenceId: this.sequenceId
                });
                
                if (result.success && result.sessionId) {
                    this.agentSessionId = result.sessionId;
                    this.isSessionReady = true;
                    console.log(`[AgentSearch] Session pre-warmed in ${Math.round(performance.now() - startTime)}ms. SessionId: ${result.sessionId}`);
                }
            } catch (error) {
                console.warn('[AgentSearch] Session pre-warm failed (will retry on search):', error);
                // Don't throw - we'll create session on first search if this fails
            }
        })();
        
        return this.sessionWarmPromise;
    }
    
    startTypewriter() {
        const typeSpeed = 80;
        const deleteSpeed = 40;
        const pauseTime = 2000;
        
        const tick = () => {
            const currentQuery = this.sampleQueries[this.currentQueryIndex];
            
            if (!this.isDeleting) {
                this.placeholderText = currentQuery.substring(0, this.currentCharIndex + 1);
                this.currentCharIndex++;
                
                if (this.currentCharIndex === currentQuery.length) {
                    this.isDeleting = true;
                    setTimeout(tick, pauseTime);
                    return;
                }
            } else {
                this.placeholderText = currentQuery.substring(0, this.currentCharIndex - 1);
                this.currentCharIndex--;
                
                if (this.currentCharIndex === 0) {
                    this.isDeleting = false;
                    this.currentQueryIndex = (this.currentQueryIndex + 1) % this.sampleQueries.length;
                }
            }
            
            this.typewriterInterval = setTimeout(tick, this.isDeleting ? deleteSpeed : typeSpeed);
        };
        
        tick();
    }
    
    // ==================== SEARCH HANDLERS ====================
    
    handleSearchInput(event) {
        this.searchTerm = event.target.value;
    }
    
    handleSearchKeydown(event) {
        if (event.key === 'Enter' && !this.isSearchDisabled) {
            this.handleSearch();
        }
    }
    
    handleClearSearch() {
        this.searchTerm = '';
    }
    
    async handleSearch() {
        if (!this.searchTerm || this.searchTerm.trim().length < 2) {
            return;
        }
        
        const term = this.searchTerm.trim();
        this.currentSearchTerm = term;
        this.isSearching = true;
        
        const isFirstSearch = !this.hasSearched;
        
        // Transition to split view immediately for responsive feel
        if (isFirstSearch) {
            this.hasSearched = true;
        }
        
        // Run search and agent conversation IN PARALLEL for speed
        const searchPromise = this.performKnowledgeSearch(term);
        
        if (isFirstSearch) {
            // First search: run agent call in parallel with search
            this.initializeAgentConversation(term);
        }
        
        // Wait for search to complete (agent runs in background)
        await searchPromise;
    }
    
    /**
     * Performs the Knowledge/Files search
     */
    async performKnowledgeSearch(term) {
        try {
            const result = await searchKnowledge({ searchTerm: term });
            
            if (result.success) {
                this.searchResults = result.results || result.articles || [];
            } else {
                console.error('Search failed:', result.message);
                this.searchResults = [];
            }
        } catch (error) {
            console.error('Search error:', error);
            this.searchResults = [];
        } finally {
            this.isSearching = false;
        }
    }
    
    handleBackToSearch() {
        // If there was a conversation, show feedback modal first
        if (this.messages.length > 1) {
            this.showFeedbackModal = true;
        } else {
            this.resetToInitialState();
        }
    }
    
    resetToInitialState() {
        this.hasSearched = false;
        this.searchTerm = '';
        this.currentSearchTerm = '';
        this.searchResults = [];
        this.messages = [];
        this.userInput = '';
        this.agentSessionId = null;
        this.sequenceId = 0;
        this.showFeedbackModal = false;
        this.feedbackRating = null;
        this.feedbackComment = '';
        
        // Pre-warm a new session
        this.prewarmAgentSession();
    }
    
    handleResultClick(event) {
        const url = event.currentTarget.dataset.url;
        if (url) {
            // Open result in new tab
            window.open(url, '_blank');
        }
    }
    
    // ==================== AGENT MESSAGING ====================
    
    async initializeAgentConversation(searchQuery) {
        // Reset messages but KEEP the pre-warmed session if available
        this.messages = [];
        
        // Add the search query as the first user message
        this.addUserMessage(searchQuery);
        
        // If session is pre-warming, wait for it (but show status)
        if (this.sessionWarmPromise && !this.isSessionReady) {
            this.addSystemMessage('Connecting to MyAmgen Agent...');
            await this.sessionWarmPromise;
            this.removeSystemMessages();
        }
        
        // Send to agent (using pre-warmed session if available)
        await this.sendToAgent(searchQuery, true);
    }
    
    handleChatInput(event) {
        this.userInput = event.target.value;
    }
    
    handleChatKeydown(event) {
        // Enter without Shift sends the message
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
        
        // Clear the textarea element directly
        const textarea = this.template.querySelector('.chat-textarea');
        if (textarea) {
            textarea.value = '';
        }
        
        this.sendToAgent(message);
    }
    
    async sendToAgent(userMessage, isInitialMessage = false) {
        this.isProcessing = true;
        
        // Remove connecting message if this is the initial message
        if (isInitialMessage) {
            this.removeSystemMessages();
        }
        
        const typingId = this.addTypingIndicator();
        
        try {
            this.sequenceId++;
            
            const result = await sendAgentMessage({
                userMessage: userMessage,
                sessionId: this.agentSessionId,
                sequenceId: this.sequenceId
            });
            
            if (result.success) {
                // Update session ID if returned
                if (result.sessionId) {
                    this.agentSessionId = result.sessionId;
                }
                
                // Add agent response
                this.addAgentMessage(result.message);
            } else {
                this.addAgentMessage('I apologize, but I encountered an error. Please try again.');
            }
            
        } catch (error) {
            console.error('Agent error:', error);
            let errorMsg = 'I apologize, but I encountered an error communicating with the agent.';
            if (error.body && error.body.message) {
                errorMsg += ' ' + error.body.message;
            }
            this.addAgentMessage(errorMsg);
        } finally {
            this.removeTypingIndicator(typingId);
            this.isProcessing = false;
        }
    }
    
    // ==================== MESSAGE HELPERS ====================
    
    addUserMessage(content) {
        const id = Date.now().toString();
        this.messages = [...this.messages, {
            id,
            content,
            isAgent: false,
            isUser: true,
            isTyping: false,
            wrapperClass: 'message-wrapper user',
            bubbleClass: 'message-bubble user'
        }];
        this.scrollToBottom();
    }
    
    addAgentMessage(content) {
        const id = Date.now().toString();
        this.messages = [...this.messages, {
            id,
            content,
            isAgent: true,
            isUser: false,
            isTyping: false,
            wrapperClass: 'message-wrapper agent',
            bubbleClass: 'message-bubble agent'
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
            bubbleClass: 'message-bubble agent'
        }];
        this.scrollToBottom();
        return id;
    }
    
    removeTypingIndicator(id) {
        this.messages = this.messages.filter(m => m.id !== id);
    }
    
    addSystemMessage(content) {
        const id = 'system-' + Date.now();
        this.messages = [...this.messages, {
            id,
            content,
            isAgent: false,
            isUser: false,
            isSystem: true,
            isTyping: false,
            wrapperClass: 'message-wrapper system',
            bubbleClass: 'message-bubble system'
        }];
        this.scrollToBottom();
        return id;
    }
    
    removeSystemMessages() {
        this.messages = this.messages.filter(m => !m.isSystem);
    }
    
    scrollToBottom() {
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        setTimeout(() => {
            // Try lwc:ref first, fallback to querySelector
            let container = this.refs.chatContainer;
            if (!container) {
                container = this.template.querySelector('.chat-messages');
            }
            if (container) {
                container.scrollTo({
                    top: container.scrollHeight,
                    behavior: 'smooth'
                });
            }
        }, 100);
    }
    
    // ==================== FEEDBACK HANDLERS ====================
    
    handleRatingPositive() {
        this.feedbackRating = 'positive';
    }
    
    handleRatingNegative() {
        this.feedbackRating = 'negative';
    }
    
    handleFeedbackCommentChange(event) {
        this.feedbackComment = event.target.value;
    }
    
    async handleSubmitFeedback() {
        if (!this.feedbackRating) {
            return;
        }
        
        this.isSubmittingFeedback = true;
        
        try {
            await saveFeedback({
                sessionId: this.agentSessionId,
                rating: this.feedbackRating,
                comment: this.feedbackComment.trim() || null,
                messageCount: this.messages.length
            });
            
            console.log('[AgentSearch] Feedback submitted successfully');
        } catch (error) {
            console.error('[AgentSearch] Error submitting feedback:', error);
            // Don't block the user on feedback errors
        } finally {
            this.isSubmittingFeedback = false;
            this.resetToInitialState();
        }
    }
    
    handleSkipFeedback() {
        this.resetToInitialState();
    }
    
    handleCloseFeedbackModal() {
        this.resetToInitialState();
    }
    
    stopPropagation(event) {
        event.stopPropagation();
    }
    
    // ==================== GETTERS ====================
    
    get containerClass() {
        return 'agent-search-container' + (this.hasSearched ? ' split-view' : ' initial-view');
    }
    
    get isSearchDisabled() {
        return !this.searchTerm || this.searchTerm.trim().length < 2 || this.isSearching;
    }
    
    get hasResults() {
        return this.searchResults && this.searchResults.length > 0;
    }
    
    get resultCountLabel() {
        if (this.isSearching) {
            return 'Searching...';
        }
        const count = this.searchResults ? this.searchResults.length : 0;
        return count === 1 ? '1 result' : count + ' results';
    }
    
    /**
     * Format file size for display
     */
    formatFileSize(bytes) {
        if (!bytes) return '';
        if (bytes < 1024) return bytes + ' B';
        if (bytes < 1048576) return Math.round(bytes / 1024) + ' KB';
        return (bytes / 1048576).toFixed(1) + ' MB';
    }
    
    get isSendDisabled() {
        return !this.userInput || !this.userInput.trim() || this.isProcessing;
    }
    
    // Feedback getters
    get isPositiveSelected() {
        return this.feedbackRating === 'positive';
    }
    
    get isNegativeSelected() {
        return this.feedbackRating === 'negative';
    }
    
    get canSubmitFeedback() {
        return this.feedbackRating && !this.isSubmittingFeedback;
    }
    
    get thumbsUpClass() {
        return 'rating-btn thumbs-up' + (this.isPositiveSelected ? ' selected' : '');
    }
    
    get thumbsDownClass() {
        return 'rating-btn thumbs-down' + (this.isNegativeSelected ? ' selected' : '');
    }
    
    get submitFeedbackLabel() {
        return this.isSubmittingFeedback ? 'Submitting...' : 'Submit Feedback';
    }
}
