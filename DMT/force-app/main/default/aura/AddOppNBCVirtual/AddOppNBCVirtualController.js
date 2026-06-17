({
   doinit : function(component,event,helper) {
      if(component.get("v.selectedValue") !== undefined && component.get("v.selectedValue") !== null && component.get("v.selectedValue") !== '') {
          var forcerrar = component.find("lookup-pill");
          $A.util.addClass(forcerrar, 'slds-show');
          $A.util.removeClass(forcerrar, 'slds-hide');

      var forcerrar1 = component.find("searchRes");
          $A.util.addClass(forcerrar1, 'slds-is-close');
          $A.util.removeClass(forcerrar1, 'slds-is-open');

      var lookUpTar = component.find("lookupField");
          $A.util.addClass(lookUpTar, 'slds-hide');
          $A.util.removeClass(lookUpTar, 'slds-show');
      }
      helper.searchOpp(component, event, helper);
      component.set('v.columns', [{label: 'Opportunities', fieldName: 'oppName', type: 'text'},]);

   },
   cancel : function(component,event,helper){
        $A.get("e.force:closeQuickAction").fire();
   },
   onfocus : function(component,event,helper){
        helper.onfocusHelper(component,event,helper);
    },
    onblur : function(component,event,helper){
        helper.onblurHelper(component,event,helper);
    },
    keyPressController : function(component, event, helper) {
      helper.keyPressControllerHelper(component,event,helper);
	  },

  // function for clear the Record Selaction
    clear :function(component,event,helper){
        helper.clearHelper(component,event,helper);
    },

  // This function call when the end User Select any record from the result list.
    handleComponentEvent : function(component, event, helper) {
        helper.handleComponentEventHelper(component, event, helper);

    },
    save : function(component, event, helper) {
        helper.saveHelper(component, event, helper).then(
                $A.getCallback(function (result) {
                    if (result.resolve !== 'Not User') {
                        $A.get("e.force:closeQuickAction").fire();
                        $A.get('e.force:refreshView').fire();
                    }
                }),
                $A.getCallback(function (error) {
                    console.error('Error calling action getUrlIp with state: ' + error.message);
                })
            ).catch(function (e) {});

    },
    saveNew : function(component, event, helper){
      var opport = component.get("v.selectedRecord");
      var TemplateId = component.get('v.recordId');
      var action = component.get('c.saveOp');
      action.setParams({
        'opp': opport,
        'recordId' : TemplateId,
      })
      action.setCallback(component,
          function(response) {
              var state = response.getState();
              console.log('state---------------------->'+state);
              if (state === 'SUCCESS'){
                $A.get('e.force:refreshView').fire();
                helper.clearHelper(component, event, helper);
                helper.searchOpp(component, event, helper);
              } else {
                console.log('FALLO : ', JSON.stringify(response.getReturnValue()));
              }
          }
      );
      $A.enqueueAction(action);
    },
    getSelected : function(component, event, helper){
      var selectedRows = event.getParam('selectedRows');
      component.set('v.oppSelec',selectedRows);
    },
    deleteSel : function(component, event, helper) {
      var opport = component.get('v.oppSelec');
      var TemplateId = component.get('v.recordId');
      var action = component.get('c.eliminarOpp');
      action.setParams({
        'recordId' : TemplateId,
        'opps': JSON.stringify(opport),
      })
      action.setCallback(component,
        function(response) {
          var state = response.getState();

          if (state === 'SUCCESS'){
            $A.get('e.force:refreshView').fire();
            helper.searchOpp(component, event, helper);
          }else{
            console.log('FALLO : ', JSON.stringify(response.getReturnValue()));
          }
        })
      $A.enqueueAction(action);
  },

})