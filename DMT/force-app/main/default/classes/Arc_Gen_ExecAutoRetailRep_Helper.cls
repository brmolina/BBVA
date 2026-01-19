/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_ExecAutoRetailRep_Helper
* @Author   Eduardo Efrain Hernandez Rendon - eduardoefrain.hernandez.contractor@bbva.com
* @Date     Created: 2021-03-01
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Service for Executive Summary visualforce
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2021-03-01 eduardoefrain.hernandez.contractor@bbva.com
*             Class creation
* |2021-04-15 eduardoefrain.hernandez.contractor@bbva.com
*             Update methods with a lot of parameters to only one data map parameter
* -----------------------------------------------------------------------------------------------
*/
public with sharing class Arc_Gen_ExecAutoRetailRep_Helper {
    /*------------------------------------------------------------------------------------------------------
    *@Description Builder Arc_Gen_ExecAutoRetailRep_Helper
    * -----------------------------------------------------------------------------------------------------
    * @Author   Eduardo Efrain Hernandez Rendon
    * @Date     2019-07-03
    * @param    null
    * @return   Arc_Gen_ExecAutoRetailRep_Helper
    * @example  new Arc_Gen_ExecAutoRetailRep_Helper()
    * */
    @TestVisible
    private Arc_Gen_ExecAutoRetailRep_Helper() {
    }
    /*------------------------------------------------------------------------------------------------------
    *@Description Method to obtains the auto retail table data
    * -----------------------------------------------------------------------------------------------------
    * @Author   eduardoefrain.hernandez.contractor@bbva.com
    * @Date     2021-01-03
    * @param    recordId account_has_analysis related with Executive Summary
    * @param    wrappObj object with related objects to build PDF
    * @return   Arc_Gen_ExecAutoRetailRep_Controller.wrapPDF Object with related data to build Executive Summary
    * @example  Arc_Gen_ExecRep_Service_Helper.getAutoRetailData(rid,wrappObj)
    * */
    public static Arc_Gen_ExecAutoRetailRep_Controller.wrapPDF getAutoRetailData(Id rid, Arc_Gen_ExecAutoRetailRep_Controller.wrapPDF wrappObj) {
        final arce__Account_has_Analysis__c aha = Arc_Gen_AutoRetailBehaviorTable_Data.getPreviousSelectedYear(rid);
        final String year2 = aha.arce__year_id__c;
        if (year2 != null) {
            final String year1 = String.valueOf(Integer.valueOf(aha.arce__year_id__c) - 1);
            wrappObj.year1 = year1;
            wrappObj.year2 = year2;
            final Map<String, Object> dataType1 = new Map<String, Object> {'accHasAnalysisId' => rid,'tableType' => '1','year1' => year1,'year2' => year2, 'isExecSummary' => true};
            final Map<String, Object> dataType2 = new Map<String, Object> {'accHasAnalysisId' => rid,'tableType' => '2','year1' => year1,'year2' => year2, 'isExecSummary' => true};
            wrappObj.autoRetForNews = Arc_Gen_AutoRetailBehaviorTable_Service.getAutoRetRows(dataType1);
            wrappObj.autoForSemiNews = Arc_Gen_AutoRetailBehaviorTable_Service.getAutoRetRows(dataType2);
        }
        return wrappObj;
    }
}