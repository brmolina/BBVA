({
    init: function(cmp, event, helper) {
      helper.setColumns(cmp);
      helper.getParticipants(cmp, helper);
      
      cmp.set('v.data', []);
      }
})