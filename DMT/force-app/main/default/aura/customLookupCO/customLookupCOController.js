({
    doInit : function(component,event,helper){
      var fromRecord = component.get('v.fromObject');
      var objectType = component.get('v.objectAPIName');

      if(!((fromRecord === 'Account' && objectType === 'opportunity') || fromRecord === 'coff__Commercial_Offer__c' || fromRecord === '')) {
        var forclose = component.find("lookup-pill");
        $A.util.addClass(forclose, 'slds-show');
        $A.util.removeClass(forclose, 'slds-hide');

        var forclose2 = component.find("searchRes");
        $A.util.addClass(forclose2, 'slds-is-close');
        $A.util.removeClass(forclose2, 'slds-is-open');

        var lookUpTarget = component.find("lookupField");
        $A.util.addClass(lookUpTarget, 'slds-hide');
        $A.util.removeClass(lookUpTarget, 'slds-show');
      }
    },
    onfocus : function(component,event,helper){
      var apiName = component.get("v.objectAPIName");
      $A.util.addClass(component.find("mySpinner"), "slds-show");
      var forOpen = component.find("searchRes");
      $A.util.addClass(forOpen, 'slds-is-open');
      $A.util.removeClass(forOpen, 'slds-is-close');
      // Get Default 5 Records order by createdDate DESC
      var getInputkeyWord = '';
      if(apiName === 'account' || apiName === 'opportunity') {
        helper.searchHelper(component,event,getInputkeyWord);
      } else {
        helper.searchHelpOvrr(component,event,getInputkeyWord);
      }
     },
     onblur : function(component,event,helper){
         component.set("v.listOfSearchRecords", null );
         var forclose = component.find("searchRes");
         $A.util.addClass(forclose, 'slds-is-close');
         $A.util.removeClass(forclose, 'slds-is-open');
     },
     keyPressController : function(component, event, helper) {
      var apiName = component.get("v.objectAPIName");
      // get the search Input keyword
      var getInputkeyWord = component.get("v.SearchKeyWord");
      // check if getInputKeyWord size id more then 0 then open the lookup result List and
      // call the helper
      // else close the lookup result List part.
      if( getInputkeyWord.length > 0 ){
        var forOpen = component.find("searchRes");
        $A.util.addClass(forOpen, 'slds-is-open');
        $A.util.removeClass(forOpen, 'slds-is-close');
        if(apiName === 'account' || apiName === 'opportunity') {
          helper.searchHelper(component,event,getInputkeyWord);
        } else {
          helper.searchHelpOvrr(component,event,getInputkeyWord);
        }
      }
      else{
        component.set("v.listOfSearchRecords", null );
        var forcls = component.find("searchRes");
        $A.util.addClass(forcls, 'slds-is-close');
        $A.util.removeClass(forcls, 'slds-is-open');
      }
     },

     clear :function(component,event,heplper){
          var pillTargt = component.find("lookup-pill");
          var lookUpTargt = component.find("lookupField");

          $A.util.addClass(pillTargt, 'slds-hide');
          $A.util.removeClass(pillTargt, 'slds-show');

          $A.util.addClass(lookUpTargt, 'slds-show');
          $A.util.removeClass(lookUpTargt, 'slds-hide');

          component.set("v.SearchKeyWord",null);
          component.set("v.listOfSearchRecords", null );
          component.set("v.selectedRecord", {} );

          //Notificamos que Lookup fue borrado para borrar Opp Tambien.
          var apiName = component.get('v.objectAPIName');
          if(apiName === 'account') {
            var compEvent = component.getEvent('lookUpClearedEvent');
            compEvent.setParams({'lookUpCleared' : apiName });
            compEvent.fire();
          }

     },

   // This function call when the end User Select any record from the result list.
     handleComponentEvent : function(component, event, helper) {
     // get the selected Record from the COMPONETN event
        var selectedAccountGetFromEvent = event.getParam("recordByEvent");
        component.set("v.selectedRecord" , selectedAccountGetFromEvent);

         var forcls = component.find("lookup-pill");
            $A.util.addClass(forcls, 'slds-show');
            $A.util.removeClass(forcls, 'slds-hide');

         var forcls2 = component.find("searchRes");
            $A.util.addClass(forcls2, 'slds-is-close');
            $A.util.removeClass(forcls2, 'slds-is-open');

         var lookUpTrget = component.find("lookupField");
             $A.util.addClass(lookUpTrget, 'slds-hide');
             $A.util.removeClass(lookUpTrget, 'slds-show');

     },
 })