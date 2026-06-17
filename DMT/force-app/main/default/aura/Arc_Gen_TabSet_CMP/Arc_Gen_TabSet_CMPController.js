({
  getItemEvent: function(component, event, helper) {
    if (event.getParam('IdItem') != null && event.getParam('IdItem') !== undefined  && event.getParam('nameEvent') === 'Arc_Gen_Carousel') {  // eslint-disable-line
      component.set('v.view', false);
      component.set('v.idSelect', event.getParam('IdItem'));
      component.set('v.selectedTab', null);
      helper.loadTabsetConfig(component, event, helper);
    }
  },
  loadTabsetConfig: function(component, event, helper) {
    component.set('v.view', false);
    helper.loadTabsetConfig(component, event, helper);
  },
  update: function(component, event, helper) {
    component.destroy();
  },
  handleSaveEvent: function(component, event, helper) {
    let promise = helper.callClassCompletitud(component, event);
    promise.then(function(resolve, reject) {
      let promise2 = helper.calculatePercentage(component, event);
      promise2.then(function(resolve2) {
        let promise3 = helper.restorePercentage(component, event);
        promise3.then(function(resolve3) {
          if (resolve3) {
            var changeMiniStattus = component.get('v.changeArceState');
            if (changeMiniStattus === true) {
              $A.get('e.force:refreshView').fire();
            } else {
              helper.policieTabStatus(component, event, helper, resolve3);
              component.set('v.sectionsLts', resolve3);
            }
            if (component.get('v.unitMessage') !== 'SameUnit') {
              helper.showToast(component, event, component.get('v.unitMessage'));
            }
          }
        });
      });
    });
  },
  handleSelect: function(component, event, helper) {
    const tabsetDisabled = component.get('v.tabsetDisabled');
    const currentTab = component.get('v.selectedTab');

    if (!tabsetDisabled && currentTab !== event.getParam('id')) {
      component.set('v.selectedTab', event.getParam('id'));
      component.set('v.tabsetDisabled', true);
    }
  },
  handleDyfrLoaded: function(component) {
    component.set('v.tabsetDisabled', false);
  }
});