({
    searchRecordsHelper : function(component, event, helper, value) {
		$A.util.removeClass(component.find("Spinner"), "slds-hide");
        var searchString = component.get('v.searchString');
        component.set('v.message', '');
        component.set('v.recordsList', []);
		// Calling Apex Method
    	var action = component.get('c.fetchRecords');
        action.setParams({
            'objectName' : component.get('v.objectName'),
            'filterField' : component.get('v.fieldName'),
            'searchString' : searchString,
            'value' : value,
            'custom' : component.get('v.custom')
        });
        action.setCallback(this,function(response){
        	var result = response.getReturnValue();
        	if(response.getState() === 'SUCCESS') {
    			if(result.length > 0) {
    				// To check if value attribute is prepopulated or not
					if( $A.util.isEmpty(value) ) {
                        component.set('v.recordsList',result);
					} else {
                        component.set('v.selectedRecord', result[0]);
					}
    			} else {
    				component.set('v.message', "No Records Found for '" + searchString + "'");
    			}
        	} else {
                // If server throws any error
                var errors = response.getError();
                if (errors && errors[0] && errors[0].message) {
                    component.set('v.message', errors[0].message);
                }
            }
            // To open the drop down list of records
            if( $A.util.isEmpty(value) )
                $A.util.addClass(component.find('resultsDiv'),'slds-is-open');
        	$A.util.addClass(component.find("Spinner"), "slds-hide");
        });
        $A.enqueueAction(action);
    },

    removeItemHelper : function(component, event, helper) {
        component.set('v.selectedRecord','');
        component.set('v.value','');
        component.set('v.searchString','');
        setTimeout( function() {
            component.find( 'inputLookup' ).focus();
        }, 250);
    },

    populateRolehelper : function(component, event, helper) {
        var custom = component.get('v.custom');
        var selecetdRecord = component.get('v.value');
        if(custom === 'primary') {
            var appEvent = $A.get("e.c:AssetSalesEvent");
            appEvent.setParams({
                "message" : 'role',
                "record"  : selecetdRecord,
                "recordid" : component.get("v.recordId")
             });
            appEvent.fire();
        } else if(custom === 'secondary') {
            var appEvnt = $A.get("e.c:AssetSalesEvent");
            appEvnt.setParams({
                "message" : 'role',
                "record"  : selecetdRecord,
                "recordid" : component.get("v.recordId")
             });
            appEvnt.fire();
        }
    },

    saveHelper : function(component, event, helper) {
        var custom = component.get('v.custom');
        var selecetdRecord = component.get('v.value');
        var appEvent = $A.get("e.c:AssetSalesEvent");
        if(custom === 'primary') {
            appEvent.setParams({
                "primary" : true,
                "record"  : selecetdRecord,
                "saveModeChild"  : true,
                "recordid" : component.get("v.recordId")

             });
            appEvent.fire();
        } else if (custom === 'secondary') {
            appEvent.setParams({
                "secondary" : true,
                "record"  : selecetdRecord,
                "saveModeChild"  : true,
                "recordid" : component.get("v.recordId")
             });
            appEvent.fire();
        }
    },

    handleEventHelper : function( component, event, helper ) {
        var custom = component.get('v.custom');
        var evento = event.getParam('message');
        var lookup = component.get('v.selectedRecord');
        if((custom === 'secondary' || custom === 'primary') && lookup != null && evento === 'remove') {
            helper.removeItemHelper( component, event, helper );
        }
        if(custom === 'secondary' && evento === 'role') {
            var record = event.getParam('record');
            console.log('record------------------>'+record);
            var action = component.get('c.metodoRole');
            action.setParams({
                'recordId' : record,
            });
            action.setCallback(this,function(response){
                var result = response.getReturnValue();
                console.log(response.getState());
                if(response.getState() === 'SUCCESS') {
                    component.set('v.selectedRecord',result[0]);
                }
            });
            $A.enqueueAction(action);
        }
        //send the id
        if(custom === 'secondary' && evento === 'get-secondary') {
            var rcd = lookup!=null?lookup.value:null;
            var appEvent = $A.get("e.c:AssetSalesEvent");
            appEvent.setParams({
                "secondary" : true,
                "message"  : "set-secondary",
                "record"  : rcd
              });
            appEvent.fire();
        }
    },

})