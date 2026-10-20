import { api } from 'lwc';
import LightningModal from 'lightning/modal';

export default class Dmt_passport_modal extends LightningModal  {
    @api noShowInfo;
    @api graphicModal;
    @api limits;
    @api featureName;
    @api featureLight;
    @api validations;
    @api errorModal;
    @api showProfitabilityChart;
    @api profitability;
    @api opportunityId;
    @api noShowInfoMessage;
    @api showConditionDesc = false;
    @api associatedLineUrl;
    @api associatedLineLabel;
    @api currencyId;

    // CIBGLOBALD-4713 - state of the profitability body (dmt_profitability_view) and of the PDF download
    profitabilityLoading = false;
    profitabilityCanDownload = false;
    downloadInProgress = false;
    downloadError;

    handleOkay() {
        this.close('okay');
    }

    /**
     * CIBGLOBALD-4713 - Footer buttons as a list, so a new action is one more entry. Profitability mode
     * adds 'Download PDF' (dmt_profitability_view.downloadPdf) to the right of Close.
     */
    get footerActions() {
        const actions = [{ name: 'close', label: 'Close', variant: 'neutral', disabled: false }];
        if (this.showProfitabilityChart) {
            actions.push({
                name: 'downloadPdf',
                label: this.downloadInProgress ? 'Downloading PDF...' : 'Download PDF',
                iconName: 'utility:download',
                variant: 'brand',
                disabled: this.downloadInProgress || this.profitabilityLoading || !this.profitabilityCanDownload
            });
        }
        return actions;
    }

    handleFooterAction(event) {
        const name = event.currentTarget.dataset.name;
        if (name === 'downloadPdf') {
            this.handleDownloadPdf();
        } else {
            this.handleOkay();
        }
    }

    handleProfitabilityStatus(event) {
        this.profitabilityLoading = event.detail.isLoading;
        this.profitabilityCanDownload = event.detail.canDownload;
    }

    async handleDownloadPdf() {
        const view = this.template.querySelector('c-dmt_profitability_view');
        if (!view) {
            return;
        }
        this.downloadInProgress = true;
        this.downloadError = null;
        try {
            await view.downloadPdf();
        } catch (error) {
            console.error('[dmt_passport_modal] PDF download error', error);
            this.downloadError = 'The PDF could not be generated. Please try again.';
        } finally {
            this.downloadInProgress = false;
        }
    }

    get featureNameTitle() {
        return this.featureName ? this.featureName : 'Capability';
    }

    get hasAssociatedLine() {
        return !!(this.associatedLineUrl && this.associatedLineLabel);
    }
}