({//eslint-disable-line
  cargarFielSet: function(component, event, helper) {
    var headerText = component.get('v.headerText') || '';
    var isAdditionalRT = component.get('v.isAdditionalRT');
    isAdditionalRT = isAdditionalRT === true || isAdditionalRT === 'true';
    component.set('v.isAdditionalRT', isAdditionalRT);
    component.set('v.showMakeMatrixCheckbox', isAdditionalRT || headerText.toLowerCase().indexOf('subsidiary') !== -1);

    var actionCtrl = component.get('c.getFieldSetFromAccount');
    actionCtrl.setParams({
      'isAdditional': isAdditionalRT,
    });
    actionCtrl.setCallback(this, function(response) {
      if (response.getState() === 'SUCCESS' && response.getReturnValue() !== null && response.getReturnValue() !== undefined) {
        var resultData = JSON.parse(response.getReturnValue());
        resultData = this.setFieldsValues(component, resultData);

        //component.set('v.Fields', resultData);
        component.set('v.recordTypeId', resultData.recordType);
        component.set('v.columns', resultData.wrapperList);
        if (resultData.customIdsJSON !== undefined && resultData.customIdsJSON !== null) {
          component.set('v.customIdsResponse', resultData.customIdsJSON);
        }
        if (component.get('v.isOnDesktop') !== 'DESKTOP') {
          this.getLookUpField(component, event, helper);
        } else {
          this.helpText(component, event, helper);
        }
      } else {
        var toastEvent = $A.get('e.force:showToast');
        toastEvent.setParams({
          title: '',
          type: 'error',
          mode: 'dismissible',
          message: $A.get('$Label.c.Contact_your_Admin')
        });
        toastEvent.fire();
      }
    });
    $A.enqueueAction(actionCtrl);
  },
  setFieldsValues: function(component, resultData) {
    if (component.get('v.getDataFirstScreen') !== undefined && component.get('v.getDataFirstScreen') !== null && component.get('v.getDataFirstScreen') !== '') {
      var datosAIntroducir = JSON.parse(component.get('v.getDataFirstScreen'));
      for (var key in datosAIntroducir) {
        if ({}.hasOwnProperty.call(datosAIntroducir, key)) {
          for (var i = 0; i < resultData.wrapperList.length; i++) {
            if (resultData.wrapperList[i].fieldAPIName === key) {
              resultData.wrapperList[i].fieldValue = datosAIntroducir[key];
              resultData.wrapperList[i].disable = datosAIntroducir[key];
            }
          }
        }
      }
    } else {
      for (var k = 0; k < resultData.wrapperList.length; k++) {
        if (resultData.wrapperList[k].fieldAPIName === 'Name') {
          resultData.wrapperList[k].fieldValue = component.get('v.clientName');
        }
      }
    }

    for (var j = 0; j < resultData.wrapperList.length; j++) {
      if (resultData.wrapperList[j].fieldAPIName === 'CIB_Commercial_Prospect__c' &&
        (resultData.wrapperList[j].fieldValue === undefined || resultData.wrapperList[j].fieldValue === null || resultData.wrapperList[j].fieldValue === '')) {
        resultData.wrapperList[j].fieldValue = 'CIB';
      }
    }

    return resultData;
  },
  getLookUpField: function(component, event, helper) {
    var actionCtrl = component.get('c.getFieldLookup');
    actionCtrl.setParams({
      'recordTypeID': component.get('v.recordTypeId'),
    });
    actionCtrl.setCallback(this, function(response) {
      if (response.getState() === 'SUCCESS' && response.getReturnValue() !== null && response.getReturnValue() !== undefined && response.getReturnValue() !== 'null') {
        var resultData = JSON.parse(response.getReturnValue());
        component.set('v.lookUpFieldAPIName', resultData.lookupField);
        component.set('v.lookUpQueryWhere', resultData.whereField);
        component.set('v.lookUpFieldLabel', resultData.lookupFieldLabel);
      }
      this.helpText(component, event, helper);
    });
    $A.enqueueAction(actionCtrl);
  },
  helpText: function(component, event, helper) {
    var actionCtrl = component.get('c.getHelpText');
    actionCtrl.setCallback(this, function(response) {
      if (response.getState() === 'SUCCESS' && response.getReturnValue() !== null && response.getReturnValue() !== undefined && response.getReturnValue() !== 'null') {
        var resultData = JSON.parse(response.getReturnValue());
        component.set('v.helpText', resultData);
      }
    });
    $A.enqueueAction(actionCtrl);
  },
  backModal: function(component, event, helper) {
    var cmpEvent = component.getEvent('cmpEvent');
    cmpEvent.setParams({
      'message': 'Back component'
    });
    cmpEvent.fire();
    component.destroy();
  },
  closeModal: function(component, event, helper) {
    var isOnAccount = component.get('v.isOnAccount');
    if (component.get('v.isOnDesktop') !== 'DESKTOP') {
      var homeEvent = $A.get('e.force:navigateToObjectHome');
      homeEvent.setParams({
        'scope': 'Account'
      });
      homeEvent.fire();
    }
    if (isOnAccount) {
      $A.get('e.force:navigateToURL').setParams({ 'url': '/lightning/o/Account/home' }).fire();
    }

    //$A.get('e.force:refreshView').fire();
    var cmpEvent = component.getEvent('cmpEvent');
    cmpEvent.setParams({
      'message': 'Close component'
    });
    cmpEvent.fire();
    $A.get('e.force:refreshView').fire();
    component.destroy();
  },
  handleOnSubmitForm: function(component, event, helper) {
    event.preventDefault();
    var fields = event.getParam('fields');
    console.log('NONC_PS_DEBUG handleOnSubmitForm START isAdditionalRT=', component.get('v.isAdditionalRT'), 'fields=', JSON.stringify(fields));
    var cuenta = {};
    var wrapperList = component.get('v.columns');
    component.set('v.canSave', 'true');
    for (var i = 0; i < wrapperList.length; i++) {
      cuenta[wrapperList[i].fieldAPIName] = fields[wrapperList[i].fieldAPIName];
    }
    var actionCtrl = component.get('c.validateNonClienteComponent');
    actionCtrl.setParams({
      'acc': cuenta,
    });
    actionCtrl.setCallback(this, function(response) {//eslint-disable-line
      var toastEvent = $A.get('e.force:showToast');
      console.log('NONC_PS_DEBUG validateNonClienteComponent state=', response.getState(), 'return=', response.getReturnValue());
      if (response.getState() === 'SUCCESS' && response.getReturnValue() !== null && response.getReturnValue() !== undefined) {
        var respuesta = JSON.parse(response.getReturnValue());
        fields.serverResponse = respuesta;
        if (respuesta.status !== 'success') {
          toastEvent.setParams({
            title: '',
            type: respuesta.status,
            mode: 'dismissible',
            message: respuesta.message
          });
          toastEvent.fire();
          component.set('v.canSave', 'false');
        } else {
          fields = this.fieldTreatmentresponse(component, fields);
          // Preserve subsidiary creation controls if they come from previous screen payload.
          var firstScreenDataRaw = component.get('v.getDataFirstScreen');
          if (firstScreenDataRaw) {
            try {
              var firstScreenData = JSON.parse(firstScreenDataRaw);
              console.log('NONC_PS_DEBUG getDataFirstScreen payload=', firstScreenData);
              if (firstScreenData.DES_Create_ProspectSubsidiary_check__c !== undefined) {
                fields.DES_Create_ProspectSubsidiary_check__c = firstScreenData.DES_Create_ProspectSubsidiary_check__c;
              }
              if (firstScreenData.DES_Create_ProspectSubsidiary_Name__c !== undefined) {
                fields.DES_Create_ProspectSubsidiary_Name__c = firstScreenData.DES_Create_ProspectSubsidiary_Name__c;
              }
            } catch (parseError) {
              // Keep save flow even if payload is malformed.
              console.warn('Invalid getDataFirstScreen payload', parseError);
            }
          }
          var lookupID = '';
          if (component.get('v.selectedLookUpRecord') !== '' && component.get('v.selectedLookUpRecord') !== undefined && component.get('v.selectedLookUpRecord').Id !== undefined) {
            lookupID = component.get('v.selectedLookUpRecord').Id;
          }
          var actionCtrl1 = component.get('c.createNewAccountNew');
          actionCtrl1.setParams({
            'accJSON': JSON.stringify(fields),
            'isAdditional': component.get('v.isAdditionalRT'),
            'fieldAPIName': component.get('v.lookUpFieldAPIName'),
            'lookupID': lookupID
          });
          console.log('NONC_PS_DEBUG createNewAccountNew params=', {
            isAdditional: component.get('v.isAdditionalRT'),
            fieldAPIName: component.get('v.lookUpFieldAPIName'),
            lookupID: lookupID,
            accJSON: JSON.stringify(fields)
          });
          actionCtrl1.setCallback(this, function(response1) {
            console.log('NONC_PS_DEBUG createNewAccountNew callback state=', response1.getState(), 'return=', response1.getReturnValue(), 'errors=', response1.getError());
            if (response1.getState() === 'SUCCESS' && response1.getReturnValue() !== null && response1.getReturnValue() !== undefined && response1.getReturnValue().length <= 20) {
              var createdGroupId = response1.getReturnValue();
              // For Prospect Group flow, verify a linked Prospect Subsidiary exists before closing modal.
              if (component.get('v.isAdditionalRT') === false) {
                var validateSubsidiaryAction = component.get('c.validateProspectSubsidiaryCreation');
                validateSubsidiaryAction.setParams({
                  'groupId': createdGroupId
                });
                validateSubsidiaryAction.setCallback(this, function(validationResponse) {
                  console.log('NONC_PS_DEBUG validateProspectSubsidiaryCreation callback state=', validationResponse.getState(), 'return=', validationResponse.getReturnValue(), 'errors=', validationResponse.getError());
                  if (validationResponse.getState() === 'SUCCESS' && validationResponse.getReturnValue() !== null && validationResponse.getReturnValue() !== undefined && validationResponse.getReturnValue().length <= 20) {
                    component.set('v.recordId', createdGroupId);
                    helper.handleSuccess(component, event, helper);
                  } else {
                    var validationMessage = validationResponse.getReturnValue();
                    if (!validationMessage && validationResponse.getState() === 'ERROR') {
                      var validationErrors = validationResponse.getError();
                      if (validationErrors && validationErrors[0] && validationErrors[0].message) {
                        validationMessage = validationErrors[0].message;
                      }
                    }

                    toastEvent.setParams({
                      title: '',
                      type: 'error',
                      mode: 'dismissible',
                      message: validationMessage ? validationMessage : $A.get('$Label.c.Contact_your_Admin')
                    });
                    toastEvent.fire();
                    component.set('v.canSave', 'false');
                  }
                });
                $A.enqueueAction(validateSubsidiaryAction);
              } else {
                component.set('v.recordId', createdGroupId);
                helper.handleSuccess(component, event, helper);
              }
            } else {
              var backendMessage = response1.getReturnValue();
              if (!backendMessage && response1.getState() === 'ERROR') {
                var actionErrors = response1.getError();
                if (actionErrors && actionErrors[0] && actionErrors[0].message) {
                  backendMessage = actionErrors[0].message;
                }
              }
              toastEvent.setParams({
                title: '',
                type: 'error',
                mode: 'dismissible',
                message: backendMessage ? backendMessage : $A.get('$Label.c.Contact_your_Admin')
              });
              toastEvent.fire();
              component.set('v.canSave', 'false');
            }
          });
          $A.enqueueAction(actionCtrl1);
        }
      } else {
        toastEvent.setParams({
          title: '',
          type: 'error',
          mode: 'dismissible',
          message: $A.get('$Label.c.Contact_your_Admin')
        });
        toastEvent.fire();
        component.set('v.canSave', 'false');
      }
    });
    $A.enqueueAction(actionCtrl);
  },
  handleSuccess: function(component, event, helper) {
    var mesg = $A.get('$Label.c.Create_Non');
    if (component.get('v.isOnDesktop') !== 'DESKTOP') {
      mesg = mesg.replace('{0}', '');
    }
    var toastEvent = $A.get('e.force:showToast');
    var clientId = component.get('v.recordId');
    if (!clientId && event && event.getParams && event.getParams().response) {
      clientId = event.getParams().response.id;
    }
    toastEvent.setParams({
      title: '',
      type: 'success',
      mode: 'dismissible',
      message: mesg,
      messageTemplate: mesg,
      messageTemplateData: [ {
        label: component.get('v.clientName'),
        url: '/lightning/r/Account/' + clientId + '/view'
      } ]
    });
    toastEvent.fire();
    if (component.get('v.isOnDesktop') !== 'DESKTOP') {
      var navEvtDesk = $A.get('e.force:navigateToSObject');
      navEvtDesk.setParams({
        'recordId': clientId,
      });
      navEvtDesk.fire();
    }
    if (component.get('v.isOnAccount')) {
      var navEvt = $A.get('e.force:navigateToSObject');
      navEvt.setParams({
        'recordId': clientId,
      });
      navEvt.fire();
    } else {
      window.setTimeout(
        $A.getCallback(function() {
          helper.closeModal(component, event, helper);
        }), 200
      );
    }
  },
  fieldTreatmentresponse: function(component, fields) {
    var customIdsResponse = component.get('v.customIdsResponse');

    var newJSONFields = fields;
    var serverResponse = newJSONFields.serverResponse;

    if (serverResponse !== null) {
      delete newJSONFields.serverResponse;
      var responseKeys = Object.keys(serverResponse);
      for (var idx = 0; idx < responseKeys.length; idx++) {
        var key = responseKeys[idx];
        var value = serverResponse[key];
        if (customIdsResponse[key] !== undefined && value !== null) {
          newJSONFields[customIdsResponse[key]] = value;
        }
      }
    }

    return newJSONFields;
  }
});