({
    doInit: function (cmp, event, helper) {
        helper.onInit(cmp, event, helper);
        helper.createButton(cmp, event, helper);
    },
    handlePress: function(cmp, event, helper) {
	    helper.onHandlePress(cmp, event, helper);
	}
});