({
    // To prepopulate the seleted value pill if value attribute is filled
	doInit : function( component, event, helper ) {
    	$A.util.toggleClass(component.find('resultsDiv'),'slds-is-open');
		if( !$A.util.isEmpty(component.get('v.value')) ) {
			helper.searchRecordsHelper( component, event, helper, component.get('v.value') );
		}
	},

    // When a keyword is entered in search box
	searchRecords : function( component, event, helper ) {
        if( !$A.util.isEmpty(component.get('v.searchString')) ) {
		    helper.searchRecordsHelper( component, event, helper, '' );
        } else {
            $A.util.removeClass(component.find('resultsDiv'),'slds-is-open');
        }
	},

    // When an item is selected
	selectItem : function( component, event, helper ) {
        if(!$A.util.isEmpty(event.currentTarget.id)) {
    		var recordsList = component.get('v.recordsList');
    		var index = recordsList.findIndex(x => x.value === event.currentTarget.id)
            if(index !== -1) {
                var selRecord = recordsList[index];
            }
            component.set('v.selectedRecord',selRecord);
            if(selRecord != null) {
            component.set('v.value',selRecord.value);
            }
            $A.util.removeClass(component.find('resultsDiv'),'slds-is-open');
        }
	},

    showRec : function( component, event, helper ) {
        if(!$A.util.isEmpty(component.get('v.recordsList')) && !$A.util.isEmpty(component.get('v.searchString'))) {
            $A.util.addClass(component.find('resultsDiv'),'slds-is-open');
        }
	},

	remItem : function( component, event, helper ){
        helper.removeItemHelper( component, event, helper );
        var appEvent = $A.get("e.c:AssetSalesEvent");
        appEvent.setParams({ "message" : 'remove' });
        appEvent.fire();

    },

    // To close the dropdown if clicked outside the dropdown.
    blurEvent : function( component, event, helper ){
    	$A.util.removeClass(component.find('resultsDiv'),'slds-is-open');
    },

    handleEvent : function( component, event, helper ) {
        helper.handleEventHelper(component, event, helper);
    },

    saveLkp : function( component, event, helper ) {
        var evento = event.getParam('message');
        if(evento === 'save-asset'){
            var getID = event.getParam('record');
            if (getID === component.get("v.recordId")) {
                helper.saveHelper(component, event, helper);
            }
        }
    },

    populateRole : function(component, event, helper) {
        helper.populateRolehelper(component, event, helper);
    }

 })