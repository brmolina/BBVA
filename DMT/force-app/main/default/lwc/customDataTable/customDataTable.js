import { api } from 'lwc';
import LightningDatatable from 'lightning/datatable';
import DatatablePicklistTemplate from './picklist-template.html';
import SearchComboboxTemplate from './search-combobox-template.html';
import customSelectRowTemplate from "./customSelectRow.html";
import recordPickerTemplate from "./record-picker-template.html";
import genericRecordPickerTemplate from "./generic-record-picker-template.html";
import customInputRowTemplate from "./customInputRow.html";
import customNumberRowTemplate from "./customNumberRow.html";
import customDateRowTemplate from "./customDateRow.html";
import customIconTextTemplate from "./customIconText.html";

export default class CustomDataTable extends LightningDatatable {
    _hasRendered = false;
    @api overflow = false;

    static customTypes = {
        picklist: { template: DatatablePicklistTemplate, typeAttributes: ['label', 'placeholder', 'options', 'value', 'context', 'fieldName', 'readonlyAttr', 'optionslimit', 'isDisabled', 'showReadOnlyWarning', 'requieresValueRecoPick'] },
        searchcombobox: { template: SearchComboboxTemplate, typeAttributes: ['pickListOrdered', 'selectedSearchlabel', 'selectedSearchvalue', 'context', 'readonlyAttr', 'fieldName', 'isDisabled', 'requieresValueRecoPick'] },
        customselectRow: { template: customSelectRowTemplate, typeAttributes: ['aviableItem', 'checkedItem', 'fieldName', 'context'] },
        custominputRow: { template: customInputRowTemplate, typeAttributes: ['aviableItem', 'inputValue', 'fieldName', 'context', 'suffix', 'validateNegative'] },
        customnumberRow: { template: customNumberRowTemplate, typeAttributes: ['aviableItem', 'numberValue', 'fieldName', 'context', 'min', 'max', 'step', 'placeholder', 'formatter', 'disabled', 'readonlyAttr', 'validateNegative'] },
        customdateRow: { template: customDateRowTemplate, typeAttributes: ['aviableItem', 'dateValue', 'fieldName', 'context', 'maxDate', 'minDate', 'lockDate'] },
        recordpicker: { template: recordPickerTemplate, typeAttributes: ['value', 'fieldName', 'context', 'matchingInfo', 'displayInfo', 'disabled', 'filter'] },
        customIconText: { template: customIconTextTemplate, typeAttributes: ['value', 'iconName', 'textColor', 'tooltip', 'iconPosition', 'iconVariant', 'iconColor'] },
        genericrecordpicker: { template: genericRecordPickerTemplate, typeAttributes: ['value', 'label', 'fieldName', 'context', 'placeholder', 'disabled', 'options'] }
    };

    renderedCallback() {
        super.renderedCallback();
        //only if we want to apply overflow on the table, on cases where dropdown is cut
        if (this.overflow) {
        // ensuring rendering first then applying properties if first time
        if (!this._hasRendered) {
            setTimeout(() => {
                this.setOverflow();
            }, 500);

            this._hasRendered = true;
        // remaining times, applies properties directly
        } else {
            this.setOverflow();
        }
        }
    }


setOverflow() {
        // Como estamos DENTRO de la clase extendida de LightningDatatable,
        // this.template SÍ tiene acceso a los divs internos de la tabla estándar.
        const scrollXContainer = this.template.querySelector('.slds-table_header-fixed_container.slds-scrollable_x');
        const scrollYContainer = this.template.querySelector('.slds-scrollable_y');

        // Verificamos y aplicamos en el contenedor X
        if (scrollXContainer) {
            const currentOverflowX = window.getComputedStyle(scrollXContainer).overflow;
            if (currentOverflowX !== 'visible') {
                scrollXContainer.style.setProperty('overflow', 'visible', 'important');
            }
        }

        // Verificamos y aplicamos en el contenedor Y
        if (scrollYContainer) {
            const currentOverflowY = window.getComputedStyle(scrollYContainer).overflow;
            if (currentOverflowY !== 'visible') {
                scrollYContainer.style.setProperty('overflow', 'visible', 'important');
            }
        }
    }
}