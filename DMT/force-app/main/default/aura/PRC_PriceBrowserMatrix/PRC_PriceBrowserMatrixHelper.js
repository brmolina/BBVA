({
  onInit: function (component, event, helper) {
    //rellenamos opciones de matrices
    if (component.get('v.responseData.data.engineWorksWith.matrices')) {
      console.log('response data correct');
      var matrices = component.get('v.responseData.data.engineWorksWith.matrices');
      var optionsListAux = [];
      for (var i = 0; i < matrices.length; i++) {
        console.log('>>>>>>>>> 1 iteration i=' + i);
        var newOption = {
          label: helper.lowerCaseFirstUpperCase(matrices[i].axis[0].id) + ' / ' + helper.lowerCaseFirstUpperCase(matrices[i].axis[1].id),
          value: matrices[i].axis[0].id + '-' + matrices[i].axis[1].id + '-' + matrices[i].axis[0].numberOfEntries
        };        /*matrices[i].axis[1].numberOfEntries*/
        console.log('>>>>>>>>> option: ' + JSON.stringify(newOption));
        optionsListAux.push(newOption);
      }

      component.set('v.matrixOptions', optionsListAux);
      component.set('v.selectedMatrix', optionsListAux[0].value);
      helper.setMatrixSelected(component, helper);
      helper.setInitPrice(component, helper);

      component.set('v.displaySpinner', false);
    }
  },
  setMatrixSelected: function (component, helper) {
    var selectedMatrix = component.get('v.selectedMatrix').split('-');
    console.log('>>>>>>> selectedmatrix :' + selectedMatrix);
    component.set('v.selectedMatrixAxis1', selectedMatrix[0]);
    component.set('v.selectedMatrixAxis2', selectedMatrix[1]);
    component.set('v.matrixColumns', parseInt(selectedMatrix[2]));
  },
  setInitPrice: function (component, helper) {
    /* La matriz de momento siempre es de 5x5 pero por si acaso varía se hace este switch case */
    var matrixNumColumns = component.get('v.matrixColumns');
    switch (matrixNumColumns) {
      case 3:
        component.set('v.initPriceId', 5);
        break;
      case 4:
        component.set('v.initPriceId', 6);
        break;
      case 5:
        component.set('v.initPriceId', 13);
        break;
      case 6:
        component.set('v.initPriceId', 15);
        break;
      case 7:
        component.set('v.initPriceId', 25);
        break;
      case 8:
        component.set('v.initPriceId', 28);
        break;
      default:
        component.set('v.initPriceId', 1);
        break;
    }
  },
  saveSelectedPrice: function (component, event, helper) {
    var action = component.get("c.callWsRegisterAmiweb");
    var fullData = component.get("v.responseData");
    var priceSel = component.get("v.selectedPrice");
    action.setParams({
      oppId: component.get("v.opportunityId"),
      priceFullResponse: fullData,
      selectedPrice: priceSel
    });

    action.setCallback(this, function (response) {
      var state = response.getState();
      if (state === "SUCCESS") {
        var msg = response.getReturnValue().split('#');
        helper.showToast(component, event, helper, msg[0], msg[1]);
        var refreshDetailEvt = $A.get("e.c:PRC_RefreshDetailsEvt");
		    refreshDetailEvt.fire();
        var closemodalevt = component.getEvent('closemodalevt');
        closemodalevt.fire();
      } else if (state === "ERROR") {
        // generic error handler
        var errors = response.getError();
        if (errors) {
          console.log("Errors", errors);
          if (errors[0] && errors[0].message) {
            helper.showToast(component, event, helper, 'error', 'Amiweb service call error: ' + errors[0].message);
          }
        } else {
          helper.showToast(component, event, helper, 'error', 'Amiweb service call failed');
        }
      }
    });
    $A.enqueueAction(action);
  },
  showToast: function (component, event, helper, msgType, msg) {
    var toastEvent = $A.get("e.force:showToast");
    toastEvent.setParams({
      // "title": "Success!",
      "type": msgType,
      "message": msg
    });
    toastEvent.fire();
  },
  lowerCaseFirstUpperCase: function (textToConvert) {
    var allTextLowerCase = textToConvert.toLowerCase();
    return allTextLowerCase.charAt(0).toUpperCase() + allTextLowerCase.slice(1);
  }
})