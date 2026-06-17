import { api, LightningElement } from 'lwc';

const DEFAULT_URL = '/lightning/o/Opportunity/list?filterName=__Recent';

export default class Dmt_navigateToPage extends LightningElement {
    @api pageUrl;
    @api useReplace;

    @api
    invoke() {
        const targetUrl = this.pageUrl && this.pageUrl.trim() ? this.pageUrl.trim() : DEFAULT_URL;
        const mustReplace = this.useReplace === true || this.useReplace === 'true';

        if (mustReplace) {
            window.location.replace(targetUrl);
            return;
        }

        window.open(targetUrl, '_self');
    }
}