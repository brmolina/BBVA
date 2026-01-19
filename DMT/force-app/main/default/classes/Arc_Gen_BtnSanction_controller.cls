/*-------------------------------------------------------------------------------------------------------------------------------------------------
*Author:        Angel Fuertes Gomez - angel.fuertes2@bbva.com / BBVA DWP
*Project:      	ARCE - BBVA Bancomer
*Description:   Class used for the button to Sanction.
*__________________________________________________________________________________________________________________________________________________
*Version    Date           Author                               Description
*1.0        30/04/2019     Angel Fuertes Gomez                  Creation.
*1.1        03/01/2020     Mario H. Ramirez Lio                 Fix comments, added new param (typeMessage) to the wrapper WrapperBtnSanction
*1.2        04/05/2020     Juan Manuel Perez Ortiz              Add method called getAnalysisData
*1.3        13/07/2020     José Luis García Díaz                Add check for edit permissions.
*1.4        18/08/2020     José Luis García Díaz                Change reference from Arc_Gen_StatusButtons to arce.Arc_Gen_GenericUtilities.
*1.4        23/09/2020     Sai Jordana                          Added arce. namespace to all classes that are now in the arce-dependencies package
*1.5        11/11/2020     Juan Ignacio Hita Manso              Add method callPersistences
*1.6        12/01/2021     Juan Ignacio Hita Manso              Changed params of callPersistences method to build request service
*1.7        22/01/2021     Juan Ignacio Hita Manso              Set true return param callPersistences
*1.8        30/04/2021     Otilia Ramona Veres Oltean           Added an empty constructor method.
*1.9        04/05/2021     Otilia Ramona Veres Oltean           Added anotation '@testVisible' to empty constructor method.
---------------------------------------------------------------------------------------------------------------------------------------------------*/
public with sharing class Arc_Gen_BtnSanction_controller {
    /*
        @Description: Authorized without changes arce__anlys_wkfl_sanction_rslt_type__c
    */
    static final String AUTH_W_CHANGES = '1';
    /*
        @Description: Authorized with changes arce__anlys_wkfl_sanction_rslt_type__c
    */
    static final String AUTH_CHANGES = '2';
    /**
    *-------------------------------------------------------------------------------
    * @description Empty constructor method
    *-------------------------------------------------------------------------------
    *@author otiliaramona.veres.contractor@bbva.com
    *@Date   Created:2021-04-30
    */
    @TestVisible
    private Arc_Gen_BtnSanction_controller() { }
    /**
    *-------------------------------------------------------------------------------
    * @description initDelegation
    *--------------------------------------------------------------------------------
    * @date   09/01/2020
    * @author juanignacio.hita.contractor@bbva.com
    * @param  Id : accHasAnalysisId
    * @return String - JSON delegation wrapper serialized
    * @example  String res = initDelegation(ambit, accHasId, action)
    */
    @AuraEnabled
    public static String initDelegation(Id accHasAnalysisId) {
      try {
        final arce__Analysis__c arceVar = arce.Arc_Gen_ArceAnalysis_Data.gerArce(accHasAnalysisId);
        final arce.Arc_Gen_User_Wrapper wrpUser = arce.Arc_Gen_User_Locator.getUserInfo(System.UserInfo.getUserId());
        final Arc_Gen_Delegation_Wrapper wrapper = Arc_Gen_Propose_Helper.initDelegation(wrpUser.ambitUser, arceVar.Id, 'SANCTION',false);
        return JSON.serialize(wrapper);
      } catch (Exception e) {
        throw new AuraHandledException(System.Label.Arc_Gen_ApexCallError + e);
      }
    }
    /**
    * ------------------------------------------------------------------------------
    * @Description: Save the reason for the sanction
    * ------------------------------------------------------------------------------
    * @param:       Object wrapper : delegation wrapper
    * @param:       Map<string,string> data - data information for save
    * @return:      WrapperBtnSanction
    * @example String ret = saveScopeOfSanction(wrapper, data);
    * ------------------------------------------------------------------------------
    */
    @AuraEnabled
    public static String saveScopeOfSanction(Object wrapper, Map<string,string> data) {
        if (!arce.Arc_Gen_GenericUtilities.isButtonAvailable((String) data.get('recordId'), 'Arc_Gen_Sanction')) {
          throw new AuraHandledException(System.Label.Arc_Gen_Generic_ButtonNotAllowed);
        }
        try {
          final Arc_Gen_Delegation_Wrapper wrapperSerialize = (Arc_Gen_Delegation_Wrapper) JSON.deserialize((String) wrapper, Arc_Gen_Delegation_Wrapper.class);
          final Arc_Gen_Delegation_Wrapper wrapperRet = Arc_Gen_BtnSanction_service.saveScopeOfSanction(wrapperSerialize, data);
          final String avPersistType = getAuditedValuePersistType(Integer.valueOf(data.get('sanction')));
          if (avPersistType != null) {
            Arc_Gen_AuditedValues_service.checkAction(wrapperRet.analysisId, avPersistType);
          }
          return JSON.serialize(wrapperRet);
        } catch (Exception e) {
          throw new AuraHandledException(System.Label.Arc_Gen_ApexCallError + e);
        }
    }
    /**
    *-------------------------------------------------------------------------------
    * @Description: Method to search users
    *-------------------------------------------------------------------------------
    * @param:  inputTerm string to search
    * returns: List<map<String,String>>
    * @example searchUser(inputTerm)
    * ------------------------------------------------------------------------------
    */
    @AuraEnabled
    public static List<map<String,String>> searchUser(String inputTerm) {
        return Arc_Gen_BtnSanction_service.searchUser(inputTerm);
    }
    /**
    *-------------------------------------------------------------------------------
    * @Description: Method to get ARCE data
    *-------------------------------------------------------------------------------
    * @param:  String acchasid
    * returns: List<arce__analysis__c>
    * @example getAnalysisData(acchasid)
    * ------------------------------------------------------------------------------
    */
    @AuraEnabled
    public static List<arce__analysis__c> getAnalysisData(String acchasid) {
        final String arceId = arce.Arc_Gen_AccHasAnalysis_Data.getAccHasAnalysis(new List<String>{acchasid})[0].arce__analysis__c;
        final List<arce__analysis__c> arceData = arce.Arc_Gen_ArceAnalysis_Data.getArceAnalysisData(new List<String>{arceId});
        return arceData;
    }
    /*------------------------------------------------------------------------------
    * @Description Auxilar method for get id structure
    * ------------------------------------------------------------------------------
    * @param    Map<String, Object> mapObj
    * @return   Boolean
    * @example  Boolean status = callPersistences(mapObj);
    * */
    @AuraEnabled
    public static Boolean callPersistences(Map<String, Object> data) {
      final String sanctionSel = (String) data.get('sanctionSel');
      Boolean retStatus = true;
      if (sanctionSel == AUTH_W_CHANGES || sanctionSel == AUTH_CHANGES) {
        retStatus = Arc_Gen_PersistenceCopyLimits_service.callCopyLimitsService(data);
      }
      return retStatus;
    }
    /*------------------------------------------------------------------------------
    * @Description Gets the type of action for audited values persistence.
    * ------------------------------------------------------------------------------
    * @param    Integer sanctionType - Selected option in sanction dialog
    * @return   String Type of audited value persistence
    * */
    private static String getAuditedValuePersistType(Integer sanctionType) {
      String action;
      switch on sanctionType {
          when 1,2 {
              action = Arc_Gen_AuditedValues_service.ACTION_SANCTION;
          }
          when 4,6 {
              action = Arc_Gen_AuditedValues_service.ACTION_PROPOSE;
          }
          when else {
              action = null;   //NOSONAR
          }
      }
      return action;
    }
}