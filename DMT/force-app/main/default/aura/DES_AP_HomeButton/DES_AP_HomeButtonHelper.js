({
    chooseFunction: function(component, event, helper) {
        console.log('dentro de chooseFunction');
        var flow = component.find('flowName');
        var lpPicklist = component.get('v.lpPicklist');

        if (component.get('v.lpPicklist') === 'Custom notification') {
            console.log('dentro de Custom notification');
          	component.set('v.Custom_notification', true);
            component.set('v.divTitle', "Notifications Setup");
            component.set('v.actionDescription', "As Account Planning administrator, you can send an individual or status-based notification");
            component.set('v.buttonName', "Notification Setup");
        }
    }
})