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
// Links (External RWA 1Y values to the RWA calculator) stay clickable in the modal and become plain text in the PDF.
const LINK_PATTERN = /<a\b[^>]*>([\s\S]*?)<\/a>/gi;
// Same aspect as the former modal chart (canvas 300 x 100).
const CHART_ASPECT_RATIO = 3;
const CHART_DEFAULT_WIDTH = 860;
const CONTENT_CLASS = 'dmt-profitability-view-content';
// Screen-only styles so the renderer output looks like the former modal (dmt_profitability_chart: slds-table
// cell-buffer bordered at 93% zoom, headers wrapped at 120px, 160px ID with ellipsis); never sent to the PDF.
const SCREEN_STYLE = `
    .${CONTENT_CLASS} > div > h2 { display: none; }
    .${CONTENT_CLASS} .slds-m-vertical_medium .slds-grid { font-size: 0.8125rem !important; }
    .${CONTENT_CLASS} .slds-m-vertical_medium .slds-col:nth-child(-n+2) { font-size: 1rem; line-height: 1.25; }
    .${CONTENT_CLASS} .slds-m-vertical_medium .slds-col { padding-bottom: 0.5rem; }
    .${CONTENT_CLASS} h3 { font-size: 1rem !important; font-weight: 400; line-height: 1.25; margin: 1rem 0 0.25rem 0 !important; }
    .${CONTENT_CLASS} [data-dmt-table-block] { overflow-x: auto; max-width: 100%; }
    .${CONTENT_CLASS} [data-dmt-table-block] table { table-layout: auto !important; width: auto !important; min-width: 98%; zoom: 93%; border-collapse: collapse; }
    .${CONTENT_CLASS} [data-dmt-table-block] td { font-size: 0.8125rem !important; line-height: 1.5; padding: 0.25rem 0.5rem !important; white-space: nowrap; word-break: normal !important; color: #181818; border-bottom: 0 !important; border-top: 1px solid #e5e5e5 !important; }
    .${CONTENT_CLASS} [data-dmt-table-block] tr:first-child td { white-space: normal; max-width: 120px; color: #444444; vertical-align: middle; }
    .${CONTENT_CLASS} [data-dmt-table-block] tr:last-child td { border-bottom: 1px solid #e5e5e5 !important; }
    .${CONTENT_CLASS} [data-dmt-table-block] td:first-child { padding-left: 1.5rem !important; }
    .${CONTENT_CLASS} [data-dmt-table-block] td:last-child { padding-right: 1.5rem !important; }
    .${CONTENT_CLASS} [data-dmt-table-block] tr[data-dmt-row] td:first-child { width: 160px; min-width: 160px; max-width: 160px; overflow: hidden; text-overflow: ellipsis; word-break: normal !important; box-sizing: content-box; }
    .${CONTENT_CLASS} [data-dmt-table-block] tr[data-dmt-row="underlying"] td:first-child { padding-left: 2.75rem !important; max-width: calc(160px - 1.25rem); min-width: calc(160px - 1.25rem); width: calc(160px - 1.25rem); }
    .${CONTENT_CLASS} [data-dmt-action="external-rwa"] { float: right; margin-top: 0.5rem; }
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
            // Drawn at the modal width so labels keep the size of the former live chart.
            const width = this.template.querySelector('.profitability-view')?.clientWidth || CHART_DEFAULT_WIDTH;
            const image = chart ? await chart.getChartImage(width, Math.round(width / CHART_ASPECT_RATIO)) : null;
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
     * without the button marker and with links as plain text. Generated on demand with DMT_PdfService;
     * nothing is recalculated.
     */
    @api
    async downloadPdf() {
        const html = this.renderedHtml.replace(RWA_MARKER_PATTERN, '').replace(LINK_PATTERN, '$1');
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
