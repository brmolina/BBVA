/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_AutoRetailTableRow
* @Author   Eduardo Efrain Hernandez Rendon - eduardoefrain.hernandez.contractor@bbva.com
* @Date     Created: 2021-01-26
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Contains the Rows for the Auto Retail Behavior table
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2021-01-26 eduardoefrain.hernandez.contractor@bbva.com
*             Class Creation
* |2021-02-15 eduardoefrain.hernandez.contractor@bbva.com
*             Added customCSSClass field
* |2021-03-04 eduardoefrain.hernandez.contractor@bbva.com
*             Added string fields to format the Decimal falues
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('PMD.ExcessivePublicCount, sf:LongVariable, sf:AvoidGlobalModifier, sf:TooManyFields')
global class Arc_Gen_AutoRetailTableRow {
    /**
    * @Description: Id of the arce__autoretail_behavior_table__c selected record
    */
    @AuraEnabled public String standardRowId {get;set;}
    /**
    * @Description: Id of the arce__autoretail_behavior_by_year__c year 1 record
    */
    @AuraEnabled public String standardYear1Id {get;set;}
    /**
    * @Description: Id of the arce__autoretail_behavior_by_year__c year 2 record
    */
    @AuraEnabled public String standardYear2Id {get;set;}
    /**
    * @Description: Name of the Company/Agency
    */
    @AuraEnabled public String agencyName {get;set;}
    /**
    * @Description: Name of the Brand
    */
    @AuraEnabled public String brand {get;set;}
    /**
    * @Description: Number of agencies
    */
    @AuraEnabled public Integer agenciesNumber {get;set;}
    /**
    * @Description: Number of agencies
    */
    @AuraEnabled public String sAgenciesNumber {get;set;}
    /**
    * @Description: Total units sold in the year 1
    */
    @AuraEnabled public Decimal totalUnitsYear1 {get;set;}
    /**
    * @Description: Total units sold in the year 1
    */
    @AuraEnabled public String sTotalUnitsYear1 {get;set;}
    /**
    * @Description: Total units sold in the year 2
    */
    @AuraEnabled public Decimal totalUnitsYear2 {get;set;}
    /**
    * @Description: Total units sold in the year 1
    */
    @AuraEnabled public String sTotalUnitsYear2 {get;set;}
    /**
    * @Description: Stock rotation description of the year 1
    */
    @AuraEnabled public String stockRotationYear1 {get;set;}
    /**
    * @Description: Stock rotation description of the year 2
    */
    @AuraEnabled public String stockRotationYear2 {get;set;}
    /**
    * @Description: Bank risk balance
    */
    @AuraEnabled public Decimal bankRisk {get;set;}
    /**
    * @Description: Bank risk balance
    */
    @AuraEnabled public String sBankRisk {get;set;}
    /**
    * @Description: Number of days in stock
    */
    @AuraEnabled public Decimal stockDays {get;set;}
    /**
    * @Description: Number of days in stock
    */
    @AuraEnabled public String sStockDays {get;set;}
    /**
    * @Description: Number of days in stock
    */
    @AuraEnabled public String customCSSClass {get;set;}
}