({
	navigateToProductForm : function(cmp,evt,helper) {
        var event = $A.get('e.force:navigateToComponent');
   event.setParams({
     componentDef: 'c:DES_OpportunityQuickAction',
     componentAttributes: {
       recordId: cmp.get('v.recordId'),
       maxProductNumber: 'none'
     }
   });
   event.fire();
    }
})