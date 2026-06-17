({
    doInit: function(cmp, event, helper) {
        console.log(cmp.get('v.dynamicId'));
        var action = cmp.get('c.getData');
        action.setParams({
            'recordId': cmp.get('v.dynamicId')
        })
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                var result = response.getReturnValue();
                if (result.accountsOptions === undefined) {
                    console.log('accountsOptions void');
                } else {
                    var accountsOptions2 = [];
                    result.accountsOptions.forEach(options => {
                        console.log(options.companyName__c + ' - ' + options.Id);
                        options = {
                            "label": options.companyName__c, 
                            "value": options.Id
                        };
                        console.log(options);
                        accountsOptions2.push(options);
                    });
                }
                //cmp.set('v.accountsOptions', accountsOptions2);
                cmp.set('v.accountsFiltred', accountsOptions2);
                if (result.accountsSelected === undefined) {
                    console.log('accountsSelected void');
                } else {
                    var accountsSelected2 = [];
                    result.accountsSelected.forEach(selected => {
                        accountsSelected2.push(selected.Id);
                    });
                    console.log(accountsSelected2);
                    cmp.set('v.accountsSelected', accountsSelected2);
                    console.log(cmp.get('v.accountsSelected'));
                }

            } else if (state === 'INCOMPLETE') {
                console.log('INCOMPLETE', response);
            } else if (state === 'ERROR') {
                console.log('ERROR', response.getError());
            }
            //helper.doneWaiting(cmp);
        });
        $A.enqueueAction(action);
    },
    handleOnCancel: function(cmp, event, helper) {
        cmp.set("v.handleAddOpen", false);
        helper.destroyCmp(cmp, event, helper);
    },
    handleSearch: function(cmp, event, helper) {
        var accountSearch = cmp.find("accountSearch").get("v.value");
        var accountsOpt = cmp.get('v.accountsOptions');
        var arrObj = [];
        accountsOpt.forEach(function(accOpt) {
            var accountFiltred = new Object();
            if (accOpt.label.search(accountSearch.toUpperCase()) >= 0) {
                accountFiltred.label = accOpt.label;
                accountFiltred.value = accOpt.value;
                arrObj.push(accountFiltred);
            }
        });
        if (arrObj.length > 0) {
            cmp.set('v.accountsFiltred', arrObj);
        }
    },
    handleOnSave: function(cmp, event, helper) {
        console.log(cmp.get('v.dynamicId'));
        var action = cmp.get('c.saveData');
        action.setParams({
            'recordId': cmp.get('v.dynamicId'),
            'accountsSelected': cmp.get('v.accountsSelected')
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                var result = response.getReturnValue();
                let appEvent = $A.get('e.c:DPMX_SimulatorRefresh_evt');
                appEvent.setParams({
                    'recordId': cmp.get('v.dynamicId')
                });
                appEvent.fire();
                helper.destroyCmp(cmp, event, helper);
            } else if (state === 'INCOMPLETE') {
                console.log('INCOMPLETE', response);
            } else if (state === 'ERROR') {
                console.log('ERROR', response.getError());
            }
            //helper.doneWaiting(cmp);
        });
        $A.enqueueAction(action);
        //cmp.set("v.handleAddOpen", false);
    }
})