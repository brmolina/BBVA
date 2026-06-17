import { api } from 'lwc';
import LightningModal from 'lightning/modal';

export default class Onb_assignRiskLinesModal extends LightningModal {
    @api header;
    @api recordOnboardingId;
    @api fundId;

    async handleClose() {
        const riskLinesCmp = this.template.querySelector('c-onb_risk-lines');

        if (riskLinesCmp && typeof riskLinesCmp.validateLines === 'function') {
            const isValid = await riskLinesCmp.validateLines();
            if (!isValid) {
                return;
            }
        }

        this.close({ saved: true });
    }
}