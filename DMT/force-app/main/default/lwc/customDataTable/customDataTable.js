import LightningDatatable from 'lightning/datatable';
//import the template so that it can be reused
import DatatablePicklistTemplate from './picklist-template.html';
import SearchComboboxTemplate from './search-combobox-template.html';
import customSelectRowTemplate from "./customSelectRow.html";
import recordPickerTemplate from "./record-picker-template.html";
import customInputRowTemplate from "./customInputRow.html";
import customDateRowTemplate from "./customDateRow.html";
import customIconTextTemplate from "./customIconText.html";
// import {
//     loadStyle
// } from 'lightning/platformResourceLoader';
//import CustomDataTableResource from '@salesforce/resourceUrl/customDataTable';

export default class CustomDataTable extends LightningDatatable {
    static customTypes = {
        picklist: {
            template: DatatablePicklistTemplate,
            typeAttributes: ['label', 'placeholder', 'options', 'value', 'context', 'fieldName','readonlyAttr','optionslimit', 'isDisabled', 'showReadOnlyWarning', 'requieresValueRecoPick'],
        },
        searchcombobox: {
            template: SearchComboboxTemplate,
            typeAttributes: ['pickListOrdered', 'selectedSearchlabel','selectedSearchvalue','context','readonlyAttr', 'fieldName', 'isDisabled', 'requieresValueRecoPick'],
        },
        customselectRow: {
            template: customSelectRowTemplate,
            typeAttributes: ['aviableItem', 'checkedItem', 'fieldName','context'],
        },
        custominputRow: {
            template: customInputRowTemplate,
            typeAttributes: ['aviableItem', 'inputValue', 'fieldName','context'],
        },
        customdateRow: {
            template: customDateRowTemplate,
            typeAttributes: ['aviableItem', 'dateValue', 'fieldName','context','maxDate', 'lockDate'],
        },
        recordpicker: {
            template: recordPickerTemplate,
            typeAttributes: ['value', 'fieldName','context','matchingInfo', 'displayInfo', 'disabled'],
        },
        customIconText:{
            template: customIconTextTemplate,
            typeAttributes: ['value','iconName','textColor','tooltip', 'iconPosition', 'iconVariant', 'iconColor']
        }
    };

     /*connectedCallback() {
        console.log('JACG');
        console.log(this.template.querySelectorAll('div'));
        
    }*/

    // handlePicklistChange(event) {
    //     const grandChildren = this.template.querySelector('c-searchable-combobox');
    //     console.log('JACG');
    //     console.log(JSON.stringify(grandChildren));
    //     /*const customEvent = new CustomEvent('changepicklist', {
    //         event
    //         });
    //     this.dispatchEvent(customEvent);/
    //    // console.log(grandChildren);
    //    // const targetGrandChild = [...grandChildren].find(grandchild => grandchild.getAttribute('context') === dataRecieved.context && grandchild.getAttribute('fieldname') != dataRecieved.fieldname);
    //     /*if (targetGrandChild) {
    //         const customEvent = new CustomEvent('changepicklist', {
    //         detail: event.detail
    //         });
    //         targetGrandChild.dispatchEvent(customEvent);
    //     }*/
    // }

    // constructor() {
    //     super();
    //     Promise.all([
    //         loadStyle(this, LightningDatatable),
    //     ]).then(() => {})
    // }
}