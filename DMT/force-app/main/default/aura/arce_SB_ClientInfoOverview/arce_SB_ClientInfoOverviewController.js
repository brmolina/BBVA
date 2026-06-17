({
    doInit: function(cmp, event, helper) {
        helper.getInitialData(cmp, event, helper);
    },
    handleMostrarInfo: function(cmp, event, helper) {
        helper.handleMostrarInfo(cmp, event, helper);
    },
    handleMostrarInfoSCRA: function(cmp, event, helper) {
        helper.handleMostrarInfoSCRA(cmp, event, helper);
    },
    handleOnCancel: function(cmp, event, helper) {
        helper.handleOnCancel(cmp, event, helper);
    },
    handleChange: function(cmp, event, helper) {
        helper.handleChange(cmp, event);
    },
    handlefilter: function(cmp, event, helper) {
        helper.getSearchData(cmp, event, helper);
    }
});