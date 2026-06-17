({ 
    helperFun : function(component,event,secId) {
         console.log('hemos llegado al helper');
	  var acc = component.find(secId);
        	for(var cmp in acc) {
        	$A.util.toggleClass(acc[cmp], 'slds-hide');  
        	$A.util.toggleClass(acc[cmp], 'slds-show'); 
             
       }
	}
});