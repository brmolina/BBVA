({
    /*Funcion que coje la Id de consumo_de_linea para invocar a su page layout*/
	getInfo : function(cmp, evt, helper){
		var action = cmp.get('c.getRiskAccount');
		action.setParams({
		'recordId' : cmp.get('v.recordId')
		});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === 'SUCCESS') {
                var ret = response.getReturnValue();
                console.log(ret[0].Id);
				cmp.set('v.RiskId',ret[0].Id);
			}
		});
		$A.enqueueAction(action);
	},
    /*Funcion que saca los datos maximos */
    GetMax : function(cmp,evt,helper){
        var action = cmp.get('c.getMaxConsumo');
		action.setParams({
		'recordId' : cmp.get('v.recordId')
		});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === 'SUCCESS') {
                var ret = response.getReturnValue();
                console.log('maximo '+ret);
				cmp.set('v.MaxConsumo',ret);
			}
		});
		$A.enqueueAction(action);
    },
    /*Funcion que saca los limites*/
    GetLimit : function(cmp,evt,helper){
        var action = cmp.get('c.getRisklimit');
		action.setParams({
		'recordId' : cmp.get('v.recordId')
		});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === 'SUCCESS') {
                var ret = response.getReturnValue();
                console.log(ret);
				cmp.set('v.LimitConsumo',ret);
			}
		});
		$A.enqueueAction(action);
    }
})