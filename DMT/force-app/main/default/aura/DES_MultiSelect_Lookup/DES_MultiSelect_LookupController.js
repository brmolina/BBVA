({
    doinit: function (component, event, helper) {
        component.set('v.columns', [{label: 'Name', fieldName: 'oppName', type: 'text'},
        {label: 'Owner', fieldName: 'owner', type: 'text'},
        {label: 'Product', fieldName: 'product', type: 'text'},]);
    },
    onblur : function(component,event,helper){
        // on mouse leave clear the listOfSeachRecords & hide the search result component
        component.set("v.listOfSearchRecords", null );
        component.set("v.SearchKeyWord", '');
        var forclose = component.find("searchRes");
        $A.util.addClass(forclose, 'slds-is-close');
        $A.util.removeClass(forclose, 'slds-is-open');
    },
    onfocus : function(component,event,helper){
        // show the spinner,show child search result component and call helper function
        $A.util.addClass(component.find("mySpinner"), "slds-show");
        component.set("v.listOfSearchRecords", null );
        var forOpen = component.find("searchRes");
        $A.util.addClass(forOpen, 'slds-is-open');
        $A.util.removeClass(forOpen, 'slds-is-close');
        // Get Default 5 Records order by createdDate DESC
        var getInputkeyWord = '';
        helper.searchHelper(component,event,getInputkeyWord);
    },

    keyPressController : function(component, event, helper) {
        $A.util.addClass(component.find("mySpinner"), "slds-show");
        var inputkeyWord = component.get("v.SearchKeyWord");
        if(inputkeyWord.length > 0){
            var forOpen1 = component.find("searchRes");
            $A.util.addClass(forOpen1, 'slds-is-open');
            $A.util.removeClass(forOpen1, 'slds-is-close');
            helper.searchHelper(component,event,inputkeyWord);
        }
        else{
            component.set("v.listOfSearchRecords", null );
            var forclose1 = component.find("searchRes");
            $A.util.addClass(forclose1, 'slds-is-close');
            $A.util.removeClass(forclose1, 'slds-is-open');
        }
    },

    clear :function(component,event,heplper){
        var selectedPillId = event.getSource().get("v.name");
        var AllPillsList = component.get("v.lstSelectedRecords");

        for(var i = 0; i < AllPillsList.length; i++){
            if(AllPillsList[i].Id === selectedPillId){
                AllPillsList.splice(i, 1);
                component.set("v.lstSelectedRecords", AllPillsList);
            }
        }
        component.set("v.SearchKeyWord",null);
        component.set("v.listOfSearchRecords", null );
    },

    // This function call when the end User Select any record from the result list.
    handleComponentEvent : function(component, event, helper) {
        component.set("v.SearchKeyWord",null);
        // get the selected object record from the COMPONENT event
        var listSelectedItems =  component.get("v.lstSelectedRecords");
        var selectedAccountGetFromEvent = event.getParam("recordByEvent");
        listSelectedItems.push(selectedAccountGetFromEvent);

        var action = component.get("c.listarOpp");

        var forclose = component.find("searchRes");
        $A.util.addClass(forclose, 'slds-is-close');
        $A.util.removeClass(forclose, 'slds-is-open');
        action.setParams({
            'lstOpp' : listSelectedItems
        });
        action.setCallback(this, function (response) {
            var stateStore = response.getState();
            if (stateStore === "SUCCESS") {
                var storeRes = response.getReturnValue();
                if(storeRes === "error") {
                    listSelectedItems.pop();
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        type: "error",
                        duration: "15000",
                        "message": "Please notice you can not relate this opportunity to the Commercial Offer as it is already related with other Commercial Offer, please go to the opportunity details to check complete information. Thanks" //NOSONAR
                    });
                    toastEvent.fire()
                } else {
                    component.set("v.lstSelectedRecords" , listSelectedItems);
                    component.set("v.data", JSON.parse(storeRes));
                    var rows = ['a'];
                    component.set('v.selectedRows', rows);
                }
            }

        });
        $A.enqueueAction(action);
    },

    cancel: function (component, event, helper) {
        helper.cancelHelper(component, event, helper);
    },

    relateOpportunity: function (component, event, helper) {
        // call the apex class method
        var action = component.get("c.oppReadyToRelate");
        // set param to method
        action.setParams({
            'commercialOffer': component.get("v.commercialOffer"),
            'lstOpp' : component.get("v.lstSelectedRecords"),
            });
        // set a callBack
        action.setCallback(this, function(response) {
        $A.util.removeClass(component.find("mySpinner"), "slds-show");
            var state = response.getState();
            if (state === "SUCCESS") {
                helper.cancelHelper(component, event, helper);
            }
       });
     // enqueue the Action
       $A.enqueueAction(action);
    },
})