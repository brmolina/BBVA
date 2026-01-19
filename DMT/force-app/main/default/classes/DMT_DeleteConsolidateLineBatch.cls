global class DMT_DeleteConsolidateLineBatch implements Database.Batchable<SObject>, Database.Stateful {

    global Database.QueryLocator start(Database.BatchableContext BC) {

        String query = 'SELECT Id, DMT_Status_Completed__c, LastModifiedDate, Line_Id__c, Start_Date__c FROM DMT_Line__c';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<SObject> scope) 
    {
        List<String> linesToDelete = new List<String>();
        List<String> linesToSearch = new List<String>();

        for(DMT_Line__c r : (List<DMT_Line__c>)scope)
        {
            if(!(r.DMT_Status_Completed__c == 'Closed Lost'))
            {
                linesToSearch.add(r.Line_Id__c);
            }
        }

        List<DMT_Risk_Line_Term__c> riskTerms = DMT_Passport_Selector.getRiskLineTermWithoutDerivatives(linesToSearch);

        for(DMT_Line__c r : (List<DMT_Line__c>)scope)
        {
            if(r.DMT_Status_Completed__c == 'Closed Lost' && r.LastModifiedDate <= Date.today().addDays(-5))
            {
                linesToDelete.add(r.Line_Id__c);
            }
            else
            {
                Integer endTerm = 0;
                for(DMT_Risk_Line_Term__c rt : riskTerms)
                {
                    if(rt.DMT_Line__r.Line_Id__c == r.Line_Id__c)
                    {
                        endTerm = !String.isEmpty(rt.DMT_End_Term__c) && endTerm < Integer.valueOf(rt.DMT_End_Term__c) ? Integer.valueOf(rt.DMT_End_Term__c) : endTerm;
                    }  
                } 
                if(endTerm != 0 && r.Start_Date__c != null && r.Start_Date__c.addDays(endTerm) <= Date.today().addDays(-15))
                {
                    linesToDelete.add(r.Line_Id__c);
                }
            }

        }

        try 
        {   
            if(!linesToDelete.isEmpty())
            {
                delete [SELECT Id FROM DMT_Consolidated_Line__c WHERE line_id__c IN :linesToDelete];
            }
            
        } catch (DmlException e) {
            // Handle exceptions
            System.debug('Error deleting records: ' + e.getMessage());
            DES_Exception_Utils.logException(e,'DMT_DeleteConsolidateLineBatch', 'execute', 'DMT', '');
        }
    }

    global void finish(Database.BatchableContext BC) {
        // Final actions to be taken after all batches are processed
        System.debug('Batch processing completed.');
    }
}