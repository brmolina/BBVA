({
    init: function(component, event, helper) {
        helper.setupDataTable(component);
        helper.getData(component);
    },
    handleRowAction : function(component, event, helper) {
        var row = event.getParam('row');
        helper.deleteError(component, row);
    },
    onNext : function(component, event, helper) {
        var pageNumber = component.get("v.currentPageNumber");
        component.set("v.currentPageNumber", pageNumber + 1);
        helper.setDataByPage(component);
    },
    onPrev : function(component, event, helper) {
        var pageNumber = component.get("v.currentPageNumber");
        component.set("v.currentPageNumber", pageNumber - 1);
        helper.setDataByPage(component);
    },
    onPageSizeChange: function(component, event, helper) {
        helper.setPaging(component, component.get('v.filteredData'));
    }

})