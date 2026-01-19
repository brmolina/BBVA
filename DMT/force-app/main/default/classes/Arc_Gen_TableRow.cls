/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_TableRow
* @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
* @Date     Created: 2019-06-20
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Global wrapper that contain all the information to create rows in tables
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2019-06-20 mariohumberto.ramirez.contractor@bbva.com
*             Class creation.
* |2019-07-24 mariohumberto.ramirez.contractor@bbva.com
*             Add new param "hasChild"
* |2019-07-24 mariohumberto.ramirez.contractor@bbva.com
*             Add new params "product" "comments", 'total' and recordTypeId
* |2020-01-28 mariohumberto.ramirez.contractor@bbva.com
*             Add new params "currencyType" "unit"
* |2021-04-28 juanmanuel.perez.ortiz.contractor@bbva.com
*             Add new param "itsTotal"
* -----------------------------------------------------------------------------------------------
**/
@SuppressWarnings('PMD.ExcessivePublicCount,sf:TooManyFields')
global class Arc_Gen_TableRow {
    /**
    * @Description: String with the Id of the limit exposure object
    */
    @AuraEnabled public String name {get;set;}
    /**
    * @Description: String with the typology name in the table
    */
    @AuraEnabled public String tipology {get;set;}
    /**
    * @Description: String with the product name in the table
    */
    @AuraEnabled public String product {get;set;}
    /**
    * @Description: String with the comments name in the table
    */
    @AuraEnabled public String comments {get;set;}
    /**
    * @Description: String with the total name in the table
    */
    @AuraEnabled public String total {get;set;}
    /**
    * @Description: Amount of the last approved in the table
    */
    @AuraEnabled public Double lastApproved {get;set;}
    /**
    * @Description: Amount of the commited in the table
    */
    @AuraEnabled public Double commited {get;set;}
    /**
    * @Description: Amount of the uncommited in the table
    */
    @AuraEnabled public Double uncommited {get;set;}
    /**
    * @Description: Amount of the current limit in the table
    */
    @AuraEnabled public Double currentLimit {get;set;}
    /**
    * @Description: Amount of the outstanding in the table
    */
    @AuraEnabled public Double outstanding {get;set;}
    /**
    * @Description: Amount of the limit proposed in the table
    */
    @AuraEnabled public Double limitProposed {get;set;}
    /**
    * @Description: Amount of the proposed approved in the table
    */
    @AuraEnabled public Double proposedApproved {get;set;}
    /**
    * @Description: recordTypeId of the object
    */
    @AuraEnabled public Id recordTypeId {get;set;}
    /**
    * @Description: List of children data
    */
    @AuraEnabled public List<Arc_Gen_TableRow> children {get;set;}
    /**
    * @Description: Map with the display order data in the table
    */
    @AuraEnabled public Map<String,Double> order {get;set;}
    /**
    * @Description: Map with some info in the data
    */
    @AuraEnabled public Map<String,String> info {get;set;}
    /**
    * @Description: Boolean to know if the tipology has a child
    */
    @AuraEnabled public Boolean hasChild {get;set;}
    /**
    * @Description: currency of the table
    */
    @AuraEnabled public String currencyType {get;set;}
    /**
    * @Description: unit of the table
    */
    @AuraEnabled public String unit {get;set;}
    /**
    * @Description: Boolean to know if the row is TOTAL
    */
    @AuraEnabled public Boolean itsTotal {get;set;}
}