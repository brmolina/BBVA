import { LightningElement } from 'lwc';
import RemoveWindowScroll from '@salesforce/resourceUrl/DMT_RemoveScrollWindow';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';

export default class Dmt_removeWindowScroll extends LightningElement {
connectedCallback() {
        loadStyle(this, RemoveWindowScroll);
    }

}