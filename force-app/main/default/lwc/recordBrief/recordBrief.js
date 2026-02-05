import { LightningElement, api, track } from 'lwc';
import generateRecordBrief from '@salesforce/apex/RecordBriefController.generateRecordBrief';
import getRecordMetadata from '@salesforce/apex/RecordBriefController.getRecordMetadata';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// Enhanced markdown parser for compact formatting
const parseMarkdown = (text) => {
    if (!text) return '';
    
    // Escape HTML
    let html = text
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;');
    
    // Headers - make them compact
    html = html.replace(/^### (.*$)/gim, '<h4 class="brief-h4">$1</h4>');
    html = html.replace(/^## (.*$)/gim, '<h3 class="brief-h3">$1</h3>');
    html = html.replace(/^# (.*$)/gim, '<h3 class="brief-h3">$1</h3>');
    
    // Bold and Italic
    html = html.replace(/\*\*\*(.*?)\*\*\*/g, '<strong><em>$1</em></strong>');
    html = html.replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>');
    html = html.replace(/\*(.*?)\*/g, '<em>$1</em>');
    
    // Bullet lists - wrap consecutive li elements
    html = html.replace(/^\s*[-*]\s+(.*)$/gim, '<li>$1</li>');
    html = html.replace(/(<li>[\s\S]*?<\/li>)(?=\s*<li>|$)/g, '$1');
    html = html.replace(/(<li>[\s\S]*<\/li>)/g, '<ul class="brief-list">$1</ul>');
    // Fix nested ul issue
    html = html.replace(/<\/ul>\s*<ul class="brief-list">/g, '');
    
    // Numbered lists  
    html = html.replace(/^\s*\d+\.\s+(.*)$/gim, '<li>$1</li>');
    
    // Line breaks (double newline = paragraph)
    html = html.replace(/\n\n/g, '</p><p>');
    html = html.replace(/\n/g, '<br/>');
    
    // Wrap in paragraph
    html = '<p>' + html + '</p>';
    
    // Clean up empty paragraphs and formatting issues
    html = html.replace(/<p><\/p>/g, '');
    html = html.replace(/<p><br\/><\/p>/g, '');
    html = html.replace(/<p>\s*<h/g, '<h');
    html = html.replace(/<\/h3>\s*<\/p>/g, '</h3>');
    html = html.replace(/<\/h4>\s*<\/p>/g, '</h4>');
    html = html.replace(/<p>\s*<ul/g, '<ul');
    html = html.replace(/<\/ul>\s*<\/p>/g, '</ul>');
    
    return html;
};

// Loading messages that cycle through
const LOADING_MESSAGES = [
    { text: 'Identifying record type...', duration: 400 },
    { text: 'Querying related records...', duration: 600 },
    { text: 'Analyzing case history...', duration: 800 },
    { text: 'Processing tasks & activities...', duration: 600 },
    { text: 'AI is generating insights...', duration: 2000 },
    { text: 'Almost there...', duration: 5000 }
];

export default class RecordBrief extends LightningElement {
    @api recordId;
    
    @track state = 'idle'; // idle, loading, streaming, loaded, error
    @track briefContent = '';
    @track displayedContent = '';
    @track errorMessage = '';
    @track loadingMessage = 'Analyzing record...';
    @track loadingMessageIndex = 0;
    @track isExpanded = true;
    @track generatedAt = null;
    @track copied = false;
    
    // Record metadata
    @track objectType = '';
    @track objectLabel = '';
    @track recordName = '';
    
    // Streaming state
    streamingIndex = 0;
    streamingInterval = null;
    loadingInterval = null;
    
    // Computed properties
    get isIdle() {
        return this.state === 'idle';
    }
    
    get isLoading() {
        return this.state === 'loading';
    }
    
    get isStreaming() {
        return this.state === 'streaming';
    }
    
    get isLoaded() {
        return this.state === 'loaded';
    }
    
    get hasError() {
        return this.state === 'error';
    }
    
    get cardClass() {
        return `record-brief-card ${this.isExpanded ? 'expanded' : 'collapsed'}`;
    }
    
    get briefContentClass() {
        return `brief-content ${this.isExpanded ? 'expanded' : 'collapsed'}`;
    }
    
    get expandCollapseIcon() {
        return this.isExpanded ? 'utility:chevronup' : 'utility:chevrondown';
    }
    
    get expandCollapseLabel() {
        return this.isExpanded ? 'Collapse' : 'Expand';
    }
    
    get copyButtonLabel() {
        return this.copied ? 'Copied!' : 'Copy';
    }
    
    get copyButtonIcon() {
        return this.copied ? 'utility:check' : 'utility:copy';
    }
    
    get formattedGeneratedAt() {
        if (!this.generatedAt) return '';
        const now = new Date();
        const gen = new Date(this.generatedAt);
        const diffMs = now - gen;
        const diffMins = Math.floor(diffMs / 60000);
        
        if (diffMins < 1) return 'just now';
        if (diffMins < 60) return `${diffMins}m ago`;
        
        const diffHours = Math.floor(diffMins / 60);
        if (diffHours < 24) return `${diffHours}h ago`;
        
        return gen.toLocaleDateString();
    }
    
    get showContent() {
        return this.isStreaming || this.isLoaded;
    }
    
    // Lifecycle
    connectedCallback() {
        // Auto-generate on page load
        if (this.recordId) {
            // Small delay to ensure component is fully rendered
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            setTimeout(() => {
                this.handleGenerateBrief();
            }, 100);
        }
    }
    
    disconnectedCallback() {
        this.clearIntervals();
    }
    
    clearIntervals() {
        if (this.streamingInterval) {
            clearInterval(this.streamingInterval);
            this.streamingInterval = null;
        }
        if (this.loadingInterval) {
            clearTimeout(this.loadingInterval);
            this.loadingInterval = null;
        }
    }
    
    // Event handlers
    handleGenerateBrief() {
        if (!this.recordId) {
            this.showToast('Error', 'No record ID available', 'error');
            return;
        }
        
        this.clearIntervals();
        this.state = 'loading';
        this.loadingMessageIndex = 0;
        this.loadingMessage = LOADING_MESSAGES[0].text;
        this.errorMessage = '';
        this.displayedContent = '';
        this.briefContent = '';
        this.copied = false;
        
        // Start cycling loading messages
        this.cycleLoadingMessages();
        
        // Get metadata first, then generate brief
        this.fetchMetadataAndBrief();
    }
    
    cycleLoadingMessages() {
        const scheduleNext = () => {
            if (this.state !== 'loading' || this.loadingMessageIndex >= LOADING_MESSAGES.length - 1) {
                return;
            }
            
            const currentMsg = LOADING_MESSAGES[this.loadingMessageIndex];
            this.loadingInterval = setTimeout(() => {
                this.loadingMessageIndex++;
                if (this.loadingMessageIndex < LOADING_MESSAGES.length) {
                    this.loadingMessage = LOADING_MESSAGES[this.loadingMessageIndex].text;
                    scheduleNext();
                }
            }, currentMsg.duration);
        };
        
        scheduleNext();
    }
    
    async fetchMetadataAndBrief() {
        try {
            // Get record metadata
            const metadata = await getRecordMetadata({ recordId: this.recordId });
            this.objectType = metadata.objectType;
            this.objectLabel = metadata.objectLabel;
            this.recordName = metadata.recordName;
            
            // Generate brief
            const brief = await generateRecordBrief({ recordId: this.recordId });
            
            this.briefContent = brief;
            this.generatedAt = new Date().toISOString();
            
            // Start streaming animation
            this.startStreaming();
            
        } catch (error) {
            console.error('Error generating brief:', error);
            this.clearIntervals();
            this.errorMessage = error.body?.message || error.message || 'An unexpected error occurred';
            this.state = 'error';
        }
    }
    
    startStreaming() {
        this.clearIntervals();
        this.state = 'streaming';
        this.streamingIndex = 0;
        this.displayedContent = '';
        this.isExpanded = true;
        
        const words = this.briefContent.split(/(\s+)/); // Split but keep whitespace
        const totalWords = words.length;
        
        // Calculate speed - faster for longer content
        const baseSpeed = 15; // ms per word
        const minSpeed = 8;
        const speed = Math.max(minSpeed, baseSpeed - Math.floor(totalWords / 50));
        
        this.streamingInterval = setInterval(() => {
            if (this.streamingIndex < totalWords) {
                // Add words in small chunks for smoother appearance
                const chunkSize = Math.min(3, totalWords - this.streamingIndex);
                for (let i = 0; i < chunkSize; i++) {
                    this.displayedContent += words[this.streamingIndex];
                    this.streamingIndex++;
                }
                this.renderStreamedContent();
            } else {
                this.finishStreaming();
            }
        }, speed);
    }
    
    renderStreamedContent() {
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        requestAnimationFrame(() => {
            const container = this.template.querySelector('.brief-text');
            if (container) {
                container.innerHTML = parseMarkdown(this.displayedContent);
                // User controls their own scrolling - no auto-scroll
            }
        });
    }
    
    finishStreaming() {
        this.clearIntervals();
        this.state = 'loaded';
        this.displayedContent = this.briefContent;
        this.renderStreamedContent();
    }
    
    handleToggleExpand() {
        this.isExpanded = !this.isExpanded;
    }
    
    handleCopy() {
        if (!this.briefContent) return;
        
        // Copy plain text version (strip markdown)
        const plainText = this.briefContent
            .replace(/#{1,4}\s/g, '') // Remove header markers
            .replace(/\*\*/g, '')     // Remove bold markers
            .replace(/\*/g, '')       // Remove italic markers
            .replace(/^[-*]\s/gm, '• '); // Convert bullets
        
        navigator.clipboard.writeText(plainText).then(() => {
            this.copied = true;
            // Reset after 2 seconds
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            setTimeout(() => {
                this.copied = false;
            }, 2000);
        }).catch(err => {
            console.error('Failed to copy:', err);
            this.showToast('Error', 'Failed to copy to clipboard', 'error');
        });
    }
    
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title,
            message,
            variant
        }));
    }
}
