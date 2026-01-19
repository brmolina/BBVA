public class PRC_ScenarioWSA_CONTROLLER {
    @AuraEnabled
    public static List<PRC_Profitability_Scenarios__c> xdata(Id oppid){
        PRCPricingUtils engine = PRCPricingUtils.getInstance();
        return engine.getScenarioWithSalesAgreementData(oppid);
    }
}