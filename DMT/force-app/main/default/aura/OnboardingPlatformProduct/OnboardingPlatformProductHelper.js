({
  getProductIDs: function (component, event, helper) {
    var act2 = component.get("c.getProductIDs");
    act2.setParams({
      "assetID": component.get("v.recordId")
    });
    act2.setCallback(this, function (resp2) {
      var state2 = resp2.getState();
      if (state2 === "SUCCESS") {
        console.log('>>>>> SUCCESS');
        component.set('v.lProductIDs', resp2.getReturnValue());
      } else {
        console.log('FALLO : ', JSON.stringify(resp2.getReturnValue()));
      }
    });
    $A.enqueueAction(act2);
  },
  addAssetProduct: function (component, event, helper) {
    var action = component.get("c.addNewAssetProduct");
    action.setParams({
      "assetID": component.get("v.recordId")
    });
    action.setCallback(this, function (response) {
      var state = response.getState();
      if (state === "SUCCESS") {
        console.log('>>>>> SUCCESS');
        helper.getProductIDs(component, event, helper);
        component.set('v.editMode', true);
      } else {
        console.log('FALLO : ', JSON.stringify(response.getReturnValue()));
      }
    });
    $A.enqueueAction(action);
  },
  handleEvent: function (component, event, helper) {
    var evento = event.getParam('message');
    if(evento === 'set-secondary') {
      helper.checkBeforeSave(component, event, helper);
    }
    else if(evento === 'edit-asset'){
      var getID = event.getParam('record');
      if (getID === component.get("v.recordId")) {
        component.set('v.editMode', true);
      }
    }
    else if(evento === 'add-product'){
      var getID2 = event.getParam('record');
      if (getID2 === component.get("v.recordId")) {
        helper.addAssetProduct(component, event, helper);
      }
    }
  },
  handleTierEvent: function (component, event, helper) {
    var evento = event.getParam('message');
    if(evento === 'edit-asset-tier'){
      component.set('v.editTierMode', true);
    }
  },
  checkBeforeSave: function (component, event, helper) {

    var action = component.get("c.canSaveAsset");
    var secondarySelected = JSON.stringify(event.getParam('record'));

    action.setParams({
      "secondary": secondarySelected,
      "recordID": component.get('v.recordId')
    });
    action.setCallback(this, function (response) {
      var state = response.getState();
      if (state === "SUCCESS") {
        console.log('>>>>> SUCCESS');
        if(response.getReturnValue()) {
          helper.saveAll(component, event, helper);
        }
        else {
          var toastEvent = $A.get("e.force:showToast");
          toastEvent.setParams({
              "title": $A.get("$Label.c.DES_Error"),
              "message": $A.get("$Label.c.Asset_Delete_Error_Secondary"),
              "type": "error"
          });
          toastEvent.fire();
          component.set('v.disableButton', false);
        }
      } else {
        console.log('FALLO : ', JSON.stringify(response.getReturnValue()));
      }
    });
    $A.enqueueAction(action);
  },
  saveAll: function (component, event, helper) {
    var appEvent = $A.get("e.c:saveAssetTemplate");
    appEvent.setParams({
        "message" : "save-asset",
        "record"  : component.get("v.recordId")
      });
    appEvent.fire();
    component.set('v.saveMode', true);
    component.set('v.editMode', false);
    window.location.reload();
  },
  saveTier: function (component, event, helper) {
    component.set('v.disableButton', true);
    component.set('v.saveTierMode', true);
    component.set('v.editTierMode', false);
    window.location.reload();
  },
  getSecondary: function (component, event, helper) {
    component.set('v.disableButton', true);
    var appEvent = $A.get("e.c:AssetSalesEvent");
    appEvent.setParams({
        "secondary" : true,
        "message"  : "get-secondary"
      });
    appEvent.fire();
  },
  handleProductRefresh: function (component, event, helper) {
    var typeOfEvent = event.getParam("typeEvent");
    if (typeOfEvent === 'refreshDelete') {
      helper.getProductIDs(component, event, helper);
    }
    else if (typeOfEvent === 'refreshClone') {
      helper.getProductIDs(component, event, helper);
      component.set('v.editMode', true);
    }
  },
  canEdit: function (component, event, helper) {

    var action = component.get("c.canEditAsset");

    action.setParams({
      'recordID': component.get('v.recordId')
    });
    action.setCallback(this, function (response) {
      var state = response.getState();
      if (state === "SUCCESS") {
        component.set('v.canEdit', response.getReturnValue());
      } else {
        console.log('FALLO : ', JSON.stringify(response.getReturnValue()));
      }
    });
    $A.enqueueAction(action);
  },
  cancelHandler: function (component, event, helper) {
    window.location.reload();
  }
})