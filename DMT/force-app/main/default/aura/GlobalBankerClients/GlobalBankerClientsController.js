({

    fetchAccounts : function(component, event, helper) {
        component.set('v.mycolumns', [
            {label: 'Main Parent', fieldName: 'accUrl', type: 'url', typeAttributes: {label: { fieldName: 'accName' }}},
            {label: 'Fiscal ID', fieldName: 'idFiscal', type: 'String'},
            {label: 'Country', fieldName: 'country', type: 'String'},
            {label: 'Parent', fieldName: 'accUrlParent', type: 'url', typeAttributes: {label: { fieldName: 'accNameParent' }}},
            {label: 'Fiscal ID (Parent)', fieldName: 'idFiscalParent', type: 'String'}
        ]);
        var action = component.get("c.fetchAccts");
        action.setParams({
            'recordId' : component.get('v.recordId')
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                var records =JSON.parse(response.getReturnValue());
                component.set("v.acctList", records);
            }
        });
        $A.enqueueAction(action);
    }


})