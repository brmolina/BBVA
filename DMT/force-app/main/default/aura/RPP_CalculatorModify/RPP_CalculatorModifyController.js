({
	doInit: function(cmp, event, helper) {
		helper.doInit(cmp, event, helper);
	},
	handleOnCancel: function(cmp, event, helper) {
		helper.destroyCmp(cmp, event, helper);
	},
	handleOnSave: function(cmp, event, helper) {
		helper.handleOnSave(cmp, event, helper);
	}
})