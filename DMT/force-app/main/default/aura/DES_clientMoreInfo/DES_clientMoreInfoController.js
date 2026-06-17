({
	onInit: function(cmp, evt, helper) {
		var action = cmp.get("c.getLocalClient");
        
          console.log(cmp.get('v.recordId'));
      	action.setParams( {recordId: cmp.get('v.recordId')});
		action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                if(response.getReturnValue()!=0){
                    cmp.set('v.texto',response.getReturnValue()[0].Id);
                }
            }
            });
        $A.enqueueAction(action);
	}
})