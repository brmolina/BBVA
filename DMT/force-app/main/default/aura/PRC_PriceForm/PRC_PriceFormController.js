({
    doinit: function (component, event, helper) {
        helper.getpicklist(component, helper);
        helper.getPricingDetails(component, helper);
    },
    /*
    save: function(component) {
		var formulario = component.find('priceform');
		formulario.submit();
    },
    */
    calculate: function (component, event, helper) {
        console.log('estoy en calculate');
        if (helper.checkIsEmpty(priceDetail.gf_scope_type__c)) {
            console.log('vacio el type');
        }


        console.log('request event handled');
        var eventfired = helper.calculate(component, helper);
        eventfired.then(function (resolve) {
            console.log(' response eventfired');
        });
    },
    closemodal: function (component, event, helper) {
    },
    closemodalevt: function (component, event, helper) {
        var loadcmpevt = component.getEvent('closemodalevt');
        console.log('recupero el evento:' + loadcmpevt);
        loadcmpevt.fire();
        console.log('lanzo el evento');
    },
    onsubmitsuccess: function (component, event, helper) {
        console.log('onsubmitsucess');
        let flagmarked = component.get('v.flag');
        if (flagmarked === false) {
            var fields = { "PRC_Pricing_Form_Edited__c": true };
            component.set('v.flag', true);
            component.find('priceform').submit(fields);
        } else {
            let submitsuccessevent = component.getEvent('formsubmitresult');
            submitsuccessevent.setParam('success', true);
            submitsuccessevent.fire();
        }
    },
    onChangeRiskProduct: function (component, event, helper) {
        var riskProduct = component.find('riskProductId').get('v.value');
        var listas = component.get('v.picklists');
        var n = 0;
        while(listas[n].id !== 'PRODUCTS') {
          n++;
        }
        var registros = listas[n].records;
        var i = 0;
        while(registros[i].id !== riskProduct) {
          i++;
        }
        var label = registros[i].name;
        component.find('riskProductName').set('v.value',label);
        var fundingCostOn = component.find('fundingCostOnId').get('v.value');
        var nominalOn = component.find('nominalOnId').get('v.value');
        var marginOn = component.find('marginOnId').get('v.value');
        helper.checkIsEditableOnBalance(component, helper, label, fundingCostOn, nominalOn, marginOn);
    },
    onChangeFundingCurve: function (component, event, helper) {
        var fundingCurve = component.find('fundingCurveId').get('v.value');
        if (fundingCurve === 'BBVA_FUNDING') {
            component.set('v.displayFundingCost', false);
            component.find('fundingCostOnId').set('v.value', null);
            component.find('fundingCostOffId').set('v.value', null);
        } else {
            component.set('v.displayFundingCost', true);
            var riskProduct = component.find('riskProductId').get('v.value');
            var RISK_PRODUCT_ONLY_OFF_BALANCE_LIST = helper.getRiskProductOffBalanceList();
            if (!RISK_PRODUCT_ONLY_OFF_BALANCE_LIST.includes(riskProduct)) {
                component.find('fundingCostOnId').set('v.value', 0);
            }
            component.find('fundingCostOffId').set('v.value', 0);
        }
    },
    onChangeBooking: function (component, event, helper) {
        helper.getbookingDet(component, event, helper,component.find('bookingId').get('v.value'));
        helper.checkIsEditableLGD(component);
    },

    /* función que se ejecuta al modificarse el campo Financing Type */
    onChangeFinancing: function (component, event, helper) {
        console.log('onchangeFinancing');

        //Comprobamos si ha deshabilitarse el campo LGD
        helper.checkIsEditableLGD(component);

        //Modifica el atributo isProjectFinance del componente, lo que hara saltar la funcion projectFinanceChangeHandler
        //Ademas, los campos de rating se habilitan/deshabilitan en el .cmp en funcion de este atributo
        helper.checkIsProjectFinance(component);
    },
    onChangeAmortizationType: function (component, event, helper) {
        var amortization = component.find('amortizationTypeId').get('v.value');
        helper.checkIsDisplayedAmortization(component, amortization, false);
    },

    /* Función que se ejecuta cuando el campo Financing Type es o no ProjectFinance */
    projectFinanceChangeHandler: function (component, event, helper) {
        console.log('projectFinanceChangeHandler');
        if (component.get('v.isProjectFinance')) {
            //Si es Project Finance, dejamos el campo Amortization Type con valor "User Defined"
            component.find('amortizationTypeId').set('v.value','USER_DEFINED');
            //Y lanzamos la funcion que habilita/deshabilita campos en funcion del Amortization Type
            helper.checkIsDisplayedAmortization(component, component.find('amortizationTypeId').get('v.value'), false);
        }
        helper.checkIsEditableLGD(component);
    },
    refreshMitigantForm: function (component, event, helper) {
        helper.createMitigantForm(component,helper);
    }

})