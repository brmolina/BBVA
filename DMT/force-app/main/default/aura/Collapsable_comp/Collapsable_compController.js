({
	collapse: function(cmp, evt, helper) {
    cmp.set('v.openCollapsible', !cmp.get('v.openCollapsible'));
  },
    hideMe : function(cmp, evt, helper){
		var isCollapsed = cmp.get('v.isCollapsed');
       
		cmp.set('v.isCollapsed', !isCollapsed)
       
	},
})