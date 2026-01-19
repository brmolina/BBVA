/**
* ────────────────────────────────────────────────────────────────────
* Profitability Analysis Trigger Handler
*
* ────────────────────────────────────────────────────────────────────
* @author      Torcuato tejada <torcuato.tejada.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2021-07-09
* @modified
* @systemLayer Trigger
* ────────────────────────────────────────────────────────────────────
* @changes
*
* ────────────────────────────────────────────────────────────────────
*/
@SuppressWarnings('sf:TooManyMethods')
public with sharing class ProfitabilityAnalysisTriggerHandler {

    private static ProfitabilityAnalysisTriggerHandler instance;

    public static ProfitabilityAnalysisTriggerHandler getInstance() {
        if (instance == null) {
            instance = new ProfitabilityAnalysisTriggerHandler();
        }
        return instance;
    }

    private Map<Id, String> profSheet2Branch(Set<Id> profSheetIds) {
        Map<Id, String> res = new Map<Id, String>();
        List<cuco__profitability_sheet__c> profSheets = [SELECT Id, gf_branch_id__c FROM cuco__profitability_sheet__c WHERE Id IN :profSheetIds];
        for (cuco__profitability_sheet__c profSheet : ProfSheets) {
            if (!String.isEmpty(profSheet.gf_branch_id__c)) {
                res.put(profSheet.Id, profSheet.gf_branch_id__c);
            }
        }
        return res;
    }

    private Map<Id, String> account2Branch(Set<Id> accountIds) {
        Map<Id, String> res = new Map<Id, String>();
        List<Account> accounts = [SELECT Id, gf_branch_id__c FROM Account WHERE Id IN :accountIds LIMIT 1];
        for (Account acc : accounts) {
            if (String.isEmpty(acc.gf_branch_id__c)) {
                res.put(acc.Id, acc.gf_branch_id__c);
            }
        }
        return res;
    }

    /**
    * @description set prof analysis Branch Id from related Profitability Sheet
    *   If empty, set Branch Id from Account
    *   If empty, set default branch id value
    * @param pAnalysis : Set Id cuco__profitability_analysis__c
    * @param profSheet2Branch : map prof_sheet_id Id to branch_id
    * @param account2Branch : map account_id to branch_id
    * @return nothing
    */
    private void setProfitabilityAnalysisBranch(cuco__profitability_analysis__c pAnalysis, Map<Id, String> profSheet2Branch, Map<Id, String> account2Branch) {

        String branch = '';

        if (String.isEmpty(pAnalysis.gf_branch_id__c) && !String.isEmpty(pAnalysis.cuco__gf_profitability_sheet_id__c) && !profSheet2Branch.containsKey(pAnalysis.cuco__gf_profitability_sheet_id__c)) {
            branch = profSheet2Branch.get(pAnalysis.cuco__gf_profitability_sheet_id__c);
        }

        // If still empty, get Branch Id from Account
        if (String.isEmpty(pAnalysis.gf_branch_id__c) && String.isEmpty(branch) && account2Branch.containsKey(pAnalysis.cuco__participant_id__c)) {
            branch = account2Branch.get(pAnalysis.cuco__participant_id__c);
        }

        if (String.isEmpty(pAnalysis.gf_branch_id__c) && String.isEmpty(branch)) {
            Schema.DescribeFieldResult fieldResults = cuco__profitability_analysis__c.gf_branch_id__c.getDescribe();
            List <Schema.PicklistEntry> pickVals = fieldResults.getPicklistValues();
            branch = pickVals[0].getValue();
        }

        pAnalysis.gf_branch_id__c = branch;
    }

    public void beforeInsert(List<cuco__profitability_analysis__c> triggerNew) {

        Set<Id> profSheetIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();

        for (cuco__profitability_analysis__c profAnalysis : triggerNew) {
            if (!String.isEmpty(profAnalysis.cuco__gf_profitability_sheet_id__c)) {
                profSheetIds.add(profAnalysis.cuco__gf_profitability_sheet_id__c);
            }
            if (!String.isEmpty(profAnalysis.cuco__participant_id__c)) {
                accountIds.add(profAnalysis.cuco__participant_id__c);
            }
            if (String.isBlank(profAnalysis.cuco__gf_pa_management_type_name__c)) {
                profAnalysis.cuco__gf_pa_management_type_name__c = 'New';
            }
        }

        Map<Id, String> profSheet2Branch = profSheet2Branch(profSheetIds);
        Map<Id, String> account2Branch = account2Branch(accountIds);

        for (cuco__profitability_analysis__c pAnalysis : triggerNew) {
            setProfitabilityAnalysisBranch(pAnalysis, profSheet2Branch, account2Branch);
        }
    }

    /**
    * @description method: Update the associated cuco__profitability_sheet__c (Notified__c=false)
    * and delete the associated cuco__profitability_sheet_error__c records.
    */
    public void afterUpdate(List<cuco__profitability_analysis__c> triggerNew) {
        Set<Id> idPA = new Set<Id>();
        List<cuco__profitability_sheet_error__c> errorList = new List<cuco__profitability_sheet_error__c> ();
        for (cuco__profitability_analysis__c pAnalysis : triggerNew) {
            if((pAnalysis.cuco__gf_pa_mgmt_stage_type_name__c == 'Formalized' || pAnalysis.cuco__gf_pa_mgmt_status_type_name__c == 'Sent for Formalization') && pAnalysis.cuco__gf_pa_management_type_name__c == 'Novation'
            && pAnalysis.cuco__gf_profitability_sheet_id__c != NULL){
                idPA.add(pAnalysis.cuco__gf_profitability_sheet_id__c);
            }
        }
        if (!idPA.isEmpty()){
            errorList = getErrors(idPA);
        }
        if (!errorList.isEmpty()){
            deleteErrors(errorList);
            updateConditions(idPA);
        }
    }

    /**
    * @description method: Select cuco__profitability_sheet_error__c
    * @param idPA : Set Id cuco__profitability_analysis__c
    * @return cuco__profitability_sheet_error__c list IN idPA
    */
    public static List <cuco__profitability_sheet_error__c> getErrors(Set<Id> idPA) {
        List<cuco__profitability_sheet_error__c> errorList = new List<cuco__profitability_sheet_error__c> ();
        errorList = [SELECT Id FROM cuco__profitability_sheet_error__c WHERE cuco__gf_profitability_sheet_id__c IN : idPA WITH SECURITY_ENFORCED];
        return errorList;
    }

    /**
    * @description method: Update the associated cuco__profitability_sheet__c (Notified__c=false)
    * @param idPA : Set Id cuco__profitability_analysis__c
    */
    public void updateConditions(Set<Id> idPA) {
        List<cuco__profitability_sheet__c> booklist = new List<cuco__profitability_sheet__c> ();
        List<cuco__profitability_sheet__c> booklistupdate = new List<cuco__profitability_sheet__c> ();
        booklist = [SELECT Id,Notified__c FROM cuco__profitability_sheet__c WHERE Id IN : idPA WITH SECURITY_ENFORCED];
        for(cuco__profitability_sheet__c book: booklist) {
            book.Notified__c = false;
            booklistupdate.add(book);
        }
        if (!booklistupdate.isEmpty() && Schema.sObjectType.cuco__profitability_sheet__c.isUpdateable()){
            update booklistupdate;
        }
    }

    /**
    * @description method: Delete the associated cuco__profitability_sheet_error__c
    * @param errorList : list cuco__profitability_sheet_error__c to delete
    */
    public static void deleteErrors(List<cuco__profitability_sheet_error__c> errorList) {
        if (!errorList.isEmpty() && Schema.sObjectType.cuco__profitability_sheet_error__c.isDeletable()){
            delete errorList;
        }
    }

    /**
    * @description method: Insert the associated dwp_cvad__Action_Audit__c/dwp_cvad__Action_Audit_Detail__c records
    */
    public void afterInsert(List<cuco__profitability_analysis__c> triggerNew) {
        List<dwp_cvad__Action_Audit__c> createAuditList = new List<dwp_cvad__Action_Audit__c>();
        for (cuco__profitability_analysis__c pAnalysis : triggerNew) {

            
            /* if (String.isBlank(pAnalysis.cuco__gf_pa_management_type_name__c)) {
                pAnalysis.cuco__gf_pa_management_type_name__c = 'New';
            } */
            dwp_cvad__Action_Audit__c createAudit = new dwp_cvad__Action_Audit__c();
            createAudit.dwp_cvad__action_audit_style__c = 'create';
            createAudit.dwp_cvad__action_audit_type__c = 'ProfitabilityAnalysis';
            createAudit.dwp_cvad__action_audit_object_api_name__c = 'cuco__profitability_analysis__c';
            createAudit.dwp_cvad__action_audit_record_id__c = pAnalysis.Id;
            createAudit.dwp_cvad__action_audit_date__c = DateTime.now();
            createAudit.dwp_cvad__action_audit_name__c = Label.cuco_pa_creationaudit_request.replace('%TYPOLOGY%',pAnalysis.cuco__gf_pa_management_type_name__c);
            createAudit.dwp_cvad__action_audit_user_id__c = UserInfo.getUserId();
            createAuditList.add(createAudit);
        }
        insert createAuditList;
        List<dwp_cvad__Action_Audit_Detail__c> createAuditDetailList = new List<dwp_cvad__Action_Audit_Detail__c>();
        for (dwp_cvad__Action_Audit__c createAudit : createAuditList) {
            dwp_cvad__Action_Audit_Detail__c createAuditDetail = new dwp_cvad__Action_Audit_Detail__c();
            createAuditDetail.dwp_cvad__action_audit_detail_content_format__c = 'HTML';
            createAuditDetail.dwp_cvad__action_audit_detail_display_order__c = 1;
            createAuditDetail.dwp_cvad__action_audit_detail_display_type__c = 'Embedded';
            createAuditDetail.dwp_cvad__action_audit_detail_content__c = label.cuco_pa_creationaudit_request_detail;
            createAuditDetail.dwp_cvad__action_audit_id__c = createAudit.Id;
            createAuditDetailList.add(createAuditDetail);
        }
        insert createAuditDetailList;
    }
}