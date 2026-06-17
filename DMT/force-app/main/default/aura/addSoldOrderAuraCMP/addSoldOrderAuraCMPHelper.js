({
    closeModel: function (component, event, helper) {
        component.set("v.isOpen", false);
    },
    fireRefreshView: function (component, event, helper) {
        $A.get('e.force:refreshView').fire();
    },
    oppCurrencyISOCode: function (component, event) {
        var action = component.get("c.obtainOppCurrency");
        action.setParams({
            'oppId': component.get('v.recordId')
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                console.log('>>>>> SUCCESS');
                component.set('v.oppCurrency', response.getReturnValue());
            } else {
                console.log('FALLO : ', JSON.stringify(response.getReturnValue()));
            }
        });
        // enqueue the Action
        $A.enqueueAction(action);
    },
    oppLineItemProrrataAmount: function (component) {
        var action = component.get("c.obtainBBVAParticipationPer");
        action.setParams({
            'oppId': component.get('v.recordId')
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                console.log('>>>>> SUCCESS');
                component.set('v.underwritingPercent', response.getReturnValue());
            } else {
                console.log('FALLO : ', JSON.stringify(response.getReturnValue()));
            }
        });
        // enqueue the Action
        $A.enqueueAction(action);
    }
})