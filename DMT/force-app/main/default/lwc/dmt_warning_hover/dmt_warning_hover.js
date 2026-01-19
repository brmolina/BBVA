import { LightningElement,api } from 'lwc';

export default class Dmt_warning_hover extends LightningElement {

    @api title;
    @api object;
    @api content;
    @api isEquals;
    @api compareFields;
    @api ignoreValueText;


    get showWarning() {
      
        var isShowWarning;

        if(this.compareFields == true || this.compareFields == 'true' ){
            var equalsOk;
            var contentOk;
            if (typeof this.isEquals ==  'string') {
                equalsOk = !this.isEquals.startsWith("{") ? true : false;
            }else{
                equalsOk = true;
            }

            if (typeof this.content ==  'string') {
                contentOk = !this.content.startsWith("{") ? true : false;
            }else{
                contentOk = true;
            }

            if ((this.isEquals!==null && this.isEquals!=='null' && this.isEquals!=='NULL' && equalsOk  && this.content!==null && this.content!=='null' && contentOk) && (this.isEquals !== this.content) ) {

                isShowWarning =  true ;

            }else {

                isShowWarning = false;

            } 

            return isShowWarning;
        }else{

            if (typeof this.isEquals ==  'string') {

                isShowWarning = this.isEquals == 'true' ? true : false;

            }else {

                isShowWarning = this.isEquals;

            } 
            return !isShowWarning;

        }

    }

    get hasTitle() {
        return this.title ? true : false;
    }

    get contentFull() {
        if(this.ignoreValueText == true || this.ignoreValueText == 'true' ) {
            return this.object;
        } else {
            return this.object + ' value: ' + this.content;
        }
        
    }

}