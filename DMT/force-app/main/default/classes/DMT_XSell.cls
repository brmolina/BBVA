public with sharing class DMT_XSell {
    
    @AuraEnabled(cacheable=true)
    public static List<DMT_X_Sell__c> getXsell(Id opportunityId) {

        Opportunity opportunity = [SELECT Id,DMT_DATE_Initial_Date__c FROM Opportunity WHERE Id =: opportunityId WITH SECURITY_ENFORCED LIMIT 1];       

        System.debug('opportunity.DMT_DATE_Initial_Date__c ' + opportunity.DMT_DATE_Initial_Date__c);

        date xSellDate = opportunity.DMT_DATE_Initial_Date__c.addYears(-6);

        System.debug('xSellDate ' + xSellDate);


        return [SELECT Id,g_year__c,g_notional_amount__c,DMT_Currency__c FROM DMT_X_Sell__c WHERE g_year__c >: xSellDate AND g_year__c <:  opportunity.DMT_DATE_Initial_Date__c WITH SECURITY_ENFORCED ORDER BY g_year__c LIMIT 5];
    }
}