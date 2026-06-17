({
    onInit : function(component, event, helper){
        var action = component.get('c.getFieldSetFromTemplate');
          action.setCallback(component,
              function(response) {
                  var state = response.getState();
                  console.log('state---------------------->'+state);
                  if (state === 'SUCCESS'){
                    console.log(response.getReturnValue());
                    var storeRes = response.getReturnValue();
                    component.set("v.fieldSetList", storeRes);
                  } else {
                    console.log('FALLO : ', JSON.stringify(response.getReturnValue()));
                  }
              }
          );
          $A.enqueueAction(action);
    },

    saveHelper: function(component, event, helper) {
      document.getElementById('submitForm').click();
    },

    handleSuccess : function(component, event, helper) {
      var payload = event.getParams().response;
      var recordId = payload.id;
      $A.get('e.force:navigateToURL').setParams({ 'url': '/lightning/r/Asset_Template__c/'+recordId+'/view' }).fire();
      $A.get('e.force:refreshView').fire();
    },

    closeModal: function(component, event, helper) {
      $A.get('e.force:navigateToURL').setParams({ 'url': '/lightning/o/Asset_Template__c/home' }).fire();
      $A.get('e.force:refreshView').fire();
    },

})