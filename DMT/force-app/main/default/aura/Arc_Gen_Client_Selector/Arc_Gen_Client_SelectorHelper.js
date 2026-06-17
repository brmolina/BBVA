({
    doInitHelper: function(component, event, helper) {
    helper.doInitCall(component, event, helper)
      .then(function(result) {
        helper.fillCountries(component, event, helper, result);
      })
      .catch(function(e) {
        helper.showToastEvent('Error', e[0].message, 'error');
      });

    },
  doInitCall: function(component, event, helper) {

        const getdata = component.get('c.gtCountries');
    getdata.setParams({
      clientCode: component.get('v.recordId')
    });

        return this.promisifyAndCallAction(getdata);
  },
  fillCountries: function(component, event, helper, result) {
    if (result) {
      let countryOpts = [];
      var obj = JSON.parse(result);
      for (let lclient of obj) {
        countryOpts.push({ value: lclient.localId, label: lclient.localName });
      }

            component.set('v.countryOptions', countryOpts);

            if (component.get('v.entityType') === 'ifis') {
        helper.forIfis(component, event, helper);
      }
    }
  },
  forIfis: function(component, event, helper) {
    const getdata = component.get('c.mainCntry');
    getdata.setParams({
      clientCode: component.get('v.recordId')
    });

    helper.promisifyAndCallAction(getdata)
      .then(function(result) {
        component.set('v.countrySlctd', result);
        component.set('v.countryIsDisabled', true);
        helper.getClientsOpts(component, event, helper);
      })
      .catch(function(e) {
        helper.showToastEvent('Error', e[0].message, 'error');
      });
  },
  getClientsOpts: function(component, event, helper) {
    const getdata = component.get('c.gtClients');
    getdata.setParams({
      clientCode: component.get('v.recordId'),
      countryCode: component.get('v.countrySlctd'),
      entityType: component.get('v.entityType')
    });
    helper.promisifyAndCallAction(getdata)
      .then(function(result) {
        const isProspect = component.get('v.isProspect');
        let optionsClient = [];
        var obj = JSON.parse(result);
        let clientBankMap = {};
        for (let lclient of obj) {
          optionsClient.push({ value: lclient.localId, label: lclient.localName });
          clientBankMap[lclient.localId] = lclient.bankEntity;
        }
        component.set('v.clientsOptions', optionsClient);
        component.set('v.bankEntities', clientBankMap);
        })
      .catch(function(e) {
        helper.showToastEvent('Error', e[0].message, 'error');
      });
  },
  handleRatingSystem: function(component) {
    if (this.hasRatingSystem(component)) {
      return this.doRatingSystem(component);
    }


    return Promise.resolve();
  },
  callParentSubsidiary: function(component) {
    const action = component.get('c.checkExpgAvailability');
    action.setParams({
      clientId: component.get('v.clientSlctd')
    });
    return new Promise((resolve, reject) => {
      action.setCallback(this, (response) => {
        const state = response.getState();
        if (state === 'SUCCESS') {
          component.set('v.parentSubsidiarySer', response.getReturnValue());
          console.log('Parent Subsidiary: ' + response.getReturnValue());
          resolve(response.getReturnValue());
        } else if (state === 'ERROR') {
          const errors = response.getError();
          const errorList = Array.isArray(errors) ? errors : [];
          const firstError = errorList.length > 0 ? errorList[0] : null;
          let errorMessage = 'Unknown error occurred';
          if (firstError) {
            errorMessage = firstError.message || errorMessage;
          }
          reject(errorMessage);
        }
      });
      $A.enqueueAction(action);
    });
  },
  hasRatingSystem: function(component) {
    const ratingSystemEnabled = component.get('v.ratingSystemEnabled');
    const selectedCountry = component.get('v.countrySlctd');
    const isProspect = component.get('v.isProspect');

    if (!ratingSystemEnabled || !selectedCountry || isProspect) {
      return false;
    }

        const allowedCountries = this.getAllowedCountries(component);
    return allowedCountries.has(selectedCountry);
  },
  doRatingSystem: function(component) {
    component.set('v.spinnerText', $A.get('$Label.c.Arc_Gen_RatingSystemLoading') + '...');
    component.set('v.isLoading', true);
    this.callRatingSystem(component)
      .then((result) => {
        this.handleRSResult(component, result);
      })
      .catch((errorMessage) => {
        this.handleRSError(component, errorMessage, false);
      })
      .finally(() => {
        component.set('v.isLoading', false);
      });
  },
  getAllowedCountries: function(component) {
    const ratingSystemBookCodes = component.get('v.ratingSystemBookCodes') || [];
    return new Set(ratingSystemBookCodes.map(country => country.value));
  },
  callRatingSystem: function(component) {
    const action = component.get('c.callRatingSystem');
    action.setParams({
      clientId: component.get('v.clientSlctd'),
      selectedFlow: component.get('v.entityType'),
      bookingCountry: component.get('v.countrySlctd')
    });
    return new Promise((resolve, reject) => {
      action.setCallback(this, (response) => {
        const state = response.getState();
        if (state === 'SUCCESS') {
          resolve(response.getReturnValue());
        } else if (state === 'ERROR') {
          const errors = response.getError();
          const errorMessage = errors && errors[0] && errors[0].message
            ? errors[0].message
            : 'Unknown error occurred';
          reject(errorMessage);
        }
    });
      $A.enqueueAction(action);
    });
  },
  handleRSResult: function(component, result) {
    component.set('v.alertTitle', result.title);
    component.set('v.alertVariant', result.variant);
    component.set('v.alertMessage', result.message);
    component.set('v.isBlocked', result.isBlocked);
    component.set('v.showAlert', result.variant !== 'SUCCESS');
    component.set('v.ratingSystemName', result.ratingSystem);
  },
  handleRSError: function(component, errorMessage, isPS) {
    console.error(errorMessage);
    component.set('v.alertTitle', 'Error');
    component.set('v.alertVariant', 'Error');
    if (isPS) {
      component.set('v.alertMessage', errorMessage);
    } else {
      component.set('v.alertMessage', $A.get('$Label.c.Arc_Gen_RatingSystem_Error'));
    }
    component.set('v.isBlocked', true);
    component.set('v.showAlert', true);
  },
  notifyParent: function(component) {
    const clientsOptions = component.get('v.clientsOptions');
    const bankEntities = component.get('v.bankEntities');
    const clientSlctd = component.get('v.clientSlctd');

    const clientOptionSlctd = clientsOptions.find(client => client.value === clientSlctd);
    const bankEntitySlctd = bankEntities[clientSlctd];
    if (clientOptionSlctd) {
      component.set('v.countrySlctdParent', component.get('v.countrySlctd'));
      component.set('v.bankEntitySlctd', bankEntitySlctd);
      component.set('v.clientOptionSlctd', clientOptionSlctd);
    }
  },
  promisifyAndCallAction: function(action) {
    return new Promise((resolve, reject) => {
      action.setCallback(this, function(response) {
        const state = response.getState();
        if (state === 'SUCCESS') {
          const returnValue = response.getReturnValue();

                if (returnValue !== null && typeof returnValue === 'object') {
            // Check whether response is a ServiceAndSaveResponse object.
            const serviceCode = returnValue.serviceCode;
            const saveStatus = returnValue.saveStatus;

                if (typeof serviceCode !== 'undefined' && !serviceCode.startsWith('2')) {
              reject(returnValue.serviceMessage);
            } else if (saveStatus === 'false') {
              reject(returnValue.saveMessage);
            } else {
                resolve(returnValue);
            }
            } else {
            resolve(returnValue);
          }
        } else {
          reject(response.getError());
        }
      });

            $A.enqueueAction(action);
    });
  },
  showToastEvent: function(title, message, type) {
    const toastEvent = $A.get('e.force:showToast');
    toastEvent.setParams({
      title: title,
      message: message,
      type: type
    });
    toastEvent.fire();
  }
});