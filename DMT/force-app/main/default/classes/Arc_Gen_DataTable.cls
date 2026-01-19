/**
* @Name          : arce.Arc_Gen_CustomServiceMessages.cls
* @Description        : @description wrapper for the data table tree grid component
* @Project:      	    ARCE - BBVA Bancomer
* @Author             : luisruben.quinto.munoz@bbva.com
* @Date     Created: 2019-11-04
* @Group              : ARCE
* @Changes :
*==============================================================================
* Ver         Date                     Author      		      Modification
*==============================================================================
* 1.0    2019-11-04 20:53:04   luisruben.quinto.munoz@bbva.com     Initial Version
* 1.24   23/09/2020     saimassimilianno.jordana.contractor@bbva.com Added arce. namespace to all classes that are now in the arce-dependencies package
**/
global class Arc_Gen_DataTable {
    /**
    * @Description: List of Arc_Gen_TableRow wrapper
    */
    @AuraEnabled public List<Arc_Gen_TableRow> data {get;set;}
    /**
    * @Description: List of Arc_Gen_TableColumns wrapper
    */
    @AuraEnabled public List<Arc_Gen_TableColumns> columns {get;set;}
    /**
    * @Description: List of Arc_Gen_TableColumns wrapper
    */
    @AuraEnabled public List<Arc_Gen_FinancialInfoRow> finInfoRow {get;set;}
}