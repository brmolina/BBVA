({
    getInitialData: function(cmp, event, helper) {
        let aha = cmp.get('v.aha');
        let action = cmp.get('c.getInitialData');
        action.setParams({
            'accountRepresentativeId': aha.Id
        });
        action.setCallback(this, function(response) {
            let state = response.getState();
            if (state === 'SUCCESS') {
                let result = response.getReturnValue();
                if(result.succes){
                    cmp.set('v.acctList', result.acctList);
                }else{
                    helper.showToast('Error', 'Advertencia', 'No se han encontrado registros.');
                }
            }else{
                helper.showToast('Error', 'Error', 'Ha sucedido un error al mostrar la inforamción.');
            }
            helper.doneWaiting(cmp);
        });
        $A.enqueueAction(action);
    },
    handleMostrarInfo: function(cmp, event, helper) {
        let target = event.target;
        let rowIndex = target.getAttribute("data-row-index");
        let getStatus = cmp.get('v.acctList');
        let aha = getStatus[rowIndex];
        /*
        1 - Financial institution
        2 - Insurance 
        3 - CORPO
        4 - FUNDS
        */
        let typeShabdowBanking = 1;
        switch (aha.aha.arce__AHA_Extension__r.arce__IFIS_ClientType__c) {
            case 'B':
            case 'F':
            case 'G':
            case 'H':
            case 'I':
            case 'J':
                typeShabdowBanking = 4;
                break;
            case 'A':
            case 'C':
                typeShabdowBanking = 1;
                break;
            case 'E':
                typeShabdowBanking = 3;
                break;
            case 'N':
                typeShabdowBanking = 2;
                break;
            default:
                typeShabdowBanking = 1;
        }
        let attr = {
            'aha': aha.aha,
            'typeShabdowBanking': aha.type
        };
        helper.loadComponent(cmp, event, helper, 'arce_ShadowBanking', attr).then($A.getCallback(newComponent => {
            let body = [];
            body.push(newComponent);
            cmp.set('v.body', body);
        }));
    },
    handleMostrarInfoSCRA: function(cmp, event, helper) {
        let target = event.target;
        let rowIndex = target.getAttribute("data-row-index");
        let getStatus = cmp.get('v.acctList');
        let aha = getStatus[rowIndex];
        let attr = {
            'aha': aha.aha,
        };
        helper.loadComponent(cmp, event, helper, 'scra', attr).then($A.getCallback(newComponent => {
            let body = [];
            body.push(newComponent);
            cmp.set('v.body', body);
        }));
    },
    showToast: function(type, title, message) {
        let toastEvent = $A.get('e.force:showToast');
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
    handleOnCancel: function(cmp, evt, helper) {
        cmp.destroy();
    },
    loadComponent: function(cmp, event, helper, cmpName, cmpAttr) {
        helper.waiting(cmp);
        return new Promise($A.getCallback(function(resolve, reject) {
            $A.createComponent(
                'c:' + cmpName, cmpAttr,
                function(newCmp, status, errorMessage) {
                    if (status === 'SUCCESS') {
                        resolve(newCmp);
                    } else if (status === 'INCOMPLETE' || status === 'ERROR') {
                        helper.showToast('Error', 'Error', errorMessage);
                    }
                }
            );
        }));
    },
    getSearchData: function(cmp, event, helper) {
        helper.waiting(cmp);
        var action = cmp.get('c.getSearchData');
        let field = cmp.find("fildName").get("v.value");
        let name = cmp.find("filterName").get("v.value");
        let aha = cmp.get('v.aha');
        action.setParams({
            'accountRepresentativeId': aha.Id,
            'field': field,
            'name': name
        })
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                var result = response.getReturnValue();
                cmp.set('v.acctList', result.acctList);
                helper.doneWaiting(cmp);
            }
        });
        $A.enqueueAction(action);
    },
    handleChange: function(cmp, event) {
        let action = cmp.find("fildName").get("v.value");
        cmp.find("filterName").set("v.value","");
    },
    waiting: function(cmp) {
        cmp.set('v.waiting', true);
    },
    doneWaiting: function(cmp) {
        cmp.set('v.waiting', false);
    }
});