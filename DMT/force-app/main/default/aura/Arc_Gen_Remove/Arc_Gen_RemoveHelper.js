({
  executeSave: function(component) {
    var inputAttributes = component.get('v.inputAttributes');
    var reasonDesc = component.find('reasonDesc').get('v.value');
    var reasonPick = component.get('v.reasonValue');
    var reasonPickLabel = component.get('v.reasonValueLabel');
    var action = component.get('c.updateRemoveInfo');
    var okMsg = $A.get('{!$Label.c.Arc_Gen_Record_Update_Success}');
    action.setParams({
      'recordId': inputAttributes.recordId,
      'reasonPick': reasonPick,
      'reasonPickLabel': reasonPickLabel,
      'reasonDesc': reasonDesc
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        this.showToast('success', okMsg);
        this.refresh(component);
      } else {
        this.showToast('error', response.getError()[0].message);
      }
    });
    $A.enqueueAction(action);
  },
  setupReasonLabel: function(component, event, helper) {
    var list = component.get('v.listReasons');
    var currentLabel =  list.filter(function(option) {
      return option.value === event.getParam('value');
    });
    component.set('v.reasonValueLabel', currentLabel[0].label);
  },
  getReasonList: function(component) {
    var action = component.get('c.getDiscardList');
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var arr = response.getReturnValue();
        component.set('v.listReasons', arr);
        component.set('v.spinnerStatus', false);
      } else {
        this.showToast('error', response.getError()[0].message);
      }
    });
    $A.enqueueAction(action);
  },
  showToast: function(type, message) {
    var toastEventUE = $A.get('e.force:showToast');
    toastEventUE.setParams({
      'title': '',
      'type': type,
      'mode': 'sticky',
      'duration': '8000',
      'message': message
    });
    toastEventUE.fire();
  },
  refresh: function(component) {
    window.location.reload();
  }
});