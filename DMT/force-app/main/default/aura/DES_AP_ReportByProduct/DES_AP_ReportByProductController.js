({
    afterScriptsLoaded : function(component, event, helper) {
        component.set('v.ready', true);
        helper.createChart(component);
    }, 
    navigateToMyComponent : function(component, event, helper) {
        var evt = $A.get('e.force:navigateToComponent');
        evt.setParams({
            componentDef : 'c:DES_APCommActionsDetail',
            componentAttributes: {
                recordId : component.get('v.recordId'),
                chartFilter : component.get('v.chartFilter')
            }
        });
        evt.fire();
    }
})