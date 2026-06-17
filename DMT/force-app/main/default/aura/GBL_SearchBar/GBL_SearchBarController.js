({ // eslint-disable-line
  dispatchSearchKeyChange: function(component, event, helper) {
    var myEvent = component.getEvent('searchKeyChange');
    var keyValue = event.getSource().get('v.value');
    myEvent.setParams({'searchKey': keyValue});
    myEvent.fire();
  }
});