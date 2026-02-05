import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import generateDailyBrief from '@salesforce/apex/DailyBriefController.generateDailyBrief';
import synthesizeSpeech from '@salesforce/apex/DailyBriefController.synthesizeSpeech';
import getAvailableVoices from '@salesforce/apex/DailyBriefController.getAvailableVoices';
import checkConfiguration from '@salesforce/apex/DailyBriefController.checkConfiguration';

export default class DailyBrief extends LightningElement {
    // State management
    @track state = 'idle'; // idle, loading, synthesizing, loaded, error
    @track briefContent = '';
    @track errorMessage = '';
    @track generatedAt = null;
    
    // Audio playback
    @track isPlaying = false;
    @track currentTime = 0;
    @track duration = 0;
    @track playbackSpeed = '1';
    audioElement = null;
    audioData = null;
    progressUpdateInterval = null;
    
    // Voice settings
    @track selectedVoiceId = 'EXAVITQu4vr4xnSDxMaL'; // Bella default
    @track voiceOptions = [];
    
    // Configuration
    @track configStatus = null;
    @track loadingMessage = 'Generating your brief...';
    @track generationSucceeded = false; // Track if generation has worked
    
    // Speed options for playback
    speedOptions = [
        { label: '0.5×', value: '0.5' },
        { label: '0.75×', value: '0.75' },
        { label: '1×', value: '1' },
        { label: '1.25×', value: '1.25' },
        { label: '1.5×', value: '1.5' },
        { label: '1.75×', value: '1.75' },
        { label: '2×', value: '2' }
    ];
    
    // Lifecycle
    connectedCallback() {
        this.loadVoices();
        this.checkConfig();
        this.loadSavedPreferences();
    }
    
    disconnectedCallback() {
        this.cleanup();
    }
    
    // Load available voices
    async loadVoices() {
        try {
            const voices = await getAvailableVoices();
            this.voiceOptions = voices;
        } catch (error) {
            console.error('[DailyBrief] Error loading voices:', error);
        }
    }
    
    // Check configuration status
    async checkConfig() {
        try {
            this.configStatus = await checkConfiguration();
            console.log('[DailyBrief] Configuration status:', this.configStatus);
        } catch (error) {
            console.error('[DailyBrief] Error checking config:', error);
        }
    }
    
    // Load saved preferences from localStorage
    loadSavedPreferences() {
        const savedVoice = localStorage.getItem('dailyBrief_voiceId');
        if (savedVoice) {
            this.selectedVoiceId = savedVoice;
        }
        
        const savedSpeed = localStorage.getItem('dailyBrief_speed');
        if (savedSpeed) {
            this.playbackSpeed = savedSpeed;
        }
    }
    
    // State getters
    get isIdle() {
        return this.state === 'idle';
    }
    
    get isLoading() {
        return this.state === 'loading';
    }
    
    get isSynthesizing() {
        return this.state === 'synthesizing';
    }
    
    get isLoaded() {
        return this.state === 'loaded';
    }
    
    get hasError() {
        return this.state === 'error';
    }
    
    get showRefreshButton() {
        return this.state === 'loaded' || this.state === 'error';
    }
    
    get canShare() {
        // Check if Web Share API with file support is available
        // Supported in Safari (macOS/iOS) and Chrome (desktop, version 89+)
        if (this.state !== 'loaded' || !this.audioData) {
            return false;
        }
        
        // Check if Web Share API exists
        if (typeof navigator === 'undefined' || !navigator.share) {
            return false;
        }
        
        // Check if file sharing is supported (canShare method exists)
        // Chrome and Safari both support this
        return typeof navigator.canShare === 'function';
    }
    
    get showConfigWarning() {
        // Don't show warning if generation has already succeeded
        if (this.generationSucceeded) return false;
        // Don't show warning once we're in loaded state with content
        if (this.state === 'loaded' && this.briefContent) return false;
        if (!this.configStatus) return false;
        return !this.configStatus.elevenLabsConfigured || !this.configStatus.promptTemplateConfigured;
    }
    
    get configWarningMessage() {
        if (!this.configStatus) return '';
        
        const issues = [];
        if (!this.configStatus.promptTemplateConfigured) {
            issues.push('Prompt template "Daily_Brief" not found in Prompt Builder');
        }
        if (!this.configStatus.elevenLabsConfigured) {
            issues.push('ElevenLabs API key not configured in Poseidon Settings');
        }
        return issues.join('. ');
    }
    
    // Progress bar style
    get progressStyle() {
        const progress = this.duration > 0 ? (this.currentTime / this.duration) * 100 : 0;
        return `width: ${progress}%`;
    }
    
    // Time formatting
    get formattedCurrentTime() {
        return this.formatTime(this.currentTime);
    }
    
    get formattedDuration() {
        return this.formatTime(this.duration);
    }
    
    get formattedGeneratedAt() {
        if (!this.generatedAt) return '';
        return new Intl.DateTimeFormat('en-US', {
            month: 'short',
            day: 'numeric',
            hour: 'numeric',
            minute: '2-digit'
        }).format(this.generatedAt);
    }
    
    formatTime(seconds) {
        const mins = Math.floor(seconds / 60);
        const secs = Math.floor(seconds % 60);
        return `${mins}:${secs.toString().padStart(2, '0')}`;
    }
    
    // Event handlers
    async handleGenerateBrief() {
        this.state = 'loading';
        this.loadingMessage = 'Generating your brief...';
        this.errorMessage = '';
        
        try {
            // Step 1: Generate the brief content
            console.log('[DailyBrief] Generating brief...');
            const content = await generateDailyBrief();
            
            if (!content) {
                throw new Error('No content was generated');
            }
            
            this.briefContent = content;
            this.generatedAt = new Date();
            this.generationSucceeded = true; // Mark that config is working
            console.log('[DailyBrief] Brief generated:', content.substring(0, 100) + '...');
            
            // Step 2: Synthesize audio
            this.state = 'synthesizing';
            await this.synthesizeAudio();
            
        } catch (error) {
            console.error('[DailyBrief] Error:', error);
            this.errorMessage = error.body?.message || error.message || 'Failed to generate brief';
            this.state = 'error';
        }
    }
    
    async synthesizeAudio() {
        try {
            console.log('[DailyBrief] Synthesizing audio...');
            
            const voiceSettings = {
                stability: 0.5,
                similarity: 0.75,
                speed: 1.0,
                style: 0.0
            };
            
            const audioBase64 = await synthesizeSpeech({
                text: this.briefContent,
                voiceId: this.selectedVoiceId,
                voiceSettings: voiceSettings
            });
            
            if (!audioBase64) {
                throw new Error('No audio data received');
            }
            
            this.audioData = audioBase64;
            await this.prepareAudioPlayer(audioBase64);
            this.renderTranscript();
            this.state = 'loaded';
            
            console.log('[DailyBrief] Audio ready, duration:', this.duration);
            
        } catch (error) {
            console.error('[DailyBrief] Audio synthesis error:', error);
            // Still show the transcript even if audio fails
            this.renderTranscript();
            this.state = 'loaded';
            
            // Surface the actual error message for debugging
            const errorMsg = error.body?.message || error.message || 'Unknown error';
            console.error('[DailyBrief] Audio error details:', errorMsg);
            this.showToast('Audio Unavailable', errorMsg, 'warning');
        }
    }
    
    async prepareAudioPlayer(base64Audio) {
        return new Promise((resolve, reject) => {
            try {
                // Cleanup any existing audio
                this.cleanup();
                
                // Detect if we're on mobile (Salesforce Mobile app uses specific user agents)
                const isMobile = /Mobile|Android|iPhone|iPad/i.test(navigator.userAgent);
                
                let audioUrl;
                if (isMobile) {
                    // Mobile: Use data URL (more compatible with mobile webviews)
                    console.log('[DailyBrief] Using data URL for mobile');
                    audioUrl = `data:audio/mpeg;base64,${base64Audio}`;
                } else {
                    // Desktop: Use blob URL (more efficient for larger files)
                    console.log('[DailyBrief] Using blob URL for desktop');
                    const binaryString = atob(base64Audio);
                    const bytes = new Uint8Array(binaryString.length);
                    for (let i = 0; i < binaryString.length; i++) {
                        bytes[i] = binaryString.charCodeAt(i);
                    }
                    const audioBlob = new Blob([bytes], { type: 'audio/mpeg' });
                    audioUrl = URL.createObjectURL(audioBlob);
                }
                
                // Create audio element
                this.audioElement = new Audio(audioUrl);
                this.audioElement.playbackRate = parseFloat(this.playbackSpeed);
                
                this.audioElement.onloadedmetadata = () => {
                    this.duration = this.audioElement.duration;
                    console.log('[DailyBrief] Audio metadata loaded, duration:', this.duration);
                    resolve();
                };
                
                this.audioElement.onended = () => {
                    this.isPlaying = false;
                    this.currentTime = 0;
                    this.stopProgressUpdates();
                };
                
                this.audioElement.onerror = (e) => {
                    console.error('[DailyBrief] Audio error event:', e);
                    console.error('[DailyBrief] Audio error code:', this.audioElement?.error?.code);
                    console.error('[DailyBrief] Audio error message:', this.audioElement?.error?.message);
                    reject(new Error('Failed to load audio: ' + (this.audioElement?.error?.message || 'Unknown error')));
                };
                
            } catch (error) {
                console.error('[DailyBrief] prepareAudioPlayer exception:', error);
                reject(error);
            }
        });
    }
    
    handlePlayPause() {
        if (!this.audioElement) {
            // Re-synthesize if audio was lost
            this.synthesizeAudio();
            return;
        }
        
        if (this.isPlaying) {
            this.audioElement.pause();
            this.isPlaying = false;
            this.stopProgressUpdates();
        } else {
            this.audioElement.play();
            this.isPlaying = true;
            this.startProgressUpdates();
        }
    }
    
    handleSkipBack() {
        if (this.audioElement) {
            this.audioElement.currentTime = Math.max(0, this.audioElement.currentTime - 15);
            this.currentTime = this.audioElement.currentTime;
        }
    }
    
    handleSkipForward() {
        if (this.audioElement) {
            this.audioElement.currentTime = Math.min(this.duration, this.audioElement.currentTime + 15);
            this.currentTime = this.audioElement.currentTime;
        }
    }
    
    handleProgressClick(event) {
        if (!this.audioElement || !this.duration) return;
        
        const progressContainer = event.currentTarget;
        const rect = progressContainer.getBoundingClientRect();
        const clickX = event.clientX - rect.left;
        const percentage = clickX / rect.width;
        
        this.audioElement.currentTime = percentage * this.duration;
        this.currentTime = this.audioElement.currentTime;
    }
    
    handleSpeedChange(event) {
        this.playbackSpeed = event.detail.value;
        localStorage.setItem('dailyBrief_speed', this.playbackSpeed);
        
        if (this.audioElement) {
            this.audioElement.playbackRate = parseFloat(this.playbackSpeed);
        }
    }
    
    handleVoiceChange(event) {
        this.selectedVoiceId = event.detail.value;
        localStorage.setItem('dailyBrief_voiceId', this.selectedVoiceId);
        
        // Re-synthesize with new voice if we have content
        if (this.briefContent && this.state === 'loaded') {
            this.state = 'synthesizing';
            this.synthesizeAudio();
        }
    }
    
    handleRefresh() {
        this.cleanup();
        this.briefContent = '';
        this.audioData = null;
        this.currentTime = 0;
        this.duration = 0;
        this.handleGenerateBrief();
    }
    
    async handleShare() {
        if (!this.audioData || !navigator.share) {
            this.showToast(
                'Sharing Unavailable', 
                'Native sharing requires Safari (macOS/iOS) or Chrome (desktop, version 89+).', 
                'warning'
            );
            return;
        }
        
        try {
            // Convert base64 to Blob, then to File
            const binaryString = atob(this.audioData);
            const bytes = new Uint8Array(binaryString.length);
            for (let i = 0; i < binaryString.length; i++) {
                bytes[i] = binaryString.charCodeAt(i);
            }
            const audioBlob = new Blob([bytes], { type: 'audio/mpeg' });
            
            // Create a File object with a meaningful name
            const timestamp = this.generatedAt 
                ? this.generatedAt.toISOString().split('T')[0] 
                : new Date().toISOString().split('T')[0];
            const audioFile = new File([audioBlob], `daily-brief-${timestamp}.mp3`, { 
                type: 'audio/mpeg',
                lastModified: this.generatedAt ? this.generatedAt.getTime() : Date.now()
            });
            
            // Check if we can share files (works in Safari macOS/iOS and Chrome desktop)
            if (navigator.canShare && navigator.canShare({ files: [audioFile] })) {
                await navigator.share({
                    title: 'Daily Brief Audio',
                    text: 'Check out my daily brief from Salesforce!',
                    files: [audioFile]
                });
                // Detect browser for appropriate message
                const isMac = navigator.platform.toUpperCase().indexOf('MAC') >= 0;
                const browserName = this.detectBrowser();
                const shareMethod = isMac ? 'macOS share sheet' : `${browserName} share dialog`;
                this.showToast('Shared Successfully', `Audio file shared via ${shareMethod}`, 'success');
            } else {
                // Fallback: try sharing without files (text only)
                // This works in more browsers but doesn't include the file
                await navigator.share({
                    title: 'Daily Brief',
                    text: 'Check out my daily brief from Salesforce!'
                });
                this.showToast('Shared', 'Brief information shared (file sharing not available)', 'success');
            }
        } catch (error) {
            // User cancelled or error occurred
            if (error.name !== 'AbortError') {
                console.error('[DailyBrief] Share error:', error);
                this.showToast('Share Failed', error.message || 'Unable to share audio file', 'error');
            }
            // If user cancelled, don't show an error - it's expected behavior
        }
    }
    
    detectBrowser() {
        const userAgent = navigator.userAgent.toLowerCase();
        if (userAgent.indexOf('chrome') > -1 && userAgent.indexOf('edg') === -1) {
            return 'Chrome';
        } else if (userAgent.indexOf('safari') > -1 && userAgent.indexOf('chrome') === -1) {
            return 'Safari';
        } else if (userAgent.indexOf('firefox') > -1) {
            return 'Firefox';
        } else if (userAgent.indexOf('edg') > -1) {
            return 'Edge';
        }
        return 'browser';
    }
    
    // Progress updates
    startProgressUpdates() {
        this.stopProgressUpdates();
        this.progressUpdateInterval = setInterval(() => {
            if (this.audioElement) {
                this.currentTime = this.audioElement.currentTime;
            }
        }, 100);
    }
    
    stopProgressUpdates() {
        if (this.progressUpdateInterval) {
            clearInterval(this.progressUpdateInterval);
            this.progressUpdateInterval = null;
        }
    }
    
    // Render transcript with markdown
    renderTranscript() {
        // Use requestAnimationFrame to ensure DOM is ready
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        requestAnimationFrame(() => {
            const transcriptDiv = this.template.querySelector('.transcript-content');
            if (transcriptDiv && this.briefContent) {
                transcriptDiv.innerHTML = this.parseMarkdown(this.briefContent);
            }
        });
    }
    
    parseMarkdown(text) {
        if (!text) return '';
        
        let html = text
            // Escape HTML entities first
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            // Headers
            .replace(/^### (.+)$/gm, '<h4 class="md-h3">$1</h4>')
            .replace(/^## (.+)$/gm, '<h3 class="md-h2">$1</h3>')
            .replace(/^# (.+)$/gm, '<h2 class="md-h1">$1</h2>')
            // Bold and italic
            .replace(/\*\*\*(.+?)\*\*\*/g, '<strong><em>$1</em></strong>')
            .replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
            .replace(/\*(.+?)\*/g, '<em>$1</em>')
            // Bullet points
            .replace(/^[\-\*] (.+)$/gm, '<li class="md-bullet">$1</li>')
            // Numbered lists
            .replace(/^\d+\. (.+)$/gm, '<li class="md-number">$1</li>')
            // Horizontal rules
            .replace(/^---$/gm, '<hr class="md-hr">')
            // Line breaks (preserve double newlines as paragraphs)
            .replace(/\n\n/g, '</p><p class="md-para">')
            .replace(/\n/g, '<br>');
        
        // Wrap in paragraph
        html = '<p class="md-para">' + html + '</p>';
        
        // Group list items
        html = html.replace(/(<li class="md-bullet">.+?<\/li>\s*)+/g, '<ul class="md-list">$&</ul>');
        html = html.replace(/(<li class="md-number">.+?<\/li>\s*)+/g, '<ol class="md-list">$&</ol>');
        
        return html;
    }
    
    // Cleanup
    cleanup() {
        this.stopProgressUpdates();
        
        if (this.audioElement) {
            this.audioElement.pause();
            this.audioElement.src = '';
            this.audioElement = null;
        }
        
        this.isPlaying = false;
    }
    
    // Toast helper
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        }));
    }
}

