({
    "doInit": function(cmp, evt, helper) {
        console.log(cmp.get('v.isSimulationTab'));
        var action = cmp.get('c.getInitialData');
        action.setParams({
            'recordId': cmp.get('v.recordId'),
        })
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                var result = response.getReturnValue();
                if (result.errorTab) {
                    helper.showToast('Error', 'error', result.msgErrorTab);
                    helper.handleClose(cmp, evt, helper);
                } else {
                    //Se pone a false para que los if de html lo detecten sin tener que modificar la logica.
                    cmp.set('v.isCustom', !result.isCustom);
                    cmp.set('v.isSelectDisabled', result.isCustom);
                    if(result.isCustom){
                        cmp.set('v.templateName', 'DPMX_SendReportCustom');
                    }else {
                        cmp.set('v.templateName', 'DPMX_SendReport');
                    }
                    cmp.set('v.saludoTasa', 'Saludos,');
                    cmp.set('v.introduccionTasa', 'En seguimiento a la solicitud que hemos conversado en días recientes, adjunto la propuesta de condiciones para la operación de actualización de tasa de descuento, a fin de que puedas revisarla y comunicarme tu decisión.');
                    cmp.set('v.closeTasa', 'Si existiera alguna duda sobre estas condiciones o requieres más información, no dudes en contactarme.');
                    cmp.set('v.debitTasa', result.debitTasa);
                    cmp.set('v.creditTasa', result.creditTasa);
                    cmp.set('v.internationalTasa', result.internationalTasa);

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

                    cmp.set('v.DPMX_Date', result.DPMX_Date);

                    cmp.set('v.DPMX_monetaryCeiling', result.DPMX_monetaryCeiling);
                    cmp.set('v.DPMX_extraBilling', result.DPMX_extraBilling);
                    cmp.set('v.DPMX_billing', result.DPMX_billing);
                    cmp.set('v.DPMX_cellnet', result.DPMX_cellnet);
                    cmp.set('v.DPMX_extraBillingRub', result.DPMX_extraBillingRub);
                    cmp.set('v.DPMX_billingRub', result.DPMX_billingRub);
                    cmp.set('v.DPMX_cellnetRub', result.DPMX_cellnetRub);
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

                    cmp.set('v.DPMX_sel_debit', result.DPMX_debit_sel);
                    cmp.set('v.DPMX_sel_credit', result.DPMX_credit_sel);
                    cmp.set('v.DPMX_sel_International', result.DPMX_International_sel);
                    cmp.set('v.DPMX_sel_Result', result.DPMX_Resultado_sel);
                    cmp.set('v.DPMX_sel_Rent', result.DPMX_Rentabilidad_sel);
                    cmp.set('v.DPMX_sel_Bai', result.DPMX_BAI_sel);
                    cmp.set('v.isLastMonthTab', result.isLastMonthTab)
                }

            } else {
                helper.showToast('Error', 'error', state);
            }
        });
        $A.enqueueAction(action);
    },
    handleSave: function(cmp, evt, helper) {
        let templateName = cmp.get("v.templateName");
        let selector = cmp.find("SaveTemplate").get("v.value");
        helper.checkCC(cmp);
        let checkCC = cmp.get('v.checkCC');
        console.log(checkCC);
        let asunto = cmp.find("asunto").get("v.value");
        let saludo = '';
        let intro = '';
        let close = '';
        if (selector == 'Propuestas de tasas de descuento') {
            saludo = cmp.find("Saludo").get("v.value");
            intro = cmp.find("Introdución").get("v.value");
            close = cmp.find("Cierre").get("v.value");
        };
        console.log(cmp.get('v.sendCC'));
        console.log(templateName);
        if (checkCC) {
            var action = cmp.get('c.sendReport');
            action.setParams({
                'recordId': cmp.get('v.recordId'),
                'templateName': templateName,
                'saludo': saludo,
                'intro': intro,
                'close': close,
                'sendCC': cmp.get('v.sendCC'),
                'asunto': asunto
            })
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === 'SUCCESS') {
                    var result = response.getReturnValue();
                    console.log(result.sendReport);
                    console.log(result.status);
                    if (result.sendReport) {
                        helper.showToast('SUCCESS', 'CORREO ENVIADO', 'El correo se ha enviado.');
                    } else {
                        helper.showToast('Error', 'CORREO NO ENVIADO', result.status);
                    }

                } else {
                    console.log(state);
                    helper.showToast('Error', 'error', state);
                }
                var dismissActionPanel = $A.get("e.force:closeQuickAction");
                dismissActionPanel.fire();

            });
            $A.enqueueAction(action);
        } else {
            helper.showToast('Error', 'error', 'Los correos especificados tienes que ser corporativos de BBVA.');
        }
    },
    handleClose: function(cmp, evt, helper) {
        console.log('destroy');
        var dismissActionPanel = $A.get("e.force:closeQuickAction");
        dismissActionPanel.fire();
    },
    handleSaveTemplate: function(cmp) {
        let selector = cmp.find("SaveTemplate").get("v.value");
        let isCustom = cmp.get('v.isCustom');
        console.log(selector);
        if (selector == 'Propuestas de tasas de descuento') {
            cmp.set('v.isTasaSelectd', true);
            cmp.set('v.templateName', 'DPMX_SendReportTasa');
        } else {
            cmp.set('v.isTasaSelectd', false);
            if(isCustom){
                cmp.set('v.templateName', 'DPMX_SendReportCustom');
            }else {
                cmp.set('v.templateName', 'DPMX_SendReport');
            }
            cmp.set('v.templateName', 'DPMX_SendReport');
        }
        console.log(cmp.find("saludo").get("v.value"));
    },
    checkCC: function(cmp, evt, helper) {
        let ccs = cmp.find("cc").get("v.value");
        let ch;

        let i = 0
        let badCharExist = true;
        do {
            ch = ccs.substring(i, i + 1);
            switch (ch) {
                case ' ':
                    ccs = ccs.replace(' ', '');
                    badCharExist = ccs.includes(' ');
                    console.log(i + ' -' + ch + '-' + badCharExist);
                    i = 0;
                    break;
                case ';':
                    ccs = ccs.replace(';', '');
                    badCharExist = ccs.includes(';');
                    console.log(i + ' -' + ch + '-' + badCharExist);
                    i = 0;
                    break;
                case ',':
                    ccs = ccs.replace(',', '');
                    badCharExist = ccs.includes(',');
                    console.log(i + ' -' + ch + '-' + badCharExist);
                    i = 0;
                    break;
                case '-':
                    ccs = ccs.replace('-', '');
                    badCharExist = ccs.includes('-');
                    console.log(i + ' -' + ch + '-' + badCharExist);
                    i = 0;
                    break;
                case ':':
                    ccs = ccs.replace(':', '');
                    badCharExist = ccs.includes(':');
                    console.log(i + ' -' + ch + '-' + badCharExist);
                    i = 0;
                    break;
                default:
                    badCharExist = false;
                    console.log(i + ' -' + ch + '-' + badCharExist);
                    break;
            }
            if (!badCharExist) {
                i++;
            }
        }
        while (i < ccs.length);
        let extLenght = ('@bbva.com').length;
        let posCC = 0;
        let result;
        let toSend = [];
        for (let i = 0; i != ccs.length; i++) {
            result = ccs.substring(i, i + extLenght);
            if (result.includes("@bbva.com")) {
                toSend[toSend.length] = ccs.substring(posCC, i + extLenght);
                posCC = i + extLenght;
                cmp.set('v.checkCC', true);
                console.log('true');
            }
        }
        console.log(toSend);
        cmp.set('v.sendCC', toSend);
    },
    checkComment: function(cmp, evt, helper) {
        let saludo = cmp.find("Saludo").get("v.value");
        let intro = cmp.find("Introdución").get("v.value");
        let close = cmp.find("Cierre").get("v.value");

        cmp.set('v.saludoTasa', saludo);
        cmp.set('v.introduccionTasa', intro);
        cmp.set('v.closeTasa', close);
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