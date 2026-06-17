import { api, LightningElement } from 'lwc';
import dmt_no_access_title from '@salesforce/label/c.dmt_no_access_title';
import dmt_no_access_subtitle from '@salesforce/label/c.dmt_no_access_subtitle';

export default class Dmt_no_access_message extends LightningElement {
    @api title = dmt_no_access_title;
    @api subtitle = dmt_no_access_subtitle;
    @api iconName = 'utility:error';
}