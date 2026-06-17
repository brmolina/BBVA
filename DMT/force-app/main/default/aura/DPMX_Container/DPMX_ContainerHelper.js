({
    doInit: function(cmp, event, helper) {
        helper.waiting(cmp);
        cmp.set('v.profitability', '0');
        cmp.set('v.profitAmount', '0');
        cmp.set('v.profitabilitySimulation', '0');
        cmp.set('v.profitAmountSimulation', '0');
        cmp.set('v.infoContent', 'Es la suma de los gastos fijos (switch, sims, personal, papelería, eGLOBAL, CCR, atención al cliente y amortización de dispositivos) más los gastos variables (VISA internacional, Mastercard internacional y doméstico).');
        var action = cmp.get('c.getInitialData');
        action.setParams({
            'recordId': cmp.get('v.recordId')
        })
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                var result = response.getReturnValue();
                if (result.formalizeExist) {
                    if (result.formalizeAcceptedCheck) {
                        cmp.set('v.deniedFormalizeCheck', result.deniedFormalizeCheck);
                        cmp.set('v.deniedAuthorizeCheck', result.deniedAuthorizeCheck);
                    } else {
                        cmp.set('v.deniedFormalizeCheck', !result.deniedFormalizeCheck);
                    }
                }
                cmp.set('v.customerId', result.customerId);
                cmp.set('v.dynamicPricing', result.dynamicPricing);
                cmp.set('v.isGs', result.isGs);
                cmp.set('v.isCustom', result.dynamicPricing.isCustom__c);
                cmp.set('v.TAMAccepted__c', result.dynamicPricing.TAMAccepted__c);

                var dynamicPricing = cmp.get('v.dynamicPricing');
                var acquirerCategoryId = dynamicPricing.familia_AcquiererCategories_Id__c;
                var familia = dynamicPricing.familia__c;

                var PrctMixOwn = dynamicPricing.Sim_Percentage_Debit_MixOwn__c;
                cmp.set('v.PrctMixOwn', PrctMixOwn);
                var PrctMixExt = dynamicPricing.Sim_Percentage_Debit_MixExternal__c;
                cmp.set('v.PrctMixExt', PrctMixExt);
                var PrctCrMixOwn = dynamicPricing.Sim_Percentage_Credit_MixOwn__c;
                cmp.set('v.PrctCrMixOwn', PrctCrMixOwn);
                var PrctCrMixExt = dynamicPricing.Sim_Percentage_Credit_MixExternal__c;
                cmp.set('v.PrctCrMixExt', PrctCrMixExt);
                var PrctIntMix = dynamicPricing.Sim_Percentage_MixInternational__c;
                cmp.set('v.PrctIntMix', PrctIntMix);
                var PrctTotalMix = dynamicPricing.Sim_Percentage_Total__c;
                cmp.set('v.PrctTotalMix', PrctTotalMix);
                cmp.set('v.basisPoint', dynamicPricing.basisPoint__c);
                var customerId = cmp.get('v.customerId');
                if (!result.dynamicPricing.isCustom__c) {
                    helper.callAcquirerActivitiesService(cmp, event, helper);
                } else {
                    helper.commisionTPVCalculator(cmp);
                    helper.commisionRedCelCalculator(cmp);
                    helper.commisionBajFacalculator(cmp);
                    cmp.set('v.razonSocialLst', result.razonSocialLst);
                    cmp.set('v.razonSocialMp', result.razonSocialMp);

                    cmp.set('v.gastoTotal', result.dynamicPricing.gastoTotal__c);
                    cmp.set('v.gastMit', result.dynamicPricing.gastMit__c);
                    cmp.set('v.valueDefault', result.dynamicPricing.familia__c);

                    /** callDiscountService */
                    var servicecallCorporateRateService = cmp.get('c.callCorporateRateService');
                    servicecallCorporateRateService.setParams({
                        'recordId': cmp.get('v.recordId'),
                        'customerId': customerId,
                        'acquirerId': acquirerCategoryId
                    })
                    servicecallCorporateRateService.setCallback(this, function(response) {
                        var state = response.getState();
                        if (state === 'SUCCESS') {
                            var result = response.getReturnValue();
                            if (result.error) {
                                serviseOk = false;
                                helper.showToast('Error', 'Error', 'Ha surgido un erro al conectarse con los servicios. Recargue la pagina.');
                            } else if (result.success) {
                                cmp.set('v.interchangeRates', result.interchangeRates);
                                cmp.set('v.discountRates', result.discountRates);
                                cmp.set('v.discountWrapper', result.discountWrapper);

                                cmp.set('v.credit', dynamicPricing.CustomAcquiredFeesCredit__c);


                                if (dynamicPricing.CustomAcquiredFeesDebit__c == 0) {
                                    cmp.set('v.debit', cmp.get('v.interchangeRates.debit'));
                                } else {
                                    cmp.set('v.debit', dynamicPricing.CustomAcquiredFeesDebit__c);
                                }
                                if (dynamicPricing.CustomAcquiredFeesInternational__c == 0) {
                                    cmp.set('v.international', result.interchangeRates.international);
                                } else {
                                    cmp.set('v.international', dynamicPricing.CustomAcquiredFeesInternational__c);
                                }

                                if (dynamicPricing.CustomSimulatedCredit__c == 0) {
                                    cmp.set('v.creditSimulation', cmp.get('v.interchangeRates.credit'));
                                } else {
                                    cmp.set('v.creditSimulation', dynamicPricing.CustomSimulatedCredit__c);
                                }

                                if (dynamicPricing.CustomSimulatedDebit__c == 0) {
                                    cmp.set('v.debitSimulation', cmp.get('v.interchangeRates.debit'));
                                } else {
                                    cmp.set('v.debitSimulation', dynamicPricing.CustomSimulatedDebit__c);
                                }
                                if (dynamicPricing.CustomSimulatedInternational__c == 0) {
                                    cmp.set('v.internationalSimulation', result.interchangeRates.international);
                                } else {
                                    cmp.set('v.internationalSimulation', dynamicPricing.CustomSimulatedInternational__c);
                                }
                                helper.doneWaiting(cmp);

                                /** */
                            }
                        } else if (state === 'ERROR') {
                            serviseOk = false;
                            var errors = response.getError();
                            helper.showToast('Error', 'Error', 'Ha surgido un error al conectarse con los servicios. Recargue la pagina.');
                        }
                    });
                    $A.enqueueAction(servicecallCorporateRateService);
                    /** */
                    
                }
            } else if (state === 'ERROR') {
                helper.showToast('Error', 'Error', 'Ha surgido un error al conectarse con los servicios. Recargue la pagina.');
            }
        });
        $A.enqueueAction(action);

    },
    handleOnCheckTerminal: function(cmp, event, helper) {
        if (event.getSource().get("v.checked")) {
            cmp.set('v.checkboxesWrapper.terminalIdCheckbox', true);
        } else {
            cmp.set('v.checkboxesWrapper.terminalIdCheckbox', false);
        }
    },
    handleOnCheckPinpad: function(cmp, event, helper) {
        if (event.getSource().get("v.checked")) {
            cmp.set('v.checkboxesWrapper.pinPadsInfoPinPadsCheckbox', true);
        } else {
            cmp.set('v.checkboxesWrapper.pinPadsInfoPinPadsCheckbox', false);
        }
    },
    handleAddClientInformation: function(cmp, event, helper) {
        let attr = {
            'acquirerActivitiesWrapper': cmp.get('v.acquirerActivitiesWrapper'),
            'action': 'add',
            'dynamicPricing': cmp.get('v.dynamicPricing'),
        };
        helper.loadComponent(cmp, event, helper, 'DPMX_SimulatorClientInfo', attr).then($A.getCallback(newComponent => {
            let body = [];
            body.push(newComponent);
            cmp.set('v.body', body);
        }));
        cmp.set('v.simulationBool',false);
    },
    handleModifyClientInformation: function(cmp, event, helper) {
        let attr = {
            'acquirerActivitiesWrapper': cmp.get('v.acquirerActivitiesWrapper'),
            'action': 'edit',
            'dynamicPricing': cmp.get('v.dynamicPricing')
        };
        helper.loadComponent(cmp, event, helper, 'DPMX_SimulatorClientInfo', attr).then($A.getCallback(newComponent => {
            let body = [];
            body.push(newComponent);
            cmp.set('v.body', body);
        }));
        cmp.set('v.simulationBool',false);
    },
    handleModifyBills: function(cmp, event, helper) {
        let attr = {
            'dynamicPricing': cmp.get('v.dynamicPricing')
        };
        helper.loadComponent(cmp, event, helper, 'DPMX_isCustom', attr).then($A.getCallback(newComponent => {
            let body = [];
            body.push(newComponent);
            cmp.set('v.body', body);
        }));
    },
    handleModifyTs: function(cmp, event, helper) {
        let attr = {
            'dynamicPricing': cmp.get('v.dynamicPricing')
        };
        helper.loadComponent(cmp, event, helper, 'DPMX_isCustomTS', attr).then($A.getCallback(newComponent => {
            let body = [];
            body.push(newComponent);
            cmp.set('v.body', body);
        }));
    },
    handleAddDevices: function(cmp, event, helper) {
        let attr = {
            'acquirerActivitiesWrapper': cmp.get('v.acquirerActivitiesWrapper'),
            'action': 'add',
            'dynamicPricing': cmp.get('v.dynamicPricing'),
        };
        helper.loadComponent(cmp, event, helper, 'DPMX_SimulatorDevices', attr).then($A.getCallback(newComponent => {
            let body = [];
            body.push(newComponent);
            cmp.set('v.body', body);
        }));
        cmp.set('v.simulationBool',false);
        helper.commisionTPVCalculator(cmp);
        helper.commisionRedCelCalculator(cmp);
        helper.commisionBajFacalculator(cmp);
    },
    handleModifyDevices: function(cmp, event, helper) {
        let attr = {
            'acquirerActivitiesWrapper': cmp.get('v.acquirerActivitiesWrapper'),
            'action': 'edit',
            'dynamicPricing': cmp.get('v.dynamicPricing')
        };
        helper.loadComponent(cmp, event, helper, 'DPMX_SimulatorDevices', attr).then($A.getCallback(newComponent => {
            let body = [];
            body.push(newComponent);
            cmp.set('v.body', body);
        }));
        cmp.set('v.simulationBool',false);
        helper.commisionTPVCalculator(cmp);
        helper.commisionRedCelCalculator(cmp);
        helper.commisionBajFacalculator(cmp);
    },
    handleAddCompany: function(cmp, event, helper) {
        var dynamicPricing = cmp.get('v.dynamicPricing');
        var acquirerCategoryId = dynamicPricing.familia_AcquiererCategories_Id__c;
        var customerId = cmp.get('v.customerId');

        let attr = {
            'dynamicId': cmp.get('v.recordId'),
            'dynamicPricing': cmp.get('v.dynamicPricing'),
            'companyComparisonList': cmp.get('v.companyComparisonList'),
            'customerId': customerId,
            'acquirerCategoryId': acquirerCategoryId
        };
        helper.loadComponent(cmp, event, helper, 'DPMX_CompanyComparisonAdd', attr).then($A.getCallback(newComponent => {
            let body = [];
            body.push(newComponent);
            cmp.set('v.body', body);
        }));
    },
    handleOnGenerateReport: function(cmp, event, helper) {
        let attr = {
            'sendConditionLst': cmp.get("v.sendConditionLst")
        };
        helper.loadComponent(cmp, event, helper, 'DPMX_SendCondition', attr).then($A.getCallback(newComponent => {
            let body = [];
            body.push(newComponent);
            cmp.set('v.body', body);
        }));
    },
    handleAuthoritation: function(cmp, event, helper) {
        let sendConditionLst;
        let isCustom = false;
        var isGs = cmp.get("v.DiscoruntDebitIsAmount");
        var debitBase;
        var creditBase = cmp.get("v.acquirerActivitiesWrapper.discount.percentage.credit");
        var internationalBase = cmp.get("v.acquirerActivitiesWrapper.discount.percentage.international");
        var baiBase = cmp.get("v.acquirerActivitiesWrapper.taxAcquirer.amount");
        var rentaBase = cmp.get("v.acquirerActivitiesWrapper.yieldPercentage");
        var family = cmp.get("v.acquirerActivitiesWrapper.businessInformation.familyAcquirer");

        if (isGs) {
            debitBase = cmp.get("v.acquirerActivitiesWrapper.discount.debit.itemizeType.amount");
        } else {
            debitBase = cmp.get("v.acquirerActivitiesWrapper.discount.debit.itemizeType.value");
        }
        if (cmp.get('v.sendConditionLst') === sendConditionLst) {
            isCustom = true;
            var resultRates = cmp.get('v.resultRates');
            var updDebit = cmp.get("v.debit");
            var updCredit = cmp.find("edtCredit").get("v.value");
            var updInternational = cmp.find("edtInternational").get("v.value");
            var updRenta = cmp.get("v.profitability");
            var updBai = cmp.get("v.profitAmount");
        } else {
            sendConditionLst = cmp.get('v.sendConditionLst');
        }
        let attr = {
            'dynamicPricing': cmp.get('v.dynamicPricing'),
            'sendConditionLst': sendConditionLst,
            'resultRates': resultRates,
            'isCustom': isCustom,
            'updDebit': updDebit,
            'updCredit': updCredit,
            'updInternational': updInternational,
            'updRenta': updRenta,
            'updBai': updBai,
            'debitBase': debitBase,
            'creditBase': creditBase,
            'internationalBase': internationalBase,
            'rentaBase': rentaBase,
            'baiBase': baiBase,
            'isGs': isGs,
            'family': family
        };
        helper.loadComponent(cmp, event, helper, 'DPMX_Authorization', attr).then($A.getCallback(newComponent => {
            let body = [];
            body.push(newComponent);
            cmp.set('v.body', body);
        }));
    },
    handleAuthoritationSimulation: function(cmp, event, helper) {
        var index = cmp.get("v.indexSimulation");
        var sendSimulationLst;
        var validate = cmp.get('v.validateresponseWraper');
        let isCustom = false;
        var isGs = cmp.get("v.DiscoruntDebitIsAmount");
        var debitBase;
        var creditBase = cmp.get("v.acquirerActivitiesWrapper.discount.percentage.credit");
        var internationalBase = cmp.get("v.acquirerActivitiesWrapper.discount.percentage.international");
        var rentaBase = cmp.get("v.acquirerActivitiesWrapper.taxAcquirer.amount");
        var baiBase = cmp.get("v.acquirerActivitiesWrapper.yieldPercentage");
        var family = cmp.get("v.acquirerActivitiesWrapper.businessInformation.familyAcquirer");
        var resultRates = 0;
        var updDebit = 0;
        var updCredit = 0;
        var updInternational = 0;
        var updRenta = 0;
        var updBai = 0;
        if (isGs) {
            debitBase = cmp.get("v.acquirerActivitiesWrapper.discount.debit.itemizeType.amount");
        } else {
            debitBase = cmp.get("v.acquirerActivitiesWrapper.discount.debit.itemizeType.value");
        }
        if (index != 5) {
            isCustom = true;
            validate.proposed.forEach((element) => {
                if (element.scenaryType == 'BREAK_EVEN') {
                    element.rate.itemizeRates.forEach((value) => {
                        switch (true) {
                            case (value.idOrder === 0):
                                if (isGs) {
                                    updDebit = value.itemizeRatesUnit.amount;
                                } else {
                                    updDebit = value.itemizeRatesUnit.percentage;
                                }
                                break;
                            case (value.idOrder == 1):
                                updCredit = value.itemizeRatesUnit.percentage;
                                break;
                            case (value.idOrder == 2):
                                updInternational = value.itemizeRatesUnit.percentage;
                                break;
                            case (value.idOrder == 3):
                                updRenta = value.itemizeRatesUnit.percentage;
                                break;
                        }
                    });
                    resultRates = 'Break even';
                    updBai = element.amount.amount;
                }
            });
        } else {
            isCustom = true;
            resultRates = cmp.get('v.resultRatesSimulation');
            updDebit = cmp.get("v.debitSimulation");
            updCredit = cmp.find("edtSimulationCredit").get("v.value");
            updInternational = cmp.find("edtSimulationInternational").get("v.value");
            updRenta = cmp.get("v.profitabilitySimulation");
            updBai = cmp.get("v.profitAmountSimulation");
        }
        let attr = {
            'dynamicPricing': cmp.get('v.dynamicPricing'),
            'sendConditionLst': sendSimulationLst,
            'resultRates': resultRates,
            'isCustom': isCustom,
            'updDebit': updDebit,
            'updCredit': updCredit,
            'updInternational': updInternational,
            'updRenta': updRenta,
            'updBai': updBai,
            'debitBase': debitBase,
            'creditBase': creditBase,
            'internationalBase': internationalBase,
            'rentaBase': rentaBase,
            'baiBase': baiBase,
            'isGs': isGs,
            'family': family
        };
        helper.loadComponent(cmp, event, helper, 'DPMX_Authorization', attr).then($A.getCallback(newComponent => {
            let body = [];
            body.push(newComponent);
            cmp.set('v.body', body);
        }));
    },
    openLink: function(cmp, event, helper) {
        window.open($A.get('$Label.c.DPMX_Microstrategy_Link'));
    },
    loadComponent: function(cmp, event, helper, cmpName, cmpAttr) {
        return new Promise($A.getCallback(function(resolve, reject) {
            $A.createComponent(
                'c:' + cmpName, cmpAttr,
                function(newCmp, status, errorMessage) {
                    if (status === 'SUCCESS') {
                        resolve(newCmp);
                    } else if (status === 'INCOMPLETE' || status === 'ERROR') {
                        helper.showToast('Error', 'error', errorMessage);
                    }
                }
            );
        }));
    },
    waiting: function(cmp) {
        cmp.set('v.waiting', true);
    },
    doneWaiting: function(cmp) {
        cmp.set('v.waiting', false);
    },
    handlesaveDiscountRate: function(cmp, event, helper) {
        var x = 0;
        var index = event.target.value;
        let radio;
        let discountRateLst;
        let editDebitBool = cmp.get('v.editDebitbool');
        let editCreditBool = cmp.get('v.editCreditbool');
        let editInternationalBool = cmp.get('v.editInternationalbool');
        if (index) {
            //radio = document.getElementById(index);
            for (x = 0; x != cmp.get('v.lstScenearios').length; x++) {
                radio = document.getElementById(x);
                radio.checked = false;
            }
            radio = document.getElementById('5');
            radio.checked = false;
            radio = document.getElementById(index);
            radio.checked = true;
            discountRateLst = cmp.get('v.lstScenearios')[index];
            if (discountRateLst !== undefined) {
                cmp.set('v.sendConditionLst', discountRateLst);
                cmp.set('v.isTasaSelect',false);
            }else{
                cmp.set('v.isTasaSelect',true);
            }
            
            cmp.set("v.disableSubmitBtn", true);

            if (!editDebitBool || !editCreditBool || !editInternationalBool) {
                cmp.set('v.deniedFormalizeCheck', true);
            } else {
                cmp.set('v.deniedFormalizeCheck', false);
                helper.handleSaveInfoToSendReport(cmp, event, helper);
            }
        }
    },
    handleOnSimulate: function(cmp, event, helper) {
        var acquirerActivitiesWrapper = cmp.get('v.acquirerActivitiesWrapper');
        var discountRates = cmp.get('v.interchangeRates');
        var customerId = cmp.get('v.customerId');
        var action = cmp.get('c.callValidate');
        action.setParams({
            'recordId': cmp.get('v.recordId'),
            'acquirerActivitiesWrapper': acquirerActivitiesWrapper,
            'discountRates': discountRates,
            'checkbox': true,
            'customerId': customerId
        })
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                var result = response.getReturnValue();
                if (result.error) {
                    cmp.set('v.simulationBool',false);
                    helper.showToast('Error', 'Error', 'Ha surgido un error al conectarse con los servicios. Recargue la pagina o vuelva a llamar a Simular.');
                } else if (result.success) {
                    cmp.set('v.validateresponseWraper', result.validateResponseWrapper);
                    cmp.set('v.rates', result.rates);
                    cmp.set('v.historalTasasBol', result.validateResponse);

                    cmp.set('v.gastoTotal', result.dynamicPricing.gastoTotal__c);
                    helper.resultRatesSimulation(cmp, event, helper);
                    helper.showToast('SUCCESS', 'Tasas actualizada', 'Se ha actualizado las tasas');
                }
            } else if (state === 'ERROR') {
                cmp.set('v.simulationBool',false);
                helper.showToast('Error', 'Error', 'Ha surgido un error al conectarse con los servicios. Recargue la pagina o vuelva a llamar a Simular.');

            }
        });
        $A.enqueueAction(action);
        cmp.set('v.simulationBool', true);
    },
    handlesaveSimulateRate: function(cmp, event, helper) {
        var index = event.target.value;
        cmp.set("v.disableSubmitSimulationBtn", true);
        cmp.set("v.indexSimulation", index);
        if (index) {
            if(!cmp.get('v.isCustom')){
                let discountRateLst = cmp.get('v.lstSceneariosSim')[index];
                cmp.set('v.sendSimulationLst', discountRateLst);
            }
            helper.handleSaveInfoToSendReport(cmp, event, helper);
        }
    },
    handleEditDebit: function(cmp, event, helper) {
        let editDebitBool = cmp.get('v.editDebitbool');
        let editCreditBool = cmp.get('v.editCreditbool');
        let editInternationalBool = cmp.get('v.editInternationalbool');
        if (editDebitBool) {
            editDebitBool = false;
        } else {
            editDebitBool = true;
        }

        if (!editDebitBool || !editCreditBool || !editInternationalBool) {
            cmp.set('v.disableUpdateBtn', false);
            cmp.set('v.disableSaveEditBtn', true);
            cmp.set('v.deniedFormalizeCheck', true);
            cmp.set('v.deniedAuthorizeCheck', true);
        } else {
            cmp.set('v.disableUpdateBtn', true);
            cmp.set('v.disableSaveEditBtn', false);
            cmp.set('v.deniedFormalizeCheck', false);
            cmp.set('v.deniedAuthorizeCheck', false);
        }
        cmp.set('v.editDebitbool', editDebitBool);
        helper.setFalseRadioButton();
    },
    handleEditCredit: function(cmp, event, helper) {
        let editDebitBool = cmp.get('v.editDebitbool');
        let editCreditBool = cmp.get('v.editCreditbool');
        let editInternationalBool = cmp.get('v.editInternationalbool');
        if (editCreditBool) {
            editCreditBool = false;
        } else {
            editCreditBool = true;
        }

        if (!editDebitBool || !editCreditBool || !editInternationalBool) {
            cmp.set('v.disableUpdateBtn', false);
            cmp.set('v.disableSaveEditBtn', true);
            cmp.set('v.deniedFormalizeCheck', true);
            cmp.set('v.deniedAuthorizeCheck', true);
        } else {
            cmp.set('v.disableUpdateBtn', true);
            cmp.set('v.disableSaveEditBtn', false);
            cmp.set('v.deniedFormalizeCheck', false);
            cmp.set('v.deniedAuthorizeCheck', false);
        }
        cmp.set('v.deniedFormalizeCheck', !editCreditBool);
        cmp.set('v.editCreditbool', editCreditBool);
        helper.setFalseRadioButton();
    },
    handleEditInternational: function(cmp, event, helper) {
        let editDebitBool = cmp.get('v.editDebitbool');
        let editCreditBool = cmp.get('v.editCreditbool');
        let editInternationalBool = cmp.get('v.editInternationalbool');
        if (editInternationalBool) {
            editInternationalBool = false;
        } else {
            editInternationalBool = true;
        }

        if (!editDebitBool || !editCreditBool || !editInternationalBool) {
            cmp.set('v.disableUpdateBtn', false);
            cmp.set('v.disableSaveEditBtn', true);
            cmp.set('v.deniedFormalizeCheck', true);
            cmp.set('v.deniedAuthorizeCheck', true);
        } else {
            cmp.set('v.disableUpdateBtn', true);
            cmp.set('v.disableSaveEditBtn', false);
            cmp.set('v.deniedFormalizeCheck', false);
            cmp.set('v.deniedAuthorizeCheck', false);
        }
        cmp.set('v.deniedFormalizeCheck', !editInternationalBool);
        cmp.set('v.editInternationalbool', editInternationalBool);
        helper.setFalseRadioButton();
    },
    handleEditDebitSimulation: function(cmp, event, helper) {
        let editDebitBoolSimulation = cmp.get('v.editDebitSimulationbool');
        let editCreditBoolSimulation = cmp.get('v.editCreditSimulationbool');
        let editInternationalBoolSimulation = cmp.get('v.editInternationalSimulationbool');

        if (editDebitBoolSimulation) {
            editDebitBoolSimulation = false;
        } else {
            editDebitBoolSimulation = true;
        }

        if (!editDebitBoolSimulation || !editCreditBoolSimulation || !editInternationalBoolSimulation) {
            cmp.set('v.disableUpdateSimulationBtn', false);
            cmp.set('v.disableSaveEditSimBtn', true);
            cmp.set('v.deniedFormalizeSimCheck', true);
            cmp.set('v.deniedAuthorizeSimCheck', true);
        } else {
            cmp.set('v.disableUpdateSimulationBtn', true);
            cmp.set('v.disableSaveEditSimBtn', false);
            cmp.set('v.deniedFormalizeSimCheck', false);
            cmp.set('v.deniedAuthorizeSimCheck', false);
        }
        cmp.set('v.editDebitSimulationbool', editDebitBoolSimulation);
        helper.setFalseRadioButtonSim();
    },
    handleEditCreditSimulation: function(cmp, event, helper) {
        let editDebitBoolSimulation = cmp.get('v.editDebitSimulationbool');
        let editCreditBoolSimulation = cmp.get('v.editCreditSimulationbool');
        let editInternationalBoolSimulation = cmp.get('v.editInternationalSimulationbool');
        if (editCreditBoolSimulation) {
            editCreditBoolSimulation = false;
        } else {
            editCreditBoolSimulation = true;
        }

        if (!editDebitBoolSimulation || !editCreditBoolSimulation || !editInternationalBoolSimulation) {
            cmp.set('v.disableUpdateSimulationBtn', false);
            cmp.set('v.disableSaveEditSimBtn', true);
            cmp.set('v.deniedFormalizeSimCheck', true);
            cmp.set('v.deniedAuthorizeSimCheck', true);
        } else {
            cmp.set('v.disableUpdateSimulationBtn', true);
            cmp.set('v.disableSaveEditSimBtn', false);
            cmp.set('v.deniedFormalizeSimCheck', false);
            cmp.set('v.deniedAuthorizeSimCheck', false);
        }
        cmp.set('v.deniedFormalizeSimCheck', !editCreditBoolSimulation);
        cmp.set('v.deniedAuthorizeSimCheck', !editCreditBoolSimulation);
        cmp.set('v.editCreditSimulationbool', editCreditBoolSimulation);
        helper.setFalseRadioButtonSim();
    },
    handleEditInternationalSimulation: function(cmp, event, helper) {
        let editDebitBoolSimulation = cmp.get('v.editDebitSimulationbool');
        let editCreditBoolSimulation = cmp.get('v.editCreditSimulationbool');
        let editInternationalBoolSimulation = cmp.get('v.editInternationalSimulationbool');
        if (editInternationalBoolSimulation) {
            editInternationalBoolSimulation = false;
        } else {
            editInternationalBoolSimulation = true;
        }

        if (!editDebitBoolSimulation || !editCreditBoolSimulation || !editInternationalBoolSimulation) {
            cmp.set('v.disableUpdateSimulationBtn', false);
            cmp.set('v.disableSaveEditSimBtn', true);
            cmp.set('v.deniedFormalizeSimCheck', true);
            cmp.set('v.deniedAuthorizeSimCheck', true);
        } else {
            cmp.set('v.disableUpdateSimulationBtn', true);
            cmp.set('v.disableSaveEditSimBtn', false);
            cmp.set('v.deniedFormalizeSimCheck', false);
            cmp.set('v.deniedAuthorizeSimCheck', false);
        }
        cmp.set('v.deniedFormalizeSimCheck', !editInternationalBoolSimulation);
        cmp.set('v.deniedAuthorizeSimCheck', !editInternationalBoolSimulation);
        cmp.set('v.editInternationalSimulationbool', editInternationalBoolSimulation);
        helper.setFalseRadioButtonSim();
    },
    handleSave: function(cmp, event, helper) {
        let dpmx = cmp.get('v.dynamicPricing');
        cmp.set("v.disableSubmitBtn", false);
        let resultRates = cmp.get('v.resultRates');
        var updDebit = 0;
        var updCredit = 0;
        var updInternational = 0;
        let editDebitBool = cmp.get('v.editDebitbool');
        let validateDebitMap;
        let editCreditBool = cmp.get('v.editCreditbool');
        let validateCreditMap;
        let editInternationalBool = cmp.get('v.editInternationalbool');
        let validateInterMap;
        let profitability = cmp.get('v.profitability');
        let profitAmount = cmp.get('v.profitAmount');
        let validate = false;
        if (!editDebitBool) {
            validateDebitMap = helper.validateDebitUpdateValues(cmp, helper);
            if (validateDebitMap.get("validateValuesBool")) {
                updDebit = cmp.find("edtDebito").get("v.value");
                validate = true;
            } else if (validateDebitMap.get("dontSaveBool")) {
                updDebit = dpmx.CustomAcquiredFeesDebit__c;
            } else {
                updDebit = 0;
            }
        }
        if (!editCreditBool) {
            validateCreditMap = helper.validateCreditUpdateValues(cmp, helper);
            if (validateCreditMap.get("validateValuesBool")) {
                updCredit = cmp.find("edtCredit").get("v.value");
                validate = true;
            } else if (validateCreditMap.get("dontSaveBool")) {
                updCredit = dpmx.CustomAcquiredFeesCredit__c;
            } else {
                updCredit = 0;
            }

        }
        if (!editInternationalBool) {
            validateInterMap = helper.validateInterUpdateValues(cmp, helper);
            if (validateInterMap.get("validateValuesBool")) {
                if (validateInterMap.get("validateInterBool")) {
                    updInternational = cmp.find("edtInternational").get("v.value");
                } else {
                    if (validateInterMap.get("dontSaveBool")) {
                        updInternational = dpmx.CustomAcquiredFeesInternational__c;
                    } else {
                        updInternational = 0;
                    }
                }
                validate = true;
            }
        }

        if (validate) {
            if (!dpmx.firstCheckTaxes__c) {
                let attr = {
                    'dynamicId': cmp.get('v.recordId')
                };
                helper.loadComponent(cmp, event, helper, 'DPMX_VerifyRates', attr).then($A.getCallback(newComponent => {
                    let body = [];
                    body.push(newComponent);
                    cmp.set('v.body', body);
                }));
            }
            var action = cmp.get('c.updateFields');
            action.setParams({
                'recordId': cmp.get('v.recordId'),
                'result': resultRates,
                'debit': updDebit,
                'decimalBoolean': !editDebitBool,
                'credit': updCredit,
                'creditBoolean': !editCreditBool,
                'international': updInternational,
                'internationalBoolean': !editInternationalBool,
                'rentaibilidad': profitability,
                'bai': profitAmount,
                'isSimulated': false
            })
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === 'SUCCESS') {
                    var result = response.getReturnValue();
                    cmp.set('v.dynamicPricing', result.dynamicPricing);
                    helper.profitabilityCalculateRates(cmp, helper);
                    let appEvent = $A.get('e.c:DPMX_SimulatorRefresh_evt');
                    appEvent.setParams({
                        'recordId': cmp.get('v.recordId')
                    });
                    appEvent.fire();
                }
            });
            $A.enqueueAction(action);
            cmp.set('v.editCreditbool', true);
            cmp.set('v.editDebitbool', true);
            cmp.set('v.editInternationalbool', true);
            cmp.set('v.disableUpdateBtn', true);
            cmp.set('v.disableSaveEditBtn', false);
        }
        helper.setFalseRadioButton();
    },
    handleSaveSimulation: function(cmp, event, helper) {
        let dpmx = cmp.get('v.dynamicPricing');
        cmp.set("v.disableUpdateSimulationBtn", false);
        let resultRatesSimulation = cmp.get('v.resultRatesSimulation');
        var updDebit = 0;
        var updCredit = 0;
        var updInternational = 0;
        let editDebitBool = cmp.get('v.editDebitSimulationbool');
        let validateDebitMap;
        let editCreditBool = cmp.get('v.editCreditSimulationbool');
        let validateCreditMap;
        let editInternationalBool = cmp.get('v.editInternationalSimulationbool');
        let validateInterMap;
        let validate = false;
        if (!editDebitBool) {
            validateDebitMap = helper.validateDebitUpdateSimulationValues(cmp, helper);
            if (validateDebitMap.get("validateValuesBool")) {
                updDebit = cmp.find("edtSimulationDebito").get("v.value");
                validate = true;
            } else if (validateDebitMap.get("dontSaveBool")) {
                updDebit = dpmx.CustomAcquiredFeesDebit__c;
            } else {
                updDebit = 0;
            }
        }
        if (!editCreditBool) {
            validateCreditMap = helper.validateCreditUpdateSimulationValues(cmp, helper);
            if (validateCreditMap.get("validateValuesBool")) {
                updCredit = cmp.find("edtSimulationCredit").get("v.value");
                validate = true;
            } else if (validateCreditMap.get("dontSaveBool")) {
                updCredit = dpmx.CustomAcquiredFeesCredit__c;
            } else {
                updCredit = 0;
            }
        }
        if (!editInternationalBool) {
            validateInterMap = helper.validateInterUpdateSimulationValues(cmp, helper);
            if (validateInterMap.get("validateValuesBool")) {
                if (validateInterMap.get("validateInterBool")) {
                    updInternational = cmp.find("edtSimulationInternational").get("v.value");
                } else {
                    if (validateInterMap.get("dontSaveBool")) {
                        updInternational = dpmx.CustomAcquiredFeesInternational__c;
                    } else {
                        updInternational = 0;
                    }
                }
                validate = true;
            }
        }
        if (validate) {
            let profitAmountSimulation = cmp.get('v.profitAmountSimulation');
            let profitabilitySimulation = cmp.get('v.profitabilitySimulation');
            if (!dpmx.firstCheckTaxes__c) {
                let attr = {
                    'dynamicId': cmp.get('v.recordId')
                };
                helper.loadComponent(cmp, event, helper, 'DPMX_VerifyRates', attr).then($A.getCallback(newComponent => {
                    let body = [];
                    body.push(newComponent);
                    cmp.set('v.body', body);
                }));
            }
            var action = cmp.get('c.updateFields');
            action.setParams({
                'recordId': cmp.get('v.recordId'),
                'result': resultRatesSimulation,
                'debit': updDebit,
                'decimalBoolean': !editDebitBool,
                'credit': updCredit,
                'creditBoolean': !editCreditBool,
                'international': updInternational,
                'internationalBoolean': !editInternationalBool,
                'rentaibilidad': profitabilitySimulation,
                'bai': profitAmountSimulation,
                'isSimulated': true
            })
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === 'SUCCESS') {
                    var result = response.getReturnValue();
                    cmp.set('v.dynamicPricing', result.dynamicPricing);
                    //helper.profitabilityCalculateRatesSimulation(cmp, event, helper);
                    //helper.doInit(cmp, event, helper);
                }
            });
            $A.enqueueAction(action);
            cmp.set('v.editCreditSimulationbool', true);
            cmp.set('v.editDebitSimulationbool', true);
            cmp.set('v.editInternationalSimulationbool', true);
            cmp.set('v.disableUpdateSimulationBtn', true);
        }
        cmp.set('v.disableSaveEditSimBtn', false);
        helper.setFalseRadioButtonSim();
    },
    showToast: function(type, title, message) {
        var toastEvent = $A.get('e.force:showToast');
        toastEvent.setParams({
            title: title,
            message: message,
            duration: 5000,
            key: 'info_alt',
            type: type,
            mode: 'dismissible'
        });
        toastEvent.fire();
    },
    resultRates: function(cmp, helper) {
        var debitRates = cmp.get('v.debit');
        var creditRates = cmp.get('v.credit');
        var InternationalRates = cmp.get('v.international');
        var interchanges = cmp.get('v.interchangeRates');
        var optimRange = 1.25;
        let profitabilityRates = cmp.get('v.profitability');

        //Si los valores de la tasa son igales o superoires a las de intercambio (interchangerate) multiplicado por 1.25 es optmio 
        switch (true) {
            case (debitRates >= cmp.get('v.interchangeRates.debit') && debitRates <= cmp.get('v.discountRates.debit') && creditRates >= cmp.get('v.interchangeRates.credit') && creditRates <= cmp.get('v.discountRates.credit') && InternationalRates >= cmp.get('v.interchangeRates.international') && InternationalRates <= cmp.get('v.discountRates.international')):
                if ((interchanges.debit*optimRange <= debitRates) && (interchanges.credit*optimRange <= creditRates) && (interchanges.international*optimRange <= InternationalRates)) {
                    cmp.set('v.resultRates', 'Optimo');
                } else if (profitabilityRates > 0) {
                    cmp.set('v.resultRates', 'Bueno');
                } else {
                    cmp.set('v.resultRates', 'Break even');
                }
                break;
            default:
                cmp.set('v.resultRates', 'Simulación');
                break;
        }
    },
    resultRatesSimulation: function(cmp, event, helper) {
        var debitRates = cmp.get('v.debitSimulation');
        var creditRates = cmp.get('v.creditSimulation');
        var InternationalRates = cmp.get('v.internationalSimulation');
        let profitabilityRates = cmp.get('v.profitabilitySimulation');
        var interchanges = cmp.get('v.interchangeRates');
        var optimRange = 1.25;

        switch (true) {
            case (profitabilityRates != 0 || debitRates != 0 || creditRates != 0 || InternationalRates != 0):
                //Si los valores de la tasa son igales o superoires a las de intercambio (interchangerate) multiplicado por 1.25 es optmio 
                if ((interchanges.debit*optimRange <= debitRates) && (interchanges.credit*optimRange <= creditRates) && (interchanges.international*optimRange <= InternationalRates)) {
                    cmp.set('v.resultRatesSimulation', 'Optimo');
                } else if (profitabilityRates > 0) {
                    cmp.set('v.resultRatesSimulation', 'Bueno');
                } else {
                    cmp.set('v.resultRatesSimulation', 'Break even');
                }
                break;
            default:
                cmp.set('v.resultRatesSimulation', 'Simulación');
                break;
        }
        helper.handleSaveSimulation(cmp, event, helper);
    },
    profitabilityCalculateRatesSimulation: function(cmp, event, helper) {
        var acquirerActivitiesWrapper = cmp.get('v.acquirerActivitiesWrapper');
        var discountRates = cmp.get('v.interchangeRates');
        var creditSimulation = cmp.get('v.creditSimulation');
        var debitSimulation = cmp.get('v.debitSimulation');
        var internationalSimulation = cmp.get('v.internationalSimulation');
        var gastoTotal = cmp.get('v.dynamicPricing.gastoTotal__c');
        var action = cmp.get('c.updateRates');
        var result;
        action.setParams({
            'recordId': cmp.get('v.recordId'),
            'acquirerActivitiesWrapper': acquirerActivitiesWrapper,
            'discountRates': discountRates,
            'checkbox': false,
            'credit': creditSimulation,
            'debit': debitSimulation,
            'international': internationalSimulation,
            'isSimulated': true,
            'totalAmountSimulated': gastoTotal
        })
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                result = response.getReturnValue();
                if (result.error) {
                    helper.showToast('Error', 'error', result.error);
                } else if (result.success) {
                    cmp.set('v.profitabilitySimulation', result.profitability);
                    cmp.set('v.profitAmountSimulation', result.profitAmount);
                    helper.resultRatesSimulation(cmp, event, helper);                }
            } else if (state === 'ERROR') {
                var errors4 = response.getError();
                if (errors4) {
                    if (errors4[0] && errors4[0].message) {
                        helper.showToast('Error', 'error', errors4[0].message);
                    }
                } else {
                    helper.showToast('Error', 'Error', 'Unknown error');
                }
            }
        });
        $A.enqueueAction(action);
    },
    profitabilityCalculateRates: function(cmp, helper) {
        var acquirerActivitiesWrapper = cmp.get('v.acquirerActivitiesWrapper');
        var discountRates = cmp.get('v.interchangeRates');
        var credit = cmp.get('v.credit');
        var debit = cmp.get('v.debit');
        var international = cmp.get('v.international');
        var gastoTotal = acquirerActivitiesWrapper.expenses.totalAmount.amount;
        var action = cmp.get('c.updateRates');
        var result;
        action.setParams({
            'recordId': cmp.get('v.recordId'),
            'acquirerActivitiesWrapper': acquirerActivitiesWrapper,
            'discountRates': discountRates,
            'checkbox': true,
            'credit': credit,
            'debit': debit,
            'international': international,
            'isSimulated': false,
            'totalAmountSimulated': gastoTotal

        })
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                result = response.getReturnValue();
                if (result.error) {
                    helper.showToast('Error', 'error', result.error);
                } else if (result.success) {
                    cmp.set('v.profitability', result.profitability);
                    cmp.set('v.profitAmount', result.profitAmount);
                    helper.resultRates(cmp, helper);
                }
            } else if (state === 'ERROR') {
                var errors4 = response.getError();
                if (errors4) {
                    if (errors4[0] && errors4[0].message) {
                        helper.showToast('Error', 'error', errors4[0].message);
                    }
                } else {
                    helper.showToast('Error', 'Error', 'Unknown error');
                }
            }
        });
        $A.enqueueAction(action);
    },
    customerIncomeRates: function(cmp, helper) {
        var incomeGross = helper.incomeGrossRates(cmp);
        var CmsnBj = cmp.get('v.acquirerActivitiesWrapper.commission.billing.amount');
        var CmsnRC = cmp.get('v.acquirerActivitiesWrapper.commission.cellnet.amount');
        var RentaTPVs = cmp.get('v.acquirerActivitiesWrapper.commission.extraBilling.amount');
        var customerIncome = incomeGross + CmsnBj + CmsnRC + RentaTPVs;
        return customerIncome;
    },
    incomeGrossRates: function(cmp) {
        var GS = cmp.get('v.acquirerActivitiesWrapper.isGS');
        var incomeGross;
        var cuotaDebit = cmp.get('v.debit');
        var tasaCredit = cmp.get('v.credit');
        var facInt = cmp.get('v.acquirerActivitiesWrapper.billing.international.amount');
        var tasaInt = cmp.get('v.international');
        var facCAjeno = cmp.get('v.acquirerActivitiesWrapper.billing.credit.thirdParty.amount');
        var facCPropio = cmp.get('v.acquirerActivitiesWrapper.billing.credit.own.amount');
        var transDebAjeno = cmp.get('v.acquirerActivitiesWrapper.transaction_y.debit.thirdParty');
        var transDebPropio = cmp.get('v.acquirerActivitiesWrapper.transaction_y.debit.own');
        if (GS === 'true') {
            incomeGross = ((transDebAjeno + transDebPropio) * cuotaDebit) + ((facCAjeno + facCPropio) * tasaCredit) + (facInt * tasaInt);
        } else {
            var facDAjeno = cmp.get('v.acquirerActivitiesWrapper.billing.debit.thirdParty.amount');
            var facDPropio = cmp.get('v.acquirerActivitiesWrapper.billing.debit.own.amount');
            var discountMaxDebit = cmp.get('v.acquirerActivitiesWrapper.discount.monetaryCeiling.amount');
            var descDebAjeno = facDAjeno * cuotaDebit;
            var descDebPropiop = facDPropio * cuotaDebit;

            if ((descDebAjeno / transDebAjeno) > discountMaxDebit) {
                descDebAjeno = facDAjeno * cuotaDebit;
            }
            if ((descDebPropiop / transDebAjeno) > discountMaxDebit) {
                descDebPropiop = facDAjeno * cuotaDebit;
            }
            incomeGross = (descDebAjeno + descDebPropiop) + ((facCAjeno + facCPropio) * tasaCredit) + (facInt * tasaInt);
        }
        return incomeGross;
    },
    customerExpensesRates: function(cmp, helper) {
        var expensesTotal = cmp.get('v.acquirerActivitiesWrapper.expenses.totalAmount.amount');
        var expensesExchange = helper.expensesExchangeRates(cmp);
        var expensesMIT = cmp.get('v.acquirerActivitiesWrapper.expenses.mit.amount');
        //Preguntar si los gastos eBind estan includidos en los gastos MIT.
        var expenseseBind = 0;
        var customerIncome = expensesTotal + expensesExchange + expensesMIT + expenseseBind;
        return customerIncome;
    },
    expensesExchangeRates: function(cmp) {
        var GS = cmp.get('v.acquirerActivitiesWrapper.isGS');
        var expensesExchange;
        var transDebAjeno = cmp.get('v.acquirerActivitiesWrapper.transaction_y.debit.thirdParty');
        var transDebPropio = cmp.get('v.acquirerActivitiesWrapper.transaction_y.debit.own');
        var debExchenge = cmp.get('v.interchangeRates.debit');
        var facCAjeno = cmp.get('v.acquirerActivitiesWrapper.billing.credit.thirdParty.amount');
        var facCPropio = cmp.get('v.acquirerActivitiesWrapper.billing.credit.own.amount');
        var credExchenge = cmp.get('v.interchangeRates.credit');
        var facInt = cmp.get('v.acquirerActivitiesWrapper.billing.international.amount');
        var interExchenge = cmp.get('v.interchangeRates.international');
        if (GS === 'true') {
            expensesExchange = ((transDebAjeno + transDebPropio) * debExchenge) + ((facCAjeno + facCPropio) * credExchenge) + (facInt * interExchenge);
        } else {
            var discountMaxDebit = 13.5;
            var facDAjeno = cmp.get('v.acquirerActivitiesWrapper.billing.debit.thirdParty.amount');
            var facDPropio = cmp.get('v.acquirerActivitiesWrapper.billing.debit.own.amount');
            var interDa = facDAjeno * debExchenge;
            var interDp = facDPropio * debExchenge;
            if ((interDa / transDebAjeno) > discountMaxDebit) {
                interDa = discountMaxDebit * transDebAjeno;
            }
            if ((interDp / transDebPropio) > discountMaxDebit) {
                interDp = discountMaxDebit * transDebPropio;
            }
            expensesExchange = (interDa + interDp) + ((facCAjeno + facCPropio) * credExchenge) + (facInt * interExchenge);
        }

        return expensesExchange;
    },
    "validateDebitUpdateValues": function(cmp, helper) {
        let validateValuesBool = true;
        let validateDebitBool = true;
        let dontSaveBool = false;
        let validateMap = new Map();
        var updDebit = cmp.find("edtDebito").get("v.value");
        if (updDebit < cmp.get('v.interchangeRates.debit') || updDebit > cmp.get('v.discountRates.debit')) {
            cmp.find("edtDebito").set('v.value', cmp.get('v.dynamicPricing.CustomAcquiredFeesDebit__c'));
            validateValuesBool = false;
            validateDebitBool = false;
        }
        if (!validateValuesBool) {
            helper.showToast('Error', 'No se pudo actualizar.', 'Datos fuera de rango.');
            dontSaveBool = true;
        }
        validateMap.set("validateValuesBool", validateValuesBool);
        validateMap.set("validateDebitBool", validateDebitBool);
        validateMap.set("dontSaveBool", dontSaveBool);
        return validateMap;
    },
    "validateCreditUpdateValues": function(cmp, helper) {
        let validateValuesBool = true;
        let validateCreditBool = true;
        let dontSaveBool = false;
        let validateMap = new Map();
        var updCredit = cmp.find("edtCredit").get("v.value");

        if (updCredit < cmp.get('v.interchangeRates.credit') || updCredit > cmp.get('v.discountRates.credit')) {
            cmp.find("edtCredit").set('v.value', cmp.get('v.dynamicPricing.CustomAcquiredFeesCredit__c'));
            validateValuesBool = false;
            validateCreditBool = false;
        }

        if (!validateValuesBool) {
            helper.showToast('Error', 'No se pudo actualizar.', 'Datos fuera de rango.');
            dontSaveBool = true;
        }

        validateMap.set("validateValuesBool", validateValuesBool);
        validateMap.set("validateCreditBool", validateCreditBool);
        validateMap.set("dontSaveBool", dontSaveBool);
        return validateMap;
    },
    "validateInterUpdateValues": function(cmp, helper) {
        let validateValuesBool = true;
        let validateInterBool = true;
        let dontSaveBool = false;
        let validateMap = new Map();
        var updInternational = cmp.find("edtInternational").get("v.value");

        if (updInternational < cmp.get('v.interchangeRates.international') || updInternational > cmp.get('v.discountRates.international')) {
            cmp.find("edtInternational").set('v.value', cmp.get('v.dynamicPricing.CustomAcquiredFeesInternational__c'));
            validateValuesBool = false;
            validateInterBool = false;
        }

        if (!validateValuesBool) {
            helper.showToast('Error', 'No se pudo actualizar.', 'Datos fuera de rango.');
            dontSaveBool = true;
        }

        validateMap.set("validateValuesBool", validateValuesBool);
        validateMap.set("validateInterBool", validateInterBool);
        validateMap.set("dontSaveBool", dontSaveBool);
        return validateMap;
    },
    "validateDebitUpdateSimulationValues": function(cmp, helper) {
        let validateValuesBool = true;
        let validateDebitBool = true;
        let dontSaveBool = false;
        let validateMap = new Map();
        var updDebit = cmp.find("edtSimulationDebito").get("v.value");
        if (updDebit < cmp.get('v.interchangeRates.debit') || updDebit > cmp.get('v.discountRates.debit')) {
            cmp.find("edtSimulationDebito").set('v.value', cmp.get('v.dynamicPricing.CustomAcquiredFeesDebit__c'));
            validateValuesBool = false;
            validateDebitBool = false;
        }
        if (!validateValuesBool) {
            helper.showToast('Error', 'No se pudo actualizar.', 'Datos fuera de rango.');
            dontSaveBool = true;
        }
        validateMap.set("validateValuesBool", validateValuesBool);
        validateMap.set("validateDebitBool", validateDebitBool);
        validateMap.set("dontSaveBool", dontSaveBool);
        return validateMap;
    },
    "validateCreditUpdateSimulationValues": function(cmp, helper) {
        let validateValuesBool = true;
        let validateCreditBool = true;
        let dontSaveBool = false;
        let validateMap = new Map();
        var updCredit = cmp.find("edtSimulationCredit").get("v.value");

        if (updCredit < cmp.get('v.interchangeRates.credit') || updCredit > cmp.get('v.discountRates.credit')) {
            cmp.find("edtSimulationCredit").set('v.value', cmp.get('v.dynamicPricing.CustomAcquiredFeesCredit__c'));
            validateValuesBool = false;
            validateCreditBool = false;
        }

        if (!validateValuesBool) {
            helper.showToast('Error', 'No se pudo actualizar.', 'Datos fuera de rango.');
            dontSaveBool = true;
        }

        validateMap.set("validateValuesBool", validateValuesBool);
        validateMap.set("validateCreditBool", validateCreditBool);
        validateMap.set("dontSaveBool", dontSaveBool);
        return validateMap;
    },
    "validateInterUpdateSimulationValues": function(cmp, helper) {
        let validateValuesBool = true;
        let validateInterBool = true;
        let dontSaveBool = false;
        let validateMap = new Map();
        var updInternational = cmp.find("edtSimulationInternational").get("v.value");

        if (updInternational < cmp.get('v.interchangeRates.international') || updInternational > cmp.get('v.discountRates.international')) {
            cmp.find("edtSimulationInternational").set('v.value', cmp.get('v.dynamicPricing.CustomAcquiredFeesInternational__c'));
            validateValuesBool = false;
            validateInterBool = false;
        }

        if (!validateValuesBool) {
            helper.showToast('Error', 'No se pudo actualizar.', 'Datos fuera de rango.');
            dontSaveBool = true;
        }

        validateMap.set("validateValuesBool", validateValuesBool);
        validateMap.set("validateInterBool", validateInterBool);
        validateMap.set("dontSaveBool", dontSaveBool);
        return validateMap;
    },
    "validateUpdateValuesSimulation": function(cmp, helper) {
        let validateValuesBool = true;
        var updDebit = cmp.find("edtSimulationDebito").get("v.value");
        var updCredit = cmp.find("edtSimulationCredit").get("v.value");
        var updInternational = cmp.find("edtSimulationInternational").get("v.value");
        if (updDebit > cmp.get('v.interchangeRates.debit') || updDebit < cmp.get('v.discountRates.debit')) {
            cmp.find("edtSimulationDebito").set('v.value', cmp.get('v.dynamicPricing.CustomSimulatedDebit__c'));
            validateValuesBool = false;
        }
        if (validateValuesBool) {
            if (updCredit > cmp.get('v.interchangeRates.credit') || updCredit < cmp.get('v.discountRates.credit')) {
                cmp.find("edtSimulationCredit").set('v.value', cmp.get('v.dynamicPricing.CustomSimulatedCredit__c'));
                validateValuesBool = false;
            }
        }
        if (validateValuesBool) {
            if (updInternational > cmp.get('v.interchangeRates.international') || updInternational < cmp.get('v.discountRates.international')) {
                cmp.find("edtSimulationInternational").set('v.value', cmp.get('v.dynamicPricing.CustomSimulatedInternational__c'));
                validateValuesBool = false;
            }
        }

        if (!validateValuesBool) {
            helper.showToast('Error', 'No se pudo actualizar.', 'Datos fuera de rango.');

        }
        return validateValuesBool;
    },
    commisionTPVCalculator: function(cmp) {
        var nTPV = cmp.get('v.dynamicPricing.Sim_Terminal_Id__c');
        var Sim_Fees_ExtraBilling_Checkbox__c = cmp.get('v.dynamicPricing.Sim_Fees_ExtraBilling_Checkbox__c');
        var commisionTPV = 0;
        var commisionTPVOpt = 0;
        if(Sim_Fees_ExtraBilling_Checkbox__c && nTPV > 0){
            commisionTPV = (nTPV - 1) * $A.get("$Label.c.DPMX_CommissionTPV");
        }
        cmp.set('v.commisionTPV', commisionTPV);
        if( nTPV > 0){
            commisionTPVOpt = (nTPV - 1) * $A.get("$Label.c.DPMX_CommissionTPV");
        }
        cmp.set('v.commisionTPVOpp', commisionTPVOpt);
    },
    commisionRedCelCalculator: function(cmp) {
        let cellnet_Checkbox = cmp.get('v.dynamicPricing.Sim_Fees_Cellnet_Checkbox__c')
        if (cellnet_Checkbox) {
            cmp.set('v.commisionRedCel', 0.42);
        } else {
            cmp.set('v.commisionRedCel', 0);
        }
        cmp.set('v.commisionRedCelularOpp', 0.42);
    },
    commisionBajFacalculator: function(cmp) {
        let billing_Checkbox = cmp.get('v.dynamicPricing.Sim_Fees_Billing_Checkbox__c')
        if (billing_Checkbox) {
            cmp.set('v.commisionBajFac', 416.44);
        } else {
            cmp.set('v.commisionBajFac', 0);
        }
        cmp.set('v.commisionBajaFactOpp', 416.44);
    },
    handleSaveFamily: function(cmp, event, helper) {
        helper.waiting(cmp);
        var action = cmp.get('c.saveFamily');
        var familia = cmp.find("existingSubs").get("v.value");
        var famMap = cmp.get('v.razonSocialMp');
        action.setParams({
            'recordId': cmp.get('v.recordId'),
            'familia': familia,
            'familiaId': famMap[familia]
        })
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                var result = response.getReturnValue();
                cmp.set('v.dynamicPricing', result.dynamicPricing);
                helper.doInit(cmp, event, helper);
            }
            helper.doneWaiting(cmp);
        });
        $A.enqueueAction(action);
    },
    handleCheckODT: function(cmp) {
        var impresionODT = cmp.find("impresionODT").get("v.checked");
        var firmaClienteODT = cmp.find("firmaClienteODT").get("v.checked");
        var scanODT = cmp.find("scanODT").get("v.checked");
        var fimaRepresODT = cmp.find("fimaRepresODT").get("v.checked");
        if (impresionODT && firmaClienteODT && scanODT && fimaRepresODT) {
            cmp.set("v.isODTcheck", false);
        } else {
            cmp.set("v.isODTcheck", true);
        }
    },
    handleSendTasas: function(cmp, event, helper) {
        var dynamicPricing = cmp.get('v.dynamicPricing');
        let attr = {
            'dynamicPricing': dynamicPricing
        };
        helper.loadComponent(cmp, event, helper, 'DPMX_ODT', attr).then($A.getCallback(newComponent => {
            let body = [];
            body.push(newComponent);
            cmp.set('v.body', body);
        }));
    },
    handleSendReport: function(cmp, event, helper) {
        let attr = {
            'recordId': cmp.get('v.recordId'),
            'isLastMonthTab': cmp.get('v.isLastMonthTab'),
            'isSimulationTab': cmp.get('v.isSimulationTab'),
            'sendConditionLst': cmp.get('v.sendConditionLst'),
            'sendSimulationLst': cmp.get('v.sendSimulationLst')

        };
        helper.loadComponent(cmp, event, helper, 'DPMX_SendReport', attr).then($A.getCallback(newComponent => {
            let body = [];
            body.push(newComponent);
            cmp.set('v.body', body);
        }));
    },
    handleTabSelected: function(cmp, event, helper) {
        cmp.set('v.isLastMonthTab', true);
        cmp.set('v.isSimulationTab', false);
        helper.handleSaveInfoToSendReport(cmp, event, helper);
    },
    handleTabSimulationSelected: function(cmp, event, helper) {
        cmp.set('v.isLastMonthTab', false);
        cmp.set('v.isSimulationTab', true);
        helper.handleSaveInfoToSendReport(cmp, event, helper);
    },
    handleTabUpdateTasasSelected: function(cmp, event, helper) {
        cmp.set('v.isLastMonthTab', false);
        cmp.set('v.isSimulationTab', false);
        helper.handleSaveInfoToSendReport(cmp, event, helper);
    },
    handleSaveInfoToSendReport: function(cmp, event, helper) {
        if (cmp.get('v.isfirstTime')) {
            cmp.set('v.isfirstTime', false);
        } else {
            var dp = cmp.get('v.dynamicPricing');
            var isGs = false;
            if(dp.familia_AcquiererCategories_Id__c == '13'){
                isGs = true;
            }
            helper.handleSaveInfo(cmp, event, helper, isGs);
        }
    },
    takeTasaLastMonth: function(cmp, isGs) {
        var tasaLastMontMap = new Map();
        var result = '';
        var debit = 0;
        var credit = 0;
        var international = 0;
        var baiLastMonth = 0;
        var rentLastMonth = 0;
        const rentAndBai = cmp.get('v.sendConditionLst')[0].fees;
        const conditionList = cmp.get('v.sendConditionLst')[0].fees.itemizeFees;
        cmp.set('v.sectionLst', conditionList.fees);
        var itemsFees = cmp.get('v.sendConditionLst')[0].fees.itemizeFees;
        if (!cmp.get('v.isTasaSelect')) {
            result = cmp.get('v.sendConditionLst')[0].scenarioType;
            for (let i = 0; i < itemsFees.length; i++) {
                switch (itemsFees[i].feeType) {
                    case 'DEBIT':
                        if (isGs) {
                            debit = itemsFees[i].itemizeFeeUnit.amount;
                        } else {
                            debit = itemsFees[i].itemizeFeeUnit.value;
                        }
                        break;
                    case 'CREDIT':
                        credit = itemsFees[i].itemizeFeeUnit.value;
                        break;
                    case 'INTERNATIONAL':
                        international = itemsFees[i].itemizeFeeUnit.value;
                        break;
                }
                baiLastMonth = rentAndBai.profitability.amount.amount;
                rentLastMonth = rentAndBai.profitability.percentage;
            }
        } else {
            result = cmp.get('v.resultRates');
            debit = cmp.get('v.debit');
            credit = cmp.find("edtCredit").get("v.value");
            international = cmp.find("edtInternational").get("v.value");
            baiLastMonth = cmp.get('v.profitAmount');
            rentLastMonth = cmp.get('v.profitability');
        }
        tasaLastMontMap.set('result', result);
        tasaLastMontMap.set('debit',debit);
        tasaLastMontMap.set('credit',credit);
        tasaLastMontMap.set('international',international);
        tasaLastMontMap.set('baiLastMonth',baiLastMonth);
        tasaLastMontMap.set('rentLastMonth',rentLastMonth);
        return tasaLastMontMap;
    },
    takeTasaSim: function(cmp, helper, isGs) {
        var validate = cmp.get('v.validateresponseWraper');
        var index = cmp.get("v.indexSimulation");
        var resultSim = '';
        var debitSim = 0;
        var creditSim = 0;
        var internationalSim = 0;
        var baiSim = 0;
        var rentSim = 0;
        var tasaSimMap = new Map();
        let tasaMap = new Map();
        if(validate !== null){
            validate.proposed.forEach((element) => {
                if(index == element.idOrder){
                     element.rate.itemizeRates.forEach((value) => {
                        switch (true) {
                            case (value.idOrder === 0):
                                if (isGs) {
                                    tasaMap.set("debitSim", value.itemizeRatesUnit.amount);
                                } else {
                                    tasaMap.set("debitSim", value.itemizeRatesUnit.percentage);
                                }
                                break;
                            case (value.idOrder == 1):
                                tasaMap.set("creditSim", value.itemizeRatesUnit.percentage);
                                break;
                            case (value.idOrder == 2):
                                tasaMap.set("internationalSim", value.itemizeRatesUnit.percentage);
                                break;
                            case (value.idOrder == 3):
                                tasaMap.set("rentSim", value.itemizeRatesUnit.percentage);
                                break;
                        }
                    });
                    tasaMap.set("resultSim", element.scenaryType);
                    tasaMap.set("baiSim", element.amount.amount);
                    debitSim = tasaMap.get('debitSim');
                    creditSim = tasaMap.get('creditSim');
                    internationalSim = tasaMap.get('internationalSim');
                    rentSim = tasaMap.get('rentSim');
                    resultSim = tasaMap.get('resultSim');
                    baiSim = tasaMap.get('baiSim');
                }else if (index == 5) {
                    resultSim = cmp.get('v.resultRatesSimulation');
                    debitSim = cmp.get("v.debitSimulation");
                    creditSim = cmp.find("edtSimulationCredit").get("v.value");
                    internationalSim = cmp.find("edtSimulationInternational").get("v.value");
                    rentSim = cmp.get("v.profitabilitySimulation");
                    baiSim = cmp.get("v.profitAmountSimulation");
                }
            });
        }
        tasaSimMap.set('resultSim', resultSim);
        tasaSimMap.set('debitSim', debitSim);
        tasaSimMap.set('creditSim', creditSim);
        tasaSimMap.set('internationalSim', internationalSim);
        tasaSimMap.set('baiSim', baiSim);
        tasaSimMap.set('rentSim', rentSim);
        return tasaSimMap;
    },
    handleSaveInfo: function(cmp, event, helper, isGs) {
            var result = '';
            var debit = 0;
            var credit = 0;
            var international = 0;
            var baiLastMonth = 0;
            var rentLastMonth = 0;
            var tasaLastMontMap = new Map();
            var resultSim = '';
            var debitSim = 0;
            var creditSim = 0;
            var internationalSim = 0;
            var baiSim = 0;
            var rentSim = 0;
            var tasaSimMap = new Map();
            var action = cmp.get('c.updateInfoToSendReport');
            var isBreakEvenAccepted = false;
            var isBreakEvenSimAccepted = false;
            var dynamicPricing = cmp.get('v.dynamicPricing');
            //Buscar la tasa de last month
            if(dynamicPricing.isCustom__c){
                //Buscar la tasa de simulacion
                tasaSimMap = helper.takeTasaSim(cmp, helper, isGs);
                resultSim = tasaSimMap.get('resultSim');
                debitSim = tasaSimMap.get('debitSim');
                creditSim = tasaSimMap.get('creditSim');
                internationalSim = tasaSimMap.get('internationalSim');
                baiSim = tasaSimMap.get('baiSim');
                rentSim = tasaSimMap.get('rentSim');
            }else{
                tasaLastMontMap = helper.takeTasaLastMonth(cmp, isGs);
                result = tasaLastMontMap.get('result');
                debit = tasaLastMontMap.get('debit');
                credit = tasaLastMontMap.get('credit');
                international = tasaLastMontMap.get('international');
                baiLastMonth = tasaLastMontMap.get('baiLastMonth');
                rentLastMonth = tasaLastMontMap.get('rentLastMonth');
                //Buscar la tasa de simulacion
                tasaSimMap = helper.takeTasaSim(cmp, helper, isGs);
                resultSim = tasaSimMap.get('resultSim');
                debitSim = tasaSimMap.get('debitSim');
                creditSim = tasaSimMap.get('creditSim');
                internationalSim = tasaSimMap.get('internationalSim');
                baiSim = tasaSimMap.get('baiSim');
                rentSim = tasaSimMap.get('rentSim');
            }
            action.setParams({
                'recordId': cmp.get('v.recordId'),
                'isLastMonthTab': cmp.get('v.isLastMonthTab'),
                'isSimulationTab': cmp.get('v.isSimulationTab'),
                'result': result,
                'debitLastMonth': debit.toFixed(2),
                'CreditLastMonth': credit.toFixed(2),
                'IntLastMonth': international.toFixed(2),
                'baiLastMonth': baiLastMonth,
                'rentLastMonth': rentLastMonth,
                'resultSim': resultSim,
                'debitSim': debitSim.toFixed(2),
                'creditSim': creditSim.toFixed(2),
                'interSim': internationalSim.toFixed(2),
                'rentSim': rentSim,
                'baiSim': baiSim

            })
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === 'SUCCESS') {
                    var retMap = response.getReturnValue();
                    isBreakEvenAccepted = retMap.isBreakEvenAccepted;
                    isBreakEvenSimAccepted = retMap.isBreakEvenSimAccepted;
                    //Flujo Ultimo mes de cliente
                    if (result != null && (result === 'BREAK_EVEN' || result === 'Minimo viable')) {
                        cmp.set('v.deniedFormalizeCheck', !isBreakEvenAccepted);
                        cmp.set('v.deniedAuthorizeCheck', isBreakEvenAccepted);
                        cmp.set('v.disableAuthBtn', true);
                    }else {
                        cmp.set('v.deniedFormalizeCheck', false);
                        cmp.set('v.deniedAuthorizeCheck', true);
                        cmp.set('v.disableAuthBtn', false);
                    } 
                    //Flujo simulacion
                    if (resultSim != null && (resultSim === 'BREAK_EVEN' || resultSim === 'Break even' || resultSim === 'Minimo viable')) {
                        cmp.set('v.deniedFormalizeSimCheck', !isBreakEvenSimAccepted);
                        cmp.set('v.deniedAuthorizeSimCheck', isBreakEvenSimAccepted);
                        cmp.set('v.disableAuthSimulationBtn', true);
                    } else {
                        cmp.set('v.deniedFormalizeSimCheck', false);
                        cmp.set('v.deniedAuthorizeSimCheck', true);
                        cmp.set('v.disableAuthSimulationBtn', false);
                    }
                } else if (state === 'ERROR') {
                    helper.showToast('Error', 'Error', 'Error al seleccionar tasa.');
                }
            });
            $A.enqueueAction(action);
    },
    handleMostrarInfo: function(cmp, event, helper) {
        var target = event.target;
        var rowIndex = target.getAttribute("data-row-index");
        var getStatus = cmp.get('v.getStatus');
        var status = getStatus[rowIndex];
        var businessAgentId = status.businessPeople.businessAgent.id;
        var businessAuthorizesId = status.businessPeople.businessAuthorizes.id;
        let attr = {
            'recordId': cmp.get('v.recordId'),
            'status': status,
            'initDate': status.updateRates.initDateFormalize,
            'sendSystDate': status.updateRates.startDate,
            'revisionDate': status.updateRates.revisionDateFormalize,
            'businessAgentId': businessAgentId,
            'businessAuthorizesId': businessAuthorizesId
        };

        helper.loadComponent(cmp, event, helper, 'DPMX_MostrarHistorialTasas', attr).then($A.getCallback(newComponent => {
            let body = [];
            body.push(newComponent);
            cmp.set('v.body', body);
        }));
    },
    callStatusFeeService: function(cmp, event, helper, folioId) {
        var customerId = cmp.get('v.customerId');
        var dynamicPricing = cmp.get('v.dynamicPricing');
        var familia = dynamicPricing.familia_AcquiererCategories_Id__c;
        var action = cmp.get('c.callstatusFee');
        action.setParams({
            'recordId': cmp.get('v.recordId'),
            'folioId': folioId,
            'customerId': customerId,
            'familia': familia
        })
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                var result = response.getReturnValue();
                if (result.error) {
                    helper.showToast('Error', 'error', result.error);
                } else if (result.success) {
                    //helper.showToast('SUCCESS', 'Status servicio', result.status);
                    helper.handleVerificarTasa(cmp, event, helper);
                }
            }
        });
        $A.enqueueAction(action);
    },
    handleVerificarTasa: function(cmp, event, helper) {
        var acquirerActivitiesWrapper = cmp.get('v.acquirerActivitiesWrapper');
        var discountRates = cmp.get('v.interchangeRates');
        let atrri = {
            'recordId': cmp.get('v.recordId'),
            'isLastMonthTab': cmp.get('v.isLastMonthTab'),
            'isSimulationTab': cmp.get('v.isSimulationTab'),
            'sendConditionLst': cmp.get('v.sendConditionLst'),
            'sendSimulationLst': cmp.get('v.sendSimulationLst'),
            'acquirerActivitiesWrapper': acquirerActivitiesWrapper,
            'discountRates': discountRates
        };
        helper.loadComponent(cmp, event, helper, 'DPMX_VerificarTasa', atrri).then($A.getCallback(newComponent => {
            let body = [];
            body.push(newComponent);
            cmp.set('v.body', body);
        }));
    },
    handlegetStatus: function(cmp, event, helper) {
        /** callgetStatusService */
        var customerId = cmp.get('v.customerId');
        var dynamicPricing = cmp.get('v.dynamicPricing');
        var acquirerCategoryId = dynamicPricing.familia_AcquiererCategories_Id__c;
        var callGetStatusService = cmp.get('c.callGetStatusService');
        callGetStatusService.setParams({
            'recordId': cmp.get('v.recordId'),
            'customerId': customerId,
            'acquirerId': acquirerCategoryId,
            'pageKey': cmp.get('v.pageKey')
        })
        callGetStatusService.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                var result = response.getReturnValue();
                cmp.set('v.getStatus', result.getStatus.data);
            }
        });
        $A.enqueueAction(callGetStatusService);
    },
    handlegetStatusNext: function(cmp, event, helper) {
        /** callgetStatusService */
        var customerId = cmp.get('v.customerId');
        var dynamicPricing = cmp.get('v.dynamicPricing');
        var acquirerCategoryId = dynamicPricing.familia_AcquiererCategories_Id__c;
        let pageKey = cmp.get('v.pageKey');
        pageKey = pageKey + 1;
        var callGetStatusService = cmp.get('c.callGetStatusService');
        callGetStatusService.setParams({
            'recordId': cmp.get('v.recordId'),
            'customerId': customerId,
            'acquirerId': acquirerCategoryId,
            'pageKey': pageKey
        })
        callGetStatusService.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                var result = response.getReturnValue();
                if (result.statusCode == '204') {
                    helper.showToast('Error', 'error', 'No se han encontrado datos.');
                } else if (result.statusCode == '200') {
                    helper.showToast('SUCCESS', 'Llamada al servicio realizada', 'Ahora se cargaran los datos.');
                    cmp.set('v.getStatus', result.getStatus.data);
                    cmp.set('v.pageKey', pageKey);
                } else {
                    helper.showToast('Error', 'error', 'Ha surgido algun error con la llamada al servicio.');
                }
            }
        });
        $A.enqueueAction(callGetStatusService);
    },
    handlegetStatusPrev: function(cmp, event, helper) {
        /** callgetStatusService */
        var customerId = cmp.get('v.customerId');
        var dynamicPricing = cmp.get('v.dynamicPricing');
        var acquirerCategoryId = dynamicPricing.familia_AcquiererCategories_Id__c;
        let pageKey = cmp.get('v.pageKey');
        pageKey = pageKey - 1;
        if (pageKey > 0) {
            var callGetStatusService = cmp.get('c.callGetStatusService');
            callGetStatusService.setParams({
                'recordId': cmp.get('v.recordId'),
                'customerId': customerId,
                'acquirerId': acquirerCategoryId,
                'pageKey': pageKey
            })
            callGetStatusService.setCallback(this, function(response) {
                var state = response.getState();
                if (state === 'SUCCESS') {
                    var result = response.getReturnValue();
                    if (result.statusCode == '204') {
                        helper.showToast('Error', 'error', 'No se han encontrado datos previos.');
                    } else if (result.statusCode == '200') {
                        helper.showToast('SUCCESS', 'Llamada al servicio realizada', 'Ahora se cargaran los datos.');
                        cmp.set('v.getStatus', result.getStatus.data);
                        cmp.set('v.pageKey', pageKey);
                    } else {
                        helper.showToast('Error', 'error', 'Ha surgido algun error con la llamada al servicio.');
                    }
                }
            });
            $A.enqueueAction(callGetStatusService);
        } else {
            helper.showToast('Error', 'Error', 'No se han encontrado datos previos.');
        }
    },
    veryRateBreakEvenOutOfLimits: function(cmp, event, helper, isbreakEvenOutOfLimits) {
        cmp.set('v.isBreakEvenOutOfLimits', isbreakEvenOutOfLimits);
        let dpmx = cmp.get('v.dynamicPricing');
        if (isbreakEvenOutOfLimits) {
            if (!dpmx.rateBreakEvenOutLimits__c) {
                let attr = {
                    'dynamicId': cmp.get('v.recordId')
                };
                helper.loadComponent(cmp, event, helper, 'DPMX_VerifyBreakEvenRates', attr).then($A.getCallback(newComponent => {
                    let body = [];
                    body.push(newComponent);
                    cmp.set('v.body', body);
                }));
            }
        }
    },
    callAcquirerFeesService: function(cmp, event, helper) {
        var serviceAcquirerFees = cmp.get('c.callAcquirerFeesService');
        var customerId = cmp.get('v.customerId');
        var dynamicPricing = cmp.get('v.dynamicPricing');
        var acquirerCategoryId = dynamicPricing.familia_AcquiererCategories_Id__c;
        serviceAcquirerFees.setParams({
            'recordId': cmp.get('v.recordId'),
            'customerId': customerId,
            'acquirerId': acquirerCategoryId,
            'acquirerActivitiesWrapper': cmp.get('v.acquirerActivitiesWrapper'),
            'discountRates': cmp.get('v.interchangeRates'),
            'checkbox': false
        })
        serviceAcquirerFees.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                helper.waiting(cmp);
                var result = response.getReturnValue();
                if (result.error) {
                    helper.showToast('Error', 'Error', 'Ha surgido un error al conectarse con los servicios. Recargue la pagina.');
                } else if (result.success) {
                    var acFW = result.acquirerFeesWrapper;
                    var acLst = acFW.scenarios;
                    let scenariosArry = [];

                    scenariosArry = helper.saveListOfFees('Minimo viable', scenariosArry, acLst);
                    scenariosArry = helper.saveListOfFees('BREAK_EVEN', scenariosArry, acLst);
                    scenariosArry = helper.saveListOfFees('GOOD', scenariosArry, acLst);
                    scenariosArry = helper.saveListOfFees('OPTIMAL', scenariosArry, acLst);

                    cmp.set('v.lstScenearios', scenariosArry);
                    cmp.set('v.lstSceneariosSim', scenariosArry);
                    cmp.set('v.acquirerFeesWrapper', result.acquirerFeesWrapper);
                    cmp.set('v.sendConditionLst', result.sendConditionLst);
                    cmp.set('v.simulationWrapper', result.acquirerFeesWrapper);
                    cmp.set('v.sendSimulationLst', result.sendConditionLst);

                    helper.veryRateBreakEvenOutOfLimits(cmp, event, helper, result.checkrateBreakEvenOutLimits);

                    helper.profitabilityCalculateRates(cmp, helper);

                    helper.commisionTPVCalculator(cmp);

                    helper.commisionRedCelCalculator(cmp);

                    helper.commisionBajFacalculator(cmp);

                    helper.profitabilityCalculateRatesSimulation(cmp, event, helper);

                    if (result.dynamicPricing.TAMAccepted__c) {
                        /** callgetStatusService */
                        helper.handlegetStatus(cmp, event, helper);
                    }

                    helper.doneWaiting(cmp);

                }
            } else if (state === 'ERROR') {
                helper.showToast('Error', 'Error', 'Ha surgido un error al conectarse con los servicios. Recargue la pagina.');
            }
        });
        $A.enqueueAction(serviceAcquirerFees);
        /** */
    },
    saveListOfFees: function(key, scenariosArry, acLst) {
        for (let i = 0; i < acLst.length; i++) {
            if (acLst[i].scenarioType === key) {
                scenariosArry.push(acLst[i]);
            }
        }
        return scenariosArry;
    },
    returnValueforFee: function(valueFromRat, valueFromElement) {
        if (valueFromRat === 0 || valueFromRat > valueFromElement) {
            valueFromRat = valueFromElement;
        }
        return valueFromRat;
    },
    servicecallCorporateRateService: function(cmp, event, helper) {

        var servicecallCorporateRateService = cmp.get('c.callCorporateRateService');
        var customerId = cmp.get('v.customerId');
        var dynamicPricing = cmp.get('v.dynamicPricing');
        var acquirerCategoryId = dynamicPricing.familia_AcquiererCategories_Id__c;
        servicecallCorporateRateService.setParams({
        'recordId': cmp.get('v.recordId'),
        'customerId': customerId,
        'acquirerId': acquirerCategoryId,
        'acquirerActivitiesWrapper': cmp.get('v.acquirerActivitiesWrapper')
        })
        servicecallCorporateRateService.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
            helper.waiting(cmp);
            var result = response.getReturnValue();
            if (result.error) {
                helper.showToast('Error', 'Error', 'Ha surgido un error al conectarse con los servicios. Recargue la pagina.');
            } else if (result.success) {
                cmp.set('v.interchangeRates', result.interchangeRates);
                cmp.set('v.discountRates', result.discountRates);
                cmp.set('v.discountWrapper', result.discountWrapper);
                cmp.set('v.acquirerActivitiesWrapper', result.acquirerActivitiesWrapper);

                cmp.set('v.credit', dynamicPricing.CustomAcquiredFeesCredit__c);
                cmp.set('v.debit', dynamicPricing.CustomAcquiredFeesDebit__c);
                cmp.set('v.international', dynamicPricing.CustomAcquiredFeesInternational__c);

                cmp.set('v.creditSimulation', dynamicPricing.CustomSimulatedCredit__c);
                cmp.set('v.debitSimulation', dynamicPricing.CustomSimulatedDebit__c);
                cmp.set('v.internationalSimulation', dynamicPricing.CustomSimulatedInternational__c);

                helper.callAcquirerFeesService(cmp, event, helper);
            }
            } else if (state === 'ERROR') {
                helper.showToast('Error', 'Error', 'Ha surgido un error al conectarse con los servicios. Recargue la pagina.');
            }
        });
        $A.enqueueAction(servicecallCorporateRateService);

    },
    CallComparativeCategories: function(cmp, event, helper) {

        /** CallComparativeCategories **/
        var serviceComparativeCategories = cmp.get('c.CallComparativeCategories');
        var customerId = cmp.get('v.customerId');
        var dynamicPricing = cmp.get('v.dynamicPricing');
        var acquirerCategoryId = dynamicPricing.familia_AcquiererCategories_Id__c;
        serviceComparativeCategories.setParams({
            'customerId': customerId,
            'acquirerCategoryId': acquirerCategoryId,
            'recordId': cmp.get('v.recordId'),
            'isGs': cmp.get('v.acquirerActivitiesWrapper.isGS')
        })
        serviceComparativeCategories.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                helper.waiting(cmp);
                var result = response.getReturnValue();
                if (result.error) {
                    helper.showToast('Error', 'Error', 'Ha surgido un error al conectarse con los servicios. Recargue la pagina.');
                } else if (result.success) {
                    cmp.set('v.acquirerCategoriesWrapper', result.acquirerCategoriesWrapper);
                    cmp.set('v.companyComparisonList', result.companyComparisonList);
                    helper.servicecallCorporateRateService(cmp, event, helper);
                }
            } else if (state === 'ERROR') {
                
                helper.showToast('Error', 'Error', 'Ha surgido un error al conectarse con los servicios. Recargue la pagina.');
            }
        });
        $A.enqueueAction(serviceComparativeCategories);
        /** */
    },
    callAcquirerActivitiesService: function(cmp, event, helper) {
        var customerId = cmp.get('v.customerId');
        var dynamicPricing = cmp.get('v.dynamicPricing');
        var familia = dynamicPricing.familia__c;
        /** callAcquirerActivitiesService **/
        var ServiceAcquirerActivitie = cmp.get('c.callAcquirerActivitiesService');
        ServiceAcquirerActivitie.setParams({
            'recordId': cmp.get('v.recordId'),
            'customerId': customerId,
            'familia': familia
        })
        ServiceAcquirerActivitie.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                helper.waiting(cmp);
                var result = response.getReturnValue();
                if (result.error) {
                    helper.showToast('Error', 'Error', 'Ha surgido un error al conectarse con los servicios. Recargue la pagina.');
                } else if (result.success) {
                    cmp.set('v.acquirerActivitiesWrapper', result.acquirerActivitiesWrapper);
                    if (result.acquirerActivitiesWrapper.discount.debit.itemizeType.amount) {
                        cmp.set('v.DiscoruntDebitIsAmount', true);
                    }
                    helper.CallComparativeCategories(cmp, event, helper);
                }
            } else if (state === 'ERROR') {
                helper.showToast('Error', 'Error', 'Ha surgido un error al conectarse con los servicios. Recargue la pagina.');
            }
        });
        $A.enqueueAction(ServiceAcquirerActivitie);
        /** */
    },
    callDiscountService: function(cmp, event, helper) {
        /** callDiscountService */
        var servicecallCorporateRateService = cmp.get('c.callCorporateRateService');
        servicecallCorporateRateService.setParams({
            'recordId': cmp.get('v.recordId'),
            'customerId': customerId,
            'acquirerId': acquirerCategoryId,
            'acquirerActivitiesWrapper': cmp.get('v.acquirerActivitiesWrapper')
        })
        servicecallCorporateRateService.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                helper.waiting(cmp);
                var result = response.getReturnValue();
                if (result.error) {
                    helper.showToast('Error', 'Error', 'Ha surgido un error al conectarse con los servicios. Recargue la pagina.');
                } else if (result.success) {
                    cmp.set('v.interchangeRates', result.interchangeRates);
                    cmp.set('v.discountRates', result.discountRates);
                    cmp.set('v.discountWrapper', result.discountWrapper);
                    cmp.set('v.credit', dynamicPricing.CustomAcquiredFeesCredit__c);
                    cmp.set('v.debit', dynamicPricing.CustomAcquiredFeesDebit__c);
                    cmp.set('v.international', dynamicPricing.CustomAcquiredFeesInternational__c);
                    cmp.set('v.creditSimulation', dynamicPricing.CustomSimulatedCredit__c);
                    cmp.set('v.debitSimulation', dynamicPricing.CustomSimulatedDebit__c);
                    cmp.set('v.internationalSimulation', dynamicPricing.CustomSimulatedInternational__c);

                    helper.profitabilityCalculateRatesSimulation(cmp, event, helper);
                    
                    helper.doneWaiting(cmp);
                }
            } else if (state === 'ERROR') {
                helper.showToast('Error', 'Error', 'Ha surgido un error al conectarse con los servicios. Recargue la pagina.');
            }
        });
        $A.enqueueAction(servicecallCorporateRateService);
        /** */
    },
    saveTasaSim: function(element) {
        let tasaMap = new Map();
        element.rate.itemizeRates.forEach((value) => {
            switch (true) {
                case (value.idOrder === 0):
                    if (isGs) {
                        tasaMap.set("debitSim", value.itemizeRatesUnit.amount);
                    } else {
                        tasaMap.set("debitSim", value.itemizeRatesUnit.percentage);
                    }
                    break;
                case (value.idOrder == 1):
                    tasaMap.set("creditSim", value.itemizeRatesUnit.percentage);
                    break;
                case (value.idOrder == 2):
                    tasaMap.set("internationalSim", value.itemizeRatesUnit.percentage);
                    break;
                case (value.idOrder == 3):
                    tasaMap.set("rentSim", value.itemizeRatesUnit.percentage);
                    break;
            }
        });
        tasaMap.set("resultSim", element.scenaryType);
        tasaMap.set("baiSim", element.amount.amount);

        return tasaMap;
    },
    setFalseRadioButtonSim: function() {
        let radio = document.getElementById("Simulation_5");
        if(radio !== null){
            radio.checked = false;
        }
        radio = document.getElementById("Simulation_0");
        if(radio !== null){
            radio.checked = false;
        }
        radio = document.getElementById("Simulation_1");
        if(radio !== null){
            radio.checked = false;
        }
        radio = document.getElementById("Simulation_2");
        if(radio !== null){
            radio.checked = false;
        }
        radio = document.getElementById("Simulation_3");
        if(radio !== null){
            radio.checked = false;
        }
    },
    setFalseRadioButton: function() {
        let radio = document.getElementById("5");
        if(radio !== null){
            radio.checked = false;
        }
        radio = document.getElementById("0");
        if(radio !== null){
            radio.checked = false;
        }
        radio = document.getElementById("1");
        if(radio !== null){
            radio.checked = false;
        }
        radio = document.getElementById("2");
        if(radio !== null){
            radio.checked = false;
        }
        radio = document.getElementById("3");
        if(radio !== null){
            radio.checked = false;
        }
    }
})