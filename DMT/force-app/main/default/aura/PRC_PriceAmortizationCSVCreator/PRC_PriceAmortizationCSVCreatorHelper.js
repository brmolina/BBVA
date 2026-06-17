({
    saveAmortizationCSV: function (component, helper, csv) {
        var opportunity = component.get('v.recordId');
        var action = component.get('c.savePriceAmortizationDataFromCSV');
        action.setParams({
            csv_str: csv,
            oppId: opportunity
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.csvObject", response.getReturnValue());
                helper.showToast(component, event, helper, 'success', 'Amortization data successfully loaded');
            } else if (state === "ERROR") {
                // generic error handler
                var errors = response.getError();
                if (errors) {
                    console.log(">>>>> Errors", errors);
                    if (errors[0] && errors[0].message) {
                        helper.showToast(component, event, helper, 'error', 'Error: ' + errors[0].message);
                    }
                } else {
                    helper.showToast(component, event, helper, 'error', 'Unknown Error');
                }
            }
        });
        $A.enqueueAction(action);
    },
    updatePricingDetails: function (component, helper, totalNonAccrualFees) {
        var opportunity = component.get('v.recordId');
        var action = component.get('c.updatePricingDetails');
        action.setParams({
            nonAccrualFees: totalNonAccrualFees,
            oppId: opportunity,
            amortization: 'USER_DEFINED'
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                /* si se quiere lanzar mensaje helper.showToast(component, event, helper, 'success','Non Accrual Fees data successfully uploaded'); */
                console.log(">>>>> Non Accrual Fees data successfully uploaded");
            } else if (state === "ERROR") {
                // generic error handler
                var errors = response.getError();
                if (errors) {
                    console.log(">>>>> Error when trying to upload Non Accrual Fees", errors);
                    if (errors[0] && errors[0].message) {
                        /* si se quiere lanzar mensaje helper.showToast(component, event, helper, 'error', 'Error: ' + errors[0].message); */
                        console.log(">>>>> Error: " + errors[0].message);
                    }
                } else {
                    /* si se quiere lanzar mensaje helper.showToast(component, event, helper, 'error', 'Unknown Error'); */
                    console.log(">>>>> Unknown Error");
                }
            }
        });
        $A.enqueueAction(action);
    },
    updatePricingDetails_prueba: function (component, helper, totalNonAccrualFees) {
        let formcomponentcontainer = component.find('modalbody');
        let formcomponent = formcomponentcontainer.get('v.body')[0].find('priceform');
        formcomponentcontainer.get('v.body')[0].find('nonAccrualFeesId').set('v.value', totalNonAccrualFees);
        console.log('>>>>>> submit de Pricing Details formcomponent: ' + formcomponent);
        formcomponent.submit();
    },
    deleteAmortizationData: function (component, helper) {
        var opportunity = component.get('v.recordId');
        var action = component.get('c.deletePriceAmortizationData');
        action.setParams({
            oppId: opportunity
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var appEvent = $A.get("e.c:PRC_AmortizationCSVInterface_Refresh");
                appEvent.fire();
                component.set("v.csvObject", response.getReturnValue());
                helper.showToast(component, event, helper, 'success', 'Amortization data successfully deleted');
                var initTable = component.get('c.doInit');
                $A.enqueueAction(initTable);
                component.set('v.displaymodal', false);
                component.set('v.displaySpinner', false);
            } else if (state === "ERROR") {
                // generic error handler
                var errors = response.getError();
                if (errors) {
                    console.log(">>>>> Errors", errors);
                    if (errors[0] && errors[0].message) {
                        helper.showToast(component, event, helper, 'error', 'Error: ' + errors[0].message);
                    }
                } else {
                    helper.showToast(component, event, helper, 'error', 'Unknown Error');
                }
            }
        });
        $A.enqueueAction(action);
    },
    convertArrayOfObjectsToCSV: function (component, objectRecords) {
        // declare variables
        var csvStringResult, counter, headerLabels, keys, columnDivider, lineDivider;
		// separar if abajo - var amort = component.get('v.proyectFinance');
        // check if "objectRecords" parameter is null, then return from function
        if (objectRecords == null) { //|| !objectRecords.length) {
            return null;
        }
        // store ,[comma] in columnDivider variabel for sparate CSV values and
        // for start next line use '\n' [new line] in lineDivider variable
        columnDivider = ';';
        lineDivider = '\n';

        // in the keys variable store fields API Names as a key
        // this labels use in CSV file header
        headerLabels = ['Fecha', 'NominalDB', 'NominalFB', 'SpreadDB', 'SpreadFB', 'Comision'];
        keys = ['cutoff_date__c', 'gf_on_bal_mrgn_gen_amount__c', 'gf_off_bal_mrgn_gen_amount__c', 'gf_ope_on_balance_margin_per__c',
            'gf_ope_off_balance_margin_per__c', 'gf_non_accrual_comission_per__c'];

        //if(amort!='GTB') {      headerLabels.push("Qualification","Rating","LGD");     keys.push("gf_financing_type_name__c","gf_amort_proc_oper_rating_type__c","gf_amort_proc_expct_lss_amount__c");    }    //NOSONAR

        csvStringResult = '';
        csvStringResult += headerLabels.join(columnDivider);
        csvStringResult += lineDivider;

        for (var i = 0; i < objectRecords.length; i++) {
            counter = 0;

            for (var sTempkey in keys) {
                var skey = keys[sTempkey];

                // add , [comma] after every String value,. [except first]
                if (counter > 0) {
                    csvStringResult += columnDivider;
                }

                var fieldValue = objectRecords[i][skey];
                if (skey === 'cutoff_date__c') {
                    var auxDate = fieldValue.split('-');
                    // formato fecha en Salesforce: 2020-03-31  -> formato fecha que se carga desde csv: 03/31/2020
                    fieldValue = auxDate[1] + '/' + auxDate[2] + '/' + auxDate[0];
                }
                csvStringResult += fieldValue;

                counter++;

            } // inner for loop close
            csvStringResult += lineDivider;
        }// outer main for loop close

        // return the CSV formate String
        return csvStringResult;
    },
    showToast: function (component, event, helper, msgType, msg, msgMode) {
        var toastEvent = $A.get("e.force:showToast");
        if (msgMode) {
            toastEvent.setParams({
                "mode": 'sticky',
                "type": msgType,
                "message": msg
            });
        } else {
            toastEvent.setParams({
                // "title": "Success!",
                "type": msgType,
                "message": msg
            });
        }

        toastEvent.fire();
        return 'OK';
    }
})