/**
* @File Name          : Arc_Gen_ProposeInPreparation_controller.cls
* @Description        : Refactorizacion
* @Author             : luisarturo.parra.contractor@bbva.com
* @Group              : ARCE
* @Last Modified By   : Global Desktop
* @Last Modified On   : 23-02-2022
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |21/11/2019 luisarturo.parra.contractor@bbva.com
*             Class creation. /Refactorizacion
* |18/12/2019 manuelhugo.castillo.contractor@bbva.com
*             Modify method 'getahas' replace arce__Account_has_Analysis__c to arce.Arc_Gen_Account_Has_Analysis_Wrapper
* |2020-01-24 luisruben.quinto.munoz@bbva.com
*             Change to without sharing
* |2020-07-13 joseluis.garcia4.contractor@bbva.com
*             Check for edit permissions.
* |2020-08-18 joseluis.garcia4.contractor@bbva.com
*             Change reference from Arc_Gen_StatusButtons to arce.Arc_Gen_GenericUtilities.
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2021-04-30 otiliaramona.veres.contractor@bbva.com
* 			  Added an empty constructor method.
* |2021-05-04 otiliaramona.veres.contractor@bbva.com
* 			  Added annotation '@testVisible' to the empty constructor method.
* |2021-07-15 juanignacio.hita.contractor@bbva.com
*             Creates persistArceAction method that invokes actions service
* -----------------------------------------------------------------------------------------------
**/
public without sharing class Arc_Gen_ProposeInPreparation_controller {
    /**
    *-------------------------------------------------------------------------------
    * @description Empty constructor method
    *-------------------------------------------------------------------------------
    *@author otiliaramona.veres.contractor@bbva.com
    * @Date   Created:2021-04-30
    * @param void
    * @return void
    * @example Arc_Gen_ProposeInPreparation_controller controller = new Arc_Gen_ProposeInPreparation_controller()
    */
    @TestVisible
    private Arc_Gen_ProposeInPreparation_controller() { }
    /**
    *-------------------------------------------------------------------------------
    * @description function that validate if the customer has a valid rating.
    *--------------------------------------------------------------------------------
    * @date		28/06/2019
    * @author	ismaelyovani.obregon.contractor@bbva.com
    * @param	recordId - account_has_analysis Id
    * @return	Boolean resp
    * @example	public static Boolean validateRatingInPreparation(String recordId)
    */
    @AuraEnabled
    public static Boolean validateRatingInPreparation(Id accHasAnalysisId) {
        if (!arce.Arc_Gen_GenericUtilities.isButtonAvailable(accHasAnalysisId, 'Arc_Gen_ProposeInPreparation')) {
            throw new AuraHandledException(System.Label.Arc_Gen_Generic_ButtonNotAllowed);
        }

        try {
            final arce__Analysis__c arceVar = arce.Arc_Gen_ArceAnalysis_Data.gerArce(accHasAnalysisId);
            return Arc_Gen_ProposeInPreparation_service.validateAllRatingsInArce(arceVar.Id);
        } catch (Exception e) {
            throw new AuraHandledException(System.Label.Arc_Gen_ApexCallError + e);
        }
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
        if (!arce.Arc_Gen_GenericUtilities.isButtonAvailable(accHasAnalysisId, 'Arc_Gen_ProposeInPreparation')) {
            throw new AuraHandledException(System.Label.Arc_Gen_Generic_ButtonNotAllowed);
        }

        try {
            final arce__Analysis__c arceVar = arce.Arc_Gen_ArceAnalysis_Data.gerArce(accHasAnalysisId);
            final arce.Arc_Gen_User_Wrapper wrpUser = arce.Arc_Gen_User_Locator.getUserInfo(System.UserInfo.getUserId());
            final Arc_Gen_Delegation_Wrapper wrapper = Arc_Gen_Propose_Helper.initDelegation(wrpUser.ambitUser, arceVar.Id, 'PROPOSE',false);
            Arc_Gen_Propose_Helper.updateSnctnType(wrapper);
            return JSON.serialize(wrapper);
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
    public static String evaluateDelegation(Object wrapper, Id accHasAnalysisId) {
        try {
            final Arc_Gen_Delegation_Wrapper wrapperSerialize = (Arc_Gen_Delegation_Wrapper) JSON.deserialize((String) wrapper, Arc_Gen_Delegation_Wrapper.class);
            final Arc_Gen_Delegation_Wrapper wrapperRet = Arc_Gen_Propose_Helper.evaluateDelegation(wrapperSerialize, accHasAnalysisId, 'PREPARATION');
            return JSON.serialize(wrapperRet);
        } catch (Exception e) {
            throw new AuraHandledException(System.Label.Arc_Gen_ApexCallError + e);
        }
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Save the ambit
    *--------------------------------------------------------------------------------
    * @date 22/01/2020
    * @author juanignacio.hita.contractor@bbva.com
    * @param recordId : id of the record associated (arce__Analysis__c)
    * @param accHasAnalysisId : id of the account has analysis related with the analysis
    * @param ambit : String ambit value selected
    * @return returns list.
    * @example saveScopeOfSanction(Id recordId, String sanction)
    */
    @AuraEnabled
    public static String saveAction(Object wrapper, Id accHasAnalysisId, String ambit) {
        try {
            final Arc_Gen_Delegation_Wrapper wrapperSerialize = (Arc_Gen_Delegation_Wrapper) JSON.deserialize((String) wrapper, Arc_Gen_Delegation_Wrapper.class);
            final Arc_Gen_Delegation_Wrapper wrapperRet = Arc_Gen_ProposeInPreparation_service.saveAction(wrapperSerialize, accHasAnalysisId, ambit);
            Arc_Gen_AuditedValues_service.checkAction(wrapperRet.analysisId, 'propose');
            return JSON.serialize(wrapperRet);
        } catch (Exception e) {
            throw new AuraHandledException(System.Label.Arc_Gen_ApexCallError + e);
        }
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Invokes the actions services for persist the propose action
    *--------------------------------------------------------------------------------
    * @date   15/07/2021
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