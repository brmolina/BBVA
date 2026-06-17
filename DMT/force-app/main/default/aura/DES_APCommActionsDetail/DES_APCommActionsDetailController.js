({
    afterScriptsLoaded : function(component, event, helper) {
        component.set('v.ready', true);
        helper.getTableData(component);

        //Table
        component.set('v.myColumns', [
            {label: 'Client', fieldName: 'clientUrl', type: 'url', typeAttributes: { label: { fieldName: 'clientName' }} },
            {label: 'Visit', fieldName: 'visitUrl', type: 'url', typeAttributes: { label: { fieldName: 'visitName' }} },
            {label: 'Type', fieldName: 'visitType', type: 'String', sortable: true},
            {label: 'Start date', fieldName: 'startDate', type: 'Date', sortable: true}
        ]);
    },

    updateColumnSorting: function (component, event, helper) {
        var fieldName = event.getParam('fieldName');
        var sortDirection = event.getParam('sortDirection');
        // Assign the latest attribute with the sorted column fieldName and sorted direction
        component.set("v.sortedBy", fieldName);
        component.set("v.sortedDirection", sortDirection);
        helper.sortData(component, fieldName, sortDirection);
    }
})