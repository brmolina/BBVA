({

  DATA: [
  ],

  setColumns: function(cmp) {
    let columnsArray = $A.get('$Label.c.PRW_ColumnsTableFlat');
    let columnsList = columnsArray.split('||');
    let numColumns = columnsList.length;

    var columns = [];
    if(cmp.get('v.isSpecialCond')) {
      columns = [
        {label: columnsList[0], fieldName: 'product', type: 'text', fixedWidth: 350, wrapText: true},
        {label: columnsList[numColumns - (numColumns - 2)], fieldName: 'agreedPC', type: 'text', cellAttributes: {alignment: 'right'}},
        {label: columnsList[numColumns - (numColumns - 5)], fieldName: 'simulatedPC',type: 'text', editable: true, cellAttributes: {alignment: 'right'}},
        {label: columnsList[numColumns - (numColumns - 6)], fieldName: 'simulatedQN',type: 'text', editable: true, cellAttributes: {alignment: 'right'}},
        {label: columnsList[numColumns - (numColumns - 7)], fieldName: 'simRevenueC', type: 'text', cellAttributes: {alignment: 'right'}},

        {type: 'button-icon', typeAttributes: {name: 'comments', iconName: {fieldName: 'displayIconName'},  class: 'classButton', disabled: { fieldName: 'isDisabled'},}, fixedWidth: 30},
        {type: 'button-icon', typeAttributes: {name: 'delete', iconName: 'utility:delete', class: 'classButton'}, fixedWidth: 30},
        // { fieldName: '', label: '', cellAttributes: { iconName: { fieldName: 'dynamicIcon' }, iconLabel: 'No soportado' }}
      ]
    } else {
      columns = [
        {label: columnsList[0], fieldName: 'product', type: 'text', fixedWidth: 350, wrapText: true},
        {label: columnsList[numColumns - (numColumns - 2)], fieldName: 'agreedPC', type: 'text', cellAttributes: {alignment: 'right'}},
        {label: columnsList[numColumns - (numColumns - 3)], fieldName: 'agreedQN', type: 'text', cellAttributes: {alignment: 'right'}},
        {label: columnsList[numColumns - (numColumns - 4)], fieldName: 'expRevenueC', type: 'text', cellAttributes: {alignment: 'right'}},
        {label: columnsList[numColumns - (numColumns - 5)], fieldName: 'simulatedPC', type: 'text', editable: true, cellAttributes: {alignment: 'right'}},
        {label: columnsList[numColumns - (numColumns - 6)], fieldName: 'simulatedQN', type: 'text', editable: true, cellAttributes: {alignment: 'right'}},
        {label: columnsList[numColumns - (numColumns - 7)], fieldName: 'simRevenueC', type: 'text', cellAttributes: {alignment: 'right'}},
        
        {type: 'button-icon', typeAttributes: {name: 'comments', iconName: {fieldName: 'displayIconName'}, class: 'classButton', disabled: { fieldName: 'isDisabled'},}, fixedWidth: 30},
        {type: 'button-icon', typeAttributes: {name: 'delete', iconName: 'utility:delete', class: 'classButton'}, fixedWidth: 30},
        // { fieldName: '', label: '', cellAttributes: { iconName: { fieldName: 'dynamicIcon' }, iconLabel: 'No soportado'}}
      ]
    }
    cmp.set('v.columns', columns);
  },

  setData: function(cmp,helper) {  
    var simulated = 0;
    var expected = 0;
    var price = 0;
    var quantity = 0;
    var priceSum = 0;
    var quantitySum = 0;
    var currentData = cmp.get('v.data');
    var expectedToConv = '';
    let self = this;
    if(this.chkConditions(cmp)) {
      this.DATA = [];
      currentData = null;
    }
    cmp.set('v.isToAdd',false);
    cmp.set('v.isToDelete',false);
    if(currentData === null) {
      currentData = JSON.parse(JSON.stringify(this.DATA));
      cmp.set('v.firstData' , JSON.parse(JSON.stringify(this.DATA)));
    }
    for(let ind = 0; ind < currentData.length; ind++) {
      currentData[ind].agreedQ = currentData[ind].agreedQ === undefined ? 0 : parseFloat(currentData[ind].agreedQ);
      currentData[ind].agreedQN = currentData[ind].agreedQN === undefined ? '' : Intl.NumberFormat('cat-ES').format(parseFloat(currentData[ind].agreedQ));
      currentData[ind].agreedP = currentData[ind].agreedP === undefined ? 0 :parseFloat(currentData[ind].agreedP);
      currentData[ind].agreedPC = currentData[ind].agreedPC === undefined ? '' :Intl.NumberFormat('cat-ES',  { style: 'currency', currency: 'EUR', minimumFractionDigits:'4' }).format(parseFloat(currentData[ind].agreedP));
      simulated += currentData[ind].simRevenue === undefined ? 0 : currentData[ind].simRevenue;  
      if(cmp.get('v.isSpecialCond')){ 
        currentData[ind].simRevenueC =currentData[ind].simRevenue === undefined || currentData[ind].simRevenue == 0 ? '0 €' : currentData[ind].simRevenueC;
      }
      if (currentData[ind].simulatedQ == -1 || currentData[ind].simulatedP == -1 ) { currentData[ind].dynamicIcon = 'utility:info' }
      price = parseFloat(currentData[ind].agreedP).toFixed(4);
      quantity =  parseFloat(currentData[ind].agreedQ).toFixed(4);
      expected += price * quantity;
      currentData[ind].expRevenueC =currentData[ind].expRevenueC === undefined ? '0 €'  : currentData[ind].expRevenueC;
      currentData[ind].simulatedP =currentData[ind].simulatedP === undefined ? 0  : currentData[ind].simulatedP;
      currentData[ind].simulatedPC = currentData[ind].simulatedPC === undefined  ? '' : Intl.NumberFormat('cat-ES',  { style: 'currency', currency: 'EUR', minimumFractionDigits:'4'}).format(parseFloat(currentData[ind].simulatedP));
      currentData[ind].tableEdited = true;
    }
    
    if(currentData.length > 0) {
      var tableEvent = $A.get("e.c:PRW_EditTableEvent");
      tableEvent.setParam('dataValues', currentData);
      tableEvent.setParam('isSpecialCond', cmp.get('v.isSpecialCond'));
      tableEvent.setParam('firstTime', true);
      tableEvent.fire();
      simulated = Intl.NumberFormat('cat-ES',  { style: 'currency', currency: 'EUR' }).format(parseFloat(simulated));
      expected = Intl.NumberFormat('cat-ES',  { style: 'currency', currency: 'EUR' }).format(parseFloat(expected));
      currentData.push({product: 'TOTAL', expRevenueC: expected, simRevenueC: simulated});
    }
    cmp.set('v.data', currentData);
  }, 

  chkConditions: function(cmp) {
    var chk = false;
    if((cmp.get('v.conditionWrp') === 'empty' || cmp.get('v.conditionWrp') === null || cmp.get('v.conditionWrp') === undefined)
    && !cmp.get('v.isToAdd') && !cmp.get('v.isToDelete')) {
      chk = true;
    }
    return chk;
  },

  setDataService: function(cmp) {
    var currentData = [];
    if(cmp.get('v.conditionWrp') === 'empty') {
      cmp.set('v.loaded' , true);
      this.DATA = [];
    } else {
      currentData = this.dataServiceAux(cmp, currentData);
      this.DATA = currentData;
      cmp.set('v.data' , currentData);
      cmp.set('v.loaded' , true);
      this.setData(cmp);
    }
  },

  dataServiceAux: function(cmp, current) {
    var currentData = current;
    var newData = JSON.parse(cmp.get('v.conditionWrp'));
      for(var i = 0; i < newData.length; i++) {
        if(cmp.get('v.isSpecialCond') === newData[i].isSpecial && parseFloat(newData[i].price) !== 0) {
          currentData.push(
            {
              id: i+1,
              product: newData[i].name,
              id_prod: newData[i].idProd,
              agreedP: newData[i].price === null ? 0 : Intl.NumberFormat('cat-ES', { style: 'currency', currency: 'EUR' }).format(parseFloat(newData[i].price)),
              agreedPC : newData[i].price === null ? '0€' : parseFloat(newData[i].price),
              agreedQ: newData[i].quantity === null ? 0 : parseFloat(newData[i].quantity),
              agreedQN: newData[i].quantity === null ? '€' : Intl.NumberFormat('cat-ES').format(parseFloat(newData[i].price)),
              expRevenue: newData[i].price === null || parseFloat(newData[i].quantity) === null ? 0 : parseFloat(newData[i].price) * parseFloat(newData[i].quantity),
              expRevenueC : parseFloat(newData[i].price) === null || parseFloat(newData[i].quantity) === null ? '0€' : Intl.NumberFormat('cat-ES', { style: 'currency', currency: 'EUR' }).format(parseFloat(newData[i].price) * parseFloat(newData[i].quantity)),
              isDisabled: true,
              editedP: false,
              editedQ: false,
              tableEdited :true
            }
          );
        }
      }
      return currentData;
  },

  showFlatRatesAddCmp: function(cmp, helper, cmpName, cmpParams) {
    return new Promise($A.getCallback(function(resolve, reject) {
      $A.createComponent(
        'c:' + cmpName,
        cmpParams,
        function(newCmp, status, errorMessage) {
          if (status === 'SUCCESS') {
            resolve(newCmp);
          } else if (status === 'INCOMPLETE' || status === 'ERROR') {
            console.log('Error');
          }
        }
      );
    }));
  },

  handleCellChange: function(cmp, evnt, draftValues) {
    var currentData = cmp.get('v.data');
    let keysChange = Object.keys(draftValues[0]);

    var keyAux;

    for(var keyCh in keysChange) {
      if(keysChange[keyCh] !== 'id') {
        keyAux = keysChange[keyCh];
      }
    }
    for(var current in currentData) {
      currentData[current].tableEdited = true;
      if(currentData[current].id === parseFloat(draftValues[0].id) && !isNaN(parseFloat(draftValues[0][keyAux]))) {
        
        if(keyAux === 'simulatedPC'){
          currentData[current]['simulatedP'] = this.convertCurrToNumber(draftValues[0][keyAux]);
          currentData[current]['simulatedPC'] = draftValues[0][keyAux];
        }else{
          currentData[current]['simulatedQ'] = this.convertCurrToNumber(draftValues[0][keyAux]);
          currentData[current]['simulatedQN'] = draftValues[0][keyAux];
        }
        if(keyAux === 'simulatedPC' && !currentData[current].editedQ) {
          delete currentData[current]['simulatedQ'];
          delete currentData[current]['simulatedQN'];
          currentData[current].editedP = true;
        } else if(keyAux === 'simulatedQN' && !currentData[current].editedP) {
          delete currentData[current]['simulatedP'];
          delete currentData[current]['simulatedPC'];
          currentData[current].editedQ = true;
        } else {
          currentData[current].editedQ = true;
          currentData[current].editedP = true;
        }
      }
    }

    var dataToSend = this.prepareDataSend(currentData);

    cmp.set('v.data', currentData);

    if(dataToSend.length > 0) {
      var tableEvent = $A.get("e.c:PRW_EditTableEvent");
      tableEvent.setParam('dataValues', dataToSend);
      tableEvent.setParam('isSpecialCond', cmp.get('v.isSpecialCond'));
      tableEvent.setParam('firstTime', false);
      tableEvent.fire();
    }

    cmp.set('v.draftValues', []);
  },

  prepareDataSend: function(current) {
    var dataToSend = JSON.parse(JSON.stringify(current));

    for(var ind = 0; ind < dataToSend.length; ind ++) {
      if(dataToSend[ind].simulatedP === '' || dataToSend[ind].simulatedP === null) {
        delete dataToSend[ind].simulatedP;
      }
      if(dataToSend[ind].simulatedQ === '' || dataToSend[ind].simulatedQ === null) {
        delete dataToSend[ind].simulatedQ;
      }
    }

    dataToSend = dataToSend.filter(function(data) {
      return data.product !== 'TOTAL'
    });

    return dataToSend;
  },

  handleDelete: function(cmp, row) {
    var currentData = cmp.get('v.data');
    var revenues = 0;
    var revenuesExp = 0;
    for(var current in currentData) {
      if(currentData[current].id === row.id) {
        revenues = currentData[current].simRevenue === undefined ? 0 : currentData[current].simRevenue;
        revenuesExp = currentData[current].expRevenue === undefined ? 0 : currentData[current].expRevenue;
        currentData.splice(current,1);
      }
    }
    if(currentData.length === 1) {
      currentData.splice(0,1);
    } else {
      cmp.set('v.isToDelete', true);
      currentData.pop();
      this.setData(cmp);

    }
    cmp.set('v.data', currentData);
    
    var otherTableEvent = $A.get("e.c:PRW_OtherTableEvent");
    otherTableEvent.setParam('data', JSON.stringify(currentData));
    otherTableEvent.setParam('isSpecial', cmp.get('v.isSpecialCond'));
    otherTableEvent.fire();

    var revenuesEvent = $A.get("e.c:PRW_RevenuesEvent");
    revenuesEvent.setParam('revenues', revenues);
    revenuesEvent.setParam('revenuesType', 'simulated');
    revenuesEvent.setParam('operationType', 'resta');
    revenuesEvent.setParam('idProd', row.id_prod);
    revenuesEvent.setParam('isSpecial', cmp.get('v.isSpecialCond'));
    revenuesEvent.fire();
    if(!cmp.get('v.isSpecialCond')){
      var revenuesEvent = $A.get("e.c:PRW_RevenuesEvent");
      revenuesEvent.setParam('revenues', revenuesExp);
      revenuesEvent.setParam('revenuesType', 'expected');
      revenuesEvent.setParam('operationType', 'resta');
      revenuesEvent.setParam('idProd', row.id_prod);
      revenuesEvent.setParam('isSpecial', cmp.get('v.isSpecialCond'));
      revenuesEvent.fire();
    }
  },

  handleProductsSelectContinue: function(cmp, event, helper) {
    let products = event.getParam('products');
    let productsSelected = event.getParam('productsSelected');
    let firstProdIds = event.getParam('firstProdIds');

    var currentData = cmp.get('v.data');
    for(var ind = 0; ind < currentData.length; ind++) {
      if(!productsSelected.includes(currentData[ind].id_prod)) {
        currentData[ind].product = 'ToDelete';
      }
    }
    currentData = currentData.filter(function( obj ) {
      return obj.product !== 'ToDelete' && obj.product !== 'TOTAL';
    });

    for(var ind1 = 0; ind1 < currentData.length; ind1++) {
      currentData[ind1].id = ind1+1;
    }

    var first = JSON.parse(JSON.stringify(cmp.get('v.firstData')));

    for(let ind = 0; ind < products.length; ind++) {
      var element = first.filter(function( obj ) {
        return obj.id_prod === products[ind].prod_id;
      });

      if(productsSelected.includes(products[ind].prod_id) && !firstProdIds.includes(products[ind].prod_id)) {
        if(element.length > 0) {
          currentData.push(
            {
              id: currentData.length+1,
              product: products[ind].family + ' - ' + products[ind].prod_name,
              id_prod: products[ind].prod_id,
              agreedP: parseFloat(element[0].agreedP),
              agreedPC :  Intl.NumberFormat('cat-ES', { style: 'currency', currency: 'EUR', minimumFractionDigits:'4'}).format(parseFloat(element[0].agreedP)),
              agreedQ: parseFloat(element[0].agreedQ),
              agreedQN : Intl.NumberFormat('cat-ES').format(element[0].agreedQ),
              transactions: element[0].transactions,
              isDisabled: true,
              editedP: false,
              editedQ: false,
              tableEdited: true
            }
          );
        } else {
          currentData.push(
            {
              id: currentData.length+1,
              product: products[ind].family + ' - ' + products[ind].prod_name,
              id_prod: products[ind].prod_id,
              isDisabled: true,
              editedP: false,
              editedQ: false,
              tableEdited: true
            }
          );
        }
      }
    }
    cmp.set('v.data' , currentData);
    cmp.set('v.isToAdd', true);
    this.setData(cmp);
    var otherTableEvent = $A.get("e.c:PRW_OtherTableEvent");
    otherTableEvent.setParam('data', JSON.stringify(currentData));
    otherTableEvent.setParam('isSpecial', cmp.get('v.isSpecialCond'));
    otherTableEvent.fire();
  },
  prepareIds: function(cmp) {
    var currentData = [];
    var newData = JSON.parse(cmp.get('v.conditionWrp'));
    var auxAgreedQ;
    var auxExpRevenue;
      for(var i = 0; i < newData.length; i++) {
        if(cmp.get('v.isSpecialCond') === newData[i].isSpecial && parseFloat(newData[i].price) !== 0) {
          auxExpRevenue= newData[i].price === null || newData[i].quantity === null ? 0 : parseFloat(newData[i].price) * parseFloat(newData[i].quantity);
          currentData.push(
            {
              id: i+1,
              product: newData[i].name,
              id_prod: newData[i].idProd,
              agreedP: newData[i].price ===  null ? 0 : parseFloat(newData[i].price),
              agreedPC: newData[i].price === null ? '0' + $A.get("$Locale.currency")  : Intl.NumberFormat('cat-ES', { style: 'currency', currency: 'EUR' }).format(parseFloat(newData[i].price)) ,
              agreedQ: newData[i].quantity === null ? 0 : parseFloat(newData[i].quantity),
              agreedQN: newData[i].quantity === null ? '0' : Intl.NumberFormat('cat-ES').format(parseFloat(newData[i].quantity)),
              expRevenue: auxExpRevenue,
              expRevenueC: Intl.NumberFormat('cat-ES', { style: 'currency', currency: 'EUR' }).format(auxExpRevenue),
              isDisabled: true,
              editedP: false,
              editedQ: false,
              tableEdited: true
            }
          );
        }
      }
      return currentData;
  },
  handleResponse: function(cmp, event, helper) {
    var products = event.getParam('productList');
    var conditionWrp = event.getParam('conditionWrp');
    var catalog = event.getParam('catalog');
    var data = cmp.get('v.data');

    if(conditionWrp !== null) {
      cmp.set('v.conditionWrp', conditionWrp);
      data = helper.prepareIds(cmp);
    }
    var totalSimRevenue = 0;
    var totalExpRevenue = 0;
    for(var ind = 0; ind < data.length; ind++) {
      for(var ind1 = 0; ind1 < products.length; ind1++) {
       
        if(data[ind].id_prod === products[ind1].id_y) {
          if(products[ind1].notificationCode === 'WARN' || products[ind1].notificationCode === 'ERROR'){
            data[ind].displayIconName = 'utility:warning';
          }else{
            data[ind].displayIconName = 'utility:anywhere_chat';
          }
          data[ind].notificationDescription = products[ind1].notificationDescription != null ? products[ind1].notificationDescription : null;
          data[ind].notificationCode = products[ind1].notificationCode != null ? products[ind1].notificationCode : null;
          data[ind] = this.responseAux(data[ind], products[ind1]);
          if(!isNaN((data[ind].simulatedP * data[ind].simulatedQ))) {
            totalSimRevenue = totalSimRevenue + (data[ind].simulatedP * data[ind].simulatedQ);
          }
          if(!isNaN(data[ind].agreedP * data[ind].agreedQ)){
            totalExpRevenue = totalExpRevenue + (data[ind].agreedP * data[ind].agreedQ);
          }
          
        }
      }
    }
    data = data.filter(function( obj ) {
      return obj.product !== 'TOTAL';
    });
    cmp.set('v.data', data);
    cmp.set('v.isToAdd', true);

    if(catalog !== null) {
      cmp.set('v.catalog' , catalog);
    }
    if(conditionWrp !== null) {
      cmp.set('v.loaded' , true);
    }
    this.setData(cmp);
    var otherTableEvent = $A.get("e.c:PRW_OtherTableEvent");
    otherTableEvent.setParam('data', JSON.stringify(data));
    otherTableEvent.setParam('isSpecial', cmp.get('v.isSpecialCond'));
    otherTableEvent.fire();

    var revenuesEvent = $A.get("e.c:PRW_RevenuesEvent");
    revenuesEvent.setParam('revenues', totalSimRevenue);
    revenuesEvent.setParam('revenuesType', 'simulated');
    revenuesEvent.setParam('operationType', 'suma');
    revenuesEvent.setParam('isSpecial', cmp.get('v.isSpecialCond'));
    revenuesEvent.fire();
    if(!cmp.get('v.isSpecialCond')){
      var revenuesEvent = $A.get("e.c:PRW_RevenuesEvent");
      revenuesEvent.setParam('revenues', totalExpRevenue);
      revenuesEvent.setParam('revenuesType', 'expected');
      revenuesEvent.setParam('operationType', 'suma');
      revenuesEvent.setParam('isSpecial', cmp.get('v.isSpecialCond'));
      revenuesEvent.fire();
    }
  },
  responseAux: function(data1, product1) {

    if(data1.simulatedP !== undefined && !isNaN(data1.simulatedP) && data1.simulatedQ !== undefined && !isNaN(data1.simulatedQ)) {
      data1.simulatedP = data1.simulatedP;
      data1.simulatedQ = data1.simulatedQ;
      data1.simulatedQN =  Intl.NumberFormat('cat-ES').format(data1.simulatedQ);
      data1.simulatedPC = Intl.NumberFormat('cat-ES', { style: 'currency', currency: 'EUR' }).format(data1.simulatedP);
    }
    if((data1.simulatedQ === undefined || isNaN(data1.simulatedQ)) || product1.description === undefined){
      data1.simulatedQ = product1.optimalVolume;
      data1.simulatedQN =  Intl.NumberFormat('cat-ES').format(product1.optimalVolume);
    }
    if((data1.simulatedP === undefined || isNaN(data1.simulatedP)|| data1.simulatedP === 0) && product1.description === undefined) {
      data1.simulatedP = product1.optimalPrice;
      data1.simulatedPC = Intl.NumberFormat('cat-ES', { style: 'currency', currency: 'EUR' }).format(product1.optimalPrice);
    }
    data1.simRevenue  = data1.simulatedP * data1.simulatedQ;
    var simRevShort = parseFloat(data1.simulatedP).toFixed(4) * parseFloat(data1.simulatedQ).toFixed(4);
    data1.simRevenueC = Intl.NumberFormat('cat-ES', { style: 'currency', currency: 'EUR' ,maximumFractionDigits : 2}).format(simRevShort);
    if(isNaN(data1.simRevenue)) {
      data1.simRevenue = 0;
    }
    let aux =data1.simRevenue;
    data1.indicators = product1.indicators;
    data1.description = product1.description;
    data1.editedP = false;
    data1.editedQ = false;
    data1.isDisabled = product1.indicators === undefined && product1.optimalVolume === undefined
    && product1.optimalPrice === undefined && product1.description === undefined ? true : false;

    return data1;
  },
  convertCurrToNumber: function(fieldToUpdate) {
    var toReturn;
    var fieldToUpdate = fieldToUpdate;
    if(typeof fieldToUpdate ==='string'){
      toReturn=fieldToUpdate;
      do {
        toReturn = toReturn.replace('.','');
      } while (toReturn.includes('.'));
      toReturn = parseFloat(toReturn.replace(',','.'));
    }
    return toReturn;
  },
  handleOtherTable: function(cmp, event, helper) {
    if(event.getParam('isSpecial') !== cmp.get('v.isSpecialCond')){
      cmp.set('v.otherTable' , event.getParam('data'));
    }
  }

})