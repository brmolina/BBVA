({
  doInit: function(component, event, helper) {
    var action = component.get("c.completeForm");
    action.setParams({
      'objName': component.get("v.objectName"),
      'fieldsNamePar': component.get("v.fieldsParam")
    })
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === "SUCCESS") {
        var elements = response.getReturnValue();
        var records = [];
        for (var i = 0; i < elements.length; i = i + 1) {
          var record = {};
          var source = elements[i];
          record.fapiname = source.fapiname;
          record.value = "";
          records.push(record);
        }
        component.set("v.fields", records);
      }
    });
    $A.enqueueAction(action);

    var action2 = component.get("c.completeForm");
    action2.setParams({
      'objName': component.get("v.objectName"),
      'fieldsNamePar': component.get("v.fields2Param")
    })
    action2.setCallback(this, function(response) {
      var state = response.getState();
      if (state === "SUCCESS") {
        var elements2 = response.getReturnValue();
        var records2 = [];
        for (var i = 0; i < elements2.length; i = i + 1) {
          var record2 = {};
          var source = elements2[i];
          record2.fapiname = source.fapiname;
          record2.value = "";
          records2.push(record2);
        }
        component.set("v.fields2", records2);
      }
    });
    $A.enqueueAction(action2);
  },

  openModal: function(component, event, helper) {
    component.set('v.popUp', true);
    var action = component.get("c.checkPerimeter");

    action.setCallback(this, function(response) {
      if(response.getState() === "SUCCESS") {
        var ret = response.getReturnValue();
        console.log('::::::::::ret: ' + ret);
        if(ret === 1) {
          component.set('v.isOpen', true);
        } else if(ret === 2) {
          component.set('v.isLoading', true);
          component.set("v.showSpinner", false);
        } else if(ret === 3) {
          var action2 = component.get("c.getSelectOptions");
          action2.setParams({
            'objName': component.get("v.objectName"),
            'fieldsNamePar': component.get("v.field3Param")
          })
          action2.setCallback(this, function(response) {
            if(response.getState() === "SUCCESS") {
              console.log(response.getReturnValue());
              console.log('response lenght: ' + response.getReturnValue().length);
              var opts = [];
              var allValues = response.getReturnValue();
              for(var key in allValues) {
                  console.log('key: ' + key);
                  console.log('key[i]: ' + allValues[key]);
                  opts.push({
                      value: key,
                      label: allValues[key]
                  });
              }
              component.set('v.field3Options', opts);
              component.set('v.isOpen4', true);
            }
          });
          $A.enqueueAction(action2);
        }
      }
    });
    $A.enqueueAction(action);
  },

  closeModal: function(component, event, helper) {
    component.set("v.popUp", false);
    component.set('v.isOpen', false);
    component.set('v.isOpen2', false);
    component.set('v.isOpen3', false);
    component.set('v.isOpen4', false);
    component.set('v.isOpen5', false);
    component.set('v.isLoading', false);
    $A.get('e.force:refreshView').fire();
  },

  next: function(component, event, helper) {
    component.set("v.showSpinner", true);
    var action = component.get("c.getData");
    action.setParams({
      'dataSet': JSON.stringify(component.get("v.fields")),
      'oFilter': component.get("v.objectNameFilter"),
      'fFilter': component.get("v.fieldsParamFilter"),
      'rtFilter': component.get("v.recordTypesFilter"),
      'otherFilter': component.get("v.otherFilter")
    })
    action.setCallback(this, function(response) {
      var state = response.getState();
      if (state === "SUCCESS") {
        var data = response.getReturnValue();
        if(data !== null && data !== '') {
          var dataObj = JSON.parse(JSON.parse(JSON.stringify(data).split('items').join('_children')));
          component.set('v.gridData', dataObj);
          var cadena = data;
          var expresion = ".*\"id\" : \".{18}\".*";
          var test = cadena.match(expresion);
          console.log('Valor de test: ' +test);
          //component.set('v.gridExpandedRows', list); Para expandir los registros descomentar esta linea
        }
        component.set('v.selectedIds', test);
        component.set("v.showSpinner", false);
      }
    });
    $A.enqueueAction(action);
    helper.printTreeGrid(component, event, helper);
    component.set("v.isOpen", false);
    component.set("v.isOpen2", true);
    component.set('v.gridColumns', [{
      label: 'Name',
      fieldName: 'name',
      type: 'text'
    }]);
  },

  handleLoad: function(component, event, helper) {
    component.set("v.showSpinner", false);
  },

  back: function(component, event, helper) {
    component.set("v.isOpen", true);
    component.set("v.isOpen2", false);
  },

  back2: function(component, event, helper) {
    component.set("v.isOpen2", true);
    component.set("v.isOpen3", false);
  },

  back3: function(component, event, helper) {
    component.set("v.isOpen", true);
    component.set("v.isOpen4", false);
  },

  back4: function(component, event, helper) {
    component.set("v.isOpen4", true);
    component.set("v.isOpen5", false);
  },

  next2: function(component, event, helper) {
    component.set("v.isOpen2", false);
    component.set("v.isOpen3", true);
  },

  next3: function(component, event, helper) {
    component.set("v.showSpinner", true);
    var action = component.get("c.getPerimeter");
    console.log("::::::::::selectedRecords: " + component.get("v.selectedRecords"));
    action.setParams({
      'dataSet': JSON.stringify(component.get("v.fields")),
      'accSelect': JSON.stringify(component.get("v.selectedRecords"))
    });
    action.setCallback(this, function(response) {
      if(response.getState() === "SUCCESS") {
        component.set("v.showSpinner", false);
        var action3 = component.get("c.getSelectOptions");
        action3.setParams({
          'objName': component.get("v.objectName"),
          'fieldsNamePar': component.get("v.field3Param")
        })
        action3.setCallback(this, function(response) {
          if(response.getState() === "SUCCESS") {
            console.log(response.getReturnValue());
            console.log('response lenght: ' + response.getReturnValue().length);
            var opts = [];
            var allValues2 = response.getReturnValue();
            for(var key in allValues2) {
              console.log('key: ' + key);
              console.log('key[i]: ' + allValues2[key]);
              opts.push({
                value: key,
                label: allValues2[key]
              });
            }
            component.set('v.field3Options', opts);
            component.set('v.isLoading', true);
          }
        });
        $A.enqueueAction(action3);
      }
    });
    $A.enqueueAction(action);

    component.set("v.isOpen3", false);
  },

  next4: function(component, event, helper) {
    var action = component.get("c.checkValidWave");
    action.setParams({
      'dataSet2': JSON.stringify(component.get("v.fields2")),
      'dataSet3list': component.get("v.field3Items")
    });
    action.setCallback(this, function(response) {
      console.log('response.getState(): ' + response.getState());
      console.log('response.getReturnValue(): ' + response.getReturnValue());
      if(response.getState() === "SUCCESS" && response.getReturnValue() === 'OK') {
        component.set("v.showSpinner", true);
        var action2 = component.get("c.getWaves");
        action2.setParams({
          'dataSet': JSON.stringify(component.get("v.fields")),
          'dataSet2': JSON.stringify(component.get("v.fields2")),
          'dataSet3list': component.get("v.field3Items")
        });
        action2.setCallback(this, function(response) {
          var state = response.getState();
          console.log('state: ' + state);
          if(component.isValid() && state === "SUCCESS") {
            component.set("v.showSpinner", false);
            component.set("v.nocountry", false);
          }
        });
        $A.enqueueAction(action2);
        component.set("v.isOpen4", false);
        component.set("v.isOpen5", true);
      } else if(response.getReturnValue() === 'COUNTRY_KO') {
        component.set("v.nocountry", true);
      }
    });
    event.preventDefault();
    $A.enqueueAction(action);
    component.set("v.showSpinner", false);
  },

  getSelectedName: function(component, event, helper) {
    component.set("v.selectedRecords", event.getParam('selectedRows'));
    console.log("::::::::::gridData: " + component.get("v.gridData"));
  },
})