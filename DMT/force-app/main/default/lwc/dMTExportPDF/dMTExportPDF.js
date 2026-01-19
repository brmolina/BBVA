import { LightningElement, api} from 'lwc';

export default class DMTExportPDF extends LightningElement {
    @api recordId = 'a5jKN000000CiVXYA0';

    openPdf() {
        const baseUrl = window.location.origin;
        const vfPageUrl = `/apex/ApproverViewPDF?id=${this.recordId}`;
        window.open(baseUrl + vfPageUrl, '_blank');
    }

    downloadPdf() {
        const baseUrl = window.location.origin;
        const vfPageUrl = `/apex/ApproverViewPDF?id=${this.recordId}`;
        const a = document.createElement('a');
        a.href = baseUrl + vfPageUrl;
        a.download = 'ApproverView.pdf';
        a.target = '_blank';
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
    }
}