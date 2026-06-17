({
  doInit: function(cmp, event, helper) {
    helper.getDisclosure(cmp);
    helper.getRecordTypeName(cmp,event);
    helper.getAccId(cmp, event);
    helper.fetchPickListVal(cmp, 'dwp_kitv__visit_duration_number__c', 'duration', 'false');
    helper.fetchPickListVal(cmp, 'dwp_kitv__visit_channel__c', 'type', 'false');
    helper.fetchPickListVal(cmp, 'dwp_kitv__visit_purpose_type__c', 'purposetype', 'false');
    helper.fetchPickListVal(cmp, 'disclosure_info_type__c', 'disclosure', 'false');
  },
  saveForm: function(cmp, evt, helper) {
    helper.newVisit(cmp, evt);
  },
  cancelForm: function(cmp, evt) {
    // Close the action panel
    var dismissActionPanel = $A.get('e.force:closeQuickAction');
    dismissActionPanel.fire();
  }
});