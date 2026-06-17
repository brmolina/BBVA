({
	doInit : function(cmp, event, helper) {
		helper.getTableData(cmp);
		cmp.set('v.columns', [
			{label: 'Opportunity Name', fieldName: 'oppUrl', type: 'url', typeAttributes: { label: { fieldName: 'cOppName' }} },
			{label: 'Form Status', fieldName: 'nStageName', type: 'String'},
			{label: 'Created Date', fieldName: 'createdDate', type: 'date', typeAttributes:{
                year: "numeric",
                month: "2-digit",
                day: "2-digit",
                hour: "2-digit",
                minute: "2-digit"
        	}},
            {label: 'Owner country', fieldName: 'country', type: 'String'}
        ]);
	},

	navigateToMyComponent : function(component, event, helper) {
        var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef : "c:IpOppInProgressList",
            componentAttributes: {
            	detailForm : 'true',
            	tableSize : null
	        }
        });
        evt.fire();
    }

})