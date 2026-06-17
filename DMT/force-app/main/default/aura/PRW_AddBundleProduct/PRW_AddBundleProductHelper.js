({
  doInit: function(cmp, event, helper) {
    this.getListProducts(cmp);
  },
  getListProducts: function(component) {
    var action = component.get('c.gtSpecialProducts');
    var promise = this.promisifyAddSpecialAction(action);
    var families = [];
    var familiesObj = [];
    var products = [];
    var productsIds = [];
    var sections = [];
    var sectionsAc = [];
    var bannedProd = [];
    var bannedProdName = [];
    var specialProds = component.get('v.dataTable');
    var bundleProds = component.get('v.bundleProds'); 
    var catalog = component.get('v.catalog');
    var flag = false;
    if(catalog != null && catalog != undefined){
      catalog = JSON.parse(catalog);
    }else{
      flag = true;
    }
    if(specialProds == '[]'){
      specialProds = [];
    }
    if(bundleProds == '[]'){
      bundleProds = [];
      flag = true;
    }
    if(!flag){
      bundleProds.forEach((product,index) => {
        catalog.forEach((catalogEl,index) => {
          if(catalogEl.firstLevel === product.bndleProduct && catalogEl.firstLevel !== undefined){
            bannedProd.push(catalogEl.thirdLevel);
            bannedProdName.push(catalogEl);
          }
        });
      });
    }
    specialProds.forEach((product, index) => {
        if(product.prod_id !== undefined) {
          productsIds.push(product.prod_id);
        }
      });

    return promise.then(
      $A.getCallback(function(result) {
        result.forEach((product, index) => {
          if(bannedProd.includes(product.cuco__gf_psc_condition_id__c)){
          }
          var addString = bannedProd.includes(product.cuco__gf_psc_condition_id__c) ? $A.get('$Label.c.PRW_Asteris') + $A.get('$Label.c.PRW_Asteris')  : '';
          products.push(
            {
              'prod_name': product.Name + addString,
              'prod_id': product.cuco__gf_psc_condition_id__c,
              'checked': productsIds.includes(product.cuco__gf_psc_condition_id__c),
              'disabled': bannedProd.includes(product.cuco__gf_psc_condition_id__c),
              'id': product.cuco__gf_psc_condition_id__c,
              'family' : product.cuco__gf_psc_family_id__r.Name
            }
          );
          if(familiesObj.length > 0 && familiesObj[familiesObj.length-1].name === product.cuco__gf_psc_family_id__r.Name) {
            if(!productsIds.includes(product.cuco__gf_psc_condition_id__c) && familiesObj[familiesObj.length-1].checked) {
              familiesObj[familiesObj.length-1].indeterminated = true;
              familiesObj[familiesObj.length-1].checked = false;
            } else if(productsIds.includes(product.cuco__gf_psc_condition_id__c) && !familiesObj[familiesObj.length-1].checked) {
              familiesObj[familiesObj.length-1].indeterminated = true;
            }if(!bannedProd.includes(product.cuco__gf_psc_condition_id__c) && familiesObj[familiesObj.length-1].disabled){
              familiesObj[familiesObj.length-1].disabled = false;
            }
            if(bannedProd.includes(product.cuco__gf_psc_condition_id__c) && !familiesObj[familiesObj.length-1].semiDisable){
              familiesObj[familiesObj.length-1].semiDisable = true;
            }
          } else {
            families.push(product.cuco__gf_psc_family_id__r.Name);
            familiesObj.push(
              {
                'name': product.cuco__gf_psc_family_id__r.Name,
                checked: productsIds.includes(product.cuco__gf_psc_condition_id__c),
                'disabled' : bannedProd.includes(product.cuco__gf_psc_condition_id__c),
                indeterminated: false,
                'section' : product.cuco__gf_psc_family_id__r.cuco__gf_psc_family_product_name__c,
                'nameDis' : product.cuco__gf_psc_family_id__r.Name + $A.get('$Label.c.PRW_Asteris'),
                semiDisable: bannedProd.includes(product.cuco__gf_psc_condition_id__c)
              }
            );
          }
          if(!sections.includes(product.cuco__gf_psc_family_id__r.cuco__gf_psc_family_product_name__c)) {
            sections.push(product.cuco__gf_psc_family_id__r.cuco__gf_psc_family_product_name__c);
            sectionsAc.push(product.cuco__gf_psc_family_id__r.cuco__gf_psc_family_product_name__c);
          }
        });
        component.set('v.firstProdIds', productsIds);
        component.set('v.families', familiesObj);
        component.set('v.products', products);
        component.set('v.activeSections', families);
        component.set('v.sections', sections);
        component.set('v.sectionsAccord', sectionsAc);

      }),
      $A.getCallback(function(error) {
        console.error( 'Error calling action "' + action + '" with state: ' + error.message );
      })
    ).catch(function(e){
    });
  },

  toggleGroup: function(cmp, event, helper) {
    const family = event.getSource().get('v.value');
    const products = cmp.find('checkbox').filter(c => c.get('v.name') === family);
    const check = event.getSource().get('v.checked');
    var i = 0;
    var d = 0;
    $A.util.removeClass(event.getSource(), 'indeterminated');

    products.forEach(product => {
      if (!product.get('v.disabled')) {
        product.set('v.checked', check);
      }else{
        d++
      }
      if (product.get('v.checked') && product.get('v.disabled') == false) {
        i++;
      }
    });
    if (i === products.length - d) {
      event.getSource().set('v.checked', true);
    } else if (i === 0) {
      event.getSource().set('v.checked', false);
    } else {
      event.getSource().set('v.checked', false);
      $A.util.addClass(event.getSource(), 'indeterminated');
    }
  },

  evaluateToggleGroup: function(cmp, event, helper) {
    const family = event.getSource().get('v.name');
    const group = cmp.find('group').filter(c => c.get('v.value') === family);
    const conditions = cmp.find('checkbox').filter(c => c.get('v.name') === family);
    const conditionsCheked = cmp.find('checkbox').filter(c => c.get('v.name') === family && c.get('v.checked'));
    $A.util.removeClass(group[0], 'indeterminated');

    if (conditionsCheked.length === 0) {
      group[0].set('v.checked', false);
    } else if (conditionsCheked.length === conditions.length) {
      group[0].set('v.checked', true);
    } else {
      group[0].set('v.checked', false);
      $A.util.addClass(group[0], 'indeterminated');
    }
  },

  handleContinue: function(cmp, event, helper) {
    const checked = cmp.find('checkbox').filter(c => c.get('v.checked'));
    var canContinue = checked.length !== 0;
    

    if (!canContinue) {
      cmp.set('v.showNotChecked', true);
      setTimeout(function() {
        cmp.set('v.showNotChecked', false);
      }, 10000);  

    } else {

      var products = cmp.get('v.products');
      let productsSelected = [];
      var producstToSend = [];
      checked.forEach(c => {
        var productElement =  products.find(({prod_id }) => prod_id == c.get('v.value'));
        producstToSend.push(productElement);
        productsSelected.push(c.get('v.value'));
      });
      producstToSend.sort((a, b) => (a.prod_name > b.prod_name) ? 1 : -1);
      let bundleEvent = $A.get("e.c:PRW_BundleEvent"); 
      bundleEvent.setParam('operation','Add Product');
      bundleEvent.setParam('dataProductsPreview',producstToSend);
      bundleEvent.fire();
      helper.destroyCmp(cmp, event, helper);
    }
  },

  promisifyAddSpecialAction: function(action) {
    return new Promise((resolve, reject) => {
      action.setCallback(this, function(response) {
        const state = response.getState();
        if (state === 'SUCCESS') {
          const returnValue = response.getReturnValue();
          resolve(returnValue);
        } else if (state === 'ERROR') {
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

      $A.enqueueAction(action);
    });
  },
})