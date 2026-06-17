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
            
                if(result.clientType != null){
                    cmp.set('v.typeShabdowBanking', result.clientType);
                }
                
                if(result.clientInfo != null){
                    cmp.set('v.localClient', result.clientInfo);
                }

                // Set saved options
                if(result.SBBool != null){

                    cmp.set('v.isDoInit', true); //Set variable to check in helper functions

                    //Check previous value in case we dont need to modify, by default values are "----"
                    if(cmp.get('v.bankActSB') != result.optionBankAct){
                        cmp.set('v.bankActSB', result.optionBankAct);
                        helper.bankingActivitiesChanges(cmp, event, helper);
                    }
                    
                    if(cmp.get('v.bankOrInsuranceCompanySB') != result.optionBankOrInsuranceCompany){
                        cmp.set('v.bankOrInsuranceCompanySB', result.optionBankOrInsuranceCompany);
                        helper.bankOrInsuranceCompanyChanges(cmp, event, helper);
                    } 

                    if(cmp.get('v.isEUBankCorpoComb') != result.optionEUBankCorpo){
                        cmp.set('v.isEUBankCorpoComb', result.optionEUBankCorpo);
                        helper.belongEU(cmp, event, helper);
                    }
                    
                    if(cmp.get('v.isInsuranceCorpoComb') != result.optionInsuranceCorpo){
                        cmp.set('v.isInsuranceCorpoComb', result.optionInsuranceCorpo);
                        helper.isInsuranceOnChange(cmp, event, helper);
                    }
                    
                    if(cmp.get('v.isEUInsuranceCorpoComb') != result.optionEUInsuranceCorpo){
                        cmp.set('v.isEUInsuranceCorpoComb', result.optionEUInsuranceCorpo);
                        helper.handleisEUInsuranceCorpoComb(cmp, event, helper);
                    }
                    
                    if(cmp.get('v.MMFOrAIFsSB') != result.optionMMFOrAIFs){
                        cmp.set('v.MMFOrAIFsSB', result.optionMMFOrAIFs);
                        helper.MMFOrAIFChanges(cmp, event, helper);
                    }
                    
                    if(cmp.get('v.regulatedFundSB') != result.optionRegulatedFund){
                        cmp.set('v.regulatedFundSB', result.optionRegulatedFund);
                        helper.regulatedFundsChanges(cmp, event, helper);
                    }
                    
                    if(cmp.get('v.InstitutionsSB') != result.optionInstitutions){
                        cmp.set('v.InstitutionsSB', result.optionInstitutions);
                        helper.bankingchange(cmp, event, helper);
                    }
                    
                    if(cmp.get('v.insuranceSB') != result.optionInsurance){
                        cmp.set('v.insuranceSB', result.optionInsurance);
                        helper.insuranceChanges(cmp, event, helper);
                    }

                    if(cmp.get('v.flowSelectSB') != result.flowSelectSB){
                        cmp.set('v.flowSelectSB', result.flowSelectSB);
                        helper.flowSelectChange(cmp, event, helper);
                    }

                    cmp.set('v.commentSB', result.commentSB);
                    if(result.SBBool == true){
                        cmp.set('v.isShadowBanking', 'YES');
                    }else{
                        cmp.set('v.isShadowBanking', 'NO');
                    }

                    // If has already been calculated enable submit button
                    cmp.set("v.isEdit", true);
                    cmp.set("v.disableSubmitBtn", false);
                    cmp.set('v.isDoInit', false);
                }
            }
        });
        $A.enqueueAction(action);
    },
    fluxCorpoIsBankAvtSB: function(cmp, event, helper, value) {
        //Financial Corporations second validation
            if (cmp.get('v.bankOrInsuranceCompanySB') === 'NO') {
                if (cmp.get('v.isInsuranceCorpoComb') === 'NO') {
                    value = 'YES';
                } else if(cmp.get('v.isInsuranceCorpoComb') === 'YES'){
                    if (cmp.get('v.isEUInsuranceCorpoComb') === 'NO') {
                        value = 'YES';
                    } else if (cmp.get('v.isEUInsuranceCorpoComb') === 'YES'){
                        value = 'NO';
                    }
                }
            } else if (cmp.get('v.bankOrInsuranceCompanySB') === 'YES'){
                if (cmp.get('v.isEUBankCorpoComb') === 'NO') {
                    value = 'YES';
                } else if (cmp.get('v.isEUBankCorpoComb') === 'YES'){
                    value = 'NO';
                }
            } else{
                value = '----';
            }
            return value;
    },
    fluxCorpo: function(cmp, event, helper, value) {
        //Financial Corporations
        if (cmp.get('v.bankActSB') === 'NO') {
            value = 'NO';
        } else if (cmp.get('v.bankActSB') === 'YES'){
            value = helper.fluxCorpoIsBankAvtSB(cmp, event, helper, value);
        } else{
                value = '----';
        }
        return value;
    },
    fluxFinancial: function(cmp, event, helper, value) {
        //Banks
        let InstitutionsSB = cmp.get('v.InstitutionsSB');
        if (cmp.get('v.countryIsInList')) {
            value = 'NO';
        }else{
            if(InstitutionsSB === 'NO'){
                value = 'YES';
            }else if (InstitutionsSB === 'YES'){
                value = 'NO';
            }else{
                value = '----';
            }
        }
        return value;
    },
    fluxInsurance: function(cmp, event, helper, value) {
        //Insurance
        if (cmp.get('v.countryIsInListInsurance')) {
            value = 'NO';
        }else{
            if(cmp.get('v.insuranceSB') === 'YES'){
                value = 'YES';
            }else if(cmp.get('v.insuranceSB') === 'NO') {
                value = 'NO';
            }else{
                value = '----';
            }
        }
        return value;
    },
    fluxFunds: function(cmp, event, helper, value) {
        //Funds
        if (cmp.get('v.MMFOrAIFsSB') === 'YES') {
            value = 'YES';
        } else if (cmp.get('v.MMFOrAIFsSB') === 'NO')  {
            if (cmp.get('v.regulatedFundSB') === 'YES') {
                value = 'NO';
            } else if (cmp.get('v.regulatedFundSB') === 'NO'){
                value = 'YES';
            } else {
                value = '----';
            }
        } else {
            value = '----';
        }
        return value;
    },
    handleCalculate: function(cmp, event, helper) {
        let financialBool = cmp.get('v.isFinancial');
        let insuranceBool = cmp.get('v.isInsuranceType');
        let corpoBool = cmp.get('v.isCorpoType');
        let fundBool = cmp.get('v.isFundType');
        let value = cmp.get("v.isShadowBanking");
        
        if (financialBool) {
            value = helper.fluxFinancial(cmp, event, helper, value);
        } else if (insuranceBool) {
            value = helper.fluxInsurance(cmp, event, helper, value);
        } else if (corpoBool) {
            value = helper.fluxCorpo(cmp, event, helper, value);
        } else if (fundBool) {
            value = helper.fluxFunds(cmp, event, helper, value);
        }
        if(value == 'YES' || value == 'NO'){
            cmp.set("v.isEdit", true);
            cmp.set("v.disableSubmitBtn", false);
            helper.showToast('SUCCESS', 'Succes', 'Shadow Banking calculated.');
        }else{
            helper.showToast('WARNING', 'warning', 'All available options must be selected.');
        }
        cmp.set("v.isShadowBanking", value);
        
    },
    handleFirstCheck: function(cmp, event, helper) {
        if (event.getSource().get("v.checked")) {
            cmp.set('v.checkfirstSB', true);
        } else {
            cmp.set('v.checkfirstSB', false);
        }
    },
    handleOnSave: function(cmp, event, helper) {
        cmp.set("v.disableSubmitBtn", true);
        
        var action = cmp.get('c.saveInfo');
        let localClient = cmp.get('v.localClient');
        let SB = cmp.get("v.isShadowBanking");
        let SBOverrideBool = cmp.get("v.checkfirstSB");
        let SBOverride = cmp.get("v.financialSecondCB");
        let SBBool = false;
        let scraMark = '';
        let scraBool = false;
        var commentarioTxt = cmp.get("v.commentSB");
        let optionBankAct = cmp.get("v.bankActSB");
        let optionBankOrInsuranceCompany = cmp.get("v.bankOrInsuranceCompanySB");
        let optionEUBankCorpo = cmp.get("v.isEUBankCorpoComb");
        let optionInsuranceCorpo = cmp.get("v.isInsuranceCorpoComb");
        let optionEUInsuranceCorpo= cmp.get("v.isEUInsuranceCorpoComb");
        let optionMMFOrAIFs = cmp.get("v.MMFOrAIFsSB");
        let optionRegulatedFund = cmp.get("v.regulatedFundSB");
        let optionInstitutions = cmp.get("v.InstitutionsSB");
        let optionInsurance = cmp.get("v.insuranceSB");
        let selectedFlowId = cmp.get("v.flowSelectSB");

        if(SBOverrideBool){
            if (SBOverride === 'YES') {
                SBBool = true;
            }
        }else{
            if (SB === 'YES') {
                SBBool = true;
            }
        }

        action.setParams({
            'localClient': localClient,
            'sBBool': SBBool,
            'scraBool': scraBool,
            'markSCRA': scraMark,
            'commentarioTxt': commentarioTxt,
            'isScraOrSB': 'SB',
            'optionBankAct': optionBankAct,
            'optionBankOrInsuranceCompany': optionBankOrInsuranceCompany, 
            'optionEUBankCorpo': optionEUBankCorpo,
            'optionInsuranceCorpo': optionInsuranceCorpo,
            'optionEUInsuranceCorpo': optionEUInsuranceCorpo, 
            'optionMMFOrAIFs': optionMMFOrAIFs,
            'optionRegulatedFund': optionRegulatedFund,
            'optionInstitutions': optionInstitutions,
            'optionInsurance': optionInsurance,
            'selectedFlowId': selectedFlowId
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                helper.showToast('SUCCESS', 'Succes', 'Information saved.');
                /* let appEvent = $A.get('e.c:DPMX_SimulatorRefresh_evt');
                appEvent.setParams({
                    'recordId': cmp.get('v.recordId')
                });
                appEvent.fire();
                helper.handleClose(cmp, event, helper); */
            } else {
                helper.showToast('Error', 'ERROR', 'The information has not been saved.');
            }
            cmp.set("v.disableSubmitBtn", false);            
        });
        $A.enqueueAction(action);
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
    /* handleClose: function(cmp, event, helper) {
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
    bankingActivitiesChanges: function(cmp, event, helper) {
        let valueSel = '';
        if(cmp.get('v.isDoInit') == false){
            valueSel = event.currentTarget.value;
            cmp.set('v.bankActSB',valueSel);
        }else{
            valueSel = cmp.get('v.bankActSB');
        }
        
        if (valueSel === 'YES') {
            cmp.set('v.bankActivityCorpo', true);
            cmp.set('v.isEUBankCorpo', true);
            cmp.set('v.bankOrInsuranceCompanySB', 'YES');
            cmp.set('v.isEUBankCorpoComb', 'YES');
            cmp.set('v.isEUInsuranceCorpoComb', 'YES');
            cmp.set('v.isInsuranceCorpoComb', 'NO');
        } else if (valueSel === 'NO') {
            cmp.set('v.bankActivityCorpo', false);
            cmp.set('v.isEUBankCorpo', false);
            cmp.set('v.isInsuranceCorpo', false);
            cmp.set('v.isEUInsuranceCorpo', false);
            /* cmp.set('v.bankOrInsuranceCompanySB', '----');
            cmp.set('v.isEUBankCorpoComb', '----');
            cmp.set('v.isEUInsuranceCorpoComb', '----');
            cmp.set('v.isInsuranceCorpoComb', '----'); */
        }
        helper.resetSBValue(cmp);
    },
    belongEU: function(cmp, event, helper) {
        helper.resetSBValue(cmp);
        let valueSel = '';
        if(cmp.get('v.isDoInit') == false){
            valueSel = event.currentTarget.value;
            cmp.set('v.isEUBankCorpoComb',valueSel);
        }else{
            valueSel = cmp.get('v.isEUBankCorpoComb');
        }        
    },
    handleisEUInsuranceCorpoComb: function(cmp, event, helper) {
        helper.resetSBValue(cmp);
        let valueSel = '';
        if(cmp.get('v.isDoInit') == false){
            valueSel = event.currentTarget.value;
            cmp.set('v.isEUInsuranceCorpoComb',valueSel);
        }else{
            valueSel = cmp.get('v.isEUInsuranceCorpoComb');
        }
    },
    bankOrInsuranceCompanyChanges: function(cmp, event, helper) {
        helper.resetSBValue(cmp);
        let valueSel = '';
        if(cmp.get('v.isDoInit') == false){
            valueSel = event.currentTarget.value;
            cmp.set('v.bankOrInsuranceCompanySB',valueSel);
        }else{
            valueSel = cmp.get('v.bankOrInsuranceCompanySB');
        }

        let isInsuranceBool = false;
        let isEUBankCorpoBool = true;
        if (valueSel === 'YES') {
            cmp.set('v.isEUInsuranceCorpo', false);
            cmp.set('v.isEUBankCorpoComb', 'YES');
            cmp.set('v.isEUInsuranceCorpoComb', 'YES');
            cmp.set('v.isInsuranceCorpoComb', 'NO');
        } else if (valueSel === 'NO') {
            isEUBankCorpoBool = false;
            isInsuranceBool = true;
            cmp.set('v.isEUInsuranceCorpo', true);
        }
        cmp.set('v.isEUBankCorpo', isEUBankCorpoBool);
        cmp.set('v.isInsuranceCorpo', isInsuranceBool); 
    },
    isInsuranceOnChange: function(cmp, event, helper) {
        helper.resetSBValue(cmp);
        let valueSel = '';
        if(cmp.get('v.isDoInit') == false){
            valueSel = event.currentTarget.value;
            cmp.set('v.isInsuranceCorpoComb',valueSel);
        }else{
            valueSel = cmp.get('v.isInsuranceCorpoComb');
        }

        if (valueSel === 'YES') {
            cmp.set('v.isEUInsuranceCorpo', true);
        } else if (valueSel === 'NO'){
            cmp.set('v.isEUInsuranceCorpo', false);
            cmp.set('v.isEUInsuranceCorpoComb','YES');
        }
    },
    bankingchange: function(cmp, event, helper) {
        helper.resetSBValue(cmp);
        let valueSel = '';
        if(cmp.get('v.isDoInit') == false){
            valueSel = event.currentTarget.value;
            cmp.set('v.InstitutionsSB',valueSel);
        }else{
            valueSel = cmp.get('v.InstitutionsSB');
        }
    },
    insuranceChanges: function(cmp, event, helper) {
        helper.resetSBValue(cmp);
        let valueSel = '';
        if(cmp.get('v.isDoInit') == false){
            valueSel = event.currentTarget.value;
            cmp.set('v.insuranceSB',valueSel);
        }else{
            valueSel = cmp.get('v.insuranceSB');
        }
    },
    regulatedFundsChanges: function(cmp, event, helper) {
        helper.resetSBValue(cmp);
        let valueSel = '';
        if(cmp.get('v.isDoInit') == false){
            valueSel = event.currentTarget.value;
            cmp.set('v.regulatedFundSB',valueSel);
        }else{
            valueSel = cmp.get('v.regulatedFundSB');
        }
    },SBAdjustChange: function(cmp, event, helper) {
        let valueSel = event.currentTarget.value;
        cmp.set('v.financialSecondCB',valueSel);
    },
    MMFOrAIFChanges: function(cmp, event, helper) {
        helper.resetSBValue(cmp);
        let valueSel = '';
        if(cmp.get('v.isDoInit') == false){
            valueSel = event.currentTarget.value;
            cmp.set('v.MMFOrAIFsSB',valueSel);
        }else{
            valueSel = cmp.get('v.MMFOrAIFsSB');
        }

        if (valueSel === 'YES') {
            cmp.set('v.MMFOrAIFsFunds', false);
        } else if (valueSel === 'NO'){
            cmp.set('v.MMFOrAIFsFunds', true);
            cmp.set('v.regulatedFundSB','YES');
        }
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
    handleseeList: function(cmp, event, helper) {
        var isBank;
         switch (true) {
            case cmp.get('v.isFinancial'):
                isBank = true;
                break;
            case cmp.get('v.isInsuranceType'):
                isBank = false;
                break;
            case cmp.get('v.isCorpoType'):
                if(cmp.get('v.bankOrInsuranceCompanySB') === 'YES'){
                    isBank = true;
                }else if(cmp.get('v.isInsuranceCorpoComb') === 'YES') {
                    isBank = false;
                }
                break;
        }
        let attr = {
            'isBank': isBank
        };
        helper.loadComponent(cmp, event, helper, 'arce_SB_CountriesList', attr).then($A.getCallback(newComponent => {
            let body = [];
            body.push(newComponent);
            cmp.set('v.body', body);
        }));
    },
    /* checkComment: function(cmp) {
        var commentarioTxt = cmp.find("commentarioTxt").get("v.value");
        if (commentarioTxt.length != 0) {
            cmp.set("v.disableSubmitBtn", false);
        } else {
            cmp.set("v.disableSubmitBtn", true);
        }
    }, */
    commentSbChange: function(cmp, event, helper) {
        let valueSel = event.currentTarget.value;
        cmp.set('v.commentSB',valueSel);
    },
    handleActivitiesList: function(cmp, event, helper) {
        helper.loadComponent(cmp, event, helper, 'arce_SB_BankActivity').then($A.getCallback(newComponent => {
            let body = [];
            body.push(newComponent);
            cmp.set('v.body', body);
        }));
    },
    resetSBValue: function(cmp) {
        cmp.set("v.isShadowBanking", '----');
		cmp.set("v.isEdit", false);
    },
    flowSelectChange: function(cmp, event, helper) {
        helper.resetSBValue(cmp);
        let selectedflowId = '';
        if(cmp.get('v.isDoInit') == false){
            selectedflowId = event.currentTarget.value;
            
            //Reset values
            cmp.set('v.bankActSB', '----');
            cmp.set('v.bankOrInsuranceCompanySB', '----');
            cmp.set('v.isEUBankCorpoComb', '----');
            cmp.set('v.isEUInsuranceCorpoComb', '----');
            cmp.set('v.isInsuranceCorpoComb', '----');
            cmp.set('v.MMFOrAIFsSB', '----');
            cmp.set('v.InstitutionsSB', '----');
            cmp.set('v.insuranceSB', '----');
            cmp.set('v.regulatedFundSB', '----');
            cmp.set('v.bankActivityCorpo', false);
            cmp.set('v.isInsuranceCorpo', false);
            cmp.set('v.isEUInsuranceCorpo', false);
            cmp.set('v.MMFOrAIFsFunds', false);
            

            cmp.set('v.flowSelectSB', selectedflowId);
        }else{
            selectedflowId = cmp.get('v.flowSelectSB');
        }

        let countryCode = cmp.get('v.localClient.g_residence_country_id__c');

        var action = cmp.get('c.checkCountryIsInList');
        action.setParams({
            'clientFlowId': selectedflowId,
            'countryCode' : countryCode
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                var result = response.getReturnValue();

                //Reset Values
                cmp.set('v.isFinancial', false);
                cmp.set('v.isInsuranceType', false);
                cmp.set('v.isCorpoType', false);
                cmp.set('v.isFundType', false);

                switch (selectedflowId) {
                    
                    case '1': //1 - Banks, Institutions & Investment Firms
                        
                        cmp.set('v.isFinancial', true);
                        cmp.set('v.countryIsInList', result.countryIsInList);
                        break;
                    
                    case '2': //2 - Insurance 
                        cmp.set('v.isInsuranceType', true);
                        cmp.set('v.countryIsInListInsurance', result.countryIsInList);
                        break;
                    
                    case '3': //3 - Financial Corporations engaged in Lending, Leasing...
                        cmp.set('v.isCorpoType', true);
                        cmp.set('v.countryIsInListCorpo', result.countryIsInList);
                        break;
                    
                    case '4': //4 - Funds
                        cmp.set('v.isFundType', true);
                        break;
                }
            }
        });
        $A.enqueueAction(action);     
    }
})