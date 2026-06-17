({
    doInit: function(cmp, event, helper) {
        let recordId = cmp.get('v.recordId');

        var action = cmp.get('c.getInitialData');
        action.setParams({
            'clientId': recordId
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                var result = response.getReturnValue();


                if (result.valueType == 1) {
                    cmp.set('v.countryIsInList', result.countryIsInList);
                    if (result.countryIsInList) {
                        cmp.set('v.isShadowBanking', 'NO');
                    }
                } else if (result.valueType == 2) {
                    cmp.set('v.countryIsInListInsurence', result.countryIsInList);
                    if (result.countryIsInList) {
                        cmp.set('v.isShadowBanking', 'NO');
                    }
                } else if (result.valueType == 3) {
                    cmp.set('v.countryIsInListCorpo', result.countryIsInList);
                } else if (result.valueType == 0){
                    helper.showToast('Error', 'ERROR', 'Activity type not contemplated in flow');
                    helper.handleClose();
                }

                if(result.clientType != null){
                    cmp.set('v.typeShabdowBanking', result.clientType);
                }
                if(result.fundType == true){
                    cmp.set('v.isFundType', true);
                }
                if(result.insuranceType == true){
                    cmp.set('v.isInsuranceType', true);
                }
                if(result.corpoType == true){
                    cmp.set('v.isCorpoType', true);
                }
                if(result.financialType == true){
                    cmp.set('v.isFinancial', true);
                }
                if(result.clientInfo != null){
                    cmp.set('v.localClient', result.clientInfo);
                }

                // Set saved options
                if(result.scraBool != null){
                    cmp.set('v.isDoInit', true);

                    if(cmp.get('v.scraMark') != result.markSCRA){
                        cmp.set('v.scraMark', result.markSCRA);
                        helper.scraMarkChange(cmp, event, helper);
                    }

                    cmp.set('v.commentSCRA', result.commentSCRA);
                    // Set scraBool last to prevent value refresh from previous mappings
                    if(result.scraBool == true){
                        cmp.set('v.scra', 'YES');
                    }else{
                        cmp.set('v.scra', 'NO');
                    }
                    
                    cmp.set('v.isDoInit', false);
                }
                
                console.log('@@@Santi-ClientInfo',   JSON.parse(JSON.stringify(result.clientInfo)));

            }
        });
        $A.enqueueAction(action);
    },
    /* doInitOld: function(cmp, event, helper) {
        let localClient = cmp.get('v.localClient');
        let valueType = 1;
        
        //1 - Financial institution
        //2 - Insurance 
        //3 - CORPO
        //4 - FUNDS
        
        console.log(aha.arce__AHA_Extension__r.arce__IFIS_ClientType__c)
        switch (aha.arce__AHA_Extension__r.arce__IFIS_ClientType__c) {
            case 'B':
            case 'F':
            case 'G':
            case 'H':
            case 'I':
            case 'J':
                valueType = 4;
                cmp.set('v.isFundType', true);
                break;
            case 'A':
            case 'C':
                valueType = 1;
                cmp.set('v.isFinancial', true);
                break;
            case 'E':
                valueType = 3;
                cmp.set('v.isCorpoType', true);
                break;
            case 'N':
                valueType = 2;
                cmp.set('v.isInsuranceType', true);
                break;
            default:
                valueType = 1;
                cmp.set('v.isFinancial', true);
        }

        var action = cmp.get('c.getInitialData');
        console.log(aha.Id);
        console.log(valueType);
        action.setParams({
            'ahaId': aha.Id,
            'valueType': valueType
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                var result = response.getReturnValue();
                if (valueType == 1) {
                    cmp.set('v.countryIsInList', result.countryIsInList);
                    if (result.countryIsInList) {
                        cmp.set('v.isShadowBanking', 'NO');
                    }
                } else if (valueType == 2) {
                    cmp.set('v.countryIsInListInsurence', result.countryIsInList);
                    if (result.countryIsInList) {
                        cmp.set('v.isShadowBanking', 'NO');
                    }
                } else if (valueType == 3) {
                    cmp.set('v.countryIsInListCorpo', result.countryIsInList);
                }
            }
        });
        $A.enqueueAction(action);
    },
    handleCalculate: function(cmp, evt, helper) {
        let financialBool = cmp.get('v.isFinancial');
        let insurenceBool = cmp.get('v.isInsuranceType');
        let corpoBool = cmp.get('v.isCorpoType');
        let fundBool = cmp.get('v.isFundType');
        let value = cmp.get("v.isShadowBanking");
        console.log(corpoBool);
        if (financialBool) {
            console.log(cmp.get('v.InstitutionsSB'));
            value = cmp.get('v.InstitutionsSB');
        } else if (insurenceBool) {
            console.log(cmp.get('v.insurenceSB'));
            value = cmp.get('v.insurenceSB');
        } else if (corpoBool) {
            if (cmp.get('v.bankActSB') == 'NO') {
                console.log('NO');
                value = 'NO';
            } else {
                console.log('SI');
                if (cmp.get('v.bankOrInsurensCompanySB') == 'NO') {
                    console.log('NO');
                    if (cmp.get('v.isInsuranceCorpoComb') == 'NO') {
                        console.log('NO');
                        value = 'NO';
                    } else {
                        if (cmp.get('v.isEUInsuranceCorpoComb') == 'NO') {
                            console.log('NO');
                            value = 'YES';
                        } else {
                            console.log('SI');
                            value = 'NO';
                        }
                    }
                } else {
                    console.log('SI');
                    if (cmp.get('v.isEUBankCorpoComb') == 'NO') {
                        console.log('NO');
                        value = 'YES';
                    } else {
                        console.log('SI');
                        value = 'NO';
                    }
                }
            }
        } else if (fundBool) {
            if (cmp.get('v.MMFOrAIFsSB') == 'YES') {
                value = 'YES';
            } else {
                if (cmp.get('v.regulatedFundSB') == 'YES') {
                    value = 'NO';
                } else {
                    value = 'YES';
                }
            }
        }

        cmp.set("v.isShadowBanking", value);
        cmp.set("v.isEdit", true);
        console.log(value);
        helper.showToast('SUCCESS', 'Succes', 'Shadow Banking calculated.');
    }, 
    handleFirstCheck: function(cmp, evt, helper) {
        if (evt.getSource().get("v.checked")) {
            cmp.set('v.checkfirstSB', true);
        } else {
            cmp.set('v.checkfirstSB', false);
        }
    },*/
    handleOnSave: function(cmp, evt, helper) {
        cmp.set("v.disableSubmitBtn", true);
        
        var action = cmp.get('c.saveInfo');
        let localClient = cmp.get('v.localClient');
        let SB = cmp.get("v.isShadowBanking");
        let SBBool = false;
        let scra = cmp.get("v.scra");
		let scraMark = cmp.get("v.scraMark");
        let scraBool = false;
        var commentarioTxt = cmp.find("commentarioTxt").get("v.value");

        if (scra == 'YES') {
            scraBool = true;
        }
        
        if(scra != '----' && scraMark != '----'){
            action.setParams({
            'localClient': localClient,
            'sBBool': SBBool,
            'scraBool': scraBool,
			'markSCRA': scraMark,
            'commentarioTxt': commentarioTxt,
            'isScraOrSB': 'SCRA',
            'optionBankAct': '',
            'optionBankOrInsuranceCompany': '', 
            'optionEUBankCorpo': '',
            'optionInsuranceCorpo': '',
            'optionEUInsuranceCorpo': '', 
            'optionMMFOrAIFs': '',
            'optionRegulatedFund': '',
            'optionInstitutions': '',
            'optionInsurance': ''
            });
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === 'SUCCESS') {
                    /*let appEvent = $A.get('e.c:DPMX_SimulatorRefresh_evt');
                    appEvent.setParams({
                        'recordId': cmp.get('v.recordId')
                    });
                    appEvent.fire(); */
                    helper.showToast('SUCCESS', 'Succes', 'Information saved.');
                    //helper.handleClose(cmp, evt, helper);
                } else {
                    helper.showToast('Error', 'ERROR', 'The information is not been saved.');
                }
                cmp.set("v.disableSubmitBtn", false);
            });
            $A.enqueueAction(action);
        }else{
            helper.showToast('WARNING', 'Warning', 'Please fill all available options');
        }
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
    /* handleClose: function(cmp, evt, helper) {
        let appEvent = $A.get('e.c:DPMX_SimulatorRefresh_evt');
            appEvent.setParams({
            'recordId': cmp.get('v.recordId')
        });
        appEvent.fire(); 
        cmp.destroy();
    }, */
    handleClose: function(cmp, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
        setTimeout(function() {
            $A.get('e.force:refreshView').fire();
        }, 300); // 300 ms delay after closing to refresh view
    },
    handleTabSimulationSelected: function(cmp, event, helper) {
        let value = cmp.get('v.isScraTab');
        if (cmp.get('v.isScraTab')) {
            cmp.set('v.isScraTab', false);
            cmp.set("v.isEdit", true);
        } else {
            cmp.set('v.isScraTab', true);
            if (cmp.get("v.isShadowBanking") == '----') {
                cmp.set("v.isEdit", false);
            } else {
                cmp.set("v.isEdit", true);
            }
        }
    },
    /* bankingActivitiesChanges: function(cmp, event, helper) {
        let value = cmp.get('v.bankActSB');
        if (value == 'YES') {
            cmp.set('v.bankActivityCorpo', true);
            cmp.set('v.isEUBankCorpo', true);
            cmp.set('v.bankOrInsurensCompanySB', 'YES');
            cmp.set('v.isEUBankCorpoComb', 'YES');
            cmp.set('v.isEUInsuranceCorpoComb', 'YES');
            cmp.set('v.isInsuranceCorpoComb', 'NO');
        } else {
            cmp.set('v.bankActivityCorpo', false);
            cmp.set('v.isEUBankCorpo', false);
            cmp.set('v.isInsuranceCorpo', false);
            cmp.set('v.isEUInsuranceCorpo', false);
        }
    }, 
    bankOrInsurensCompanyChanges: function(cmp, event, helper) {
        let value = cmp.get('v.bankOrInsurensCompanySB');
        if (value == 'YES') {
            cmp.set('v.isEUBankCorpo', true);
            cmp.set('v.isInsuranceCorpo', false);
            cmp.set('v.isEUInsuranceCorpo', false);
            cmp.set('v.isEUBankCorpoComb', 'YES');
            cmp.set('v.isEUInsuranceCorpoComb', 'YES');
            cmp.set('v.isInsuranceCorpoComb', 'NO');
        } else {
            cmp.set('v.isEUBankCorpo', false);
            cmp.set('v.isInsuranceCorpo', true);
        }
    },
    isInsuranceOncange: function(cmp, event, helper) {
        let value = cmp.get('v.isInsuranceCorpoComb');
        if (value == 'YES') {
            cmp.set('v.isEUInsuranceCorpo', true);
        } else {
            cmp.set('v.isEUInsuranceCorpo', false);
        }
    },
    MMFOrAIFChanges: function(cmp, event, helper) {
        let value = cmp.get('v.MMFOrAIFsSB');
        if (value == 'YES') {
            cmp.set('v.MMFOrAIFsFunds', false);
        } else {
            cmp.set('v.MMFOrAIFsFunds', true);
        }
    },*/
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
    /* handleseeList: function(cmp, event, helper) {
        let attr = {
            'value': 1
        };
        helper.loadComponent(cmp, event, helper, 'arce_SB_CountriesList', attr).then($A.getCallback(newComponent => {
            let body = [];
            console.log(newComponent);
            body.push(newComponent);
            cmp.set('v.body', body);
        }));
    }, 
    checkComment: function(cmp) {
        var commentarioTxt = cmp.find("commentarioTxt").get("v.value");
        if (commentarioTxt.length != 0) {
            cmp.set("v.disableSubmitBtn", false);
        } else {
            cmp.set("v.disableSubmitBtn", true);
        }
    },*/
    scraChange: function(cmp, event, helper) {
        let valueSel = '';
        if(cmp.get('v.isDoInit') == false){
            valueSel = event.currentTarget.value;
            cmp.set('v.scra',valueSel);
        }else{
            valueSel = cmp.get('v.scra');
        }
    },
    scraMarkChange: function(cmp, event, helper) {
        let valueSel = '';
        if(cmp.get('v.isDoInit') == false){
            valueSel = event.currentTarget.value;
            cmp.set('v.scraMark',valueSel);
        }else{
            valueSel = cmp.get('v.scraMark');
        }
    },
    commentScraChange: function(cmp, event, helper) {
        let valueSel = '';
        if(cmp.get('v.isDoInit') == false){
            valueSel = event.currentTarget.value;
            cmp.set('v.commentSCRA',valueSel);
        }else{
            valueSel = cmp.get('v.commentSCRA');
        }
    }
})