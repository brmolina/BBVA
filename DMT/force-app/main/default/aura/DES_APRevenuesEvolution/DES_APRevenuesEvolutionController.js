({
    afterScriptsLoaded : function(component, event, helper) {
       console.log('show table navigate: ' + component.get('v.showTable'));
        component.set('v.ready', true);
        component.set('v.country', '');
        helper.createChart(component);
        console.log('detailForm: ' + component.get('v.detailForm'));
        console.log('lstCountries en el controller: ' + component.get('v.lstCountries'));

        //Table
        helper.getTableData(component);
        component.set('v.myColumns', [
            {label: 'Client', fieldName: 'clientUrl', type: 'url', typeAttributes: { label: { fieldName: 'clientName' }} },
            {label: 'Year', fieldName: 'year', type: 'String', sortable: true},
            {label: 'Family', fieldName: 'family', type: 'String', sortable: true},
            {label: 'Country', fieldName: 'country', type: 'String', sortable: true},
            {label: 'Product', fieldName: 'product', type: 'String', sortable: true},
            {label: 'Revenues', fieldName: 'revenues', type: 'currency', typeAttributes: { currencyCode: component.get("v.userISOCode") }, sortable: true}
        ]);
    },

    doInit : function(component, event, helper) {
        helper.getCountries(component, event, helper);
    },

    navigateToMyComponent : function(component, event, helper) {
		var country = component.get('v.country');
        component.set('v.showTable', true);

        console.log('country navigate: ' + country);
        console.log('show table navigate: ' + component.get('v.showTable'));

        var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef : "c:DES_APRevenuesEvolution",
            componentAttributes: {
                recordId : component.get("v.recordId"),
                detailForm : 'true',
                tableSize : null,
                country : component.get('v.country'),
                showTable: component.get('v.showTable')
            }
        });
        evt.fire();
    },

    clickCountry : function(component, event, helper) {
        var country = event.getSource().get("v.name");
        console.log('country: ' + country);
        component.set('v.country', country);

        helper.createChart(component, event, helper);
        helper.getTableData(component);
    },

    // TABLE
    updateColumnSorting: function (component, event, helper) {
        var fieldName = event.getParam('fieldName');
        var sortDirection = event.getParam('sortDirection');
        // Assign the latest attribute with the sorted column fieldName and sorted direction
        component.set("v.sortedBy", fieldName);
        component.set("v.sortedDirection", sortDirection);
        helper.sortData(component, fieldName, sortDirection);
    }

})