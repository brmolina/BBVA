({
  hinit: function(component, event) {
    var action = component.get('c.getProducts');
    action.setParams({
      'tipologia': component.get('v.tipology')
    });
    action.setCallback(this, function(response) {
      var estado = response.getState();
      if (estado === 'SUCCESS') {
        var respuesta = response.getReturnValue();
        if (respuesta.successResponse === true) {
          component.set('v.listProducts', respuesta.gblProductResp);
          component.set('v.spinnerStatus', false);
          component.set('v.typologyId', respuesta.limitTypologyId);
        } else {
          component.set('v.error', true);
        }
      }
    });
    $A.enqueueAction(action);
  },
  honSubmit: function(component11, event, helper) {
    var fields = event.getParam('fields');
    let term = fields.arce__current_apprv_limit_term_type__c;
    let importValue = fields.arce__current_proposed_amount__c;
    if (!term || !importValue || importValue < 0) {
      component11.set('v.error', true);
      component11.set('v.insertSubmit', false);
      component11.set('v.errorMessageFields', true);
      setTimeout($A.getCallback(function() {
        component11.set('v.error', false);
        component11.set('v.errorMessageId', false);
      }), 5000);
    } else {
      if (component11.get('v.inputClass') === 'default') {
        helper.insertRecordsDefault(component11, event, helper);
      } else {
        helper.insertAutoRecords(component11, event, helper);
      }
    }
  },
  insertRecordsDefault: function(component, event, helper) {
    var fields = event.getParam('fields');
    let ProductId = component.get('v.selectedChild');
    fields.arce__account_has_analysis_id__c = component.get('v.accHasAId');
    fields.arce__limits_exposures_parent_id__c = component.get('v.parentId');
    fields.arce__Product_id__c = ProductId;
    fields.arce__limits_typology_id__c = component.get('v.typologyId');
    var campos1 = this.update2ZeroFields(fields);
    component.find('myform').submit(campos1);
  },
  insertAutoRecords: function(component, event, helper) {
    var fields = event.getParam('fields');
    fields.arce__account_has_analysis_id__c = component.get('v.accHasAId');
    fields.arce__limits_exposures_parent_id__c = component.get('v.parentId');
    fields.arce__Product_id__c = component.get('v.selectedChild');
    fields.arce__limits_typology_id__c = component.get('v.typologyId');
    component.find('myform').submit(fields);
  },
  update2ZeroFields: function(fields) {
    var fieldExposures = ['arce__last_approved_amount__c', 'arce__curr_approved_commited_amount__c', 'arce__curr_apprv_uncommited_amount__c',
      'arce__current_formalized_amount__c', 'arce__outstanding_amount__c', 'arce__current_proposed_amount__c', 'arce__current_approved_amount__c'];
    for (var i = 0; i < fieldExposures.length; i++) {
      for (var fiel in fields) {
        if (fiel === fieldExposures[i] && (fields[fiel] < 0 || !fields[fiel])) {
          fields[fiel] = 0;
        }
      }
    }
    return fields;
  },
  deactivateValidFlag: function(component) {
    var action = component.get('c.desactivateValidFlag');
    action.setParams({
      'recordId': component.get('v.accHasAId'),
      'desactivate': 'desactivate'
    });
    return new Promise($A.getCallback(function(resolve, reject) {
      action.setCallback(this, function(response) {
        var state1 = response.getState();
        if (state1 === 'SUCCESS') {
          var respo = response.getReturnValue();
          component.set('v.changeStatus', respo.successResponse);
          resolve();
        } else {
          reject($A.get('$Label.c.Arc_Gen_ApexCallError'));
        }
      });
      $A.enqueueAction(action);
    }));
  },
  updateLimitsFromService: function(component, event, helper, newRecordId) {
    var action = component.get('c.insertProducts');
    action.setParams({
      'accHasAId': component.get('v.accHasAId'),
      'tipologia': component.get('v.tipology'),
      'prodId': component.get('v.selectedChild'),
      'recordId': newRecordId
    });
    return new Promise($A.getCallback(function(resolve, reject) {
      action.setCallback(this, function(response) {
        if (response.getState() === 'SUCCESS') {
          let resp = response.getReturnValue();
          if (resp.successResponse === true) {
            helper.persistenceService(component, event, helper, event.getParam('id'))
              .then(function() {
                resolve();
              })
              .catch(function(err) {
                reject(err);
              });
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
  showErrorToast: function(message) {
    const toastEvent = $A.get('e.force:showToast');
    toastEvent.setParams({
      'title': $A.get('$Label.c.Cls_arce_GRP_glbError'),
      'message': message,
      'type': 'error'
    });
    toastEvent.fire();
  },
  persistenceService: function(component, event, helper, newRecordId) {
    var action = component.get('c.addLimitPersService');
    action.setParams({
      'accHasAId': component.get('v.accHasAId'),
      'limitId': newRecordId
    });
    return new Promise($A.getCallback(function(resolve, reject) {
      action.setCallback(this, function(response4) {
        if (response4.getState() === 'SUCCESS') {
          let resp2 = response4.getReturnValue();
          if (resp2) {
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
  updateStatusLimitPers: function(component14) {
    var action = component14.get('c.updateStatusLimitPers');
    action.setParams({
      'accHasId': component14.get('v.accHasAId'),
      'callout': false
    });
    $A.enqueueAction(action);
  }
});