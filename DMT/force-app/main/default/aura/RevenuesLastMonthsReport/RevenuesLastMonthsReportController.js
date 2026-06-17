({
    doInit: function (cmp, event, helper) {
        helper.retrieveData(cmp, event, helper);
    },
    onClickButtonAcc: function (cmp, evt, helper) {
        helper.navigateGoBackAccount(cmp, evt, helper);
    },
    onClickButtonFamily: function (cmp, evt, helper) {
        helper.navigateGoBackFamily(cmp, evt, helper);
    }
})