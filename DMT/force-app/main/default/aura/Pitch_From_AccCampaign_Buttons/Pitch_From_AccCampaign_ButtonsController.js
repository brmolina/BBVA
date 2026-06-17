({
    addFunction: function (component, event, helper) {
        component.set('v.AddOption', true);
        helper.flowClicked(component, event);
    },
    newFunction: function (component, event, helper) {
        component.set('v.NewOption', true);
        helper.flowClicked(component, event);
    },
})