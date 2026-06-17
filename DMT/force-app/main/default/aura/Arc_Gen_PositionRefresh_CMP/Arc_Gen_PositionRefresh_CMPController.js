({
  doInit: function(component, event, helper) {
    const dateField = component.get('v.dateFieldName');
    component.set('v.dateFieldNameList', [ dateField ]);
    component.set('v.loaded', true);
  },
  refreshAction: function(component, event, helper) {
    component.set('v.disabledBtn', true);
    var aplicEvent = $A.get('e.c:Arc_Gen_PositionEvent');
    aplicEvent.setParams({'table': component.get('v.table')});
    aplicEvent.setParams({'recordId': component.get('v.recordId')});
    aplicEvent.fire();
  },
  onLoadedTableEvent: function(component, event, helper) {
    const currentTable = component.get('v.table');
    const eventTable = event.getParam('table');
    if (currentTable === eventTable) {
      const dataFetcher = component.find('ahaRecord');
      dataFetcher.reloadRecord({ skipCache: true });
    }
  },
  onUpdate: function(component, event, helper) {
    const fields = component.get('v.ahaFields');
    const fieldName = component.get('v.dateFieldName');
    if (fields[fieldName] !== null && fields[fieldName] !== '') {
      component.set('v.datetime', new Date(fields[fieldName]));
    }
  }
});