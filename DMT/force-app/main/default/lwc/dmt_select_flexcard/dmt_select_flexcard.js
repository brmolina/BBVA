import { LightningElement,api } from 'lwc';
import { FlexCardMixin  } from 'omnistudio/flexCardMixin';

import pubsub from 'omnistudio/pubsub';

export default class Dmt_select_flexcard extends FlexCardMixin(LightningElement) {

    @api list;
    @api catalog;
    disabledValue;
    @api
    get  selectDisabled() {
      return this.disabledValue;
    }
  
    set selectDisabled(value) {console.log('value',value)
        if(value === 'false'){
        this.disabledValue = false;
        }else{
            this.disabledValue = value;
        }console.log('value2',this.disabledValue)
    }

    handleChangeValue(event) {

        console.log("this.catalog " + this.catalog);
        console.log("event.target.value " + event.target.value);

        pubsub.fire("select", "changeValues", {catalog: this.catalog, key: event.target.key, value: event.target.value })
    }
}