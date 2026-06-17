import { LightningElement, api } from 'lwc';

export default class PreviewPdf extends LightningElement {

    @api pdfData;
    @api fileName = 'document.pdf'; 

    // Añadimos el segundo parámetro aquí
    @api
    preview(pdfData, nombreArchivo) {
        this.pdfData = pdfData; 
        
        // Si el padre nos envió un nombre, lo guardamos
        if (nombreArchivo) {
            this.fileName = nombreArchivo;
        }
        
        const payload = {
            base64: this.pdfData,
            fileName: this.fileName
        };
        this.template.querySelector('iframe').contentWindow.postMessage(payload, window.location.origin);
    }

    reload() {
        if (this.pdfData) {
            const payload = {
                base64: this.pdfData,
                fileName: this.fileName
            };
            this.template.querySelector('iframe').contentWindow.postMessage(payload, window.location.origin);
        }
    }
}