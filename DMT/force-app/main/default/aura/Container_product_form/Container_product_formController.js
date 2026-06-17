({
	doInit: function(component, event, helper) {
		helper.getInfo(component, event, helper);
	},
	doInitRefreshView: function(cmp, evt, helper){
		if(window.location.href.includes(cmp.get("v.recordId"))){
			cmp.set("v.isLoad",false);
			helper.getInfo(cmp, evt, helper);
		}
	}
})