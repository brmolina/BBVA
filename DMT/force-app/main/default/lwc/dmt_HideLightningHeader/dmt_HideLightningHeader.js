import { LightningElement } from 'lwc';
import HideLightningHeader from '@salesforce/resourceUrl/DMT_HideLightningHeader';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';

export default class Dmt_HideLightningHeader extends LightningElement {
    connectedCallback() {
        loadStyle(this, HideLightningHeader);
        
    }
}