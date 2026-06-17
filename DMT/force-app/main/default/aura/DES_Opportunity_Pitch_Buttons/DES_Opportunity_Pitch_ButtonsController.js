({
    addOpportunity: function (component, event, helper) {
        component.set('v.AddOpportunity', true);
        var actionClicked = event.getSource().getLocalId();
        var navigate = component.get('v.navigateFlow');
        navigate(actionClicked);
    },
    newOpportunity: function (component, event, helper) {
        component.set('v.NewOpportunity', true);
        var actionClicked = event.getSource().getLocalId();
        var navigate = component.get('v.navigateFlow');
        navigate(actionClicked);
    },
})