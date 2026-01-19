import { LightningElement, api, wire, track } from 'lwc';
import getProductsByCategory from '@salesforce/apex/DMT_TaxonomyMultipleProducts.getProductsByCategory';
import saveLineTerm from '@salesforce/apex/DMT_TaxonomyMultipleProducts.saveCategoryOtherLine';

export default class ProductSelectorModal extends LightningElement {
    @api recordId;        // Line ID to save later
    @api categoryName;    // Filter
    optionsTerm = [{ label: 'Select Term', value: '' },{label:"0D",value:"0"},{label:"2D",value:"2"},{label:"3D",value:"3"},{label:"4D",value:"4"},{label:"7D",value:"7"},{label:"10D",value:"10"},{label:"15D",value:"15"},{label:"20D",value:"20"},{label:"1M",value:"30"},{label:"45D",value:"45"},{label:"2M",value:"60"},{label:"3M",value:"90"},{label:"4M",value:"120"},{label:"5M",value:"150"},{label:"6M",value:"180"},{label:"9M",value:"270"},{label:"1Y",value:"365"},{label:"18M",value:"548"},{label:"2Y",value:"730"},{label:"3Y",value:"1095"},{label:"4Y",value:"1460"},{label:"5Y",value:"1825"},{label:"6Y",value:"2190"},{label:"7Y",value:"2555"},{label:"8Y",value:"2920"},{label:"9Y",value:"3285"},{label:"10Y",value:"3650"},{label:"11Y",value:"4015"},{label:"12Y",value:"4380"},{label:"13Y",value:"4745"},{label:"14Y",value:"5110"},{label:"15Y",value:"5475"},{label:"16Y",value:"5840"},{label:"17Y",value:"6205"},{label:"18Y",value:"6570"},{label:"19Y",value:"6935"},{label:"20Y",value:"7300"},{label:"21Y",value:"7665"},{label:"22Y",value:"8030"},{label:"25Y",value:"9125"},{label:"27Y",value:"9855"},{label:"30Y",value:"10950"},{label:"32Y",value:"11680"},{label:"35Y",value:"12775"},{label:"37Y",value:"13505"},{label:"40Y",value:"14600"},{label:"42Y",value:"15330"},{label:"45Y",value:"16425"}];
    showSpinner = false;
    @track products = [];
    @track selectedProductId;
    @track selectedMaxTerm;
    @track error;
        @api
        get lineId() {
            return this.recordId;
        }
        set lineId(value) {
            this.recordId = value;
            if (value) {
                this.wiredProducts(this.recordId);
            }
        }

    @wire(getProductsByCategory, { recordId: '$recordId' })
    wiredProducts({ data, error }) {
        if (data) {
            this.products = data.map(prod => {
                return {
                    ...prod,
                    selected: false,
                    maxterm: ''
                };
            });
            this.error = undefined;
            console.log('data: ', JSON.stringify(data));
        } else if (error) {
            this.error = error;
            this.products = undefined;
            console.error(error);
        }
    }

    get disableSave() {
        return !this.selectedProductId;
    }

    handleSelect(event) {
        //this.selectedProductId = event.currentTarget.querySelector('input').value;
        this.selectedMaxTerm = '';console.log('event: ', event.target.dataset.id);
        console.log('this.selectedMaxTerm: ', this.selectedMaxTerm);
        // this.products.forEach(prod => {
        //     if( prod.selected) {
        //         this.selectedProductId = prod.Id;
        //     } else {
        //         this.selectedProductId = prod.Id;
        //     }
        // });
        this.selectedProductId  = event.target.dataset.id;
        this.updateTreeNode(this.products, event.target.dataset.id, 'selected',true);
        this.updateTreeNode(this.products, this.selectedProductId, 'maxterm', '');
        console.log('prod ', JSON.stringify(this.products));
                    
    }

    updateTreeNode(nodes, id, field, value) {
        for (let node of nodes) {
            if (node.Id === id) {
                node[field] = value;
            }
            else{
                node[field] = field == 'selected' ? false : '';
            }
        }
    }

    handleSave() {
        this.showSpinner = true;
        const selected = this.products.find(p => p.Id === this.selectedProductId);

        saveLineTerm({
            lineId: this.recordId,
            productId: selected.Id,
            productName: selected.Name,
            productCode: selected.ProductCode,
            maxTerm: this.selectedMaxTerm
        })
        .then(result => {
            this.dispatchEvent(new CustomEvent('reloadparent', { bubbles:true, composed:true}));
        })
        .catch(error => {
            console.error(error);
        });
    }

    handleCancel() {
        this.dispatchEvent(new CustomEvent('cancel'));
        this.dispatchEvent(new CustomEvent('closemodal', { bubbles:true, composed:true}));
    }

    handleSelectMaxTerm(event){

        this.selectedMaxTerm = event.detail.value;
        this.updateTreeNode(this.products, this.selectedProductId, 'maxterm', this.selectedMaxTerm);
    }
}