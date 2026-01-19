/**
* ------------------------------------------------------------------------------------------------
* @Name     DES_Arc_GBL_Workflow_Service
* -----------------------------------------------------------------------------------------------
* @Description Class "DES_Arc_GBL_Workflow_Service"
* -----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('sf:AvoidGlobalModifier, sf:UseSingleton')
global with sharing class DES_Arc_GBL_Workflow_Service  implements Arc_Gen_Workflow_Interface {

    /**
    * @Description : Variable status schedule action workflow delegation
    */
    static final String SCHEDULE_STATUS = 'SCHEDULE';
    /**
    * @Description : Variable status propose action workflow delegation
    */
    static final String PROPOSE_STATUS = 'PROPOSE';
    /**
    * @Description : Variable status propose action workflow delegation
    */
    static final String RETURN_STATUS = 'RETURN';
    /**
    * @Description : Variable status propose action workflow delegation
    */
    static final String SANCTION_STATUS = 'SANCTION';
    /**
    * @Description : Variable status propose raip action
    */
    static final String RAIPPRO_STATUS = 'RAIP-PROPOSE';

    /**
    *-------------------------------------------------------------------------------
    * @description  getDelegation : method that execute an action of the workflow and return wrapper with data analysis arce
    --------------------------------------------------------------------------------
    * @author Global Desktop
    * @date   11/03/2020
    * @param  String : ambit
    * @param  Id : analysisId
    * @param  String : action
    * @return Arc_Gen_Delegation_Wrapper
    * @example Arc_Gen_Delegation_Wrapper wrapper = getDelegation(ambit, analysisId, action);
    **/
    public static Arc_Gen_Delegation_Wrapper getDelegation(String ambit, Id analysisId, String action, Boolean validate) {
        Arc_Gen_Delegation_Wrapper wrapper = new Arc_Gen_Delegation_Wrapper();
        final arce.Arc_Gen_CustomServiceMessages serviceMessage = new arce.Arc_Gen_CustomServiceMessages();

        wrapper.analysisId = analysisId;
        wrapper.ambit = ambit;
        wrapper.validate = validate;

        if (action == SCHEDULE_STATUS) {
            wrapper = Arc_GBL_Workflow_Helper.scheduleAction(wrapper);
        } else if (action == PROPOSE_STATUS) {
            wrapper = Arc_GBL_Workflow_Helper.proposeAction(wrapper);
        } else if (action == RETURN_STATUS) {
            wrapper = DES_Arc_GBL_Workflow_Helper.returnAction(wrapper);
        } else if (action == SANCTION_STATUS) {
            wrapper = Arc_GBL_Workflow_Helper.sanctionAction(wrapper);
        } else if (action == RAIPPRO_STATUS) {
            wrapper = DES_Arc_GBL_Workflow_Helper.proposeRAIPAction(wrapper);
        } else {
            wrapper.codStatus = serviceMessage.CODE_500;
            wrapper.msgInfo = 'Action not found, please review lightning component configuration';
        }
        return wrapper;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description  getIdentification : method that get the identification of the user from ambit and account has analysis
    --------------------------------------------------------------------------------
    * @author Global Desktop
    * @date   11/03/2020
    * @param  String : ambit
    * @param  Id : accHasAnalysisId
    * @return String
    * @example String identification = getIdentification(ambit, accHasAnalysisId);
    **/
    public static String getIdentification(String ambit, Id analysisId) {
        return UserInfo.getUserId();
    }
}