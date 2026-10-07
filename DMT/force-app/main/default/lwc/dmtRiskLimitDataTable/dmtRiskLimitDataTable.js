import LightningDatatable from 'lightning/datatable';
import endTermPicklistTemplate from './endTermPicklistTemplate.html';
import amountStatic from './amountStatic.html';
import amountEditable from './amountEditable.html';

export default class DmtRiskLimitDataTable extends LightningDatatable {
    static customTypes = {
        endTermPicklist: {
            template: endTermPicklistTemplate,
            typeAttributes: ['value', 'options', 'optionslimit', 'isDisabled', 'context']
        },
        amountColumn: {
            template: amountStatic,
            editTemplate: amountEditable,
            standardCellLayout: true,
            typeAttributes: ['displayValue', 'editValue', 'currencyLabel']
        }
    };

    renderedCallback() {
        super.renderedCallback();

        const scrollXContainer = this.template.querySelector(
            '.slds-table_header-fixed_container.slds-scrollable_x'
        );
        const scrollYContainer = this.template.querySelector('.slds-scrollable_y');

        if (scrollXContainer) {
            scrollXContainer.style.setProperty('overflow', 'visible', 'important');
        }

        if (scrollYContainer) {
            scrollYContainer.style.setProperty('overflow', 'visible', 'important');
        }
    }
}