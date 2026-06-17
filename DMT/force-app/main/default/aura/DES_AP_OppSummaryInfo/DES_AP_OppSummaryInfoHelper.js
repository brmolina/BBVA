({
	getOppInfo: function(cmp, evt, helper) {
        var action = cmp.get('c.getRelatedOpportunities');
        action.setParams({
            gaId: cmp.get('v.recordId'),
            qType: cmp.get('v.OpportunityInfo'),
            sumType: cmp.get('v.sumType'),
            configType: 'Totals'
    	});
        action.setCallback(this, $A.getCallback(function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var resultData = response.getReturnValue();
                var listitems = [];
                var labelscmp = cmp.get('v.fieldLabels');
                for (var i = 0; i<2; i++) {
                    var item = {
                        label: labelscmp.toString().split(",")[i],
                        value : resultData.split(",")[i]
                    };
                    listitems.push(item);
                }
                cmp.set('v.dataResult', listitems);
            } else if (state === "ERROR") {
                var errors = response.getError();
                console.error(errors);
            }
        }));
        $A.enqueueAction(action);
	}
})