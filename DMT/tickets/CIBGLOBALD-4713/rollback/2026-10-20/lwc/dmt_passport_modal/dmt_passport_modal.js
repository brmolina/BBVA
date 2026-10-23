import { api } from 'lwc';
import LightningModal from 'lightning/modal';

export default class Dmt_passport_modal extends LightningModal  {
    @api noShowInfo;
    @api graphicModal;
    @api limits;
    @api featureName;
    @api featureLight;
    @api validations;
    @api errorModal;
    @api showProfitabilityChart;
    @api profitability;
    @api opportunityId;
    @api noShowInfoMessage;
    @api showConditionDesc = false;
    @api associatedLineUrl;
    @api associatedLineLabel;
    @api currencyId;

    handleOkay() {
        this.close('okay');
    }

    get featureNameTitle() {
        return this.featureName ? this.featureName : 'Capability';
    }

    get hasAssociatedLine() {
        return !!(this.associatedLineUrl && this.associatedLineLabel);
    }
}