({
  doInit : function(cmp, event, helper){
        helper.getTableData(cmp);
        cmp.set('v.columns', [
            {label: 'Visit Name', fieldName: 'visUrl', type: 'url', typeAttributes: { label: { fieldName: 'visName' }} },
            {label: 'Client', fieldName: 'accUrl', type: 'url', typeAttributes: { label: { fieldName: 'accName' } }},
            {label: 'Country', fieldName: 'country', type: 'String'},
            {label: 'Product', fieldName: 'prod', type: 'String'},
            {label: 'Owner', fieldName: 'creatBy', type: 'String'},
            {label: 'Start Date', fieldName: 'startDate', type: 'Date'}
        ]);

  },
    onClickButtonAcc: function(cmp, evt, helper) {
        helper.navigateGoBackAccount(cmp, evt, helper);
    },
    onClickButtonFamily: function(cmp, evt, helper) {
        helper.navigateGoBackFamily(cmp, evt, helper);
    }
})