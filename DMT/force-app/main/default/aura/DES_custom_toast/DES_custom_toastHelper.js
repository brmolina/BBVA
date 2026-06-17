({
	success : function(component) {
    var toastEvent = $A.get("e.force:showToast");
    _ipUtils
        .sucess(toastEvent, component.get("v.mensaje"), null);
  	},
    validation : function(component) {
		var toastEvent = $A.get("e.force:showToast");
                _ipUtils.validation(toastEvent,
                 component.get("v.mensaje"));
    },
    error : function(component) {
		var toastEvent = $A.get("e.force:showToast");
                _ipUtils.errorToast(toastEvent,
                 component.get("v.mensaje"));
    }
})