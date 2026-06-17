({

    showList: function (component, event, helper) {
        var viewList = component.find("view");
        var hide = document.getElementsByClassName("hide");
        if (viewList.getElement().className !== 'slds-hide') {
            for (var iterator = 0; iterator < hide.length; iterator++) {
                $A.util.removeClass(hide[iterator], 'slds-hide');
            }
            $A.util.addClass(viewList, 'slds-hide');
        } else {
            for (var iterator2 = 0; iterator2 < hide.length; iterator2++) {
                $A.util.addClass(hide[iterator2], 'slds-hide');
            }
            $A.util.removeClass(viewList, 'slds-hide');
        }
        helper.colorVotes(component, event, helper);
    },
    supportives: function (component, event, helper) {
        if (component.get('v.endpoint') !== true) {
            var supp = $A.get("$Label.c.DES_Supportive");
            helper.updatevote(supp, component, event, helper).then(
                $A.getCallback(function (result) {
                    if (result.resolve !== 'Not User') {
                        helper.refresh(component, event, helper);
                    }
                }),
                $A.getCallback(function (error) {
                    console.error('Error calling action getUrlIp with state: ' + error.message);
                })
            ).catch(function (e) {});
        }
    },
    notsupportive: function (component, event, helper) {
        if (component.get('v.endpoint') !== true) {
            var nonsupp = $A.get("$Label.c.DES_Non_Supportive");
            helper.updatevote(nonsupp, component, event, helper).then(
                $A.getCallback(function (result) {
                    if (result.resolve !== 'Not User') {
                        helper.refresh(component, event, helper);
                    }
                }),
                $A.getCallback(function (error) {
                    console.error('Error calling action getUrlIp with state: ' + error.message);
                })
            ).catch(function (e) {});
        }
    },
    handleComponentEvent: function (component, event, helper) {
        component.set('v.iden', true);
        console.log(component.get('v.endpoint'));
        var selectedOpportunityGetFromEvent = event.getParam("IdItem");
        if (selectedOpportunityGetFromEvent !== null) {
            component.set('v.oppId', selectedOpportunityGetFromEvent);
            var viewList = component.find("view");
            var hide = document.getElementsByClassName("hide");
            for (var iterator = 0; iterator < hide.length; iterator++) {
                $A.util.addClass(hide[iterator], 'slds-hide');
            }
            $A.util.removeClass(viewList, 'slds-hide');
            helper.getUserRelated(component, event, helper, component.get('v.oppId'));
            helper.getTemplate(component, event, helper, component.get('v.oppId'));
            helper.getVotes(component, event, helper, component.get('v.oppId'));

        }
    },
    viewmore: function (component, event, helper) {
        var viewList = component.find("view2");
        var description = component.find("description");
        var hide = document.getElementsByClassName("hide2");
        if(viewList.length > 0){
            helper.viewmore2(component, event, helper);
        }
        else{
        if (viewList.getElement().className !== 'slds-hide') {
            for (var iterator3 = 0; iterator3 < hide.length; iterator3++) {
                $A.util.removeClass(hide[iterator3], 'slds-hide');
            }
            $A.util.removeClass(description, 'littel');
            $A.util.addClass(viewList, 'slds-hide');
        } else {
            for (var iterator4 = 0; iterator4 < hide.length; iterator4++) {
                $A.util.addClass(hide[iterator4], 'slds-hide');
            }
            $A.util.addClass(description, 'littel');
            $A.util.removeClass(viewList, 'slds-hide');
        }
        }
        helper.colorVotes(component, event, helper);
    }
})