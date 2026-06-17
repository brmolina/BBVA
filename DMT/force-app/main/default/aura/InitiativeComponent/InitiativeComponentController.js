({
	getReportToShow : function(cmp, event, helper) {
        var permission;
        var creator = cmp.get('v.Creator');
        var participants = cmp.get('v.Participants');
        var banker = cmp.get('v.Banker');
        var reports = [];
        var action = cmp.get('c.getPermission');
        action.setCallback(this, function(response){
            console.log(response.getReturnValue() + ' ' + response.getState());
            var state = response.getState();
            if( state === "SUCCESS"){
                permission = response.getReturnValue();
                if(creator && permission) {
                    reports.push('My_initiatives_BmR');
                }
                if(participants && !permission) {
                    reports.push('Initiatives_I_participate_EcW');
                }
                if(banker) {
                    reports.push('My_groups_initiatives_Dsh');
                }
                cmp.set('v.reportsToShow', reports);
            }
        })
        $A.enqueueAction(action);
	}
})