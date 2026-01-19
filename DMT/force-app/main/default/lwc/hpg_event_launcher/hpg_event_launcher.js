// https://github.com/salesforce/lwc/issues/1666
// https://github.com/salesforce/lwc/issues/3235
import { api, LightningElement } from 'lwc';
export default class Hpg_event_launcher extends LightningElement {
	@api
	launchEvent(event) {
		this.dispatchEvent(event);
	}
}