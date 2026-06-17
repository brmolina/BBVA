({
    init: function(cmp, event, helper) {
        helper.setData(cmp,helper);
        helper.handleCatalog(cmp,event,helper);
      },
    firstCalculateEvtHandler: function(cmp, event, helper) {
      helper.handleCatalog(cmp,event,helper);
    }
})