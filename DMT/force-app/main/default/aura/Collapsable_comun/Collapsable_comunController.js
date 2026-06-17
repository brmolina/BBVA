({
	hideMe : function(cmp, evt, helper){
		var isCollapsed = cmp.get('v.isCollapsed');
		isCollapsed = !isCollapsed;
		cmp.set('v.isCollapsed', isCollapsed); 
	},
	setSlsdHide : function(cmp, evt, helper) {
		var accId = evt.getParams().showMessage;
		if(accId==="show"||accId==="hide"){
			if(accId==='show'){
				var cmpTarget = cmp.find('slds-hide');
				$A.util.removeClass(cmpTarget,'slds-hide');
			}
			else{
				var cmpTarget = cmp.find('slds-hide');
				$A.util.addClass(cmpTarget,'slds-hide');
			}
		}else{
			var cmpTarget = cmp.find('slds-hide');
			$A.util.removeClass(cmpTarget,'slds-hide');
		}
	},
	doInit : function(cmp, evt, helper){
		var cmpTarget = cmp.find('slds-hide');
		$A.util.removeClass(cmpTarget,'slds-hide');
	},
})