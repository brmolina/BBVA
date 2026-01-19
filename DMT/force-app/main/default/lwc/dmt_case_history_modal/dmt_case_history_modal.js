import { LightningElement, api,track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getb64Pdf from '@salesforce/apex/DMT_Case_Steps_Controller.getBase64PdfData';
import getCaseDescription from '@salesforce/apex/DMT_Case_Steps_Controller.getCaseDescription';
import generatePDFContentDocument from '@salesforce/apex/DMT_ViewController.generateContentDocumentForView'; 
import fileTypeDocument from '@salesforce/apex/DMT_ViewController.fileTypeDocument';

export default class Dmt_case_history_modal extends NavigationMixin(LightningElement) {
    @api closecallback;
    @api record;
    @track downloadInProgress = false;
    recordData;
    hasFeatureName = false;
    pdfUrl;
    objectURL;
    @track pdfData = '';
    htmlPage;
    showSpinner = false;
    showErrorPdf = false;
    isDowloadpdf = false;
    showDowloadpdf = false;
    showPdf = false;
    isLoading = true;
    showHTML = false;
    caseDescription;
    doreload = false;
    isDownload = false;

    connectedCallback() {
        
        if(this.record.featureName !== undefined && this.record.featureName !== null ){
            this.hasFeatureName=true;
        }
        this.getTypeFile();
    }

    async initialize() {
        try {
            this.showHTML = false; 
            this.showPdf = true;
            let result = await this.loadPDF();
            const previewComponent = this.template.querySelector("c-preview-pdf");
        
            if (previewComponent) {
                    previewComponent.preview(result);
            }
    
        } catch (error) {
            console.error('Error al cargar el PDF:', error);
            this.showPdf = false;
            this.showErrorPdf = true;
            this.isLoading=false;
        }
    }

    @wire(getCaseDescription, { recordId: "$record.taskId" })
      wiredDescription(result) {
        
        if (result.error) 
        {
          
        }
        else if (result.data) {
          this.caseDescription = result.data;
        }
      }

    closeModal() {
        if (this.closecallback) {
            this.closecallback();
        }
    }

    loadPDF() {
        let type = 'PDF';
        return new Promise ((resolve, reject) => {
            getb64Pdf({ recordId : this.record.taskId, type: type}).then(result => {
                this.pdfData = result;
                this.showPdf = true;
                this.showHTML = false; 
                this.isLoading=false;
                resolve(result);
            }).catch(error => {
                reject(error);
                this.isLoading=false;
                this.showHTML = false; 
                this.showErrorPdf = true;
            });
        });
    }

    async getTypeFile(){

        const response = await fileTypeDocument({ taskId: this.record.taskId})
        if(response === 'HTML'){
            this.handleViewHTML()
        }else if(response === 'PDF' ){
            this.initialize();
             this.showHTML = false;   
        }else if(response === 'JSON' ){
            setTimeout(()=> this.getJSONFromTask(),800);
        }else if(response === null || response === undefined || response === ''){
            this.isLoading =false;
            this.showPdf = false;
            this.showHTML = false; 
            this.showErrorPdf = true;
            
        }
    }
   async getJSONFromTask(){
        try{
            let type = 'JSON'
            const response = await getb64Pdf({ recordId: this.record.taskId, type: type })
            const parsedResponse = JSON.parse(response);
            await this.generatePdfForTask(parsedResponse );
        } catch (error) {
            console.error('Error in getJSONFromTask:'+ error);
        }

    }
    async generatePdfForTask(parsedResponse) {
        try {
            let url = '';
            const pdfGenerator = this.template.querySelector('c-pdf-generator');
            pdfGenerator.jsonData = parsedResponse;
            pdfGenerator.output = 'blob';
            const pdfBlob = await pdfGenerator.generatePDF();
            console.log('VIEW PDF STRING:', pdfBlob);
            if(this.isDownload){
                if (pdfBlob) {
                    const blobUrl= URL.createObjectURL( pdfBlob);  
                    url = blobUrl;
                    const a = document.createElement('a');
                    a.href = url;
                    a.download = 'DMT_ViewPDF.pdf';
                    document.body.appendChild(a);
                    a.click();
                    document.body.removeChild(a);
                    window.open(url, '_blank'); 
                    URL.revokeObjectURL(url);   
                    
                }
            }
            await this.saveBase64Pdf(pdfBlob);
            
            return pdfBlob;
        } catch (error) {
            console.error('Error in generatePdfForTask:', error);
            throw new Error('Failed to generate PDF.');
        }finally{
            this.isDowloadpdf = false;
            this.isDownload = false;
            this.downloadInProgress = false;
            
        }
    }
    async saveBase64Pdf(pdfBlob) {
        try {
            if(pdfBlob){
                console.log('Case:', this.record.caseId);
                const dataBase64 = await this.convertBlobToBase64(pdfBlob);
                const pdfLoadB64 = dataBase64;
                const response = await generatePDFContentDocument({caseId: '', taskId: this.record.taskId, documentType: 'PDF', itemsB64: pdfLoadB64});
                //this.doreload = true;
                console.log('Response Save:', response);
            }
            if(!this.isDowloadpdf){this.initialize();}

        } catch (error) {
            console.error('Error in saveBase64Pdf:', JSON.stringify(error));
        }
    }
    
    convertBlobToBase64(blob) {
        return new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onloadend = () =>{
                const base64 = reader.result.split(',')[1];

                resolve(base64);
            };
            reader.onerror = reject;
            reader.readAsDataURL(blob);
        });
    }

    async handleViewHTML() {
            const type = 'HTML';
            this.showPdf = false;
            this.isLoading = true;
            this.showHTML = true;
            const response = await getb64Pdf({ recordId: this.record.taskId, type: type }) 
            console.log('response DMT_ViewHTML:', response);
            if(response != null){  
                this.htmlPage = `<div class="htmlInterno"> ${response}</div> `;   
            }
            this.loadIframe();
    }
    loadIframe(){  
        const contentHtml = this.template.querySelector('.contentHtml');
        if(contentHtml){
            console.log('this.htmlPage: 3', this.htmlPage);
            
            const styleTableView = `
            <style>
            .style-table td{
                white-space: normal !important;
            }
            .style-table th{
                background-color: transparent;
            }
            .style-table tr:hover td{
                background-color: transparent !important;
                cursor: default !important;
                box-shadow: none !important;
            }
            .style-table td:hover{
                background-color: transparent !important;
                cursor: default !important;
                box-shadow: none !important;
            }
            </style>`;	
            //Se añade Stilo a la ventana modal
            contentHtml.innerHTML = styleTableView + this.htmlPage ;
            contentHtml.style.width = '100%';
            contentHtml.style.maxHeight = '73vh';
            contentHtml.style.overflowY = 'auto';
            contentHtml.style.padding ='1.7rem';
            contentHtml.style.boxSizing = 'border-box';
            contentHtml.style.backgroundColor = '#ffffff';
        }
        this.isLoading = false;
        this.showHTML = true;
        this.showDowloadpdf = true;

    }
    get downloadLabel() {
        return this.downloadInProgress ? 'Downloading PDF...' : 'Download PDF';
    }
    get isDownloadInProgress() {
        return this.isLoading || this.downloadInProgress;
    }
        // Descargar el PDF
        handleDownloadPDF() {
            this.isDownload = true;
            this.isDowloadpdf = true;
            this.downloadInProgress = true;
            setTimeout(() => this.getJSONFromTask(), 1400);
        }
}