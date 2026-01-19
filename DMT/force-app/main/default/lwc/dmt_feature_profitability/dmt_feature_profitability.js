import { LightningElement,api } from 'lwc';
import passportModal from 'c/dmt_passport_modal';

export default class Dmt_feature_profitability extends LightningElement {

    _feature;
    _isbig;
    errorModal;

    
    @api
    get feature() {
        return this._feature;
    }
    set feature(value) {
        
        console.log('Dmt_feature_profitability set feature feature ' +  JSON.stringify(value,2));
        console.log('Dmt_feature_profitability set feature name ' + value.name);
        console.log('Dmt_feature_profitability set feature stateName ' + value.stateName);
        this._feature = value;
        
    }
    
    @api 
    get isbig() {
        return this._isbig;
    }
    set isbig(value) {
        this._isbig = value;
    }
    
    openModal(event){
           
        let noShowInfo = false;
        
        passportModal.open({
            noShowInfo: noShowInfo,
            graphicModal: true,
            limits: null,
            featureName: null,
            featureLight: null,
            validations: null,
            errorModal: false,
            profitability: this.feature?.profitability,
            showProfitabilityChart: true
        }).then((result) => {
            this.graphicModal = false;
            this.errorModal = false;
            this.errorMessages = [];
        });
    }   
}