import { LightningElement, api } from 'lwc';
//import {loadStyle } from 'lightning/platformResourceLoader';
//import comboboxContainer from '@salesforce/resourceUrl/comboboxContainer';

export default class ProductTreeNode extends LightningElement {
    @api product;
    @api level = 0;
    @api isSelected = false;
    @api zeroLevel = false;
    optionsTerm = [{ label: 'Select Term', value: '' },{label:"0D",value:"0"},{label:"2D",value:"2"},{label:"3D",value:"3"},{label:"4D",value:"4"},{label:"7D",value:"7"},{label:"10D",value:"10"},{label:"15D",value:"15"},{label:"20D",value:"20"},{label:"1M",value:"30"},{label:"45D",value:"45"},{label:"2M",value:"60"},{label:"3M",value:"90"},{label:"4M",value:"120"},{label:"5M",value:"150"},{label:"6M",value:"180"},{label:"9M",value:"270"},{label:"1Y",value:"365"},{label:"18M",value:"548"},{label:"2Y",value:"730"},{label:"3Y",value:"1095"},{label:"4Y",value:"1460"},{label:"5Y",value:"1825"},{label:"6Y",value:"2190"},{label:"7Y",value:"2555"},{label:"8Y",value:"2920"},{label:"9Y",value:"3285"},{label:"10Y",value:"3650"},{label:"11Y",value:"4015"},{label:"12Y",value:"4380"},{label:"13Y",value:"4745"},{label:"14Y",value:"5110"},{label:"15Y",value:"5475"},{label:"16Y",value:"5840"},{label:"17Y",value:"6205"},{label:"18Y",value:"6570"},{label:"19Y",value:"6935"},{label:"20Y",value:"7300"},{label:"21Y",value:"7665"},{label:"22Y",value:"8030"},{label:"25Y",value:"9125"},{label:"27Y",value:"9855"},{label:"30Y",value:"10950"},{label:"32Y",value:"11680"},{label:"35Y",value:"12775"},{label:"37Y",value:"13505"},{label:"40Y",value:"14600"},{label:"42Y",value:"15330"},{label:"45Y",value:"16425"}];

    get hasChildren() {
        return Array.isArray(this.product.children) && this.product.children.length > 0;
    }

    get expandedIcon() {
        return this.product.expanded ? 'utility:chevrondown' : 'utility:chevronright';
    }

    get indentStyle() {
        const effectiveLevel = this.product.manualIndent == '99' ||  this.product.manualIndent == '1' ? 0 : this.product.manualIndent;
        return `margin-left: ${Math.max((1.4 + this.level * 1.4) + effectiveLevel * 1.4,1.4)}rem; min-height:1.8rem`;
    }

    get levelClass() {
        const lvl = Math.min(this.level,  4);
        return `level-${lvl}`;
    }

    get nextLevel() {
        return parseInt(this.level, 10) + 1;
    }

    connectedCallback() {
        //loadStyle(this, comboboxContainer);
        this.zeroLevel = this.zeroLevel == 'true' ? true : false;
    }

    toggleExpand() {
        if(this.product.disabled){
            return;
        }
        if( !this.zeroLevel || ((this.zeroLevel || this.product.length > 0) && !this.product.selected)){
            const clone = { ...this.product, expanded: !this.product.expanded, selected: !this.product.expanded };
            this.isSelected = !this.product.expanded;
            //this.zeroLevel = this.level == 0;
            this.dispatchEvent(new CustomEvent('expand', {
            detail: { product: clone }
        }));
        }else{
            const clone = { ...this.product, expanded: true, selected: true };
            this.isSelected = true;
            //this.zeroLevel = this.level == 0;
            this.dispatchEvent(new CustomEvent('expand', {
            detail: { product: clone }
        }));
        }
        
    }

    handleCheckbox(event) {
        if( !this.zeroLevel || (this.zeroLevel && !this.isSelected)){
            const updated = { ...this.product, selected: !this.isSelected };
            this.isSelected = !this.isSelected;
            //this.zeroLevel = this.level == 0;
            this.dispatchEvent(new CustomEvent('check', {
                detail: { product: updated }
            }));
        }else{
            const updated = { ...this.product, selected: true };
            this.isSelected = true;
            //this.zeroLevel = this.level == 0;
            this.dispatchEvent(new CustomEvent('check', {
            detail: { product: updated }
        }));
        }
        
    }

    handleCheckboxBubble(event) {
        this.dispatchEvent(new CustomEvent('check', {
            detail: event.detail
        }));
    }

    handleExpandBubble(event) {
        this.dispatchEvent(new CustomEvent('expand', {
            detail: event.detail
        }));
    }

    handleChangeTerm(event){
        const updated = { ...this.product, maxTerm: event.target.value };
        this.dispatchEvent(new CustomEvent('term', {
            detail: { product: updated }
        }));
    }

    handleChangeTermBubble(event){
        //const updated = { ...this.product, maxTerm: event.target.value };
        this.dispatchEvent(new CustomEvent('term', {
            detail: event.detail
        }));
    }
}