({

  doInit : function(cmp, event, helper) {
       var action = cmp.get("c.getInsideFormData");
       action.setParams({
           "insideFormId": cmp.get("v.recordId")
       });

       action.setCallback(this, function(response) {

           var state = response.getState();


           if (state === "SUCCESS") {
                cmp.set('v.form', response.getReturnValue().insideInformationForm );
                cmp.set('v.userAccess', response.getReturnValue().userRecordAccess );


           }
           else {
           }
       });
       $A.enqueueAction(action);

      	var actionCompliance = cmp.get("c.isCompliance");
       	actionCompliance.setCallback(this, function(response) {

           var state = response.getState();
           if (state === "SUCCESS") {
                cmp.set('v.isCompliance', response.getReturnValue());
           }
           else {
           }
       });
       $A.enqueueAction(actionCompliance);

    //Executed when component initializes
    helper.getUrlIpOppV(cmp, event, helper).then(
    	$A.getCallback(function(result) {
     		 helper.initComponent(cmp, event, helper);
	 	}),
        $A.getCallback(function(error) {
            console.error( 'Error calling action getUrlIp with state: ' + error.message );
        }));

       helper.showCountryLabel(cmp, event, helper);

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

  changeStateIP2 : function changeState(component) {
    component.set('v.isexpandedIP2', !component.get('v.isexpandedIP2'));
  },
  editRecordIP : function(component, event, helper) {

      var isCompliance =component.get("v.isCompliance");

      var action = component.get("c.getInsideFormData");
       action.setParams({
           "insideFormId": component.get("v.recordId")
       });

       action.setCallback(this, function(response) {

           var state = response.getState();

           if (state === "SUCCESS") {
                component.set('v.form', response.getReturnValue().insideInformationForm );

                var form =component.get("v.form");
               	if((form.status_type__c !== "Pending" && form.status_type__c !== "Approved") || (isCompliance || isCompliance === true))  {
                	helper.showHideIP(component);
                }
               else{
                       var toastEvent = $A.get("e.force:showToast");
    					toastEvent.setParams({
        					"title": "Edit Record",
        					"message": "The status is \"Pending\" or \"Approved\". You can't edit the form.",
                            "type": "info"
    					});
    					toastEvent.fire();
               }
           }
           else {
           }
       });
       $A.enqueueAction(action);
  },

  handleCancelIP : function(component, event, helper) {
    helper.showHideIP(component);
    helper.fetchConfidentialData(component, event, helper);
    event.preventDefault();
  },
  handleSaveIP : function(cmp, event, helper) {
    var action = cmp.get("c.saveFormulario");
      var form =cmp.get("v.form");
       action.setParams({
           "form": form
       });
       action.setCallback(this, function(response) {
           var state = response.getState();
           if (state === "SUCCESS") {
                cmp.set('v.form', response.getReturnValue());
           }
           else {
               console.error("Failed with state: "+ state);
           }
       });
       $A.enqueueAction(action);

      helper.modifyOpp(cmp).catch(function(e){
               });
      helper.updateListed(cmp, event, helper);
      helper.showHideIP(cmp);
      setTimeout(function(){helper.fetchListedData(cmp,event,helper)},500);
  },

    onchange : function(component, event, helper) {
    }

})