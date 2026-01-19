import { LightningElement, api } from 'lwc';

export default class PreviewPdf extends LightningElement {

    @api pdfData;

    @api
    preview(pdfData) {
        this.template.querySelector('iframe').contentWindow.postMessage(pdfData, window.location.origin);
    }

    reload() {
        this.template.querySelector('iframe').contentWindow.postMessage(this.pdfData, window.location.origin);
    }
}