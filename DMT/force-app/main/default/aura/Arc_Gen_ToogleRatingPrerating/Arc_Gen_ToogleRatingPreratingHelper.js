({
  toggleChange: function(component, event, helper) {
    var toggleName = event.getSource().get('v.name');
    var checked = event.getSource().get('v.checked');
    if (toggleName === 'Rating') {
      component.set('v.isRating', checked);
      component.set('v.isPreRating', !checked);
    } else if (toggleName === 'PreRating') {
      component.set('v.isPreRating', checked);
      component.set('v.isRating', !checked);
    }
    helper.setRatingTypeSelected(component, event, helper, component.get('v.isRating'));
  },
  setRatingTypeSelected: function(component, event, helper, isRating) {
    let ratingType = isRating ? 'Rating' : 'Prerating';
    var action = component.get('c.setRatingTypeSelected');
    action.setParams({
      ahaId: component.get('v.ahaId'),
      ratingType: ratingType,
    });
    action.setCallback(this, function(response) {
      if (response.getState() === 'SUCCESS') {
        var resp = JSON.parse(response.getReturnValue());
        if (resp.state === 'OK') {
          window.location.reload();
        } else {
          helper.resetToogleValues(component);
          component.set('v.updating', false);
        }
      } else {
        helper.resetToogleValues(component);
        component.set('v.updating', false);
      }
    });
    $A.enqueueAction(action);
  },
  getInitialInfo: function(component, event, helper, isRating) {
    var action = component.get('c.getInitInfo');
    action.setParams({
      ahaId: component.get('v.ahaId')
    });
    action.setCallback(this, function(response) {
      if (response.getState() === 'SUCCESS') {
        let modelsShowToogle = component.get('v.modelsShowToogle');
        var resp = JSON.parse(response.getReturnValue());
        if (!resp.hasOwnProperty('errorMssg') && resp.hasOwnProperty('state') && resp.state === 'OK' && modelsShowToogle !== '') {
          let listModels = modelsShowToogle.includes(';') ? modelsShowToogle.split(';') : modelsShowToogle;
          if (listModels.includes(resp.ratingTool) && resp.stage === '1') {
            component.set('v.view', true);
            helper.setInitRatingType(component, resp.ratingType);
          }
        } else {
          console.log('There was an error retrieving current rating type');
        }
      }
    });
    $A.enqueueAction(action);
  },
  setInitRatingType: function(component, ratingType) {
    if (ratingType === 'Prerating') {
      component.set('v.isRating', false);
      component.set('v.isPreRating', true);
    } else {
      component.set('v.isRating', true);
      component.set('v.isPreRating', false);
    }
  },
  resetToogleValues: function(component) {
    let isRatingSaved = component.get('v.isRating');
    let isPreRatingSaved = component.set('v.isPreRating');
    component.set('v.isRating', !isRatingSaved);
    component.set('v.isPreRating', !isPreRatingSaved);
  },
  fireToast: function(type, time, message) {
    let toastError = $A.get('e.force:showToast');
    toastError.setParams({
      title: type + '!',
      type: type.toLowerCase(),
      message: message,
      duration: time,
    });
    toastError.fire();
  }
});