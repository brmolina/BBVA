/**
  * @File Name : Arc_Gen_ProposeInSanction_Controller.cls
  * @Description : controller of Arc_Gen_ProposeInSanction_Data and Arc_Gen_ProposeInSanction_Service
  * @Author : luisarturo.parra.externo@bbva.com
  * @Group : ARCE - BBVA Bancomer
  * @Last Modified By : luisruben.quinto.munoz@bbva.com
  * @Last Modified On : 11/11/2019 13:52:33
  * @Modification Log :
  *==============================================================================
  * Ver Date Author          Modification
  *==============================================================================
  * 1.0 16/04/2019 ARCE TEAM Creación.
  * 1.1 28/06/2019 Add function that validate rating.
  * 1.2 28/06/2019 Added comments.
  * 1.3 13/07/2020 Check for edit permissions on all mutation actions.
  * 1.3 23/09/2020 Added arce. namespace to all classes that are now in the arce-dependencies package
  * 1.4 19/07/2020 Creates persistArceAction method that invokes actions service
  **/
@SuppressWarnings('sf:TooManyMethods')
public with sharing class Arc_Gen_ProposeInSanction_Controller {

  /**
  *-------------------------------------------------------------------------------
  * @description Constructor method for sonnar
  *--------------------------------------------------------------------------------
  * @author luisruben.quinto.munoz@bbva.com
  * @date 5/10/2019
  * @return void
  * @example  private Arc_Gen_ProposeInSanction_Controller()
  **/
  @TestVisible
  private Arc_Gen_ProposeInSanction_Controller() {
  }

  /**
  *-------------------------------------------------------------------------------
  * @description get customers who are in review
  *--------------------------------------------------------------------------------
  * @author luisarturo.parra.contractor@bbva.com
  * @date 5/10/2019
  * @param boolean appear for modal show and hide
  * @param String recordId to query the arce data
  * @return List < Arc_Gen_ProposeInSanction_Controller.WrapperAccHasAnalysis >
  * @example public static List < arce__Account_has_Analysis__c > getCustomerDatactrl(Boolean appear)
  **/
  @AuraEnabled
  public static Arc_Gen_ProposeInSanction_Wrappers.WrapperGeneral getCustomerDatactrl(Boolean appear, Id accHasAnalysisId) {
    Arc_Gen_ProposeInSanction_Service.editPermissionCheck(accHasAnalysisId);
    try {
      final arce__Analysis__c arceVar = arce.Arc_Gen_ArceAnalysis_Data.gerArce(accHasAnalysisId);
      //final Arc_Gen_ProposeInSanction_Wrappers.WrapperGeneral resp = Arc_Gen_ProposeInSanction_Service.getCustomersService(appear, arceVar.Id);
      return Arc_Gen_ProposeInSanction_Service.getCustomersService(appear, arceVar.Id);
    } catch (Exception e) {
        throw new AuraHandledException(System.Label.Arc_Gen_ApexCallError+e);
    }
  }
    /**
    *-------------------------------------------------------------------------------
    * @description get ARCE id from Account has analysis
    *--------------------------------------------------------------------------------
    * @author javier.soto.carrascosa@bbva.com
    * @date 22/10/2019
    * @param string Id of account has analysis
    * @return List < arce__Account_has_Analysis__c >
    * @example public static arce__Analysis__c getArceId (string Id)
    **/
  @AuraEnabled
  public static arce__Analysis__c getArceId (Id accHasId) {
    arce__Analysis__c resp  = new arce__Analysis__c();
    try {
      resp = arce.Arc_Gen_ArceAnalysis_Data.gerArce(accHasId);
    } catch (Exception e) {
        throw new AuraHandledException(System.Label.Arc_Gen_ApexCallError+e);
    }
    return resp;
  }
    /**
    *-------------------------------------------------------------------------------
    * @description update values of step 1 in modal
    *--------------------------------------------------------------------------------
    * @author luisarturo.parra.contractor@bbva.com | 5/7/2019
    * @date 5/10/2019
    * @param  arce__Account_has_Analysis__c element
    * @return void
    * @example public static void updateStep1crtl(arce__Account_has_Analysis__c element)
    **/
  @AuraEnabled
  public static void updateMainSubsidiary(Arc_Gen_ProposeInSanction_Wrappers.WrapperAccHasAnalysis element) {
    Arc_Gen_ProposeInSanction_Service.editPermissionCheck(element.recordId);
    try {
      Arc_Gen_ProposeInSanction_Service.updateMainSubsidiary(element);
    } catch (Exception e) {
        throw new AuraHandledException(System.Label.Arc_Gen_ApexCallError+e);
    }
  }
    /**
    *-------------------------------------------------------------------------------
    * @description get picklist values for stage
    *--------------------------------------------------------------------------------
    * @author javier.soto.carrascosa@bbva.com
    * @date 22/10/2019
    * @param  void
    * @return static List<Map<string,string>> of picklist values and label
    * @example public static List<Map<string,string>> getStagePicklist()
    **/
  @AuraEnabled
  public static List<Map<String,String>> getStagePicklist() {
    List<Map<String,String>> resp = new List<Map<String,String>>();
    try {
      resp = arce.Arc_Gen_GenericUtilities.getPicklistValuesLabels('arce__Analysis__c','arce__stage_collective_type__c');
    } catch (Exception e) {
        throw new AuraHandledException(System.Label.Arc_Gen_ApexCallError+e);
    }
    return resp;
  }
    /**
    *-------------------------------------------------------------------------------
    * @description update stage
    *--------------------------------------------------------------------------------
    * @author luisarturo.parra.contractor@bbva.com | 5/7/2019
    * @date 5/10/2019
    * @param  List < arce__Analysis__c > stageObjectToUpdate list of arces to update
    * @return void
    * @example public static void updateStagesetDataCtrl(List < arce__Analysis__c > stageObjectToUpdate)
    **/
  @AuraEnabled
  public static void updateStagesetDataCtrl(Id accHasAnalysisId, string stage) {
    Arc_Gen_ProposeInSanction_Service.editPermissionCheck(accHasAnalysisId);
    try {
      final arce__Analysis__c arceVar = arce.Arc_Gen_ArceAnalysis_Data.gerArce(accHasAnalysisId);
      Arc_Gen_ProposeInSanction_Service.updateStageSetStage(arceVar.Id, stage);
    } catch (Exception e) {
        throw new AuraHandledException(System.Label.Arc_Gen_ApexCallError+e);
    }
  }
  /**
  *-------------------------------------------------------------------------------
  * @description get ambit options
  *--------------------------------------------------------------------------------
  * @author luisarturo.parra.contractor@bbva.com | 5/7/2019
  * @date 5/10/2019
  * @param  List < arce__Analysis__c > stageObjectToUpdate List to get the current ambit
  * @return List < String > ambitList list of ambits
  * @example public static List < String > getAmbitCtrl(List < arce__Analysis__c > stageObjectToUpdate)
  **/
  @AuraEnabled
  public static List<Map<string,string>> getAmbitCtrl() {
    List<Map<string,string>> resp = new List<Map<string,string>>();
    try {
      resp = arce.Arc_Gen_GenericUtilities.getPicklistValuesLabels('arce__Analysis__c','arce__anlys_wkfl_edit_br_level_type__c');
    } catch (Exception e) {
        throw new AuraHandledException(System.Label.Arc_Gen_ApexCallError+e);
    }
    return resp;
  }
  /**
  *-------------------------------------------------------------------------------
  * @description update ambit selection
  --------------------------------------------------------------------------------
  * @author luisarturo.parra.contractor@bbva.com | 5/7/2019
  * @date 5/10/2019
  * @param  String ambit new ambit to propose
  * @param  String recordId to set the new ambit to
  * @return none
  * @example public static void setAmbitCtrl(String ambit, String recordId)
  **/
  @AuraEnabled
  public static String setAmbitCtrl(String ambit, Id accHasAnalysisId, Object wrapper) {
    Arc_Gen_ProposeInSanction_Service.editPermissionCheck(accHasAnalysisId);
    try {
      final Arc_Gen_Delegation_Wrapper wrapperSerialize = (Arc_Gen_Delegation_Wrapper) JSON.deserialize((String) wrapper, Arc_Gen_Delegation_Wrapper.class);
      final Arc_Gen_Delegation_Wrapper wrapperReturn = Arc_Gen_ProposeInSanction_Service.setAmbitService(ambit, accHasAnalysisId, wrapperSerialize);
      Arc_Gen_AuditedValues_service.checkAction(wrapperReturn.analysisId, 'propose');
      return JSON.serialize(wrapperReturn);
    } catch (Exception e) {
        throw new AuraHandledException(System.Label.Arc_Gen_ApexCallError + e);
    }
  }
    /**
    *-------------------------------------------------------------------------------
    * @description Calls a function that validate rating of customer.
    *--------------------------------------------------------------------------------
    * @date   28/06/2019
    * @author ismaelyovani.obregon.contractor@bbva.com
    * @param  recordId - account_has_analysis Id
    * @return Boolean resp validates the current rating of the arce
    * @example  public static Boolean validateRatingInSanction(Id arceId)
    */
    @AuraEnabled
    public static Boolean validateRatingInSanction(Id accHasAnalysisId) {
      Arc_Gen_ProposeInSanction_Service.editPermissionCheck(accHasAnalysisId);
      Boolean resp = true;
      final arce__Analysis__c arceVar = arce.Arc_Gen_ArceAnalysis_Data.gerArce(accHasAnalysisId);
      resp = Arc_Gen_ProposeInPreparation_Service.validateAllRatingsInArce(arceVar.Id);
      return resp;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Calls a function that retrieves the modeo of the component.   // DESUSO
    *--------------------------------------------------------------------------------
    * @date   21/10/2019
    * @author Javier.soto.carrascosa@bbva.com
    * @param  no params
    * @return Boolean resp true: mode light, false: full mode
    * @example  public static Boolean validateRatingInSanction()
    */
    @AuraEnabled
    public static Boolean retrieveComponentMode() {
        Boolean resp = true;
        try {
          resp = Boolean.valueOf(arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo('ProposeInSanctLite')[0].arce__Value1__c);
        } catch (Exception e) {
            throw new AuraHandledException(System.Label.Arc_Gen_ApexCallError+e);
        }
        return resp;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description initDelegation
    *--------------------------------------------------------------------------------
    * @date   09/01/2020
    * @author juanignacio.hita.contractor@bbva.com
    * @param  String : ambit
    * @param  Id : accHasId
    * @param  String : action
    * @return String
    * @example  String res = initDelegation(ambit, accHasId, action)
    */
    @AuraEnabled
    public static String initDelegation(Id accHasAnalysisId) {
      Arc_Gen_ProposeInSanction_Service.editPermissionCheck(accHasAnalysisId);
      try {
        final arce__Analysis__c arceVar = arce.Arc_Gen_ArceAnalysis_Data.gerArce(accHasAnalysisId);
        final arce.Arc_Gen_User_Wrapper wrpUser = arce.Arc_Gen_User_Locator.getUserInfo(System.UserInfo.getUserId());
        final Arc_Gen_Delegation_Wrapper wrapper = Arc_Gen_Propose_Helper.initDelegation(wrpUser.ambitUser, arceVar.Id, 'PROPOSE',false);
        return JSON.serialize(wrapper);
      } catch (Exception e) {
          throw new AuraHandledException(System.Label.Arc_Gen_ApexCallError+e);
      }
    }
    /**
    *-------------------------------------------------------------------------------
    * @description updateSnctnType
    *--------------------------------------------------------------------------------
    * @date   09/01/2020
    * @author juanignacio.hita.contractor@bbva.com
    * @param  Object : wrapper
    * @return void
    * @example updateSnctnType(wrapper);
    */
    @AuraEnabled
    public static void updateSnctnType(Object wrapper) {
      try {
        final Arc_Gen_Delegation_Wrapper wrapperSerialize = (Arc_Gen_Delegation_Wrapper) JSON.deserialize((String) wrapper, Arc_Gen_Delegation_Wrapper.class);
        Arc_Gen_Propose_Helper.updateSnctnType(wrapperSerialize);
      } catch (Exception e) {
        throw new AuraHandledException(System.Label.Arc_Gen_ApexCallError + e);
      }
    }
    /**
    *-------------------------------------------------------------------------------
    * @description evaluateDelegation
    *--------------------------------------------------------------------------------
    * @date   09/01/2020
    * @author juanignacio.hita.contractor@bbva.com
    * @param  Object : wrapper
    * @param  Id : accHasAnalysisId
    * @return String
    * @example  String res = evaluateDelegation(wrapper, accHasAnalysisId);
    */
    @AuraEnabled
    public static String evaluateDelegation(Object wrapper, Id accHasAnalysisId){
      Arc_Gen_ProposeInSanction_Service.editPermissionCheck(accHasAnalysisId);
      try {
        final Arc_Gen_Delegation_Wrapper wrapperSerialize = (Arc_Gen_Delegation_Wrapper) JSON.deserialize((String) wrapper, Arc_Gen_Delegation_Wrapper.class);
        final Arc_Gen_Delegation_Wrapper wrapperRet = Arc_Gen_Propose_Helper.evaluateDelegation(wrapperSerialize, accHasAnalysisId, 'SANCTION');
        return JSON.serialize(wrapperRet);
      } catch (Exception e) {
        throw new AuraHandledException(System.Label.Arc_Gen_ApexCallError + e);
      }
    }
    /**
    *-------------------------------------------------------------------------------
    * @description initModeCmp
    *--------------------------------------------------------------------------------
    * @date   20/01/2020
    * @author juanignacio.hita.contractor@bbva.com
    * @param  Object : wrapper
    * @param  Id : accHasAnalysisId
    * @return String
    * @example  String res = initModeCmp(wrapper, accHasAnalysisId);
    */
    @AuraEnabled
    public static Boolean initModeCmp() {
      try {
        return Boolean.valueOf(arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo('ProposeInSanctLite')[0].arce__Value1__c);
      } catch (Exception e) {
        throw new AuraHandledException(System.Label.Arc_Gen_ApexCallError + e);
      }
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Invokes the actions services for persist the propose action
    *--------------------------------------------------------------------------------
    * @date   19/07/2021
    * @author juanignacio.hita.contractor@bbva.com
    * @param  Object wrapper
    * @param  accHasAnalysisId : id of the account has analysis related with the analysis
    * @return returns String serialize wrapper
    * @example String str = persistArceAction(wrapper, accHasAnalysisId);
    */
    @AuraEnabled
    public static String persistArceAction(Object wrapper, Id accHasAnalysisId) {
        try {
            final Arc_Gen_Delegation_Wrapper wrapperSerialize = (Arc_Gen_Delegation_Wrapper) JSON.deserialize((String) wrapper, Arc_Gen_Delegation_Wrapper.class);
            arce.Arc_Gen_ActionsPersistence_Service.persistArceAction(wrapperSerialize.analysisId, arce.Arc_Gen_ActionsPersistence_Service.ACTION_PROPOSE);
            return JSON.serialize(wrapperSerialize);
        } catch (Exception e) {
            throw new AuraHandledException(System.Label.Arc_Gen_ApexCallError + e);
        }
    }

}