({
    doInit: function(cmp, evt, helper) {
        var action = cmp.get('c.getInitialData');
        console.log(cmp.get('v.recordId'));
        action.setParams({
            'recordId': cmp.get('v.recordId')
        })
        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log('INIT');
            console.log(state);
            if (state === 'SUCCESS') {
                var result = response.getReturnValue();
                if (result.formalizeDenied) {
                    helper.showToast('Error', 'Formalización rechazada', 'Esta Formalización se ha rechazado.');
                }

                cmp.set('v.disableButtons', result.formalizeDenied);

                cmp.set('v.initDate', result.initDate);
                cmp.set('v.revisionDate', result.revisionDate);

                cmp.set('v.dynamicPricingId', result.dynamicPricingId);

                cmp.set('v.authTypeName', result.authTypeName);
                cmp.set('v.authSolicitudeName', result.authSolicitudeName);
                cmp.set('v.authTypeProduct', result.authTypeProduct);
                cmp.set('v.authTypeRazSoc', result.authTypeRazSoc);
                cmp.set('v.authTypeFam', result.authTypeFam);


                cmp.set('v.authBai', result.authBai);
                cmp.set('v.authCredit', result.authCredit);
                cmp.set('v.authDebit', result.authDebit);
                cmp.set('v.authInternational', result.authInternational);
                cmp.set('v.authProfitability', result.authProfitability);
                cmp.set('v.authResult', result.authResult);
                cmp.set('v.authFamily', result.authFamily);
                cmp.set('v.isGs', result.isGs);
                console.log(result.authCredit);

                cmp.set('v.creditBase', result.creditBase);
                cmp.set('v.debitBase', result.debitBase);
                cmp.set('v.internationalBase', result.internationalBase);
                cmp.set('v.rentaBase', result.rentaBase);
                cmp.set('v.baiBase', result.baiBase);

                cmp.set('v.FirmODTUser__c', result.FirmODTUser__c);
                cmp.set('v.FirmOdtClient__c', result.FirmOdtClient__c);
                cmp.set('v.NewODT__c', result.NewODT__c);
                cmp.set('v.ScanODT__c', result.ScanODT__c);
                cmp.set('v.archRespaldo__c', result.archRespaldo__c);

                cmp.set('v.DPMX_Company_Name__c', result.DPMX_Company_Name__c);
                cmp.set('v.DPMX_familia__c', result.DPMX_familia__c);
                cmp.set('v.DPMX_NumeroCliente__c', result.DPMX_NumeroCliente__c);
                cmp.set('v.consultDate', result.consultDate);

                cmp.set('v.DPMX_debit', result.DPMX_debit);
                cmp.set('v.DPMX_credit', result.DPMX_credit);
                cmp.set('v.DPMX_International', result.DPMX_International);
                cmp.set('v.DPMX_Resultado', result.DPMX_Resultado);
                cmp.set('v.DPMX_Rentabilidad', result.DPMX_Rentabilidad);
                cmp.set('v.DPMX_BAI', result.DPMX_BAI);

                cmp.set('v.DPMX_extraBillingRub', result.DPMX_extraBillingRub);
                cmp.set('v.DPMX_billingRub', result.DPMX_billingRub);
                cmp.set('v.DPMX_cellnetRub', result.DPMX_cellnetRub);

                cmp.set('v.DPMX_Date', result.DPMX_Date);

                cmp.set('v.DPMX_monetaryCeiling', result.DPMX_monetaryCeiling);
                cmp.set('v.DPMX_extraBilling', result.DPMX_extraBilling);
                cmp.set('v.DPMX_billing', result.DPMX_billing);
                cmp.set('v.DPMX_cellnet', result.DPMX_cellnet);
                cmp.set('v.DPMX_totalAmount', result.DPMX_totalAmount);
                cmp.set('v.DPMX_totalAmountSim', result.DPMX_totalAmountSim);
                cmp.set('v.DPMX_mit', result.DPMX_mit);

                cmp.set('v.DPMX_transaction_y_debit_own', result.DPMX_transaction_y_debit_own);
                cmp.set('v.DPMX_billing_debit_own', result.DPMX_billing_debit_own);
                cmp.set('v.DPMX_tickets_debit_own', result.DPMX_tickets_debit_own);
                cmp.set('v.DPMX_percentage_debit_own', result.DPMX_percentage_debit_own);

                cmp.set('v.DPMX_transaction_y_debit_thirdParty', result.DPMX_transaction_y_debit_thirdParty);
                cmp.set('v.DPMX_billing_debit_thirdParty', result.DPMX_billing_debit_thirdParty);
                cmp.set('v.DPMX_tickets_debit_thirdParty', result.DPMX_tickets_debit_thirdParty);
                cmp.set('v.DPMX_percentage_debit_thirdParty', result.DPMX_percentage_debit_thirdParty);

                cmp.set('v.DPMX_transaction_y_credit_own', result.DPMX_transaction_y_credit_own);
                cmp.set('v.DPMX_billing_credit_own', result.DPMX_billing_credit_own);
                cmp.set('v.DPMX_tickets_credit_own', result.DPMX_tickets_credit_own);
                cmp.set('v.DPMX_percentage_credit_own', result.DPMX_percentage_credit_own);

                cmp.set('v.DPMX_transaction_y_credit_thirdParty', result.DPMX_transaction_y_credit_thirdParty);
                cmp.set('v.DPMX_billing_credit_thirdParty', result.DPMX_billing_credit_thirdParty);
                cmp.set('v.DPMX_tickets_credit_thirdParty', result.DPMX_tickets_credit_thirdParty);
                cmp.set('v.DPMX_percentage_credit_thirdParty', result.DPMX_percentage_credit_thirdParty);

                cmp.set('v.DPMX_transaction_y_international', result.DPMX_transaction_y_international);
                cmp.set('v.DPMX_billing_international', result.DPMX_billing_international);
                cmp.set('v.DPMX_tickets_international', result.DPMX_tickets_international);
                cmp.set('v.DPMX_percentage_international', result.DPMX_percentage_international);

                cmp.set('v.DPMX_transaction_y_total', result.DPMX_transaction_y_total);
                cmp.set('v.DPMX_billing_total', result.DPMX_billing_total);
                cmp.set('v.DPMX_tickets_total', result.DPMX_tickets_total);
                cmp.set('v.DPMX_percentage_total', result.DPMX_percentage_total);

                cmp.set('v.DPMX_terminal', result.DPMX_terminal);
                cmp.set('v.DPMX_pinPads', result.DPMX_pinPads);
                cmp.set('v.DPMX_ecommerceCheckbox', result.DPMX_ecommerceCheckbox);
                cmp.set('v.DPMX_devicesNumber', result.DPMX_devicesNumber);

                cmp.set('v.DPMX_scenario', result.DPMX_scenario);

                cmp.set('v.DPMX_debitPorpio', result.DPMX_debitPorpio);
                cmp.set('v.DPMX_creditPorpio', result.DPMX_creditPorpio);
                cmp.set('v.DPMX_interPorpio', result.DPMX_interPorpio);
                cmp.set('v.DPMX_resultPorpio', result.DPMX_resultPorpio);
                cmp.set('v.DPMX_rentPorpio', result.DPMX_rentPorpio);
                cmp.set('v.DPMX_baiPorpio', result.DPMX_baiPorpio);

                cmp.set('v.DPMX_oppPosExtra', result.DPMX_oppPosExtra);
                cmp.set('v.DPMX_oppCallnet', result.DPMX_oppCallnet);
                cmp.set('v.DPMX_oppLowBilling', result.DPMX_oppLowBilling);

                cmp.set('v.DPMX_basisPoints', result.DPMX_basisPoints);

                cmp.set('v.DPMX_interchangeRates_debit', result.DPMX_interchangeRates_debit);
                cmp.set('v.DPMX_interchangeRates_credit', result.DPMX_interchangeRates_credit);
                cmp.set('v.DPMX_interchangeRates_International', result.DPMX_interchangeRates_International);

                cmp.set('v.DPMX_discountRates_debit', result.DPMX_discountRates_debit);
                cmp.set('v.DPMX_discountRates_credit', result.DPMX_discountRates_credit);
                cmp.set('v.DPMX_discountRates_International', result.DPMX_discountRates_International);

                cmp.set('v.DPMX_DescuentoMaximo', result.DPMX_DescuentoMaximo);

                cmp.set('v.formalizeExist', result.formalizeExist);

                cmp.set('v.usersToODTLst', result.usersToODTLst);
                cmp.set('v.usersToODTNamesLst', result.usersToODTNamesLst);

                cmp.set('v.DPMX_sel_debit', result.DPMX_debit_sel);
                cmp.set('v.DPMX_sel_credit', result.DPMX_credit_sel);
                cmp.set('v.DPMX_sel_International', result.DPMX_sel_International);
                cmp.set('v.DPMX_sel_Result', result.DPMX_Resultado_sel);
                cmp.set('v.DPMX_sel_Rent', result.DPMX_Rentabilidad_sel);
                cmp.set('v.DPMX_sel_Bai', result.DPMX_BAI_sel);

                if (result.ScanODT__c) {
                    helper.handleIsCheck(cmp, evt, helper);
                }
            }
        });
        $A.enqueueAction(action);
    },
    handleCheckODT: function(cmp, evt, helper) {
        var firmaClienteODT = cmp.find("firmaClienteODT").get("v.checked");
        var scanODT = cmp.find("scanODT").get("v.checked");
        var fimaRepresODT = cmp.find("fimaRepresODT").get("v.checked");
        var archRespaldo = cmp.find("archRespaldo").get("v.checked");
        var action = cmp.get('c.updateFormalize');
        action.setParams({
            'recordId': cmp.get('v.recordId'),
            'firmaClienteODT': firmaClienteODT,
            'scanODT': scanODT,
            'archRespaldo': archRespaldo,
            'fimaRepresODT': fimaRepresODT
        })
        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log('INIT');
            if (state === 'SUCCESS') {
                console.log(state);
                var result = response.getReturnValue();
                let attr = {
                    'dynamicPricingId': cmp.get('v.dynamicPricingId')
                };
                helper.loadComponent(cmp, evt, helper, 'DPMX_FormalizeAtam', attr).then($A.getCallback(newComponent => {
                    let body = [];
                    body.push(newComponent);
                    cmp.set('v.body', body);
                }));

            }
        });
        $A.enqueueAction(action);
    },
    handleSave: function(cmp, evt, helper) {
        let attr = {
            'dynamicPricingId': cmp.get('v.dynamicPricingId')
        };
        helper.loadComponent(cmp, evt, helper, 'DPMX_FormalizeAccept', attr).then($A.getCallback(newComponent => {
            let body = [];
            body.push(newComponent);
            cmp.set('v.body', body);
        }));
    },
    handleRechazar: function(cmp, evt, helper) {
        let attr = {
            'recordId': cmp.get('v.recordId')
        }

        helper.loadComponent(cmp, evt, helper, 'DPMX_FormalizeDeny', attr).then($A.getCallback(newComponent => {
            let body = [];
            body.push(newComponent);
            cmp.set('v.body', body);
        }));
    },
    handleIsCheck: function(cmp, evt, helper) {
        var firmaClienteODT = cmp.find("firmaClienteODT").get("v.checked");
        var scanODT = cmp.find("scanODT").get("v.checked");
        var fimaRepresODT = cmp.find("fimaRepresODT").get("v.checked");
        var archRespaldo = cmp.find("archRespaldo").get("v.checked");
        var formalizeDenied = cmp.get('v.disableButtons');

        if (firmaClienteODT && scanODT && fimaRepresODT && archRespaldo && !formalizeDenied) {
            //cmp.set('v.isDisable', result.formalizeDenied);
            cmp.set('v.isDisable', false);
        } else {
            cmp.set('v.isDisable', true);
        }
    },
    loadComponent: function(cmp, evt, helper, cmpName, cmpAttr) {
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
    }
})