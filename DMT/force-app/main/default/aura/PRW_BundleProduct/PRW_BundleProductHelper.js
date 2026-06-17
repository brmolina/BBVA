({
  setColumns: function(cmp){
    let columnsProductArray = $A.get('$Label.c.PRW_ColumnsBundleProduct');
    let columnsProductList = columnsProductArray.split('||');
    let numColumnsProdList = columnsProductList.length;
    var columnsProduct = [];
    var columnsProductsAddProduct = [];
    
    columnsProduct = [
      {label: columnsProductList[0], fieldName: 'bndleProduct', type: 'text', wrapText: true},
      {label: columnsProductList[numColumnsProdList - (numColumnsProdList - 1)], fieldName: 'q', type: 'text',editable: true, cellAttributes: {alignment: 'right'}}
    ]

    columnsProductsAddProduct = [
      {label: columnsProductList[0], fieldName: 'bndleProductAdded', type: 'text', wrapText: true},
      {label: columnsProductList[numColumnsProdList - (numColumnsProdList - 2)], fieldName: 'p', type: 'text',editable: true, cellAttributes: {alignment: 'right'}},
      {label: columnsProductList[numColumnsProdList - (numColumnsProdList - 1)], fieldName: 'q', type: 'text',editable: true, cellAttributes: {alignment: 'right'}},
      {type: 'button-icon', typeAttributes: {name: 'delete', iconName: 'utility:delete', class: 'classDeleteRowButton'}, fixedWidth: 30}
    ]

    cmp.set('v.columnsProducts', columnsProduct);
    cmp.set('v.columnsProductsAddProduct', columnsProductsAddProduct);

    let columnsNBPArray = $A.get('$Label.c.PRW_ColumnsNextBestProduct');
    let columnsNBPList = columnsNBPArray.split('||');
    let numColumnsNBPList = columnsNBPList.length;
    var columnsNBP = [];
    columnsNBP = [
      {label: columnsNBPList[0], fieldName: 'bndleNBP', type: 'text', wrapText: true},
      {label: columnsNBPList[numColumnsNBPList - (numColumnsNBPList - 1)], fieldName: 'p', type: 'currency', cellAttributes: {alignment: 'right'}},
      {label: columnsNBPList[numColumnsNBPList - (numColumnsNBPList - 1)], fieldName: 'q', type: 'text', cellAttributes: {alignment: 'right'}}
    ]
    cmp.set('v.columnsNextBestProducts', columnsNBP);
  },

  setData: function(cmp,event,helper,component){
    var bundleEvent = $A.get("e.c:PRW_BundleEvent");
    let variable = cmp.get('v.isPreview');
    let dataProduct = [];
    let dataProductInitial = [];

    if(!variable){
      //tambi�n habr�a que setear la variable totalAnnualValue cuando se recargue la p�gina y el bundle preview ya tenga datos guardados
      cmp.set('v.totalAnnualValueNotPreview',Intl.NumberFormat('cat-ES', { style: 'currency', currency: 'EUR', minimumFractionDigits:'0'}).format(cmp.get('v.data').bundlePrice));
      cmp.set('v.totalAnnualPriceBundleInitial', Intl.NumberFormat('cat-ES', { style: 'currency', currency: 'EUR', minimumFractionDigits:'0'}).format(cmp.get('v.data').bundlePrice));
      cmp.set('v.totalAnnualValueNotPreviewNumber',cmp.get('v.data').bundlePrice);
      let tableDataProduct = cmp.get('v.data').bundleProducts;
        for(var ind = 0; ind < tableDataProduct.length; ind++) {
          dataProduct.push(
            {
              bndleNumber : cmp.get('v.data').bundleName,
              bndleProduct : tableDataProduct[ind].bundleProd,
              q: Intl.NumberFormat('cat-ES').format(tableDataProduct[ind].qntity),
              qNumber : tableDataProduct[ind].qntity,
              addedNumber : cmp.get('v.data').cif
            }
          );
          dataProductInitial.push(
            {
              bndleNumber : cmp.get('v.data').bundleName,
              bndleProduct : tableDataProduct[ind].bundleProd,
              q: Intl.NumberFormat('cat-ES').format(tableDataProduct[ind].qntity),
              qNumber : tableDataProduct[ind].qntity,
              addedNumber : cmp.get('v.data').cif
            }
          );
        }
      if(cmp.get('v.data').cif > 0){
        var article = cmp.find("articleID");
        var divID = cmp.find("articleDivID");
        $A.util.addClass(article,"isBestClassSelect");
        $A.util.removeClass(divID,"bundleClassNotSelected");
        $A.util.addClass(divID,"bundleCLass");
        cmp.set('v.bundleAddedNumber', cmp.get('v.data').cif);
        cmp.set('v.removeButtonDisable', false);
        bundleEvent.setParam('bundleName', cmp.get('v.data').bundleName);
        bundleEvent.setParam('dataProductsPreview' , dataProduct);
        bundleEvent.setParam('bundleAnnualPrice',cmp.get('v.data').bundlePrice);
        bundleEvent.setParam('bundleAddedNumber', cmp.get('v.data').cif);
        bundleEvent.setParam('operation' , 'Add');
        bundleEvent.fire();
      }else{
        cmp.set('v.bundleAddedNumber', 0);
      }
      cmp.set('v.dataProducts' , dataProduct);
      cmp.set('v.bundleProductsInitialList' , dataProductInitial);
      let bestOption=cmp.get('v.data').isBestOption;
      var article = cmp.find("articleID");
      let mayorTable = cmp.get('v.data').bundleProducts.length;
      if(bestOption){
        $A.util.addClass(article,"isBestClass");
      }else{
        $A.util.removeClass(article,"isBestClass");
      }
      cmp.set('v.articleHeader',bestOption);

      if(mayorTable>4){
        cmp.set('v.tableLength',true);
      }else{
        cmp.set('v.tableLength',false);
      }
    }else{
        dataProduct.push(
          {
            bndleProduct : '',
            q: ''
          }
        );
      cmp.set('v.dataProductsPreview' , dataProduct);
      cmp.set('v.dataProductsPreviewInitial' , dataProduct);
    }
  },
    
  buttonAddAction: function(cmp,event,helper,component){
    var bundleEvent = $A.get("e.c:PRW_BundleEvent");
    var draftvaluesTable = cmp.get('v.draftValues');
    var dataToSend = cmp.get('v.dataProducts');
    var article = cmp.find("articleID");
    var divID = cmp.find("articleDivID");
    $A.util.addClass(article,"isBestClassSelect");
    $A.util.removeClass(divID,"bundleClassNotSelected");
    $A.util.addClass(divID,"bundleCLass");
    cmp.set('v.removeButtonDisable', false);
    if(draftvaluesTable != '[]'){
      for(var intLoop=0 ; intLoop<draftvaluesTable.length;intLoop++){
        dataToSend[draftvaluesTable[intLoop].id.split("-")[1]].q  = draftvaluesTable[intLoop].q;
      }
    }
    bundleEvent.setParam('bundleName', cmp.get('v.data').bundleName );
    bundleEvent.setParam('dataProductsPreview' , dataToSend);
    bundleEvent.setParam('bundleAnnualPrice',cmp.get('v.totalAnnualValueNotPreviewNumber'));
    bundleEvent.setParam('bundleAddedNumber', cmp.get('v.bundleAddedNumber')+1);
    bundleEvent.setParam('operation' , 'Add');
    cmp.set('v.bundleAddedNumber', cmp.get('v.bundleAddedNumber')+1 );
    bundleEvent.fire();
  },

  buttonDeleteAction: function(cmp,event,helper,component){
    var bundleEvent = $A.get("e.c:PRW_BundleEvent");
    var article = cmp.find("articleID");
    var divID = cmp.find("articleDivID");
    let dataToSend = cmp.get('v.dataProducts');
    let option = [];
    option.length=0;

    //se controla el total annual price
      if(cmp.get('v.bundleAddedNumber')==1){
        $A.util.removeClass(article,"isBestClassSelect");
        $A.util.removeClass(divID,"bundleCLass");
        $A.util.addClass(divID,"bundleClassNotSelected");
        cmp.set('v.removeButtonDisable', true);
      }
      
      bundleEvent.setParam('bundleAddedNumber', cmp.get('v.bundleAddedNumber')-1);
      cmp.set('v.bundleAddedNumber', cmp.get('v.bundleAddedNumber')-1);
      bundleEvent.setParam('dataProductsPreview',dataToSend);
      bundleEvent.setParam('operation' , 'Substract');
      bundleEvent.fire();
  },

  selectionAction: function(cmp, event, handler){
    //si es preview inicializo la tabla que va a tener todos los datos
    if(cmp.get('v.isPreview')){
      var productsAdded = cmp.get('v.dataProductsAdded');
      if(productsAdded == '[]'){
        productsAdded= [];
      }
      var masterDataTable = cmp.get('v.masterDataPreview');
      if(masterDataTable == '[]'){
        masterDataTable= [];
      }
      var operationType = event.getParam('operation'); 
      var bundleProducts = event.getParam('dataProductsPreview');
      var annualPrice = 0;
      var bundlePrice = event.getParam('bundleAnnualPrice');
      var bundlePreviewProducts = [];
      var bundleNumberAdded = event.getParam('bundleAddedNumber');
      //si el n�mero de cif es mayor que 0 proceso la informaci�n
      if(operationType === 'Add'){
        //si la tabla est� vac�a meto los datos de entrada
        if(masterDataTable ==[]){
          masterDataTable.push(
            {
              bundleOrigin : bundleProducts[0].bndleNumber,
              bundleProducts : bundleProducts,
              bundleAddedNumber : bundleNumberAdded,
              bundlePrice : bundlePrice
            }
          )
          //si tiene datos busco alguna coincidencia con el bundle de origen 
        } else {
          var indexMasterTable = masterDataTable.findIndex(({bundleOrigin}) => bundleOrigin === bundleProducts[0].bndleNumber);
          // si no encuentra coincidencia devuelve -1 y eso quiere decir que tengo que a�adir estos datos a la tabla
          if(indexMasterTable == -1){
            masterDataTable.push(
              {
                bundleOrigin : bundleProducts[0].bndleNumber,
                bundleProducts : bundleProducts,
                bundleAddedNumber : bundleNumberAdded,
                bundlePrice : bundlePrice
              }
            );
            //si encuentra coincidencia modifico el numero de cif, el resto de datos ya los tengo
          }else{
            masterDataTable[indexMasterTable].bundleAddedNumber = bundleNumberAdded;
          } 
        } 
        
      }else if (operationType === 'Add Product'){
        if(productsAdded.length==0){
          for(var indAdd = 0; indAdd<bundleProducts.length; indAdd++ ){
              productsAdded.push({
                bndleProductAdded : bundleProducts[indAdd].prod_name ,
                prod_id : bundleProducts[indAdd].prod_id,
                p : null,
                q : null,
                pNumber : 0,
                qNumber : 0
              });  
          }
        }else{
          var prodAdded = [];

          for(var indAdd2 = 0; indAdd2<productsAdded.length; indAdd2++){
            prodAdded.push(productsAdded[indAdd2].prod_id);  
          }
          for(var indAdd = 0; indAdd<bundleProducts.length; indAdd++ ){
            if(!prodAdded.includes(bundleProducts[indAdd].prod_id)){
              productsAdded.push({
                bndleProductAdded : bundleProducts[indAdd].family + ' - ' + bundleProducts[indAdd].prod_name ,
                prod_id : bundleProducts[indAdd].prod_id,
                p : null,
                q : null,
                pNumber : 0,
                qNumber : 0
              }); 
            }
          }
          productsAdded.sort((a, b) => (a.bndleProductAdded > b.bndleProductAdded) ? 1 : -1);
        }
        if(productsAdded.length > 0){
          cmp.set('v.isProductAddedPreview', true);
        }
        cmp.set('v.dataProductsAdded', productsAdded);

      }else if(operationType !== 'Add' && operationType !== 'Delete Product' && operationType !== 'Add Product'){
        var indexMasterTable = masterDataTable.findIndex(({bundleOrigin}) => bundleOrigin === bundleProducts[0].bndleNumber);
        if(operationType === 'Edit Cell'){

          masterDataTable[indexMasterTable].bundleProducts = bundleProducts;

        }else if(operationType === 'Edit Price'){


          masterDataTable[indexMasterTable].bundlePrice = bundlePrice;

        }else if(operationType === 'Substract'){

          masterDataTable[indexMasterTable].bundleAddedNumber = bundleNumberAdded;

        }else if (operationType === 'Reset'){

          masterDataTable[indexMasterTable].bundleProducts = bundleProducts;
          masterDataTable[indexMasterTable].bundlePrice = bundlePrice;

        }
      }
      cmp.set('v.masterDataPreview' ,masterDataTable);
      // recorremos la tabla maestra para generar el preview, a�adiendo en una tabla de productos y calculando el annual price de todos los elementos cuyo cif sea mayo que 0
      for(var indMasterTable1 = 0 ;  indMasterTable1 <  masterDataTable.length ; indMasterTable1++){
        if(masterDataTable[indMasterTable1].bundleAddedNumber > 0){
          //recorremos los productos dentro de cada bundle (masterDataTable[indMasterTable1].bundleProducts, es una lista) y comprobamos si la lista de bundleProduct lo contiene
          for(var indProductList = 0; indProductList < masterDataTable[indMasterTable1].bundleProducts.length ; indProductList ++){
            //si preview no esta vacio, sumar lo necesario y as� podemos utilizar el findindex q
            var productElement =  bundlePreviewProducts.find(({bndleProduct}) => bndleProduct == masterDataTable[indMasterTable1].bundleProducts[indProductList].bndleProduct);
            //si lo contiene le sumo el q (numero cif/bundleAddedNumber * q) 
            
            if(productElement != undefined){
              productElement.qNumber += parseInt(masterDataTable[indMasterTable1].bundleAddedNumber) * parseInt(masterDataTable[indMasterTable1].bundleProducts[indProductList].qNumber);
              productElement.q = Intl.NumberFormat('cat-ES').format(productElement.qNumber);
            }else{            
              // si no encontr� el producto en la lista lo a�ado
             
              bundlePreviewProducts.push({
                bndleProduct : masterDataTable[indMasterTable1].bundleProducts[indProductList].bndleProduct,
                qNumber : parseInt(masterDataTable[indMasterTable1].bundleAddedNumber) * parseInt(masterDataTable[indMasterTable1].bundleProducts[indProductList].qNumber),
                q : Intl.NumberFormat('cat-ES').format(parseInt(masterDataTable[indMasterTable1].bundleAddedNumber) * parseInt(masterDataTable[indMasterTable1].bundleProducts[indProductList].qNumber))
              });
            }
          }
          //operaci�n para sumar los anual price por el cif
          annualPrice += parseInt(masterDataTable[indMasterTable1].bundleAddedNumber) * parseFloat(masterDataTable[indMasterTable1].bundlePrice);
        }
      }
      for(let i=0;i<productsAdded.length ;i++){
        annualPrice += parseFloat(productsAdded[i].pNumber) * parseFloat(productsAdded[i].qNumber);
      }
      var totalAnnualPriceFormat = Intl.NumberFormat('cat-ES', { style: 'currency', currency: 'EUR', minimumFractionDigits:'0'}).format(parseInt(annualPrice));
      bundlePreviewProducts.sort((a, b) => (a.bndleProduct > b.bndleProduct) ? 1 : -1);
      cmp.set('v.totalAnnualValueInitial', totalAnnualPriceFormat);
      cmp.set('v.totalAnnualValueNumber', annualPrice);
      cmp.set('v.totalAnnualValue', totalAnnualPriceFormat);
      cmp.set('v.dataProductsPreview', bundlePreviewProducts);
      cmp.set('v.buttonSendInbox', bundlePreviewProducts.length <= 0);
    }

    if(cmp.get('v.isPreview')){
      cmp.set('v.draftValues',[]);
      var inputID = cmp.find("inputColorPreview");
      $A.util.removeClass(inputID,"cellInputClass");
    }

    if(!cmp.get('v.isPreview')){
      
      var operationType = event.getParam('operation'); 
      if((operationType == 'Add Product' || operationType =='Delete Product') && cmp.get('v.catalog') !== undefined){
        var bundleProds = cmp.get('v.dataProducts');
        var specialProd = event.getParam('dataProductsPreview');
        var catalog = JSON.parse(cmp.get('v.catalog'));
        var flagSpecialIncluded = false;
        var bannedProducts = [];
          specialProd.forEach((product,index) => {
            catalog.forEach((catalogEl,index) => {
              if(catalogEl.thirdLevel == product.prod_id && catalogEl.firstLevel !== undefined){
                bannedProducts.push(catalogEl.firstLevel);
              }
            });
          });
        bundleProds.forEach((bundleProd,index) =>{
          if(bannedProducts.includes(bundleProd.bndleProduct)){
            flagSpecialIncluded = true;
          }
        });
        var article = cmp.find("articleID");
        var divID = cmp.find("articleDivID");
        if(flagSpecialIncluded){
          $A.util.addClass(article,"isNotAvailable");
          $A.util.removeClass(divID,"bundleClassNotSelected");
          $A.util.addClass(divID,"bundleCLass");
          cmp.set('v.bundleAvailable' , false);
        }else{
          $A.util.removeClass(article,"isNotAvailable");
          $A.util.removeClass(divID,"bundleCLass");
          $A.util.addClass(divID,"bundleClassNotSelected");
          cmp.set('v.bundleAvailable' , true);
        }
      }
    }
  },

  checkpointAction: function(cmp, event, handler){
   let estadoCheck = cmp.get('v.checkbox');
      cmp.set('v.buttonCalculate', estadoCheck);
      cmp.set('v.checkbox', !estadoCheck);        
  },
  createComponent : function(cmp, helper,cmpName, cmpParams) {
    return new Promise($A.getCallback(function(resolve, reject) {
      $A.createComponent(
        'c:' + cmpName,
        cmpParams,
        function(newCmp, status, errorMessage) {
          if (status === 'SUCCESS') {
            resolve(newCmp);
          } else if (status === 'INCOMPLETE' || status === 'ERROR') {
            console.log('Error');
            console.log('Error message : ' +errorMessage );
          }
        }
      );
    }));
  },
  bundleProductEventHandle: function(cmp, event, handler){
    let bundleSelectedName = event.getParam('bundleName');
    var CmpProduct = cmp.find("myCmp");
    var cmpInbox = cmp.find("cmpInbox");
    
    
    if(bundleSelectedName != cmp.get('v.data.bundleName')){
      cmp.set('v.buttonGeneric',true);
      cmp.set('v.checkboxActivate',true);
      cmp.set('v.buttonCalculate', true);
      cmp.set('v.radioBundle', false);
      $A.util.addClass(CmpProduct, "colorIconNotActivate");
      $A.util.removeClass(CmpProduct, "colorIconActivate");
      $A.util.addClass(cmpInbox, "colorIconNotActivate");
      $A.util.removeClass(cmpInbox, "colorIconActivate");
    }
  },

  sendEmailAction : function(component, helper) {
    var draftValues = component.get('v.draftValues');
    var productsValues = component.get('v.dataProductsPreview');
    var dataToSendFinal = [];
    
    var specialToSend = component.get('v.dataProductsAdded') == '[]' ? null : component.get('v.dataProductsAdded');
    for(let i=0;i<productsValues.length;i++){ 
        dataToSendFinal.push(
          {
            bndleNumber : productsValues[i].bndleNumber,
            bndleProduct : productsValues[i].bndleProduct,
            q:  productsValues[i].q,
            qNumber: productsValues[i].qNumber
          }
        );  
    }
    if(component.get('v.draftValues').length !== 0){
      for(var indValues = 0 ; indValues<draftValues.length ; indValues++){
        dataToSendFinal[draftValues[indValues].id.split("-")[1]].q  = draftValues[indValues].q;
      }
    }
    $A.createComponent(
      'c:PRW_TemplateBuilder',
      {
          'recordId': 'BND:::::'+JSON.stringify(component.get('v.totalAnnualValue'))+':::::'+
          component.get('v.accountId')+':::::'+component.get('v.lAccountId')
          +':::::'+component.get('v.profSheetId')+':::::'+component.get('v.isGroup')
          +':::::'+JSON.stringify(dataToSendFinal)+':::::'+JSON.stringify(specialToSend)

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

  handleCellChange : function(cmp, event, draftValues) {
    var bundleEvent = $A.get("e.c:PRW_BundleEvent");          
    var draftvaluesTable = cmp.get('v.draftValues');
    var dataToSend = cmp.get('v.dataProducts');
    var dataToSendFinal = [];
    if(cmp.get('v.isPreview')){
      bundleEvent.setParam('isBundlePreviewEdited', true);
    }
    if(draftValues[0].q == ''){ 
      draftValues[0].q = 0;
    }
    if(draftValues[0].q != 0){
      draftValues[0].q = draftValues[0].q.replace('.','');
    }
    // el numero cambio es un numero? Si es que s� le aplico el formato, de ser que no pongo format error
    draftValues[0].qNumber = isNaN(draftValues[0].q) ? 'Format Error' : parseInt(draftValues[0].q);
    draftValues[0].q = isNaN(draftValues[0].q) ? 'Format Error' : Intl.NumberFormat('cat-ES').format(parseInt(draftValues[0].q));
    
    //le meto  el numero crudo en la informacion del dato a enviar en evento
    if(!isNaN(draftValues[0].q)){
      for(let i=0;i<dataToSend.length;i++){ 
        if(draftValues[0].id.split("-")[1]==i){
          dataToSendFinal.push(
            {
              bndleNumber : dataToSend[i].bndleNumber,
              bndleProduct : dataToSend[i].bndleProduct,
              q:  draftValues[0].q,
              qNumber: draftValues[0].qNumber
            }
          );        
        }else{
          dataToSendFinal.push(
            {
              bndleNumber : dataToSend[i].bndleNumber,
              bndleProduct : dataToSend[i].bndleProduct,
              q:  dataToSend[i].q,
              qNumber: dataToSend[i].qNumber
            }
          );
        }
      }
    }
   
    if(draftvaluesTable != '[]'){
      draftvaluesTable.push(draftValues[0]);
      cmp.set('v.draftValues', draftvaluesTable);
    }else{
    cmp.set('v.draftValues', draftValues);
    }

    cmp.set('v.buttonReset' , false);

    if(!cmp.get('v.isPreview')){
      if(cmp.get('v.bundleAddedNumber') != 0){
        bundleEvent.setParam('dataProductsPreview' , dataToSendFinal);
        bundleEvent.setParam('operation' , 'Edit Cell');
      }
        bundleEvent.fire();
    }
  },
  handleCellChangeAdded : function(cmp, event, draftValues) {
    let keysChange = Object.keys(draftValues[0]);
    var currentData = cmp.get('v.dataProductsAdded');
    var masterdata = cmp.get('v.masterDataPreview');
    var keyAux;
    var annualValue =0;
    for(var keyCh in keysChange) {
      if(keysChange[keyCh] !== 'id') {
        keyAux = keysChange[keyCh];
      }
    }
    if(draftValues[0][keyAux] == ''){ 
      draftValues[0][keyAux] = 0;
    }
        if(keyAux === 'q'){
          if(draftValues[0].q != 0){
    draftValues[0].q = draftValues[0].q.replace('.','');
          }
          currentData[draftValues[0].id.split("-")[1]].qNumber = isNaN(parseFloat(draftValues[0].q)) ? 0 : parseInt(draftValues[0].q);
          currentData[draftValues[0].id.split("-")[1]].q = isNaN(parseFloat(draftValues[0].q)) ? 'Format Error' : Intl.NumberFormat('cat-ES').format(parseInt(draftValues[0].q));
          currentData[draftValues[0].id.split("-")[1]].p = currentData[draftValues[0].id.split("-")[1]].pEdited ? Intl.NumberFormat('cat-ES', { style: 'currency', currency: 'EUR' , minimumFractionDigits:'4'}).format(currentData[draftValues[0].id.split("-")[1]].pNumber) : Intl.NumberFormat('cat-ES', { style: 'currency', currency: 'EUR'}).format(0);
          currentData[draftValues[0].id.split("-")[1]].pNumber = currentData[draftValues[0].id.split("-")[1]].pEdited ? currentData[draftValues[0].id.split("-")[1]].pNumber : 0 ;
          currentData[draftValues[0].id.split("-")[1]].qEdited = true;
        }else{
          if(draftValues[0].p != 0){
            draftValues[0].p = draftValues[0].p.replace('.','');
            draftValues[0].p = draftValues[0].p.replace(',','.');
          }
        currentData[draftValues[0].id.split("-")[1]].pNumber = isNaN(parseFloat(draftValues[0].p)) ? 0 : parseFloat(draftValues[0].p);
        currentData[draftValues[0].id.split("-")[1]].p = isNaN(parseFloat(draftValues[0].p)) ? 'Format Error' : Intl.NumberFormat('cat-ES', { style: 'currency', currency: 'EUR', minimumFractionDigits:'4'}).format(parseFloat(draftValues[0].p));    
        currentData[draftValues[0].id.split("-")[1]].qNumber = currentData[draftValues[0].id.split("-")[1]].qEdited ? currentData[draftValues[0].id.split("-")[1]].qNumber : 0;
        currentData[draftValues[0].id.split("-")[1]].q = currentData[draftValues[0].id.split("-")[1]].qEdited ? currentData[draftValues[0].id.split("-")[1]].q : '0';
        currentData[draftValues[0].id.split("-")[1]].pEdited = true;    
        
      }
  annualValue +=currentData[draftValues[0].id.split("-")[1]].pNumber * currentData[draftValues[0].id.split("-")[1]].qNumber;
  for(var ind2 = 0; ind2 < masterdata.length; ind2++) {
    if(masterdata[ind2].bundleAddedNumber> 0){
      annualValue += masterdata[ind2].bundleAddedNumber * masterdata[ind2].bundlePrice;
    }
  }
    cmp.set('v.totalAnnualValueNumber', annualValue);
    cmp.set('v.totalAnnualValue', Intl.NumberFormat('cat-ES', { style: 'currency', currency: 'EUR', minimumFractionDigits:'0'}).format(parseInt(annualValue)));
    cmp.set('v.dataProductsAdded', currentData);
    cmp.set('v.draftValuesAdded' , []);

  },

  handleResetBundle : function(cmp,event){
    var bundleEvent = $A.get("e.c:PRW_BundleEvent");
    var divID = cmp.find("inputColorNotPreviewID");
    $A.util.removeClass(divID,"cellInputClass");
    cmp.set('v.dataProducts', cmp.get('v.bundleProductsInitialList'));

      
      //input preview
      if(cmp.get('v.bundleAddedNumber')>0){
        bundleEvent.setParam('dataProductsPreview' , cmp.get('v.dataProducts'));
        bundleEvent.setParam('bundleAnnualPrice', cmp.get('v.data').bundlePrice);
        bundleEvent.setParam('operation' , 'Reset');
        bundleEvent.fire();
      }
      if(cmp.get('v.isPreview')){
        var previewID = cmp.find("inputColorPreview");
        var annualValue = 0 ;
        var masterdata = cmp.get('v.masterDataPreview');
        var productsAdded = cmp.get('v.dataProductsAdded');
        if(productsAdded == '[]'){
          productsAdded = [];
        }
        $A.util.removeClass(previewID,"cellInputClass");
        for(var ind2 = 0; ind2 < masterdata.length; ind2++) {
          if(masterdata[ind2].bundleAddedNumber> 0){
            annualValue += masterdata[ind2].bundleAddedNumber * masterdata[ind2].bundlePrice;
          }
        } 
        for(var ind1 = 0; ind1 < productsAdded.length; ind1++) {
          if((productsAdded[ind1].optimalPrice != -1 && productsAdded[ind1].optimalVolume != -1) && productsAdded[ind1]!== undefined){
            
          annualValue += productsAdded[ind1].pNumber * productsAdded[ind1].qNumber;
          }
        }
        cmp.set('v.totalAnnualValueNumber' , parseFloat(annualValue));
        cmp.set('v.totalAnnualValue', Intl.NumberFormat('cat-ES', { style: 'currency', currency: 'EUR', minimumFractionDigits:'0'}).format(parseInt(annualValue)));
        
      }else{
      cmp.set('v.totalAnnualValueNotPreview', Intl.NumberFormat('cat-ES', { style: 'currency', currency: 'EUR', minimumFractionDigits:'0'}).format(cmp.get('v.data').bundlePrice));
      }
      cmp.set('v.draftValues', []);
      cmp.set('v.buttonReset', true);
      
  },

  changeInputHandler : function(cmp,event){
    var divID = cmp.find("inputColorPreview");
    $A.util.addClass(divID,"cellInputClass");
    let aux = cmp.get('v.totalAnnualValue');
    var arrayAux= aux.split("");
    var stringToNumber ='';
    if(arrayAux[arrayAux.length-1]==$A.get('$Label.c.PRW_Euro')){
      arrayAux.splice(arrayAux.length-1,1);
    }
    for(let i=0;i<arrayAux.length;i++){
      if(isNaN(arrayAux[i])){
        if(arrayAux[i]=='.'){
          arrayAux.splice(i,1);1
        }else if(arrayAux[i]!='.'){
          stringToNumber = 'Format Error';
          cmp.set('v.totalAnnualValue', stringToNumber);
          break;
        }
      }
    }
    if(stringToNumber != 'Format Error'){
      for(var ind = 0; ind<arrayAux.length; ind ++){
        stringToNumber += arrayAux[ind];
      }
    
      if(stringToNumber!='Format Error'){
        cmp.set('v.totalAnnualValueNumber' , parseFloat(stringToNumber));
        cmp.set('v.totalAnnualValue', Intl.NumberFormat('cat-ES', { style: 'currency', currency: 'EUR', minimumFractionDigits:'0'}).format(parseInt(stringToNumber)));
      }
    }
    cmp.set('v.buttonReset' , false);
  },

  changeInputNotPreviewHandler : function(cmp,event){
    let input = cmp.get('v.totalAnnualValueNotPreview');
    var bundleEvent = $A.get("e.c:PRW_BundleEvent");        
    var divID = cmp.find("inputColorNotPreviewID");
    $A.util.addClass(divID,"cellInputClass");
    var stringToNumber ='';
    var aux = input;
    var arrayAux= aux.split("");

    //comprobar que el usuario ha escrito bien el numero  
      if(arrayAux[arrayAux.length-1]==$A.get('$Label.c.PRW_Euro')){
        arrayAux.splice(arrayAux.length-1,1);
      }
      for(let i=0;i<arrayAux.length;i++){
        if(isNaN(arrayAux[i])){
          if(arrayAux[i]=='.'){
            arrayAux.splice(i,1);1
          }else if(arrayAux[i]!='.'){
            stringToNumber = 'Format Error';
            cmp.set('v.totalAnnualValueNotPreview', stringToNumber);
            break;
          }
        }
      }
      if(stringToNumber != 'Format Error'){
        for(var ind = 0; ind<arrayAux.length; ind ++){
          stringToNumber += arrayAux[ind];
        }
      }
      

      if(stringToNumber!='Format Error'){
        cmp.set('v.totalAnnualValueNotPreview', Intl.NumberFormat('cat-ES', { style: 'currency', currency: 'EUR', minimumFractionDigits:'0'}).format(parseFloat(stringToNumber)));
        if(cmp.get('v.bundleAddedNumber')>0){
          bundleEvent.setParam('bundleAnnualPrice', parseFloat(stringToNumber));
          bundleEvent.setParam('operation' , 'Edit Price');
        }
      }
    // }

    bundleEvent.setParam('dataProductsPreview' , cmp.get('v.dataProducts'));
    bundleEvent.setParam('buttonReset', false);
    cmp.set('v.buttonReset',event.getParam('buttonReset'));
    bundleEvent.fire();
  },
  handleDelete: function(cmp, row) {
    var annualValue = 0 ;
    var masterdata = cmp.get('v.masterDataPreview');
    var productsAdded = cmp.get('v.dataProductsAdded');
    var indexMasterTable = productsAdded.findIndex(({prod_id}) => prod_id === row.prod_id);
    productsAdded.splice(indexMasterTable,1);
    for(var ind1 = 0; ind1 < productsAdded.length; ind1++) {
      if(productsAdded[ind1].optimalPrice != -1 && productsAdded[ind1].optimalVolume != -1){
      annualValue += productsAdded[ind1].pNumber * productsAdded[ind1].qNumber;
      }
    }
    for(var ind2 = 0; ind2 < masterdata.length; ind2++) {
      if(masterdata[ind2].bundleAddedNumber> 0){
        annualValue += masterdata[ind2].bundleAddedNumber * masterdata[ind2].bundlePrice;
      }
    }
    cmp.set('v.dataProductsAdded' , productsAdded);
    cmp.set('v.totalAnnualValueNumber', annualValue);
    cmp.set('v.totalAnnualValue', Intl.NumberFormat('cat-ES', { style: 'currency', currency: 'EUR', minimumFractionDigits:'0'}).format(parseInt(annualValue)));
    if(productsAdded.length == 0 ){
      cmp.set('v.isProductAddedPreview' , false);
    } 
    console.log('sending not deleted products : ' + productsAdded);
    let bundleEvent = $A.get("e.c:PRW_BundleEvent"); 
      bundleEvent.setParam('operation','Delete Product');
      bundleEvent.setParam('dataProductsPreview',productsAdded);
      bundleEvent.fire();
  },
  handleCalculation: function(component, event,helper){
    var actionCalculate = component.get('c.calculatePrice');
    var productsAdded = component.get('v.dataProductsAdded');
    var dataToCalculate = [];
    for(var indProd = 0; indProd<productsAdded.length ; indProd++){
      dataToCalculate.push(
        {
          id_prod : productsAdded[indProd].prod_id,
          simulatedP : productsAdded[indProd].pNumber,
          simulatedQ : productsAdded[indProd].qNumber
        }
      )
    }
    var customerID = component.get('v.acc').g_customer_id__c;
    customerID= customerID.substring(customerID.length - 9);
    actionCalculate.setParams({
      clientCode: customerID,
      data: JSON.stringify(dataToCalculate),
      idCuaderno: component.get('v.profSheetId'),
      isGroup: true 
    });
    var promiseCalculate = this.promisifyBundle(actionCalculate);
    return promiseCalculate.then(
      $A.getCallback(function(result) {
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
  promisifyBundle: function(actionCalculate) {
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
  proccessResponse : function(component, products) {
    var currentValues = component.get('v.dataProductsAdded');
    var masterdata = component.get('v.masterDataPreview');
    var annualprice = 0;
    for(var ind = 0; ind < currentValues.length; ind++) {
      for(var ind1 = 0; ind1 < products.length; ind1++) {
        if(currentValues[ind].prod_id === products[ind1].id_y) {
          
          currentValues[ind].pNumber = products[ind1].optimalPrice == 0 ? currentValues[ind].simulatedP : parseFloat(products[ind1].optimalPrice);//NOSONAR
          currentValues[ind].qNumber = products[ind1].optimalVolume == 0 ? currentValues[ind].simulatedQ : parseFloat(products[ind1].optimalVolume);//NOSONAR
          currentValues[ind].p = products[ind1].optimalPrice == 0 ? Intl.NumberFormat('cat-ES', { style: 'currency', currency: 'EUR'}).format(0) : Intl.NumberFormat('cat-ES', { style: 'currency', currency: 'EUR', minimumFractionDigits:'4'}).format(parseFloat(products[ind1].optimalPrice));
          currentValues[ind].q = products[ind1].optimalVolume ==  0 ? '0' : Intl.NumberFormat('cat-ES').format(parseFloat(products[ind1].optimalVolume));
          if(products[ind1].optimalPrice != -1 && products[ind1].optimalVolume != -1){
          annualprice += products[ind1].optimalPrice * products[ind1].optimalVolume;
          }
        }
      }
    }
    for(var ind2 = 0; ind2 < masterdata.length; ind2++) {
      if(masterdata[ind2].bundleAddedNumber> 0){
        annualprice += masterdata[ind2].bundleAddedNumber * masterdata[ind2].bundlePrice;
      }
    }
    component.set('v.totalAnnualValueNumber', annualprice);
    component.set('v.totalAnnualValue', Intl.NumberFormat('cat-ES', { style: 'currency', currency: 'EUR', minimumFractionDigits:'0'}).format(parseInt(annualprice)));
    component.set('v.dataProductsAdded', currentValues);
    
  },
  setCatalog : function(component,event, helper) {
    var catalog = event.getParam('catalog');
    component.set('v.catalog' ,catalog);
  }
})