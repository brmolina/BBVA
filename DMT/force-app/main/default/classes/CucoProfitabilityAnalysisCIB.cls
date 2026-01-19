/**
* ────────────────────────────────────────────────────────────────────
* Profitability Analysis CIB
* Implementation of the ProfitabilityAnalysis_Itf interface methods for CIB
* ────────────────────────────────────────────────────────────────────
* @author      Torcuato Tejada <torcuato.tejada.contractor@bbva.com>
* @version     1.0
* @created     2021-07-05
* @modified
* @systemLayer BusinessLogic
* ────────────────────────────────────────────────────────────────────
* @changes
* ────────────────────────────────────────────────────────────────────
*/
@SuppressWarnings('PMD.AvoidGlobalModifier, sf:TooManyMethods')
global with sharing class CucoProfitabilityAnalysisCIB implements cuco.ProfitabilityAnalysis_Itf {
    /**
    * @description method that receives the user's id and returns the Federation Identifier
    * @param userId : user Id
    * @return String
    */
    global String getUserCode(Id userId) {
        return [SELECT FederationIdentifier FROM User WHERE Id = :userId LIMIT 1].FederationIdentifier;
    }

    /*
    * @description method that receives the user's Federation id and returns the User Id
    * @param userCode : user federation id
    * @return String
    */
    global Id getUserId(String userCode) {
        return [SELECT Id FROM User WHERE FederationIdentifier = :userCode LIMIT 1].Id;
    }

    /**
    * @description method that returns the branch code
    * @param userId : user Id
    * @return String
    */
    global String getBranchCode(Id contextRecordId, String contextObject) {
        String res;
        switch on contextObject {
            when 'cuco__profitability_analysis__c' {
                res = [SELECT gf_branch_id__c FROM cuco__profitability_analysis__c WHERE Id =:contextRecordId LIMIT 1].gf_branch_id__c;
            }
            when 'cuco__profitability_sheet__c' {
                res = [SELECT gf_branch_id__c FROM cuco__profitability_sheet__c WHERE Id =:contextRecordId LIMIT 1].gf_branch_id__c;
            }
        }
        return res;
    }

    /**
    * @description method default values for creation data
    * @param profAnalysis : object profitability analysis
    * @return object profitability_analysis__c
    */

    global cuco__profitability_analysis__c setPADefaultCreationData (cuco__profitability_analysis__c profAnalysis) {
        profAnalysis.OwnerId = UserInfo.getUserId();
        return profAnalysis;
    }

    /**
    * @description method for creating a default request profitability analysis
    * @param profAnalysis : object profitability analysis
    * @param branchCode : String with branch code
    * @param userCode : String with user code
    * @return profitability_analysis__c updated record
    */

    global cuco__profitability_analysis__c setPADefaultRequestData (cuco__profitability_analysis__c profAnalysis, String branchCode, String userCode) {
        String profAnalysisName = profAnalysis.Name;
        switch on profAnalysis.cuco__gf_pa_management_type_name__c {
            when 'Renewal' {
                profAnalysisName = ('Renewal' + ' - ' + profAnalysis.Name);
            }
            when 'Novation' {
                profAnalysisName = ('Novation' + ' - ' + profAnalysis.Name);
            }
            when 'Cancellation' {
                profAnalysisName = ('Cancellation' + ' - ' + profAnalysis.Name);
            }
        }
        if (profAnalysisName.length() > 80) {
            profAnalysisName = profAnalysisName.substring(0, 80);
        }
        profAnalysis.Name = profAnalysisName;
        return profAnalysis;
    }

    /**
    * @description method default values for creation data
    * @param profAnalysisId : context profitability analysis id
    * @return date : return Arce date
    */

    global date getARCEDate (Id profAnalysisId) {
        return null;
    }

    /**
    * @description method that returns a price decission wrapper object list by his decision id list
    * @param decisionsIdsList : a decision id's list
    * @param currentStatus : current status of the analysis
    * @return List<PriceDecision_Wrapper> : return a price decision wrapper object
    */

    global List<cuco.PriceDecision_Wrapper> getPriceDecisions (List<String> decisionsIdsList, String currentStatus) {

        final List<cuco.PriceDecision_Wrapper> lstToReturn = new List<cuco.PriceDecision_Wrapper>();

        for (String decision : decisionsIdsList) {

            String style = null;
            String name = null;
            switch on decision {
                when 'A' {		// when decision is A and  the status is 'Sent for Price Approval' return scaletop else return scaleup
                    if (currentStatus == 'Sent for Price Approval') {
                        style = 'scaletop';
                        name = Label.cuco.price_dec_elevateTop_sample;
                    }
                }
                when 'Y' {		// when decision is Y
                    // return the string scaleup
                    style = 'scaleup';
                    name = Label.cuco.price_dec_elevate_sample;
                }
                when 'Z' {		// when decision is Z
                    // return the string scaltop
                    style = 'scaltop';
                    name = Label.cuco.price_dec_elevateTop_sample;
                }
                when 'B' {		// when decision is B
                    // return the string aprove
                    style = 'approve';
                    name = Label.cuco.price_dec_approve_sample;
                }
                when 'S' {		// when decision is S
                    // return the string aprove
                    style = 'approve';
                    name = Label.cuco.price_dec_authorize_sample;
                }
                when 'E' {		// when decision is E
                    // return the string deny
                    style = 'deny';
                    name = Label.cuco.price_dec_return_sample;
                }
            }
            cuco.PriceDecision_Wrapper pdw = new cuco.PriceDecision_Wrapper();
            pdw.id = decision;
            pdw.name = name;
            pdw.style = style;

            lstToReturn.add(pdw);
        }
        return lstToReturn;
    }

    /**
    * @description method that returns a price decission wrapper object list by his decision id list
    * @param decisionsIdsList : a decision id's list
    * @param ProfitabilityAnalysis_Wrapper : profAnalysis wrapper object
    * @param String : a decision id
    * @param String : a screenShot
    * @return Map<String, Object> : return a string object map with the result of the update
    */
    global Map<String, Object> setPriceDecision (cuco.ProfitabilityAnalysis_Wrapper profAnalysis, String decisionId, String decisionComments, String screenShot) {

        final Map<String, Object> res = new Map<String, Object>();
        res.put('success', true);
        return res;
    }

    /**
    * @description returns wrapper info updated for profAnalysis
    * @param profAnalysis : ProfitabilityAnalysis_Wrapper wrapper with profitability_analysis__c info
    * @param approvalComments : String with comments
    * @return Map<String, Object> map with the response
    */
    global Map<String, Object> setPAApprovePrice(cuco.ProfitabilityAnalysis_Wrapper profAnalysis, String approvalComments) {
        final Map<String,Object> retMap = new Map<String,Object>();
        final Set<Id> setPaId = new Set<Id>{profAnalysis.Id};
        final cuco.ProfitabilityAnalysis_Selector paSelector = new cuco.ProfitabilityAnalysis_Selector(true);
        final List<cuco__profitability_analysis__c> lstPA = paSelector.selectById(setPaId);
        if(!lstPA.isEmpty()) {
            lstPA[0].cuco__gf_pa_mgmt_stage_type_name__c = 'Price Approval';
            lstPA[0].cuco__gf_pa_mgmt_status_type_name__c = 'Price Approved';
        }

        /* DML actions */
        //final DML_Wrapper dmlUpdatePA = updatePA(lstPA);

        retMap.put('success',false);
        retMap.put('message',Label.cuco.approve_price_error_sample);

        return retMap;
    }

    /**
    * @description Do the actions of dismissal of profitability analysis
    * @param profAnalysis : Wrapper with related info of profAnalysis
    * @param dismissalComments : String with dismissal comments value
    * @param screenShot : String with value to audit record
    * @return Map<String, Object>, with action results
    */
    global Map<String, Object> setPADismissal(cuco.ProfitabilityAnalysis_Wrapper profAnalysis, String dismissalComments, String screenShot) {
        final Map<String, Object> retMap = new Map<String, Object>();

        // First, update context prof analysis id (Stage and status fields)
        final cuco.ProfitabilityAnalysis_Selector paSelector = new cuco.ProfitabilityAnalysis_Selector(true);
        final List<cuco__profitability_analysis__c> lstPA = paSelector.selectById(new Set<Id>{profAnalysis.id});
        lstPA[0].cuco__gf_pa_mgmt_stage_type_name__c = 'Dismissed';
        lstPA[0].cuco__gf_pa_mgmt_status_type_name__c = 'Dismissed';
        final DML_Wrapper updateResult = updatePA(lstPA);
        retMap.put('success', updateResult.isSuccess);
        retMap.put('message', updateResult.isSuccess ? Label.cuco.dismissal_success_sample : Label.cuco.dismissal_error_sample + ' ' + updateResult.lstErrMessage.toString());

        // Second, create new audit and audit detail records
        if (updateResult.isSuccess) {
            final dwp_cvad__Action_Audit__c dismissalAudit = new dwp_cvad__Action_Audit__c();
            dismissalAudit.dwp_cvad__action_audit_name__c = Label.cuco.dismissal_action_sample;
            dismissalAudit.dwp_cvad__action_audit_object_api_name__c = 'cuco__profitability_analysis__c';
            dismissalAudit.dwp_cvad__action_audit_record_id__c = profAnalysis.id;
            dismissalAudit.dwp_cvad__action_audit_style__c = 'deny';
            dismissalAudit.dwp_cvad__action_audit_date__c = DateTime.now();
            dismissalAudit.dwp_cvad__action_audit_type__c = 'ProfitabilityAnalysis';
            dismissalAudit.dwp_cvad__action_audit_user_id__c = UserInfo.getUserId();
            Insert dismissalAudit;

            final dwp_cvad__Action_Audit_Detail__c dismissalAuditDetail = new dwp_cvad__Action_Audit_Detail__c();
            dismissalAuditDetail.dwp_cvad__action_audit_id__c = dismissalAudit.id;
            dismissalAuditDetail.dwp_cvad__action_audit_detail_content__c = screenShot;
            dismissalAuditDetail.dwp_cvad__action_audit_detail_content_format__c = 'HTML';
            dismissalAuditDetail.dwp_cvad__action_audit_detail_display_order__c = 1;
            dismissalAuditDetail.dwp_cvad__action_audit_detail_display_type__c = 'Embedded';
            Insert dismissalAuditDetail;
        }
        return retMap;
    }

    /**
    * @description returns wrapper info updated for profAnalysis in formalization
    * @param profAnalysis : ProfitabilityAnalysis_Wrapper wrapper with profitability_analysis__c info
    * @param formMethod : String with method to formalize
    * @param formComments : String with comments
    * @param screenShot : String with screen shot id
    * @return Map<String, Object> map with the response
    */
    global Map<String, Object> setPAFormalization(cuco.ProfitabilityAnalysis_Wrapper profAnalysis, String formMethod, String formComments, String screenShot) {
        final Map<String,Object> retMap = new Map<String,Object>();
        final CucoProfitabilityAnalysisCIB paSample = new CucoProfitabilityAnalysisCIB();
        final Set<Id> setPaId = new Set<Id>{profAnalysis.Id};
        final cuco.ProfitabilityAnalysis_Selector paSelector = new cuco.ProfitabilityAnalysis_Selector(true);
        List<cuco__profitability_analysis__c> lstPA = paSelector.selectById(setPaId);
        if(!lstPA.isEmpty()) {
            lstPA = paSample.updProfAnalysis(lstPA, profAnalysis, formMethod);
        }

        /* DML actions */
        final DML_Wrapper dmlUpdatePA = updatePA(lstPA);

        if(dmlUpdatePA.isSuccess == true && formMethod != null) {
            /* audit info */
            final dwp_cvad__Action_Audit__c audit = paSample.createAuditForm(profAnalysis, formMethod, formComments);
            Database.insert(audit);

            /* audit detail info */
            final dwp_cvad__Action_Audit_Detail__c auditDetail = new dwp_cvad__Action_Audit_Detail__c(
                dwp_cvad__action_audit_id__c = audit.id,
                dwp_cvad__action_audit_detail_content__c = screenShot,
                dwp_cvad__action_audit_detail_content_format__c = 'HTML',
                dwp_cvad__action_audit_detail_display_order__c = 1,
                dwp_cvad__action_audit_detail_display_type__c = 'Embedded'
            );
            Database.insert(auditDetail);

            retMap.put('success', true);
            if(formMethod == 'Combined') {
                retMap.put('message', Label.cuco.form_complete_success_sample);
            } else if(formMethod == 'Automatic') {
                retMap.put('message', Label.cuco.form_sent_success_sample);
            }
        }

        return retMap;
    }

    /**
    * @description private method to update profitability analysis record
    * @param lstPA : list with profitability analysis record to update
    * @param profAnalysis : ProfitabilityAnalysis_Wrapper wrapper with profitability_analysis__c info
    * @param formMethod : String with method to formalize
    * @return List<profitability_analysis__c> with updated list
    */
    private List<cuco__profitability_analysis__c> updProfAnalysis(List<cuco__profitability_analysis__c> lstPA, cuco.ProfitabilityAnalysis_Wrapper profAnalysis, String formMethod) {

        if(formMethod == 'Combined') {
            lstPA[0].cuco__gf_pa_mgmt_stage_type_name__c = 'Formalization';
            lstPA[0].cuco__gf_pa_mgmt_status_type_name__c = 'Sent for Formalization';
            lstPA[0].cuco__gf_manl_formalization_req_id__c = profAnalysis.manualFormRequestId;
            if (profAnalysis.status != 'Pending Send for Manual Formalization') {
                lstPA[0].cuco__gf_pa_cond_appl_eff_date__c = profAnalysis.startDate;
                if(lstPA[0].cuco__gf_pa_management_type_name__c != 'Cancellation') {
                    lstPA[0].cuco__gf_pa_cond_appl_expiry_date__c = profAnalysis.endDate;
                }
                lstPA[0].cuco__gf_auto_formalization_req_id__c = profAnalysis.autoFormRequestId;
                lstPA[0].cuco__gf_auto_form_sys_lst_cmun_date__c = Date.today();
            }
        } else if (formMethod == 'Automatic') {
            lstPA[0].cuco__gf_pa_mgmt_stage_type_name__c = 'Formalized';
            lstPA[0].cuco__gf_pa_mgmt_status_type_name__c = 'Formalized';
            lstPA[0].cuco__gf_pa_cond_appl_eff_date__c = profAnalysis.startDate;
            if(lstPA[0].cuco__gf_pa_management_type_name__c != 'Cancellation') {
                lstPA[0].cuco__gf_pa_cond_appl_expiry_date__c = profAnalysis.endDate;
            }
            lstPA[0].cuco__gf_auto_formalization_req_id__c = profAnalysis.autoFormRequestId;
            lstPA[0].cuco__gf_auto_form_sys_lst_cmun_date__c = Date.today();
        }
        return lstPA;
    }

    /**
    * @description private method to create audit action record
    * @param profAnalysis : ProfitabilityAnalysis_Wrapper wrapper with profitability_analysis__c info
    * @param formMethod : String with method to formalize
    * @param formComments : String with comments
    * @return dwp_cvad__Action_Audit__c action audit record
    */
    private dwp_cvad__Action_Audit__c createAuditForm(cuco.ProfitabilityAnalysis_Wrapper profAnalysis, String formMethod, String formComments) {
        final dwp_cvad__Action_Audit__c audit = new dwp_cvad__Action_Audit__c(
            dwp_cvad__action_audit_object_api_name__c = 'cuco__profitability_analysis__c',
            dwp_cvad__action_audit_record_id__c = profAnalysis.Id,
            dwp_cvad__action_audit_date__c = DateTime.now(),
            dwp_cvad__action_audit_type__c = 'ProfitabilityAnalysis',
            dwp_cvad__action_audit_user_id__c = UserInfo.getUserId()
        );
        if(formMethod == 'Combined') {
            audit.dwp_cvad__action_audit_name__c = Label.cuco.form_sent_sample;
            audit.dwp_cvad__action_audit_style__c = 'elevate';
        } else if(formMethod == 'Automatic') {
            audit.dwp_cvad__action_audit_name__c = Label.cuco.form_complete_sample;
            audit.dwp_cvad__action_audit_style__c = 'approve';
        }
        return audit;
    }

    /**
    * @description Do the actions of restudy of profitability analysis
    * @param profAnalysis : Wrapper with related info of profAnalysis
    * @param dismissalComments : String with dismissal comments value
    * @param screenShot : String with value to audit record
    * @return Map<String, Object>, with action results
    */
    global Map<String, Object> setPARestudy(cuco.ProfitabilityAnalysis_Wrapper profAnalysis, String restudyComments, String screenShot) {
        final Map<String, Object> retMap = new Map<String, Object>();

        // First, update context prof analysis id (Stage and status fields) and empty certains fields in funtion of stage value
        final cuco.ProfitabilityAnalysis_Selector paSelector = new cuco.ProfitabilityAnalysis_Selector(true);
        final List<cuco__profitability_analysis__c> lstPA = paSelector.selectById(new Set<Id>{profAnalysis.id});


            lstPA[0].cuco__gf_price_aprvl_process_req_id__c = null;
            lstPA[0].cuco__gf_pa_price_negotiated_date__c = null;
            lstPA[0].cuco__gf_pa_aprvl_proc_deleg_br_id__c = null;

        lstPA[0].cuco__gf_pa_mgmt_stage_type_name__c = 'Analysis';
        lstPA[0].cuco__gf_pa_mgmt_status_type_name__c = 'Restudy';
        final DML_Wrapper updateResult = updatePA(lstPA);
        retMap.put('success', updateResult.isSuccess);
        retMap.put('message', updateResult.isSuccess ? Label.cuco.restudy_success_sample : Label.cuco.restudy_error_sample + ' ' + updateResult.lstErrMessage.toString());

        // Second, create new audit and audit detail records
        if (updateResult.isSuccess) {
            final dwp_cvad__Action_Audit__c restudyAudit = new dwp_cvad__Action_Audit__c();
            restudyAudit.dwp_cvad__action_audit_name__c = Label.cuco.restudy_sample;
            restudyAudit.dwp_cvad__action_audit_object_api_name__c = 'cuco__profitability_analysis__c';
            restudyAudit.dwp_cvad__action_audit_record_id__c = profAnalysis.id;
            restudyAudit.dwp_cvad__action_audit_style__c = 'restudy';
            restudyAudit.dwp_cvad__action_audit_date__c = DateTime.now();
            restudyAudit.dwp_cvad__action_audit_type__c = 'ProfitabilityAnalysis';
            restudyAudit.dwp_cvad__action_audit_user_id__c = UserInfo.getUserId();
            Insert restudyAudit;

            final dwp_cvad__Action_Audit_Detail__c restudyAuditDetail = new dwp_cvad__Action_Audit_Detail__c();
            restudyAuditDetail.dwp_cvad__action_audit_id__c = restudyAudit.id;
            restudyAuditDetail.dwp_cvad__action_audit_detail_content__c = screenShot;
            restudyAuditDetail.dwp_cvad__action_audit_detail_content_format__c = 'HTML';
            restudyAuditDetail.dwp_cvad__action_audit_detail_display_order__c = 1;
            restudyAuditDetail.dwp_cvad__action_audit_detail_display_type__c = 'Embedded';
            Insert restudyAuditDetail;
        }
        return retMap;
    }

    /**
    * @description Auxiliar method to obtain FirstName and LastName from a Owner Id. If its a Group id, returns empty string.
    * @param ownerId : Id of the User/Group
    * @return String, with FirstName and LastName concatenated
    */
    global String getFirstAndLastName(Id ownerId) {
        String str;
        try {
            User u = [SELECT Id, FirstName, LastName FROM User WHERE Id =: ownerId LIMIT 1];
            str = u.FirstName + ' ' + u.LastName;
        } catch (Exception e) {
            str = '';
        }
        return str;
    }

    /**
    * @description Do the actions of notification of profitability analysis
    * @param profAnalysis : Wrapper with related info of profAnalysis
    * @param notificationComments : String with notification comments value
    * @param screenShot : String with value to audit record
    * @return Map<String, Object>, with action results
    */
    global Map<String, Object> setPANotification(cuco.ProfitabilityAnalysis_Wrapper profAnalysis, String notificationComments, String screenShot) {
        final Map<String, Object> retMapNotification = new Map<String, Object>();

        // First, update gf_manl_formalization_req_id__c field of context prof analysis id
        final cuco.ProfitabilityAnalysis_Selector paSelectorNotification = new cuco.ProfitabilityAnalysis_Selector(true);
        final List<cuco__profitability_analysis__c> lstPANotification = paSelectorNotification.selectById(new Set<Id>{profAnalysis.id});
        lstPANotification[0].cuco__gf_manl_formalization_req_id__c = profAnalysis.manualFormRequestId;
        lstPANotification[0].picasso_info_request__c = false;

        final DML_Wrapper updateNotificationResult = updatePA(lstPANotification);
        retMapNotification.put('success', updateNotificationResult.isSuccess);
        retMapNotification.put('message', updateNotificationResult.isSuccess ? Label.cuco.notification_success_sample : Label.cuco.notification_error_sample + ' ' + updateNotificationResult.lstErrMessage.toString());

        // Second, create new audit and audit detail records
        if (updateNotificationResult.isSuccess) {
            final dwp_cvad__Action_Audit__c notificationAudit = new dwp_cvad__Action_Audit__c();
            notificationAudit.dwp_cvad__action_audit_name__c = Label.cuco.notification_action_sample;
            notificationAudit.dwp_cvad__action_audit_object_api_name__c = 'cuco__profitability_analysis__c';
            notificationAudit.dwp_cvad__action_audit_record_id__c = profAnalysis.id;
            notificationAudit.dwp_cvad__action_audit_style__c = 'quickText';
            notificationAudit.dwp_cvad__action_audit_date__c = DateTime.now();
            notificationAudit.dwp_cvad__action_audit_type__c = 'ProfitabilityAnalysis';
            notificationAudit.dwp_cvad__action_audit_user_id__c = UserInfo.getUserId();
            Insert notificationAudit;

            final dwp_cvad__Action_Audit_Detail__c notificationAuditDetail = new dwp_cvad__Action_Audit_Detail__c();
            notificationAuditDetail.dwp_cvad__action_audit_id__c = notificationAudit.id;
            notificationAuditDetail.dwp_cvad__action_audit_detail_content__c = screenShot;
            notificationAuditDetail.dwp_cvad__action_audit_detail_content_format__c = 'HTML';
            notificationAuditDetail.dwp_cvad__action_audit_detail_display_order__c = 1;
            notificationAuditDetail.dwp_cvad__action_audit_detail_display_type__c = 'Embedded';
            Insert notificationAuditDetail;
        }
        return retMapNotification;
    }

    /**
    * @description Extra actions
    */
    global List<cuco.AdditionalActions_Wrapper> getExtraParticipantActions(Id profAnalysisId, Id userId) {
        final Set<Id> ids = new Set<Id>{profAnalysisId};
        final List<cuco.AdditionalActions_Wrapper> res = new List<cuco.AdditionalActions_Wrapper>();
        final cuco.ProfitabilityAnalysis_Selector selector = new cuco.ProfitabilityAnalysis_Selector(true);
        final List<cuco__profitability_analysis__c> lstPA = selector.selectById(ids);
        final List<String> validTypology = new List<String>{'Renewal', 'Novation'};
        if (!lstPA.isEmpty() && validTypology.indexOf(lstPA[0].cuco__gf_pa_management_type_name__c) > -1) {
            res.add(new cuco.AdditionalActions_Wrapper('Move', 'move', 'c:participant_move_cmp'));
        }
        return res;
    }

    /**
    * @description Returns an updated record of profitability analysis for cloning process
    * @param paRecordId Profitability analysis record
    * @return profitability_analysis__c updated record
    */
    global cuco__profitability_analysis__c setPADefaultCloneData(cuco__profitability_analysis__c profAnalysis) {
        profAnalysis.OwnerId = UserInfo.getUserId();
        return profAnalysis;
    }

    /**
    * @description Wrapper use to return info on dml operations
    */
    public class DML_Wrapper {

        /**
          * @description Boolean variable to set if DML Operation was successful
          */
        @AuraEnabled
        public Boolean isSuccess {get; set;}

        /**
          * @description String variable to set DML Operation errors, if exist
          */
        @AuraEnabled
        public List<String> lstErrMessage {get; set;}

        /**
          * @description Constructor of DML_Wrapper class
          */
        public DML_Wrapper(Boolean isSuccess, List<String> lstErrMessage) {
            this.isSuccess = isSuccess;
            this.lstErrMessage = lstErrMessage;
        }
    }

    public static DML_Wrapper updatePA (List<cuco__profitability_analysis__c> lstPA) {
        final List<String> errLstUpdatePA = new List<String>();
        final List<Database.SaveResult> srLstPA = Database.Update(lstPA, false);
        for (Database.SaveResult srPA : srLstPA) {
            if (!srPA.isSuccess()) {
                // Operation failed, so get all errors
                for (Database.Error errInsPA : srPA.getErrors()) {
                    errLstUpdatePA.add(errInsPA.getMessage());
                    System.debug('Update profitability_analysis__c ERROR: ' + userInfo.getUserName() + ', ' + errInsPA.getStatusCode() + ': ' + errInsPA.getMessage());
                }
            }
        }
        return new DML_Wrapper(errLstUpdatePA.isEmpty(), errLstUpdatePA);
    }

    /**
    * @description
    * @param profAnalysis Profitability analysis record wrapped
    * @param comments String introduce by the user
    * @param screenShot String with value to audit record
    * @return Map<String, Object>
    */
    global Map<String, Object> setPAResetRenewal(cuco.ProfitabilityAnalysis_Wrapper profAnalysis, String comments, String screenShot) {
        final Map<String, Object> mapToReturn = new Map<String, Object>();
        final cuco.ProfitabilityAnalysis_Selector paSelector = new cuco.ProfitabilityAnalysis_Selector();
        final List<cuco__profitability_analysis__c> lstPA = paSelector.selectById(new Set<Id>{profAnalysis.id});
        if (lstPA != null && !lstPA.isEmpty()) {
            lstPA[0].cuco__gf_pa_mgmt_stage_type_name__c = 'Analysis';
            lstPA[0].cuco__gf_pa_mgmt_status_type_name__c = 'Analysis';
            lstPA[0].cuco__fast_track_ind_type__c = false;

            //Update profitability analysis
            final DML_Wrapper updateResult = updatePA(lstPA);
            if (updateResult.isSuccess) {
                mapToReturn.put('success', updateResult.isSuccess);
                mapToReturn.put('message', Label.cuco.reset_renewal_success_sample);

                final dwp_cvad__Action_Audit__c audit = new dwp_cvad__Action_Audit__c();
                audit.dwp_cvad__action_audit_name__c = Label.cuco.reset_renewal_sample;
                audit.dwp_cvad__action_audit_object_api_name__c = 'cuco__profitability_analysis__c';
                audit.dwp_cvad__action_audit_record_id__c = lstPA[0].id;
                audit.dwp_cvad__action_audit_style__c = 'sendBack';
                audit.dwp_cvad__action_audit_date__c = DateTime.now();
                audit.dwp_cvad__action_audit_type__c = 'ProfitabilityAnalysis';
                audit.dwp_cvad__action_audit_user_id__c = UserInfo.getUserId();
                //Insert audit record
                Insert audit;

                final dwp_cvad__Action_Audit_Detail__c auditDetail = new dwp_cvad__Action_Audit_Detail__c();
                auditDetail.dwp_cvad__action_audit_id__c = audit.id;
                auditDetail.dwp_cvad__action_audit_detail_content__c = screenShot;
                auditDetail.dwp_cvad__action_audit_detail_content_format__c = 'HTML';
                auditDetail.dwp_cvad__action_audit_detail_display_order__c = 1;
                auditDetail.dwp_cvad__action_audit_detail_display_type__c = 'Embedded';
                //Insert auditDetail record
                Insert auditDetail;
            } else {
                //add to returned map the result
                mapToReturn.put('success', updateResult.isSuccess);
                mapToReturn.put('message', Label.cuco.reset_renewal_error_sample);
            }
        }
        return mapToReturn;
    }
}