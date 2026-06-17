/**
* @File Name          : Arc_Gen_ReturnButton_controller.cls
* @Description        : Controller that return an ARCE to the before status.
* @Author             : eduardoefrain.hernandez.contractor@bbva.com
* @Group              : ARCE
* @Last Modified By   : Global Desktop
* @Last Modified On   : 23-02-2022
* @Changes
*==============================================================================
* Ver         Date                     Author      		      Modification
*==============================================================================
* 1.0    3/5/2019   13:14:27   eduardoefrain.hernandez.contractor@bbva.com     Initial Version
* 1.1    08/06/2020 12:00:00   juanignacio.hita.contractor@bbva.com            Moved the validations after the call to the init delegation
* 1.2    13/07/2020 12:00:00   joseluis.garcia4.contractor@bbva.com            Check for edit permissions.
* 1.3    18/08/2020 10:00:00   joseluis.garcia4.contractor@bbva.com            Change reference from Arc_Gen_StatusButtons to Arc_Gen_GenericUtilities.
* 1.4    23/09/2020     saimassimilianno.jordana.contractor@bbva.com           Added arce. namespace to all classes that are now in the arce-dependencies package
* 1.5    22/01/2021 12:00:00   juanignacio.hita.contractor@bbva.com            Changed ambit param "initIdentification" method to the first entry delegation wrapper
**/
public without sharing class Arc_Gen_ReturnButton_controller {
    /**
    *-------------------------------------------------------------------------------
    * @description Empty priavate constructor
    --------------------------------------------------------------------------------
    * @author   eduardoefrain.hernandez.contractor@bbva.com
    * @date     2019-05-13
    * @example  private Arc_Gen_ReturnButton_controller ()
    **/
    @SuppressWarnings('PMD.EmptyStatementBlock')
    @TestVisible
    private Arc_Gen_ReturnButton_controller () {
    }

    /**
    *-------------------------------------------------------------------------------
    * @description initDelegation
    *--------------------------------------------------------------------------------
    * @date     15/01/2020
    * @author   juanignacio.hita.contractor@bbva.com
    * @param    Id : accHasAnalysisId
    * @return   String
    * @example  String res = initDelegation(accHasAnalysisId)
    */
    @AuraEnabled
    public static String initDelegation(Id accHasAnalysisId) {
        final arce.Arc_Gen_CustomServiceMessages serviceMessage = new arce.Arc_Gen_CustomServiceMessages();
      try {
        final arce__Analysis__c arceVar = arce.Arc_Gen_ArceAnalysis_Data.gerArce(accHasAnalysisId);
        final arce.Arc_Gen_User_Wrapper wrpUser = arce.Arc_Gen_User_Locator.getUserInfo(System.UserInfo.getUserId());
            final Arc_Gen_Delegation_Wrapper wrapper = Arc_Gen_Propose_Helper.initDelegation(wrpUser.ambitUser, arceVar.Id, 'RETURN',false);
            if(Arc_Gen_TabSet_service.hasPermissionAmbit(accHasAnalysisId)) {
        Arc_Gen_ReturnButton_service.valAfterInitDelegation(wrapper, arceVar);
            } else {
                wrapper.codStatus = serviceMessage.CODE_500;
                wrapper.msgInfo = 'The action cannot be executed. Invalid profile.';
            }
        return JSON.serialize(wrapper);
      } catch (Exception e) {
          throw new AuraHandledException(System.Label.Arc_Gen_ApexCallError + e);
      }
    }
    /**
    *-------------------------------------------------------------------------------
    * @description initIdentification
    *--------------------------------------------------------------------------------
    * @date     15/01/2020
    * @author   juanignacio.hita.contractor@bbva.com
    * @param    Object : delegation wrapper
    * @return   String
    * @example  String res = initIdentification(wrapper)
    */
    @AuraEnabled
    public static String initIdentification(Object wrapper) {
        try {
            final Arc_Gen_Delegation_Wrapper wrapperSerialize = (Arc_Gen_Delegation_Wrapper) JSON.deserialize((String) wrapper, Arc_Gen_Delegation_Wrapper.class);
            return Arc_Gen_Propose_Helper.initIdentification(wrapperSerialize.lstAmbits[0].get('value'), wrapperSerialize.analysisId);
        } catch (Exception e) {
            throw new AuraHandledException(System.Label.Arc_Gen_ApexCallError + e);
        }
    }
    /**
    *-------------------------------------------------------------------------------
    * @description evaluateIdentification
    *--------------------------------------------------------------------------------
    * @date     15/01/2020
    * @author   juanignacio.hita.contractor@bbva.com
    * @param    Id : accHasAnalysisId
    * @param    Object : wrapper
    * @param    String : userId
    * @param    String : reason
    * @return   String : JSON serialize of the delegation wrapper
    * @example  String res = evaluateIdentification(accHasId, wrapper, userId, reason);
    */
    @AuraEnabled
    public static String evaluateIdentification(Id accHasAnalysisId, Object wrapper, String userId, String reason) {
        if (!arce.Arc_Gen_GenericUtilities.isButtonAvailable(accHasAnalysisId, 'Arc_Gen_BtnReturn') &&
            !arce.Arc_Gen_GenericUtilities.isButtonAvailable(accHasAnalysisId, 'Arc_Gen_Return_2021RTC')) {
            throw new AuraHandledException(System.Label.Arc_Gen_Generic_ButtonNotAllowed);
        }

        try {
            final Arc_Gen_Delegation_Wrapper wrapperRet = Arc_Gen_ReturnButton_service.evaluateIdentification(accHasAnalysisId, wrapper, userId, reason);
            return JSON.serialize(wrapperRet);
        } catch (Exception e) {
            throw new AuraHandledException(System.Label.Arc_Gen_ApexCallError + e);
        }
    }
}