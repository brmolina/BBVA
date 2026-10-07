import { LightningElement, api } from 'lwc';
import { NavigationMixin} from "lightning/navigation";

export default class dmt_navigateFromDmtToHpg extends NavigationMixin(LightningElement){
    @api groupOrigin

    handleOpenNavigation() {
        const pageReference = {
            type: 'standard__component',
            attributes: {
                // El nombre de tu componente en formato c__componentName
                componentName: 'hpgr__global_clients_exposure_cmp'
            },
            state: {
                
                c__customerId: this.groupOrigin
            }
        };

        // Genera la URL para la pageReference
        this[NavigationMixin.GenerateUrl](pageReference)
            .then(url => {
                const link = document.createElement('a');
                link.href = url;
                link.target = '_blank';
                link.rel = 'noopener noreferrer';
                link.style.visibility = 'hidden';
                document.body.appendChild(link);
                link.click();
                link.remove();
            });
    }
}