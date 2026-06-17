({
  setInitialValues : function(cmp) {
    cmp.set("v.recordId", cmp.get("v.inputAttributes.recordId"));
  },
  previousChecks: function(cmp, evt, helper) {
    helper.waiting(cmp);
    var action = cmp.get('c.previousChecks');
    action.setParams({
      'iRecordId': cmp.get('v.recordId')
    })
    action.setCallback(this, function(response) {
      var state = response.getState();
      if(state === 'SUCCESS') {
        var ret = response.getReturnValue();
        if (ret.errorParticipants) {
          helper.showToast('Error', 'error', ret.errorMessage);
          helper.destroyCmp(cmp, evt, helper);
        } else {
          cmp.set('v.stage', ret.stage);
          cmp.set('v.papName', ret.papName);
          cmp.set('v.hasReqPkg', ret.hasReqPkg);
          cmp.set('v.hasExtPkg', ret.hasExtPkg);
          cmp.set('v.extPkgName', ret.extPkgName);
          cmp.set('v.participantId', ret.participantId);
          cmp.set('v.profAnId', ret.profAnId);
          cmp.set('v.hasPackages', ret.hasPackages);
          cmp.set('v.hasConditions', ret.hasConditions);
          cmp.set('v.hasFlatRates', ret.hasFlatRates);
        }
      }else if(state === 'INCOMPLETE'){
        console.log('INCOMPLETE', response);
      }else if(state === 'ERROR') {
        var errors = response.getError();
        console.error('Error message: ' + errors[0].message);
      }
      helper.doneWaiting(cmp);
    });
    $A.enqueueAction(action);
  },
  getProfitabilitySheets: function(cmp) {
    var action = cmp.get('c.getProfitabilitySheets');
    action.setParams({
      'iRecordId': cmp.get('v.recordId')
    })
    action.setCallback(this, function(response) {
      var state = response.getState();
      if(state === 'SUCCESS') {
        let ret = response.getReturnValue();
        let radioButtonValues = [];
        let objValue1 = {'label': 'New Pricing Conditions Book', 'value': 'new'};
        radioButtonValues.push(objValue1);
        if(ret.length > 0) {
          let objValue2 = {'label': 'Existing Pricing Conditions Book', 'value': 'existing'};
          radioButtonValues.push(objValue2);
        }
        cmp.set('v.optionRadioButton', radioButtonValues);
        cmp.set('v.moveOptionsList', radioButtonValues);
        cmp.set('v.existingProfSheetList', ret);
      }else if(state === 'INCOMPLETE'){
        console.log('INCOMPLETE', response);
      }else if(state === 'ERROR') {
        var errors = response.getError();
        console.error('Error message: ' + errors[0].message);
      }
    });
    $A.enqueueAction(action);
  },
  handleMoveOptionChange: function(cmp, evt) {
    switch (evt.getSource().get("v.value")) {
      case 'existing':
          cmp.set('v.new', false);
          cmp.set('v.existing', true);
      break;
      case 'new':
          cmp.set('v.new', true);
          cmp.set('v.existing', false);
      break;
      default:
          cmp.set('v.new', false);
          cmp.set('v.existing', false);
      break;
    }
  },
  handleOnSubmit : function(cmp, evt, helper) {
    helper.waiting(cmp);
    if((cmp.get('v.new') && cmp.find("newName").get("v.value") === '') || (cmp.get('v.existing') && cmp.find("existingProfSheet").get("v.value") === null) || (!cmp.get('v.existing') && !cmp.get('v.new'))) {
      helper.doneWaiting(cmp);
      return;
    }
    var clonefg = cmp.get("v.clonefg");
    var firstStageAction = '';
    if(clonefg){
      firstStageAction = 'temporarily';
    }else{
      firstStageAction = 'permanently';
    }
    var action = cmp.get('c.removeParticipant');
    action.setParams({
      'recordId': cmp.get('v.recordId'),
      'firstWarning': firstStageAction
    })
    action.setCallback(this, function(response) {
      if (response.getState() === 'SUCCESS') {
        let ret = response.getReturnValue();
        if (ret.errMessage !== '' && ret.errMessage !== undefined) {
          switch (ret.toastType) {
            case 'warning':
              helper.showNewToastParticipantRemoveCmp('warning', ret.errMessage);
              break;
            case 'error':
              helper.showNewToastParticipantRemoveCmp('error', ret.errMessage);
              break;
          }
        } else {
          helper.moveParticipant(cmp, evt, helper);
        }
      }
    });
    $A.enqueueAction(action);
  },
  moveParticipant : function(cmp, evt, helper) {
    var optionNew = cmp.get('v.new');
    var optionexisting = cmp.get('v.existing');
    var newName = null;
    var clonefr = true;
    var clonesc = true;
    var profiSheet = null;
    if (optionNew) {
      newName = cmp.find("newName").get("v.value");
      clonefr = cmp.get("v.clonefr");
      clonesc = cmp.get("v.clonesc");
    } else {
      profiSheet = cmp.find("existingProfSheet").get("v.value");
    }
    var action = cmp.get('c.moveParticipant');
    action.setParams({
      'create': optionNew,
      'existing': optionexisting,
      'name': newName,
      'profSheetId': profiSheet,
      'iRecordId': cmp.get('v.recordId'),
      'participantId': cmp.get('v.participantId'),
      'profAnId': cmp.get('v.profAnId'),
      'clonefr': clonefr,
      'clonesc': clonesc
    })
    action.setCallback(this, function(response) {
      var state = response.getState();
      if(state === 'SUCCESS') {
        var result = response.getReturnValue();
        if (result.success) {
          var toastEvent = $A.get("e.force:showToast");
          toastEvent.setParams({
            title: "Success",
            type: "success",
            mode: "dismissible",
            duration: "30000",
            message: 'This is a required message',
            messageTemplate: 'Participant moved to {0}.',
            messageTemplateData: [
              {
                url: '/' + result.profAId,
                label: result.profAName
              }
            ]
          });
          toastEvent.fire();
          // Refresh participants evt
          let appEvent = $A.get('e.cuco:refresh_participants_evt');
          appEvent.setParams({
            'contextId': cmp.get('v.recordId')
          });
          appEvent.fire();
          // Refresh participants evt
          let appEventCommPartRemove = $A.get('e.cuco:refresh_comm_packages_evt');
          appEventCommPartRemove.setParams({
            'contextId': cmp.get('v.profAnId')
          });
          appEventCommPartRemove.fire();
          // Refresh forfait packages evt
          let appEventForfaitPartRemove = $A.get('e.cuco:refresh_forfait_packages_evt');
          appEventForfaitPartRemove.setParams({
            'contextId': cmp.get('v.profAnId')
          });
          appEventForfaitPartRemove.fire();
          // Refresh gip package evt
          let appEventGipPartRemove = $A.get('e.cuco:refresh_gip_packages_evt');
          appEventGipPartRemove.setParams({
            'contextId': cmp.get('v.profAnId')
          });
          appEventGipPartRemove.fire();
          // Refresh flat evt
          let appEventFlatRefreshFlat = $A.get('e.cuco:refresh_flat_rates_evt');
          appEventFlatRefreshFlat.setParams({
            'contextId': cmp.get('v.profAnId')
          });
          appEventFlatRefreshFlat.fire();
        } else {
          helper.showToast('Error', 'error', $A.get("$Label.c.cuco_move_error"));
        }
        helper.destroyCmp(cmp, evt, helper);
      } else if(state === 'INCOMPLETE'){
        console.log('INCOMPLETE', response);
      } else if(state === 'ERROR') {
        var errors = response.getError();
        console.error('Error message: ' + errors[0].message);
      }
      helper.doneWaiting(cmp);
    });
    $A.enqueueAction(action);
  },
  showToast: function(type, title, message) {
    var toastEvent = $A.get('e.force:showToast');
    toastEvent.setParams({
      title: title,
      message: message,
      duration: 5000,
      key: 'info_alt',
      type: type,
      mode: 'dismissible'
    });
    toastEvent.fire();
  },
  waiting: function(cmp) {
    cmp.set('v.waiting', true);
  },
  doneWaiting: function(cmp) {
    cmp.set('v.waiting', false);
  },
})