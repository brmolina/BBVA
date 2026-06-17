({
  init : function(component, event, helper) {
    let urlString = window.location.href;
    component.set('v.profSheetUrl', urlString.substring(0, urlString.indexOf('/', 14)));
	},
  handleSectionToggle: function (cmp, event) {
    var section = cmp.find('clientsSection');
    $A.util.toggleClass(section, 'divNames');
    $A.util.toggleClass(section, 'divNames1');
    $A.util.toggleClass(section, 'slds-scrollable');
  },
  chargeData: function (cmp, event, helper) {
    helper.tableClients(cmp, event, helper);
  }
})