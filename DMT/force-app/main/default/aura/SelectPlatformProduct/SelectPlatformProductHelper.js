({
  getStartFields: function (comp, event, helper) {
    var assetProductIDJS = comp.get('v.assetProductID');
    var action = comp.get("c.getProductFields");

    action.setParams({
      'productID': assetProductIDJS
    });
    action.setCallback(this, function (response) {
      var state = response.getState();
      if (state === "SUCCESS") {
        console.log('>>>>> SUCCESS');
        comp.set('v.selectedPlatform', response.getReturnValue().split("::")[0]);
        comp.set('v.selectedProduct', response.getReturnValue().split("::")[1]);
        comp.set('v.selectedTier', response.getReturnValue().split("::")[2]);
        comp.set('v.oldPlatform', response.getReturnValue().split("::")[0]);
        comp.set('v.oldProduct', response.getReturnValue().split("::")[1]);
        comp.set('v.oldTier', response.getReturnValue().split("::")[2]);
        comp.set('v.onboardType', response.getReturnValue().split("::")[3]);
        comp.set('v.assetType', response.getReturnValue().split("::")[4]);
        comp.set('v.oldPriorPlatform', response.getReturnValue().split("::")[5]);
        comp.set('v.canEdit', response.getReturnValue().split("::")[6]);
        comp.set('v.isClone', response.getReturnValue().split("::")[7]);
        comp.set('v.oldClearingHouse', response.getReturnValue().split("::")[8]);
        comp.set('v.oldAccess', response.getReturnValue().split("::")[9]);
        comp.set('v.oldFormat', response.getReturnValue().split("::")[10]);
        comp.set('v.stage', response.getReturnValue().split("::")[11]);
        comp.set('v.isProfile', response.getReturnValue().split("::")[12]);
        helper.getPriorPlatform(comp, event, helper);
        helper.getPlatform(comp, event, helper);
        helper.getRecordFields(comp, event, helper);
        helper.getRecordFieldsPicklist(comp, event, helper);
        helper.getRecordFieldsExcludePicklist(comp, event, helper);
        helper.getRecordFieldsWrong(comp, event, helper);
        helper.getClearingHouse(comp, event, helper);
        helper.getAccess(comp, event, helper);
        helper.getFormat(comp, event, helper);
      } else {
        console.log('FALLO : ', JSON.stringify(response.getReturnValue()));
      }
    });
    $A.enqueueAction(action);
  },
  getRecordFields: function (comp, event, helper) {
    var assetTypeJS1 = comp.get('v.assetType');
    var onboardTypeJS1 = comp.get('v.onboardType');
    var platformJS1 = comp.get('v.selectedPlatform');
    var productJS1 = comp.get('v.selectedProduct');
    var fieldsToGet1 = 'ALL';
    var action1 = comp.get("c.getFieldSetFromAsset");

    action1.setParams({
      'assetType': assetTypeJS1,
      'onboardType': onboardTypeJS1,
      'platform': platformJS1,
      'product': productJS1,
      'typeToGet': fieldsToGet1,
      'stage': null
    });
    action1.setCallback(this, function (response) {
      var state = response.getState();
      if (state === "SUCCESS") {
        console.log('>>>>> SUCCESS');
        comp.set('v.lFieldsAll', response.getReturnValue());
        helper.getRecordFieldsTrader(comp, event, helper);
      } else {
        console.log('FALLO : ', JSON.stringify(response.getReturnValue()));
      }
    });
    $A.enqueueAction(action1);
  },
  getRecordFieldsTrader: function (comp, event, helper) {

    var actionTrader = comp.get("c.getTraderExclude");

    actionTrader.setParams({
      'listAtt': comp.get('v.lFieldsAll')
    });
    actionTrader.setCallback(this, function (response) {
      var state = response.getState();
      if (state === "SUCCESS") {
        console.log('>>>>> SUCCESS');
        comp.set('v.lFieldsTrader', response.getReturnValue());
      } else {
        console.log('FALLO : ', JSON.stringify(response.getReturnValue()));
      }
    });
    $A.enqueueAction(actionTrader);
  },
  getRecordFieldsWrong: function (comp, event, helper) {
    var assetTypeJS1 = comp.get('v.assetType');
    var onboardTypeJS1 = comp.get('v.onboardType');
    var platformJS1 = comp.get('v.selectedPlatform');
    var productJS1 = comp.get('v.selectedProduct');
    var stageJS1 = comp.get('v.stage');
    var fieldsToGet1 = 'WRONG';
    var action1 = comp.get("c.getFieldSetFromAsset");

    action1.setParams({
      'assetType': assetTypeJS1,
      'onboardType': onboardTypeJS1,
      'platform': platformJS1,
      'product': productJS1,
      'typeToGet': fieldsToGet1,
      'stage': stageJS1
    });
    action1.setCallback(this, function (response) {
      var state = response.getState();
      if (state === "SUCCESS") {
        console.log('>>>>> SUCCESS');
        comp.set('v.lFieldsWrong', response.getReturnValue());
      } else {
        console.log('FALLO : ', JSON.stringify(response.getReturnValue()));
      }
    });
    $A.enqueueAction(action1);
  },
  getRecordFieldsExcludePicklist: function (comp, event, helper) {
    var assetTypeJS2 = comp.get('v.assetType');
    var onboardTypeJS2 = comp.get('v.onboardType');
    var platformJS2 = comp.get('v.selectedPlatform');
    var productJS2 = comp.get('v.selectedProduct');
    var stageJS2 = comp.get('v.stage');
    var fieldsToGet2 = 'EDIT';
    var action2 = comp.get("c.getFieldSetFromAsset");

    action2.setParams({
      'assetType': assetTypeJS2,
      'onboardType': onboardTypeJS2,
      'platform': platformJS2,
      'product': productJS2,
      'typeToGet': fieldsToGet2,
      'stage': stageJS2
    });
    action2.setCallback(this, function (response) {
      var state = response.getState();
      if (state === "SUCCESS") {
        console.log('>>>>> SUCCESS');
        comp.set('v.lFields', response.getReturnValue());
      } else {
        console.log('FALLO : ', JSON.stringify(response.getReturnValue()));
      }
    });
    $A.enqueueAction(action2);
  },
  getRecordFieldsPicklist: function (comp, event, helper) {
    var assetTypeJS3 = comp.get('v.assetType');
    var onboardTypeJS3 = comp.get('v.onboardType');
    var platformJS3 = comp.get('v.selectedPlatform');
    var productJS3 = comp.get('v.selectedProduct');
    var stageJS3 = comp.get('v.stage');
    var fieldsToGet3 = 'PICKLIST';
    var action3 = comp.get("c.getFieldSetFromAsset");

    action3.setParams({
      'assetType': assetTypeJS3,
      'onboardType': onboardTypeJS3,
      'platform': platformJS3,
      'product': productJS3,
      'typeToGet': fieldsToGet3,
      'stage': stageJS3
    });
    action3.setCallback(this, function (response) {
      var state = response.getState();
      if (state === "SUCCESS") {
        console.log('>>>>> SUCCESS');
        comp.set('v.lFieldsPickList', response.getReturnValue());
        helper.setPicklistToUse(comp, event, helper);
      } else {
        console.log('FALLO : ', JSON.stringify(response.getReturnValue()));
      }
    });
    $A.enqueueAction(action3);
  },
  setPicklistToUse: function (comp, event, helper) {
    if(comp.get('v.lFieldsPickList').includes("Prior_Platform__c")) {
      comp.set('v.flagPriorPlatform', true);
    }
    if(comp.get('v.lFieldsPickList').includes("Platform__c")) {
      comp.set('v.flagPlatform', true);
    }
    if(comp.get('v.lFieldsPickList').includes("Product__c")) {
      comp.set('v.flagProduct', true);
    }
    if(comp.get('v.lFieldsPickList').includes("Tier__c")) {
      comp.set('v.flagTier', true);
    }
    if(comp.get('v.lFieldsPickList').includes("Clearing_House__c")) {
      comp.set('v.flagClearingHouse', true);
    } else {
      comp.set('v.flagClearingHouse', false);
    }
    if(comp.get('v.lFieldsPickList').includes("Access__c")) {
      comp.set('v.flagAccess', true);
    } else {
      comp.set('v.flagAccess', false);
    }
    if(comp.get('v.lFieldsPickList').includes("Format__c")) {
      comp.set('v.flagFormat', true);
    } else {
      comp.set('v.flagFormat', false);
    }
  },
  getPlatform: function (comp, event, helper) {
    var assetTypeJS = comp.get('v.assetType');
    var oldPlatformJS = comp.get('v.oldPlatform');
    var action = comp.get("c.getPlatformList");

    action.setParams({
      'assetType': assetTypeJS,
      'oldPlatform': oldPlatformJS
    });
    action.setCallback(this, function (response) {
      var state = response.getState();
      if (state === "SUCCESS") {
        console.log('>>>>> SUCCESS');
        comp.set('v.lPlatform', response.getReturnValue());
        if (comp.get('v.selectedProduct') != null && comp.get('v.isStart') === true) {
          helper.getProductStart(comp, event, helper);
        }
      } else {
        console.log('FALLO : ', JSON.stringify(response.getReturnValue()));
      }
    });
    $A.enqueueAction(action);
  },
  getPriorPlatform: function (comp, event, helper) {
    var assetTypeJS = comp.get('v.assetType');
    var oldPlatformJS = comp.get('v.oldPriorPlatform');
    var action = comp.get("c.getPlatformList");

    action.setParams({
      'assetType': assetTypeJS,
      'oldPlatform': oldPlatformJS
    });
    action.setCallback(this, function (response) {
      var state = response.getState();
      if (state === "SUCCESS") {
        console.log('>>>>> SUCCESS');
        comp.set('v.lPriorPlatform', response.getReturnValue());
      } else {
        console.log('FALLO : ', JSON.stringify(response.getReturnValue()));
      }
    });
    $A.enqueueAction(action);
  },
  getProduct: function (comp, event, helper) {
    comp.set("v.selectedPlatform", comp.find('platform').get("v.value"));
    var assetTypeJS = comp.get('v.assetType');
    var oldPlatformJS = comp.get('v.oldPlatform');
    var oldProductJS = comp.get('v.oldProduct');
    var platformJS = comp.find('platform').get("v.value");
    var action = comp.get("c.getProductList");
    comp.find('product').set("v.value", "empty");
    comp.set('v.lProduct', "");
    comp.set("v.selectedProduct", "null");
    comp.find('tier').set("v.value", "empty");
    comp.set('v.lTier', "");
    comp.set("v.selectedTier", "null");
    helper.getRecordFieldsExcludePicklist(comp, event, helper);
    helper.getRecordFields(comp, event, helper);
    helper.getRecordFieldsPicklist(comp, event, helper);

    action.setParams({
      'assetType': assetTypeJS,
      'platformType': platformJS,
      'oldPlatform': oldPlatformJS,
      'oldProduct': oldProductJS
    });
    action.setCallback(this, function (response) {
      var state = response.getState();
      if (state === "SUCCESS") {
        console.log('>>>>> SUCCESS');
        comp.set('v.lProduct', response.getReturnValue());
      } else {
        console.log('FALLO : ', JSON.stringify(response.getReturnValue()));
      }
    });
    $A.enqueueAction(action);
  },
  getTier: function (comp, event, helper) {
    comp.set("v.selectedPlatform", comp.find('platform').get("v.value"));
    comp.set("v.selectedProduct", comp.find('product').get("v.value"));
    var assetTypeJS = comp.get('v.assetType');
    var oldPlatformJS = comp.get('v.oldPlatform');
    var oldProductJS = comp.get('v.oldProduct');
    var oldTierJS = comp.get('v.oldTier');
    var platformJS = comp.find('platform').get("v.value");
    var productJS = comp.find('product').get("v.value");
    var action2 = comp.get("c.getTierList");
    helper.getRecordFieldsExcludePicklist(comp, event, helper);
    helper.getRecordFields(comp, event, helper);

    action2.setParams({
      'assetType': assetTypeJS,
      'platformType': platformJS,
      'productType': productJS,
      'oldPlatform': oldPlatformJS,
      'oldProduct': oldProductJS,
      'oldTier': oldTierJS
    });
    action2.setCallback(this, function (response2) {
      var state2 = response2.getState();
      if (state2 === "SUCCESS") {
        console.log('>>>>> SUCCESS');
        comp.set('v.lTier', response2.getReturnValue());
      } else {
        console.log('FALLO : ', JSON.stringify(response2.getReturnValue()));
      }
    });
    $A.enqueueAction(action2);
  },
  getProductStart: function (comp, event, helper) {
    var assetTypeJS = comp.get('v.assetType');
    var platformJSNew = comp.get('v.selectedPlatform');
    var oldPlatformJS = comp.get('v.oldPlatform');
    var oldProductJS = comp.get('v.oldProduct');
    var action6 = comp.get("c.getProductList");

    action6.setParams({
      'assetType': assetTypeJS,
      'platformType': platformJSNew,
      'oldPlatform': oldPlatformJS,
      'oldProduct': oldProductJS
    });
    action6.setCallback(this, function (response6) {
      var state6 = response6.getState();
      if (state6 === "SUCCESS") {
        console.log('>>>>> SUCCESS');
        comp.set('v.lProduct', response6.getReturnValue());
        if (comp.get('v.isStart') === true) {
          helper.getTierStart(comp, event, helper);
        }
      } else {
        console.log('FALLO : ', JSON.stringify(response6.getReturnValue()));
      }
    });
    $A.enqueueAction(action6);
  },
  getTierStart: function (comp, event, helper) {
    var assetTypeJS = comp.get('v.assetType');
    var oldPlatformJS = comp.get('v.oldPlatform');
    var oldProductJS = comp.get('v.oldProduct');
    var oldTierJS = comp.get('v.oldTier');
    var platformJS = comp.get('v.selectedPlatform');
    var productJS = comp.get('v.selectedProduct');
    var action8 = comp.get("c.getTierList");
    helper.getRecordFieldsExcludePicklist(comp, event, helper);
    helper.getRecordFields(comp, event, helper);

    action8.setParams({
      'assetType': assetTypeJS,
      'platformType': platformJS,
      'productType': productJS,
      'oldPlatform': oldPlatformJS,
      'oldProduct': oldProductJS,
      'oldTier': oldTierJS
    });
    action8.setCallback(this, function (response8) {
      var state8 = response8.getState();
      if (state8 === "SUCCESS") {
        console.log('>>>>> SUCCESS');
        comp.set('v.lTier', response8.getReturnValue());
        if (comp.get('v.isStart') === true) {
          helper.setProductStart(comp, event, helper);
        }
      } else {
        console.log('FALLO : ', JSON.stringify(response8.getReturnValue()));
      }
    });
    $A.enqueueAction(action8);
  },
  getClearingHouse: function (comp, event, helper) {
    var action11 = comp.get("c.getPickListValues");
    var oldvalueJS3 = comp.get('v.oldClearingHouse');

    action11.setParams({
      'picklistAPI': 'Clearing House',
      'oldValue': oldvalueJS3
    });
    action11.setCallback(this, function (response11) {
      var state11 = response11.getState();
      if (state11 === "SUCCESS") {
        console.log('>>>>> SUCCESS');
        comp.set('v.lClearingHouse', response11.getReturnValue());
      } else {
        console.log('FALLO : ', JSON.stringify(response11.getReturnValue()));
      }
    });
    $A.enqueueAction(action11);
  },
  getAccess: function (comp, event, helper) {
    var action13 = comp.get("c.getPickListValues");
    var oldvalueJS13 = comp.get('v.oldAccess');

    action13.setParams({
      'picklistAPI': 'Access',
      'oldValue': oldvalueJS13
    });
    action13.setCallback(this, function (response13) {
      var state13 = response13.getState();
      if (state13 === "SUCCESS") {
        console.log('>>>>> SUCCESS');
        comp.set('v.lAccess', response13.getReturnValue());
      } else {
        console.log('FALLO : ', JSON.stringify(response13.getReturnValue()));
      }
    });
    $A.enqueueAction(action13);
  },
  getFormat: function (comp, event, helper) {
    var action21 = comp.get("c.getPickListValues");
    var oldvalueJS21 = comp.get('v.oldFormat');

    action21.setParams({
      'picklistAPI': 'Format',
      'oldValue': oldvalueJS21
    });
    action21.setCallback(this, function (response21) {
      var state21 = response21.getState();
      if (state21 === "SUCCESS") {
        console.log('>>>>> SUCCESS');
        comp.set('v.lFormat', response21.getReturnValue());
      } else {
        console.log('FALLO : ', JSON.stringify(response21.getReturnValue()));
      }
    });
    $A.enqueueAction(action21);
  },
  setProductStart: function (comp, event, helper) {
    var selPlat = comp.get("v.selectedPlatform");
    var selPriorPlat = comp.get("v.oldPriorPlatform");
    var stageJS = comp.get('v.stage');
    comp.find('platform').set("v.value", selPlat);
    comp.find('priorplatform').set("v.value", selPriorPlat);
    comp.set('v.isStart', false);

    var action = comp.get("c.waitTime");

    action.setParams({
      'timeNumber': 50
    });
    action.setCallback(this, function (response) {
      var selProd = comp.get("v.selectedProduct");
      var selTier = comp.get("v.selectedTier");
      comp.find('product').set("v.value", selProd);
      comp.find('tier').set("v.value", selTier);
      if(stageJS === 'Validate' && comp.get("v.isClone") === 'false' && comp.get("v.isProfile") === 'false') {
        comp.find('tierTrader').set("v.value", selTier);
      }
      var selClearing = comp.get("v.oldClearingHouse");
      comp.find('clearingHouse').set("v.value", selClearing);
      comp.find('access').set("v.value", comp.get("v.oldAccess"));
      comp.find('format').set("v.value", comp.get("v.oldFormat"));
      $A.util.removeClass(comp.find("contenedor"), "slds-hide");
    });
    $A.enqueueAction(action);

  },
  deleteProduct: function (comp, event, helper) {
    var assetProductIDJS = comp.get('v.assetProductID');
    var action = comp.get("c.delAssetProduct");

    action.setParams({
      'assetProdID': assetProductIDJS
    });
    action.setCallback(this, function (response) {
      var state = response.getState();
      if (state === "SUCCESS") {
        console.log('>>>>> SUCCESS');
        var compEvent = comp.getEvent('refreshEvent');
        compEvent.setParams({ 'typeEvent': 'refreshDelete' });
        compEvent.fire();
      } else {
        console.log('FALLO : ', JSON.stringify(response.getReturnValue()));
      }
    });
    $A.enqueueAction(action);
  },
  cloneProduct: function (comp, event, helper) {
    event.preventDefault();
    var flds = event.getParam('fields');
    var asstProduct2 = {};
    var fldsFlds = comp.get('v.lFields');
    var stageJS = comp.get('v.stage');
    console.log(stageJS);
    for (var i = 0; i < fldsFlds.length; i++) {
      asstProduct2[fldsFlds[i]] = flds[fldsFlds[i]];
    }

    asstProduct2['Platform__c'] = comp.find('platform').get("v.value");
    asstProduct2['Prior_Platform__c'] = comp.find('priorplatform').get("v.value");
    console.log("1");
    if(comp.find('clearingHouse').get("v.value") !== 'null'){
      asstProduct2['Clearing_House__c'] = comp.find('clearingHouse').get("v.value");
    }
    console.log("2");
    if(comp.find('tier').get("v.value") !== 'null'){
      console.log(comp.find('tier').get("v.value"));
      asstProduct2['Tier__c'] = comp.find('tier').get("v.value");
    }
    console.log("4");
    if(comp.find('format').get("v.value") !== 'null'){
      asstProduct2['Format__c'] = comp.find('format').get("v.value");
      console.log(comp.find('format').get("v.value"));
    }
    console.log("4");
    if(comp.find('access').get("v.value") !== 'null'){
      asstProduct2['Access__c'] = comp.find('access').get("v.value");
    }
    console.log("5");
    if(comp.find('product').get("v.value") !== 'null'){
      asstProduct2['Product__c'] = comp.find('product').get("v.value");
    }
    console.log("6");
    if(comp.find('access').get("v.value") !== 'null'){
      console.log(comp.find('access').get("v.value"));
      asstProduct2['Access__c'] = comp.find('access').get("v.value");
    }
    console.log(JSON.stringify(asstProduct2));

    var asstPrdsIDs = comp.get('v.assetProductID');
    var action = comp.get("c.cloneAssetProduct");

    action.setParams({
      'assetProdID': asstPrdsIDs,
      'assetProd': asstProduct2
    });
    action.setCallback(this, function (response) {
      var state = response.getState();
      if (state === "SUCCESS") {
        console.log('>>>>> SUCCESS');
        var compEvent = comp.getEvent('refreshEvent');
        compEvent.setParams({ 'typeEvent': 'refreshClone' });
        compEvent.fire();
      } else {
        console.log('FALLO : ', JSON.stringify(response.getReturnValue()));
      }
    });
    $A.enqueueAction(action);
  },
  saveProduct: function (comp, event, helper) {
    event.preventDefault();
    var fields = event.getParam('fields');
    var prodAsset = {};
    var fieldsFields = comp.get('v.lFields');
    for (var i = 0; i < fieldsFields.length; i++) {
      prodAsset[fieldsFields[i]] = fields[fieldsFields[i]];
    }

    prodAsset['Platform__c'] = comp.find('platform').get("v.value");
    prodAsset['Prior_Platform__c'] = comp.find('priorplatform').get("v.value");
    prodAsset['Product__c'] = comp.find('product').get("v.value");
    prodAsset['Tier__c'] = comp.find('tier').get("v.value");
    prodAsset['Clearing_House__c'] = comp.find('clearingHouse').get("v.value");
    prodAsset['Access__c'] = comp.find('access').get("v.value");
    prodAsset['Format__c'] = comp.find('format').get("v.value");
    console.log(JSON.stringify(prodAsset));

    var action = comp.get("c.updateProduct");

    action.setParams({
      'assetProd': prodAsset,
      'prodID': comp.get('v.assetProductID'),
      'assetType': comp.get('v.assetType')
    });
    action.setCallback(this, function (response) {
      var state = response.getState();
      if (state === "SUCCESS") {
        console.log('>>>>> SUCCESS SAVE');
      } else {
        console.log('Error');
      }
    });
    $A.enqueueAction(action);

  },
  saveTierProduct: function (comp, event, helper) {
    event.preventDefault();
    var fields = event.getParam('fields');
    var astProd = {};
    var fieldsFields = comp.get('v.lFields');
    for (var i = 0; i < fieldsFields.length; i++) {
      astProd[fieldsFields[i]] = fields[fieldsFields[i]];
    }
    var stageJS = comp.get('v.stage');
    astProd['Id'] = comp.get('v.assetProductID');
    astProd['Platform__c'] = comp.find('platform').get("v.value");
    astProd['Prior_Platform__c'] = comp.find('priorplatform').get("v.value");
    astProd['Product__c'] = comp.find('product').get("v.value");
    if(stageJS === 'Validate' /*&& comp.get("v.isClone") == 'false'*/ && comp.get("v.isProfile") === 'false') {
      astProd['Tier__c'] = comp.find('tierTrader').get("v.value");
    } else {
      astProd['Tier__c'] = comp.find('tier').get("v.value");
    }
    console.log(JSON.stringify(astProd));

    var act13 = comp.get("c.updateProduct");

    act13.setParams({
      'assetProd': astProd,
      'prodID': comp.get('v.assetProductID')
    });
    act13.setCallback(this, function (response) {
      var status = response.getState();
      if (status === "SUCCESS") {
        console.log('>>>>> SUCCESS SAVE');
      } else {
        console.log('Error');
      }
    });
    $A.enqueueAction(act13);

  },
  getSelected: function (comp, event, helper) {
    comp.set("v.selectedPlatform", comp.find('platform').get("v.value"));
    comp.set("v.selectedProduct", comp.find('product').get("v.value"));
    comp.set("v.selectedTier", comp.find('tier').get("v.value"));
  },
  /*
  * CUIDADO CON CUALQUIER CAMBIO DE CLASES DE SALESFORCE
  *//*
  fieldChange: function (comp, event, helper) {
    var selected = event.getParam('value');
    var assetProductIDJS = comp.get('v.assetProductID');
    var idSpecific = "#Specific_user__c" + assetProductIDJS;

    if(selected == "Select specific user names") {
      $( idSpecific ).removeClass( "toggle" );
      $( idSpecific+"read" ).removeClass( "toggle" );
    }
    else if(selected == "All pending users (Not for Bloomberg)") {
      $( idSpecific ).addClass( "toggle" );
      $( idSpecific+"read" ).addClass( "toggle" );
    }
  },*/
  /*
  * CUIDADO CON CUALQUIER CAMBIO DE CLASES DE SALESFORCE
  *//*
  hideOnStart: function (comp, event, helper) {
    var action = comp.get("c.waitTime");

    action.setParams({
      'timeNumber': 1000
    });
    action.setCallback(this, function (response) {
      var assetProductIDJS = comp.get('v.assetProductID');
      var className = "#User_Name__c" + assetProductIDJS + "read .slds-form-element__static";
      var idSpecific = "#Specific_user__c" + assetProductIDJS;
      var selected = $( className ).value;

      if(selected == "Select specific user names") {
        $( idSpecific ).removeClass( "toggle" );
        $( idSpecific+"read" ).removeClass( "toggle" );
      }
      else if(selected == "All pending users (Not for Bloomberg)") {
        $( idSpecific ).addClass( "toggle" );
        $( idSpecific+"read" ).addClass( "toggle" );
      }
    });
    $A.enqueueAction(action);

  }*/
})