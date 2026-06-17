({
    searchHelper : function(component,event,getInputkeyWord) {
        // call the apex class method
        var action = component.get("c.fetchLookUpValues");
        // set param to method
        action.setParams({
            'searchKeyWord': getInputkeyWord,
            'comOfferId' : component.get("v.commercialOffer"),
            'excludeitemsList' : component.get("v.lstSelectedRecords")
        });
        action.setCallback(this, function(response) {
            $A.util.removeClass(component.find("mySpinner"), "slds-show");
            var stat = response.getState();
            if (stat === "SUCCESS") {
                var storeRes = response.getReturnValue();
                if (storeRes.length === 0) {
                    component.set("v.Message", 'No records found...');
                } else {
                    component.set("v.Message", '');
                }
                component.set("v.listOfSearchRecords", storeRes);
            }
        });
        $A.enqueueAction(action);
    },

    cancelHelper: function (component, event, helper) {
        var url = window.location.href;
        var pos = url.indexOf(".com");
        var res = url.slice(0,pos+5);
        var redirectUrl = res + component.get("v.commercialOffer");
        window.location.replace(redirectUrl);
    },
})