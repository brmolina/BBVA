({
    "doInit": function(cmp, evt, helper) {
        const isCustom = cmp.get('v.isCustom');
        const dynamicPricing = cmp.get('v.dynamicPricing');
        if (isCustom) {
            const resultRates = cmp.get('v.resultRates');
            if (resultRates === 'Break even' || resultRates === 'Minimo viable') {
                cmp.set('v.breakEvenSelectedBool', true);
            }
        } else {
            const conditionList = cmp.get('v.sendConditionLst')[0];
            if (conditionList.scenarioType === 'BREAK_EVEN' || conditionList.scenarioType === 'Minimo viable') {
                cmp.set('v.breakEvenSelectedBool', true);
                cmp.set('v.sectionLst', conditionList.fees);
            }
        }

        var action = cmp.get('c.getInitialData');
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                var result = response.getReturnValue();
                cmp.set('v.usersToAuthLst', result.usersToAuthLst);
                cmp.set('v.usersToAuthNamesLst', result.usersToAuthNamesLst);
            } else {
                helper.showToast('Error', 'Operación no realizada', 'Se ha producido un error al cargar la información. Inténtelo de nuevo.');
                cmp.destroy();
            }
        });
        $A.enqueueAction(action);
    },
    "closeModal": function(cmp) {
        cmp.destroy();
    },
    "checkComment": function(cmp) {
        var commentarioTxt = cmp.find("commentarioTxt").get("v.value");
        let userName = cmp.find("existingUser").get("v.value");
        if (commentarioTxt != null && commentarioTxt.length != 0 && userName.length != 0) {
            cmp.set("v.disableSubmitBtn", false);
        } else {
            cmp.set("v.disableSubmitBtn", true);
        }
    },
    "saveAuth": function(cmp, evt, helper) {
        const isCustom = cmp.get('v.isCustom');
        var isGs = cmp.get('v.isGs');
        const resultRates = cmp.get('v.resultRates');
        if (isCustom) {
            var debit = cmp.get('v.updDebit');
            var credit = cmp.get('v.updCredit');
            var international = cmp.get('v.updInternational');
            var profability = cmp.get('v.updRenta');
            var bai = cmp.get('v.updBai');
        } else {
            var itemsFees = cmp.get('v.sectionLst.itemizeFees');
            for (let i = 0; i < itemsFees.length; i++) {
                switch (itemsFees[i].feeType) {
                    case 'DEBIT':
                        var debit;
                        if (isGs) {
                            debit = itemsFees[i].itemizeFeeUnit.amount;
                        } else {
                            debit = itemsFees[i].itemizeFeeUnit.value;
                        }
                        break;
                    case 'CREDIT':
                        var credit = itemsFees[i].itemizeFeeUnit.value;
                        break;
                    case 'INTERNATIONAL':
                        var international = itemsFees[i].itemizeFeeUnit.value;
                        break;
                }
            }
            var profability = cmp.get('v.sectionLst.profitability.percentage');
            var bai = cmp.get('v.sectionLst.profitability.amount.amount');

        }
        let userId = '';
        let userName = cmp.find("existingUser").get("v.value");
        let userLst = cmp.get("v.usersToAuthLst");
        for (let i = 0; i < userLst.length; i++) {
            if (userLst[i].Assignee.Name == userName) {
                userId = userLst[i].AssigneeId;
            }
        }
        console.log(cmp.get('v.family'));
        var action = cmp.get('c.createAuthorization');
        action.setParams({
            'commentarioTxt': cmp.find("commentarioTxt").get("v.value"),
            'DPAut': cmp.get('v.dynamicPricing'),
            'debit': debit.toFixed(2),
            'credit': credit.toFixed(2),
            'international': international.toFixed(2),
            'profability': profability,
            'bai': bai,
            'isGs': isGs,
            'debitBase': cmp.get('v.debitBase').toFixed(2),
            'creditBase': cmp.get('v.creditBase').toFixed(2),
            'internationalBase': cmp.get('v.internationalBase').toFixed(2),
            'baiBase': cmp.get('v.baiBase'),
            'rentaBase': cmp.get('v.rentaBase'),
            'family': cmp.get('v.family'),
            'userId': userId,
            'resultRates': resultRates
        })
        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log('INIT');
            if (state === 'SUCCESS') {
                console.log(state);
                var result = response.getReturnValue();
                console.log(result);
                if (result.true) {
                    helper.showToast('Error', 'Operación no realizada', 'Se ha producido un error al cargar la información. Inténtelo de nuevo.');
                } else {
                    helper.showToast('SUCCESS', 'Registro creado!', 'Se ha avisado al usuario encargado de la autorización.');
                }
                cmp.destroy();
            } else {
                helper.showToast('Error', 'Operación no realizada', 'Se ha producido un error al cargar la información. Inténtelo de nuevo.');
            }
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
    }
})