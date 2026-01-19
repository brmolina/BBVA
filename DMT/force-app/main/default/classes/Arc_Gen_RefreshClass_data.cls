/**
* @File Name          : Arc_Gen_RefreshClass_data.cls
* @Description        : Call services and motors to update ARCE information
* @Author             : luisarturo.parra.contractor@bbva.com
* @Group              : ARCE Team
* @Controller Class   : Arc_Gen_ProposeInPreparation_controller
* @Service Class      : Arc_Gen_RefreshClass_service
* @Test Class         : Arc_Gen_RefreshClass_test
* @Last Modified By   : juanignacio.hita.contractor@bbva.com
* @Last Modified On   : 24/06/2020
* @Modification Log   :
*==============================================================================================
* Ver         Date                     Author      		                        Modification
*==============================================================================================
* 1.0         28/04/2019           luisarturo.parra.contractor@bbva.com         Initial Version Refactor
* 1.2         06/12/2019           luisarturo.parra.contractor@bbva.com         add field arce__Analysis__r.arce__analysis_customer_relation_type__c
* 1.3         29/01/2020           juanmanuel.perez.ortiz.contractor@bbva.com   Remove companyEcoAct, accActivity, rtDevName from logic of account wrapper
* 1.4         07/02/2020           juanignacio.hita.contractor@bbva.com         Refactorization
* 1.5         08/05/2020           juanmanuel.perez.ortiz.contractor@bbva.com   Change reference fro method buildAccHasAnalysis
* 1.6         24/06/2020           juanignacio.hita.contractor@bbva.com         Added isHolding parameter n the AHA buildAccHasAnalysis creation method
* 1.6         23/09/2020     saimassimilianno.jordana.contractor@bbva.com Added arce. namespace to all classes that are now in the arce-dependencies package
**/
public without sharing class Arc_Gen_RefreshClass_data {
    /**
    *-------------------------------------------------------------------------------
    * @description empty constructor to sonar validations
    *--------------------------------------------------------------------------------
    * @date		28/05/2019
    * @author	diego.miguel.contractor@bbva.com
    */
    @TestVisible
    private Arc_Gen_RefreshClass_data() {
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Create a new Account has Analysis
    *--------------------------------------------------------------------------------
    * @date		28/04/2019
    * @author	diego.miguel.contractor@bbva.com
    * @param	List<String> participantNoExist
    * @param	arce__Analysis__c analysis
    * @param	Map<String, Boolean> mapIsHolding
    * @return	List<arce__Account_has_Analysis__c>
    * @example	List<arce__Account_has_Analysis__c> lst = createAHAParticipants(participantNoExist, analysis, mapIsHolding)
    */
    public static List<arce__Account_has_Analysis__c> createAHAParticipants(List<String> participantNoExist, arce__Analysis__c analysis, Map<String, Boolean> mapIsHolding) {
        List<arce__Account_has_Analysis__c> lstAcc = new List<arce__Account_has_Analysis__c>();
        final Map<String,arce.Arc_Gen_Account_Wrapper> mapAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(participantNoExist);
        for (String key : mapAccWrapper.keySet()) {
            Arc_Gen_NewAnalysis_Service.BuildAhaWrapper buildAhaWrapper = new Arc_Gen_NewAnalysis_Service.BuildAhaWrapper(analysis, mapAccWrapper.get(key));
            buildAhaWrapper.emptyFFSS = new List<arce__Financial_Statements__c>();
            buildAhaWrapper.clientType = analysis.arce__anlys_wkfl_sub_process_type__c;
            buildAhaWrapper.isHolding = mapIsHolding.get(key);
            final arce__Account_has_Analysis__c acc = Arc_Gen_NewAnalysis_Service.buildAccHasAnalysis(buildAhaWrapper);
            lstAcc.add(acc);
        }
        return lstAcc;
    }
    /**
    * @description gets Analysis data and returns it in a map:
    * id (String)
    * arceId (String)
    * customerId (String)
    * customerNumber (String)
    * path (String)
    * name (String)
    * customerName (String)
    * rating (String)
    * parentId (String)
    * rtName (String)
    * arce__wf_status_id (String)
    *--------------------------------------------------------------------------------
    * @date		28/04/2019
    * @author	diego.miguel.contractor@bbva.com
    * @param	String miniArceId - account_has_analysis Id
    * @return	map<String,Object>
    * @example	public static map<String,Object> getAnalysis(String miniArceId)
    */
    public static map<String,Object> getAnalysis(String miniArceId) {
        List<String> lstStrRecords = new List<String>{miniArceId};
        List<arce.Arc_Gen_Account_Has_Analysis_Wrapper> lstAHAAndCustomer = arce.Arc_Gen_AccHasAnalysis_Data.getAccountHasAnalysisAndCustomer(lstStrRecords);
        map<String,Object> miniArceData = new map<String,Object>();
        miniArceData.put('id', lstAHAAndCustomer[0].ahaObj.Id);
        miniArceData.put('arceId', lstAHAAndCustomer[0].ahaObj.arce__Analysis__c);
        miniArceData.put('customerId', lstAHAAndCustomer[0].accWrapperObj.accId);
        miniArceData.put('customerNumber', lstAHAAndCustomer[0].accWrapperObj.accNumber);
        miniArceData.put('participantType', lstAHAAndCustomer[0].accWrapperObj.participantType);
        miniArceData.put('path', lstAHAAndCustomer[0].ahaObj.arce__path__c);
        miniArceData.put('name', lstAHAAndCustomer[0].ahaObj.Name);
        miniArceData.put('customerName', lstAHAAndCustomer[0].accWrapperObj.name);
        miniArceData.put('parentId', lstAHAAndCustomer[0].accWrapperObj.accParentId);
        miniArceData.put('arce__wf_status_id',lstAHAAndCustomer[0].ahaObj.arce__Analysis__r.arce__wf_status_id__c);
        miniArceData.put('arceStage', lstAHAAndCustomer[0].ahaObj.arce__Analysis__r.arce__Stage__c);
        miniArceData.put('groupAsset',lstAHAAndCustomer[0].ahaObj.arce__group_asset_header_type__c);
        // Falta el participant type
        // check if validEF and get rating
        if (!String.isEmpty(lstAHAAndCustomer[0].ahaObj.arce__ffss_for_rating_id__c)) {
            arce__Financial_Statements__c validFinancialState = [SELECT id,arce__rating_final__c FROM arce__Financial_Statements__c WHERE Id =:lstAHAAndCustomer[0].ahaObj.arce__ffss_for_rating_id__c LIMIT 1];
            miniArceData.put('rating', validFinancialState.arce__rating_final__c);
        }
        Return miniArceData;
    }
}