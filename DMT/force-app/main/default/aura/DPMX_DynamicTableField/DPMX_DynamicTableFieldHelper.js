({
	doInit : function(cmp, event, helper) {
		helper.waiting(cmp);
		helper.doneWaiting(cmp);
	},
	waiting: function(cmp) {
		cmp.set('v.waiting', true);
	},
	doneWaiting: function(cmp) {
		cmp.set('v.waiting', false);
	}
})