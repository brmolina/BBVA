/**
* -----------------------------------------------------------------------------------------------
* @Name           Arc_IFIS_ButtonsPropose_Ctrl
* @Author         marcos.gimeno.next@bbva.com
* @Date           30-08-2023
*
* @Group          ARCE
* -----------------------------------------------------------------------------------------------
* @Description Controller class to propose IFIS rating.
* -----------------------------------------------------------------------------------------------
* @Changes
* v1.0            marcos.gimeno.next@bbva.com
* 30-08-2023      Class creation.
* ----------------------------------------------------------------------------------------------- 
**/
public with sharing class Arc_IFIS_ButtonsReturn_Ctrl {
    /**
    * -----------------------------------------------------------------------------------------------
    * @description Empty constructor.1
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     30-08-2023
    * -----------------------------------------------------------------------------------------------
    **/
    @SuppressWarnings('PMD.EmptyStatementBlock')
    @TestVisible
    private Arc_IFIS_ButtonsReturn_Ctrl() {
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @description Checks the validity of the rating and initializes the delegation.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     30-08-2023
    * @param    ahaId    arce__Analysis__c record ID
    * @return   Wrapper with delegation info
    * @example  String e = initDelegation(Id ahaId)
    * -----------------------------------------------------------------------------------------------
    **/
    @AuraEnabled
    public static String initDelegation(Id ahaId) {
        try {
            final arce__Analysis__c analysis = arce.Arc_Gen_ArceAnalysis_Data.gerArce(ahaId);
            final arce.Arc_Gen_User_Wrapper userWrap = arce.Arc_Gen_User_Locator.getUserInfo(
                System.UserInfo.getUserId()
            );
            final Arc_IFIS_Buttons_Wrp.DelegationWrapper delegationWrap = Arc_IFIS_Buttons_Helper.initDelegation(
                userWrap.ambitUser,
                analysis.Id,
                'RETURN'
            );

            return JSON.serialize(delegationWrap);
        } catch (Exception e) {
            throw new AuraHandledException(System.Label.arce.Arc_IFIS_ApexCallError + ': ' + e.getMessage());
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
    public static String evaluateIdentification(Id ahaId, Object wrapper, String reason) {
        if (!Arc_IFIS_Buttons_Helper.isButtonAvailable(ahaId, 'Arc_IFIS_BtnReturn')) {
            throw new AuraHandledException(System.Label.arce.Arc_IFIS_ButtonNotAllowed);
        }

        try {
            final Arc_IFIS_Buttons_Wrp.DelegationWrapper delegationWrap = Arc_IFIS_ButtonsReturn_Service.evaluateIdentification(
                ahaId,
                wrapper,
                reason
            );
            return JSON.serialize(delegationWrap);
        } catch (Exception e) {
            throw new AuraHandledException(System.Label.arce.Arc_IFIS_ApexCallError + ': ' + e.getMessage());
        }
    }
}