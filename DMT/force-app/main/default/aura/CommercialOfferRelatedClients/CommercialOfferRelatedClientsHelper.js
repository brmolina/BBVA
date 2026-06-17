({
	getRelatedClients : function(component ) {
		var act = component.get( "c.getClients" );
        act.setParams({
      		'cOfferId': component.get('v.recordId')
    	});

        act.setCallback(this, function (response) {
            if (response.getState() === 'SUCCESS') {
                var elemnts = JSON.parse(response.getReturnValue());
                var listitems = [];
                var nloops = 0;
                if(elemnts.length>3) {
                    nloops = 3;
                    component.set('v.sizeMembers', '3+');
                } else {
                    nloops = elemnts.length;
                    component.set('v.sizeMembers', elemnts.length);
                }

                for (var i = 0; i<nloops; i++) {
                    listitems.push(elemnts[i]);
                }
                component.set('v.membersRelated', listitems);
                component.set('v.members', elemnts);

                component.set('v.columns', [
                            {label: 'Client Name', fieldName: 'clientUrl', type: 'url', typeAttributes: { label: { fieldName: 'clientName' }} },
                            {label: 'Client Type', fieldName: 'cType', type: 'String'},
                            {label: 'Global Banker', fieldName: 'globalBanker', type: 'String'},
                    		{label: 'Client CClient', fieldName: 'codeClient', type: 'String'},
                            {label: 'Country', fieldName: 'labelCountry', type: 'String'},
                            {label: 'Country of Management', fieldName: 'labelCountryManag', type: 'String'},
                            {label: 'RAR YTD', fieldName: 'rarYtd', type: 'String'},
                    		{label: 'RAR last 12 months', fieldName: 'rar12Ytd', type: 'String'},
                    		{label: 'GROSS MARGIN YTD', fieldName: 'marginYtd', type: 'String'},
                    		{label: 'RORC', fieldName: 'rorcPar', type: 'String'}
                        ]);
            } else if (response.getState() === "ERROR") {
                var err = response.getError();
                console.error(err);
            }
        });
        $A.enqueueAction(act);
	}
})