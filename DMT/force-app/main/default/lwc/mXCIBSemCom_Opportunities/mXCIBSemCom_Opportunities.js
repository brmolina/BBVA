import { LightningElement, api, track } from 'lwc';
import getTier from '@salesforce/apex/OppsCommercialActivityController.getTier';
import getOppInfo from '@salesforce/apex/OppsCommercialActivityController.getOppInfo';

export default class mXCIBSemCom_Opportunities extends LightningElement {
    @api recordId;
    @track tier = '-';
    @track totalOpp = 0;

    connectedCallback() {
        this.loadData();
    }

    async loadData() {
        try {
            const [tierRes, oppInfoRes] = await Promise.all([
                getTier({ accId: this.recordId }),
                getOppInfo({ accId: this.recordId, country: 'Todos' })
            ]);

            this.tier = tierRes || 'N/A';

            if (oppInfoRes) {
                const data = JSON.parse(oppInfoRes);
                if (data && data.length > 0) {
                    this.totalOpp = data[0].returnTotalOpp || 0;
                }
            }
        } catch (error) {
            console.error('Error al cargar métricas de Oportunidades:', error);
        }
    }
}