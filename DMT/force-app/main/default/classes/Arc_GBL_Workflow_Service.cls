/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_Delegation
* @Author   Juan Ignacio Hita Manso juanignacio.hita.contractor@bbva.com
* @Date     Created: 2020-01-07
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Implements of local class workflow that implements Arc_Gen_Workflow_Interface
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2020-01-07 juanignacio.hita.contractor@bbva.com
*             Class creation.
* |2020-03-31 juanignacio.hita.contractor@bbva.com
*             Added RAIP propose action
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2020-05-13 otiliaramona.veres.contractor.capacitacion@bbva.com
*             Fixed excessively long variable names of RAIPPROPOSE_STATUS to RAIPPRO_STATUS
* -----------------------------------------------------------------------------------------------
*/
public class Arc_GBL_Workflow_Service implements Arc_Gen_Workflow_Interface {
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
    * @author juanignacio.hita.contractor@bbva.com
    * @date   09/01/2020
    * @param  String : ambit
    * @param  Id : analysisId
    * @param  String : action
    * @return Arc_Gen_Delegation_Wrapper
    * @example Arc_Gen_Delegation_Wrapper wrapper = getDelegation(ambit, analysisId, action);
    **/
    public Arc_Gen_Delegation_Wrapper getDelegation(String ambit, Id analysisId, String action, Boolean validate) {
        Arc_Gen_Delegation_Wrapper wrapper = new Arc_Gen_Delegation_Wrapper();
        wrapper.analysisId = analysisId;
        wrapper.ambit = ambit;

        if (action == SCHEDULE_STATUS) {
            wrapper = Arc_GBL_Workflow_Helper.scheduleAction(wrapper);
        } else if (action == PROPOSE_STATUS) {
            wrapper = Arc_GBL_Workflow_Helper.proposeAction(wrapper);
        } else if (action == RETURN_STATUS) {
            wrapper = Arc_GBL_Workflow_Helper.returnAction(wrapper);
        } else if (action == SANCTION_STATUS) {
            wrapper = Arc_GBL_Workflow_Helper.sanctionAction(wrapper);
        } else if (action == RAIPPRO_STATUS) {
            wrapper = Arc_GBL_Workflow_Helper.proposeRAIPAction(wrapper);
        } else {
            final arce.Arc_Gen_CustomServiceMessages serviceMessage = new arce.Arc_Gen_CustomServiceMessages();
            wrapper.codStatus = serviceMessage.CODE_500;
            wrapper.msgInfo = 'Action not found, please review lightning component configuration';
        }
        return wrapper;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description  getIdentification : method that get the identification of the user from ambit and account has analysis
    --------------------------------------------------------------------------------
    * @author juanignacio.hita.contractor@bbva.com
    * @date   09/01/2020
    * @param  String : ambit
    * @param  Id : accHasAnalysisId
    * @return String
    * @example String identification = getIdentification(ambit, accHasAnalysisId);
    **/
    public String getIdentification(String ambit, Id analysisId) {
        return UserInfo.getUserId();
    }
}