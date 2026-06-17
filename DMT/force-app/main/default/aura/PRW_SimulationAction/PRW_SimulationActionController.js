({
  doInit : function(cmp, event, helper) {
    helper.doInit(cmp, helper);
  },
  closePanel: function() {
    $A.get("e.force:closeQuickAction").fire();
  }
})