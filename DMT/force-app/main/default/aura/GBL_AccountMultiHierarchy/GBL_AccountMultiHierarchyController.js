({
    doInit: function(cmp, event, helper) {
        helper.initComponent(cmp, event, helper);
    },

    handleScope: function(cmp, event, helper) {
        try {
            console.log("handleScope - START");

            var selectedVision = event.getSource().get("v.value");
            console.log("Selected Vision: " + selectedVision);

            cmp.set("v.selectedScope", selectedVision);
            cmp.set("v.currentNodeId", cmp.get("v.recordId"));
            cmp.set("v.startFromRow", "START");
            helper.processHierarchyTree(cmp, event);

            setTimeout($A.getCallback(function() {
                const visibleNodes = helper.getVisibleNodeIds(cmp);
                console.log("Visible nodes after Vision change:", visibleNodes);
                helper.triggerEventNode(cmp, visibleNodes);
            }), 1000);

            console.log("handleScope - END");
        } catch (error) {
            console.error("Error in handleScope:", error, error.stack);
        }
    },


    handleRelTypes: function(cmp, event) {
        // Placeholder si se necesita en el futuro
    },

    handleSelectChangeEvent: function(cmp, event, helper) {
        console.log("handleSelectChangeEvent → START");

        const items = event.getParam('values');
        cmp.set('v.mySelectedRels', items);
        cmp.set('v.OptionsLoaded', true);

        helper.processHierarchyTree(cmp, event);

        setTimeout($A.getCallback(function() {
            const visibleNodes = helper.getVisibleNodeIds(cmp);
            console.log("Visible nodes to send:", visibleNodes);
            helper.triggerEventNode(cmp, visibleNodes);
        }), 1000);

        console.log("handleSelectChangeEvent → END");
    },

    handleOptionsLoadedEvent: function(cmp, event, helper) {
        var items = event.getParam('values');
        var result = event.getParam('result');
        var recordId = cmp.get('v.recordId');
        cmp.set('v.mySelectedRels', items);
        cmp.set('v.OptionsLoaded', result);
        cmp.set('v.currentNodeId', recordId);
        helper.processHierarchyTree(cmp, event);
    },

    handleNodeClick: function(cmp, event, helper) {
        helper.triggerEventNode(cmp, event);
    },

    handleGetNode: function(cmp, event, helper) {
        helper.triggerEventNode(cmp, event);
    },

    handleRefresh: function(cmp, event, helper) {
        helper.processHierarchyTree(cmp, event);
        helper.triggerEventNode(cmp, event);
    },

    handleHierarchyModeChange: function(cmp, event, helper) {
        var hierarchyMode = cmp.get('v.hmValue');
        cmp.set('v.hmValue', hierarchyMode);

        var childAccounts = cmp.find('childAccountsListView');
        var optRelatedList = cmp.find('optRelatedList');
        var conRelatedList = cmp.find('conRelatedList');
        var casRelatedList = cmp.find('casRelatedList');

        if (hierarchyMode === 'ModeAsc') {
            if (childAccounts) $A.util.addClass(childAccounts, 'slds-hide');
            if (optRelatedList) $A.util.addClass(optRelatedList, 'slds-hide');
            if (conRelatedList) $A.util.addClass(conRelatedList, 'slds-hide');
            if (casRelatedList) $A.util.addClass(casRelatedList, 'slds-hide');
        } else if (hierarchyMode === 'ModeDesc') {
            if (childAccounts) $A.util.removeClass(childAccounts, 'slds-hide');
            if (optRelatedList) $A.util.removeClass(optRelatedList, 'slds-hide');
            if (conRelatedList) $A.util.removeClass(conRelatedList, 'slds-hide');
            if (casRelatedList) $A.util.removeClass(casRelatedList, 'slds-hide');
        }

        helper.processHierarchyTree(cmp, event);
    },

    afterLoaded: function(cmp, event, helper) {
        // Resources loaded
    }
});