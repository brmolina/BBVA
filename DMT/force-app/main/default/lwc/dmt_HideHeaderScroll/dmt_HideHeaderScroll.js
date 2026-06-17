import { LightningElement } from 'lwc';
import HideLightningHeader from '@salesforce/resourceUrl/DMT_HideLightningHeader';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';

export default class dmt_HideHeaderScroll extends LightningElement {
    connectedCallback() {
        loadStyle(this, HideLightningHeader);
        // Encuentra el contenedor principal donde vive este LWC
        const hostContainer = this.template.host.closest('.oneContent.active.lafPageHost');

        if (hostContainer) {
            const target = hostContainer.querySelector('.lwcAppFlexipage');
            if (target) {
                target.classList.add('myNoOuterScroll');
            }
        }
    }
}