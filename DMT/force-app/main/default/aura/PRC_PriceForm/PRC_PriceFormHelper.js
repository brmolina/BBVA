({
    getRiskProductOffBalanceList: function () {
        return ["Loan Underwritting", "Guarantee/SBLC - Credit Substitue", "Financial or Technical Guarantee", "Technical Guarantee",
            "Stand by Letter of Credit", "L/C", "Documentary Credit with Shipment Guarantee", "Silent Guarantee"];
    },
    getbookingDet: function (component, event, helper,bk) {
        var action = component.get('c.getPickRating');
        var params ={ 'booking': bk };

        var callback = function (response) {
             var stateStore = response.getState();

            if(stateStore === "SUCCESS") {
                var storeRes = response.getReturnValue();
                component.find('costToIncomeId').set('v.value',storeRes.PRC_costToIncome__c);
                component.find('taxRateId').set('v.value',storeRes.PRC_taxRate__c);
				component.set('v.bookval',storeRes.Label);
				helper.checkIsEditableLGD(component);
            }

         };
        action.setParams(params);
        action.setCallback(this, callback);
        $A.enqueueAction(action);
   },

    getpicklist: function (component, helper) {
        var action = component.get('c.getPickList');

        action.setCallback(this, function (response) {
            var stateStore = response.getState();
            if (stateStore === "SUCCESS") {
                var storeRes = JSON.parse(response.getReturnValue());
                var storeStatus = storeRes.status;
                var storeStatusMS = storeRes.wsErrorMsg;
                if(storeRes != null && storeStatus == 200) { //NOSONAR
                    var body = JSON.parse(storeRes.body);
                    component.set('v.picklists', body.data.catalogs);
                    component.set('v.pickloaded', true);
                    console.log(body);
                } else {
                    let PicklistEvtresponse = component.getEvent('PRCPicklistError');
                    PicklistEvtresponse.setParams({'codesstatus': storeStatus,
                                                   'codeserror':storeStatusMS});
                    PicklistEvtresponse.fire();
                    component.set('v.pickloaded', false);
                }
            } else {
                    console.log('calculation crashed');
                                    component.set('v.pickloaded', false);
                }
        });

        $A.enqueueAction(action);
    },

    getPricingDetails: function (component, helper) {
        let opportunityId = component.get('v.recordId');
        console.log('opportunityId: ' + opportunityId);
        var action = component.get('c.getPricingDetail');
        var params = { 'oppId': opportunityId };
        var callback = function (response) {
            let state = response.getState();
            var value = response.getReturnValue();
            if (state === 'SUCCESS') {
                console.log('>>>>> getPricingDetails success');
                component.set('v.pricingDetailId', value.Id);
                component.set('v.loaded', true);
                component.set('v.pricingdet', value);
                                console.log(value);

                /* Inicilializar campos */
                if(component.get('v.loaded') && component.get('v.pickloaded')){
                    helper.populateInitFields(component, helper, value);
                    /* Comprobación del Risk Product para deshabilitar campos OnBalance */
                    helper.checkIsEditableOnBalance(component, helper, value.gf_pricing_risk_product_name__c,
                    value.gf_on_balance_funding_per__c, value.gf_on_bal_mrgn_gen_amount__c, value.gf_ope_on_balance_margin_per__c);
                }
            } else {
                console.log();
            }
        };
        action.setParams(params);
        action.setCallback(this, callback);
        $A.enqueueAction(action);
    },
    calculate: function (component, helper) {
        return new Promise(function (resolve, reject) {
            let action = componet.get('c.callWS');
            let params = {};
            let callback = function (response) {
                let state = response.getState();
                let value = response.getReturnValue();
                if (state === 'SUCCESS') {
                    console.log('calculation success');
                    let calculateEvtresponse = component.getEvent('calculateresponse');
                    calculateEvtresponse.setParams('response', value);
                    calculateEvtresponse.fire();
                    resolve();
                } else {
                    console.log('calculation crashed');
                    reject();
                }
            };
            action.setParams(params);
            action.setCallback(callback);
            $A.enqueueAction(action);
        });
    },
    populateInitFields: function (component, helper, priceDetail) {
        /* campos para inicializar a un valor por defecto */
        if (helper.checkIsEmpty(priceDetail.gf_scope_type__c)) {
            component.find('clientTypeId').set('v.value', null);
        }
        if (helper.checkIsEmpty(priceDetail.gf_financing_type_name__c)) {
            component.find('financingTypeId').set('v.value', 'STANDARD_FUNDING');
                        component.set('v.enableLGD', false);

        } else if (priceDetail.gf_financing_type_name__c.includes('PROJECT_FINANCE_SOLID')) {
                        component.find('financingTypeId').set('v.value', 'PROJECT_FINANCE_SOLID');

            component.set('v.enableLGD', true);
        }


        helper.populateInitFields_2(component, helper, priceDetail);
    },

    //se divide en varias por evitar errores de sonar
    populateInitFields_2: function (component, helper, priceDetail) {
        if (helper.checkIsEmpty(priceDetail.gf_funding_curve_type__c)) {
            component.find('fundingCurveId').set('v.value', 'BBVA_FUNDING');
            component.set('v.displayFundingCost', false);
        } else {
            if (priceDetail.gf_funding_curve_type__c === 'BBVA_FUNDING') {
                component.set('v.displayFundingCost', false);
            } else {
                component.set('v.displayFundingCost', true);
                if (helper.checkIsEmpty(priceDetail.gf_on_balance_funding_per__c)) {
                    component.find('fundingCostOnId').set('v.value', 0);
                }
                if (helper.checkIsEmpty(priceDetail.gf_off_balance_funding_per__c)) {
                    component.find('fundingCostOffId').set('v.value', 0);
                }
            }
        }
        helper.checkIsDisplayedAmortization(component, priceDetail.amortization_desc__c,priceDetail.business_area_desc__c, true);

        if (helper.checkIsEmpty(priceDetail.gf_off_bal_mrgn_gen_amount__c)) {
            component.find('nominalOffId').set('v.value', 0);
        }
        if (helper.checkIsEmpty(priceDetail.gf_ope_off_balance_margin_per__c)) {
            component.find('marginOffId').set('v.value', 0);
        }

        helper.populateInitFields_3(component, helper, priceDetail);
    },

    //se divide en varias por evitar errores de sonar
    populateInitFields_3: function (component, helper, priceDetail) {
        /* Campos para autorellenar con valores de cliente, booking oportunidad... */
        if (helper.checkIsEmpty(priceDetail.currency_id__c)) {
            component.find('operationalCurrencyId').set('v.value', priceDetail.PRC_Opportunity__r.CurrencyIsoCode);
        }
        if (helper.checkIsEmpty(priceDetail.transaction_country_name__c)) {
            component.find('CR').set('v.value', priceDetail.transaction_country_name__c);
        }
        if (!helper.checkIsEmpty(priceDetail.gf_ope_booking_entity_name__c)){
            component.find('bookingId').set('v.value', priceDetail.gf_ope_booking_entity_name__c);
            helper.getbookingDet(component, event, helper,priceDetail.gf_ope_booking_entity_name__c);
        } else {
            component.set('v.bookval',null);
    	}
		helper.createMitigantForm(component,helper);   
    },

    checkIsEmpty: function (x) {
        return ((typeof x === 'undefined') || (x == null) || (x === "") || (x.length === 0) || (x === false) || (typeof x === 'string' && x.replace(/\s/g, "") === "")
            /*  || (!/[^\s]/.test(x)) || (/^\s*$/.test(x))  */
        );
    },

    checkIsEditableOnBalance: function (component, helper, riskProduct, fundingCostOn, nominalOn, marginOn) {
        var RISK_PRODUCT_ONLY_OFF_BALANCE_LIST = helper.getRiskProductOffBalanceList();
        if (RISK_PRODUCT_ONLY_OFF_BALANCE_LIST.includes(riskProduct)) {
            component.set('v.enableOnBalance', false);
            component.find('fundingCostOnId').set('v.value', null);
            component.find('nominalOnId').set('v.value', null);
            component.find('marginOnId').set('v.value', null);
        } else {
            component.set('v.enableOnBalance', true);
            var fundingCurve = component.find('fundingCurveId').get('v.value');
            if (fundingCurve !== 'BBVA_FUNDING' && helper.checkIsEmpty(fundingCostOn)) {
                component.find('fundingCostOnId').set('v.value', 0);
            }
            if (helper.checkIsEmpty(nominalOn)) {
                component.find('nominalOnId').set('v.value', 0);
            }
            if (helper.checkIsEmpty(marginOn)) {
                component.find('marginOnId').set('v.value', 0);
            }
        }
    },

    checkIsEditableLGD:function(component) {
        var resp = false;
        var booking = component.find('bookingId').get('v.value');
        var proyectf = component.find('financingTypeId').get('v.value');
        if (booking === 'Compass' || proyectf === 'PROJECT_FINANCE_SOLID') {
            component.find('lgdId').set('v.value', 20);
            resp = true;
        } else {
            component.find('lgdId').set('v.value', null);
        }
        component.set('v.enableLGD', resp);
    },

    checkIsDisplayedAmortization: function (component, amortization,proyectfinance, isInit) {
        if (amortization === 'USER_DEFINED') {
            component.set('v.proyectf', proyectfinance);
            component.set('v.isAmortizationVisible', true);
            component.find('paymentFrequencyId').set('v.value', null);
            component.find('marginOffId').set('v.value', null);
            component.find('marginOnId').set('v.value', null);
            component.find('nominalOffId').set('v.value', null);
            component.find('nominalOnId').set('v.value', null);
        } else {
            component.set('v.isAmortizationVisible', false);
            if (!isInit) {
                component.find('paymentRateId').set('v.value', null);
                component.find('paymentFrequencyId').set('v.value', 'ANNUAL');
                component.find('nonAccrualFeesId').set('v.value', 0);
                component.find('accrualFeesId').set('v.value', 0);
                component.find('marginOffId').set('v.value', 0);
                component.find('marginOnId').set('v.value', 0);
                component.find('nominalOffId').set('v.value', 0);
                component.find('nominalOnId').set('v.value', 0);
            }
        }
},

    checkIsProjectFinance: function (component) {
        console.log('financingtypeid: ' + component.find('financingTypeId').get('v.value'));
        var financing = component.find('financingTypeId').get('v.value');
        if (financing != null && financing.includes('PROJECT_FINANCE')) {
            component.set('v.isProjectFinance', true);
            console.log('a true');
        } else {
            component.set('v.isProjectFinance', false);
            console.log('a false');
        }
    },
    createMitigantForm : function (component,  helper) {
        console.log('++++++++ pricingDetailId:' + component.get('v.pricingDetailId'));
        $A.createComponent(
            "c:PRC_MitigantsForm",
            {
                "pricingDetailsId": component.get('v.pricingDetailId'),
                "picklists": component.get('v.picklists')
            },
            function(mitigantsForm, status, errorMessage){
                //Add the new button to the body array
                if (status === "SUCCESS") {
                    component.set("v.body", []);
                    var body = component.get("v.body");
                    body.push(mitigantsForm);
                    component.set("v.body", body);
                    console.log("++++ componente creado");
                }
                else if (status === "INCOMPLETE") {
                    console.log("No response from server or client is offline.")
                    // Show offline error
                }
                else if (status === "ERROR") {
                    console.log("Error: " + errorMessage);
                    // Show error message
                }
            }
        );
    }

})