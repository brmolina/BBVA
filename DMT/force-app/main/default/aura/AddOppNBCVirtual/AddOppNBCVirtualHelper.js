({
    searchHelper: function (component, event, getInputkeyWord) {
        // call the apex class method
        var TemplateId = component.get('v.recordId');
        var action = component.get("c.fetchLookUpValues");

        // set param to method
        action.setParams({
            'recordId': TemplateId,
            'searchKeyWord': getInputkeyWord,
        });
        // set a callBack
        action.setCallback(this, function (response) {
            $A.util.removeClass(component.find("mySpinner"), "slds-show");
            var stateStore = response.getState();
            if (stateStore === "SUCCESS") {
                var storeRes = response.getReturnValue();
                // if storeRes size is equal 0 ,display No Result Found... message on screen.                }
                if (storeRes.length === 0) {
                    component.set("v.Message", 'No Result Found...');
                } else {
                    component.set("v.Message", '');
                }
                // set searchResult list with return value from server.
                component.set("v.listOfSearchRecords", storeRes);
            }

        });
        // enqueue the Action
        $A.enqueueAction(action);

    },

    saveHelper : function(component, event, helper) {
        var opport = component.get("v.selectedRecord");
        var TemplateId = component.get('v.recordId');
           //set the default accountId is null
       // check if selectedLookupRecord is not equal to undefined then set the accountId from
       // selected Lookup Object to Contact Object before passing this to Server side method

       //call apex class method
       console.debug('Oportunidad---------------------->'+opport);
       console.debug('RecordId----------------------->'+TemplateId);
       var action = component.get('c.saveOp');
        action.setParams({
            'opp': opport,
            'recordId' : TemplateId,
        })
        return new Promise($A.getCallback(function (resolve, reject) {
      action.setCallback(this, function(response) {
        //store stateStore of response
        var stateStore = response.getState();
        if (stateStore === "SUCCESS") {
            if (response.getReturnValue() === null) {
               resolve('Not User');
            }
        }else{
            console.log('FALLO : ', JSON.stringify(response.getReturnValue()));
        }
      });
            
      $A.enqueueAction(action);
        }));
    },
    clearHelper :function(component, event, helper){
        var pillTarget = component.find("lookup-pill");
         var lookUpTarget = component.find("lookupField");

         $A.util.addClass(pillTarget, 'slds-hide');
         $A.util.removeClass(pillTarget, 'slds-show');

         $A.util.addClass(lookUpTarget, 'slds-show');
         $A.util.removeClass(lookUpTarget, 'slds-hide');

         component.set("v.SearchKeyWord","");
         component.set("v.listOfSearchRecords", null );
         component.set("v.selectedRecord", {} );
         component.set("v.selectedRecordId" , null);
    },
    keyPressControllerHelper : function(component, event, helper) {
        // get the search Input keyword
          var getInputkeyWord = component.get("v.SearchKeyWord");
          console.debug('SearchKeyWord---------------------->'+getInputkeyWord);

        // check if getInputKeyWord size id more then 0 then open the lookup result List and
        // call the helper
        // else close the lookup result List part.
         if( getInputkeyWord.length > 0 ){
                var forOpen = component.find("searchRes");
                console.debug('SearchKeyWord---------------------->'+forOpen);

                $A.util.addClass(forOpen, 'slds-is-open');
                $A.util.removeClass(forOpen, 'slds-is-close');
                helper.searchHelper(component,event,getInputkeyWord);
         }
         else{
                component.set("v.listOfSearchRecords", null );
                var forclose = component.find("searchRes");
                $A.util.addClass(forclose, 'slds-is-close');
                $A.util.removeClass(forclose, 'slds-is-open');
           }
    },
    onfocusHelper : function(component,event,helper){
        $A.util.addClass(component.find("mySpinner"), "slds-show");
        var forOpen = component.find("searchRes");
        $A.util.addClass(forOpen, 'slds-is-open');
        $A.util.removeClass(forOpen, 'slds-is-close');
        var getInputkeyWord = '';
        helper.searchHelper(component,event,getInputkeyWord);
    },
    onblurHelper : function(component,event,helper){
        component.set("v.listOfSearchRecords", null );
        var forclose = component.find("searchRes");
        $A.util.addClass(forclose, 'slds-is-close');
        $A.util.removeClass(forclose, 'slds-is-open');
    },
    handleComponentEventHelper : function(component, event, helper) {
        // get the selected Account record from the COMPONETN event
           var selectedAccountGetFromEvent = event.getParam("recordByEvent");
           component.set("v.selectedRecord" , selectedAccountGetFromEvent);
           component.set("v.selectedRecordId" , selectedAccountGetFromEvent.Id);
           var fieldName= component.get("v.fieldName");
           component.set("v.selectedValue",selectedAccountGetFromEvent[fieldName]);

            var forclose = component.find("lookup-pill");
               $A.util.addClass(forclose, 'slds-show');
               $A.util.removeClass(forclose, 'slds-hide');

            var forclose1 = component.find("searchRes");
               $A.util.addClass(forclose1, 'slds-is-close');
               $A.util.removeClass(forclose1, 'slds-is-open');

            var lookUpTarget = component.find("lookupField");
                $A.util.addClass(lookUpTarget, 'slds-hide');
                $A.util.removeClass(lookUpTarget, 'slds-show');

        },

        searchOpp: function (component, event, helper) {
            // call the apex class method
            var TemplateId = component.get('v.recordId');
            var action = component.get("c.listarOpp");
            // set param to method
            action.setParams({
                'recordId': TemplateId,
            });
            // set a callBack
            action.setCallback(this, function (response) {
                var stateStore = response.getState();
                if (stateStore === "SUCCESS") {
                    var storeRes = response.getReturnValue();
                    component.set("v.hayOpp", true);
                    component.set("v.data", JSON.parse(storeRes));
                    console.log("------------------------------------"+JSON.stringify(component.get("v.listOppAux")));
                }

            });
            // enqueue the Action
            $A.enqueueAction(action);

        },
})