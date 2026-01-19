import { LightningElement, api } from 'lwc';

export default class Hpg_fetcher extends LightningElement {
    @api
    fireFetchMoreEvent(params) {
        const fetchMoreEvent = new CustomEvent('fetchmore', {detail: params});
        this.dispatchEvent(fetchMoreEvent);
    }

}