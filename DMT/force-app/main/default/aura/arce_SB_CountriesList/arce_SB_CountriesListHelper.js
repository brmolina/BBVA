({
    doInit: function(cmp, evt, helper) {
        var action = cmp.get('c.getInitialData');
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                var result = response.getReturnValue();
                var countriesBkLst = [];
                var countriesInsLst = [];
                console.log(cmp.get('v.isBank'));
                if(cmp.get('v.isBank')){
                    for(var key in result.bankCountriesSBList){
                        countriesBkLst.push({value:result.bankCountriesSBList[key], key:key});
                    }
                }else{
                    for(var key in result.insurerCountriesSBList){
                        countriesInsLst.push({value:result.insurerCountriesSBList[key], key:key});
                    }
                }
                cmp.set('v.bankCountriesSBList', countriesBkLst);
                cmp.set('v.insurerCountriesSBList',countriesInsLst);
            }
        });
        $A.enqueueAction(action);
    },
    handleClose: function(cmp, evt, helper) {
        cmp.destroy();
    }
})