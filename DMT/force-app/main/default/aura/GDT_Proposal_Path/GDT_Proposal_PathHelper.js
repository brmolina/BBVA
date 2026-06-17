({
    updateFieldValueHelper: function (component,event, fieldName, value) {
        let fieldValuesMap = component.get("v.fieldValuesMap");  
        fieldValuesMap[fieldName] = value;
        component.set("v.fieldValuesMap", fieldValuesMap);  
        console.log('se actualiza', fieldValuesMap);
        let validationResult = this.validateRequireFields(component);
         if (!validationResult.valid) {
             fieldValuesMap["isFormCompleted"] = false;
         }else{
             fieldValuesMap["isFormCompleted"] = true;
         }
        fieldValuesMap.isEdit = 'yes';
        const appEvent = $A.get("e.arce:Arc_Gen_Initial_Buttons_Prop_EVT");
        if (appEvent) {
        	let mapChildInfo = component.get("v.fieldValuesMap");
        	appEvent.setParams({ mapChildInfo });
        	appEvent.fire();
        }
    },
    
    handleStateSubstate: function(component, helper, state, substate, fieldValuesMap) {
    var action = state + ':' + substate;

    switch (action) {
      case '1:1':
        helper.handleState1Substate1(component, fieldValuesMap);
        return Promise.resolve();
      case '1:2':
        helper.handleState1Substate2(component, fieldValuesMap);
        return Promise.resolve();
      case '1:3':
        helper.getRegionHelperPromise(component)
          .then(function() {
            helper.handleState1Substate3Promise(component, fieldValuesMap);
          });
        return Promise.resolve();
      case '2:4':
        helper.getGeographyCommitteeHelperPromise(component)
          .then(function() {
            helper.handleState2Substate4Promise(component, fieldValuesMap);
          });
        return Promise.resolve();
      case '2:5':
        return helper.getCommitteeComboHelperPromise(component);
      case '2:6':
        helper.handleState2Substate6(component, fieldValuesMap);
        return Promise.resolve();
      case '3:7':
        helper.handleState3Substate7(component, fieldValuesMap);
        return Promise.resolve();
      case '3:8':
        helper.handleState3Substate8(component, fieldValuesMap);
        return Promise.resolve();
      default:
        return Promise.resolve();
    }
  },

  handleState1Substate2: function(component, fieldValuesMap) {
    component.set('v.selectedValueBs', fieldValuesMap.BusinessSanction || '');
    let bsanction = component.get('v.selectedValueBs');
    component.set('v.selectedValueBs', bsanction);
    if (bsanction === 'IH' || bsanction === 'FRAC') {
      component.set('v.showQuest2', true);
    } else {
      component.set('v.showQuest3', true);
    }
  },

  handleState1Substate1: function(component, fieldValuesMap) {
    if (fieldValuesMap.isCibGroup === 'yes') {
      component.set('v.showComboBox6', true);
      if (fieldValuesMap.GCRMCProgram === 'no') {
        component.set('v.showComboBox7', true);
        if (fieldValuesMap.CGCCProgram === 'yes') {
          component.set('v.showComboBox8', true);
        }
      }
      fieldValuesMap.stageToUpdate = '1';
      fieldValuesMap.statusToUpdate = '2';
    } else {
      component.set('v.showComboBox7', false);
      fieldValuesMap.stageToUpdate = '1';
      fieldValuesMap.statusToUpdate = '3';
      delete fieldValuesMap.GCRMCProgram;
      delete fieldValuesMap.CGCCProgram;
      delete fieldValuesMap.ComercialCriteria;
      delete fieldValuesMap.BusinessSanction;
    }
    component.set('v.fieldValuesMap', fieldValuesMap);
    component.set('v.selectedValue', '');
  },

  handleState1Substate3Promise: function(component, fieldValuesMap) {
    return new Promise(function(resolve, reject) {
      var geographicalArea = fieldValuesMap.geographicalArea;
      if (!geographicalArea) {
        resolve();
        return;
      }

      var action = component.get('c.getLevelAmbit');
      action.setParams({ filterValue: geographicalArea });
      action.setCallback(this, function(response) {
        var state = response.getState();
        if (state === 'SUCCESS') {
          component.set('v.levelOpt', response.getReturnValue());
          var ambit = fieldValuesMap.ambit;
          if (ambit) {
            var actionDesc = component.get('c.getDescriptionAmbit');
            actionDesc.setParams({
              filterValue1: ambit,
              filterValue2: geographicalArea
            });
            actionDesc.setCallback(this, function(responseDesc) {
              var stateDesc = responseDesc.getState();
              if (stateDesc === 'SUCCESS') {
                component.set('v.descriptionOpt', responseDesc.getReturnValue());
                resolve();
              } else {
                reject(responseDesc.getError());
              }
            });
            $A.enqueueAction(actionDesc);
          } else {
            resolve();
          }
        } else {
          reject(response.getError());
        }
      });
      $A.enqueueAction(action);
    });
  },

  handleState2Substate4Promise: function(component, fieldValuesMap) {
    return new Promise(function(resolve, reject) {
      var localApprGeo = fieldValuesMap.localApprGeo;
      if (!localApprGeo) {
        resolve();
        return;
      }

      var action = component.get('c.getCommittee');
      action.setParams({ filterValue: localApprGeo });
      action.setCallback(this, function(response) {
        var state = response.getState();
        if (state === 'SUCCESS') {
          component.set('v.committeeOpt', response.getReturnValue());
          resolve();
        } else {
          reject(response.getError());
        }
      });
      $A.enqueueAction(action);
    });
  },
  handleState2Substate6: function(component, fieldValuesMap) {
    const holdingApproval = fieldValuesMap.HoldingApproval;
    if (holdingApproval === 'yes') {
      component.set('v.showQuestion2', true);
      const holdingCommit = fieldValuesMap.HoldingCommit;
      if (holdingCommit === 'CGCC') {
        component.set('v.selectedValueContrast', 'CIB');
      }
    }
  },

  handleState3Substate7: function(component, fieldValuesMap) {
    // No hay lógica adicional por ahora, pero se mantiene por consistencia
  },

  handleState3Substate8: function(component, fieldValuesMap) {
    component.set('v.selectedValAppCommittee', fieldValuesMap.HoldingCommit || '');
  },
    
    getRegionHelperPromise: function(component) {
    return new Promise(function(resolve, reject) {
      var action = component.get('c.getRegionAmbit');
      action.setCallback(this, function(response) {
        var state = response.getState();
        if (state === 'SUCCESS') {
          component.set('v.regionOpt', response.getReturnValue());
          resolve();
        } else {
          console.error('Error al obtener opciones:', response.getError());
          reject(response.getError());
        }
      });
      $A.enqueueAction(action);
        }); 
    },
    
    getGeographyCommitteeHelper: function(component,event) {
        var actionGeo = component.get("c.getGeographyCommittee");  
        actionGeo.setCallback(this, function(response) {
             var state = response.getState();  
             if (state === "SUCCESS") {
                 console.log("entro en la clase");
                 component.set("v.geographyOpt", response.getReturnValue());
             } else {
                 console.error("Error al obtener opciones:", response.getError());
             }
        });
        $A.enqueueAction(actionGeo);
    },

    getGeographyCommitteeHelperPromise: function(component) {
        return new Promise(function(resolve, reject) {
        var actionGeo = component.get('c.getGeographyCommittee');
        actionGeo.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
            component.set('v.geographyOpt', response.getReturnValue());
            resolve();
            } else {
            console.error('Error al obtener opciones:', response.getError());
            reject(response.getError());
            }
        });
        $A.enqueueAction(actionGeo);
        });
    },
    
    getCommitteeComboHelper: function(component,event) {
        let fieldValuesMap = component.get("v.fieldValuesMap") || {};
        component.set("v.selectedValueCommittee", fieldValuesMap['localApprComit'] || '');
        let value = component.get("v.selectedValueCommittee"); 
        let action = component.get("c.getCommitteeCombo");
        action.setParams({ filterValue: value });
        action.setCallback(this, function(response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                let options = response.getReturnValue();
                component.set("v.committeeOpt", options);
            } else {
                console.error("Error al obtener opciones:", response.getError());
            }
        });
    
        $A.enqueueAction(action);
    },

    getCommitteeComboHelperPromise: function(component) {
        return new Promise(function(resolve, reject) {
        var fieldValuesMap = component.get('v.fieldValuesMap') || {};
        component.set('v.selectedValueCommittee', fieldValuesMap.localApprComit || '');
        var value = component.get('v.selectedValueCommittee');
        var action = component.get('c.getCommitteeCombo');
        action.setParams({ filterValue: value });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
            component.set('v.committeeOpt', response.getReturnValue());
            resolve();
            } else {
            console.error('Error al obtener opciones:', response.getError());
            reject(response.getError());
            }
        });
        $A.enqueueAction(action);
        });
    },
    
    geographyChangeHelper: function(component,event) {
        let geographyFldName = event.getSource().get('v.name');
        let  geographyValue = event.getSource().get('v.value');
        this.updateFieldValueHelper(component, event, geographyFldName, geographyValue);
        let action = component.get("c.getCommittee");
        action.setParams({ filterValue: geographyValue });
        action.setCallback(this, function(response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                let options = response.getReturnValue();
                component.set("v.committeeOpt", options);
            } else {
                console.error("Error al obtener opciones:", response.getError());
            }
        });

        $A.enqueueAction(action);
    },
    
    regionChangeHelper: function(component,event) {
        component.set('v.descriptionOpt', []);
        let regionFldName = event.getSource().get('v.name');
        let regionValue = event.getSource().get('v.value');
        this.updateFieldValueHelper(component, event, regionFldName, regionValue);
        let action = component.get("c.getLevelAmbit");
        action.setParams({ filterValue: regionValue });
        action.setCallback(this, function(response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                let options = response.getReturnValue();
                component.set("v.levelOpt", options);
            } else {
                console.error("Error al obtener opciones:", response.getError());
            }
        });

        $A.enqueueAction(action);
    },
    
    levelChangeHelper: function(component,event) {
        let levelChangeValue = event.getSource().get('v.value');
        let levelChangeFldName = event.getSource().get('v.name');
        this.updateFieldValueHelper(component, event, levelChangeFldName, levelChangeValue);
        let fieldValuesMap = component.get("v.fieldValuesMap"); 
        let value2 = fieldValuesMap["geographicalArea"];       
        let action = component.get("c.getDescriptionAmbit");       
        action.setParams({ 
            filterValue1: levelChangeValue,
            filterValue2: value2
        });
        action.setCallback(this, function(response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                let options = response.getReturnValue();
                component.set("v.descriptionOpt", options);
            } else {
                console.error("Error al obtener opciones:", response.getError());
            }
        });
        $A.enqueueAction(action);        
        component.set("v.fieldValuesMap", fieldValuesMap); 
    },
    
    validateRequireFields: function(component) {
        let state = component.get("v.state");
        let substate = component.get("v.substate");
        let fieldValuesMap = component.get("v.fieldValuesMap"); 
        
    
        let stateField = {
            "1:1": ['isCibGroup'],
            
            "1:2": ['BADecision', 'BusinessSanctionDate'],
            
            "1:3": ['geographicalArea', 'ambit', 'dmt'],
            
            "2:4": ['localApprGeo', 'localApprComit'],
            
            "2:5": ['Decision', 'dateSaction'],
            
            "2:6": ['HoldingApproval'],
            
            "3:7": ['HoldingCommit'],

            "3:8": ['DecisionHolding', 'HoldingDateFinalize']
        };
        
        if(substate === "1"){
            let isCibGroup = fieldValuesMap["isCibGroup"];
            if(isCibGroup && isCibGroup !== "no"){
                stateField["1:1"] = ['isCibGroup', 'BusinessSanction'];
            }
        }
        
        if(substate === "2"){
            let bsSanction = fieldValuesMap["BusinessSanction"];
            if(bsSanction && bsSanction !== "GB"){
                stateField["1:2"] = ['IHApproval', 'BusinessSanctionDate'];
            }
        }
        
        if(substate === "6"){
            let hApproval = fieldValuesMap["HoldingApproval"];
            if(hApproval && hApproval !== "no"){
                stateField["2:6"] = ['HoldingApproval', 'HoldingCommit', 'ContrastPropose'];
            }
        }
    
        let fieldKey = `${state}:${substate}`;
        let validateField = stateField[fieldKey] || [];
    
        let leftField = [];
    
        validateField.forEach(fieldName => {
            let valor = fieldValuesMap[fieldName];  
            if (!valor || (typeof valor === 'string' && valor.trim() === '')) {
                leftField.push(fieldName);
            }
        });
    
        return {
            valid: leftField.length === 0, 
            leftField: leftField  
        };
    },
 
 	showToast: function(title, message, typeError) {
        let toastEvent = $A.get("e.force:showToast");
        if (toastEvent) {
            toastEvent.setParams({
                title: title,
                message: message,
                type: typeError, 
                mode: 'dismissible' 
            });
            toastEvent.fire();
        } else {
            alert(`${title}: ${message}`);
        }
    },

    fireInitialEvent: function(component, helper) {
        const fieldValuesMap = component.get('v.fieldValuesMap');
        const validationResult = helper.validateRequireFields(component);

        if (!validationResult.valid) {
        fieldValuesMap.isFormCompleted = false;
        } else {
        fieldValuesMap.isFormCompleted = true;
        }
        fieldValuesMap.isEdit = 'no';
        component.set('v.fieldValuesMap', fieldValuesMap);

        const appEvent = $A.get('e.arce:Arc_Gen_Initial_Buttons_Prop_EVT');
        if (appEvent) {
        const mapChildInfo = component.get('v.fieldValuesMap');
        appEvent.setParams({ mapChildInfo });
        appEvent.fire();
        }
    }
    
});