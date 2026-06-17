({
	navigateTo : function(cmp, event, helper) {
        cmp.find("nav").navigate({
	        type: "standard__recordPage",
	        attributes: {
	        	recordId: cmp.get("v.recordId"),
	            objectApiName: cmp.get("v.object"),
	            actionName: "view"
            }
        });
    }
});