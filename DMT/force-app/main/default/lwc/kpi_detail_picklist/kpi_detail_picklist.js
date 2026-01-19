import LightningDatatable from 'lightning/datatable';
import picklistColumn from './picklistcolumn.html';
import pickliststatic from './pickliststatic.html'

export default class Kpi_detail_picklist extends LightningDatatable {
    static customTypes = {
        picklistColumn: {
            template: pickliststatic,
            editTemplate: picklistColumn,
            standardCellLayout: true,
            typeAttributes: ['label', 'placeholder', 'options', 'value', 'context', 'variant','name']
        }
    };
}