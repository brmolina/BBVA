({
    getInitialData: function(cmp, event, helper) {
        var action = cmp.get('c.getInitialData');
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                var result = response.getReturnValue();
                cmp.set('v.acctList', result.groupAccLst);
                cmp.set('v.pagenumber', result.pagenumber);
                cmp.set('v.changePage', 0);
            }
        });
        $A.enqueueAction(action);
    },
    handleChange: function(cmp, event) {
        let action = cmp.find("fildName").get("v.value");
    },
    handlefilter: function(cmp, event, helper) {
        let action = cmp.find("filterName").get("v.value");
    },
    getSearchData: function(cmp, event, helper) {
        var action = cmp.get('c.getSearchData');
        let field = cmp.find("fildName").get("v.value");
        let name = cmp.find("filterName").get("v.value");
        action.setParams({
            'field': field,
            'name': name
        })
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                var result = response.getReturnValue();
                cmp.set('v.changePage', 0);
                if(result.succes){
                    cmp.set('v.acctList', result.groupAccLst);
                }else{
                    helper.showToast('Error', 'error', result.msgError);
                }
            }
        });
        $A.enqueueAction(action);
    },
    handleMostrarInfo: function(cmp, event, helper) {
        var target = event.target;
        var rowIndex = target.getAttribute("data-row-index");
        var getStatus = cmp.get('v.acctList');
        var aha = getStatus[rowIndex];
        let attr = {
            'aha': aha
        };
        helper.loadComponent(cmp, event, helper, 'arce_SB_ClientInfoOverview', attr).then($A.getCallback(newComponent => {
            let body = [];
            body.push(newComponent);
            cmp.set('v.body', body);
        }));
    },
    nextPage: function(cmp, event, helper) {
        cmp.set('v.changePage', 1);
        helper.getSearchData(cmp, event, helper);
    },
    previusPage: function(cmp, event, helper) {
        cmp.set('v.changePage', -1);
        helper.getSearchData(cmp, event, helper);
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
    }
});