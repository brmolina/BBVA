({
  onfocus: function (component, event, helper) {
    $A.util.addClass(component.find('mySpinner'), 'slds-show');
    var forOpen = component.find('searchRes');
    $A.util.addClass(forOpen, 'slds-is-open');
    $A.util.removeClass(forOpen, 'slds-is-close');

    // Get Default 5 Records order by createdDate DESC
    var getInputkeyWord = '';
    helper.searchHelper(component, event, getInputkeyWord);
  },

  keyPressController: function (component, event, helper) {
    // get the search Input keyword
    var getInputkeyWord = component.get('v.SearchKeyWord');

    // check if getInputKeyWord size id more then 0 then open the lookup result List and
    // call the helper
    // else close the lookup result List part.
    if (getInputkeyWord.length > 0) {
      var toOpen = component.find('searchRes');
      $A.util.addClass(toOpen, 'slds-is-open');
      $A.util.removeClass(toOpen, 'slds-is-close');
      helper.searchHelper(component, event, getInputkeyWord);
    } else {
      component.set('v.listOfSearchRecords', null);
      var toclose = component.find('searchRes');
      $A.util.addClass(toclose, 'slds-is-close');
      $A.util.removeClass(toclose, 'slds-is-open');
    }
  },
  onblur: function (component, event, helper) {
    component.set('v.listOfSearchRecords', null);
    var toclose = component.find('searchRes');
    $A.util.addClass(toclose, 'slds-is-close');
    $A.util.removeClass(toclose, 'slds-is-open');
  },

  // function for clear the Record Selaction
  clear: function (component, event, helper) {
    component.set('v.selectedRecord', null);
    var pillCmp = component.find('lookup-pill');
    var lookUpCmp = component.find('lookupField');
    $A.util.addClass(pillCmp, 'slds-hide');
    $A.util.removeClass(pillCmp, 'slds-show');
    $A.util.addClass(lookUpCmp, 'slds-show');
    $A.util.removeClass(lookUpCmp, 'slds-hide');
    component.set('v.SearchKeyWord', null);
    component.set('v.listOfSearchRecords', null);
    component.set('v.selectedRecord', {});

  },

  // This function call when the end User Select any record from the result list.
  handleComponentEvent: function (component, event, helper) {
    // get the selected Account record from the COMPONENT event
    var parameterObject = component.get('v.objectAPIName');
    if (parameterObject === 'User') {
      var selectedAccountGetFromEvent1 = event.getParam('recordByEvent');
      if (selectedAccountGetFromEvent1 !== null) {
        component.set('v.selectedRecord', selectedAccountGetFromEvent1);
      }
    } else if (parameterObject === 'Account') {
      var selectedAccountGetFromEvent2 = event.getParam('recordAccByEvent');
      if (selectedAccountGetFromEvent2 !== null) {
        component.set('v.selectedRecord', selectedAccountGetFromEvent2);
      }
    } else if (parameterObject === 'Product2') {
      var selectedProduct2GetFromEvent = event.getParam('recordByEvent');
      if (selectedProduct2GetFromEvent !== null) {
        component.set('v.selectedRecord', selectedProduct2GetFromEvent);
      }
    } else if (parameterObject === 'Opportunity') {
      var selectedOpportunityGetFromEvent = event.getParam('recordByEvent');
      if (selectedOpportunityGetFromEvent !== null) {
        component.set('v.selectedRecord', selectedOpportunityGetFromEvent);
      }
    }

    var forclose = component.find('lookup-pill');
    $A.util.addClass(forclose, 'slds-show');
    $A.util.removeClass(forclose, 'slds-hide');
    var forclose2 = component.find('searchRes');
    $A.util.addClass(forclose2, 'slds-is-close');
    $A.util.removeClass(forclose2, 'slds-is-open');
    var lookUpTarget = component.find('lookupField');
    $A.util.addClass(lookUpTarget, 'slds-hide');
    $A.util.removeClass(lookUpTarget, 'slds-show');
  },
  doInit: function (component, event, helper) {
    var objectOpen = component.get("v.objectOpenForm");
    var parameterObject = component.get('v.objectAPIName');
    if (parameterObject === 'User') {
      var action = component.get("c.getLookupValue");
      action.setParams({
        "objectName": component.get("v.objectOpenForm"),
        "objectRecordId": component.get("v.recordId"),
      });
      action.setCallback(this, function (response) {
        if (response.getState() === "SUCCESS") {
          component.set("v.selectedRecord", response.getReturnValue());

          helper.checkObjectOpen(component, objectOpen, response);

          var selectedAccountGetFromEvent = response.getReturnValue();
          if (selectedAccountGetFromEvent !== null) {
            component.set('v.selectedRecord', selectedAccountGetFromEvent);
          }
          var compEvent = component.getEvent('oSelectedRecordEvent');
          compEvent.setParams({ 'recordByEvent': selectedAccountGetFromEvent });
          compEvent.fire();
        }
      });
      $A.enqueueAction(action);
    }

    if (parameterObject === 'Account') {
      helper.accountAction(component, event, objectOpen);
    }

  }

});