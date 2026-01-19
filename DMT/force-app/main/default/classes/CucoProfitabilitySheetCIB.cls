/**
* ─────────────────────────────────────────────────────────────────────────
* Profitability Sheet CIB
* Sample implementation of the multiple methods from ProfitabilitySheet_Itf
* ─────────────────────────────────────────────────────────────────────────
* @author      Cosme Alcázar <cosme.alcazar.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2022-09-07
* @modified
* @systemLayer Sample
* ─────────────────────────────────────────────────────────────────────────
* @changes
*
* ─────────────────────────────────────────────────────────────────────────
*/
@SuppressWarnings('PMD.AvoidGlobalModifier, sf:DMLWithoutSharingEnabled')
global class CucoProfitabilitySheetCIB implements cuco.ProfitabilitySheet_Itf {

    /** @description success */
    private static final String STRINGSUCCESS = 'success';

    /**
    * @description returns the user code
    * @param profSheetId Id of the Profitability Sheet
    * @param discardComments String with discard decision comments
    * @param userId Id of the current user
    * @param discardDate Date with discard decision time value
    * @return Map<String, Object>, with the result of current method execution
    */
    global Map<String, Object> setDiscardDetails(Id profSheetId, String discardComments, Id userId, Date discardDate) {
        final Map<String, Object> retMapDiscard = new Map<String, Object>();

        final cuco.ProfitabilitySheet_Selector psSelectorDiscard = new cuco.ProfitabilitySheet_Selector(true);
        final List<cuco__profitability_sheet__c> lstPSDiscard = psSelectorDiscard.selectById(new Set<Id>{profSheetId});
        lstPSDiscard[0].cuco__renewal_discarded_type__c = true;

        final cuco.Utils.DML_Wrapper updateDiscardDML = updatePS(lstPSDiscard);
        retMapDiscard.put(STRINGSUCCESS, updateDiscardDML.isSuccess);

        // Second, create new audit and audit detail records
        if (updateDiscardDML.isSuccess) {
            final dwp_cvad__Action_Audit__c discardAudit = new dwp_cvad__Action_Audit__c();
            discardAudit.dwp_cvad__action_audit_name__c = Label.cuco.discard_action_sample;
            discardAudit.dwp_cvad__action_audit_object_api_name__c = 'cuco__profitability_sheet__c';
            discardAudit.dwp_cvad__action_audit_record_id__c = profSheetId;
            discardAudit.dwp_cvad__action_audit_style__c = 'deny';
            discardAudit.dwp_cvad__action_audit_date__c = DateTime.now();
            discardAudit.dwp_cvad__action_audit_type__c = 'ProfitabilitySheet';
            discardAudit.dwp_cvad__audit_audit_comments__c = discardComments;
            discardAudit.dwp_cvad__action_audit_user_id__c = UserInfo.getUserId();
            Insert discardAudit;
        } else {
            retMapDiscard.put('message', Label.cuco.discard_action_error_sample + ' ' + updateDiscardDML.lstErrMessage.toString());
        }
        return retMapDiscard;
    }
    
    /**
    * @description returns the user code
    * @param profSheetId Id of the Profitability Sheet
    * @return Map<String, Object>, with the result of current method execution
    */
    global Map<String, Object> getDiscardDetails(Id profSheetId) {
        final Map<String, Object> retMapDiscard = new Map<String, Object>();
        final List<dwp_cvad__Action_Audit__c> lstPSDiscardAudit = [ SELECT Id, dwp_cvad__audit_audit_comments__c, dwp_cvad__action_audit_user_id__c, dwp_cvad__action_audit_date__c
                                                                    FROM dwp_cvad__Action_Audit__c
                                                                    WHERE dwp_cvad__action_audit_record_id__c =: profSheetId
                                                                    AND dwp_cvad__action_audit_name__c =: Label.cuco.discard_action_sample
                                                                    ORDER BY CreatedDate DESC
                                                                    LIMIT 1];
        if (!lstPSDiscardAudit.isEmpty()) {
            final List<User> lstUser = [SELECT Id, Name FROM User WHERE Id =: lstPSDiscardAudit[0].dwp_cvad__action_audit_user_id__c LIMIT 1];
            retMapDiscard.put('comments', lstPSDiscardAudit[0].dwp_cvad__audit_audit_comments__c);
            retMapDiscard.put('user', lstUser.isEmpty() ? new User() : lstUser[0]);
            retMapDiscard.put('date', lstPSDiscardAudit[0].dwp_cvad__action_audit_date__c);
        }
        return retMapDiscard;
    }

    /**
    * @description Returns whether the PS name was successfully changed
    * @param profSheet ProfitabilitySheet_Wrapper PS Wrapper
    * @param psNewName String New name for profitability sheet
    * @param userId Id User
    * @param data Map<String, Object>
    * @return Map<String, Object>, with the result of current method execution
    */
    global Map<String, Object> setModificationPSData(cuco.ProfitabilitySheet_Wrapper profSheet, String psNewName, Id userId, Map<String, Object> data) {

        final Map<String, Object> retMapModify = new Map<String, Object>();
        final List<String> lstErrors = new List<String>();
        Boolean serviceOK = true;
        Boolean dmlOK = true;

        final Savepoint savePoint = Database.setSavepoint();

        if ((Boolean) data.get('needCallService')) {
            try {
                final dwp_cvad__Action_Audit__c modificationAudit = new dwp_cvad__Action_Audit__c();
                modificationAudit.dwp_cvad__action_audit_name__c = Label.cuco.modify_notebook_action_sample;
                modificationAudit.dwp_cvad__action_audit_object_api_name__c = 'cuco__profitability_sheet__c';
                modificationAudit.dwp_cvad__action_audit_record_id__c = profSheet.id;
                modificationAudit.dwp_cvad__action_audit_style__c = 'infoAlt';
                modificationAudit.dwp_cvad__action_audit_date__c = DateTime.now();
                modificationAudit.dwp_cvad__action_audit_type__c = 'ProfitabilitySheet';
                modificationAudit.dwp_cvad__audit_audit_comments__c = (String) data.get('modifyComments');
                modificationAudit.dwp_cvad__action_audit_user_id__c = userId;
                Insert modificationAudit;
            } catch (QueryException ex) {
                serviceOK = false;
                lstErrors.add(ex.getMessage());
            }
        }

        if ((Boolean) data.get('needDoDML')) {

            final cuco.ProfitabilitySheet_Selector psSelectorModify = new cuco.ProfitabilitySheet_Selector(true);
            final List<cuco__profitability_sheet__c> lstPSModify = psSelectorModify.selectById(new Set<Id>{profSheet.id});
            lstPSModify[0].Name = psNewName;

            final cuco.Utils.DML_Wrapper updateModifydDML = updatePS(lstPSModify);

            if (!updateModifydDML.isSuccess) {
                dmlOK = false;
                lstErrors.add(updateModifydDML.lstErrMessage.toString());
            }
        }

        if (dmlOK && serviceOK) {
            retMapModify.put(STRINGSUCCESS, true);
            retMapModify.put('toastType', STRINGSUCCESS);
            retMapModify.put('modifyMessage', Label.cuco.modify_notebook_action_success_sample);
        } else {
            Database.rollback(savePoint);
            retMapModify.put(STRINGSUCCESS, false);
            retMapModify.put('toastType', 'false');
            retMapModify.put('modifyMessage', Label.cuco.modify_notebook_action_error_sample + ' ' + lstErrors.toString());
        }

        return retMapModify;
    }

    /**
    * @description Update the profitability sheet passed as parameter
    * @param lstPS: List of profitability sheet ready to update
    * @return Utils.DML_Wrapper, with the response of the DML operation
    */
    public static cuco.Utils.DML_Wrapper updatePS (List<cuco__profitability_sheet__c> lstPS) {
        final List<String> errLstUpdatePS = new List<String>();
        final List<Database.SaveResult> srLstPS = Database.Update(lstPS, false);
        // Iterate through each returned result
        for (Database.SaveResult srPS : srLstPS) {
            if (!srPS.isSuccess()) {
                // Operation failed, so get all errors
                for (Database.Error errInsPS : srPS.getErrors()) {
                    errLstUpdatePS.add(errInsPS.getMessage());
                    System.debug('Update profitability_sheet__c ERROR: ' + userInfo.getUserName() + ', ' + errInsPS.getStatusCode() + ': ' + errInsPS.getMessage());
                }
            }
        }
        return new cuco.Utils.DML_Wrapper(errLstUpdatePS.isEmpty(), errLstUpdatePS);
    }
}