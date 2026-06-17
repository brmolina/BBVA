({
	doInit : function(component, event, helper) {
        console.log('entro en doInit');
        var action = component.get("c.isDesktop");
        var isDesktop;

        action.setCallback(this, function(response) {
            console.log(response.getState());
            console.log(response.getReturnValue());
            isDesktop = response.getReturnValue();
            console.log('isDesktop: '+ isDesktop);

            if (isDesktop) {
            console.log('isDesktop = true');
            var redirectToComponent = $A.get("e.force:navigateToComponent");
            redirectToComponent.setParams({
                componentDef : "c:DES_Popup_Custom_New_Contact"
            });
            redirectToComponent.fire();
        } else {
            console.log('isDesktop = false');
            var createRecordEvent = $A.get("e.force:createRecord");
            createRecordEvent.setParams({
            	"entityApiName": "Contact",
            	//"recordTypeId": "1234455566" // Optionally Specify Record Type Id
            });
            createRecordEvent.fire();
        }
        });
        $A.enqueueAction(action);

	}
})