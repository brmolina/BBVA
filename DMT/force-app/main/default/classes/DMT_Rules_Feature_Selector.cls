public with sharing class DMT_Rules_Feature_Selector {
    
    public static List<DMT_Fuature_Rule__c> getFeatureRules (List<String> featureType,String validateType) {
        return [SELECT Id, DMT_Is_Required_Field__c,DMT_Feature_Type__c,DMT_Field__c,dmt_message__c FROM DMT_Fuature_Rule__c WHERE DMT_Feature_Type__c IN :featureType AND DMT_Validate_Type__c = :validateType WITH SECURITY_ENFORCED];
    }

    public static DMT_Line__c getLine(String lineId) {
        return [SELECT Id, OwnerId, IsDeleted, Name, CurrencyIsoCode, RecordTypeId, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, LastViewedDate, LastReferencedDate, Amount__c, Max_Tenor__c, Clearing__c, Allowed__c, Status__c, Client__c, DvP_Amount__c, Custom_Association__c, FD_Amount__c, Line_Term__c, Start_Date__c, End_Date__c, Product__c, Booking_Geography__c, Closed__c, DvP_Currency__c, FD_Currency__c, Client_Type__c, Treasury_Currency__c, Depos_Limit__c, Depos_Limit_1Y__c, Equity_Limit__c, Repos_Limit__c, Repos_Limit_6M__c, First_Breakclause__c, Breakclause_Frequency__c, DMT_CreatedDate__c, DMT_Status_Completed__c, First_Breakclause_Date__c, DMT_Cancel__c, DMT_Origin__c, DMT_ClientInfoJSON__c, DMT_DateToProposal__c, Waiver__c, Line_Details__c, Client_Code__c, Line_Id__c, DMT_DerivativesAmount__c, DMT_EquitiesAmount__c, DMT_DeposAmount__c, DMT_Comments__c, DMT_Parent_Line__c, DMT_Total_Amount__c, DMT_Client_Entific__c, DMT_Operation__c, DMT_Nominal__c, DMT_Franchise_L12M__c, DMT_RAROEC_RORC_Proposal__c FROM DMT_Line__c WHERE Id =: lineId WITH SECURITY_ENFORCED];
    }

    public static Opportunity getOpportunity(String opportunityId) {
        return [SELECT Id, OwnerId, IsDeleted, Name, CurrencyIsoCode, RecordTypeId, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, LastViewedDate, LastReferencedDate, DMT_CUR_Notional_Amount_Sum__c, StageName, AccountId, DMT_DATE_Initial_Date__c, DMT_RUP_Maturity_Date__c, DMT_Client_Type__c, Booking__c, DMT_Opp_Id__c, DMT_Parent_Opportunity__c, Description FROM Opportunity WHERE Id =: opportunityId WITH SECURITY_ENFORCED];
    }
}