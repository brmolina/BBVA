/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_FinancialInfoRow
* @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
* @Date     Created: 2020-04-14
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Global wrapper that contain all the information to create rows in tables
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2020-04-15 mariohumberto.ramirez.contractor@bbva.com
*             Class creation.
* |2020-29-06 mariohumberto.ramirez.contractor@bbva.com
*             New parameters were added: 'year' and 'currencyVal'
* |2020-11-13 joseluis.garcia4.contractor@bbva.com
*             New parameter was added: 'unitsVal'
* -----------------------------------------------------------------------------------------------
**/
@SuppressWarnings('PMD.ExcessivePublicCount')
public without sharing class Arc_Gen_FinancialInfoRow {
    /**
    * @Description: String with the Id of the limit exposure object
    */
    @AuraEnabled public String name {get;set;}
    /**
    * @Description: String with the typology name in the table
    */
    @AuraEnabled public String rating {get;set;}
    /**
    * @Description: String with the product name in the table
    */
    @AuraEnabled public String totalBalance {get;set;}
    /**
    * @Description: String with the comments name in the table
    */
    @AuraEnabled public String ffpp {get;set;}
    /**
    * @Description: String with the total name in the table
    */
    @AuraEnabled public String netDebt {get;set;}
    /**
    * @Description: Amount of the last approved in the table
    */
    @AuraEnabled public String sales {get;set;}
    /**
    * @Description: Amount of the commited in the table
    */
    @AuraEnabled public String ebitda {get;set;}
    /**
    * @Description: Amount of the uncommited in the table
    */
    @AuraEnabled public String netProfit {get;set;}
    /**
    * @Description: Amount of the current limit in the table
    */
    @AuraEnabled public String debtEbitda {get;set;}
    /**
    * @Description: Amount of the outstanding in the table
    */
    @AuraEnabled public String intCov {get;set;}
    /**
    * @Description: Amount of the limit proposed in the table
    */
    @AuraEnabled public String margEbtda {get;set;}
    /**
    * @Description: year of the EEFF
    */
    @AuraEnabled public String year {get;set;}
    /**
    * @Description: currency of the EEFF
    */
    @AuraEnabled public String currencyVal {get;set;}
    /**
    * @Description: units of the EEFF
    */
    @AuraEnabled public String unitsVal {get;set;}
}