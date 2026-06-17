({
  doInit: function(cmp, event, helper) {
    this.getFlatProducts(cmp);
  },

  toggleGroup: function(cmp, event, helper) {
    const fam = event.getSource().get('v.value');
    const prod = cmp.find('checkbox').filter(c => c.get('v.name') === fam);
    const check = event.getSource().get('v.checked');
    var i = 0;
    var d = 0;
    $A.util.removeClass(event.getSource(), 'indeterminated');

    prod.forEach(prod => {
      if (!prod.get('v.disabled')) {
        prod.set('v.checked', check);
      }else{
        d++;
      }
      if (prod.get('v.checked') && prod.get('v.disabled') == false) {
        i++;
      }
    });
    if (i === prod.length - d) {
      event.getSource().set('v.checked', true);
    } else if (i === 0) {
      event.getSource().set('v.checked', false);
    } else {
      event.getSource().set('v.checked', false);
      $A.util.addClass(event.getSource(), 'indeterminated');
    }
  },

  flatToggleGroup: function(cmp, event, helper) {
    const familyGroup = event.getSource().get('v.name');
    const group = cmp.find('group').filter(c => c.get('v.value') === familyGroup);
    const conds = cmp.find('checkbox').filter(c => c.get('v.name') === familyGroup);
    const condsCheked = cmp.find('checkbox').filter(c => c.get('v.name') === familyGroup && c.get('v.checked'));
    $A.util.removeClass(group[0], 'indeterminated');

    if (condsCheked.length === 0) {
      group[0].set('v.checked', false);
    } else if (condsCheked.length === conds.length) {
      group[0].set('v.checked', true);
    } else {
      group[0].set('v.checked', false);
      $A.util.addClass(group[0], 'indeterminated');
    }
  },

  handleContinue: function(cmp, event, helper) {
    const prodchecked = cmp.find('checkbox').filter(c => c.get('v.checked'));
    var cont = prodchecked.length !== 0;

    if (!cont) {
      cmp.set('v.showNotChecked', true);
      setTimeout(function() {
        cmp.set('v.showNotChecked', false);
      }, 10000);

    } else {
      let productsSelected = [];
      prodchecked.forEach(c => {
        productsSelected.push(c.get('v.value'));
      });
      let productsSelectContinueEvent = cmp.getEvent('productSelectContinueEvt');
      productsSelectContinueEvent.setParams({
        productsSelected: productsSelected,
        products: cmp.get('v.products'),
        firstProdIds: cmp.get('v.firstProdIds')
      });
      productsSelectContinueEvent.fire();
      helper.destroyCmp(cmp, event, helper);
    }
  },

  getFlatProducts: function(component) {
    var actionFlat = component.get('c.gtFlatProducts');
    var promise = this.promisifyAddFlatAction(actionFlat);
    var families = [];
    var familiesObj = [];
    var products = [];
    var productsIds = [];
    var bannedProd = [];
    var bannedProdId = [];
    var catalog = component.get('v.catalog');
    var flag = false;
    if(catalog != null && catalog != undefined){
      catalog = JSON.parse(catalog);
    }else{
      flag = true;
    }
    var otherTableData =  component.get('v.otherTableData');
    if(otherTableData != null && otherTableData != undefined){
      otherTableData = JSON.parse(component.get('v.otherTableData'));
    }else{
      flag = true;
    }
    if(!flag){
      otherTableData.forEach((product,index) => {
        catalog.forEach((catalogEl,index) => {
          if(catalogEl.thirdLevel == product.id_prod){
            bannedProd.push(catalogEl.secondLevel);
          }
        });
      });
    }
    
    component.get('v.dataTable').forEach((product, index) => {
      if(product.id_prod !== undefined) {
        productsIds.push(product.id_prod);
      }
    });

    return promise.then(
      $A.getCallback(function(result) {
        result.forEach((product, index) => {
          var addString = bannedProd.includes(product.Id_product__c) ? $A.get('$Label.c.PRW_Asteris')+ $A.get('$Label.c.PRW_Asteris') : '';
          products.push(
            {
              'prod_name': product.Product_name__c + addString,
              'prod_id': product.Id_product__c,
              'checked': productsIds.includes(product.Id_product__c),
              'disabled': bannedProd.includes(product.Id_product__c),
              'id': product.Id_product__c,
              'family' : product.Family_Name__c
            }
          );
          if(familiesObj.length > 0 && familiesObj[familiesObj.length-1].name === product.Family_Name__c) {
            if(!productsIds.includes(product.Id_product__c) && familiesObj[familiesObj.length-1].checked) {
              familiesObj[familiesObj.length-1].indeterminated = true;
              familiesObj[familiesObj.length-1].checked = false;
            } else if(productsIds.includes(product.Id_product__c) && !familiesObj[familiesObj.length-1].checked) {
              familiesObj[familiesObj.length-1].indeterminated = true;
            }if(!bannedProd.includes(product.cuco__gf_psc_condition_id__c) && familiesObj[familiesObj.length-1].disabled){
              familiesObj[familiesObj.length-1].disabled = false;
            }
            if(bannedProd.includes(product.Id_product__c) && !familiesObj[familiesObj.length-1].semiDisable){
              familiesObj[familiesObj.length-1].semiDisable = true;
            }
            
          } else {
            families.push(product.Family_Name__c);
            familiesObj.push(
              {
                'name': product.Family_Name__c,
                checked: productsIds.includes(product.Id_product__c),
                disabled: bannedProd.includes(product.Id_product__c),
                indeterminated: false,
                'nameDis' : product.Family_Name__c + $A.get('$Label.c.PRW_Asteris'),
                semiDisable: bannedProd.includes(product.Id_product__c)
             }
            );
          }
        });
        component.set('v.firstProdIds', productsIds);
        component.set('v.families', familiesObj);
        component.set('v.products', products);
        component.set('v.activeSections', families);
      }),
      $A.getCallback(function(error) {
        console.error( 'Error calling action "' + actionFlat + '" with state: ' + error.message );
      })
    ).catch(function(e){
    });
  },

  promisifyAddFlatAction: function(actionFlat) {
    return new Promise((resolve, reject) => {
      actionFlat.setCallback(this, function(response) {
        const status = response.getState();
        if (status === 'SUCCESS') {
          const returnValue = response.getReturnValue();
          resolve(returnValue);
        } else if (status === 'ERROR') {
          var errors = response.getError();
          if (errors) {
            if (errors[0] && errors[0].message) {
              reject(Error('Error message: ' + errors[0].message));
            }
          } else {
            reject(Error('Unknown error'));
          }
      }
      });

      $A.enqueueAction(actionFlat);
    });
  },
})