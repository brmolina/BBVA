({
  getAHA: function(component, event, helper) {
    return new Promise($A.getCallback(function(resolve, reject) {
      var action = component.get('c.getAHARefresh');
      var recordId = component.get('v.inputAttributes').recordId;
      action.setParams({
        'recordId': recordId
      });
      action.setCallback(this, function(response) {
        var state = response.getState();
        if (state === 'SUCCESS') {
          var resp = response.getReturnValue();
          var groupid = '';
          var groupnumber = '';
          var ahaswithoutgroup = [];
          var ahaswithoutgroupnumber = [];
          var groupname = '';
          var accWrapers = [];
          var arceId = '';
          var currentAhaAccNumber;
          for (var x of resp) {
            if (x.ahaObj.Id === recordId) {
              currentAhaAccNumber = x.accWrapperObj.accNumber;
            }
            if (x.ahaObj.arce__group_asset_header_type__c === '1') {
              groupid = x.ahaObj.Id;
              groupnumber = x.accWrapperObj.accNumber;
              groupname = x.accWrapperObj.name;
              arceId = x.ahaObj.arce__Analysis__c;
              accWrapers.push(x.accWrapperObj);
            } else {
              ahaswithoutgroup.push(x.ahaObj.Id);
              ahaswithoutgroupnumber.push(x.accWrapperObj.accNumber);
              accWrapers.push(x.accWrapperObj);
            }
          }
          component.set('v.groupid', groupid);
          component.set('v.groupname', groupname);
          component.set('v.groupnumber', groupnumber);
          component.set('v.ahaswithoutgroup', ahaswithoutgroup);
          component.set('v.ahaswithoutgroupnumber', ahaswithoutgroupnumber);
          component.set('v.accountWrapLts', JSON.stringify(accWrapers));
          component.set('v.currentAhaAccNumber', currentAhaAccNumber);
          component.set('v.arceId', arceId);
          resolve();
        } else {
          helper.cancelAction(component, helper);
          reject();
        }
      });
      $A.enqueueAction(action);
    }));
  },
  callServices: function(component, event, helper) {
    /* HEADER AND SUBSIDIARY CLIENTS */
    if (component.get('v.groupid') !== '') {
      let promise2 = helper.listParticipant(component, event, helper);
      promise2.then(function() {
        return helper.listCustomers(component, event, helper);
      }).then(function() {
        return helper.updateFinancialSponsor(component, event, helper);
      }).then(function() {
        return helper.callEcoGroupParticipantsPer(component, event, helper);
      }).then(function() {
        component.set('v.refreshSpinner', 'false');
        component.set('v.refreshMessage', $A.get('{!$Label.c.Arc_Gen_RefreshProperly}'));
      });
    /* ORPHAN CLIENT */
    } else if (component.get('v.groupid') === '' && component.get('v.ahaswithoutgroup') !== null) {
      let promise = helper.economicParticipants(component);
      promise.then(function() {
        return helper.listParticipantOrphan(component, helper);
      }).then(function() {
        return helper.updateGroupStructure(component);
      }).then(function() {
        component.set('v.refreshSpinner', 'false');
        component.set('v.refreshMessage', $A.get('{!$Label.c.Arc_Gen_RefreshProperly}'));
      });
    }
  },
  listParticipant: function(component, event, helper) {
    return new Promise($A.getCallback(function(resolve, reject) {
      var componentTarget = component.find('changespin');
      $A.util.removeClass(componentTarget, 'getingdata');
      $A.util.addClass(componentTarget, 'listparticip');

      var action = component.get('c.getListParticipants');
      action.setParams({
        'encryptedgroup': component.get('v.groupnumber'),
        'ahaswithoutgroup': component.get('v.ahaswithoutgroup'),
        'ahaswithoutgroupnumber': component.get('v.ahaswithoutgroupnumber'),
        'recordId': component.get('v.groupid')
      });
      action.setCallback(this, helper.getListParticipantsHandler(component, resolve, reject));
      $A.enqueueAction(action);
    }));
  },
  getListParticipantsHandler: function(component, resolve, reject) {
    return function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var resp = JSON.parse(response.getReturnValue());
        if (resp.servicecallerror || resp.errormessage) {
          component.set('v.refreshSpinner', 'false');
          component.set('v.refreshMessage', $A.get('{!$Label.c.Arc_Gen_SpinnerMessageError}') + '..');
          reject();
        } else if (resp.error204message) {
          component.set('v.refreshSpinner', 'false');
          component.set('v.refreshMessage', resp.error204message + '..');
          reject();
        } else {
          component.set('v.listparticipant', response.getReturnValue());
          resolve();
        }
      } else {
        component.set('v.refreshSpinner', false);
        component.set('v.refreshMessage', response.getError()[0].message);
        reject();
      }
    };
  },
  listCustomers: function(component, event, helper) {
    return new Promise($A.getCallback(function(resolve, reject) {
      var idSelected = component.get('v.inputAttributes').recordId;
      let action = component.get('c.callListCustomers');
      action.setParams({
        recordId: idSelected
      });
      action.setCallback(this, function(response) {
        var state = response.getState();
        var resp = response.getReturnValue();
        if (state === 'SUCCESS') {
          if (resp.message && resp.serviceStatus === 'KO') {
            component.set('v.refreshSpinner', false);
            component.set('v.refreshMessage', $A.get('{!$Label.c.Arc_Gen_SpinnerMessageError}') + '.....');
            component.set('v.resolvelistcust', false);
            reject();
          } else {
            component.set('v.resolvelistcust', true);
            resolve();
          }
        } else {
          component.set('v.refreshSpinner', false);
          component.set('v.refreshMessage', $A.get('{!$Label.c.Arc_Gen_SpinnerMessageError}') + '.....');
          component.set('v.resolvelistcust', false);
          reject();
        }
      });
      $A.enqueueAction(action);
    }));
  },
  updateFinancialSponsor: function(component, event, helper) {
    return new Promise($A.getCallback(function(resolve, reject) {
      var idSelected = component.get('v.inputAttributes').recordId;
      let action = component.get('c.refreshFinancialSponsor');
      action.setParams({
        ahaId: idSelected
      });
      action.setCallback(this, function(response) {
        var state = response.getState();
        var resp = response.getReturnValue();
        if (state === 'SUCCESS') {
          if (resp.serviceCode === '200') {
            resolve(resp);
          } else if (resp.serviceCode === '204') {
            helper.showToast($A.get('{!$Label.c.Lc_arce_redirectingURL}'), 'error', resp.serviceMessage);
            window.setTimeout(
              $A.getCallback(function() {
                helper.cancelAction(component);
              }), 5000
            );
            reject();
          }
        } else {
          component.set('v.refreshSpinner', false);
          component.set('v.refreshMessage', $A.get('{!$Label.c.Arc_Gen_SpinnerMessageError}') + '.....');
          reject();
        }
      });
      $A.enqueueAction(action);
    }));
  },
  cancelAction: function(component) {
    window.location.reload();
  },
  callEcoGroupParticipantsPer: function(component, event, helper) {
    return new Promise($A.getCallback(function(resolve, reject) {
      var action = component.get('c.callEcoGroupParticipantsPersistence');
      action.setParams({
        listparticipant: component.get('v.listparticipant'),
        accParticipants: component.get('v.accountWrapLts'),
        analysisId: component.get('v.arceId')
      });
      action.setCallback(this, function(response) {
        if (response.getState() === 'SUCCESS') {
          var resp = response.getReturnValue();
          if (resp.serviceCode !== '200' && resp.serviceCode !== '201' && resp.serviceCode !== '204') {
            component.set('v.refreshSpinner', false);
            component.set('v.refreshMessage', $A.get('{!$Label.c.Arc_Gen_SpinnerMessageError}') + '...');
            reject();
          } else {
            resolve();
          }
        } else {
          component.set('v.refreshSpinner', false);
          component.set('v.refreshMessage', response.getError()[0].message);
          reject();
        }
      });
      $A.enqueueAction(action);
    }));
  },

  /* METHODS FOR ORPHAN REFRESH. */
  economicParticipants: function(component) {
    var action = component.get('c.callEconomicParticipants');
    action.setParams({
      'encryptedClient': component.get('v.currentAhaAccNumber'),
      'recordId': component.get('v.inputAttributes').recordId
    });

    return new Promise($A.getCallback(function(resolve, reject) {
      action.setCallback(this, function(response) {
        var state = response.getState();
        if (state === 'SUCCESS') {
          var parsedResp = JSON.parse(response.getReturnValue());
          component.set('v.economicParticipants', response.getReturnValue());
          component.set('v.groupnumber', parsedResp.groupinfo.decryptedgroupid);
          resolve();
        } else {
          component.set('v.refreshSpinner', false);
          component.set('v.refreshMessage', response.getError()[0].message);
          reject();
        }
      });

      $A.enqueueAction(action);
    }));
  },

  listParticipantOrphan: function(component, helper) {
    var action = component.get('c.getListParticipantsOrphan');
    action.setParams({
      'encryptedClient': component.get('v.groupnumber'),
      'recordId': component.get('v.inputAttributes').recordId
    });

    return new Promise($A.getCallback(function(resolve, reject) {
      action.setCallback(this, helper.getListParticipantsHandler(component, resolve, reject));

      $A.enqueueAction(action);
    }));
  },

  updateGroupStructure: function(component) {
    var action = component.get('c.constructGroupStructure');
    action.setParams({
      'listparticipant': component.get('v.listparticipant'),
      'economicparticipant': component.get('v.economicParticipants'),
      'recordId': component.get('v.inputAttributes').recordId
    });

    return new Promise($A.getCallback(function(resolve, reject) {
      action.setCallback(this, function(response) {
        var state = response.getState();
        if (state === 'SUCCESS') {
          component.set('v.groupId', response.getReturnValue());
          resolve();
        } else {
          component.set('v.refreshSpinner', false);
          component.set('v.refreshMessage', response.getError()[0].message);
          reject();
        }
      });

      $A.enqueueAction(action);
    }));
  },

  showToast: function(title, type, message) {
    var toast = $A.get('e.force:showToast');
    toast.setParams({
      'title': title,
      'type': type,
      'message': message,
      'duration': '10000'
    });
    toast.fire();
  }
});