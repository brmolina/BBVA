import { LightningElement, api,wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from "lightning/navigation";

export default class DMT_navigatePageLine extends NavigationMixin(LightningElement){   

isLoaded = false;
@api
get  line() {
  return this.linevalue;
}
set line(value) {
  this.linevalue = value;
    this.handlerNavigate();

}  
renderedCallback(){
  if(this.isLoaded) return;
    const STYLE = document.createElement("style");
    STYLE.innerHTML = `.slds-popover {
      position: absolute;
      border-radius: 0px;
      width: var(--lwc-sizeMedium, 0rem);
      min-height: 0rem;
      z-index: auto;
      background-color: unset;
      display: inline-block;
      box-shadow: unset;
      border: unset;
      visibility: hidden;
    }`;
  this.template.querySelector("lightning-card").appendChild(STYLE);
  this.isLoaded = true;
}
  connectedCallback() {}
  handlerNavigate(){

    let idLine = this.linevalue;
    let urlMixin = {
        type: 'standard__recordPage',
        attributes: {
            recordId: idLine,
            objectApiName: 'DMT_Line__c',
            actionName: 'view'
        }};
        setTimeout(()=>{
          this.dispatchEvent(new CustomEvent('closemodal',  { bubbles:true, composed:true} ));
          this[NavigationMixin.GenerateUrl](urlMixin).then(url => {
            const link = document.createElement('a');
            link.href = url;
            link.target = '_blank';
            link.rel = 'noopener noreferrer';
            link.style.visibility = 'hidden';
            document.body.appendChild(link);
            link.click();
            link.remove();
          });
        },15);

  }
}