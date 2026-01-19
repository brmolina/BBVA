/**
* @File Name          : Arc_Gen_UtilityBarFire_Controller.cls
* @Description        : Controller for the Utility Bar Fire component
* @Author             : juanignacio.hita.contractor@bbva.com
* @Group              : ARCE Team
* @Last Modified By   : juanignacio.hita.contractor@bbva.com
* @Last Modified On   : 13/11/2019 12:16
* @Changes            :
*==============================================================================
* Ver         Date                     Author      		      Modification
*==============================================================================
* 1.0    30/4/2019 18:00:36   juanignacio.hita.contractor@bbva.com     Initial Version
* 1.0    23/09/2020     saimassimilianno.jordana.contractor@bbva.com   Added arce. namespace to all classes that are now in the arce-dependencies package
**/
public with sharing class Arc_Gen_UtilityBarFire_Controller {
    /**
    *-------------------------------------------------------------------------------
    * @description Private method for sonar
    --------------------------------------------------------------------------------
    * @author luisarturo.parra.contractor@bbva.com
    * @date 13/11/2019
    * @example private Arc_Gen_UtilityBarFire_Controller(){
    **/
    @testVisible
    private Arc_Gen_UtilityBarFire_Controller(){
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that get the analysis for the account
    --------------------------------------------------------------------------------
    * @author juanignacio.hita.contractor@bbva.com
    * @date 13/11/2019
    * @param String recordId of the account has analisis
    * @return Arc_Gen_TestLeverage_service.leverageTestResponse - Wrapper with the response of the leveraged test
    * @example public static Arc_Gen_TestLeverage_service.leverageTestResponse setupLeverage(String analysisId)
    **/
    @AuraEnabled
    public static String getAnalysis(String recordId) {
        List<String> lstRecordId = new List<String>();
        lstRecordId.add(recordId);
        List<arce__Account_has_Analysis__c> lstAccHasAnalysis = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(lstRecordId);
        return lstAccHasAnalysis[0].arce__Analysis__c;
    }
}