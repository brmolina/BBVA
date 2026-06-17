({
    doInit: function(component, event, helper) {
        helper.loadData(component);
    },

    nextPage: function(component, event, helper) {
        let current = component.get("v.currentPage");
        component.set("v.currentPage", current + 1);
        helper.updatePagedData(component);
    },

    prevPage: function(component, event, helper) {
        let current = component.get("v.currentPage");
        component.set("v.currentPage", current - 1);
        helper.updatePagedData(component);
    }
})