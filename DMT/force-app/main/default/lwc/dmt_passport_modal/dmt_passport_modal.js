import { api } from 'lwc';
import LightningModal from 'lightning/modal';
import FORM_FACTOR from '@salesforce/client/formFactor';

// CIBGLOBALD-4711 - The Profitability Detail CSV is a browser download, which the mobile app does not support.
const IS_DESKTOP = FORM_FACTOR === 'Large';

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
    // CIBGLOBALD-4711 - Profitability Detail CSV download (dmt_profitability_view.downloadProfitabilityDetail)
    profitabilityHasResults = false;
    detailDownloadInProgress = false;

    handleOkay() {
        this.close('okay');
    }

    /**
     * CIBGLOBALD-4713 - Footer buttons as a list, so a new action is one more entry. Profitability mode
     * adds 'Download PDF' (dmt_profitability_view.downloadPdf) to the right of Close.
     * CIBGLOBALD-4711 - On desktop, 'Profitability Detail' (Epsilon CSV) goes between Close and Download PDF,
     * enabled when the Passport has profitability results and the body is not loading.
     */
    get footerActions() {
        const actions = [{ name: 'close', label: 'Close', variant: 'neutral', disabled: false }];
        if (this.showProfitabilityChart) {
            const anyDownloadInProgress = this.downloadInProgress || this.detailDownloadInProgress;
            if (IS_DESKTOP) {
                actions.push({
                    name: 'profitabilityDetail',
                    label: this.detailDownloadInProgress ? 'Downloading...' : 'Profitability Detail',
                    iconName: 'utility:download',
                    variant: 'neutral',
                    disabled: anyDownloadInProgress || this.profitabilityLoading || !this.profitabilityHasResults
                });
            }
            actions.push({
                name: 'downloadPdf',
                label: this.downloadInProgress ? 'Downloading PDF...' : 'Download PDF',
                iconName: 'utility:download',
                variant: 'brand',
                disabled: anyDownloadInProgress || this.profitabilityLoading || !this.profitabilityCanDownload
            });
        }
        return actions;
    }

    handleFooterAction(event) {
        const name = event.currentTarget.dataset.name;
        if (name === 'downloadPdf') {
            this.handleDownloadPdf();
        } else if (name === 'profitabilityDetail') {
            this.handleDownloadProfitabilityDetail();
        } else {
            this.handleOkay();
        }
    }

    handleProfitabilityStatus(event) {
        this.profitabilityLoading = event.detail.isLoading;
        this.profitabilityCanDownload = event.detail.canDownload;
        this.profitabilityHasResults = event.detail.hasResults;
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

    // CIBGLOBALD-4711 - Errors (no detail, backend message, not a CSV) are shown above the footer buttons.
    async handleDownloadProfitabilityDetail() {
        const view = this.template.querySelector('c-dmt_profitability_view');
        if (!view) {
            return;
        }
        this.detailDownloadInProgress = true;
        this.downloadError = null;
        try {
            await view.downloadProfitabilityDetail();
        } catch (error) {
            console.error('[dmt_passport_modal] Profitability detail download error', error);
            this.downloadError = error?.body?.message || error?.message || 'The profitability detail could not be downloaded.';
        } finally {
            this.detailDownloadInProgress = false;
        }
    }

    get featureNameTitle() {
        return this.featureName ? this.featureName : 'Capability';
    }

    get hasAssociatedLine() {
        return !!(this.associatedLineUrl && this.associatedLineLabel);
    }
}