({
  getAvailableArceTypes: function(component) {
    const getTypesAction = component.get('c.getAvailableArceTypes');

    return this.promisifyAndCallAction(getTypesAction);
  },

  getShouldShowGroupStructureRaip: function(component) {
    const getShouldShowGs = component.get('c.shouldShowRaipGroupStructure');

    return this.promisifyAndCallAction(getShouldShowGs);
  },

  getAvailableIrpDependCustomer: function(component) {
    const getIrpConfig = component.get('c.getIrpConfigCustomer');

    return this.promisifyAndCallAction(getIrpConfig);
  },

  profilingRating: function(component, event, helper) {
    const getIrpProfiling = component.get('c.profilingResult');

    getIrpProfiling.setParams({
      clientId: component.get('v.recordId')
    });

    return this.promisifyAndCallAction(getIrpProfiling);
  },

  newOrResume: function(component, event, helper) {
    // Check whether an ARCE is being resumed.
    const resumeArce = component.get('v.continue');
    const arceTypeToContinue = component.get('v.arceTypeToContinue');

    if (resumeArce) {
      component.set('v.selectedArceType', arceTypeToContinue);
      const getAccInfoPromise = helper.getfullaccountforservices(component);
      getAccInfoPromise.then(function() {
        component.set('v.currentStep', arceTypeToContinue);
        component.set('v.loading', false);
      }).catch(function() {
        component.set('v.errorMessage', 'Could not resume ARCE analysis. Please contact your system administrator.');
        component.set('v.loading', false);
      });
    } else {
      // Set list of steps.
      component.set('v.progressSteps', [
        { label: $A.get('{!$Label.c.Arc_Gen_Analysis_ST_ArceType}'), value: 'arceTypeSelection' },
        { label: $A.get('{!$Label.c.Arc_Gen_Analysis_ST_GroupStructure}'), value: 'groupStructure' },
        { label: $A.get('{!$Label.c.Arc_Gen_Analysis_ST_RedirectToARCE}'), value: 'redirectToArce' },
      ]);

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
    }
    return Promise.resolve();
  },

  handleArceTypeNext: function(component) {
    const helper = this; // eslint-disable-line
    component.set('v.loading', true);
    component.set('v.subtitleText', '');

    // Build group structure.
    const arceType = component.get('v.selectedArceType');
    const skipGroupStructureRaip = !component.get('v.shouldShowGsRaip');
    const skipGroupStructure = (arceType === 'raip' || arceType === 'sp2Analysis') && skipGroupStructureRaip;
    const nextStep = skipGroupStructure ? arceType : 'groupStructure';

    const getAccInfoPromise = this.getfullaccountforservices(component, skipGroupStructure);
    getAccInfoPromise.then(function(redirected) {
      component.set('v.loading', false);

      if (!redirected) {
        component.set('v.currentStep', nextStep);
        component.set('v.backHidden', false);
        component.set('v.currentProgressStep', nextStep);
        helper.changeSubtitle(component);
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

  handleGroupStructureNext: function(component) {
    const arceType = component.get('v.selectedArceType');

    component.set('v.currentStep', arceType);
    component.set('v.nextDisabled', true);
    this.changeSubtitle(component);
  },

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

  getfullaccountforservices: function(component, skipGroupStructure, onlyGetStructureGroup) {
    var action = component.get('c.getaccdataforservices');
    var helper = this; // eslint-disable-line
    action.setParams({
      recordId: component.get('v.recordId')
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

  chainingpromisesforservice: function(component) {
    var account = component.get('v.firstaccountforfilldata');
    component.set('v.accountInfo.accNumber', account.accNumber);
    var CLIENT = 'SUBSIDIARY';
    var helper = this; // eslint-disable-line

    if (account.participantType === CLIENT) {
      let clientorgroupnumber = account.accNumber;

      let economicpar = helper.economicpartservice(component, clientorgroupnumber);
      return economicpar.then(function(result) {
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
      }).then(function(result) {
        return helper.getpreviousArce(component, helper, result);
      });
    }
  },

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

  /**exectution of economic participant service **/
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
        // Set account number and type.
        component.set('v.clientNumber', result.accountNumber);
        component.set('v.clientOrGroup', result.accHasAnaType);

        // Redirect to current ARCE if it already exists.
        component.set('v.ModStructGroup', result.modifiedStrucGroup);
        if (result.modifiedStrucGroup && result.redirectRevoke) {
          helper.evalModifiedStruct(component, helper, result);
        } else {
          helper.initTypesArce(component, helper, resumeArce, result);
        }
        var redirect = component.get('v.redirect');
        return redirect;
      });
  },

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

  initTypesArce: function(component, helper, resumeArce, result) {
    if (result.idARCE && !resumeArce && result.wfStage !== '3') {
      helper.handleRedirect(component, 'analysis', result.idARCE);
    } else if (result.idARCE && resumeArce) {
      component.set('v.existingArceId', result.idARCE);
      component.set('v.existingArceIdToModification', result.arceExistingId);
    } else if (helper.checkEval(component, result.wfStatus, result.wfStage, result.sanctionType, result.modification, result.renovation) && !result.modifiedStrucGroup) {
      helper.setOptionsArce(component, true, !result.modification, !result.renovation);
      component.set('v.existingArceIdToModification', result.idARCE);
    } else {
      helper.setOptionsArce(component, false, true, true);
    }
  },


  checkEval: function(component, wfStatus, wfStage, sanctionType, modification, renovation) {
    return wfStatus === '10' && wfStage === '3' && (sanctionType === '1' || sanctionType === '2') && (modification || renovation);
  },

  setOptionsArce: function(component, newOpt, mod, reno) {
    component.set('v.NewAnalysis', newOpt);
    component.set('v.ModAnalysis', mod);
    component.set('v.RenoAnalysis', reno);
  },

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

  changeSubtitle: function(component) {
    const currentStep = component.get('v.currentStep');
    var subtitleText = '';

    switch (currentStep) {
      case 'arceTypeSelection':
        subtitleText = $A.get('{!$Label.c.Arc_Gen_Analysis_ST_ArceType}');
        break;
      case 'groupStructure':
        subtitleText = $A.get('{!$Label.c.Arc_Gen_Analysis_ST_GroupStructure}');
        break;
      case 'redirectToArce':
        subtitleText = $A.get('{!$Label.c.Arc_Gen_Analysis_ST_RedirectToARCE}');
        break;
    }

    component.set('v.subtitleText', subtitleText);
  },

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
  evalSetLoading: function(component, parameters) {
    component.set('v.loading', parameters.loading);
    if (parameters.loading) {
      component.set('v.subtitleText', '');
    }
  },
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

  getOptIrpTypeCustomer: function(component, helper, irpAvailableCustomer) {
    const getAccInfoPromise = this.getfullaccountforservices(component, false, true);
    getAccInfoPromise.then(function() {
      var availableArces = component.get('v.availableArceTypes');
      var getAcc = component.get('v.firstaccountforfilldata');
      var arrayPos = helper.getPositionTypesVar(component);
      const testGroup = irpAvailableCustomer.includes('Group');
      const testSubsidiary = irpAvailableCustomer.includes('Subsidiary');
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
    }).catch(function() {
      component.set('v.errorMessage', 'Could not resume ARCE analysis. Please contact your system administrator.');
      component.set('v.loading', false);
    });
  },

  getPositionTypesVar: function(component) {
    var availableArces = component.get('v.availableArceTypes');
    var lstRet = [];
    var posIrp = undefined;
    var posArce = undefined;
    for (var i = 0; i < availableArces.length; i++) {
      posIrp = availableArces[i] === 'RAIP' && posIrp === undefined ? i : posIrp;
      posArce = availableArces[i] === 'Analysis' && posArce === undefined ? i : posArce;
    }
    lstRet.push(posIrp);
    lstRet.push(posArce);
    return lstRet;
  },
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
  showToast: function(title, type, message) {
    // Show toast.
    var toast = $A.get('e.force:showToast');
    toast.setParams({
      'title': title,
      'type': type,
      'message': message,
      'duration': '5000'
    });
    toast.fire();
  }
});