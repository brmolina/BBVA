({
	doInit : function(component, event, helper) {
		helper.getTableData(component);
    component.set('v.myColumns', [
      { label: 'Visit: Visit Name', fieldName: 'visitUrl', type: 'url', typeAttributes: { label: { fieldName: 'visName' } },sortable : true },
      { label: 'Client', fieldName: 'clientProspectURL', type: 'url', typeAttributes: { label: { fieldName: 'clientProspect' } },sortable : true },
      { label: 'Start Date', fieldName: 'StartDate', type: 'date',sortable : true },
      { label: 'Type', fieldName: 'types', type: 'String',sortable : true },
      { label: 'Purpose Type', fieldName: 'PurposType', type: 'picklist',sortable : true}
    ]);
	},updateColumnSorting: function (cmp, event, helper) {
        var fieldName = event.getParam('fieldName');
        var sortDirection = event.getParam('sortDirection');
        cmp.set("v.sortBy", fieldName);
        cmp.set("v.sortDirection", sortDirection);
        helper.sortData(cmp, fieldName, sortDirection);
    }
})