import LightningDatatable from 'lightning/datatable';
import picklistColumn from './picklistColumn.html';
import pickliststatic from './pickliststatic.html';
import bpsColumn from './bpsColumn.html';
import bpsstatic from './bpsstatic.html';
import minValueColumn from './minValueColumn.html';
import minValuestatic from './minValuestatic.html';
import textStatic from './textStatic.html';
import textColumn from './textColumn.html';
import kpiDescriptionCellType from './kpiDescriptionCellType.html';


export default class Kpi_custom_datatable extends LightningDatatable {
    static customTypes = {
        picklistColumn: {
            template: pickliststatic,
            editTemplate: picklistColumn,
            standardCellLayout: true,
            typeAttributes: ['label', 'placeholder', 'options', 'value', 'optionlabel', 'context', 'variant', 'name']
        },
        bpsColumn: {
            template: bpsstatic,
            editTemplate: bpsColumn,
            standardCellLayout: true,
            typeAttributes: ['value']
        },
        minValueColumn: {
            template: minValuestatic,
            editTemplate: minValueColumn,
            standardCellLayout: true,
            typeAttributes: ['value']
        },
        textColumn: {
            template: textStatic,
            editTemplate: textColumn,
            standardCellLayout: true,
            typeAttributes: ['value']
        },
        kpiDescriptionCellType: {
            template: textStatic,
            editTemplate: kpiDescriptionCellType,
            standardCellLayout: true,
            typeAttributes: ['value']
        }
    };
}