({
  doInit: function(component, event, helper) {
    component.set('v.isOpen', true);
    var idrecord = component.get('v.inputAttributes').recordId;
    var flow = component.find('modifyBusinessPlan');
    var inputVariables = [
      { name: 'recordId', type: 'String', value: idrecord } ];
    flow.startFlow('AccountPlanningNewBPVersion', inputVariables);
  },
  closeFlowModal: function(component, event, helper) {
    component.set('v.isOpen', false);
  },
  closeModalOnFinish: function(component, event, helper) {
    if (event.getParam('status') === 'FINISHED') {
      component.set('v.isOpen', false);
    }
  }
});