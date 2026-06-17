({
	doInit : function(cmp, event, helper){
        helper.getTableData(cmp);
        var filial = cmp.get('v.filial');
        if (filial) {
            cmp.set('v.columns', [
                {label: 'Opportunity Name', fieldName: 'oppUrl', type: 'url', typeAttributes: { label: { fieldName: 'oppName' }} },
                {label: 'Exp. Revenues', fieldName: 'expectedRevenue', type: 'currency', typeAttributes: { currencyCode: cmp.get('v.userISOCode') } },
                {label: 'Pot. Revenues', fieldName: 'potentialRevenue', type: 'currency', typeAttributes: { currencyCode: cmp.get('v.userISOCode') } },
                {label: 'Exp. Probability', fieldName: 'expProb', type: 'String'},
                {label: 'Status', fieldName: 'status', type: 'String'},
                {label: 'Country', fieldName: 'oppCountry', type: 'String'},
                {label: 'Est. Closing Date', fieldName: 'closingDate', type: 'Date'}
            ]);
        } else {
            cmp.set('v.columns', [
                {label: 'Opportunity Name', fieldName: 'oppUrl', type: 'url', typeAttributes: { label: { fieldName: 'oppName' }} },
                {label: 'Client Name', fieldName: 'accUrl', type: 'url', typeAttributes: { label: { fieldName: 'accName' } }},
                {label: 'Status', fieldName: 'status', type: 'String'},
                {label: 'Country', fieldName: 'oppCountry', type: 'String'},
                {label: 'Est. Closing Date', fieldName: 'closingDate', type: 'Date'},
                {label: 'Exp. Revenues', fieldName: 'expectedRevenue', type: 'currency', typeAttributes: { currencyCode: cmp.get('v.userISOCode') } }
            ]);
        }
	},

	navigateToMyComponent : function(component, event, helper) {
        var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef : "c:OpportunitiesInProgressByFamAll",
            componentAttributes: {
	            idAcc : component.get("v.recordId"),
                famParamAll : component.get("v.familyParam"),
                country : component.get("v.country"),
                breadcrumbsActive : component.get("v.breadcrumbsActive"),
                filial : component.get("v.filial")
	        }
        });
        evt.fire();
    }

})