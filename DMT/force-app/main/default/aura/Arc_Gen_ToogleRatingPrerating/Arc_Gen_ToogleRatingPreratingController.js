({
  getItemEvent: function(component, event, helper) {
    if (event.getParam('IdItem') != null && event.getParam('IdItem') !== undefined  && event.getParam('nameEvent') === 'Arc_Gen_Carousel') {  // eslint-disable-line
      component.set('v.view', false);
      component.set('v.ahaId', event.getParam('IdItem'));
      helper.getInitialInfo(component, event, helper);
    }
  },
  handleToggleChange: function(component, event, helper) {
    component.set('v.updating', true);
    helper.toggleChange(component, event, helper);
  }
});