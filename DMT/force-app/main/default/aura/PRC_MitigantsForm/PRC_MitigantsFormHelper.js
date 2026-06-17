({
  addMitigant : function(component, event, helper) {
    var pricingMitigant = helper.informData(component);

    var actionRel = component.get('c.insertMitigant');
    actionRel.setParams({
      'mapDataMitigant': pricingMitigant
    })

    var promiseRel = this.actionPromise(component, actionRel);
    return promiseRel.then(
      $A.getCallback(function(result) {
        helper.emptyForm(component);
        var addMitigantEvt = $A.get("e.c:PRC_MitigantEvent");
		    addMitigantEvt.fire();
      }),
      $A.getCallback(function(error) {
        console.error( 'Error calling action "' + actionRel + '" with state: ' + error.message );
      })
    ).catch(function(e){});
  },
  validFormMitigant: function(component, helper) {
    let valid = true;
		//variable que se utilizara para mostrar en el mensaje los campos obligatorios sin rellenar
		let requiredFields = '';

		requiredFields = helper.checkfieldMitigant(component, requiredFields, 'mitigantingTypeId', 'Mitigating Type');
		requiredFields = helper.checkfieldMitigant(component, requiredFields, 'mitigantingId', 'Mitigating');
		requiredFields = helper.checkfieldMitigant(component, requiredFields, 'comPercentageId', 'Commercial Percentage');
		requiredFields = helper.checkfieldMitigant(component, requiredFields, 'expirationId', 'Expiration');
		requiredFields = helper.checkfieldMitigant(component, requiredFields, 'polPercentageId', 'Political Percentage');
    if(helper.ifShowPicklist(component, 'v.showSameParent')) {
      requiredFields = helper.checkfieldMitigant(component, requiredFields, 'sameParentId', 'Belong to the same parent?');
    }
		if(helper.ifShowPicklist(component, 'v.showCoverCountry')) {
      requiredFields = helper.checkfieldMitigant(component, requiredFields, 'countryRiskCoverageId', 'Cover the Country Risk?');
    }
    if(helper.ifShowPicklist(component, 'v.showIsEuropean')) {
      requiredFields = helper.checkfieldMitigant(component, requiredFields, 'agencyEuropeanId', 'Is European?');
    }
    if(helper.ifShowPicklist(component, 'v.showDistinctCncy')) {
      requiredFields = helper.checkfieldMitigant(component, requiredFields, 'distinctCurrencyId', 'Distinct currency?');
    }
		requiredFields = helper.checkfieldMitigant(component, requiredFields, 'conterpartyId', 'Conterparty Mitigating');
		requiredFields = helper.checkfieldMitigant(component, requiredFields, 'externalRatingId', 'External Rating');
		requiredFields = helper.checkfieldMitigant(component, requiredFields, 'ratingId', 'Rating');
    if (requiredFields.length>2) {
			valid = false;
      component.set('v.requiredFieldsMessage', 'Required fields: ' + requiredFields.substring(0, requiredFields.length-2));
      component.set('v.displayError', true);

		}

    return valid;
  },
  checkfieldMitigant: function(component,requiredFields,fieldToCheck, errorField) {
		let fields = requiredFields;
		let valueToCheck = component.find(fieldToCheck).get('v.value');
		if (valueToCheck == null || valueToCheck === '') {
			fields = fields + errorField + ' , ';
		}
		return fields;
	},
  informData : function(component) {
    var pricingMitigant = {};
    pricingMitigant['gf_warranty_type__c'] = component.find('mitigantingTypeId').get('v.value');
    pricingMitigant['gf_subwarranty_name__c'] = component.find('mitigantingId').get('v.value');
    pricingMitigant['DES_Client_Mitigant__c'] = component.find('conterpartyId').get('v.value');
    pricingMitigant['gf_external_rating_agncy_type__c'] = component.find('externalRatingId').get('v.value');
    pricingMitigant['gf_warranty_ptt_rating_type__c'] = component.find('ratingId').get('v.value');
    pricingMitigant['gf_offer_warranty_country_type__c'] = component.find('countryId').get('v.value');
    pricingMitigant['gf_cty_rqst_wrrnty_risk_per__c'] = component.find('polPercentageId').get('v.value');
    pricingMitigant['gf_mit_rk_rqst_warranty_per__c'] = component.find('comPercentageId').get('v.value');
    pricingMitigant['gf_expir_wrrnty_operation_name__c'] = component.find('expirationId').get('v.value');
    pricingMitigant['gf_end_guarantee_date__c'] = component.find('endDateId').get('v.value');
    pricingMitigant['gf_gtr_debtor_group_ind_type__c'] = this.ifShowPicklist(component, 'v.showSameParent') ? component.find('sameParentId').get('v.value') : 'No';
    pricingMitigant['gf_cvr_rk_cty_wrrnty_ind_type__c'] = this.ifShowPicklist(component, 'v.showCoverCountry') ? component.find('countryRiskCoverageId').get('v.value') : 'No';
    pricingMitigant['gf_exprt_cr_eur_agncy_ind_type__c'] = this.ifShowPicklist(component, 'v.showIsEuropean') ? component.find('agencyEuropeanId').get('v.value') : 'No';
    pricingMitigant['gf_oppy_mit_dif_ccy_ind_type__c'] = this.ifShowPicklist(component, 'v.showDistinctCncy') ? component.find('distinctCurrencyId').get('v.value') : 'No';
    pricingMitigant['gf_mitigating_comment_desc__c'] = component.find('commentsId').get('v.value');
    pricingMitigant['Pricing_Detail__c'] = component.get('v.pricingDetailsId');
    pricingMitigant['Id'] = component.get('v.pricingMitigantId');
    return pricingMitigant;
  },
  emptyForm: function(component) {
    if(this.ifShowPicklist(component, 'v.showSameParent')) {
      component.find('sameParentId').set('v.value', null);
    }
		if(this.ifShowPicklist(component, 'v.showCoverCountry')) {
      component.find('countryRiskCoverageId').set('v.value', null);
    }
    if(this.ifShowPicklist(component, 'v.showIsEuropean')) {
      component.find('agencyEuropeanId').set('v.value', null);
    }
    if(this.ifShowPicklist(component, 'v.showDistinctCncy')) {
      component.find('distinctCurrencyId').set('v.value', null);
    }
    component.find('mitigantingTypeId').set('v.value',null);
    component.find('mitigantingId').set('v.value', null);
    component.find('conterpartyId').set('v.value', null);
    component.find('externalRatingId').set('v.value', null);
    component.find('ratingId').set('v.value', null);
    component.find('countryId').set('v.value', null);
    component.find('polPercentageId').set('v.value', null);
    component.find('comPercentageId').set('v.value', null);
    component.find('expirationId').set('v.value', null);
    component.find('endDateId').set('v.value', null);
    component.find('commentsId').set('v.value', null);
    component.set('v.displayError', false);
    component.set('v.requiredFieldsMessage','');
    component.set('v.pricingMitigantId',null);
  },
  controlPicklist: function(component, valueMitiganting) {
    let isSameParentValues = ['FIX_INCOME','EQUITY','BANKS_BANKING','MULTILATERALS_BANKING','SOVEREIGN_ECA','IRUS_BANKING',
    'VENTASEC_BANKING','CORPORATE','ECAS_ECA','PRIVATEINSURANCE_BANKING','FIXED_INC_SOVEREIGN','COMMERCIAL_DISCOUNT'];
    let isCountryValues = ['CASH','FIX_INCOME','EQUITY','BANKS_BANKING','MULTILATERALS_BANKING','SOVEREIGN_ECA','IRUS_BANKING',
    'VENTASEC_BANKING','CORPORATE','ECAS_ECA','PRIVATEINSURANCE_BANKING','FIXED_INC_SOVEREIGN','COMFORT_LETTER','COMMERCIAL_DISCOUNT','PARENT','MORTGAGE'];
    let isEuropeanValues = ['SOVEREIGN_ECA','ECAS_ECA'];
    let isDistinctValues = ['CASH','FIX_INCOME','EQUITY','BANKS_BANKING','MULTILATERALS_BANKING','SOVEREIGN_ECA','IRUS_BANKING',
    'VENTASEC_BANKING','ECAS_ECA','PRIVATEINSURANCE_BANKING','FIXED_INC_SOVEREIGN'];

    this.conditionalCheck(component, isSameParentValues, valueMitiganting, 'v.showSameParent');
    this.conditionalCheck(component, isCountryValues, valueMitiganting, 'v.showCoverCountry');
    this.conditionalCheck(component, isEuropeanValues, valueMitiganting, 'v.showIsEuropean');
    this.conditionalCheck(component, isDistinctValues, valueMitiganting, 'v.showDistinctCncy');
  },
  conditionalCheck: function(component, isSameParentValues, valueMitiganting, toCheck) {
    if(isSameParentValues.includes(valueMitiganting)) {
      component.set(toCheck,true);
    } else {
      component.set(toCheck,false);
    }
  },
  ifShowPicklist: function(component, toCheck) {
    var valueToSend = false;
    if(component.get(toCheck)) {
      valueToSend = true;
    }
    return valueToSend;
  },
  actionPromise: function(component, actionMitigant, callback) {
    return new Promise(function(resolve, reject) {
      actionMitigant.setCallback(this, function(response) {
          var statusaction = response.getState();
          if (statusaction === 'SUCCESS') {
              resolve(response.getReturnValue());
          } else if (statusaction === 'ERROR') {
              var resperr = response.getError();
              if (resperr) {
                  if (resperr[0] && resperr[0].message) {
                      reject(
                          Error('Err: ' + resperr[0].message)
                      );
                  }
              } else {
                  reject(
                      Error('Uknown error')
                  );
              }
          }
      });
      $A.enqueueAction(actionMitigant);
    });
  }
})