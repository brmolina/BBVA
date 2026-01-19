import { api, LightningElement } from 'lwc';

export default class Dmt_no_access_message extends LightningElement {

    @api title = 'You do not have permission to perform this action';
    @api subtitle = 'Please contact your Salesforce administrator.';
    @api iconName = 'utility:error';
}