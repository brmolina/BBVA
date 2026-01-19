import LightningDatatable from 'lightning/datatable';
import picklistColumn from './picklistColumn.html';
import pickliststatic from './pickliststatic.html'
import currencyEdit from './currencyEdit.html';
import currencyStatic from './currencyStatic.html';
import linkToGuarantees from './linkToGuarantees.html';

export default class Hpg_custom_datatable extends LightningDatatable {
    static customTypes = {
        picklistColumn: {
            template: pickliststatic,
            editTemplate: picklistColumn,
            standardCellLayout: true,
            typeAttributes: ['label', 'placeholder', 'options', 'value', 'optionlabel', 'context', 'variant', 'name']
        },
        customCurrency: {
            template: currencyStatic,
            editTemplate: currencyEdit,
            standardCellLayout: true,
            typeAttributes: ['value', 'currencyCode']
        },
        linkToGuarantees: {
            template: linkToGuarantees,
            editTemplate: linkToGuarantees,
            standardCellLayout: true,
            typeAttributes: ['value', 'date']
        }
    };
}