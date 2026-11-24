/**-------------------------------------------------------------------------------------------
 * @Name     DMT Sanction AMIWEB
 * @Author   diego.peran.tech@bbva.com
 * @Date     Created: 2024-010-24
 * ------------------------------------------------------------------------------------------------
 * @Description This batch runs every night  and update Dmt_Lines with AMIWEB origin and Draft Status
 *              It is also launched from Bulk Import (Update Line Status action) for the lines of one import
 * ------------------------------------------------------------------------------------------------
 */
global without sharing class DMT_BatchSanctionAMIWEB implements Database.Batchable<sObject>, Database.Stateful, Schedulable{
    global final String query;

    private static final Map<String, String> STATUS_BY_CODE = new Map<String, String>{'DR' => 'Draft', 'PR' => 'Proposal', 'AP' => 'Approval', 'RC' => 'Ready to close', 'CL' => 'Closed', 'CW' => 'Closed'};
    private static final Integer MAX_FAILURES_REPORTED = 200;
    // CIBGLOBALD-4851 - org-wide sender of the DMT notifications (also used by DMT_SendEmailService, DMT_CloseWonNotificationService)
    private static final String SENDER_DISPLAY_NAME = 'Global Desktop Notification';

    // Bulk Import mode only: Line_Id__c of the imported lines to update (null in the nightly AMIWEB mode)
    private Set<String> bulkImportLineIds;
    // CIBGLOBALD-4851 - Bulk Import load mode only: target status by Line_Id__c, decided by the load
    // (DMT_BulkImportBatch.planStatus); null in the other modes, where the status comes from g_line_status_type__c
    private Map<String, String> targetStatusByLineId;

    // Bulk Import mode only: per-row failures collected across chunks (Database.Stateful), used to
    // build the completion email and the DES_Exceptions__b log entries. Nightly AMIWEB mode never
    // populates this - it keeps the original whole-chunk `update lines` behaviour untouched.
    private List<String> bulkImportFailures = new List<String>();
    private Integer bulkImportFailureCount = 0;
    // CIBGLOBALD-4851 - Bulk Import modes launched from the screen: its jobId (DMT_BulkImportProgress__e, Phase STATUS),
    // the lines done so far, the lines moved and the failed lines (Line_Id__c, Name, message) for the screen
    private String progressJobId;
    private Integer bulkImportProcessed = 0;
    private Integer bulkImportSuccessCount = 0;
    private List<Map<String, Object>> bulkImportErrorRows = new List<Map<String, Object>>();

    public DMT_BatchSanctionAMIWEB() {
        query = 'SELECT Id, Name, Status__c, Closed__c, DMT_Status_Completed__c, g_line_status_type__c FROM DMT_Line__c WHERE Status__c = \'Draft\' AND (DMT_Origin__c =  \'XX\' OR DMT_Origin__c =  \'AMIWEB\') AND Client_Type__c = \'Customer\'';
    }

    /**
     * Bulk Import mode (Update Line Status action): updates only the Draft lines of the given import
     * that carry a known status code in g_line_status_type__c. Client type is not filtered.
     */
    public DMT_BatchSanctionAMIWEB(Set<String> lineIds) {
        bulkImportLineIds = lineIds;
        query = 'SELECT Id, Name, Line_Id__c, Status__c, Closed__c, DMT_Status_Completed__c, g_line_status_type__c FROM DMT_Line__c WHERE Status__c = \'Draft\' AND DMT_Origin__c = \'BulkImport\' AND Line_Id__c IN :lineIds AND g_line_status_type__c IN :statusCodes';
    }

    /**
     * @description CIBGLOBALD-4851 - Bulk Import mode launched from the Update Line Status button: as above, and the
     * progress and result are published for the screen with its jobId (DMT_BulkImportBatch.publishEvent, Phase STATUS).
     */
    public DMT_BatchSanctionAMIWEB(Set<String> lineIds, String jobId) {
        this(lineIds);
        progressJobId = jobId;
    }

    /**
     * @description CIBGLOBALD-4851 - Bulk Import load mode (after Process in the LWC dmt_bulk_import, launched by
     * DMT_BulkImportBatch.finish with scope 1: a status change that restarts approval tasks costs about 76 SOQL). Moves
     * each Draft BulkImport line straight to its target status: the code's status, or the status the line had before the
     * load sent it to Draft (that line may have no code). Same partial save, log and email as the Bulk Import mode.
     * @param targetStatusByLineId Line_Id__c -> target Status__c
     * @param jobId                the jobId of the load on the screen (progress and result, Phase STATUS)
     */
    public DMT_BatchSanctionAMIWEB(Map<String, String> targetStatusByLineId, String jobId) {
        this.targetStatusByLineId = targetStatusByLineId;
progressJobId = jobId;
        bulkImportLineIds = targetStatusByLineId.keySet();
        query = 'SELECT Id, Name, Line_Id__c, Status__c, Closed__c, DMT_Status_Completed__c, g_line_status_type__c FROM DMT_Line__c WHERE Status__c = \'Draft\' AND DMT_Origin__c = \'BulkImport\' AND Line_Id__c IN :lineIds';
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        // Bind variables referenced by the Bulk Import mode query
        Set<String> lineIds = bulkImportLineIds;
        Set<String> statusCodes = STATUS_BY_CODE.keySet();
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<DMT_Line__c> lines) {

        for (DMT_Line__c line : lines) {
line.Status__c = targetStatusByLineId != null
                ? targetStatusByLineId.get(line.Line_Id__c)
                : STATUS_BY_CODE.get(line.g_line_status_type__c);
            if(line.g_line_status_type__c == 'CW'){
                 line.Closed__c = DMT_Constants.WON;
            }
            if(line.g_line_status_type__c == 'CL'){
                 line.Closed__c = 'Lost';
            }

        }

        if (lines.isEmpty()) {
            return;
        }

        // Bulk Import mode: partial save. One line failing a validation rule/flow (e.g. missing
        // product amounts) must not take the rest of the chunk down with it - each row is saved or
        // reported independently, and reported failures are logged + emailed in finish().
        if (bulkImportLineIds != null) {
            Database.SaveResult[] results = Database.update(lines, false);
            for (Integer i = 0; i < results.size(); i++) {
                if (results[i].isSuccess()) {
bulkImportSuccessCount++;
                }
                if (!results[i].isSuccess() && bulkImportFailureCount < MAX_FAILURES_REPORTED) {
                    DMT_Line__c failedLine = lines[i];
                    String message = results[i].getErrors().isEmpty() ? 'Unknown error' : results[i].getErrors()[0].getMessage();
                    bulkImportFailures.add(failedLine.Line_Id__c + ' (' + failedLine.Name + '): ' + message);
bulkImportErrorRows.add(new Map<String, Object>{
                        'id' => failedLine.Line_Id__c, 'label' => failedLine.Name, 'message' => message
                    });
                    DMT_AsyncOrchestrator.enqueue(new DMT_LogExceptionPayload(
                        message, null, null, 'DmlException',
                        'DMT_BatchSanctionAMIWEB', 'execute', 'DMT', failedLine.Line_Id__c
                    ));
                }
                if (!results[i].isSuccess()) {
                    bulkImportFailureCount++;
                }
            }
            DMT_AsyncOrchestrator.flush();
            // CIBGLOBALD-4851 - progress for the screen, one event per chunk
            bulkImportProcessed += lines.size();
            if (progressJobId != null) {
                DMT_BulkImportBatch.publishEvent(progressJobId, DMT_BulkImportBatch.PHASE_STATUS, DMT_BulkImportBatch.EVENT_IN_PROGRESS,
                    null, bulkImportProcessed, bulkImportSuccessCount, bulkImportFailureCount, null);
            }
            return;
        }

        // Nightly AMIWEB mode: unchanged - whole-chunk update, error swallowed as it always was.
        try{
            update lines;
        }catch (DmlException e) {
            System.debug(e.getMessage());
            //DES_Exception_Utils.logException(e,'DMT_BatchSanctionAMIWEB', 'execute', 'DMT', '');
        }

    }

    global void finish(Database.BatchableContext bc) {
AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email, ExtendedStatus FROM AsyncApexJob WHERE Id = :bc.getJobId()];
        // CIBGLOBALD-4851 - the result for the screen goes first, so a failure in the email cannot hide it; a chunk that
        // failed without a row result (limit, unhandled exception) is reported with the job's first error
        if (progressJobId != null) {
            if (a.NumberOfErrors > 0) {
                bulkImportErrorRows.add(new Map<String, Object>{
                    'message' => a.NumberOfErrors + ' part(s) of the job failed: ' + a.ExtendedStatus
                });
            }
            DMT_BulkImportBatch.publishEvent(progressJobId, DMT_BulkImportBatch.PHASE_STATUS, DMT_BulkImportBatch.EVENT_COMPLETED,
                bulkImportProcessed, bulkImportProcessed, bulkImportSuccessCount, bulkImportFailureCount, bulkImportErrorRows);
        }
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {a.CreatedBy.Email};
        mail.setToAddresses(toAddresses);
        // CIBGLOBALD-4851 - Enhancement to existing process: sent from the org-wide address Global Desktop Notification
        // (DMT_SendEmailService_Selector) instead of the user who ran the job; as before when the address is not found.
        List<OrgWideEmailAddress> senders = DMT_SendEmailService_Selector.getOrgWideEmailByDisplayName(SENDER_DISPLAY_NAME);
        if (!senders.isEmpty()) {
            mail.setOrgWideEmailAddressId(senders[0].Id);
        }
        if (bulkImportLineIds == null) {
            mail.setSubject('Batch AMIWEB Sanctions finished with status ' + a.Status);
            mail.setPlainTextBody
            ('The batch AMIWEB Sanctions processed ' + a.TotalJobItems +
            ' batches with '+ a.NumberOfErrors + ' failures.');
        } else {
            mail.setSubject('Bulk Import Update Line Status finished — ' + bulkImportFailureCount + ' failure(s)');
            String body = 'The Bulk Import Update Line Status job processed ' + a.TotalJobItems + ' batch(es).';
            if (bulkImportFailureCount > 0) {
                body += '\n\n' + bulkImportFailureCount + ' line(s) could not be updated:\n' + String.join(bulkImportFailures, '\n');
                if (bulkImportFailureCount > bulkImportFailures.size()) {
                    body += '\n...and ' + (bulkImportFailureCount - bulkImportFailures.size()) + ' more (see the exception log).';
                }
            } else {
                body += ' All lines were updated successfully.';
            }
            mail.setPlainTextBody(body);
        }
        if (!Test.isRunningTest()) {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{ mail });
        }
    }

    global void execute(SchedulableContext sc) {
        DMT_BatchSanctionAMIWEB batch = new DMT_BatchSanctionAMIWEB();
        Database.executeBatch(batch, 200);
    }



}