import { LightningElement,api, track } from 'lwc';
import getFeaturesForJsonPdf from '@salesforce/apex/DMT_ViewController.getFeaturesForJsonPdf';
import getJHTMLFromCase from '@salesforce/apex/DMT_ViewController.generateContentDocumentForView';

export default class dmt_CreateHTMLAndJSONForTask extends LightningElement {
    isLoaded = false;
    lineId;
    limits
    currencyIsCode
    imageB64
    allLimits = [];
    allLimit;
    allParams;
    dataLimit;
    allImageB64;
    image64All = [];
    _caseId;
    _taskId;
    isOpp = false;
    @api 
    set caseId(value) {
        this._caseId = value;
        if(this._prodId){
            this.getFeaturCase();
        }
    }
    get caseId() {return this._caseId;}

    @api 
    set taskId(value) {
        this. _taskId = value;
        if(this._caseId){this.getFeaturCase();}
    }
    get taskId() {return this._taskId;}

renderedCallback(){
        if(this.isLoaded) return;
          const STYLE = document.createElement("style");
          STYLE.innerHTML = `.slds-popover {
            position: absolute;
            border-radius: 0px;
            width: var(--lwc-sizeMedium, 0rem);
            min-height: 0rem;
            z-index: auto;
            background-color: unset;
            display: inline-block;
            box-shadow: unset;
            border: unset;
            visibility: hidden;
          
          }`;
        this.template.querySelector("lightning-card").appendChild(STYLE);
        this.isLoaded = true;
      }
    connectedCallback() {}

    async getFeaturCase(){
        try{
            const response = await getFeaturesForJsonPdf({ lineId: this.lineId, caseId: this.caseId})
            this.dataLimit = JSON.parse(response).features;
            this.currencyIsCode = JSON.parse(response).currencyCode;
            const features = this.dataLimit || [];
            const profitabilityFeature = features.find(f => (f?.name || '').includes('Profitability') && f?.profitability);
            if (profitabilityFeature) {
                this.isOpp = true;
                this.profitability = profitabilityFeature.profitability;
            }
            // Genera los wraperData para enviar al chartJS para generar el ImagBase64 
            for(const key in this.dataLimit ) {
                if(this.dataLimit[key].consumptionLimits !== undefined){
                    let conditions = [];
                    let currencies = [];
                    let labels = [];
                    let limitLights = [];
                    let targets = [];
                    let dataDraw = [];
                    let dataUndrawnCommitted = [];
                    let dataUndrawnUncommitted = [];
                    let dataPendingAuthorized = [];
                    let dataNewOpportunity = [];
                    this.dataLimit [key].consumptionLimits.forEach(cl => {
                        if(cl.stateName !== undefined){
                            conditions.push(cl.conditionDesc);
                            currencies.push(cl.currencyId);
                            labels.push(cl.limitDesc);
                            limitLights.push(cl.stateName?.toUpperCase());
                            targets.push(parseFloat(cl.amount?.currentApprovedAmount));
                            dataDraw.push(parseFloat(cl.amount?.cmtContDisposedAmount) + parseFloat(cl.amount?.uncmtContDisposedAmount));
                            dataUndrawnCommitted.push(parseFloat(cl.amount?.cmtContNonDspsAmount));
                            dataUndrawnUncommitted.push(parseFloat(cl.amount?.uncmtContNonDspsAmount));
                            dataPendingAuthorized.push(parseFloat(cl.amount?.authorizedRiskAmount));
                            dataNewOpportunity.push(parseFloat(cl.amount?.notSignedTrConsumptionAmount));  
                        }
                    });
                    
                    let sections = ["Drawn", "Undrawn committed", "Undrawn uncommitted", "Pending authorized", "New Opportunity"];
                    let datasets = [
                        {"backgroundColor": "rgba(4, 50, 99, 1)", "data": dataDraw, "hoverBackgroundColor": "rgba(4, 50, 99, 1)","label": "Drawn"},
                        {"backgroundColor": "rgba(20, 100, 165, 1)", "data": dataUndrawnCommitted, "hoverBackgroundColor": "rgba(20, 100, 165, 1)","label": "Undrawn committed"},
                        {"backgroundColor": "rgba(36, 150, 234, 1)", "data": dataUndrawnUncommitted, "hoverBackgroundColor": "rgba(36, 150, 234, 1)","label": "Undrawn uncommitted"},
                        {"backgroundColor": "rgba(45, 204, 205, 1)", "data": dataPendingAuthorized, "hoverBackgroundColor": "rgba(45, 204, 205, 1)","label": "Pending authorized"},
                        {"backgroundColor": "rgba(189, 189, 189, 1)", "data": dataNewOpportunity, "hoverBackgroundColor": "rgba(189, 189, 189, 1)","label": "New Opportunity"}
                        ]; 
                        this.limits = {conditions: conditions, currencies: currencies, datasets: datasets, labels: labels, limitLights: limitLights, originCurrency: this.currencyIsCode, sections: sections, targetColor: 'red', targets: targets};
                        // this.allLimit ={wrapperData: this.limits,format: 'JPEG', quality: 0.7, };
                        this.allLimit ={format: 'JPEG', quality: 0.7, wrapperData: this.limits};
                        this.allParams ={params: this.allLimit}
                        this.allLimits.push(this.allLimit);
                        this.limits= '';     
                } 
            }
            if(this.isOpp) {
                await this.getImageB64(this.profitability);
            } else {
                await this.getImageB64(this.allLimits);
            }
        }catch(e) {
            console.log(JSON.stringify(e));
        }
    }
    async getImageB64(limit){ 
        try{
            if(this.isOpp) {
                // Profitability chart image
                const imageGenerator = this.template.querySelector('c-dmt_profitability_chart');
                imageGenerator.profitability = limit;
                const result = await imageGenerator.getChartImage(300, 100);
                this.allImageB64={imgB64: result};
                this.image64All.push(this.allImageB64);
                this.createHTML();
            } else {
                const imageGenerator = this.template.querySelector('c-dmt_subfeature_chart'); 
                const promises =limit.map((async  (item)=>{
                    const result = await imageGenerator.getChartImage(200, 100, JSON.parse(JSON.stringify(item)));
                    return {item,result};
                })); 
                const resolved = await Promise.all(promises);
                resolved.forEach(({result})=>{
                    this.allImageB64={imgB64: result};
                    this.image64All.push(this.allImageB64);
                });
                this.createHTML();
            }
        }catch(e) {
            console.log(JSON.stringify(e));
        }             
    }
    async createHTML(){       
        try { 
            const itemsImg = JSON.stringify(this.image64All); 
            const response = await getJHTMLFromCase({ caseId: this.caseId, taskId: this.taskId, documentType:'HTML', itemsB64: itemsImg})  
             
        } catch (error) {
            console.error('Error in getViewJSON:', JSON.stringify(error));              
        }
    
    }
}