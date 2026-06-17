({
    afterScriptsLoaded : function(component, event, helper) {
        //$A.get("e.force:refreshView").fire();
        component.set('v.ready', true);
        helper.getTableData(component);
        
        //Table
        component.set('v.myColumns', [
            {label: 'Client', fieldName: 'clientUrl', type: 'url', typeAttributes: { label: { fieldName: 'clientName' }} },
            {label: 'Year', fieldName: 'year', type: 'String', sortable: true},
            {label: 'Family', fieldName: 'family', type: 'String', sortable: true},
            {label: 'Country', fieldName: 'country', type: 'String', sortable: true},
            {label: 'Product', fieldName: 'product', type: 'String', sortable: true},
            {label: 'Revenues', fieldName: 'revenues', type: 'currency', typeAttributes: { currencyCode: component.get("v.userISOCode") }, sortable: true}
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