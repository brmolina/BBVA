({
  doInit: function(component, event, helper) {
    console.log(component.get('v.data'));
    helper.setColumns(component);
    helper.fetchAccHelper(component, event, helper);
  },
  newOrRenewal: function(component, event, helper) {
    console.log('Click en el nuevo newOrRenewal');
    console.log('Clicko como --> ' + event.getSource().get('v.value'));
  },
  goToAnalisys: function(component, event, helper) {
    window.open('/' + component.get('v.data').id);
  }
});