({
	doInit : function(cmp, event, helper){
        helper.getTableData(cmp);
        baseFichaGrupo.setColumns(cmp);
	},
	onClickButtonAcc: function(cmp, evt, helper) {
    	helper.navigateGoBackAccount(cmp, evt, helper);
  	},
  	onClickButtonBefore: function(cmp, evt, helper) {
    	helper.navigateGoBackBefore(cmp, evt, helper);
  	}
})