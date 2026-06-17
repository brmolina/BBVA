({
	StarFlow: function (component) {
    var IsVisibles = component.get('v.IsVisible');
    var inputVariables = [{
      name: 'recordId',
      type: 'SObject',
      value: component.get('v.recordId')
    }];
    console.log(IsVisibles);
    if (IsVisibles == false) {
      var flow = component.find('Pitch_FileUpload');
      flow.startFlow('pith__Pitch_FileUpload', inputVariables);
    }
  },
  GetV: function (component, event) {
    var recordId = component.get('v.recordId');
    var action = component.get('c.getCreated');
    var start = component.find('Start');
    action.setParams({
      'recordId': recordId
    });
    action.setCallback(this, function (response) {
      if (response.getState() === 'SUCCESS') {
        $A.util.addClass(start, 'slds-show');
        $A.util.removeClass(start, 'slds-hide');
        component.set('v.IsVisible', response.getReturnValue());
      }

    });
    $A.enqueueAction(action);
  }
})