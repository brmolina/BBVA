({
     doInit:  function(component, event, helper) {
         helper.accountname(component, event);
     },
	handleClick: function(component, event, helper) {
		helper.navigate(component, event);
	},
    handleClick2: function(component, event, helper) {
		helper.navigate2(component, event);
	},
})