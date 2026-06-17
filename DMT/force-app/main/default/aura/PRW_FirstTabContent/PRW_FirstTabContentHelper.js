({
  handleRevenues : function(component, event, helper) {
    let revenues = event.getParam('revenues');
    let operationType = event.getParam('operationType');
    let revenuesType = event.getParam('revenuesType');
    let idProd = event.getParam('idProd');
    let isSpecial = event.getParam('isSpecial');
    var specRev = component.get('v.specRev');
    var flatRev = component.get('v.flatRev');
    var simulatedR = component.get('v.simRevenues');
    var expectedR = component.get('v.expRevenues');
    if(revenuesType === 'simulated') {
      if(operationType === 'suma') {
        simulatedR = helper.handleSpecialAdd(component, simulatedR, specRev, isSpecial, revenues, flatRev);
      } else if(operationType === 'resta') {
        simulatedR = helper.handleSpecialR(component, simulatedR, specRev, isSpecial, revenues, flatRev);
      }
    } else if(revenuesType === 'expected') {
      if(operationType === 'suma') {
        expectedR =  revenues;
      } else if(operationType === 'resta') {
        expectedR = expectedR - revenues <= 0 ? 0 : expectedR - revenues;
      }
    }
    component.set('v.simRevenuesFlatEuro', Intl.NumberFormat('cat-ES' , {style: 'currency', currency: 'EUR'}).format(parseFloat(component.get('v.flatRev'))));
    component.set('v.simRevenuesSpecEuro', Intl.NumberFormat('cat-ES' , {style: 'currency', currency: 'EUR'}).format(parseFloat(component.get('v.specRev'))));
    helper.removeElement(component, operationType, idProd);
    component.set('v.simRevenuesEuro', Intl.NumberFormat('cat-ES' , {style: 'currency', currency: 'EUR'}).format(parseFloat(simulatedR)));
    component.set('v.simRevenues', parseFloat(simulatedR));
    component.set('v.expRevenuesEuro', Intl.NumberFormat('cat-ES' , {style: 'currency', currency: 'EUR'}).format(parseFloat(expectedR)));
    component.set('v.expRevenues', expectedR);
  },
  removeElement: function(component, operationType, idProd) {
    if(operationType === 'resta') {
      var dataValues = component.get('v.dataValues');
      dataValues = dataValues.filter(function( obj ) {
        return obj.id_prod !== idProd;
      });
      var aux = 1;
      for(var ind = 0; ind < dataValues.length; ind++) {
        if(ind === 0) {
          dataValues[ind].id = 1;
        }
        else if(dataValues[ind].id-1 !== aux) {
          dataValues[ind].id = aux+1;
        }
        aux = dataValues[ind].id;
      }
      component.set('v.dataValues', dataValues)
    }
  },
  handleSpecialAdd: function(component, simulatedR, specRev, isSpecial, revenues, flatRev) {
    if(isSpecial) {
      simulatedR = simulatedR - specRev;
      component.set('v.specRev', revenues);
    } else {
      simulatedR = simulatedR - flatRev;
      component.set('v.flatRev', revenues);
    }
    simulatedR = simulatedR + revenues;
    return simulatedR;
  },
  handleSpecialR: function(component,simulatedR, specRev, isSpecial, revenues, flatRev) {
    revenues = parseFloat(revenues);
    if(isSpecial) {
      specRev = specRev - revenues;
      component.set('v.specRev', specRev);
    } else {
      flatRev = flatRev - revenues;
      component.set('v.flatRev', flatRev);
    };
    simulatedR = simulatedR - revenues <= 0 ? 0 : simulatedR - revenues;
    return simulatedR;
  },
  handleTableEvent: function(component, event, helper) {
    var dataValues = event.getParam("dataValues");
    var special = event.getParam("isSpecialCond");
    let firstTime = event.getParam('firstTime');
    var currentValues = JSON.parse(JSON.stringify(component.get('v.dataValues')));
    if(currentValues === null) {
      currentValues = JSON.parse(JSON.stringify(dataValues));
      for(var value3 = 0; value3 < currentValues.length; value3++) {
        currentValues[value3].id = value3 + 1;
      }
    } else {
      let currentString = JSON.stringify(currentValues);
      let currentLength = currentValues.length;
      for(var value = 0; value < dataValues.length; value++) {
        if(!currentString.includes(dataValues[value].id_prod)) {
          dataValues[value].id = currentLength + 1;
          currentValues.push(dataValues[value]);
          currentLength++;
        } else {
          helper.handleNotContains(value, currentValues, dataValues);
        }
      }
    }
    if(!firstTime) {
      component.set('v.disabledCalculate', false);
    }
    component.set('v.dataValues', currentValues);
    component.set('v.isSpecialCond', special);
  },
  handleNotContains: function(value, currentValues, dataValues) {
    for(var value1 = 0; value1 < currentValues.length; value1++) {
      if(currentValues[value1].id_prod === dataValues[value].id_prod) {
        if(dataValues[value].simulatedQ !== undefined) {
          currentValues[value1].simulatedQ = parseFloat(dataValues[value].simulatedQ)
        } else {
          currentValues[value1].simulatedQ = '0'
        }
        if(dataValues[value].simulatedP !== undefined) {
          currentValues[value1].simulatedP = parseFloat(dataValues[value].simulatedP)
        } else {
          currentValues[value1].simulatedP = '0'
        }
      }
    }
  },
  handleTemplateBuilder : function(component, helper) {
    var currentValues = component.get('v.dataValues');
    for(var ind = 0; ind < currentValues.length; ind++) {
      if(currentValues[ind].agreedP != null && currentValues[ind].agreedP != undefined){
        currentValues[ind].agreedPC = Intl.NumberFormat('cat-ES',  { style: 'currency', currency: 'EUR', minimumFractionDigits:'4'}).format(parseFloat(currentValues[ind].agreedP));
      }
      if(currentValues[ind].agreedQ != null && currentValues[ind].agreedQ != undefined){
        currentValues[ind].agreedQN =  Intl.NumberFormat('cat-ES', { maximumFractionDigits : '2'}).format(parseFloat(currentValues[ind].agreedQ));
      }
      if(currentValues[ind].agreedQ != null && currentValues[ind].agreedP != null){
        currentValues[ind].expRevenueC =  Intl.NumberFormat('cat-ES', { style: 'currency', currency: 'EUR', maximumFractionDigits : '2'}).format(parseFloat(currentValues[ind].agreedQ) * parseFloat(currentValues[ind].agreedP));
      }
      if(currentValues[ind].simulatedP != null && currentValues[ind].simulatedQ != null){
        var simRevShort = parseFloat(currentValues[ind].simulatedP).toFixed(4) * parseFloat(currentValues[ind].simulatedQ).toFixed(4);
        currentValues[ind].simRevenueC = Intl.NumberFormat('cat-ES', { style: 'currency', currency: 'EUR' , minimumFractionDigits:'2'}).format(simRevShort);
        currentValues[ind].simulatedQN = currentValues[ind].simulatedQ == null ? null : Intl.NumberFormat('cat-ES').format(currentValues[ind].simulatedQ);
        currentValues[ind].simulatedPC = currentValues[ind].simulatedP == null ? null : Intl.NumberFormat('cat-ES',  { style: 'currency', currency: 'EUR', minimumFractionDigits:'4'}).format(parseFloat(currentValues[ind].simulatedP));
      }
    }
    component.set('v.dataValues', currentValues);
    $A.createComponent(
      'c:PRW_TemplateBuilder',
      {
          'recordId': 'PRW:::::'+JSON.stringify(currentValues)+':::::'+
          component.get('v.accountId')+':::::'+component.get('v.lAccountId')
          +':::::'+component.get('v.profSheetId')+':::::'+component.get('v.isGroup')

      },
      function(newButton, status, errorMessage){
          //Add the new button to the body array
          if (status === 'SUCCESS') {
              var body = component.get('v.body');
              body.push(newButton);
              component.set('v.body', body);
          }
          else if (status === 'INCOMPLETE') {
              console.log('No response from server or client is offline.')
              // Show offline error
          }
          else if (status === 'ERROR') {
              console.log('Error: ' + errorMessage);
              // Show error message
          }
      }
    );
  },
  handleCalculate : function(component, helper, conditionWrp) {
    var actionCalculate = component.get('c.calculatePrice');
    var customerID = component.get('v.acc').g_customer_id__c;
    customerID= customerID.substring(customerID.length - 9);
    actionCalculate.setParams({
      clientCode: customerID,
      data: JSON.stringify(component.get('v.dataValues')),
      idCuaderno: component.get('v.profSheetId'),
      isGroup: component.get('v.isGroup') === 'true' ? true : false
    });
    var promiseCalculate = this.promisifyCalculate(actionCalculate);
      return promiseCalculate.then(
        $A.getCallback(function(result) {
          component.set('v.disabledCalculate', true);
          if(result.success === true) {
            helper.proccessResponse(component, JSON.parse(result.products));
            component.set('v.disabledSend', false);
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
              "title": "Success!",
              "message": 'Success',
              "type": "success"
            });
            toastEvent.fire();
            var responseEvent = $A.get("e.c:PRW_ResponseEvent");
            responseEvent.setParam('productList', JSON.parse(result.products));
            responseEvent.setParam('isSpecialCond', component.get('v.isSpecialCond'));
            responseEvent.setParam('conditionWrp', conditionWrp);
            responseEvent.setParam('catalog', component.get('v.catalog'));
            responseEvent.fire();
          } else {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
              "title": "Error!",
              "message": result.errorMessage,
              "type": "error"
            });
            toastEvent.fire();
          }
        }),
        $A.getCallback(function(error) {
          console.error( 'Error calling action "' + actionCalculate + '" with state: ' + error.message );
        })
      ).catch(function(e){
      });
  },
  proccessResponse : function(component, products) {
    var currentValues = component.get('v.dataValues');
    for(var ind = 0; ind < currentValues.length; ind++) {
      for(var ind1 = 0; ind1 < products.length; ind1++) {
        if(currentValues[ind].id_prod === products[ind1].id_y) {
          currentValues[ind].simulatedP = products[ind1].optimalPrice == 0 ? currentValues[ind].simulatedP : parseFloat(products[ind1].optimalPrice);//NOSONAR
          currentValues[ind].simulatedQ = products[ind1].optimalVolume == 0 ? currentValues[ind].simulatedQ : parseFloat(products[ind1].optimalVolume);//NOSONAR
          currentValues[ind].simRevenue = currentValues[ind].simulatedP * currentValues[ind].simulatedQ;
        }
      }
    }
    component.set('v.dataValues', currentValues);
  },
  promisifyCalculate: function(actionCalculate) {
    return new Promise((resolve, reject) => {
      actionCalculate.setCallback(this, function(response) {
        const status = response.getState();
        if (status === 'SUCCESS') {
          resolve(response.getReturnValue());
        } else if (status === 'ERROR') {
          var errorCalculate = response.getError();
          if (errorCalculate) {
            if (errorCalculate[0] && errorCalculate[0].message) {
              reject(Error('Error message: ' + errorCalculate[0].message));
            }
          } else {
            reject(Error('Unknown error'));
          }
      }
      });

      $A.enqueueAction(actionCalculate);
    });
  },
  handleProductsSelectContinue: function(component,event,helper){
    let products = event.getParam('products');
    let productsSelected = event.getParam('productsSelected');
    let firstProdIds = event.getParam('firstProdIds');
    
    for(let ind = 0; ind < products.length; ind++) {
      if(productsSelected.includes(products[ind].prod_id) && !firstProdIds.includes(products[ind].prod_id)){
        component.set('v.disabledCalculate', false);
      } 
    }
  }
})