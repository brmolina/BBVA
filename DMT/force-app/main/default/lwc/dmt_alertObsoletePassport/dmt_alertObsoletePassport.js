import { api, LightningElement } from 'lwc';
import ccsicon from '@salesforce/resourceUrl/DMT_Styles';
import { loadStyle } from 'lightning/platformResourceLoader';

export default class Dmt_alertObsoletePassport extends LightningElement {
@api message;
@api linkMessage;
@api idOpp;

renderedCallback() {
        Promise.all([
            loadStyle(this, ccsicon)
        ]);
      } 
get linkOpp() {
        return this.idOpp ? '/' + this.idOpp : '#';
    }
}