({
	doInit : function(cmp, event, helper) {

        helper.gtAPAccountId(cmp);
        cmp.set('v.columns', [
            {label: 'Visit/Call Name', fieldName: 'visUrl', type: 'url', typeAttributes: { label: { fieldName: 'visName' }} },
            {label: 'Type', fieldName: 'visitCallType', type: 'String'},
            {label: 'Client', fieldName: 'accUrl', type: 'url', typeAttributes: { label: { fieldName: 'accName' } }},
            {label: 'Country', fieldName: 'country', type: 'String'},
            {label: 'Product', fieldName: 'prod', type: 'String'},
            {label: 'Owner', fieldName: 'creatBy', type: 'String'},
            {label: 'Start Date', fieldName: 'startDate', type: 'Date'}
        ]);
        
	},
            
	navigateToMyComponent : function(component, event, helper) {
        var evt = $A.get('e.force:navigateToComponent');
        evt.setParams({
            componentDef : 'c:DES_AP_RelatedOpenVisits',
            componentAttributes: {
	            accId : component.get('v.accId'),
                tableSize : null,
                recordId : component.get('v.recordId')
	        }
        });
        evt.fire();
    }
                                
})