({
  handleLookupChooseEvent: function(component, event, helper) {
    component.set('v.chosenRecordId', event.getParam('recordId'));
    component.set('v.chosenRecordLabel', event.getParam('recordLabel'));
    helper.toggleLookupList(component, false, 'slds-combobox-lookup', 'slds-is-open');
  },
  searchRecords: function(component, event, helper) {
    var searchText = component.find('searchinput').get('v.value');
    if (searchText) {
      helper.searchSOSLHelper(component, searchText);
    }
  },
  hideList: function(component, event, helper) {
    window.setTimeout($A.getCallback(function() {
      if (component.isValid()) {
        helper.toggleLookupList(component, false, 'slds-combobox-lookup', 'slds-is-open');
      }
    }), 200);
  }
});