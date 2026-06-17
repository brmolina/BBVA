({
	callServerData: function(cmp, evt, helper) {
    	var cssClassName = cmp.get('v.cssClassName');
    
        if (cssClassName === 'View Details') {
          cmp.set('v.View_Details', true);
        } else if (cssClassName === 'View PF') {
          cmp.set('v.View_PF', true);
        }  else if (cssClassName === 'View data in Engloba') {
          cmp.set('v.View_data_in_Engloba', true);
        }  
    }
})