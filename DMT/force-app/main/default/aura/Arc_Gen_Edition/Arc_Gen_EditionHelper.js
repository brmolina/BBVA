({
  hsaveFields: function(component, event) {
    event.preventDefault();
    var fields = event.getParam('fields');
    var campos1 = [];
    if (component.get('v.producto') === true) {
      let term = fields.arce__current_apprv_limit_term_type__c;
      let importValue = fields.arce__current_proposed_amount__c;
      if (!term || !importValue || importValue < 0) {
        component.set('v.error', true);
        component.set('v.insertSubmit', false);
        setTimeout($A.getCallback(function() {
          component.set('v.error', false);
        }), 5000);
      } else {
        campos1 = this.update2ZeroFields1(fields);
        component.find('EditForm').submit(campos1);
      }
    } else if (component.get('v.tipology') === 'TP_0013' || component.get('v.tipology') === 'TP_0003' || component.get('v.tipology') === 'TP_0006') {
      component.set('v.sumTypo', true);
      campos1 = this.update2ZeroFields1(fields);
      component.find('EditForm').submit(campos1);
    } else {
      campos1 = this.update2ZeroFields1(fields);
      component.find('EditForm').submit(campos1);
    }
  },
  hhandleSaveSuccess: function(component7) {
    var action = component7.get('c.desactivateValidFlag');
    action.setParams({
      'recordId': component7.get('v.accHasAId'),
      'desactivate': 'desactivate',
      'limitId': component7.get('v.recordId')
    });
    return new Promise($A.getCallback(function(resolve, reject) {
      action.setCallback(this, function(response) {
        var state = response.getState();
        if (state === 'SUCCESS') {
          var respo = response.getReturnValue();
          component7.set('v.changeStatus', respo.successResponse);
          resolve();
        } else {
          component7.set('v.changeStatus', false);
          reject($A.get('$Label.c.Arc_Gen_ApexCallError'));
        }
      });
      $A.enqueueAction(action);
    }));
  },
  sumTypos: function(component) {
    return new Promise($A.getCallback(function(resolve, reject) {
      if (component.get('v.sumTypo') === true) {
        var action = component.get('c.sumTypologies');
        action.setParams({
          'recordId': component.get('v.accHasAId')
        });
        action.setCallback(this, function(response) {
          var state = response.getState();
          if (state === 'SUCCESS') {
            component.set('v.sumTyposId', response.getReturnValue());
            resolve();
          } else {
            reject($A.get('$Label.c.Arc_Gen_ApexCallError'));
          }
        });
        $A.enqueueAction(action);
      } else {
        resolve();
      }
    }));
  },
  update2ZeroFields1: function(fields) {
    var fieldsExposure = ['arce__last_approved_amount__c', 'arce__curr_approved_commited_amount__c', 'arce__curr_apprv_uncommited_amount__c',
      'arce__current_formalized_amount__c', 'arce__outstanding_amount__c', 'arce__current_proposed_amount__c', 'arce__current_approved_amount__c'];
    for (var i = 0; i < fieldsExposure.length; i++) {
      for (var field in fields) {
        if (field === fieldsExposure[i] && (fields[field] < 0 || !fields[field])) {
          fields[field] = 0;
        }
      }
    }
    return fields;
  },
  showErrorToast: function(message) {
    const toastEvent = $A.get('e.force:showToast');
    toastEvent.setParams({
      'title': $A.get('$Label.c.Cls_arce_GRP_glbError'),
      'message': message,
      'type': 'error'
    });
    toastEvent.fire();
  },
  updateAhaLimits: function(component, event, helper) {
    var action = component.get('c.setLimitsToAha');
    action.setParams({
      'accHasAnId': component.get('v.accHasAId')
    });
    return new Promise($A.getCallback(function(resolve, reject) {
      action.setCallback(this, function(response) {
        var state = response.getState();
        if (state === 'SUCCESS') {
          var resp = JSON.parse(response.getReturnValue());
          if (resp.status === 'true') {
            if (component.get('v.sumTyposId') === null || component.get('v.sumTyposId') === undefined) {
              helper.persistenceService(component, event.getParam('id'))
                .then(function() {
                  resolve();
                })
                .catch(function(err) {
                  reject(err);
                });
            } else {
              helper.persistenceService(component, component.get('v.sumTyposId'))
                .then(function() {
                  helper.persistenceService(component, event.getParam('id'))
                    .then(function() {
                      resolve();
                    })
                    .catch(function(err) {
                      reject(err);
                    });
                })
                .catch(function(err) {
                  reject(err);
                });
            }
          } else {
            reject($A.get('$Label.c.Arc_Gen_ErrorService'));
          }
        } else {
          reject($A.get('$Label.c.Arc_Gen_ApexCallError'));
        }
      });
      $A.enqueueAction(action);
    }));
  },
  persistenceService: function(component, limitId) {
    var action = component.get('c.addLimitPersService');
    action.setParams({
      'accHasAId': component.get('v.accHasAId'),
      'limitId': limitId
    });
    return new Promise($A.getCallback(function(resolve, reject) {
      action.setCallback(this, function(response3) {
        var state = response3.getState();
        if (state === 'SUCCESS') {
          var resp1 = response3.getReturnValue();
          if (resp1) {
            resolve();
          } else {
            reject($A.get('$Label.c.Arc_Gen_ServicePersistenceError'));
          }
        } else {
          reject($A.get('$Label.c.Arc_Gen_ApexCallError'));
        }
      });
      $A.enqueueAction(action);
    }));
  },
  updateStatusLimitPers: function(component13) {
    var action = component13.get('c.updateStatusLimitPers');
    action.setParams({
      'accHasId': component13.get('v.accHasAId'),
      'callout': false
    });
    $A.enqueueAction(action);
  }
});