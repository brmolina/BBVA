({
  doInit : function(cmp, event, helper) {
    //Executed when component initializes
    helper.getUrlIpOppV(cmp, event, helper).then(
    	$A.getCallback(function(result) {
     		 helper.initComponent(cmp, event, helper);
	 	}),
        $A.getCallback(function(error) {
            console.error( 'Error calling action getUrlIp with state: ' + error.message );
        }));
  },

  handleSuccess : function(component, event, helper) {
    var toastEvent = $A.get("e.force:showToast");
    _ipUtils
        .sucess(toastEvent, "Success!", "Information has been updated.");
    helper.showHide(component);
  },
  handleCancel : function(component, event, helper) {
    helper.showHide(component);
    event.preventDefault();
  },
  editRecord : function(component, event, helper) {
    helper.showHide(component);
  },
  changeStateIP : function changeState(component) {
    component.set('v.isexpandedIP', !component.get('v.isexpandedIP'));
  },
  editRecordIP : function(component, event, helper) {
    helper.showHideIP(component);
  },
  handleCancelIP : function(component, event, helper) {
    helper.showHideIP(component);
    helper.fetchConfidentialData(component, event, helper);
    event.preventDefault();
  },
  handleSaveIP : function(component, event, helper) {
    var visit = component.get("v.visit");

        if (visit.visitFeedback === undefined || visit.visitFeedback === null || visit.visitFeedback === ""
        || visit.visitDescription === undefined ||  visit.visitDescription === null
        || visit.visitDescription === "") {
      var toastEvent = $A.get("e.force:showToast");
      _ipUtils.validation(toastEvent,
          "Please check the fields that are not completed");
    } else {
      helper.modifyOpp(component).catch(function(e){
               });
      helper.showHideIP(component);
    }

  }

})