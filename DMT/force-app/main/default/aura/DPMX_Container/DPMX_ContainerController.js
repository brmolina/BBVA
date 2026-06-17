({
    doInit: function(cmp, event, helper) {
        helper.doInit(cmp, event, helper);
    },
    openLink: function(cmp, event, helper) {
        helper.openLink(cmp, event, helper);
    },
    handleOnCheckTerminal: function(cmp, event, helper) {
        helper.handleOnCheckTerminal(cmp, event, helper);
    },
    handleOnCheckPinpad: function(cmp, event, helper) {
        helper.handleOnCheckPinpad(cmp, event, helper);
    },
    handleOnCancel: function(cmp, event, helper) {
        helper.destroyCmp(cmp, event, helper);
    },
    /*handleOnSave: function(cmp, event, helper) {
        helper.handleOnSave(cmp, event, helper);
    },*/
    /*handleOnChangeFields: function(cmp, event, helper) {
        helper.handleOnChangeFields(cmp, event, helper);
    },*/
    handleAddClientInformation: function(cmp, event, helper) {
        helper.handleAddClientInformation(cmp, event, helper);
    },
    handleModifyClientInformation: function(cmp, event, helper) {
        helper.handleModifyClientInformation(cmp, event, helper);
    },
    handleAddDevices: function(cmp, event, helper) {
        helper.handleAddDevices(cmp, event, helper);
    },
    handleModifyDevices: function(cmp, event, helper) {
        helper.handleModifyDevices(cmp, event, helper);
    },
    handleAddCompany: function(cmp, event, helper) {
        helper.handleAddCompany(cmp, event, helper);
    },
    handleAuthoritation: function(cmp, event, helper) {
        helper.handleAuthoritation(cmp, event, helper);
    },
    handleAuthoritationSimulation: function(cmp, event, helper) {
        helper.handleAuthoritationSimulation(cmp, event, helper);
    },
    handlesaveDiscountRate: function(cmp, event, helper) {
        helper.handlesaveDiscountRate(cmp, event, helper);
    },
    handleOnSimulate: function(cmp, event, helper) {
        helper.handleOnSimulate(cmp, event, helper);
    },
    handlesaveSimulateRate: function(cmp, event, helper) {
        helper.handlesaveSimulateRate(cmp, event, helper);
    },
    handleSave: function(cmp, event, helper) {
        helper.handleSave(cmp, event, helper);
    },
    handleSaveSimulation: function(cmp, event, helper) {
        helper.profitabilityCalculateRatesSimulation(cmp, event, helper);
    },
    handleEditDebit: function(cmp, event, helper) {
        helper.handleEditDebit(cmp, event, helper);
    },
    handleEditCredit: function(cmp, event, helper) {
        helper.handleEditCredit(cmp, event, helper);
    },
    handleEditInternational: function(cmp, event, helper) {
        helper.handleEditInternational(cmp, event, helper);
    },
    handleEditCreditSimulation: function(cmp, event, helper) {
        helper.handleEditCreditSimulation(cmp, event, helper);
    },
    handleEditInternationalSimulation: function(cmp, event, helper) {
        helper.handleEditInternationalSimulation(cmp, event, helper);
    },
    handleEditDebitSimulation: function(cmp, event, helper) {
        helper.handleEditDebitSimulation(cmp, event, helper);
    },
    handleModifyBills: function(cmp, event, helper) {
        helper.handleModifyBills(cmp, event, helper);
    },
    handleModifyTs: function(cmp, event, helper) {
        helper.handleModifyTs(cmp, event, helper);
    },
    handleSaveFamily: function(cmp, event, helper) {
        helper.handleSaveFamily(cmp, event, helper, false);
    },
    handleCheckODT: function(cmp, event, helper) {
        helper.handleCheckODT(cmp, event, helper);
    },
    handleSendReport: function(cmp, event, helper) {
        helper.handleSendReport(cmp, event, helper);
    },
    handleTabSelected: function(cmp, event, helper) {
        helper.handleTabSelected(cmp, event, helper);
    },
    handleTabSimulationSelected: function(cmp, event, helper) {
        helper.handleTabSimulationSelected(cmp, event, helper);
    },
    handleTabUpdateTasasSelected: function(cmp, event, helper) {
        helper.handleTabUpdateTasasSelected(cmp, event, helper);
    },
    handleMostrarInfo: function(cmp, event, helper) {
        helper.handleMostrarInfo(cmp, event, helper);
    },
    handleVerificarTasa: function(cmp, event, helper) {
        helper.handleVerificarTasa(cmp, event, helper);
    },
    handlegetStatusPrev: function(cmp, event, helper) {
        helper.handlegetStatusPrev(cmp, event, helper);
    },
    handlegetStatusNext: function(cmp, event, helper) {
        helper.handlegetStatusNext(cmp, event, helper);
    },
    calculateCostAndPrice: function(component, event, helper) {
        var target = event.target;
        var rowIndex = target.getAttribute("data-row-index");
        console.log("Row No : " + rowIndex);
    }
})