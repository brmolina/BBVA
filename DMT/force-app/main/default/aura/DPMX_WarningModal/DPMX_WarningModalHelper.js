({
    "doInit": function(cmp, evt, helper) {
        var action = cmp.get('c.getInitialData');
        action.setParams({
            'recordId': cmp.get('v.recordId'),
        })
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                var result = response.getReturnValue();
                if (result.errorTab) {} else {
                    cmp.set('v.minDate', result.minDate);
                    console.log(result.minDate);
                }
            } else {
                helper.showToast('Error', 'error', state);
            }
        });
        $A.enqueueAction(action);
    },
    handleSave: function(cmp, evt, helper) {
        let templateName = 'DPMX_SendReportForFormalize';
        let fomralizeExist = cmp.get('v.formalizeExist');
        helper.checkCC(cmp);
        let checkCC = cmp.get('v.checkCC');
        let asunto = cmp.find("asunto").get("v.value");
        let userName = cmp.find("existingUser").get("v.value");
        let userLst = cmp.get("v.usersToODTLst");
        let userId = '';
        let saludo = '';
        let intro = '';
        let close = '';
        let initDate = cmp.find("initDate").get("v.value");
        let revisionDate = cmp.find("revisionDate").get("v.value");
        var action = cmp.get('c.sendReport');
        action.setParams({
            'recordId': cmp.get('v.recordId'),
        })
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                var result = response.getReturnValue();
                if (result.sendReport) {
                    helper.showToast('SUCCESS', 'CORREO ENVIADO', 'El correo se ha enviado.');
                } else {
                    helper.showToast('Error', 'CORREO NO ENVIADO', result.status);
                }

            } else {
                console.log(state);
                helper.showToast('Error', 'error', state);
            }
            helper.handleClose(cmp, evt, helper);
        });
        $A.enqueueAction(action);
    },
    handleClose: function(cmp, evt, helper) {
        cmp.destroy();
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