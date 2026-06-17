({
    doInit: function(component, event, helper) {
        let fieldValuesMap = component.get("v.fieldValuesMap") || {};
        component.set("v.state", fieldValuesMap['stage'] || ''); 
        component.set("v.substate", fieldValuesMap['status'] || '');
        let state = component.get("v.state"); 
    	let substate = component.get("v.substate"); 
        var action = component.get("c.getRegionAmbit");

        // Setear valores iniciales para campos disabled que usan selectedValue
        if (fieldValuesMap.BusinessSanction) {
        component.set('v.selectedValue', fieldValuesMap.BusinessSanction);
        }
        if (fieldValuesMap.ContrastPropose) {
        component.set('v.selectedValueContrast', fieldValuesMap.ContrastPropose);
        }

        helper.handleStateSubstate(component, helper, state, substate, fieldValuesMap)
        .then(function() {
            return helper.fireInitialEvent(component, helper);
        })
        .catch(function(error) {
            console.error('Error initializing component:', error);
        });
    },
    
    updateFieldValue: function (component, event, helper) {
        let fieldName = event.getSource().get("v.name"); 
    	let value = event.getSource().get("v.value");
    	helper.updateFieldValueHelper(component, event, fieldName, value);
    },
    
    geographyChange: function (component, event, helper) {
        helper.geographyChangeHelper(component, event);
        let fieldValuesMap = component.get("v.fieldValuesMap"); 
        fieldValuesMap["stageToUpdate"] = "2";
        fieldValuesMap["statusToUpdate"] = "5";
        component.set("v.fieldValuesMap", fieldValuesMap);
    },
    
    
    regionChange: function (component, event, helper) {
        helper.regionChangeHelper(component, event);
    },
    
    levelChange: function (component, event, helper) {
        helper.levelChangeHelper(component, event);
    },

    handleCheckboxChange: function (component, event, helper) {
        let fieldName = "IsGlobalSectorialApprove";
        let fieldValue = event.getSource().get("v.checked");
        let fieldValuesMap = component.get("v.fieldValuesMap");
        fieldValuesMap[fieldName] = fieldValue;
        component.set("v.fieldValuesMap", fieldValuesMap);
    },
    
    validateContrastbyCommit: function (component, event, helper) {
        let fieldName = event.getSource().get("v.name"); 
    	let value = event.getSource().get("v.value");
        if(value === "CGCC"){
            component.set("v.selectedValueContrast", "CIB");
            component.set("v.isDisabled", true);
            let fieldValuesMap = component.get("v.fieldValuesMap");
            fieldValuesMap["ContrastPropose"] = "CIB";
            component.set("v.fieldValuesMap", fieldValuesMap);
        }else{
            let fieldValuesMap = component.get("v.fieldValuesMap");
            fieldValuesMap["ContrastPropose"] = "";
            component.set("v.fieldValuesMap", fieldValuesMap);
            component.set("v.isDisabled", false);
            component.set("v.selectedValueContrast", "");
        }
        helper.updateFieldValueHelper(component, event, fieldName, value);
    },
    
    handleHoldingApprovalChange: function (component, event, helper) {
        let fieldName = event.getSource().get("v.name"); 
    	let value = event.getSource().get("v.value");
        let fieldValuesMap = component.get("v.fieldValuesMap");
    	helper.updateFieldValueHelper(component, event, fieldName, value);
        let selectedValue = event.getSource().get("v.value");
        component.set("v.showQuestion2", selectedValue === "yes");
        fieldValuesMap["stageToUpdate"] = "3";
       	fieldValuesMap["statusToUpdate"] = "7";
        component.set("v.fieldValuesMap", fieldValuesMap);
        
        if (selectedValue !== "yes") {
            component.set("v.showQuestion2", false);
            fieldValuesMap["stageToUpdate"] = "4";
       		fieldValuesMap["statusToUpdate"] = "9";
            delete fieldValuesMap["HoldingCommit"];
            delete fieldValuesMap["ContrastPropose"];
            delete fieldValuesMap.DecisionHolding;
            delete fieldValuesMap.HoldingDateFinalize;
            component.set("v.fieldValuesMap", fieldValuesMap);
        }
        helper.updateFieldValueHelper(component, event, fieldName, value);
    },

    handleComboBox5Change: function (component, event, helper) {
        let fieldName = event.getSource().get("v.name"); 
    	let value = event.getSource().get("v.value");
        let fieldValuesMap = component.get("v.fieldValuesMap");
        let selectedValue = event.getSource().get("v.value");
        component.set("v.fieldValuesMap", fieldValuesMap);
        
        if (selectedValue === 'no') {
            component.set('v.showComboBox6', false);
            component.set("v.showComboBox7", false);
            component.set('v.showComboBox8', false);
            fieldValuesMap["stageToUpdate"] = "1";
        	fieldValuesMap["statusToUpdate"] = "3";
            delete fieldValuesMap["GCRMCProgram"];
            delete fieldValuesMap["CGCCProgram"];
            delete fieldValuesMap["ComercialCriteria"];
            delete fieldValuesMap["BusinessSanction"];
            delete fieldValuesMap.IHApproval;
            delete fieldValuesMap.BADecision;
            delete fieldValuesMap.BusinessSanctionDate;
            delete fieldValuesMap.BusinessSanctionDetails;
            component.set("v.fieldValuesMap", fieldValuesMap);
            component.set("v.selectedValue", "");
        } else {
            component.set('v.showComboBox6', true);
        }
        helper.updateFieldValueHelper(component, event, fieldName, value);
    },

    handleComboBox6Change: function (component, event, helper) {
		let fieldValuesMap = component.get("v.fieldValuesMap");
        let fieldName = event.getSource().get("v.name"); 
        let selectedValue = event.getSource().get("v.value");
        component.set("v.showComboBox7", selectedValue === "no");
        fieldValuesMap["BusinessSanction"] = "";
        component.set("v.fieldValuesMap", fieldValuesMap);
        component.set("v.selectedValue", "");

        if (selectedValue === 'yes') {
            component.set("v.selectedValue", "FRAC");
            fieldValuesMap["BusinessSanction"] = "FRAC";
            fieldValuesMap["stageToUpdate"] = "1";
        	fieldValuesMap["statusToUpdate"] = "2";
            delete fieldValuesMap["CGCCProgram"];
            delete fieldValuesMap["ComercialCriteria"];
            component.set('v.showComboBox7', false);
            component.set('v.showComboBox8', false);
            component.set('v.fieldValuesMap', fieldValuesMap);
            } else {
            delete fieldValuesMap.CGCCProgram;
            delete fieldValuesMap.ComercialCriteria;
            component.set('v.showComboBox8', false);
            component.set("v.fieldValuesMap", fieldValuesMap);
        }
        helper.updateFieldValueHelper(component, event, fieldName, selectedValue);
    },
    
    handleComboBox7Change: function (component, event, helper) {
        let fieldName = event.getSource().get("v.name"); 
        let selectedValue = event.getSource().get("v.value");
        let fieldValuesMap = component.get("v.fieldValuesMap");
        component.set("v.showComboBox8", selectedValue === "yes");
        component.set("v.selectedValue", "");
        fieldValuesMap["BusinessSanction"] = "";
        component.set("v.fieldValuesMap", fieldValuesMap);

        if (selectedValue !== "yes") {
            component.set("v.selectedValue", "GB");
            fieldValuesMap["BusinessSanction"] = "GB";
            fieldValuesMap["stageToUpdate"] = "1";
        	fieldValuesMap["statusToUpdate"] = "2";
            delete fieldValuesMap["ComercialCriteria"];
            component.set("v.fieldValuesMap", fieldValuesMap);
        }
        helper.updateFieldValueHelper(component, event, fieldName, selectedValue);
    },
    
    handleComboBox8Change: function (component, event, helper) {
        let fieldName = event.getSource().get("v.name"); 
        let selectedValue = event.getSource().get("v.value");
        let fieldValuesMap = component.get("v.fieldValuesMap");
        component.set("v.selectedValue", "IH");
        fieldValuesMap["BusinessSanction"] = "IH";
        fieldValuesMap["stageToUpdate"] = "1";
       	fieldValuesMap["statusToUpdate"] = "2";
        component.set("v.fieldValuesMap", fieldValuesMap);

        if (selectedValue !== "yes") {
            component.set("v.selectedValue", "GB");
            fieldValuesMap["BusinessSanction"] = "GB";
            fieldValuesMap["stageToUpdate"] = "1";
       		fieldValuesMap["statusToUpdate"] = "2";
			helper.updateFieldValueHelper(component, event, fieldName, selectedValue);
            component.set("v.fieldValuesMap", fieldValuesMap);
        }
        helper.updateFieldValueHelper(component, event, fieldName, selectedValue);
    },
    
    validateSecState: function (component, event, helper) {
        let fieldName = event.getSource().get("v.name"); 
    	let value = event.getSource().get("v.value");
    	helper.updateFieldValueHelper(component, event, fieldName, value);
        let fieldValuesMap = component.get("v.fieldValuesMap"); 
        fieldValuesMap["stageToUpdate"] = "1";
        fieldValuesMap["statusToUpdate"] = "3";
        component.set("v.fieldValuesMap", fieldValuesMap); 
    },
    
    validateThirdState: function (component, event, helper) {
        let fieldName = event.getSource().get("v.name"); 
    	let value = event.getSource().get("v.value");
    	helper.updateFieldValueHelper(component, event, fieldName, value);
        let fieldValuesMap = component.get("v.fieldValuesMap"); 
        fieldValuesMap["stageToUpdate"] = "2";
        fieldValuesMap["statusToUpdate"] = "4";
        component.set("v.fieldValuesMap", fieldValuesMap); 
    },
    
    validateFithState: function (component, event, helper) {
        let fieldName = event.getSource().get("v.name"); 
    	let value = event.getSource().get("v.value");
    	helper.updateFieldValueHelper(component, event, fieldName, value);
        let fieldValuesMap = component.get("v.fieldValuesMap"); 
        fieldValuesMap["stageToUpdate"] = "2";
        fieldValuesMap["statusToUpdate"] = "6";
        component.set("v.fieldValuesMap", fieldValuesMap); 
    },
    
    validateSixthState: function (component, event, helper) {
        let fieldName = event.getSource().get("v.name"); 
    	let value = event.getSource().get("v.value");
    	helper.updateFieldValueHelper(component, event, fieldName, value);
        let fieldValuesMap = component.get("v.fieldValuesMap");
        
        if (value !== "yes") {
            fieldValuesMap["stageToUpdate"] = "4";
        	fieldValuesMap["statusToUpdate"] = "9";
            component.set("v.fieldValuesMap", fieldValuesMap);
        }else{
            fieldValuesMap["stageToUpdate"] = "3";
        	fieldValuesMap["statusToUpdate"] = "7";
            component.set("v.fieldValuesMap", fieldValuesMap);
        }
    },

    validateSeventhState: function (component, event, helper) {
        let fieldName = event.getSource().get("v.name"); 
    	let value = event.getSource().get("v.value");
    	helper.updateFieldValueHelper(component, event, fieldName, value);
        let fieldValuesMap = component.get("v.fieldValuesMap"); 
        fieldValuesMap["stageToUpdate"] = "3";
        fieldValuesMap["statusToUpdate"] = "8";
        component.set("v.fieldValuesMap", fieldValuesMap); 
    },
    
    validateEighthState: function (component, event, helper) {
        let fieldName = event.getSource().get("v.name"); 
    	let value = event.getSource().get("v.value");
    	helper.updateFieldValueHelper(component, event, fieldName, value);
        let fieldValuesMap = component.get("v.fieldValuesMap"); 
        fieldValuesMap["stageToUpdate"] = "4";
        fieldValuesMap["statusToUpdate"] = "9";
        component.set("v.fieldValuesMap", fieldValuesMap); 
    },
    
    //fireChildEvent: function(component, event, helper) {
    // let validationResult = helper.validateRequireFields(component);
    //  if (!validationResult.valid) {
    //      helper.showToast('Error', 'Complete all formulary', 'error');
    //      return;
    //  }else{
    //      const appEvent = $A.get("e.arce:Arc_Gen_Initial_Buttons_Prop_EVT");
    //      if (appEvent) {
    //        let mapChildInfo = component.get("v.fieldValuesMap");
    //        appEvent.setParams({ mapChildInfo });
    //        appEvent.fire();
    //      }
    //  }
      //component.set("v.isDisabled", true);
    //},
                                
    updateCharCount: function(component, event, helper) {
        const field = event.getSource().get("v.name");
        const value = event.getSource().get("v.value") || "";
        let map = component.get("v.charLengthsMap");
        map[field] = value.length;
        component.set("v.charLengthsMap", map);
    },
                            
    
});