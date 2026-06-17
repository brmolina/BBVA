({
	doInit : function(cmp, event, helper){
		helper.getTableData(cmp);
		cmp.set('v.columns', [
            {label: 'Alert Name', fieldName: 'alUrl', type: 'url', typeAttributes: { label: { fieldName: 'alName' }} },
            {label: 'Type', fieldName: 'altype', type: 'String'},
            {label: 'Description', fieldName: 'descrip', type: 'String'/*, initialWidth: 900*/},
            {label: 'Owner', fieldName: 'urlOwner', type: 'url', typeAttributes: { label: { fieldName: 'nameOwner' }} },
            {label: 'Banker/Product Specialist', fieldName: 'urlBanker', type: 'url', typeAttributes: { label: { fieldName: 'nameBanker' }} }
        ]);
	},

	navigateToMyComponent : function(component, event, helper) {
        var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef : "c:AlertsRelatedList",
            componentAttributes: {
	            recordId : component.get("v.recordId"),
                familyParam : component.get("v.familyParam"),
            	detailForm : 'true',
            	tableSize : null
	        }
        });
        evt.fire();
    }

})