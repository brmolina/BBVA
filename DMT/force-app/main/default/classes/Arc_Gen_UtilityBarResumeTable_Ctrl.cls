/**
* @File Name          : Arc_Gen_UtilityBarResumeTable_Ctrl.cls
* @Description        : table for customer politics resume
* @Author             : luisarturo.parra.contractor@bbva.com
* @Group              : ARCE
* @Last Modified By   : juanignacio.hita.contractor@bbva.com
* @Last Modified On   : 11/06/2020  09:00:00
* @Modification Log   :
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0    23/12/2019          luisarturo.parra.contractor@bbva.com     Initial Version
* 1.1    11/06/2020          juanignacio.hita.contractor@bbva.com     Added currency type, units and hidden total row to group resume
**/
public class Arc_Gen_UtilityBarResumeTable_Ctrl {
    /**private constructor for sonar**/
    private Arc_Gen_UtilityBarResumeTable_Ctrl(){}
/**
*-------------------------------------------------------------------------------
* @description get typologies for the table
*-------------------------------------------------------------------------------
* @date 23/12/2019
* @author luisarturo.parra.contractor@bbva.com
* @param none
* @return   List<arce__limits_typology__c>
* @example public static List<arce__limits_typology__c> getDataTypologies() {
*/
    @AuraEnabled
    public static List<arce__limits_typology__c> getDataTypologies() {
        return Arc_Gen_LimitsTypologies_Data.getTypologiesData();
    }
/**
*-------------------------------------------------------------------------------
* @description get data for the table
*-------------------------------------------------------------------------------
* @date 23/12/2019
* @author luisarturo.parra.contractor@bbva.com
* @param recordId analysisId of the account has analysis
* @return   List<String>
* @example public static List<String> getTableData(Id recordId) {
*/
    @AuraEnabled
    public static String getTableData(Id recordId) {
      return Arc_Gen_UtilityBarResumeTable_Service.getTableData(recordId);
    }
}