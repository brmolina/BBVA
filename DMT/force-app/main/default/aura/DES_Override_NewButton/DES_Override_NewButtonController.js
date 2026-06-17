({
	doInit : function(component, event, helper) {
	  console.log('v. 01.09');
	  console.log('>>>>> ' + $A.get("$Browser.formFactor"));
		var staticMsgLabel = '';
	  if(component.get("v.sObjectName") === 'Opportunity'){
		   staticMsgLabel = $A.get("$Label.c.DES_Message_Override_NewOpportunity");
	  }else if(component.get("v.sObjectName") === 'dwp_kitv__Visit__c'){
			staticMsgLabel = $A.get("$Label.c.DES_Message_Override_NewVisit");
	  }
	  component.set("v.myMessage", staticMsgLabel); 

	  var domain = component.get("c.getDomain");
		domain.setCallback(this, function(response){
            console.log('>>>>> ANTES RESPUESTA SUCCESS');
			if(response.getState() === "SUCCESS"){
				component.set("v.domain", response.getReturnValue());
                console.log('>>>>> response.getReturnValue(): ' + response.getReturnValue());
			}
		});
		$A.enqueueAction(domain); 
	},

	
	aceptar : function(component, event, helper) {  
		if($A.get("$Browser.formFactor") === 'DESKTOP'){
			var nameDomain = component.get("v.domain");
			window.location.replace(nameDomain+".lightning.force.com/one/one.app?source=aloha#/sObject/Account/list?filterName=Recent");
			//window.location.replace("https://bbvacibsales--ccloudd4.lightning.force.com/one/one.app?source=aloha#/sObject/Account/list?filterName=Recent");
			//helper.helperFun(component,event,'message');
		}/*else{
			var action = component.get("c.getClientListViews");
			action.setCallback(this, function(response){
				var state = response.getState();
				if (state === "SUCCESS") {
					var listviews = response.getReturnValue();
					var navEvent = $A.get("e.force:navigateToList");
					navEvent.setParams({
						"listViewId": listviews
					});
					navEvent.fire();
				}
			});
			$A.enqueueAction(action);
		}*/
	},
	cancelar : function(component, event, helper) {
		var nameDomain = component.get("v.domain");
		var url = '';
		if($A.get("$Browser.formFactor") === 'DESKTOP'){
			
			if(component.get("v.sObjectName") === 'Opportunity'){
			   url = ".lightning.force.com/one/one.app?source=aloha#/sObject/Opportunity/list?filterName=Recent";
			}else if(component.get("v.sObjectName") === 'dwp_kitv__Visit__c'){
				url = ".lightning.force.com/one/one.app?source=aloha#/sObject/dwp_kitv__Visit__c/list?filterName=Recent"
			}  
			window.location.replace(nameDomain+url);
			
		}else{
			//alert('MOVIL v2');

            var navEvent = $A.get("e.force:navigateToObjectHome");
            navEvent.setParams({
                "scope": component.get("v.sObjectName")
            });
            navEvent.fire();
			
		}
			 
		
		
		//window.location.replace("https://bbvacibsales--ccloudd4.lightning.force.com/one/one.app?source=aloha#/sObject/Opportunity/list?filterName=Recent");
		//helper.helperFun(component,event,'message');
	}

})