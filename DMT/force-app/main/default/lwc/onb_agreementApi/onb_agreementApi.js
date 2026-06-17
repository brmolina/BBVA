import { LightningElement, api } from 'lwc';
import syncAgreementsForAccount from '@salesforce/apex/ONB_AgreementsSyncController.syncAgreementsForAccount';

export default class Onb_agreementApi extends LightningElement {
    @api recordId;
    hasExecuted = false;

    renderedCallback() {
        if (this.hasExecuted) return;
        if (!this.recordId) return;

        this.hasExecuted = true;
        this.run();
    }

    async run() {
        try {
            const result = await syncAgreementsForAccount({ recordId: this.recordId });
        } catch (e) {
            const msg = e?.body?.message || e?.message || JSON.stringify(e);
            console.error('[onb_agreementApi] Sync failed:', msg, e);
        }
    }
}