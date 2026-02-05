/**
 * Deal Review Launcher
 * A compact card component for home pages that launches the full Deal Review experience
 */
import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getReviewStats from '@salesforce/apex/DealReviewController.getReviewStats';

export default class DealReviewLauncher extends NavigationMixin(LightningElement) {
    @track openDeals = 0;
    @track needsReview = 0;
    @track hasStats = false;

    connectedCallback() {
        this.loadStats();
    }

    async loadStats() {
        try {
            const stats = await getReviewStats();
            this.openDeals = stats.openDeals;
            this.needsReview = stats.needsReview;
            this.hasStats = true;
        } catch (error) {
            console.error('Failed to load review stats:', error);
            // Stats are optional, component still works without them
        }
    }

    handleLaunch() {
        // Navigate to the Deal Review tab
        this[NavigationMixin.Navigate]({
            type: 'standard__navItemPage',
            attributes: {
                apiName: 'Agentforce_Deal_Review'
            }
        });
    }
}

