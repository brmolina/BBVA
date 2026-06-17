import { LightningElement,api } from 'lwc';
import passportModal from 'c/dmt_passport_modal';

export default class Dmt_global_validation_feature extends LightningElement {
    
    _feature;
    _isbig;
    errorModal;
    
    @api
    get feature() {
        return this._feature;
    }
    set feature(value) {
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
        
        this.errorModal = true;
        
        if(this.errorModal){
            this.validations?.forEach(v => {
                if(v.state === 'RED'){
                    v.styleColor = 'color: #ea001e;';
                }
                else {
                    v.styleColor = '';
                }
            });
        }
        
        passportModal.open({
            noShowInfo: false,
            graphicModal: false,
            limits: null,
            featureName: this.feature?.name,
            featureLight: this.feature?.stateName?.toLowerCase(),
            validations:this.feature?.validations,
            errorModal: this.errorModal,
            profitability: null,
            showProfitabilityChart: false
        }).then((result) => {
            this.graphicModal = false;
            this.errorModal = false;
            this.errorMessages = [];
        });
    }
}