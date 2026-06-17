({
  getRatingData: function(component, helper) {
    var action = component.get('c.getRatingData');
    action.setParams({
      analysisId: component.get('v.hasRecordId')
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var resp = response.getReturnValue();
        component.set('v.ratingId', resp.ratingId);
        component.set('v.ratingFinal', resp.ratingFinal);
        component.set('v.ratingScore', resp.ratingScore);
        component.set('v.subProcessType', resp.subProcessType);
        component.set('v.loading', false);
        component.set('v.showScore', true);
      } else {
        component.set('v.show', false);
        helper.showToast('error', response.getError()[0].message);
        $A.get('e.force:closeQuickAction').fire();
        if (component.get('v.isRAIP')) {
          component.getEvent('ValidateRatingRAIPClose').fire();
        }
      }
    });
    $A.enqueueAction(action);
  },
  validating: function(component, helper) {
    var action = component.get('c.changeStatus');
    action.setParams({
      analysisId: component.get('v.hasRecordId'),
      ratingId: component.get('v.ratingId'),
      isRaip: component.get('v.isRAIP')
    });
    action.setCallback(this, function(response) {
      var resp = response.getReturnValue();
      var state = response.getState();
      if (state === 'SUCCESS') {
        if (resp.serviceCode === '200' && resp.saveStatus === 'true') {
          component.set('v.loading', false);
          component.set('v.success', 'yes');
          var analysisIdref = component.get('v.hasRecordId');
          var tabRefresh = $A.get('e.dyfr:SaveObject_evt');
          tabRefresh.setParams({
            'recordId': analysisIdref
          });
          tabRefresh.fire();
          if (component.get('v.subProcessType') === '4') {
            window.location.reload();
            $A.get('e.force:closeQuickAction').fire();
          } else {
            window.setTimeout($A.getCallback(function() {
              $A.get('e.force:refreshView').fire();
            }), 2500);
          }
        } else if (resp.serviceCode !== '200') {
          component.set('v.loading', false);
          component.set('v.success', 'no');
          var errorWrapper = JSON.parse(resp.serviceMessage);
          component.set('v.errorCode', $A.get('{!$Label.c.Arc_Gen_RatingError_ErrorCode}') + ' ' + errorWrapper.errorCode);
          component.set('v.errorTitle', errorWrapper.errorTitle);
          component.set('v.message', errorWrapper.errorMessage);
          component.set('v.success', 'no');
        }
        if (resp.saveStatus === 'false') {
          component.set('v.message', $A.get('{!$Label.c.Lc_arce_newAnalysisError}') + resp.saveMessage);
          component.set('v.success', 'no');
        }
      } else {
        component.set('v.show', false);
        component.set('v.success', 'no');
        helper.showToast('error', ' : ' + response.getError()[0].message);
        $A.get('e.force:closeQuickAction').fire();
        if (component.get('v.isRAIP')) {
          component.getEvent('ValidateRatingRAIPClose').fire();
        }
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
  }
});