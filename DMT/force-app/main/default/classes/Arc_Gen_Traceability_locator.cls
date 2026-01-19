/**
* @File Name          : Arc_Gen_Traceability_locator
* @Description        : Locator class for get traceability objects
* @Author             : juanignacio.hita.contractor@bbva.com
* @Group              : ARCE
* @Last Modified By   : juanignacio.hita.contractor@bbva.com
* @Last Modified On   : 08/06/2020 12:00:00
* @Changes
*==============================================================================
* Ver         Date                     Author      		      Modification
*==============================================================================
* 1.0    08/06/2020 12:00:00   juanignacio.hita.contractor@bbva.com      Initial Version
**/
public without sharing class Arc_Gen_Traceability_locator {
    /**
    *-------------------------------------------------------------------------------
    * @description builder to avoid error in sonar
    *-------------------------------------------------------------------------------
    * @author      juanignacio.hita.contractor@bbva.com
    * @date        08/06/2020
    * @method      Arc_Gen_Traceability_locator
    * @return      nothing.
    * @example     Arc_Gen_Traceability_locator().
    */
    private Arc_Gen_Traceability_locator() {
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method to get a record traceability of a button type related with an analysis
    *-------------------------------------------------------------------------------
    * @author      juanignacio.hita.contractor@bbva.com
    * @date        08/06/2010
    * @Method      getActionAuditBtn
    * @param       recordId : record id analysis
    * @param       actionBtn : name of the button action
    * @return      List<dwp_cvad__Action_Audit__c>
    * @example     List<dwp_cvad__Action_Audit__c> lstDwp = Arc_Gen_Traceability_locator.getActionAuditBtn(actionBtn);
    */
    public static List<dwp_cvad__Action_Audit__c> getActionAuditBtn(String recordId, String actionBtn) {
        final List<String> lstStatus = new List<String> {
            arce.Arc_Gen_Constants.STATUS_PREPARING_ANALYSIS,
            arce.Arc_Gen_Constants.STATUS_ARCE_PREPARED,
            arce.Arc_Gen_Constants.STATUS_CONTRASTING_ANALYSIS,
            arce.Arc_Gen_Constants.STATUS_SCHEDULECOMMITTEEWDELEGATION,
            arce.Arc_Gen_Constants.STATUS_DECIDINGCOMMITTEEWDELEGATION,
            arce.Arc_Gen_Constants.STATUS_SCHEDULECOMMITTEE,
            arce.Arc_Gen_Constants.STATUS_SANCTIONCOMMITTEE,
            arce.Arc_Gen_Constants.STATUS_PREPARINGANALYSIS,
            arce.Arc_Gen_Constants.STATUS_FINALIZEDANALYSIS
        };
        return [SELECT Id, anlys_wkfl_status_stage_type__c, button_unique_id__c, anlys_wkfl_edit_br_level_type__c FROM dwp_cvad__Action_Audit__c WHERE button_unique_id__c =:actionBtn AND anlys_wkfl_status_stage_type__c IN :lstStatus AND dwp_cvad__action_audit_record_id__c =:recordId];
    }
}