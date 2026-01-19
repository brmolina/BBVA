/**
* @File Name          : Arc_Gen_ProposeInSanction_Service.cls
* @Description        : Service class for propose in sanction
* @Author             : luisarturo.parra.contractor@bbva.com
* @Group              : ARCE
* @Last Modified By   : juanignacio.hita.contractor@bbva.com
* @Last Modified On   : 04/12/2020 10:30:00
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |05/07/2019  luisarturo.parra.contractor@bbva.com
*             Class creation.
* |10/12/2019 juanmanuel.perez.ortiz.contractor@bbva.com
*             Add logic to assign previous and owner user
* |26/12/2019 juanmanuel.perez.ortiz.contractor@bbva.com
*             Add logic to send notifications
* |2020-01-24 luisruben.quinto.munoz@bbva.com
*             Change to without sharing and added field arce__proposeUser__c and fix comments
* |2020-07-13 joseluis.garcia4.contractor@bbva.com
*             Add editPermissionCheck() method.
* |2020-08-18 joseluis.garcia4.contractor@bbva.com
*             Change reference from Arc_Gen_StatusButtons to arce.Arc_Gen_GenericUtilities.
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
*             Change reference from Arc_Gen_StatusButtons to Arc_Gen_GenericUtilities.
* |2020-12-04 juanignacio.hita.contractor@bbva.com
*             Adds aha name (analysisId) param in traceability record
* -----------------------------------------------------------------------------------------------
  **/
public with sharing class Arc_Gen_ProposeInSanction_Service {
  /**
  *-------------------------------------------------------------------------------
  * @description Constructor method for sonnar
  *--------------------------------------------------------------------------------
  * @author juanignacio.hita.contractor@bbva.com
  * @date   05/02/2020
  * @return void
  * @example  private Arc_Gen_ProposeInSanction_Service()
  **/
  @TestVisible
  private Arc_Gen_ProposeInSanction_Service() {
  }
  /**
  *-------------------------------------------------------------------------------
  * @description Check if current user has edit permissions on analysis. Throws exception
  * if it is not the case.
  --------------------------------------------------------------------------------
  * @author joseluis.garcia4.contractor@bbva.com
  * @date 13/07/2020
  * @param Id ahaId - ID of the Account_has_Analysis__c record
  **/
  public static void editPermissionCheck(Id ahaId) {
    if (!arce.Arc_Gen_GenericUtilities.isButtonAvailable(ahaId, 'Arc_Gen_ProposeInSanction')) {
      throw new AuraHandledException(System.Label.Arc_Gen_Generic_ButtonNotAllowed);
    }
  }
  /**
  *-------------------------------------------------------------------------------
  * @description get customers who are in review
  --------------------------------------------------------------------------------
  * @author luisarturo.parra.contractor@bbva.com
  * @date 5/10/2019
  * @param boolean appear the account has analisis selected
  * @param  String recordId the account has analisis to query
  * @return Arc_Gen_ProposeInSanction_Controller.WrapperAccHasAnalysis
  * @example public static List < arce__Account_has_Analysis__c > getCustomersService(Boolean appear)
  **/
  public static Arc_Gen_ProposeInSanction_Wrappers.WrapperGeneral getCustomersService(Boolean appear, Id arceId) {
    final List<Map<String, String>> lstWrapper = new List<Map<String, String>>();
    List<arce__Account_has_Analysis__c> customerList = new List<arce__Account_has_Analysis__c > ();
    final Map<String, Arc_Gen_ProposeInSanction_Wrappers.WrapperAccHasAnalysis> mapWrapper = new Map<String, Arc_Gen_ProposeInSanction_Wrappers.WrapperAccHasAnalysis>();
    final Arc_Gen_ProposeInSanction_Wrappers.WrapperGeneral wrapperGeneral = new Arc_Gen_ProposeInSanction_Wrappers.WrapperGeneral();

    if (appear) {
      customerList = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnFromArce(arceId);
    }
    if(!customerList.isEmpty()) {
      for(arce__Account_has_Analysis__c acc : customerList) {
        final Arc_Gen_ProposeInSanction_Wrappers.WrapperAccHasAnalysis wrapper = new Arc_Gen_ProposeInSanction_Wrappers.WrapperAccHasAnalysis();
        wrapper.recordId = acc.Id;
        wrapper.mainSubsidiary = acc.arce__main_subsidiary_ind_type__c;
        wrapper.ffssRatingId = acc.arce__ffss_for_rating_id__c;
        wrapper.ffssRatingFinal = acc.arce__ffss_for_rating_id__r.arce__rating_final__c;
        wrapper.customerId = acc.arce__Customer__r.Id;
        wrapper.customerName = acc.arce__Customer__r.Name;
        lstWrapper.add(new map<String,String>{'label' => acc.arce__Customer__r.Name , 'value' => acc.Id});
        mapWrapper.put(acc.Id, wrapper);
      }
      wrapperGeneral.mapAccHasAnalysis = mapWrapper;
      wrapperGeneral.mapComboBox = lstWrapper;
    }
    return wrapperGeneral;
  }
  /**
  *-------------------------------------------------------------------------------
  * @description update values of step 1 in modal
  --------------------------------------------------------------------------------
  * @author luisarturo.parra.contractor@bbva.com | 5/7/2019
  * @date 5/10/2019
  * @param  arce__Account_has_Analysis__c element to update
  * @return void
  * @example public static void updateStep1service(arce__Account_has_Analysis__c element)
  **/
  public static void updateMainSubsidiary(Arc_Gen_ProposeInSanction_Wrappers.WrapperAccHasAnalysis element) {
    final arce__Account_has_Analysis__c accHasAnalysis = new arce__Account_has_Analysis__c();
    accHasAnalysis.Id = element.recordId;
    accHasAnalysis.arce__main_subsidiary_ind_type__c = element.mainSubsidiary;
    final List<arce__Account_has_Analysis__c> lstAccHasAnalysis = new List<arce__Account_has_Analysis__c>();
    lstAccHasAnalysis.add(accHasAnalysis);
    arce.Arc_Gen_AccHasAnalysis_Data.updateAccHasAnalysis(lstAccHasAnalysis);
  }
  /**
  *-------------------------------------------------------------------------------
  * @description  get stage to update
  --------------------------------------------------------------------------------
  * @author luisarturo.parra.contractor@bbva.com | 5/7/2019
  * @date 5/10/2019
  * @param  List < arce__Analysis__c > stageObjectToUpdate of analsis to update
  * @return List < arce__Analysis__c > of analsis to update
  * @example  public static void updateStageSetStage(List < arce__Analysis__c > stageObjectToUpdate)
  **/
  public static void updateStageSetStage(Id arceId, string stage) {
    Map<String, Object> fieldValueMap = new Map<String, Object>();
    fieldValueMap.put('arce__stage_collective_type__c', stage);
    arce.Arc_Gen_ArceAnalysis_Data.editAnalysisFields(arceId, fieldValueMap);
  }
  /**
  *-------------------------------------------------------------------------------
  * @description  setAmbitService
  --------------------------------------------------------------------------------
  * @author juanignacio.hita.contractor@bbva.com
  * @date   09/01/2020
  * @param  String : ambit
  * @param  Id : accHasAnalysisId
  * @param  Arc_Gen_Delegation_Wrapper : wrapper
  * @return void
  * @example setAmbitService(ambit, accHasAnalysisId, wrapper);
  **/
  public static Arc_Gen_Delegation_Wrapper setAmbitService(String ambitSelected, Id accHasAnalysisId, Arc_Gen_Delegation_Wrapper wrapper) {
    final arce.Arc_Gen_User_Wrapper wrpUser = arce.Arc_Gen_User_Locator.getUserInfo(System.UserInfo.getUserId());
    Arc_Gen_Delegation_Wrapper wrapperRet = wrapper;
    if (ambitSelected == wrpUser.ambitUser) {
      wrapperRet = Arc_Gen_Propose_Helper.evaluateDelegationA(wrapper, 'SANCTION', accHasAnalysisId);
    } else {
      List<String> valuesSelected = new List<String>{ambitSelected};
      wrapper.lstAmbits =  arce.Arc_Gen_GenericUtilities.getPicklistValuesLabels('arce__Analysis__c','arce__anlys_wkfl_edit_br_level_type__c', valuesSelected);
      wrapperRet = Arc_Gen_Propose_Helper.evaluateDelegationElement(wrapper, accHasAnalysisId, 'SANCTION');
    }
    return wrapperRet;
  }
}