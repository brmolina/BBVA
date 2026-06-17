import { LightningElement, api, wire } from 'lwc';
import getWebLinkUrl from '@salesforce/apex/DMT_Opportunity_Handler.getWebLinkUrl';
import dmtHereText from '@salesforce/label/c.DMT_weblink_label_here';
import dmtDefaultLabel from '@salesforce/label/c.DMT_weblink_default_label';

export default class DmtProductScopeLink extends LightningElement {
    // Expose this so the Admin can type the exact Metadata record name in the App Builder
    @api metadataRecordName = 'Default_Record_Name';
    @api infoText;
    @api applyIconTopOffset;

    targetUrl;
    labels = {
        dmtHereText,
        dmtDefaultLabel
    };

    get resolvedInfoText() {
        return this.infoText || this.labels.dmtDefaultLabel;
    }

    get iconClass() {
        const shouldApplyOffset = this.applyIconTopOffset !== false;
        return `slds-m-right_small${shouldApplyOffset ? ' icon-top-offset' : ''}`;
    }

    @wire(getWebLinkUrl, { recordDeveloperName: '$metadataRecordName' })
    wiredUrl({ error, data }) {
        if (data) {
            this.targetUrl = data;
        } else if (error) {
            console.error('Error fetching URL from Custom Metadata', error);
        }
    }
}