({
	closeModal: function (component, event, helper) {
        const isQuickAction = component.get('v.isQuickAction');
        if (isQuickAction) {
            $A.get('e.force:closeQuickAction').fire();
        } else {
            const nameDomain = component.get('v.domain');
            window.location.replace(nameDomain + '.lightning.force.com/one/one.app?source=aloha#/sObject/Contact/list?filterName=Recent');
        }
    },
    getDomain: function (component, event, helper) {
        let domain = component.get('c.currentDomain');
        domain.setCallback(this, function (response) {
            if (response.getState() === 'SUCCESS') {
                component.set('v.domain', response.getReturnValue());
            }
        });
        $A.enqueueAction(domain);
    }
})