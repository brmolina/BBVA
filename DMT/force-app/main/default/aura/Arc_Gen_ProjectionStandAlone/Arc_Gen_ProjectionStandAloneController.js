({
  initEng: function(component, event, helper) {
    helper.checkControlValues(component, helper);
  },

  printTable: function(component, event, helper) {
    window.open('/apex/arce__Arc_Gen_PDF_Projection_DataTable_Summary' + '?ahaId=' +    component.get('v.recordId'));
  }
});