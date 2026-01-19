import { LightningElement,api, track } from 'lwc';
import convertProductList from '@salesforce/apex/DMT_CurrencyConversionService.convertProductList';


export default class Dmt_productstiletemplate extends LightningElement {
    
    _isOpportunityObject = false;
    
    @track _productList;
    @track riskSelected;

    @api
    get productList() {
        return this._productList;
    }

    set productList(value) {
        if (!value) {
            this._productList = [];
            return;
        }

        if (!Array.isArray(value)) {
            value = [value];
        }

        if (value.length === 0) {
            this._productList = [];
            return;
        }

        this._productList = value;
    }


    @api
    get  riskId() {
      return this.riskSelected;
    }
  
    set riskId(value) {
        this.riskSelected = value;
    }

    @api
    get  isOpportunityObject() {
      return this._isOpportunityObject;
    }
  
    set isOpportunityObject(value) {
        this._isOpportunityObject = value;
    }

    


    handleSelected(event){
        let selected = this.template.querySelector('.isSelected');
        if (selected && selected != null) {
           selected.classList.remove('isSelected');
        }
        // if(this.template.querySelector(`[data-id="${event.target.getAttribute("data-id")}"]`) != null){
        //     this.template.querySelector(`[data-id="${event.target.getAttribute("data-id")}"]`).classList.remove('isSelected');
        // }
        this.template.querySelector(`[data-id="${event.target.getAttribute("data-id")}"]`).classList.add('isSelected');
        const idSelected = event.target.getAttribute("data-id");
        var nameSelected = this.productList.filter((product) => product.Id == idSelected)[0].name;
        if(this.isOpportunityObject){
            nameSelected = this.productList.filter((product) => product.Id == idSelected)[0].nameProduct;
        }
        var evt = new CustomEvent('riskSelected', {
            bubbles: true,
            composed: true,
            cancelable: true,
            detail: {Id: idSelected, Name: nameSelected}
        });
        this.dispatchEvent(evt);
    }

    handleAddProducts(){
        var evt = new CustomEvent('addproductmodal', {
            bubbles: true,
            composed: true,
            cancelable: true
        });
        this.dispatchEvent(evt);
    }
    
}