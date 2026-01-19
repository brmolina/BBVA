import { LightningElement,api } from 'lwc';
import passportModal from 'c/dmt_passport_modal';
import dmt_case_comment_modal_v2 from 'c/dmt_case_comment_modal_v2';
import startCase from '@salesforce/apex/DMT_Passport_Handler.startCase';

export default class Dmt_feature_limit extends LightningElement {
    
    _feature;
    _isbig;
    isExpanded = false;
    haveProducts = false;
    
    @api
    get feature() {
        return this._feature;
    }
    set feature(value) {
        
        console.log('Dmt_feature_limit set feature feature ' +  JSON.stringify(value,2));
        console.log('Dmt_feature_limit set feature name ' + value.name);
        console.log('Dmt_feature_limit set feature stateName ' + value.stateName);
        console.log('Dmt_feature_limit set feature value.products?.length > 0 ' + value.products?.length > 0);
        console.log('Dmt_feature_limit set feature value.products !== undefined ' + value.products != undefined);
        console.log('Dmt_feature_limit set feature feature.showTrafficLight ' + value.showTrafficLight);
        console.log('Dmt_feature_limit set feature record.tasks ' + JSON.stringify(value.tasks));
        console.log('Dmt_feature_limit set feature dmtCurrency ' + JSON.stringify(value?.dmtCurrency));
        
        this.haveProducts = value.products != undefined && value.products?.length > 0;
        
        console.log('Dmt_feature_limit set feature this.haveProducts ' + this.haveProducts);
        
        var temptValue = JSON.parse(JSON.stringify(value));
        temptValue.showTrafficLight = this.haveProducts ? !this.haveProducts : value.showTrafficLight;
        
        console.log('Dmt_feature_limit set feature temptValue ' +  JSON.stringify(temptValue,2));
        
        this._feature = temptValue;
    }
    
    @api 
    get isbig() {
        return this._isbig;
    }
    set isbig(value) {
        this._isbig = value;
    }
    
    openModal(event){

        const idEvent = event.target.dataset.id;

        console.log('Dmt_feature_limit openModal idEvent ' + JSON.stringify(idEvent));
        
        let conditions = [];
        let currencies = [];
        let labels = [];
        let limitLights = [];
        let sections = ["Drawn", "Undrawn committed", "Undrawn uncommitted", "Pending authorized", "New Opportunity"];
        let targets = [];
        
        let dataDraw = [];
        let dataUndrawnCommitted = [];
        let dataUndrawnUncommitted = [];
        let dataPendingAuthorized = [];
        let dataNewOpportunity = [];
        
        let noShowInfo = false;
        let consuptionsLimits = [];

        consuptionsLimits = this.searchCorrectConsuptionLimit(idEvent);

        console.log('Dmt_feature_limit openModal consuptionsLimits ' + JSON.stringify(consuptionsLimits));

        consuptionsLimits?.forEach(limits => {
            
            console.log('Dmt_feature_limit openModal limits ' + JSON.stringify(limits));
            console.log('Dmt_feature_limit openModal limits?.stateName ' + JSON.stringify(limits?.stateName));
            
            if(limits?.stateName !== undefined){
                conditions.push(limits.conditionDesc);
                currencies.push(limits.currencyId);
                labels.push(limits.limitDesc);
                limitLights.push(limits.stateName?.toUpperCase());
                targets.push(parseFloat(limits.amount?.currentApprovedAmount));
                dataDraw.push(parseFloat(limits.amount?.cmtContDisposedAmount) + parseFloat(limits.amount?.uncmtContDisposedAmount));
                dataUndrawnCommitted.push(parseFloat(limits.amount?.cmtContNonDspsAmount));
                dataUndrawnUncommitted.push(parseFloat(limits.amount?.uncmtContNonDspsAmount));
                dataPendingAuthorized.push(parseFloat(limits.amount?.authorizedRiskAmount));
                dataNewOpportunity.push(parseFloat(limits.amount?.notSignedTrConsumptionAmount));
            }
        });
        
        let datasets = [
            {"backgroundColor": "rgba(4, 50, 99, 1)", "data": dataDraw, "hoverBackgroundColor": "rgba(4, 50, 99, 1)","label": "Drawn"},
            {"backgroundColor": "rgba(20, 100, 165, 1)", "data": dataUndrawnCommitted, "hoverBackgroundColor": "rgba(20, 100, 165, 1)","label": "Undrawn committed"},
            {"backgroundColor": "rgba(36, 150, 234, 1)", "data": dataUndrawnUncommitted, "hoverBackgroundColor": "rgba(36, 150, 234, 1)","label": "Undrawn uncommitted"},
            {"backgroundColor": "rgba(45, 204, 205, 1)", "data": dataPendingAuthorized, "hoverBackgroundColor": "rgba(45, 204, 205, 1)","label": "Pending authorized"},
            {"backgroundColor": "rgba(189, 189, 189, 1)", "data": dataNewOpportunity, "hoverBackgroundColor": "rgba(189, 189, 189, 1)","label": "New Opportunity"}
        ];
        
        console.log('Dmt_feature_limit openModal this.feature?.dmtCurrency ' + JSON.stringify(this.feature?.dmtCurrency));
        
        let limits = {conditions: conditions, currencies: currencies, datasets: datasets, labels: labels, limitLights: limitLights, originCurrency: this.feature?.dmtCurrency, sections: sections, targetColor: 'red', targets: targets};
        
        console.log('Dmt_feature_limit openModal dataDraw.length ' + JSON.stringify(dataDraw.length));
        console.log('Dmt_feature_limit openModal consuptionsLimits ' + JSON.stringify(consuptionsLimits));
        console.log('Dmt_feature_limit openModal this.feature?.validations?.length ' + JSON.stringify(this.feature?.validations?.length));
        
        if(consuptionsLimits === undefined || dataDraw.length === 0) {
            noShowInfo = true;
        }
        
        console.log('Dmt_feature_limit openModal limits ' + JSON.stringify(limits));
        
        passportModal.open({
            noShowInfo: noShowInfo,
            graphicModal: true,
            limits: limits,
            featureName: this.feature?.name,
            featureLight: this.feature?.stateName?.toLowerCase(),
            validations:this.feature?.validations,
            errorModal: false,
            profitability: null,
            showProfitabilityChart: false
        }).then((result) => {
            this.graphicModal = false;
            this.errorMessages = [];
        });
    }

    searchCorrectConsuptionLimit(idEvent) {

        console.log('Dmt_feature_limit searchCorrectConsuptionLimit feature idEvent ' + idEvent);

        let consumptionLimits = [];

        if(this.feature.idProccess == idEvent) {

            console.log('Dmt_feature_limit searchCorrectConsuptionLimit feature modal');
            console.log('Dmt_feature_limit searchCorrectConsuptionLimit this.feature?.consumptionLimits '  + JSON.stringify(this.feature?.consumptionLimits));
            consumptionLimits = this.feature?.consumptionLimits;
        }
        
        this.feature.products?.forEach(product => {
            
            if(product.productId == idEvent) {
                console.log('Dmt_feature_limit searchCorrectConsuptionLimit product modal');
                console.log('Dmt_feature_limit searchCorrectConsuptionLimit product.consumptionLimits '  + JSON.stringify(product.consumptionLimits));
                consumptionLimits = product.consumptionLimits;
            }

            product.mitigants?.forEach(mitigant => {
                
                if(mitigant.mitigantId == idEvent) {
                    console.log('Dmt_feature_limit searchCorrectConsuptionLimit mitigant modal');
                    console.log('Dmt_feature_limit searchCorrectConsuptionLimit mitigant.consumptionLimits '  + JSON.stringify(mitigant.consumptionLimits));
                    consumptionLimits = mitigant.consumptionLimits;
                }
            });
        });

        return consumptionLimits;
    }
    
    expandedControlEvent(event) {
        this.isExpanded = !this.isExpanded;
    }
}