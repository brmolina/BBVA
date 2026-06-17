({//eslint-disable-line
  handleInit: function(component, event, helper) {

    console.log('PRUEBA ENTRA');
    let device = $A.get('$Browser.formFactor');
    let heightCalculation = (device !== 'DESKTOP') ? 'check-similar-form mobile' : 'check-similar-form';
    component.set('v.heightCalculation', heightCalculation);


    let actionCtrl = component.get('c.getFieldValidation');
    actionCtrl.setCallback(this, function(response) {
      if (response.getState() === 'SUCCESS' && response.getReturnValue() !== null && response.getReturnValue() !== undefined) {
        if (response.getReturnValue().trim().length > 0) {
          var respuesta = JSON.parse(response.getReturnValue());
          component.set('v.labelFieldValidation', respuesta.strLabel);
          component.set('v.showFieldValidation', true);
        }
        this.handleCountry(component, event, helper);
        this.handleInformation(component, event, helper);
      } else if (response.getState() === 'ERROR') {
        var error = actionCtrl.getError();
        component.set('v.showValidation', true);
        component.set('v.msg', error[0].message);
      }
    });
    /* get fields from Account fieldset to search duplicates values*/
    let actionSearchFields = component.get('c.getAccountFieldSetValues');
    actionSearchFields.setParams({
      fieldSetName: 'NONC_DuplicateSearchFieldSet',
      objectName: 'Account'
    });

    actionSearchFields.setCallback(this, function(response) {
      if (response.getState() === 'SUCCESS' && response.getReturnValue() !== null && response.getReturnValue() !== undefined) {
        component.set('v.isFieldSetInformed', true);
        let jsonObj = [];
        jsonObj = JSON.parse(response.getReturnValue());

        // Añadimos atributo value al JSON Generado para posteriormente almacenar el valor introducido en el formulario

        for (let z = 0; z < jsonObj.simpleFields.length; z++) {
          let simpleField = jsonObj.simpleFields[z];
          simpleField.value = '';
        }

        for (let x = 0; x < jsonObj.billingFields.length; x++) {
          let billingField = jsonObj.billingFields[x];
          billingField.value = '';
        }

        for (let y = 0; y < jsonObj.shippingFields.length; y++) {
          let shippingField = jsonObj.shippingFields[y];
          shippingField.value = ' ';
        }

        component.set('v.billingAddressRequired', this.hasRequiredField(jsonObj, 'billingFields'));
        component.set('v.shippingAddressRequired', this.hasRequiredField(jsonObj, 'shippingFields'));
        component.set('v.searchFields', jsonObj);
      } else if (response.getState() === 'ERROR') {
        component.set('v.isFieldSetInformed', false);
        var error = actionSearchFields.getError();
        component.set('v.msg', error[0].message);
      }
    });

    let isdisable = component.get('c.isDisabledtrue');
    isdisable.setCallback(this, function(response) {
      if (response.getState() === 'SUCCESS' && response.getReturnValue() !== null && response.getReturnValue() !== undefined) {
        if (response.getReturnValue() === true) {
          component.set('v.isDisable', true);
        }
      } else if (response.getState() === 'ERROR') {
        var error = isdisable.getError();
        component.set('v.msg', error[0].message);
      }
    });

    let googlePlacesChecks = component.get('c.getChecksGooglePlaces');
    googlePlacesChecks.setCallback(this, function(response) {
      if (response.getState() === 'SUCCESS' && response.getReturnValue() !== null && response.getReturnValue() !== undefined) {
        let csGooglePlaces = JSON.parse(response.getReturnValue());
        component.set('v.addressPredictive', csGooglePlaces.showGoogleMap);
        component.set('v.showGoogleMap', csGooglePlaces.addressPredictive);
      } else if (response.getState() === 'ERROR') {
        var error = googlePlacesChecks.getError();
        component.set('v.msg', error[0].message);
      }
    });

    $A.enqueueAction(actionSearchFields);
    $A.enqueueAction(actionCtrl);
    $A.enqueueAction(isdisable);
    $A.enqueueAction(googlePlacesChecks);
  },
  hasRequiredField: function(jsonObj, addressType) {
    let hasRequiredField = false;
    let arrAddress = jsonObj[addressType];
    if (arrAddress.some(item => item.required === true)) {
      hasRequiredField = true;
    }

    return hasRequiredField;
  },
  handleCountry: function(component, event, helper) {
    let actionCountry = component.get('c.getFieldCountry');
    actionCountry.setCallback(this, function(response) {
      if (response.getState() === 'SUCCESS' && response.getReturnValue() !== null && response.getReturnValue() !== undefined) {
        if (response.getReturnValue().trim().length > 0) {
          var respuesta = JSON.parse(response.getReturnValue());
          component.set('v.labelFieldCountry', respuesta.strLabel);
          component.set('v.showCountry', true);
        }
        this.handleUniqueId(component, event, helper);
      } else if (response.getState() === 'ERROR') {
        var error = actionCountry.getError();
        component.set('v.showValidation', true);
        component.set('v.msg', error[0].message);
      }
    });
    $A.enqueueAction(actionCountry);
  },
  handleUniqueId: function(component, event, helper) {
    let actionUniqueId = component.get('c.getFieldUniqueId');
    actionUniqueId.setCallback(this, function(response) {
      if (response.getState() === 'SUCCESS' && response.getReturnValue() !== null && response.getReturnValue() !== undefined) {
        if (response.getReturnValue().trim().length > 0) {
          let respuesta = JSON.parse(response.getReturnValue());//NOSONAR
        }
        this.handleRT(component, event, helper);
      } else if (response.getState() === 'ERROR') {
        var error = actionUniqueId.getError();
        component.set('v.showValidation', true);
        component.set('v.msg', error[0].message);
      }
    });
    $A.enqueueAction(actionUniqueId);
  },
  handleRT: function(component, event, helper) {
    let actionUniqueId = component.get('c.validateRecType');
    actionUniqueId.setCallback(this, function(response) {
      if (response.getState() === 'SUCCESS' && response.getReturnValue() !== null && response.getReturnValue() !== undefined) {
        if (response.getReturnValue().trim().length > 0) {
          let respuesta = JSON.parse(response.getReturnValue());//NOSONAR
        }
        this.handleType(component, event, helper);
      } else if (response.getState() === 'ERROR') {
        var error = actionUniqueId.getError();
        component.set('v.showValidation', true);
        component.set('v.msg', error[0].message);
      }
    });
    $A.enqueueAction(actionUniqueId);
  },
  handleType: function(component, event, helper) {
    let actionType = component.get('c.getFieldType');
    actionType.setCallback(this, function(response) {
      if (response.getState() === 'SUCCESS' && response.getReturnValue() !== null && response.getReturnValue() !== undefined) {
        if (response.getReturnValue().trim().length > 0) {
          var respuesta = JSON.parse(response.getReturnValue());
          component.set('v.labelFieldType', respuesta.strLabel);
          component.set('v.showType', true);
        }
        this.handleAddRT(component, event, helper);
      } else if (response.getState() === 'ERROR') {
        var error = actionType.getError();
        component.set('v.showValidation', true);
        component.set('v.msg', error[0].message);
      }
    });
    $A.enqueueAction(actionType);
  },
  handleAddRT: function(component, event, helper) {
    let actionType = component.get('c.validateAddRecType');
    actionType.setCallback(this, function(response) {
      if (response.getState() === 'SUCCESS' && response.getReturnValue() !== null && response.getReturnValue() !== undefined) {
        if (response.getReturnValue().trim().length > 0) {
          let respuesta = JSON.parse(response.getReturnValue());//NOSONAR
        }
      } else if (response.getState() === 'ERROR') {
        var error = actionType.getError();
        component.set('v.showValidation', true);
        component.set('v.msg', error[0].message);
      }
    });
    $A.enqueueAction(actionType);
  },
  handleChange: function(component, event, helper) {
    component.set('v.clientName', event.getParam('value'));
    component.set('v.checkSimilarName', false);
    component.set('v.disableContinue', true);
    component.set('v.showError', false);
    component.set('v.closeDropdown', true);

    let actionCtrl = component.get('c.getSimilarAccountName');
    actionCtrl.setParams({
      'searchName': event.getParam('value'),
    });
    actionCtrl.setCallback(this, function(response) {
      if (response.getState() === 'SUCCESS' && response.getReturnValue() !== null && response.getReturnValue() !== undefined) {
        let lResults = response.getReturnValue().split('<br/>');
        component.set('v.similarNames', lResults);
        var showResults = component.find('searchesults');
        if (lResults.length > 1 && event.getParam('value').length >= 3) {
          $A.util.addClass(showResults, 'show');
        } else {
          $A.util.removeClass(showResults, 'show');
        }
      } else {
        console.log('error');
      }
    });
    $A.enqueueAction(actionCtrl);
  },
  handleChangeAditional: function(component, event, helper) {
    component.set('v.checkSimilarName', false);
    component.set('v.disableContinue', true);
    component.set('v.showError', false);
  },
  checkSimilar: function(component, event, helper) {
    let billingField = component.find('billingInput');
    let shippingField = component.find('shippingInput');
    let nocontinuar = this.addresLogic(component, billingField, shippingField);

    component.set('v.showError', false);


    if (component.get('v.clientName').length >= 3 && nocontinuar === false) {

      event.preventDefault(); // stop form submission
      var eventFields = event.getParam('fields');

      if (eventFields !== undefined && eventFields !== null && eventFields !== '') {
        component.set('v.clientName', eventFields.Name);
        eventFields = JSON.stringify(eventFields);
        this.nifExist(component, eventFields);
        component.set('v.dataNewProspect', eventFields);
      }

      let actionCtrl = component.get('c.getAllNamesSOSLComponent');
      actionCtrl.setParams({
        'searchName': component.get('v.clientName'),
        'strFielValidation': component.get('v.fieldValidation'),
        'strFielLabel': component.get('v.labelFieldValidation'),
        'isOnDesktop': component.get('v.isOnDesktop'),
        'fields': eventFields
      });

      actionCtrl.setCallback(this, function(response) {
        if (response.getState() === 'SUCCESS' && response.getReturnValue() !== null && response.getReturnValue() !== undefined) {
          component.set('v.similarAccounts', this.getListRecords(component, helper, response));
        } else if (response.getState() === 'ERROR') {
          component.set('v.showValidation', false);
          component.set('v.checkNoDuplicate', false);
          component.set('v.disableContinue', true);
          component.set('v.checkSimilarName', false);
          component.set('v.compararNames', '');

          var error = actionCtrl.getError();
          component.set('v.showValidation', true);
          component.set('v.msg', error[0].message);
        }
      });
      $A.enqueueAction(actionCtrl);
    } else {
      component.set('v.showError', true);
    }
  },
  addresLogic: function(component, billingField, shippingField) {
    let nocontinuar = false;
    if (billingField !== undefined && billingField !== null) {
      let billingInputError = component.find('billingInputError');
      if (component.get('v.billingAddressRequired') === true && billingField.get('v.value') === '') {
        $A.util.addClass(billingField, 'slds-has-error');
        $A.util.removeClass(billingInputError, 'hide');
        nocontinuar = true;
      } else {
        $A.util.removeClass(billingField, 'slds-has-error');
        $A.util.addClass(billingInputError, 'hide');
      }
    }

    if (shippingField !== undefined && shippingField !== null) {
      let shippingInputError = component.find('shippingInputError');
      if (component.get('v.shippingAddressRequired') === true && shippingField.get('v.value') === '') {
        $A.util.addClass(shippingField, 'slds-has-error');
        $A.util.removeClass(shippingInputError, 'hide');
        nocontinuar = true;
      } else {
        $A.util.removeClass(shippingField, 'slds-has-error');
        $A.util.addClass(shippingInputError, 'hide');
      }
    }

    return nocontinuar;
  },
  getListRecords: function(component, helper, response) {
    var strFielValidation = component.get('v.fieldValidation');
    var lstNameCuentas;
    var bolValidarDuplicate = 0;
    var bolValidarCodigo = 0;

    let lResult = [];
    let result = JSON.parse(response.getReturnValue());

    var strNombreTextBox = component.get('v.clientName');

    strNombreTextBox = strNombreTextBox.replace(/[^a-zA-Z0-9 ]/g, '').toLowerCase().replace(/ {2}/g, ' ');
    strNombreTextBox = helper.delSpaceString(strNombreTextBox);

    for (let i = 0; i < result.length; i++) {
      lResult.push(result[i]);
    }

    component.set('v.disableContinue', false);
    component.set('v.showValidation', false);
    component.set('v.checkNoDuplicate', false);
    component.set('v.checkSimilarName', false);
    component.set('v.compararNames', '');

    lstNameCuentas = result;
    var mesg = '';
    var validations = helper.hasDuplicateName(component, helper, lstNameCuentas, strNombreTextBox, strFielValidation, bolValidarCodigo, bolValidarDuplicate);
    bolValidarDuplicate = validations.bolValidarDuplicate;
    bolValidarCodigo = validations.bolValidarCodigo;
    if (bolValidarDuplicate === 0 && lstNameCuentas.length > 0) {
      if (!(lstNameCuentas[0].length === 0 && lstNameCuentas.length === 1)) {
        if (component.get('v.stopCreation') === true) {
          component.set('v.disableContinue', true);
          component.set('v.checkNoDuplicate', true);
          mesg = $A.get('$Label.c.NClient_lbl_Equal_FI').replace('%field%', '<u>' + component.get('v.clientName') + '</u>');
          component.set('v.msg', mesg);
        } else {
          component.set('v.checkNoDuplicate', true);
          mesg = $A.get('$Label.c.NClient_lbl_Similar').replace('%field%', '<u>' + component.get('v.clientName') + '</u>');
          component.set('v.msg', mesg);
        }
      }
    }
    if (bolValidarCodigo === 1) {
      component.set('v.checkNoDuplicate', false);
      component.set('v.checkSimilarName', true);
      component.set('v.disableContinue', true);

      mesg = $A.get('$Label.c.NClient_lbl_NotExistCustomValue');
      mesg = mesg.replace('&Field&', '<u>' + component.get('v.labelFieldValidation') + '</u>');
      mesg = mesg.replace('&Valor&', '<u>' + strFielValidation + '</u>');
      component.set('v.msg', mesg);
    }

    return lResult;
  },
  hasDuplicateName: function(component, helper, lstNameCuentas, strNombreTextBox, strFielValidation, bolValidarCodigo, bolValidarDuplicate) {
    var validations = [];
    validations.bolValidarCodigo = bolValidarCodigo;
    validations.bolValidarDuplicate = bolValidarDuplicate;
    for (var i = 0; i < lstNameCuentas.length; i++) {
      var strNombreCliente = lstNameCuentas[i].clientName;
      var strCode = lstNameCuentas[i].code;
      strNombreCliente = strNombreCliente.replace(/[^a-zA-Z0-9 ]/g, '').toLowerCase().replace(/ {2}/g, ' ');
      strNombreCliente = helper.delSpaceString(strNombreCliente);

      if (strNombreCliente === strNombreTextBox) {
        component.set('v.compararNames', lstNameCuentas[i].clientName);
        component.set('v.checkNoDuplicate', false);
        component.set('v.checkSimilarName', true);
        /*if (component.get('v.isDisable') === true) {
          component.set('v.disableContinue', false);
        } else {
          component.set('v.disableContinue', true);
        }*/
        bolValidarDuplicate = 1;
        component.set('v.msg', $A.get('$Label.c.NClient_lbl_ExistDuplicate').replace('%field%', '<u>' + component.get('v.clientName') + '</u>'));
      }
      if (strCode !== undefined && strCode !== null && strCode.length > 0 && strFielValidation === strCode) {
        bolValidarCodigo = 1;
      }
      validations.bolValidarCodigo = bolValidarCodigo;
      validations.bolValidarDuplicate = bolValidarDuplicate;
    }
    return validations;
  },

  delSpaceString: function(strCadena) {
    if (strCadena !== undefined && strCadena !== null) {
      strCadena = strCadena.trim();
    }
    if (strCadena === undefined || strCadena === null) {
      console.log(strCadena);
    } else {
      while (strCadena.indexOf('  ') !== -1) {
        strCadena = strCadena.replace('  ', ' ');
      }
    }
    return strCadena;
  },
  goToForm: function(component, event, helper) {
    var lstNameCuentas = component.get('v.similarNames');
    if (component.get('v.checkNoDuplicate') && lstNameCuentas.length > 0 && !component.get('v.clickNoDuplicate')) {
      component.set('v.alertSimilar', true);
      component.set('v.clickNoDuplicate', true);
    } else if (!component.get('v.disableContinue')) {
      let device = $A.get('$Browser.formFactor');
      let heightCalculation = (device !== 'DESKTOP') ? 'check-similar-form mobile reset-height' : 'check-similar-form';
      component.set('v.heightCalculation', heightCalculation);

      // We instantiate the Aura wrapper (not the LWC directly) because $A.createComponent
      // does not reliably instantiate an LWC at runtime. The wrapper statically embeds
      // c:nONC_createNonClientOverwriteLWC and bridges its events to c:NONC_ceEvent.
      $A.createComponent('c:NONC_editFormNonClientLWCWrapper', {
        'headerText': component.get('v.headerText'),
        'clientName': component.get('v.clientName'),
        'isOnAccount': component.get('v.isOnAccount'),
        'isAdditionalRT': component.get('v.isAdditionalRT'),
        'getDataFirstScreen': component.get('v.dataNewProspect')
      },
      function(modalComponent, status, errorMessage) {
        if (status === 'SUCCESS') {
          //Appending the newly created component in div
          let body = component.find('editFormController').get('v.body');
          body.push(modalComponent);
          component.find('editFormController').set('v.body', body);
          component.set('v.showModal', false);
        } else if (status === 'INCOMPLETE') {
          console.log('Server issue or client is offline.');
        } else if (status === 'ERROR') {
          console.log(JSON.stringify(errorMessage));
        }
      }
      );
    } else {
      component.set('v.showError', true);
    }
  },
  handleComponentEvent: function(component, event, helper) {
    var message = event.getParam('message');
    component.set('v.messageFromEvent', message);
    var numEventsHandled = parseInt(component.get('v.numEvents')) + 1;
    component.set('v.numEvents', numEventsHandled);
    if (message === 'Close component' || message === 'Cancel component') {
      helper.closeModal(component, event, helper);
    } else if (message === 'Back component') {
      let editFormContainer = component.find('editFormController');
      if (editFormContainer) {
        editFormContainer.set('v.body', []);
      }
      component.set('v.alertSimilar', false);
      component.set('v.clickNoDuplicate', false);
      component.set('v.disableContinue', true);
      component.set('v.showModal', true);
    }
  },
  backModal: function(component, event, helper) {
    component.set('v.checkNoDuplicate', false);
    component.set('v.checkSimilarName', false);
    component.set('v.disableContinue', true);
    component.set('v.clickNoDuplicate', false);
    component.set('v.alertSimilar', false);


  },
  handleLwcBack: function(component, event, helper) {
    let editFormContainer = component.find('editFormController');
    if (editFormContainer) {
      editFormContainer.set('v.body', []);
    }
    component.set('v.showModal', true);
    helper.backModal(component, event, helper);
  },
  closeModal: function(component, event, helper) {

    let isOnAccount = component.get('v.isOnAccount');
    if (component.get('v.isOnDesktop') !== 'DESKTOP') {
      var homeEvent = $A.get('e.force:navigateToObjectHome');
      homeEvent.setParams({
        'scope': 'Account'
      });
      homeEvent.fire();
    }

    if (isOnAccount) {
      $A.get('e.force:navigateToURL').setParams({'url': '/lightning/o/Account/home'}).fire();
    } else {
      var cmpEvent = component.getEvent('cmpEvent');
      cmpEvent.setParams({
        'message': 'Close component'
      });
      cmpEvent.fire();
    }

    component.destroy();
  },
  onClickInputText: function(component, event, helper) {
    let field = event.getSource();
    let cmpAddressModal;

    if (field.get('v.name') === 'shipping') {
      cmpAddressModal = component.find('shippingModal');
    } else if (field.get('v.name') === 'billing') {
      cmpAddressModal = component.find('billingModal');
    }

    let resetOverflow = component.find('newProspectModalContent');
    let opacityField = component.find('opacityField');

    $A.util.addClass(cmpAddressModal, 'showMe');
    $A.util.addClass(resetOverflow, 'overflowInitial');
    $A.util.addClass(opacityField, 'show');
  },
  onClickCloseAddressModal: function(component, event, helper) {
    let field = event.getSource();
    let cmpAddressModal;
    let resetOverflow = component.find('newProspectModalContent');
    let opacityField = component.find('opacityField');

    let myInputs;

    if (field.get('v.name') === 'shippingFields') {
      cmpAddressModal = component.find('shippingModal');
      myInputs = component.find('shippingModal').find({instancesOf: 'lightning:inputField'});
    } else if (field.get('v.name') === 'billingFields') {
      cmpAddressModal = component.find('billingModal');
      myInputs = component.find('billingModal').find({instancesOf: 'lightning:inputField'});
    }

    let addressConcat = '';
    var infoaddress = [];

    if (myInputs !== null && myInputs !== undefined) {
      for (var i = 0; i < myInputs.length; i++) {
        if (myInputs[i].get('v.value') !== null && myInputs[i].get('v.value') !== '') {
          infoaddress.push(myInputs[i].get('v.value'));
        }
      }
    }

    addressConcat = infoaddress.join();

    if (field.get('v.name') === 'shippingFields') {
      component.find('shippingInput').set('v.value', addressConcat);
    } else if (field.get('v.name') === 'billingFields') {
      component.find('billingInput').set('v.value', addressConcat);
    }

    $A.util.removeClass(cmpAddressModal, 'showMe');
    $A.util.removeClass(resetOverflow, 'overflowInitial');
    $A.util.removeClass(opacityField, 'show');
  },
  handleInformation: function(component, event, helper) {
    let actionType = component.get('c.getFieldInformation');
    actionType.setCallback(this, function(response) {
      if (response.getState() === 'SUCCESS' && response.getReturnValue() !== null && response.getReturnValue() !== undefined) {
        if (response.getReturnValue().trim().length > 0) {
          var respuesta = JSON.parse(response.getReturnValue());
          component.set('v.labelFieldInformation', respuesta.strLabel);
          component.set('v.showInformation', true);
        }

      } else if (response.getState() === 'ERROR') {
        var error = actionType.getError();
        component.set('v.showValidation', true);
        component.set('v.msg', error[0].message);
      }
    });
    $A.enqueueAction(actionType);
  },
  closeDropdown: function(component, event, helper) {
    component.set('v.closeDropdown', false);
  },
  nifExist: function(component, eventFields) {
    let stopcreation = component.get('c.disableforce');
    stopcreation.setParams({
      'fields': eventFields
    });
    stopcreation.setCallback(this, function(response) {
      if (response.getState() === 'SUCCESS' && response.getReturnValue() !== null && response.getReturnValue() !== undefined) {
        if (response.getReturnValue() === true) {
          component.set('v.stopCreation', true);
        } else if (response.getState() === 'ERROR') {
          var error = stopcreation.getError();
          component.set('v.msg', error[0].message);
        }
      }
    });
    $A.enqueueAction(stopcreation);
  },
  handleComponentEventGoogle: function(component, event) {
    let addressType = event.getParam('addressType');

    var searchFields = component.get('v.searchFields');


    if (addressType === 'billing') {
      searchFields = this.informBillingFields(searchFields, event);
    }

    if (addressType === 'shipping') {
      searchFields = this.informShippingFields(searchFields, event);
    }
    component.set('v.searchFields', searchFields);
  },
  informBillingFields: function(searchFields, event) {
    let city = event.getParam('city');
    let street = event.getParam('street');
    let country = event.getParam('country');
    let state = event.getParam('state');
    let postalCode = event.getParam('postalCode');

    for (var i = 0; i < searchFields.billingFields.length; i++) {
      switch (searchFields.billingFields[i].fieldPath) {
        case 'BillingCity':
          searchFields.billingFields[i].value = city;
          break;
        case 'BillingStreet':
          searchFields.billingFields[i].value = street;
          break;
        case 'BillingPostalCode':
          searchFields.billingFields[i].value = postalCode;
          break;
        case 'BillingState':
          searchFields.billingFields[i].value = state;
          break;
        case 'BillingCountry':
          searchFields.billingFields[i].value = country;
          break;
      }
    }
    return searchFields;
  },
  informShippingFields: function(searchFields, event) {
    let city = event.getParam('city');
    let street = event.getParam('street');
    let country = event.getParam('country');
    let state = event.getParam('state');
    let postalCode = event.getParam('postalCode');

    for (var i = 0; i < searchFields.billingFields.length; i++) {
      switch (searchFields.billingFields[i].fieldPath) {
        case 'ShippingCity':
          searchFields.billingFields[i].value = city;
          break;
        case 'ShippingStreet':
          searchFields.billingFields[i].value = street;
          break;
        case 'ShippingPostalCode':
          searchFields.billingFields[i].value = postalCode;
          break;
        case 'ShippingState':
          searchFields.billingFields[i].value = state;
          break;
        case 'ShippingCountry':
          searchFields.billingFields[i].value = country;
          break;
      }
    }
    return searchFields;
  }
});