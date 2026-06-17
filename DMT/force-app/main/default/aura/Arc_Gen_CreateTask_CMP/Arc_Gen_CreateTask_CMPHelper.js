({
  getData: function(component, event, helper) {
    var action = component.get('c.retrieveData');
    action.setParams({
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var resultValue = response.getReturnValue();
        component.set('v.createTask.RecordTypeId', resultValue[0][0]);
        component.set('v.subjectList', resultValue[1]);
        component.set('v.typeList', resultValue[2]);
        component.set('v.priorityList', resultValue[3]);
        component.set('v.statusList', resultValue[4]);
        component.set('v.listFieldLabels', resultValue[5]);
      } else {
        var mensaje = response.getError()[0].message;
        var resultsToast = $A.get('e.force:showToast');
        resultsToast.setParams({
          'title': $A.get('{!$Label.c.Arc_Gen_ApexCallError}'),
          'type': 'error',
          'message': mensaje,
          'duration': '8000'
        });
        resultsToast.fire();
        component.find('overlayLib').notifyClose();
      }
    });
    $A.enqueueAction(action);
  },
  insertRecords: function(component, event, helper) {
    var action = component.get('c.createTaskRecord');
    action.setParams({
      taskForInsert: component.get('v.createTask'),
      ownerIds: component.get('v.ownerIds'),
      relatedTo: component.get('v.createTask.WhatId')
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var toastEvent = $A.get('e.force:showToast');
        toastEvent.setParams({
          'type': 'SUCCESS',
          'title': $A.get('$Label.c.Arc_Gen_Toast_Success_Title'),
          'message': $A.get('$Label.c.Arc_Gen_recordSaveSuccess')
        });
        toastEvent.fire();
        component.find('overlayLib').notifyClose();
      } else {
        var mensaje = response.getError()[0].message;
        var resultsToast = $A.get('e.force:showToast');
        resultsToast.setParams({
          'title': $A.get('{!$Label.c.Arc_Gen_ApexCallError}'),
          'type': 'error',
          'message': mensaje,
          'duration': '8000'
        });
        resultsToast.fire();
        component.find('overlayLib').notifyClose();
      }
    });
    $A.enqueueAction(action);
  },
  checkRequiredFields: function(component, event, helper) {
    var usersAssigned = component.get('v.ownerIds').length;
    var arceRelated = component.get('v.createTask.WhatId');
    if (usersAssigned === 0 && !arceRelated) {
      helper.setErrorMessage(component, $A.get('$Label.c.Arc_Gen_Error_CreateTask'));
    } else if (usersAssigned === 0) {
      helper.setErrorMessage(component, $A.get('$Label.c.Arc_Gen_Error_OwnerId'));
    } else if (!arceRelated) {
      helper.setErrorMessage(component, $A.get('$Label.c.Arc_Gen_Error_WhatId'));
    } else {
      helper.insertRecords(component, event, helper);
    }
  },
  createForm: function(component, event, helper) {
    var params = {
      'buttonOrModal': true
    };
    $A.createComponent(
      component.get('v.formName'),
      params,
      function(html, status, errorMessage) {
        if (status === 'SUCCESS') {
          component.find('overlayLib').showCustomModal({
            header: $A.get('$Label.c.Arc_Gen_New_Task'),
            body: html,
            showCloseButton: true,
            cssClass: 'cArc_Gen_CreateTask_CMP',
            closeCallback: function() {

            }
          });
        }
      }
    );
  },
  setErrorMessage: function(component, message) {
    component.set('v.error', true);
    component.set('v.messageError', message);
    setTimeout($A.getCallback(function() {
      component.set('v.error', false);
      component.set('v.messageError', null);
    }), 5000);
  }
});