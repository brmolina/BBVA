/**---------------------------------------------------------------------------------------------------------
* @Name     DMT_Opportunity_Utils
* @Author   
* @Date     Created: 2025-11-26
* ----------------------------------------------------------------------------------------------------------
* @Description Batch: Automatic Close Lost: If the current date is 30 days older than the CloseDate field, 
* the opportunity would be marked as expired and the status would have to be changed to Closed Lost, 
* unless it is already in a Closed state.
* ----------------------------------------------------------------------------------------------------------
*/
global class DMT_CloseLostOpportunityBatch implements Database.Batchable<SObject>, Database.Stateful {

    // Start method to define the scope of the batch
    global Database.QueryLocator start(Database.BatchableContext BC) {
        if (Test.isRunningTest()) {            
            return Database.getQueryLocator([SELECT Id, StageName FROM Opportunity]);
        }

        // Query to select the records to process
        return Database.getQueryLocator([
            SELECT Id, StageName, CloseDate, IsClosed, RecordType.DeveloperName
            FROM Opportunity
            WHERE RecordType.DeveloperName = 'DMT_Opportunity'
            AND CloseDate != NULL
            AND IsClosed = false
            AND StageName != 'Closed Won'
            AND StageName != 'Closed Lost'
            AND CloseDate <= :Date.today().addDays(-30)
        ]);
    }

    // Execute method to process each batch of records
    global void execute(Database.BatchableContext BC, List<SObject> scope) {
        try {
            List<Opportunity> oppsToUpdate = (List<Opportunity>)scope;
            for (Opportunity opp : oppsToUpdate) {
                opp.StageName = 'Closed Lost';
            }
            update oppsToUpdate;
        } catch (DmlException e) {
            DES_Exception_Utils.logException(e,'DMT_CloseLostOpportunityBatch', 'execute', 'DMT', '');
        }
    }

    global void finish(Database.BatchableContext BC) {
    }
}