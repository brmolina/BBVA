({
	flowClicked : function(component, event) {
		var actionClicked = event.getSource().getLocalId();
        var navigate = component.get('v.navigateFlow');
        navigate(actionClicked);
	}
})