({
    selectedAF: function (component, event, helper) {
        helper.selectedTab(component, 'Asset Finance');
    },
    selectedPF: function (component, event, helper) {
        helper.selectedTab(component, 'Project Finance');
    },
    selectedCF: function (component, event, helper) {
        helper.selectedTab(component, 'Corporate Facilities');
    },
    selectedLF: function (component, event, helper) {
        helper.selectedTab(component, 'Leveraged Finance');
    }
})