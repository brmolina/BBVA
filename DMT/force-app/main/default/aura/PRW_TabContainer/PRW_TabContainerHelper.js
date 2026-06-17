({
  getAccountFromURL: function(component, helper) {
    var sPageURL = decodeURIComponent(window.location.search.substring(1));
    var sURLVariables = sPageURL.split('&');
    var sParameterName;
    for (var i = 0; i < sURLVariables.length; i++) {
      sParameterName = sURLVariables[i].split('=');
      helper.getDataFromURL(component, sParameterName, 'c__accountId', 'v.accountId' );
      helper.getDataFromURL(component, sParameterName, 'c__lAccountId', 'v.lAccountId' );
      helper.getDataFromURL(component, sParameterName, 'c__startDate', 'v.profSheetStart' );
      helper.getDataFromURL(component, sParameterName, 'c__endDate', 'v.profSheetEnd' );
      helper.getDataFromURL(component, sParameterName, 'c__sheetSFId', 'v.profSheetSFId' );
      helper.getDataFromURL(component, sParameterName, 'c__sheetId', 'v.profSheetId' );
      helper.getDataFromURL(component, sParameterName, 'c__isGroup', 'v.isGroup');
    }
    if(component.get('v.isGroup') !== 'true') {
      component.set('v.isGroup', 'false');
    }
  },
  getAccountInfo: function(component, helper) {
    var action = component.get('c.gtInfoAccount');
    action.setParams({
      recordId: component.get('v.accountId')
    });
    var promise = this.promisifyTabContAction(action);
      return promise.then(
        $A.getCallback(function(result) {
            component.set('v.acc', result);
            if(component.get('v.profSheetSFId') === undefined) {
              helper.getProfSheetInfo(component, helper);
            } else {
              helper.gtParticipants(component, helper);
            }
        }),
        $A.getCallback(function(error) {
          console.error( 'Error calling action "' + action + '" with state: ' + error.message );
        })
      ).catch(function(e){
      });
  },
  getProfSheetInfo: function(component, helper) {
    var actionSheet = component.get('c.gtProfSheet');
    actionSheet.setParams({
      accId: component.get('v.accountId')
    });
    var promise = this.promisifyTabContAction(actionSheet);
      return promise.then(
        $A.getCallback(function(result) {
          if(result === null) {
            component.set('v.conditionWrp', 'empty');
            var serviceEvent = $A.get("e.c:PRW_ServiceCUCOEvt");
            serviceEvent.setParam('conditionWrp', 'empty');
            serviceEvent.fire();
          } else {
            component.set('v.profSheetSFId', result.cuco__gf_profitability_sheet_id__r.Id);
            component.set('v.profSheetId', result.cuco__gf_profitability_sheet_id__r.cuco__gf_profitability_sheet_id__c);
            component.set('v.profSheetEnd', result.cuco__gf_profitability_sheet_id__r.cuco__gf_prftbly_sheet_end_date__c);
            component.set('v.profSheetStart', result.cuco__gf_profitability_sheet_id__r.cuco__gf_prftbly_sheet_start_date__c);
            component.set('v.profSheet', result);
            helper.gtParticipants(component, helper);
          }
        }),
        $A.getCallback(function(error) {
          console.error( 'Error calling action "' + actionSheet + '" with state: ' + error.message );
        })
      ).catch(function(e){
      });
  },
  gtParticipants: function(component, helper) {
    var partcipantsAction = component.get('c.gtParticipants');
    partcipantsAction.setParams({
      profShId: component.get('v.profSheetSFId')
    });
    var promise = this.promisifyTabContAction(partcipantsAction);
      return promise.then(
        $A.getCallback(function(result) {
          component.set('v.lAccountNames', result);
          helper.gtCuCoConditions(component, helper);
        }),
        $A.getCallback(function(error) {
          console.error( 'Error calling action "' + partcipantsAction + '" with state: ' + error.message );
        })
      ).catch(function(e){
      });
  },
  gtCuCoConditions: function(component, helper) {
    var cucoCond = component.get('c.gtCuCoConditions');
    cucoCond.setParams({
      cucoSFId: component.get('v.profSheetSFId'),
      cucoId: component.get('v.profSheetId')
    });
    var promise = this.promisifyTabContAction(cucoCond);
      return promise.then(
        $A.getCallback(function(result) {
          if(result.success) {
            helper.gtAmmountConditions(component, helper, JSON.stringify(result.profSheetDetails));
          }
        }),
        $A.getCallback(function(error) {
          console.error( 'Error calling action "' + cucoCond + '" with state: ' + error.message );
        })
      ).catch(function(e){
      });
  },
  gtAmmountConditions: function(component, helper, serializeConditions) {
    var actionSheet = component.get('c.gtCucoNamesAndAmount');
    actionSheet.setParams({
      sConditions: serializeConditions
    });
    var promise = this.promisifyTabContAction(actionSheet);
      return promise.then(
        $A.getCallback(function(result) {
          helper.gtcatalog(component, helper, result);
        }),
        $A.getCallback(function(error) {
          console.error( 'Error calling action "' + actionSheet + '" with state: ' + error.message );
        })
      ).catch(function(e){
      });
  },
  gtcatalog : function(component, helper, serializeConditions){
    var actionCatalog = component.get('c.gtCatalog');
    var promise = this.promisifyTabContAction(actionCatalog);
      return promise.then(
        $A.getCallback(function(result) {
          var current = helper.firstCalculate(serializeConditions);
          component.set('v.conditionWrp', serializeConditions);
          component.set('v.catalog',result.catalog);
          var firstEvent = $A.get("e.c:PRW_FirstCalculateEvt");
          firstEvent.setParam('dataProcessed', JSON.stringify(current));
          firstEvent.setParam('conditionWrp', serializeConditions);
          firstEvent.setParam('catalog', result.catalog);
          firstEvent.fire();
        }),
        $A.getCallback(function(error) {
          console.error( 'Error calling action "' + actionSheet + '" with state: ' + error.message );
        })
      ).catch(function(e){
      });
  },

  firstCalculate: function(dataSer) {
    var currentData = [];
    var newData = JSON.parse(dataSer);
    for(var i = 0; i < newData.length; i++) {
      currentData.push(
        {
          id: i+1,
          product: newData[i].name,
          id_prod: newData[i].idProd,
          agreedP: parseFloat(newData[i].price) === null ? 0 : parseFloat(newData[i].price),
          agreedQ: parseFloat(newData[i].quantity) === null ? 0 : parseFloat(newData[i].quantity),
          simulatedP: 0,
          simulatedQ: 0,
          expRevenue: parseFloat(newData[i].price) === null || parseFloat(newData[i].quantity) === null ? 0 : parseFloat(newData[i].price) * parseFloat(newData[i].quantity),
          isDisabled: true
        }
      );
    }
    return currentData;
  },
  promisifyTabContAction: function(actionInfoAcc) {
    return new Promise((resolve, reject) => {
      actionInfoAcc.setCallback(this, function(response) {
        const statusInfo = response.getState();
        if (statusInfo === 'SUCCESS') {
          const returnValue = response.getReturnValue();
          resolve(returnValue);
        } else if (statusInfo === 'ERROR') {
          var errorsInfo = response.getError();
          if (errorsInfo) {
            if (errorsInfo[0] && errorsInfo[0].message) {
              reject(Error('Error message: ' + errorsInfo[0].message));
            }
          } else {
            reject(Error('Unknown error'));
          }
      }
      });

      $A.enqueueAction(actionInfoAcc);
    });
  },
  getDataFromURL: function(component, sParameterName, urlName, attName ) {
    let parameter;
    if (sParameterName[0] === urlName) {
      parameter = sParameterName[1] === undefined ? 'Not found' : sParameterName[1];
    }
    if(component.get(attName) === undefined || component.get(attName) === null) {
      component.set(attName,parameter);
    }
  },
})