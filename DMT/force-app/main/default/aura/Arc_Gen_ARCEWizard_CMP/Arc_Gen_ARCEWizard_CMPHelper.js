({
  /**
   * Initializes the component and fetches necessary data.
   */
  checkArceExist: function(component, event, helper) {
    const checkArceExist = component.get('c.checkArceAnalisysExist');

    checkArceExist.setParams({
      clientId: component.get('v.recordId')
    });
    return this.promisifyAndCallAction(checkArceExist);
  },
  /**
   * Initializes the component and fetches necessary data.
   */
  initComponent: function(component, event, helper) {
    helper.getEEFFServiceCheck(component);

    const profilingPromise = helper.profilingRating(component, event, helper);
    profilingPromise.then(function(resp) {
      component.set('v.profilingRating', resp);
      helper.newOrResume(component, event, helper);
    }).catch(function(err) {
      component.set('v.loading', false);
      if (typeof(err) === 'string') {
        component.set('v.errorMessage', $A.get('$Label.c.Lc_arce_NewARCE_CouldNotCreate').replace('{0}', err));
      } else if (typeof(err) === 'object') {
        component.set('v.errorMessage', err);
      } else {
        component.set('v.errorMessage', $A.get('$Label.c.Lc_arce_NewARCE_UnexpectedError'));
      }
      helper.changeSubtitle(component);
    });
  },

  /**
   * Retrieves the available Arcetypes from the custom metadata configuration.
   *
   * @return {Promise} A promise that resolves with the result of the server call.
   */
  getAvailableArceTypes: function(component) {
    const getTypesAction = component.get('c.getAvailableArceTypes');

    return this.promisifyAndCallAction(getTypesAction);
  },

  /**
   * Checks whether the Group Structure for RAIP should be displayed from the
   * custom metadata configuration.
   *
   * @return {Promise} A promise that resolves with the result of the server call.
   */
  getShouldShowGroupStructureRaip: function(component) {
    const getShouldShowGs = component.get('c.shouldShowRaipGroupStructure');

    return this.promisifyAndCallAction(getShouldShowGs);
  },

  /**
   * Retrieves the available IRP for a client from the custom metadata configuration.
   *
   * @return {Promise} A promise that resolves with the result of the server call.
   */
  getAvailableIrpDependCustomer: function(component) {
    const getIrpConfig = component.get('c.getIrpConfigCustomer');

    return this.promisifyAndCallAction(getIrpConfig);
  },

  /**
   * Retrieves profiling results for a client from the custom metadata configuration.
   *
   * @return {Promise} A promise that resolves with the result of the server call.
   */
  profilingRating: function(component, event, helper) {
    const getIrpProfiling = component.get('c.profilingResult');

    getIrpProfiling.setParams({
      clientId: component.get('v.recordId')
    });

    return this.promisifyAndCallAction(getIrpProfiling);
  },

  /**
   * Check if an ARCE is being resumed or if it is a new ARCE and verify settings.
   *
   * @returns {Promise} A promise that resolves when the action is complete.
   */
  newOrResume: function(component, event, helper) {
    // Check whether an ARCE is being resumed.
    helper.setProgressSteps(component);

    const getArceTypesPromise = helper.getAvailableArceTypes(component);
    const shouldShowGsPromise = helper.getShouldShowGroupStructureRaip(component);
    const irpStructureGroup = helper.getAvailableIrpDependCustomer(component);

    Promise.all([getArceTypesPromise, shouldShowGsPromise, irpStructureGroup])
      .then(function(responses) {//NOSONAR
        const availableArces = responses[0];
        const shouldShowGsRaip = responses[1];
        const irpAvailableCustomer = responses[2];
        component.set('v.availableArceTypes', availableArces);
        component.set('v.shouldShowGsRaip', shouldShowGsRaip);
        helper.changeSubtitle(component);
        if (availableArces.includes('RAIP')) {
          return helper.getOptIrpTypeCustomer(component, helper, irpAvailableCustomer);
        } else {
          component.set('v.loading', false);
        }
      });
    return Promise.resolve();
  },

  /**
   * Sets the progress steps for the progress indicator.
   */
  setProgressSteps: function(component) {
    component.set('v.progressSteps', [
      {
        label: $A.get('{!$Label.c.Arc_Gen_RTC_RSSelection}'),
        value: 'ratingSystemSelection'
      },
      {
        label: $A.get('{!$Label.c.Arc_Gen_Analysis_ST_RedirectToARCE}'),
        value: 'redirectToArce'
      }
    ]);
  },

  /**
   * Handles the action when the selected step is 'groupStructure'.
   */
  handleGroupStructureNext: function(component) {
    const arceType = component.get('v.selectedArceType');

    component.set('v.currentStep', arceType);
    component.set('v.nextDisabled', true);
    this.changeSubtitle(component);
  },

  /**
   * Handles the wizard's back action, navigating to the previous step.
   */
  handleWizardBack: function(component) {
    // If ARCE type is RAIP and the group structure if skipped, go back to
    // ARCE type selection. Otherwise, go back to group structure.
    const arceType = component.get('v.selectedArceType');
    const skipGroupStructureRaip = !component.get('v.shouldShowGsRaip');
    const skipGroupStructure = arceType === 'raip' && skipGroupStructureRaip;
    const previousStep = skipGroupStructure ? 'arceTypeSelection' : 'groupStructure';
    component.set('v.currentStep', previousStep);
    component.set('v.currentProgressStep', previousStep);
    component.set('v.backHidden', skipGroupStructure);
    component.set('v.nextDisabled', false);
    this.changeSubtitle(component);
  },

  /**
   * Handles the redirect action to an ARCE or account.
   *
   * @param {String} type - The type of redirect.
   * @param {String} arceId - The ID of the ARCE or account to redirect to.
   * @param {Boolean} arceNotInScope - Indicates whether the ARCE is out of scope.
   * @param {String} riskSegment - The risk segment information.
   */
  handleRedirect: function(component, type, arceId, arceNotInScope, riskSegment) {
    var helper = this; // eslint-disable-line

    component.set('v.currentStep', 'redirectToArce');
    component.set('v.currentProgressStep', 'redirectToArce');
    component.set('v.loading', false);
    component.set('v.backHidden', true);
    component.set('v.nextHidden', true);
    component.set('v.arceNotInScope', arceNotInScope);
    component.set('v.redirect', true);

    // Build text of out-of-scope ARCE
    var baseLabel = $A.get('$Label.c.Arc_Gen_NewARCE_WaitRedirectNotScope');
    var label = baseLabel.replace('{0}', riskSegment);
    component.set('v.outOfScopeText', label);

    helper.changeSubtitle(component);
    setTimeout($A.getCallback(function() {
      if (type === 'account') {
        helper.redirectAccount(component, arceId);
      } else if (type === 'analysis') {
        helper.redirectAnalysis(component, arceId);
      }
    }), 3000);
  },

  /**
   * Retrieves client data for services and related information.
   *
   * @param {Boolean} skipGroupStructure - Indicates whether to skip group structure.
   * @param {Boolean} onlyGetStructureGroup - Indicates to get only structure group information.
   * @returns {Promise} A promise that resolves with account information.
   */
  getfullaccountforservices: function(component, skipGroupStructure, onlyGetStructureGroup) {
    const nextStep = component.get('v.selectedArceType');
    const isGDT = component.get('v.isGDT');

    let actualClientId;
    if (nextStep === 'sp2Analysis' && isGDT) {
      actualClientId = component.get('v.selectedClient')[0].value; // Get the local client ID
    } else {
      actualClientId = component.get('v.recordId');
    }
    component.set('v.actualClientId', actualClientId);

    var action = component.get('c.getaccdataforservices');
    var helper = this; // eslint-disable-line
    action.setParams({
      recordId: actualClientId
    });

    return this.promisifyAndCallAction(action)
      .then(result => {
        component.set('v.firstaccountforfilldata', result);
        if (!onlyGetStructureGroup) {
          return skipGroupStructure ? helper.initializeSkipGroupStructure(component) : helper.chainingpromisesforservice(component);
        } else {
          return false;
        }
      });
  },


  /**
   * Initializes the skip group structure process for a specific client.
   */
  initializeSkipGroupStructure: function(component) {
    var helper = this; // eslint-disable-line
    var account = component.get('v.firstaccountforfilldata');
    var CLIENT = 'SUBSIDIARY';
    let clientorgroupnumber = account.accNumber;
    if (account.participantType === CLIENT) {
      // When client.
      return helper.getpreviousArce(component, helper);
    } else {
      // When group.
      let ffssTestCall = helper.ffssTestCall(component, clientorgroupnumber);
      return ffssTestCall.then(function() {
        return helper.getpreviousArce(component, helper);
      });
    }
  },

  /**
   * Chains promises for service calls related to economic participants and group structure.
   *
   * @returns {Promise} A promise that resolves when all service calls are complete.
   */
  chainingpromisesforservice: function(component) {
    var account = component.get('v.firstaccountforfilldata');
    component.set('v.accountInfo.accNumber', account.accNumber);
    var CLIENT = 'SUBSIDIARY';
    var helper = this; // eslint-disable-line

    if (account.participantType === CLIENT) {
      let clientorgroupnumber = account.accNumber;

      let economicpar = helper.economicpartservice(component, clientorgroupnumber);
      return economicpar.then(function(result) {
        return helper.listparticipant(component, result);
      }).then(function() {
        return helper.groupstructure(component, component.get('v.listparticipant'), component.get('v.economicparticipant'), clientorgroupnumber, helper);
      }).then(function(result) {
        return helper.getpreviousArce(component, helper, result);
      });
    } else {
      //when is group
      let grpid = account.accId;
      let clientorgroupnumber = account.accNumber;
      component.set('v.accountInfo.groupId', grpid);
      component.set('v.accountInfo.isorphan', false);
      component.set('v.accountInfo.orphanNumber', '');
      component.set('v.idofarceexecutor', component.get('v.recordId'));

      let ffssTestCall = helper.ffssTestCall(component, clientorgroupnumber);
      return ffssTestCall.then(function() {
        return helper.listparticipant(component, clientorgroupnumber);
      }).then(function() {
        return helper.groupstructure(component, component.get('v.listparticipant'), component.get('v.economicparticipant'), clientorgroupnumber, helper);
      }).then(function(result) {
        return helper.getpreviousArce(component, helper, result);
      });
    }
  },

  /**
   * Performs a test call to the corresponding financial statements service.
   *
   * @param {String} accountNumber - The account number for the FFSS test.
   * @returns {Promise} A promise that resolves with the FFSS test results.
   */
  ffssTestCall: function(component, accountNumber) {
    const selectedArceType = component.get('v.selectedArceType');
    const eeffCheck = component.get('v.eeffCheck');
    if (selectedArceType === 'raip' && eeffCheck) {
      const action = component.get('c.performFfssTestCall');
      action.setParams({ accountNumber });

      return this.promisifyAndCallAction(action);
    } else {
      return Promise.resolve();
    }
  },

  /**
   * Retrieves a list of participants for the selected client.
   *
   * @param {String} result - The result of the list participant service.
   * @returns {Promise} A promise that resolves with the list of participants.
   */
  listparticipant: function(component, result) {
    var listpartaction = component.get('c.listparticipant');

    // Check if orphan. If it is, call to listParticipants service will be skipped.
    var isOrphan = component.get('v.accountInfo.isorphan');
    listpartaction.setParams({
      'encryptedgroup': result,
      'isOrphan': isOrphan
    });

    return this.promisifyAndCallAction(listpartaction)
      .then(function(response) {
        component.set('v.listparticipant', response);
        var listparticipantsdetails = JSON.parse(response);
        if (listparticipantsdetails.customersdata || listparticipantsdetails.error204message) {
          return Promise.resolve();
        } else if (listparticipantsdetails.servicecallerror || listparticipantsdetails.errormessage) {
          component.set('v.errorMessage', $A.get('{!$Label.c.Arc_Gen_SpinnerMessageError}'));
          return Promise.reject();
        } else {
          return Promise.resolve();
        }
      })
      .catch(function() {
        component.set('v.errorMessage', $A.get('{!$Label.c.Arc_Gen_SpinnerMessageError}'));
        throw new Error('Execution failed');
      });
  },

  /**
   * Executes the economic participant service to retrieve related data.
   *
   * @param {String} result - The result of the economic participant service.
   * @returns {Promise} A promise that resolves with economic participant information.
   */
  economicpartservice: function(component, result) {
    var econpartaction = component.get('c.economicarticipants');

    econpartaction.setParams({
      'encryptedClient': result
    });

    return this.promisifyAndCallAction(econpartaction)
      .then(function(response) {
        component.set('v.economicparticipant', response);
        var economicparticipants = JSON.parse(response);
        component.set('v.accountInfo.isorphan', economicparticipants.isorphan === null ? false : economicparticipants.isorphan);
        if (economicparticipants.isorphan) {
          component.set('v.accountInfo.orphanNumber', economicparticipants.groupinfo.groupid);
        }
        if (economicparticipants.groupinfo) {
          return Promise.resolve(economicparticipants.groupinfo.groupid);
        } else if (economicparticipants.errormessage || economicparticipants.servicecallerror) {
          component.set('v.errorMessage', $A.get('{!$Label.c.Arc_Gen_SpinnerMessageError}'));
          return Promise.reject();
        } else {
          return Promise.resolve();
        }
      })
      .catch(function() {
        component.set('v.errorMessage', $A.get('{!$Label.c.Arc_Gen_SpinnerMessageError}'));
        throw new Error('Execution failed');
      });
  },

  /**
   * Retrieves group structure information for the selected client.
   *
   * @param {String} listparticipant - The list of participants data.
   * @param {String} economicparticipant - The economic participant data.
   * @param {String} clientorgroupnumber - The client or group number.
   * @returns {Promise} A promise that resolves with group structure information.
   */
  groupstructure: function(component, listparticipant, economicparticipant, clientorgroupnumber, helper) {
    var groupstructure = component.get('c.constructgroupstructure');

    groupstructure.setParams({
      'listparticipant': listparticipant,
      'economicparticipant': economicparticipant,
      'accountNumber': clientorgroupnumber,
      'isOrphan': component.get('v.accountInfo.isorphan')
    });

    return this.promisifyAndCallAction(groupstructure)
      .then(function(result) {
        var resp = JSON.parse(result);
        var arceType = component.get('v.selectedArceType');

        component.set('v.accountInfo.accounts', JSON.stringify(resp.participantsOnline));

        // Save map isHolding with accNumber as key and value of listParticipant service
        component.set('v.isHolding', JSON.stringify(resp.isHolding));

        // If RAIP, idofarceexecutor must be the current account, not the group.
        if (arceType !== 'raip') {
          component.set('v.idofarceexecutor', resp.groupID);
        }
        if (component.get('v.accountInfo.isorphan') && resp.noGroupsInSf === false) {
          component.set('v.accountInfo.groupId', resp.orphanId);
          return Promise.resolve(resp);
        } else if (resp.noGroupsInSf === false) {
          component.set('v.accountInfo.groupId', resp.groupID);
          return Promise.resolve(resp);
        } else {
          component.set('v.errorMessage', $A.get('{!$Label.c.Arc_Gen_NoGroupInARCE}'));
          return Promise.reject();
        }
      })
      .catch(function() {
        component.set('v.errorMessage', $A.get('{!$Label.c.Arc_Gen_SpinnerMessageError}'));
        throw new Error('Execution failed');
      });
  },

  /**
   * Retrieves the previous ARCE information and checks for redirection.
   *
   * @param {Object} structure - The group structure information.
   * @returns {Promise} A promise that resolves with the previous ARCE data and redirection status.
   */
  getpreviousArce: function(component, helper, structure) {
    var resumeArce = component.get('v.continue');

    var previousarce = component.get('c.getExistingArce');
    previousarce.setParams({
      'recordId': component.get('v.recordId'),
      'accountswraper': component.get('v.accountInfo.accounts'),
      'arceType': component.get('v.selectedArceType'),
      'structure': JSON.stringify(structure)
    });

    return this.promisifyAndCallAction(previousarce)
      .then(function(result) {
        // Set previousArce wrapper to attribute for send analysisWizard cmp
        component.set('v.previousArce', result);

        // Set account number and type.
        component.set('v.clientNumber', result.accountNumber);
        component.set('v.clientOrGroup', result.accHasAnaType);

        // Redirect to current ARCE if it already exists.
        if (result.modifiedStrucGroup && result.redirectRevoke) {
          helper.evalModifiedStruct(component, helper, result);
        } else {
          helper.initTypesArce(component, helper, resumeArce, result);
        }
        return component.get('v.redirect');
      });
  },

  /**
   * Evaluates modified structure and handles redirection if required.
   *
   * @param {Object} result - The result containing modified structure data.
   * @returns {Boolean} Returns true if redirection is required; otherwise, false.
   */
  evalModifiedStruct: function(component, helper, result) {
    var redirect = false;
    if (result.wfStage !== '3') {
      helper.handleRedirect(component, 'account', result.accountId);
      redirect = true;
    } else {
      helper.setOptionsArce(component, false, true, true);
    }
    return redirect;
  },

  /**
   * Initializes options for the ARCE type based on the previous ARCE and ARCE type.
   *
   * @param {Boolean} resumeArce - Indicates whether the ARCE is being resumed.
   * @param {Boolean} isRaip - Indicates whether the ARCE type is RAIP.
   */
  initTypesArce: function(component, helper, resumeArce, result) {
    if (result.idARCE && !resumeArce && result.wfStage !== '3') {
      helper.handleRedirect(component, 'analysis', result.idARCE);
    } else if (result.idARCE && resumeArce) {
      component.set('v.existingArceId', result.idARCE);
      component.set('v.existingArceIdToModification', result.arceExistingId);
    } else if (helper.checkEval(component, result.wfStatus, result.wfStage, result.sanctionType, result.modification, result.renovation)) {
      helper.setOptionsArce(component, true, !result.modification, !result.renovation);
      component.set('v.existingArceIdToModification', result.idARCE);
    } else {
      helper.setOptionsArce(component, false, true, true);
    }
  },

  /**
   * Checks if the provided criteria are met for evaluation.
   *
   * @param {string} wfStatus - The workflow status.
   * @param {string} wfStage - The workflow stage.
   * @param {string} sanctionType - The sanction type.
   * @param {boolean} modification - Indicates if there is a modification.
   * @param {boolean} renovation - Indicates if there is a renovation.
   * @returns {boolean} True if the criteria are met, false otherwise.
   */
  checkEval: function(component, wfStatus, wfStage, sanctionType, modification, renovation) {
    return wfStatus === '10' && wfStage === '3' && (sanctionType === '1' || sanctionType === '2') && (modification || renovation);
  },

  /**
   * Sets analysis options in the component attributes.
   *
   * @param {string} newOpt - The new analysis option.
   * @param {string} mod - The modification analysis option.
   * @param {string} reno - The renovation analysis option.
   */
  setOptionsArce: function(component, newOpt, mod, reno) {
    component.set('v.NewAnalysis', newOpt);
    component.set('v.ModAnalysis', mod);
    component.set('v.RenoAnalysis', reno);
  },

  /**
   * Redirects to the analysis page and displays a success message.
   *
   * @param {string} arceId - The analysis record ID.
   */
  redirectAnalysis: function(component, arceId) {
    // Refresh view.
    $A.get('e.force:refreshView').fire();

    // Show toast.
    var resultsToast = $A.get('e.force:showToast');
    resultsToast.setParams({
      'title': $A.get('{!$Label.c.Lc_arce_newAnalysisSuccess}'),
      'type': 'success',
      'message': $A.get('{!$Label.c.Lc_arce_redirectingURL}'),
      'duration': '5000'
    });
    resultsToast.fire();

    // Navigate to analysis page.
    var navService = component.find('navService');
    if (!navService) {
      window.location.href = '/'  + arceId;
    } else {
      navService.navigate({
        type: 'standard__recordPage',
        attributes: {
          actionName: 'view',
          objectApiName: 'arce__Analysis__c',
          recordId: arceId
        }
      });
    }
  },

  /**
   * Redirects to an account page and displays a success message.
   *
   * @param {string} accountId - The account ID.
   */
  redirectAccount: function(component, accountId) {
    // Refresh view.
    $A.get('e.force:refreshView').fire();

    // Show toast.
    var resultsToast = $A.get('e.force:showToast');
    resultsToast.setParams({
      'title': $A.get('{!$Label.c.Lc_arce_newAnalysisSuccess}'),
      'type': 'success',
      'message': 'Redirect account',
      'duration': '5000'
    });
    resultsToast.fire();

    // Navigate to analysis page.
    var navService = component.find('navService');
    if (!navService) {
      window.location.href = '/'  + accountId;
    } else {
      navService.navigate({
        type: 'standard__recordPage',
        attributes: {
          actionName: 'view',
          objectApiName: 'Account',
          recordId: accountId
        }
      });
    }
  },

  /**
   * Changes the subtitle text based on the current step.
   */
  changeSubtitle: function(component) {
    const currentStep = component.get('v.currentStep');
    var subtitleText = '';

    switch (currentStep) {
      case 'ratingSystemSelection':
        subtitleText = $A.get('{!$Label.c.Arc_Gen_RTC_RSSelection}');
        break;
      case 'redirectToArce':
        subtitleText = $A.get('{!$Label.c.Arc_Gen_Analysis_ST_RedirectToARCE}');
        break;
    }

    component.set('v.subtitleText', subtitleText);
  },

  /**
   * Reusable method that romisifies and executes an action, resolving or rejecting based on the result.
   *
   * @param {Object} action - The action to execute.
   * @returns {Promise} A promise that resolves with the result or rejects with an error.
   */
  promisifyAndCallAction: function(action) {
    return new Promise($A.getCallback((resolve, reject) => {
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
    }));
  },

  /**
   * Shows a renovation message and redirects to an existing ARCE.
   *
   * @param {string} arceId - The analysis record ID.
   */
  showRenovationMessage: function(component, arceId) {
    var helper = this; // eslint-disable-line

    component.set('v.currentStep', 'renovationMessage');
    component.set('v.currentProgressStep', 'redirectToArce');
    component.set('v.loading', false);
    component.set('v.backHidden', true);
    component.set('v.nextHidden', true);

    helper.changeSubtitle(component);
    setTimeout($A.getCallback(function() {
      helper.redirectAnalysis(component, arceId);
    }), 10000);
  },

  /**
   * Sets the loading state and optionally clears the subtitle text.
   *
   * @param {Object} parameters - Loading state parameters.
   */
  evalSetLoading: function(component, parameters) {
    component.set('v.loading', parameters.loading);
    if (parameters.loading) {
      component.set('v.subtitleText', '');
    }
  },

  /**
   * Retrieves the EEFF service check from the custom metadata configuration.
   */
  getEEFFServiceCheck: function(component) {
    var action = component.get('c.getEEFFServiceCheck');

    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === 'SUCCESS') {
        var res = response.getReturnValue();
        component.set('v.eeffCheck', res);
      }
    });
    $A.enqueueAction(action);
  },

  /**
   * Retrieves the OptIrpTypeCustomer based on the specified criteria and updates the component attributes accordingly.
   *
   * @param {String[]} irpAvailableCustomer - An array of available client types.
   */
  getOptIrpTypeCustomer: function(component, helper, irpAvailableCustomer) {
    const getAccInfoPromise = this.getfullaccountforservices(component, false, true);
    getAccInfoPromise.then(function() {
      var availableArces = component.get('v.availableArceTypes');
      var getAcc = component.get('v.firstaccountforfilldata');
      var arrayPos = helper.getPositionTypesVar(component);
      const testGroup = irpAvailableCustomer.includes('Group');
      const testSubsidiary = irpAvailableCustomer.includes('Subsidiary');
      const isProspect = getAcc.isProspect;
      if (getAcc.participantType === 'GROUP' && !testGroup && arrayPos[0] !== undefined) {
        availableArces.splice(arrayPos[0], 1);
        component.set('v.availableArceTypes', availableArces);
      } else if (getAcc.participantType === 'SUBSIDIARY' && !testSubsidiary) {
        if (arrayPos[0] !== undefined) {
          availableArces.splice(arrayPos[0], 1);
        } else if (arrayPos[1] !== undefined) {
          availableArces.splice(arrayPos[1], 1);
        }
        component.set('v.availableArceTypes', availableArces);
      }
      component.set('v.loading', false);
      component.set('v.isProspect', isProspect);
    }).catch(function() {
      component.set('v.errorMessage', 'Could not resume ARCE analysis. Please contact your system administrator.');
      component.set('v.loading', false);
    });
  },

  /**
   * Retrieves the positions of 'RAIP' and 'Analysis' in the availableArces array.
   *
   * @returns {Number[]} An array of two numbers representing the positions of 'RAIP' and 'Analysis'.
   */
  getPositionTypesVar: function(component) {
    var availableArces = component.get('v.availableArceTypes');
    var lstRet = [];
    var posIrp = null;
    var posArce = null;
    for (var i = 0; i < availableArces.length; i++) {
      posIrp = availableArces[i] === 'RAIP' && posIrp === null ? i : posIrp;
      posArce = availableArces[i] === 'Analysis' && posArce === null ? i : posArce;
    }
    lstRet.push(posIrp);
    lstRet.push(posArce);
    return lstRet;
  },

  /**
   * Sets the profiling message and updates component attributes based on the selected ARCE type.
   *
   * @param {String} arceSelctd - The selected ARCE type.
   */
  setProfilingMsg: function(component, event, helper, arceSelctd) {
    let profiling = component.get('v.profilingRating');

    if (profiling === 'false' || !profiling || arceSelctd === 'analysis') {
      component.set('v.nextDisabled', false);
      return;
    }

    let byModel = profiling.split(';');
    let mssg = $A.get('{!$Label.c.Arc_Gen_AllowedRaipFlows}') + '<br>';
    byModel.forEach(function(val, ind, byMod) {
      let model = val.split(':')[0] === '2019' ? '2021' : val.split(':')[0];
      mssg = mssg + 'model ' + model + ':';
      let flows = val.substr(5);
      mssg = flows.includes('IRP') ? mssg + ' IRP' : mssg;
      mssg = flows.includes('ARP') ? mssg + ' ARP' : mssg;
      mssg = flows.includes('CRP') ? mssg + ' CRP' : mssg;
      mssg = mssg + '<br>';
    });

    if (mssg.includes('IRP') || mssg.includes('ARP') || mssg.includes('CRP')) {
      component.set('v.profilingMssg', mssg.split('<br>'));
      component.set('v.nextDisabled', false);
    } else {
      component.set('v.profilingMssg', $A.get('{!$Label.c.Arc_Gen_NoActiveFlow}'));
      component.set('v.nextDisabled', true);
    }

    if (component.get('v.selectedArceType') === 'sp2Analysis') {
      component.set('v.profilingMssg', []);
      component.set('v.nextDisabled', false);
    }
  },

  /**
   * Displays a toast message with the specified title, type, and message.
   *
   * @param {string} title - The title of the toast message.
   * @param {string} type - The type of the toast (e.g., "success").
   * @param {string} message - The message to display in the toast.
   */
  showToast: function(title, type, message) {
    var toast = $A.get('e.force:showToast');
    toast.setParams({
      title: title,
      type: type,
      message: message,
      duration: '5000'
    });
    toast.fire();
  },

  /**
   * Handles the next action when the selected step is 'ratingSystemSelection'.
   */
  handleRatingSystemNext: function(component, event, helper) {
    const nextStep = component.get('v.selectedArceType');

    component.set('v.loading', true);
    component.set('v.subtitleText', '');

    const getAccInfoPromise = helper.getfullaccountforservices(component, true);
    getAccInfoPromise.then(function(redirected) {
      component.set('v.loading', false);

      if (nextStep === 'sp2Analysis') {
        helper.create2021RTCAnalysis(component);
      }

      if (nextStep === 'ifisAnalysis') {
        helper.createIfisAnalysis(component);
      }

      if (!redirected) {
        component.set('v.currentStep', nextStep);
      }
    }).catch(function(err) {
      component.set('v.loading', false);
      if (typeof(err) === 'string') {
        component.set('v.errorMessage', $A.get('$Label.c.Lc_arce_NewARCE_CouldNotCreate').replace('{0}', err));
      } else {
        component.set('v.errorMessage', $A.get('$Label.c.Lc_arce_NewARCE_UnexpectedError'));
      }
      helper.changeSubtitle(component);
    });
  },

  /**
   * Creates an 2021RTC analysis component if it does not already exist and appends it to the specified component's body.
   * If an 2021RTC analysis component with the specified aura:id already exists, it is destroyed before creating a new one.
   */
  create2021RTCAnalysis: function(component) {
    if (component.find('rtc2021-wizard')) {
      component.find('rtc2021-wizard').destroy();
    }
    const params = {
      'aura:id': 'rtc2021-wizard',
      'localClientId': component.get('v.actualClientId'),
      'accountId': component.get('v.recordId'),
      'modelOptions': component.get('v.modelOptions'),
      'formDataMap': component.get('v.formDataMap'),
      'wizardEvent': component.getReference('c.handleEventWizard'),
      'isProspect': component.get('v.isProspect')
    };
    $A.createComponent('arce:Arc_Gen_2021RTC_Wizard_CMP', params, function(elem, status, errorMessage) {
      if (status === 'SUCCESS') {
        const body = component.get('v.RTC2021Analysis') || [];
        body.push(elem);

        component.set('v.RTC2021Analysis', body);
      } else if (status === 'ERROR') {
        console.error('Error creating 2021RTCAnalysis component:', errorMessage);
      }
    });
  },

  /**
   * Creates an IFIS analysis component if it does not already exist and appends it to the specified component's body.
   * If an IFIS analysis component with the specified aura:id already exists, it is destroyed before creating a new one.
   */
  createIfisAnalysis: function(component) {
    if (component.find('ifis-wizard')) {
      component.find('ifis-wizard').destroy();
    }
    const selectedClient = component.get('v.selectedClient');
    const params = {
      'aura:id': 'ifis-wizard',
      'recordId': component.get('v.recordId'),
      'actualClient': component.get('v.firstaccountforfilldata'),
      'formDataMap': component.get('v.formDataMap'),
      'modelOptions': component.get('v.modelOptions'),
      'currentStep': component.get('v.currentStep'),
      'representativeClient': selectedClient ? selectedClient[0].value : component.get('v.recordId'),
      'wizardEvent': component.getReference('c.handleEventWizard'),
      'isProspect': component.get('v.isProspect'),
    };
    $A.createComponent('arce:Arc_IFIS_Wizard_CMP', params, function(elem, status, errorMessage) {
      if (status === 'SUCCESS') {
        const body = component.get('v.ifisAnalysis') || [];
        body.push(elem);

        component.set('v.ifisAnalysis', body);
      } else if (status === 'ERROR') {
        console.error('Error creating ifisAnalysis component:', errorMessage);
      }
    });
  },

  /**
   * Handles the event when the 'changeStep' event type is selected.
   */
  handleEventChangeStep: function(component, parameters) {
    if (parameters.loading !== null && parameters.loading !== undefined) {
      component.set('v.loading', parameters.loading);
    }
    if (parameters.enabled !== null && parameters.enabled !== undefined) {
      component.set('v.nextDisabled', !parameters.enabled);
    }
    if (parameters.step !== null && parameters.step !== undefined) {
      component.set('v.currentProgressStep', parameters.step);
    }
    component.set('v.subtitleText', parameters.text);
  },

  /**
   * Handles the event when the 'ratingSystem' event type is selected.
   */
  /* eslint-disable camelcase */
  handleEventRatingSystem: function(component, parameters, helper) {
    const isProspect = component.get('v.isProspect');
    const formDataMap = parameters.formDataMap || {};
    const { arce__rating_system__c, arce__RAR_rating_tool_id__c } = formDataMap;
    const isValid = arce__rating_system__c !== undefined && arce__RAR_rating_tool_id__c !== undefined;

    component.set('v.errorMessage', parameters.error);
    component.set('v.warningMessage', parameters.warning);
    component.set('v.formDataMap', formDataMap);
    component.set('v.nextDisabled', !isValid);

    let selectedArceType = '';
    if (isValid) {
      if (!arce__RAR_rating_tool_id__c.includes('IFIS') && arce__RAR_rating_tool_id__c !== '2021RTC_NBF') {
        selectedArceType = 'sp2Analysis';
      } else {
        selectedArceType = 'ifisAnalysis';
      }
      component.set('v.selectedArceType', selectedArceType);
    }
  },
  /* eslint-enable camelcase */

  /**
   * Fires a custom event with the specified event type and parameters.
   *
   * @param {string} eventType - The type of the event to fire.
   * @param {Object} parameters - The parameters to include in the event.
   */
  fireEventWizard: function(component, eventType, parameters) {
    const wizardEvent = component.getEvent('wizardEvent');
    wizardEvent.setParams({
      eventType: eventType,
      parameters: parameters,
    });
    wizardEvent.fire();
  },
});