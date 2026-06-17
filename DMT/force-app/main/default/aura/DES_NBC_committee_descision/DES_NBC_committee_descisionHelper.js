({
    getTemplate: function (component, event, helper, opp) {
        var action = component.get("c.gtNBCTemplate");
        action.setParams({
            oppId: opp
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                if (response.getReturnValue().length !== 0) {
                    var nbc=response.getReturnValue();
                    helper.setAtributes(component, event, helper,nbc);
                }
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " +
                            errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        $A.enqueueAction(action);
    },

    setAtributes: function (component, event, helper,values) {
        component.set('v.OppName', values[0].opportunity_id__r.Name);
        component.set('v.ClientName', values[0].opportunity_id__r.Account.Name);
        component.set('v.Description', values[0].opportunity_nbc_comments_desc__c);
         var viewList = component.find("view2");
        var description = component.find("description");
        var hide = document.getElementsByClassName("hide2");
        if (values[0].opportunity_nbc_comments_desc__c == null) {
            component.set('v.descLen', 0);
        } else {
            component.set('v.descLen', values[0].opportunity_nbc_comments_desc__c.length);
            var espacing = '<p>';
            var r = values[0].opportunity_nbc_comments_desc__c.indexOf(espacing);
            var c = 0;
            var espacing2 = '<li>';
            var r = values[0].opportunity_nbc_comments_desc__c.indexOf(espacing);
            while (r !== -1) {
                c++;
                r = values[0].opportunity_nbc_comments_desc__c.indexOf(espacing, r + 1);
            }
            var w = values[0].opportunity_nbc_comments_desc__c.indexOf(espacing2);
            console.log(w);
            while (w !== -1) {
                c+=4/6;
                console.log(c);
                w = values[0].opportunity_nbc_comments_desc__c.indexOf(espacing2, w + 1);
            }
            component.set('v.numberof', c);
            if(c <= 4){
                for (var iterator2 = 0; iterator2 < hide.length; iterator2++) {
                    $A.util.addClass(hide[iterator2], 'slds-hide');
                }
                $A.util.addClass(description, 'littel');
                $A.util.removeClass(viewList, 'slds-hide');
            }
        }
        helper.decisionTaken(component, event, helper, values);
    },
    getVotes: function (component, event, helper, opp) {
        var action = component.get("c.gtNBCMembers");
        action.setParams({
            oppId: opp,
            recordId: component.get("v.recordId")
        });
        var non = 0;
        var supp = 0;
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                for (var iterator = 0; iterator < response.getReturnValue().length; iterator++) {
                    if (response.getReturnValue()[iterator].gf_virtual_cmtee_supp_ind_type__c === $A.get("$Label.c.DES_Non_Supportive")) {
                        non++;
                    } else if (response.getReturnValue()[iterator].gf_virtual_cmtee_supp_ind_type__c === $A.get("$Label.c.DES_Supportive")) {
                        supp++;
                    }
                    component.set('v.commiteUser', response.getReturnValue());
                }
                helper.changecolors(non, supp, component);
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " +
                            errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        $A.enqueueAction(action);
    },
    changecolors: function (non, supp, component) {
        if (non !== 0) {
            component.set('v.NotSupportive', non);
        } else {
            component.set('v.NotSupportive', '-');
        }
        if (supp !== 0) {
            component.set('v.Supportive', supp);
        } else {
            component.set('v.Supportive', '-');
        }
    },
    updatevote: function (membervote, component, event, helper) {
        var action = component.get("c.updateNBCvote");
        var opps = component.get('v.oppId');
        action.setParams({
            recordId: component.get("v.recordId"),
            vote: membervote,
            oppId: opps
        });
        return new Promise($A.getCallback(function (resolve, reject) {
            action.setCallback(this, function (response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    component.set('v.endpoint', true);
                    if (response.getReturnValue() === null) {
                        resolve('Not User');
                    }
                } else if (state === "ERROR") {
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.log("Error message: " +
                                errors[0].message);
                        }
                    } else {
                        console.log("Unknown error");
                    }
                }
            })
            $A.enqueueAction(action);
        }));
    },
    colorVotes: function (component, event, helper) {
        var users = component.get('v.commiteUser');
        for (var iterator = 0; iterator < users.length; iterator++) {
            var viewList = document.getElementById(users[iterator].gf_oppy_virtual_cmtee_user_id__c);
            if (users[iterator].gf_virtual_cmtee_supp_ind_type__c === $A.get("$Label.c.DES_Supportive")) {
                $A.util.addClass(viewList, 'Sup');
            } else if (users[iterator].gf_virtual_cmtee_supp_ind_type__c === $A.get("$Label.c.DES_Non_Supportive")) {
                $A.util.addClass(viewList, 'NonSup');
            }
        }
    },
    decisionTaken: function (component, event, helper, opp) {
        for (var iterator = 0; iterator < opp.length; iterator++) {
            if (opp[iterator].opportunity_id__r.NBC_decision_type__c === true) {
                component.set('v.endpoint', true);
                if (opp[iterator].opportunity_id__r.NBC_Decision_Taken_type__c === $A.get("$Label.c.NBC_Decision_Recommended")) {
                    $A.util.addClass(component.find("decision2"), 'decisionYes');
                    $A.util.removeClass(component.find("decision1"), 'decisionNon');
                } else if (opp[iterator].opportunity_id__r.NBC_Decision_Taken_type__c === $A.get("$Label.c.NBC_Decision_Not_Recommended")) {
                    $A.util.addClass(component.find("decision1"), 'decisionNon');
                    $A.util.removeClass(component.find("decision2"), 'decisionYes');
                }
            } else {
                component.set('v.endpoint', false);
                $A.util.removeClass(component.find("decision2"), 'decisionYes');
                $A.util.removeClass(component.find("decision1"), 'decisionNon');
            }
        }
    },
    refresh: function (component, event, helper) {
        var eventTest = $A.get('e.c:refreshVotes');
        eventTest.fire();
    },
    getUserRelated: function (component, event, helper) {
        var action = component.get("c.getUserRelated");
        action.setParams({
            oppId: component.get("v.oppId")
        });
        return new Promise($A.getCallback(function (resolve, reject) {
            action.setCallback(this, function (response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    console.log(response.getReturnValue());
                    component.set('v.canSee', response.getReturnValue());
                    if (response.getReturnValue() === null) {
                        resolve('enter');
                    }
                } else if (state === "ERROR") {
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.log("Error message: " +
                                errors[0].message);
                        }
                    } else {
                        console.log("Unknown error");
                    }
                }
            })
            $A.enqueueAction(action);
        }));
    },
    viewmore2: function (component, event, helper) {
        var viewList = component.find("view2");
        var description = component.find("description");
        var hide = document.getElementsByClassName("hide2");
        if (viewList[0].getElement().className !== 'slds-hide') {
            for (var iterator = 0; iterator < hide.length; iterator++) {
                $A.util.removeClass(hide[iterator], 'slds-hide');
            }
            $A.util.removeClass(description, 'littel');
            $A.util.addClass(viewList[0], 'slds-hide');
            } else {
                for (var iterator2 = 0; iterator2 < hide.length; iterator2++) {
                    $A.util.addClass(hide[iterator2], 'slds-hide');
                }
                $A.util.addClass(description, 'littel');
                $A.util.removeClass(viewList[0], 'slds-hide');
            }
    }
})