({

      setData: function(cmp ,helper) {
        let tipoCliente = cmp.get('v.profSheetId') == undefined || cmp.get('v.profSheetId') == null ? 'BUSINESS' : 'NOTEBOOK' ;
        var customerID = cmp.get('v.acc').g_customer_id__c;
        customerID= customerID.substring(customerID.length - 9);
        let idClient = cmp.get('v.profSheetId') == undefined || cmp.get('v.profSheetId') == null ? customerID : cmp.get('v.profSheetId');
        let dataTableOrigin = [];
        var actionPart = cmp.get('c.gtDataBundles');
          actionPart.setParams({
            idServicio : idClient,
            clientType: tipoCliente
          });
          var promise = this.promisifyBundle(actionPart);
          
          return promise.then(
            $A.getCallback(function(result) {
              if(result.success === true) {
                let bundlesList = JSON.parse(result.bundles);
                for(var ind = 0; ind < bundlesList.length; ind++) {
                  dataTableOrigin.push(
                    {
                      bundleProducts : bundlesList[ind].bundleProd,
                      bundleName : ind + 1,
                      bundlePrice : bundlesList[ind].bundlePrice,
                      bundleCurrency : bundlesList[ind].currency_y,
                      isBestOption : bundlesList[ind].isBestOption,
                      cif : bundlesList[ind].cifs,
                      cifNames : bundlesList[ind].cifNames,
                      description : bundlesList[ind].description
                    }
                  );
                }
                  cmp.set('v.data', dataTableOrigin);
                  helper.getCatalog(cmp);
              }
              
            }),
            $A.getCallback(function(error) {
              console.error( 'Error calling action "' + actionPart + '" with state: ' + error.message );
            })
          ).catch(function(e){
          });
         
      },
      getCatalog: function(component) {
        var actionCatalog = component.get('c.gtCatalog');
        var promise = this.promisifyBundle(actionCatalog);
        return promise.then(
          $A.getCallback(function(result) {
            var firstEvent = $A.get("e.c:PRW_CatalogEvent");
            firstEvent.setParam('catalog',result.catalog);
            firstEvent.fire();
            }),
          $A.getCallback(function(error) {
          console.error( 'Error calling action "' + action + '" with state: ' + error.message );
            })
          ).catch(function(e){
          });
      },
      promisifyBundle: function(actionMargin) {
        return new Promise((resolve, reject) => {
          actionMargin.setCallback(this, function(response) {
            const statusVolume = response.getState();
            if (statusVolume === 'SUCCESS') {
              const returnValue = response.getReturnValue();
              resolve(returnValue);
            } else if (statusVolume === 'ERROR') {
              var errorsVolume = response.getError();
              if (errorsVolume) {
                if (errorsVolume[0] && errorsVolume[0].message) {
                  reject(Error('Error message: ' + errorsVolume[0].message));
                }
              } else {
                reject(Error('Unknown error'));
              }
            }
          });
          $A.enqueueAction(actionMargin);
        });
      },
      handleCatalog : function(cmp ,event, helper) {
        var catalog = event.getParam('catalog');
        
      }
})