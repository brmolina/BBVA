/**
 * CIBGLOBALD-4713 - Body of the Profitability modal (dmt_passport_modal). Shows the HTML built by the
 * Profitability renderer (DMT_Profitability_utils.renderProfitabilityHtml -> DMT_RendererFactory
 * 'Profitability' -> DMT_OppProfitabilityRenderer), the same one used by the NBC views, so the screen and
 * the PDF come from one implementation. The chart image is generated here with the hidden
 * dmt_profitability_chart and sent to Apex. The 'External RWA calculate' button is inserted where the
 * renderer leaves an empty marker; clicking it renders again with the External RWA column.
 */
import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { loadScript } from 'lightning/platformResourceLoader';
import FORM_FACTOR from '@salesforce/client/formFactor';
import chartJS from '@salesforce/resourceUrl/DMT_ChartJS';
import renderProfitabilityHtml from '@salesforce/apex/DMT_Profitability_utils.renderProfitabilityHtml';
import preparePdfAssets from '@salesforce/apex/DMT_PdfService.preparePdfAssets';
import generateFinalPdf from '@salesforce/apex/DMT_PdfService.generateFinalPdf';
import generateFinalPdfMob from '@salesforce/apex/DMT_PdfService.generateFinalPdfMob';

const RWA_MARKER_SELECTOR = '[data-dmt-action="external-rwa"]';
const RWA_MARKER_PATTERN = /<div data-dmt-action="external-rwa"[^>]*><\/div>/g;
const CHART_IMAGE_WIDTH = 1400;
const CHART_IMAGE_HEIGHT = 480;
const CONTENT_CLASS = 'dmt-profitability-view-content';
// Screen-only sizing so the renderer output looks like the former modal; never sent to the PDF.
const SCREEN_STYLE = `
    .${CONTENT_CLASS} > div > h2 { display: none; }
    .${CONTENT_CLASS} h3 { font-size: 1.125rem !important; font-weight: 400; margin: 1rem 0 0.5rem 0 !important; }
    .${CONTENT_CLASS} [data-dmt-table-block] { overflow-x: auto; margin-bottom: 0.5rem; }
    .${CONTENT_CLASS} [data-dmt-table-block] table { table-layout: auto !important; width: auto !important; min-width: 100%; }
    .${CONTENT_CLASS} [data-dmt-table-block] td { font-size: 0.8125rem !important; padding: 0.4rem 0.6rem !important; white-space: nowrap; word-break: normal !important; }
    .${CONTENT_CLASS} [data-dmt-table-block] td:first-child { max-width: 14rem; overflow: hidden; text-overflow: ellipsis; }
    .${CONTENT_CLASS} [data-dmt-action="external-rwa"] { float: right; margin-top: 0.75rem; }
    .${CONTENT_CLASS} img[alt="profitability"] { width: 100% !important; height: auto !important; }
`;

export default class Dmt_profitability_view extends NavigationMixin(LightningElement) {
    @api opportunityId;
    @api profitability;

    isLoading = false;
    errorMessage;
    renderedHtml = '';
    fileName = 'Profitability.pdf';
    chartImages = '';
    _initialized = false;

    get hasResults() {
        return Array.isArray(this.profitability?.results) && this.profitability.results.length > 0;
    }

    get showNoData() {
        return !this.isLoading && !this.hasResults;
    }

    /** True when there is rendered profitability content that can be downloaded. */
    @api
    get canDownload() {
        return !this.isLoading && this.hasResults && !!this.renderedHtml;
    }

    renderedCallback() {
        if (this._initialized) {
            return;
        }
        this._initialized = true;
        if (this.hasResults) {
            this.loadView();
        } else {
            this.notifyStatus();
        }
    }

    async loadView() {
        this.setLoading(true);
        try {
            this.chartImages = await this.buildChartImages();
            await this.renderView(false);
        } finally {
            this.setLoading(false);
        }
    }

    // Chart image from the same Chart.js chart the former modal showed; blank lets the renderer use its server chart.
    async buildChartImages() {
        try {
            await loadScript(this, chartJS);
            const chart = this.template.querySelector('c-dmt_profitability_chart');
            const image = chart ? await chart.getChartImage(CHART_IMAGE_WIDTH, CHART_IMAGE_HEIGHT) : null;
            return image ? JSON.stringify([{ imgB64: image }]) : '';
        } catch (error) {
            console.error('[dmt_profitability_view] chart image error', error);
            return '';
        }
    }

    async renderView(withExternalRwa) {
        try {
            const result = await renderProfitabilityHtml({
                oppId: this.opportunityId,
                itemsImg: this.chartImages,
                withExternalRwa
            });
            this.errorMessage = result?.message || null;
            if (result?.html) {
                this.renderedHtml = result.html;
                this.fileName = result.fileName || this.fileName;
                this.paint();
            }
        } catch (error) {
            console.error('[dmt_profitability_view] render error', error);
            this.errorMessage = 'Unable to load the profitability view.';
        }
    }

    paint() {
        const container = this.template.querySelector('.profitability-html');
        if (!container) {
            return;
        }
        // eslint-disable-next-line @lwc/lwc/no-inner-html
        container.innerHTML = `<style>${SCREEN_STYLE}</style><div class="${CONTENT_CLASS}">${this.renderedHtml}</div>`;
        this.insertExternalRwaButton(container);
    }

    insertExternalRwaButton(container) {
        const marker = container.querySelector(RWA_MARKER_SELECTOR);
        if (!marker) {
            return;
        }
        const button = document.createElement('button');
        button.className = 'slds-button slds-button_brand';
        button.textContent = 'External RWA calculate';
        button.disabled = marker.dataset.enabled !== 'true';
        button.addEventListener('click', () => this.handleExternalRwa());
        marker.appendChild(button);
    }

    async handleExternalRwa() {
        this.setLoading(true);
        try {
            await this.renderView(true);
        } finally {
            this.setLoading(false);
        }
    }

    /**
     * Downloads the PDF of the content on screen (with the External RWA column only if it was requested),
     * without the button marker. Generated on demand with DMT_PdfService; nothing is recalculated.
     */
    @api
    async downloadPdf() {
        const html = this.renderedHtml.replace(RWA_MARKER_PATTERN, '');
        const isMobile = FORM_FACTOR === 'Small' || FORM_FACTOR === 'Medium';
        const prep = await preparePdfAssets({ originalHtml: html });
        if (isMobile) {
            const contentDocumentId = await generateFinalPdfMob({
                finalHtml: prep.modifiedHtml,
                docIds: prep.documentIds || [],
                isMobile: true
            });
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: { url: `/sfc/servlet.shepherd/document/download/${contentDocumentId}` }
            });
            return;
        }
        const pdfBase64 = await generateFinalPdf({
            finalHtml: prep.modifiedHtml,
            docIds: prep.documentIds || []
        });
        const byteChars = atob(pdfBase64);
        const byteArray = new Uint8Array(byteChars.length);
        for (let i = 0; i < byteChars.length; i++) {
            byteArray[i] = byteChars.charCodeAt(i);
        }
        const blobUrl = URL.createObjectURL(new Blob([byteArray], { type: 'application/pdf' }));
        const link = document.createElement('a');
        link.href = blobUrl;
        link.download = this.fileName;
        document.body.appendChild(link);
        link.click();
        link.remove();
        URL.revokeObjectURL(blobUrl);
    }

    setLoading(value) {
        this.isLoading = value;
        const rwaButton = this.template.querySelector(`${RWA_MARKER_SELECTOR} button`);
        if (rwaButton && value) {
            rwaButton.disabled = true;
        }
        this.notifyStatus();
    }

    notifyStatus() {
        this.dispatchEvent(new CustomEvent('statuschange', {
            detail: { isLoading: this.isLoading, canDownload: this.canDownload }
        }));
    }
}
