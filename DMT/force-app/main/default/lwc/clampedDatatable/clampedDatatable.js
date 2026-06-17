import LightningDatatable from 'lightning/datatable';
import clampTemplate from './clampTemplate.html';
import clampCheckbox from './clampCheckbox.html';

export default class ClampedDatatable extends LightningDatatable {
  static customTypes = {
    clampedText: {
      template: clampTemplate,
      standardCellLayout: true,
      typeAttributes: []
    },
    checkboxReadOnly: {
      template: clampCheckbox,
      standardCellLayout: true,
      typeAttributes: []
    }
  };
}