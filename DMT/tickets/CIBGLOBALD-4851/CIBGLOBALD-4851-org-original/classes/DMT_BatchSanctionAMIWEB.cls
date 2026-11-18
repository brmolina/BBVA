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

    // Bulk Import mode only: Line_Id__c of the imported lines to update (null in the nightly AMIWEB mode)
    private Set<String> bulkImportLineIds;

    // Bulk Import mode only: per-row failures collected across chunks (Database.Stateful), used to
    // build the completion email and the DES_Exceptions__b log entries. Nightly AMIWEB mode never
    // populates this - it keeps the original whole-chunk `update lines` behaviour untouched.
    private List<String> bulkImportFailures = new List<String>();
    private Integer bulkImportFailureCount = 0;

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

    global Database.QueryLocator start(Database.BatchableContext bc) {
        // Bind variables referenced by the Bulk Import mode query
        Set<String> lineIds = bulkImportLineIds;
        Set<String> statusCodes = STATUS_BY_CODE.keySet();
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<DMT_Line__c> lines) {

        for (DMT_Line__c line : lines) {
            line.Status__c = STATUS_BY_CODE.get(line.g_line_status_type__c);
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
                if (!results[i].isSuccess() && bulkImportFailureCount < MAX_FAILURES_REPORTED) {
                    DMT_Line__c failedLine = lines[i];
                    String message = results[i].getErrors().isEmpty() ? 'Unknown error' : results[i].getErrors()[0].getMessage();
                    bulkImportFailures.add(failedLine.Line_Id__c + ' (' + failedLine.Name + '): ' + message);
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
        AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :bc.getJobId()];
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {a.CreatedBy.Email};
        mail.setToAddresses(toAddresses);
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