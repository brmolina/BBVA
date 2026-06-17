({
  toggleLookupList: function(component, ariaexpanded, classadd, classremove) {
    component.find('lookupdiv').set('v.aria-expanded', true);
    $A.util.addClass(component.find('lookupdiv'), classadd);
    $A.util.removeClass(component.find('lookupdiv'), classremove);
  },
  searchSOSLHelper: function(component, searchText) {
    if (searchText && searchText.length > 3) {
      component.find('searchinput').set('v.isLoading', true);
      var action = component.get('c.getaccountsForLookupctrl');
      action.setParams({
        'searchWord': searchText
      });
      action.setCallback(this, function(a) {
        var state = a.getState();
        if (component.isValid() && state === 'SUCCESS') {
          var result = a.getReturnValue();
          component.set('v.matchingRecords', result);
          if (a.getReturnValue() && a.getReturnValue().length > 0) {
            this.toggleLookupList(component, true, 'slds-is-open', 'slds-combobox-lookup');
            component.find('searchinput').set('v.isLoading', false);
          } else {
            this.toggleLookupList(component, false, 'slds-combobox-lookup', 'slds-is-open');
          }
        }
      });
      $A.enqueueAction(action);
    } else {
      this.toggleLookupList(component, false, 'slds-combobox-lookup', 'slds-is-open');
    }
  }
});