/**
* ────────────────────────────────────────────────────────────────────
* CucoFormalizationErrorsController
* Controller class for CucoFormalizationErrors.cmp Lightning Component
* ────────────────────────────────────────────────────────────────────
* @author      CuCo CIB <globalhub_components.group@bbva.com>
* @modifiedBy
* @version     1.0
* @created     July 2021
* @modified
* @systemLayer Presentation
* ────────────────────────────────────────────────────────────────────
* @changes
*
* ────────────────────────────────────────────────────────────────────
*/
public with sharing class CucoFormalizationErrorsController {

    /**
	* SINGLETON PATTERN
	*/
    private static CucoFormalizationErrorsController instance;

    /**
	* Constructor
	*/
    private CucoFormalizationErrorsController() {
    }

    /**
	* getInstance
	*/
    public static CucoFormalizationErrorsController gtInstance() {
        if(instance == null) {
            instance = new CucoFormalizationErrorsController();
        }
        return instance;
    }

    /**
    * @description Returns the cuco__profitability_sheet_error__c info to show on table
    * @param recordId : Id of the context record
    * @return List<cuco__profitability_sheet_error__c>, with table info
    */
    @AuraEnabled
    public static List<cuco__profitability_sheet_error__c> getErrors(Id recordId) {
        try {
            final cuco__profitability_analysis__c analysis = [SELECT Id,cuco__gf_profitability_sheet_id__c,cuco__gf_pa_management_type_name__c FROM cuco__profitability_analysis__c WHERE Id =: recordId AND cuco__gf_profitability_sheet_id__c != NULL AND cuco__gf_pa_management_type_name__c = 'Novation' WITH SECURITY_ENFORCED LIMIT 1]; //NOSONAR
            List<cuco__profitability_sheet_error__c> errorList = new List<cuco__profitability_sheet_error__c> ();
            if (analysis != null) {
                errorList = [SELECT Id, cuco__gf_error_code_id__c, cuco__gf_error_desc__c, Family_Code__c FROM cuco__profitability_sheet_error__c WHERE cuco__gf_profitability_sheet_id__c =: analysis.cuco__gf_profitability_sheet_id__c AND Fixed__c = FALSE WITH SECURITY_ENFORCED];
            }
            return errorList;
        } catch(Exception e) {
            throw new AuraHandledException(System.Label.Basic_error_handling + ' ' + e.getMessage()); // NOSONAR
        }
    }

    /**
    * @description Create an Action Audit to leave traces that the user has said he has solved the error (logical deletion).
    * @param error : cuco__profitability_sheet_error__c
    * @param recordId : Id of the context record
    */
    @AuraEnabled
    public static void deleteErrors(cuco__profitability_sheet_error__c error, Id recordId) {
        if(error != null && Schema.sObjectType.cuco__profitability_sheet_error__c.fields.Fixed__c.isUpdateable()) {
            error.Fixed__c = true;
            update error;
        }
        if (Schema.sObjectType.dwp_cvad__Action_Audit__c.isCreateable() && Schema.sObjectType.dwp_cvad__Action_Audit_Detail__c.isCreateable()) {
            final dwp_cvad__Action_Audit__c event = createActionAudit(error, recordId);
            insert event;
            final dwp_cvad__Action_Audit_Detail__c eventDetail = createActionAuditDetail(error, event.Id);
            insert eventDetail;
        }
    }

    /**
    * @description Data for dwp_cvad__Action_Audit__c
    * @param error : cuco__profitability_sheet_error__c
    * @param recordId : Id of the context record
    * @return dwp_cvad__Action_Audit__c detail
    */
    public static dwp_cvad__Action_Audit__c createActionAudit(cuco__profitability_sheet_error__c error, Id recordId) {
        return new dwp_cvad__Action_Audit__c(
            dwp_cvad__action_audit_date__c = Datetime.now(),
            dwp_cvad__action_audit_object_api_name__c = 'cuco__profitability_analysis__c',
            dwp_cvad__action_audit_record_id__c = recordId,
            dwp_cvad__action_audit_style__c = 'delete',
            dwp_cvad__action_audit_type__c = 'ProfitabilityAnalysis',
            dwp_cvad__action_audit_name__c = System.Label.Error_deleted + ' ' + error.Family_Code__c,
            dwp_cvad__action_audit_user_id__c = UserInfo.getUserId()
        );
    }

    /**
    * @description Data for dwp_cvad__Action_Audit_Detail__c
    * @param error : cuco__profitability_sheet_error__c
    * @param actionAuditId : Parent Id
    * @return dwp_cvad__Action_Audit_Detail__c detail
    */
    public static dwp_cvad__Action_Audit_Detail__c createActionAuditDetail(cuco__profitability_sheet_error__c error, Id actionAuditId) {
        return new dwp_cvad__Action_Audit_Detail__c(
            dwp_cvad__action_audit_detail_content_format__c = 'HTML',
            dwp_cvad__action_audit_detail_display_order__c = 1,
            dwp_cvad__action_audit_detail_display_type__c = 'Embedded',
            dwp_cvad__action_audit_detail_content__c = System.Label.Error_description + ' ' + error.cuco__gf_error_desc__c,
            dwp_cvad__action_audit_id__c = actionAuditId
        );
    }

}