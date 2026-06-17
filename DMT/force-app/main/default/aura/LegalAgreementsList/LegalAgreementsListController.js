({
	doInit : function(cmp, event, helper) {
        var detailForm = cmp.get("v.header");
        if(detailForm == true){
            window.scrollTo(0,0)
;        }
        
        helper.getTableData(cmp);
        
        if(detailForm == true) {
        	cmp.set('v.columns', [
                {label: 'Contract Name', fieldName: 'cName', type: 'String'},
                {label: 'Contract Type', fieldName: 'cType', type: 'String'},
                {label: 'Client Name', fieldName: 'accUrl', type: 'url', typeAttributes: { label: { fieldName: 'accName' } }},
                {label: 'Signature Date', fieldName: 'cDate', type: 'String'},
                {label: 'Entities', fieldName: 'cEntity', type: 'String'},
                {label: 'Collateral Contract', fieldName: 'cCollateralType', type: 'String'},
                {label: 'Counterparty', fieldName: 'cCounterparty', type: 'String'}
        	]);
        } else {
           cmp.set('v.columns', [
                {label: 'Contract Name', fieldName: 'cName', type: 'String'},
                {label: 'Contract Type', fieldName: 'cType', type: 'String'},
				{label: 'Client Name', fieldName: 'accUrl', type: 'url', typeAttributes: { label: { fieldName: 'accName' } }},
                {label: 'Signature Date', fieldName: 'cDate', type: 'String'},
                {label: 'Entities', fieldName: 'cEntity', type: 'String'}
        	]);
        }
	},
	
	navigateToMyComponent : function(component, event, helper) {
        var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef : "c:LegalAgreementsList",
            componentAttributes: {
	            recordId : component.get("v.recordId"),
                familyParam : component.get("v.familyParam"),
				breadcrumbsActive : component.get("v.breadcrumbsActive"),
            	detailForm : 'true',
                header: true,
            	tableSize : null
	        }
        });
        evt.fire();
    }
	
})