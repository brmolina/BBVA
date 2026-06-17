({
  checkPermisions : function(component) {
    var action = component.get("c.gtPermissions");
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === "SUCCESS") {
        component.set("v.spinnerView",false);
        var storeResponse = response.getReturnValue();
        // set searchResult list with return value from server.
        component.set("v.hasPermissions", storeResponse);
      }
    });
    // enqueue the Action
    $A.enqueueAction(action);
  },
  checkAccountFields : function(component) {
    var idRecord = component.get("v.recordId");
    var action = component.get("c.checkAccountConditions");
    // set param to method
    action.setParams({
      'AccountId': idRecord
    });
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === "SUCCESS") {
        component.set("v.spinnerView",false);
        var storeResponse = response.getReturnValue();
        // set searchResult list with return value from server.
        component.set("v.checkAccountConditions", storeResponse);
      }
    });
    // enqueue the Action
    $A.enqueueAction(action);
  },
  inAccountInit : function(component, event, helper) {
  component.set("v.spinnerView",true);
  var idRecord = component.get("v.recordId");
  var action = component.get("c.getinitAcount");
  // set param to method
  action.setParams({
    'idAccs': idRecord
  });
  action.setCallback(this, function(response) {
    $A.util.removeClass(component.find("mySpinner"), "slds-show");
    var state = response.getState();
    if (state === "SUCCESS") {
      component.set("v.spinnerView",false);
      var storeResponse = response.getReturnValue();
      // set searchResult list with return value from server.
      console.log('>>>>> RESULTADO ACC------> ' + JSON.stringify(storeResponse));
      component.set("v.selectedAcc", storeResponse);
    }
  });
  // enqueue the Action
  $A.enqueueAction(action);

  },
  inOpportunityInit : function(component, event, helper) {
    var idRecord = component.get("v.recordId");

    var action = component.get("c.getinitOpp");
    component.set("v.spinnerView",true);
    // set param to method
    action.setParams({
      'idOpp': idRecord
    });
    action.setCallback(this, function(response) {
      $A.util.removeClass(component.find("mySpinner"), "slds-show");
      var state = response.getState();
      if (state === "SUCCESS") {
        component.set("v.spinnerView",false);
        var storeResponse = response.getReturnValue();
        // set searchResult list with return value from server.
        console.log('>>>>> RESULTADO OPP ------> ' + JSON.stringify(storeResponse[0]));
        console.log('>>>>> RESULTADO ACC ------> ' + JSON.stringify(storeResponse[1]));
        component.set("v.selectedOpp", storeResponse[0]);
        component.set("v.selectedAcc", storeResponse[1]);
        component.set("v.stageOpp", storeResponse[0].StageName);
        if(storeResponse[0].StageName === 'Proposal' || storeResponse[0].StageName === 'Draft Opp' || storeResponse[0].StageName === 'Approval'
        || storeResponse[0].StageName === 'Ready to close') {
          component.set('v.modalView', 'oppButtons');
        } else {
          component.set('v.modalView', 'coffNoCreatable');
        }
      }
    });
    // enqueue the Action
    $A.enqueueAction(action);
  },
  saveCommercialOff : function(component, event, helper) {

    var action2 = component.get("c.saveCommOff");
    component.set("v.spinnerView",true);
    // set param to method
    action2.setParams({
      'apexCommOff' : component.get("v.commOfferAtt"),
      'clientCO': component.get("v.selectedAcc").Id,
      'oppCO': component.get("v.selectedOpp").Id
    });
    action2.setCallback(this, function(response) {
      $A.util.removeClass(component.find("mySpinner"), "slds-show");
      var state2 = response.getState();
      if (state2 === "SUCCESS") {
        component.set("v.spinnerView",false);
        var strResp = response.getReturnValue();
        // set searchResult list with return value from server.
        if(strResp.Id !== null && strResp.Id !== undefined) {
          console.log('>>>>> OFERTA COMERCIAL GUARDADA ');
          var eUrl= $A.get("e.force:navigateToURL");
          eUrl.setParams({
            "url": '/' +strResp.Id
          });
          eUrl.fire();
        }
      }
    });
    // enqueue the action2
    $A.enqueueAction(action2);

  },
  saveCOStan : function(component, event, helper) {
    var act2 = component.get("c.saveCommOff");
    component.set("v.spinnerView",true);
    // set param to method
    act2.setParams({
      'apexCommOff' : component.get("v.commOfferAtt"),
      'clientCO': component.get("v.selectedAcc").Id,
      'oppCO': component.get("v.selectedOpp").Id
    });
    act2.setCallback(this, function(response) {
      $A.util.removeClass(component.find("mySpinner"), "slds-show");
      var stte2 = response.getState();
      if (stte2 === "SUCCESS") {
        component.set("v.spinnerView",false);
        var strRes = response.getReturnValue();
        // set searchResult list with return value from server.
        console.log('>>>>> OFERTA COMERCIAL GUARDADA ');
        if(location.href.length < 200) {
          var eUrl= $A.get("e.force:navigateToURL");
          eUrl.setParams({
            "url": '/lightning/o/dwp_kitv__Visit_Topic__c/new?defaultFieldValues=Commercial_Offer__c=' +strRes.Id
          });
          eUrl.fire();
        } else {
          eUrl= $A.get("e.force:navigateToURL");
          eUrl.setParams({
            "url": '/' +strRes.Id
          });
          eUrl.fire();

        }
      }
    });
    // enqueue the act2
    $A.enqueueAction(act2);
  },
  relateCOtoOpp : function(component, event, helper) {
    var action = component.get("c.relateCo");
    component.set("v.spinnerView",true);
    // set param to method
    action.setParams({
      'commOffrId': component.get("v.selectedCoff").Id,
      'currentOpp': component.get("v.recordId")
    });
    action.setCallback(this, function(response) {
      $A.util.removeClass(component.find("mySpinner"), "slds-show");
      var state = response.getState();
      component.set("v.spinnerView",true);
      if (state === "SUCCESS") {
        component.set("v.spinnerView",false);
        // set searchResult list with return value from server.
        console.log('>>>>> OFERTA COMERCIAL RELACIONADA ');
          window.history.back();
      }
    });
    // enqueue the Action
    $A.enqueueAction(action);
  },
  checkFieldsHelper : function(component, event, helper) {
    if(component.find('continueRfp') != null) {
      if((component.get('v.commOfferAtt.Name') !== null && component.get('v.commOfferAtt.Name') !== '')
      && (component.get('v.selectedAcc') !== null && component.get('v.selectedAcc') !== '{}' && JSON.stringify(component.get('v.selectedAcc')) !== '{}')
      && component.get('v.commOfferAtt.CurrencyIsoCode') !== null
      && (component.get('v.commOfferAtt.coff__gf_commercial_offer_desc__c') != null && component.get('v.commOfferAtt.coff__gf_commercial_offer_desc__c') !== '')
      && component.get('v.commOfferAtt.gf_proposal_requested_ind_type__c')) {
        component.find('continueRfp').set('v.disabled',false);
      } else {
        component.find('continueRfp').set('v.disabled',true);
      }
    } else if(component.find('saveCoff') != null) {
      if((component.get('v.commOfferAtt.Name') != null && component.get('v.commOfferAtt.Name') !== '')
      && (component.get('v.selectedAcc') != null && component.get('v.selectedAcc') !== '{}' && JSON.stringify(component.get('v.selectedAcc')) !== '{}')
      && component.get('v.commOfferAtt.CurrencyIsoCode') != null
      && (component.get('v.commOfferAtt.coff__gf_commercial_offer_desc__c') != null && component.get('v.commOfferAtt.coff__gf_commercial_offer_desc__c') !== '')) {
        component.find('saveCoff').set('v.disabled',false);
      } else {
        component.find('saveCoff').set('v.disabled',true);
      }

    }
  },
  getPicklistVal : function(component, event, helper) {
    var pickvar = component.get("c.pickListValuesIn");
        pickvar.setCallback(this, function(response) {
            var state = response.getState();
            if(state === 'SUCCESS'){
                var list = response.getReturnValue();
                component.set("v.picvalue", list);
            }
        })
        $A.enqueueAction(pickvar);
  },
  rfpCheckHelper : function(component, event, helper) {
    var field1 = component.find("rfpIssueDate");
    var field2 = component.find("rfpReceived");
    var field3 = component.find("rfpPartDe");
    var field4 = component.find("rfpQaDe");
    var field5 = component.find("rfpDueDate");
    if (field1.get("v.validity").valid && field2.get("v.validity").valid
    && field3.get("v.validity").valid && field4.get("v.validity").valid
    && field5.get("v.validity").valid ) {
      component.find('rfpSave').set('v.disabled',false);
    } else {
      component.find('rfpSave').set('v.disabled',true);
    }

  },
  checkRltHelper : function(component, event, helper) {
    if(component.get('v.selectedCoff') !== null && component.get('v.selectedCoff') !== '{}' && JSON.stringify(component.get('v.selectedCoff')) !== '{}') {
      component.find('relateCoId').set('v.disabled',false);
    } else {
      component.find('relateCoId').set('v.disabled',true);
    }
  }
})