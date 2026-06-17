({
	doInit : function(cmp, event, helper){
        helper.getTableData(cmp);
        var filial = cmp.get('v.filial');
        if(filial) {
            baseFichaGrupo.setColumnsFilial(cmp);
        } else {
            baseFichaGrupo.setColumns(cmp);
        }
	},
    onClickButtonAcc: function(cmp, evt, helper) {
        helper.navigateGoBackAccount(cmp, evt, helper);
    },
    onClickButtonFamily: function(cmp, evt, helper) {
        helper.navigateGoBackFamily(cmp, evt, helper);
    }
})