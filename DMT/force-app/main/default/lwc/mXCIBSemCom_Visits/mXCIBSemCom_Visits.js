import { LightningElement, api, track } from 'lwc';
import getTier from '@salesforce/apex/VisitsCommercialActivityController.getTier';
import getVisitInfo from '@salesforce/apex/VisitsCommercialActivityController.getVisitInfo';

export default class MXCIBSemCom_Visits extends LightningElement {
    @api recordId;
    @track tier = '-';
    @track totalVisits = 0;

    connectedCallback() {
        this.loadData();
    }

    async loadData() {
        try {
            const [tierRes, visitRes] = await Promise.all([
                getTier({ accId: this.recordId }),
                getVisitInfo({ accId: this.recordId, country: 'Todos' })
            ]);

            this.tier = tierRes || 'N/A';

            if (visitRes) {
                const data = JSON.parse(visitRes);
                if (data && data.length > 0) {
                    this.totalVisits = data[0].returnTotalVisitsYTD || 0;
                }
            }
        } catch (error) {
            console.error('Error cargando métricas de visitas:', error);
        }
    }
}