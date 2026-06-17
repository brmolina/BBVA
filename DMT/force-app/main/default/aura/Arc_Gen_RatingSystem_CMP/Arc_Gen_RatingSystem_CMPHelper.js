/* eslint-disable camelcase */
({
  getAuraIds: function() {
    return [
      'entityType',
      'ifisModel',
      'arce__unit_booking__c',
      'arce__level_Shell__c',
      'arce__group_corporative__c',
      'arce__explicit_guarantee__c',
      'arce__filial_Core__c',
      'arce__captive_nbf__c',
      'arce__group_treasury_subsidiary__c',
      'arce__legal_EEFF__c',
      'arce__matrizIg__c',
      'arce__common_ops_no_ffss__c',
    ];
  },
  getCurrentValues: function(component, auraIds) {
    const values = {};
    auraIds.forEach((auraId) => {
      const componentCmp = component.find(auraId);
      let valueForId = null;
      if (componentCmp) {
        if (componentCmp.get('v.type') === 'checkbox') {
          const checkedValue = componentCmp.get('v.checked');
          valueForId = checkedValue === undefined || checkedValue === null ? null : checkedValue.toString();
        } else {
          valueForId = componentCmp.get('v.value');
        }
      }
      values[auraId] = valueForId;
    });

    return values;
  },
  parseBooleanValue: function(value) {
    if (typeof value === 'boolean') {
      return value;
    }
    if (typeof value === 'string') {
      return value.toLowerCase() === 'true';
    }
    return Boolean(value);
  },
  setProspectValues: function(component, auraIds, helper) {
    const selectedCountry = component.get('v.selectedCountry');
    return {
      arce__captive_nbf__c: false,
      arce__common_ops_no_ffss__c: false,
      arce__explicit_guarantee__c: false,
      arce__filial_Core__c: false,
      arce__group_corporative__c: true,
      arce__group_treasury_subsidiary__c: false,
      arce__legal_EEFF__c: false,
      arce__level_Shell__c: false,
      arce__matrizIg__c: false,
      arce__unit_booking__c: selectedCountry,
      entityType: 'ifis',
      ifisModel: 'IFIS-RTC-FNB'
    };
  },
  getRatingSystemModel: function(component, event, helper, values) {
    const jsonData = component.get('v.conditionsJson');
    const visibilityMap = component.get('v.visibilityMap');
    let result = {};

    for (const data of jsonData) {
      const conditions = data.conditions;

      // Check if all conditions match and all values are visible
      const conditionsMatch = conditions.every((condition) => condition.value.split(';').includes(values[condition.key]));
      const valuesVisible = conditions.every((condition) => visibilityMap[condition.key]);

      // If true, set the model and ratingSystem
      if (conditionsMatch && valuesVisible) {
        const { arce__RAR_rating_tool_id__c, arce__rating_system__c } = data;
        const ratingSystemName = component.get('v.ratingSystemName');
        const selectedRatingSystem = ratingSystemName || arce__rating_system__c;
        if (helper.checkModelAvailability(component, arce__RAR_rating_tool_id__c)) {
          const parentSubsidiarySer = component.get('v.parentSubsidiarySer');
          const isCoreRelation = helper.parseBooleanValue(parentSubsidiarySer.isCoreRelation);
          result.formDataMap = helper.getFormDataMap(component, values, arce__RAR_rating_tool_id__c, selectedRatingSystem, visibilityMap, String(isCoreRelation));
        } else {
          result.warningMessage = $A.get('$Label.c.Arc_Gen_RTC_RSWarning');
        }
        return result;
      }
    }

    result.errorMessage = $A.get('$Label.c.Arc_Gen_RTC_RSError');
    return result;
  },
  getFormDataMap: function(component, values, arce__RAR_rating_tool_id__c, arce__rating_system__c, visibilityMap, arce__filial_Core__c) {
    const unwantedKeys = ['entityType', 'ifisModel', 'arce__filial_Core__c'];
    const formDataMap = {
      arce__RAR_rating_tool_id__c,
      arce__rating_system__c,
      arce__filial_Core__c
    };
    Object.entries(values).forEach(([key, value]) => {
      if (visibilityMap[key] && !unwantedKeys.includes(key)) {
        formDataMap[key] = value;
      }
    });

    return formDataMap;
  },
  setDefaults: function(component, event, helper) {
    const isProspect = component.get('v.isProspect');
    component.set('v.checkboxOptions', [
      { label: 'Yes', value: 'true' },
      { label: 'No', value: 'false' }
    ]);
    helper.setDefaultVisibility(component, helper);
    component.set('v.view', true);
  },

  // Set the default visibility flags
  setDefaultVisibility: function(component, helper) {
    const isProspect = component.get('v.isProspect');
    component.set('v.visibilityMap', {
      entityType: true,
      ifisModel: false,
      arce__unit_booking__c: false,
      arce__level_Shell__c: false,
      arce__group_corporative__c: false,
      arce__explicit_guarantee__c: false,
      arce__filial_Core__c: false,
      arce__captive_nbf__c: false,
      arce__group_treasury_subsidiary__c: false,
      arce__legal_EEFF__c: false,
      arce__matrizIg__c: false,
      arce__common_ops_no_ffss__c: false
    });
  },
  setConditionalVisibility: function(component, values) {
    this.setAttributeValues(component, values);
    const conditions = this.extractConditions(values);
    const visibilityMap = this.buildVisibilityMap(conditions);

    this.setVisibilityMapClass(component, visibilityMap);
    component.set('v.visibilityMap', visibilityMap);
  },
  setAttributeValues: function(component, values) {
    const { entityType } = values;

    component.set('v.entityTypeValue', entityType);
  },
  extractConditions: function(values) {
    const {
      entityType,
      ifisModel,
      arce__group_corporative__c,
      arce__explicit_guarantee__c,
      arce__filial_Core__c,
      arce__captive_nbf__c,
      arce__group_treasury_subsidiary__c,
      arce__legal_EEFF__c
    } = values;

    return {
      isEntityCheck: entityType === 'corporates' || entityType === 'ifis',
      isCorporates: entityType === 'corporates',
      isIfis: entityType === 'ifis',
      isIfisAlt: ifisModel === 'IFIS-RTC-ALT',
      isParentCheck: arce__group_corporative__c === 'true' || arce__group_corporative__c === 'false',
      isParent: arce__group_corporative__c === 'true',
      isExGuaranteeCheck: arce__explicit_guarantee__c === 'true' || arce__explicit_guarantee__c === 'false',
      isExGuarantee: arce__explicit_guarantee__c === 'true',
      isFilialCore: arce__filial_Core__c === 'true',
      isNbfCheck: arce__captive_nbf__c === 'true' || arce__captive_nbf__c === 'false',
      isNbf: arce__captive_nbf__c === 'true',
      isTreasStockHoldersCheck: arce__group_treasury_subsidiary__c === 'true' || arce__group_treasury_subsidiary__c === 'false',
      isTreasStockHolders: arce__group_treasury_subsidiary__c === 'true',
      isLegalFfss: arce__legal_EEFF__c === 'false'
    };
  },
  /* eslint-disable complexity */
  buildVisibilityMap: function(conditions) {
    const {
      isEntityCheck,
      isCorporates,
      isIfis,
      isIfisAlt,
      isParentCheck,
      isParent,
      isExGuaranteeCheck,
      isExGuarantee,
      isFilialCore,
      isNbfCheck,
      isNbf,
      isTreasStockHoldersCheck,
      isTreasStockHolders,
      isLegalFfss
    } = conditions;

    return {
      entityType: true,
      ifisModel: isIfis,
      arce__level_Shell__c: isCorporates,
      arce__group_corporative__c: isEntityCheck && (isCorporates || !isIfisAlt),
      arce__unit_booking__c: isCorporates,
      arce__explicit_guarantee__c: isCorporates && isParentCheck && !isParent,
      arce__filial_Core__c: isCorporates && isParentCheck && !isParent && isExGuaranteeCheck && !isExGuarantee,
      arce__captive_nbf__c: isCorporates && isFilialCore,
      arce__group_treasury_subsidiary__c: isCorporates && isNbfCheck && !isNbf,
      arce__legal_EEFF__c: isCorporates && isTreasStockHoldersCheck && !isTreasStockHolders,
      arce__matrizIg__c: isCorporates && isLegalFfss,
      arce__common_ops_no_ffss__c: isCorporates && isLegalFfss
    };
  },
  /* eslint-enable complexity */
  setVisibilityMapClass: function(component, visibilityMap) {
    const visibilityMapClass = {};
    Object.entries(visibilityMap).forEach(([key, value]) => {
      visibilityMapClass[key] = value ? 'slds-show' : 'slds-hide';
    });

    component.set('v.visibilityMapClass', visibilityMapClass);
  },
  setClientValues: function(component) {
    const selectedClient = component.get('v.selectedClient');
    if (selectedClient.length > 0) {
      const selectedText = $A.get('$Label.c.Arc_Gen_RatingSystemClient');
      const selectedCountry = component.get('v.selectedCountry');
      const formattedClient = selectedText + ': ' + selectedCountry + ' - ' + selectedClient[0].label;

      const selectedBankEntity = component.get('v.selectedBankEntity');

      const ifisInstTypeJson = component.get('v.ifisInstTypeJson');
      const ifisModelOptions = component.get('v.picklistValues').IFIS_ModelOptions;

      let institutionType = 'Institution Type: Not Informed';
      let modelName = ' | Not Informed';
      let modelCode = ' | Not Informed';

      if (selectedBankEntity && ifisInstTypeJson) {
        const instTypeModel = Object.keys(ifisInstTypeJson).find((key) =>
          ifisInstTypeJson[key].includes(selectedBankEntity)
        );

        if (instTypeModel) {
          institutionType = `Institution Type: ${instTypeModel}`;

          const modelOption = ifisModelOptions.find((option) => option.value === instTypeModel);
          if (modelOption) {
            modelName = ` | ${modelOption.label}`;
            modelCode = ` | ${selectedBankEntity}`;
          }
        }
      }

      const additionalInfo = `${institutionType}${modelName}${modelCode}`;
      component.set('v.formattedClient', formattedClient);
      component.set('v.additionalInfo', additionalInfo);

      this.setUnitBooking(component, selectedCountry);
    }
  },
  setUnitBooking: function(component, selectedCountry) {
    const formDataMap = component.get('v.formDataMap') || {};
    formDataMap.arce__unit_booking__c = selectedCountry;
    component.set('v.unitBookingValue', selectedCountry);
    component.set('v.formDataMap', formDataMap);
  },
  setIfisModelOption: function(component, event, helper) {
    const ifisModelOptions =
      component.get('v.picklistValues').IFIS_ModelOptions;
    const ifisInstTypeJson = component.get('v.ifisInstTypeJson');
    const selectedBankEntity = component.get('v.selectedBankEntity');

    // Path 1: If the selectedBankEntity is not informed
    if (!selectedBankEntity) {
      helper.fireEventWizard(component, 'showWarning', {
        warning: $A.get('$Label.c.Arc_Gen_RatingSystemEntNotInformed'),
      });
      return;
    }

    // Find the model that includes the selectedBankEntity
    const instTypeModel = Object.keys(ifisInstTypeJson).find((key) =>
      ifisInstTypeJson[key].includes(selectedBankEntity)
    );

    // Path 2: If the institution type is informed but the code is not found or invalid
    if (!instTypeModel) {
      helper.fireEventWizard(component, 'showWarning', {
        warning: $A.get('$Label.c.Arc_Gen_RatingSystemEntIncorrect'),
      });
      return;
    }

    // Find the corresponding model in the picklist values
    const ifisModelValue = ifisModelOptions.find(
      (option) => option.value === instTypeModel
    );

    // Path 3: If the model is found, set the value and disable the model selection
    if (ifisModelValue) {
      const ifisModel = component.find('ifisModel');
      if (ifisModel && ifisModel.isValid()) {
        ifisModel.set('v.value', ifisModelValue.value);
        const auraIds = helper.getAuraIds();
        helper.handleChangeForm(component, event, helper, auraIds);
      }
    }
  },
  callPersistenceMdt: function(component) {
    return new Promise($A.getCallback(function(resolve, reject) {
      const action = component.get('c.getPersistenceMdt');
      action.setParams({ forceException: false });
      action.setCallback(this, function(response) {
        const state = response.getState();
        if (state === 'SUCCESS') {
          const returnValue = JSON.parse(response.getReturnValue());
          const conditionsJson = returnValue.Model_RS_Conditions;
          const instTypeJson = returnValue.IFIS_InstitutionTypes;
          component.set('v.conditionsJson', JSON.parse(conditionsJson));
          component.set('v.ifisInstTypeJson', JSON.parse(instTypeJson));
          resolve();
        } else if (state === 'ERROR') {
          const errors = response.getError();
          reject(errors[0].message);
        }
      });
      $A.enqueueAction(action);
    }));
  },
  callArceConfigMdt: function(component, event, helper) {
    return new Promise($A.getCallback(function(resolve, reject) {
      const action = component.get('c.getArceConfigMdt');
      action.setParams({ forceException: false });
      action.setCallback(this, function(response) {
        const state = response.getState();
        if (state === 'SUCCESS') {
          const configMap = JSON.parse(response.getReturnValue());
          try {
            helper.handleArceConfigMdt(component, configMap);
            resolve();
          } catch (error) {
            reject(error);
          }
        } else if (state === 'ERROR') {
          const errors = response.getError();
          reject(errors[0].message);
        }
      });
      $A.enqueueAction(action);
    }));
  },
  handleArceConfigMdt: function(component, configMap) {
    const config = this.getInitialConfig(component);
    this.processModelConfigs(config, configMap);
    this.processPicklistConfigs(config, configMap);
    this.processRatingSystemConfigs(config, configMap);
    this.applyConfigToComponent(component, config);
  },
  getInitialConfig: function(component) {
    return {
      entityOptions: component.get('v.entityOptions') || [],
      picklistValues: component.get('v.picklistValues') || {},
      modelOptions: component.get('v.modelOptions') || {},
      ratingSystemBookCodes: component.get('v.ratingSystemBookCodes') || [],
      ratingSystemEnabled: component.get('v.ratingSystemEnabled') || false
    };
  },
  processModelConfigs: function(config, configMap) {
    if (configMap.IRPModelsAvailable) {
      config.modelOptions.corporates = configMap.IRPModelsAvailable;
      this.addEntityOption(config.entityOptions, 'corporates', 'Corporates');
    }
    if (configMap.IFIS_AvailableModels) {
      config.modelOptions.ifis = configMap.IFIS_AvailableModels;
      this.addEntityOption(config.entityOptions, 'ifis', 'IFIS');
    }
    if (configMap.ProspectModelsAvailable) {
      config.modelOptions.prospect = configMap.ProspectModelsAvailable;
    }
  },
  processPicklistConfigs: function(config, configMap) {
    if (configMap.UnitBookingOptions) {
      config.picklistValues.UnitBookingOptions = configMap.UnitBookingOptions;
    }
    if (configMap.IFIS_ModelOptions) {
      config.picklistValues.IFIS_ModelOptions = configMap.IFIS_ModelOptions;
    }
  },
  processRatingSystemConfigs: function(config, configMap) {
    if (configMap.UnitBookingRS) {
      config.ratingSystemBookCodes = configMap.UnitBookingRS;
    }
    if (configMap.EnableRatingSystem && configMap.EnableRatingSystem.length > 0) {
      config.ratingSystemEnabled = configMap.EnableRatingSystem[0].value === 'true';
    }
  },
  addEntityOption: function(entityOptions, value, label) {
    if (!entityOptions.some((option) => option.value === value)) {
      entityOptions.push({ label: label, value: value });
    }
  },
  applyConfigToComponent: function(component, config) {
    component.set('v.entityOptions', config.entityOptions);
    component.set('v.picklistValues', config.picklistValues);
    component.set('v.modelOptions', config.modelOptions);
    component.set('v.ratingSystemEnabled', config.ratingSystemEnabled);
    component.set('v.ratingSystemBookCodes', config.ratingSystemBookCodes);
  },
  handleChangeForm: function(component, event, helper, auraIds) {
    const values = helper.getCurrentValues(component, auraIds);
    helper.setConditionalVisibility(component, values);

    const completionCheck = helper.hasMoreThanOneValue(values) ? helper.checkCompletion(component, auraIds) : false;
    const { formDataMap, errorMessage, warningMessage } = completionCheck ? helper.getRatingSystemModel(component, event, helper, values) : {};

    helper.fireEventWizard(component, 'ratingSystemChanged', { formDataMap: formDataMap || {}, error: errorMessage || null, warning: warningMessage || null });
  },
  checkModelAvailability: function(component, model) {
    const isProspect = component.get('v.isProspect');
    const modelOptions = component.get('v.modelOptions');

    if (isProspect) {
      delete modelOptions.ifis;
      delete modelOptions.corporates;
    } else {
      delete modelOptions.prospect;
    }
    for (const optionList of Object.values(modelOptions)) {
      const foundOption = optionList.find((option) => option.value === model);
      if (foundOption) {
        return foundOption;
      }
    }
    return null;
  },
  checkCompletion: function(component, auraIds) {
    const isProspect = component.get('v.isProspect');
    const visibilityMap = component.get('v.visibilityMap');
    for (const auraId of auraIds) {
      const componentCmp = component.find(auraId);
      if (componentCmp && visibilityMap[auraId] && componentCmp.get('v.required')) {
        if (componentCmp.get('v.type') === 'checkbox') {
          if (!componentCmp.get('v.checked')) {
            return false;
          }
        } else if (!componentCmp.get('v.value')) {
          return false;
        }
      }
    }
    return true;
  },
  hasRSEnabledChange: function(component, eventSource) {
    const allowedCountries = this.getAllowedCountries(component);
    const eventSourceValue = eventSource ? eventSource.get('v.value') : null;
    const eventSourceId = eventSource ? eventSource.getLocalId() : null;

    return component.get('v.ratingSystemEnabled') &&
          eventSourceId === 'arce__unit_booking__c' &&
          allowedCountries.has(eventSourceValue);
  },
  hasMoreThanOneValue: function(values) {
    return Object.values(values).filter((value) => value).length > 1;
  },
  applyParentSubsidiaryDefaults: function(component, event, helper) {
    const parentSubsidiarySer = component.get('v.parentSubsidiarySer');

    if (!parentSubsidiarySer || Object.keys(parentSubsidiarySer).length === 0) {
      component.set('v.groupCorporateDisabled', false);
      component.set('v.explicitGuaranteeDisabled', false);
      component.set('v.filialCoreDisabled', false);
      return;
    }
    const isParent = helper.parseBooleanValue(parentSubsidiarySer.isParent);
    const isExpgAvailable = helper.parseBooleanValue(parentSubsidiarySer.isExpgAvailable);
    const isCoreRelation = helper.parseBooleanValue(parentSubsidiarySer.isCoreRelation);

    component.set('v.groupCorporateDisabled', true);
    component.set('v.explicitGuaranteeDisabled', true);
    component.set('v.filialCoreDisabled', true);
    component.set('v.groupCorporateValue', String(isParent));
    component.set('v.explicitGuaranteeValue', String(isExpgAvailable));
    if (!isExpgAvailable) {
      component.set('v.filialCoreValue', String(isCoreRelation));
    }
    const auraIds = helper.getAuraIds();
    helper.handleChangeForm(component, event, helper, auraIds);
  },
  clearValues: function(component, auraIds) {
    // Clear component values
    component.set('v.selectedCountry', null);
    component.set('v.selectedClient', []);
    component.set('v.selectedBankEntity', null);
    component.set('v.parentSubsidiarySer', null);
    component.set('v.selectedRatingSystem', null);
    component.set('v.formDataMap', {});
    component.set('v.ifisModelDisabled', false);
    component.set('v.groupCorporateDisabled', false);
    component.set('v.explicitGuaranteeDisabled', false);
    component.set('v.filialCoreDisabled', false);
    component.set('v.groupCorporateValue', null);
    component.set('v.explicitGuaranteeValue', null);
    component.set('v.filialCoreValue', null);

    // Clear aura id component values
    for (const auraId of auraIds) {
      if (auraId !== 'entityType') { // Do not clear the entity type
        const componentCmp = component.find(auraId);
        if (componentCmp) {
          if (componentCmp.get('v.type') === 'checkbox') {
            componentCmp.set('v.checked', false);
          } else {
            componentCmp.set('v.value', null);
          }
        }
      }
    }

    // Clear visibility class
    const values = this.getCurrentValues(component, auraIds);
    this.setConditionalVisibility(component, values);
  },
  createClientSelector: function(component, entityTypeValue) {

    // Clear array to avoid multiple components
    component.set('v.clientSelectorCmp', []);

    const params = {
      'aura:id': 'client-selector',
      'recordId': component.get('v.recordId'),
      'entityType': entityTypeValue,
      'clientOptionSlctd': component.getReference('v.selectedClient'),
      'countrySlctdParent': component.getReference('v.selectedCountry'),
      'bankEntitySlctd': component.getReference('v.selectedBankEntity'),
      'parentSubsidiarySer': component.getReference('v.parentSubsidiarySer'),
      'isGDT': component.getReference('v.isGDT'),
      'ratingSystemName': component.getReference('v.ratingSystemName'),
      'isProspect': component.get('v.isProspect'),
      'ratingSystemEnabled': component.get('v.ratingSystemEnabled'),
      'ratingSystemBookCodes': component.get('v.ratingSystemBookCodes')
    };

    $A.createComponent('c:Arc_Gen_Client_Selector', params, function(elem, status, errorMessage) {
      if (status === 'SUCCESS') {
        const body = component.get('v.clientSelectorCmp') || [];
        body.push(elem);

        component.set('v.clientSelectorCmp', body);
      } else if (status === 'ERROR') {
        console.error('Error creating client selector: ' + errorMessage);
      }
    });
  },
  fireRefreshViewForm: function(component) {
    const clientSelectorCmp = component.get('v.clientSelectorCmp')[0];
    if (clientSelectorCmp && clientSelectorCmp.isValid()) {
      clientSelectorCmp.refreshViewForm();
    }
  },
  fireEventWizard: function(component, eventType, parameters) {
    const wizardEvent = component.getEvent('wizardEvent');
    wizardEvent.setParams({
      eventType: eventType,
      parameters: parameters
    });
    wizardEvent.fire();
  }
});