/*------------------------------------------------------------------
* @File Name : Arc_Gen_ProposeInPreparation_Service
* @Author:      Luisarturo.parra.contractor@bbva.com
* @Project:     ARCE - BBVA Bancomer
* @Group:       ARCE
* @Description:   Test class for code coverage of:
* @Last Modified By   : juanignacio.hita.contractor@bbva.com
* @Last Modified On   : 04/12/2020
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |11/04/2019 luisarturo.parra.contractor@bbva.com
*             Class creation. /Refactorizacion
* |10/12/2019 juanmanuel.perez.ortiz.contractor@bbva.com
*             Add logic to assign previous and owner user
* |26/12/2019 juanmanuel.perez.ortiz.contractor@bbva.com
*             Add logic to send notifications
* |2020-01-24 luisruben.quinto.munoz@bbva.com
*             Change to without sharing and added field arce__proposeUser__c and fix comments
* |2020-02-28 juanignacio.hita.contractor@bbva.com
*             Remove traceability move to propose helper file
* |2020-03-24 mariohumberto.ramirez.contractor@bbva.com
*             Added new call to the method Arc_Gen_Propose_Helper.updateProposeInPrepDate
* |2020-09-15 juanignacio.hita.contractor@bbva.com
*             Remove unused methods
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2020-12-04 juanignacio.hita.contractor@bbva.com
*             Adds aha name (analysisId) param in traceability record
* -----------------------------------------------------------------------------------------------
*/
public without sharing class Arc_Gen_ProposeInPreparation_service {
    /**
    *-------------------------------------------------------------------------------
    * @description Constructor method for sonnar
    *--------------------------------------------------------------------------------
    * @author juanignacio.hita.contractor@bbva.com
    * @date   05/02/2020
    * @return void
    * @example  private Arc_Gen_ProposeInPreparation_service()
    **/
    @TestVisible
    private Arc_Gen_ProposeInPreparation_service() {
    }
    /**
    *-------------------------------------------------------------------------------
    * @Description  Methot that valid financial statements
    *-------------------------------------------------------------------------------
    * @date  01/10/2019
    * @author mariohumberto.ramirez.contractor@bbva.com
    * @param arceId - Id of the ARCE
    * @param sanction ambit chosen
    * @return wrp wrapper for propose in sanction
    *------------------------------------------------------------------------------
    */
    public static Boolean validateAllRatingsInArce(Id arceId) {
        Boolean ratingValid = true;
        final List<arce__Account_has_Analysis__c> accHasAn = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnFromArce(arceId);
        List<String> finStatementIds = new List<String>();
        for (arce__Account_has_Analysis__c accHas: accHasAn) {
            if (accHas.arce__group_asset_header_type__c != '1') { // no se valida para el FS del grupo, a modificar con lógica TD/BU
                finStatementIds.add(accHas.arce__ffss_for_rating_id__c);
            }
        }
        final List<arce__Financial_Statements__c> finStatementObjLts = arce.Arc_Gen_FinancialStatements_locator.getFSInfo(finStatementIds);
        for (arce__Financial_Statements__c fs: finStatementObjLts) {
            if (!Arc_Gen_Balance_Tables_helper.validateFSForRating(fs)) {
                ratingValid = false;
            }
        }
        return ratingValid;
    }
    /**
    *-------------------------------------------------------------------------------
    * @Description  Save the reason for the sanction
    *-------------------------------------------------------------------------------
    * @date  26/04/2019
    * @author angel.fuertes2@bbva.com
    * @Method:      Save the reason for the sanction
    * @param recordId record id (arce__Analysis__c)
    * @param sanction sanction
    * @return wrp
    */
    public static Arc_Gen_Delegation_Wrapper saveAction(Arc_Gen_Delegation_Wrapper wrapper, Id accHasAnalysisId, String ambit) {
        final arce.Arc_Gen_User_Wrapper wrpUser = arce.Arc_Gen_User_Locator.getUserInfo(System.UserInfo.getUserId());
        Arc_Gen_Delegation_Wrapper wrapperRet = new Arc_Gen_Delegation_Wrapper();
        if (ambit == wrpUser.ambitUser) {
            wrapperRet = Arc_Gen_Propose_Helper.evaluateDelegationA(wrapper, 'PREPARATION', accHasAnalysisId);
        } else {
            final List<String> valuesSelected = new List<String>{ambit};
            wrapper.lstAmbits =  arce.Arc_Gen_GenericUtilities.getPicklistValuesLabels('arce__Analysis__c','arce__anlys_wkfl_edit_br_level_type__c', valuesSelected);
            wrapperRet = Arc_Gen_Propose_Helper.evaluateDelegationElement(wrapper, accHasAnalysisId, 'PREPARATION');
        }
        if (wrapperRet.codStatus == 200 || wrapperRet.codStatus == 201) {
            Arc_Gen_Propose_Helper.updateProposeInPrepDate(wrapper);
        }
        return wrapperRet;
    }
}