public without sharing class DMT_BulkClosedDataCreator implements Queueable {

    private Integer remaining;
    private Id lineId;
    private Id queueId;
    private Id caseRtId;
    private Id taskRtId;
    private Id taskTypeId;
    private Id accountId;
    private String currencyIsoCode;
    private Integer startIndex;
    private Integer casesPerJob;

    public DMT_BulkClosedDataCreator(
        Integer remaining,
        Id lineId,
        Id queueId,
        Id caseRtId,
        Id taskRtId,
        Id taskTypeId,
        Id accountId,
        String currencyIsoCode,
        Integer startIndex,
        Integer casesPerJob
    ) {
        this.remaining = remaining;
        this.lineId = lineId;
        this.queueId = queueId;
        this.caseRtId = caseRtId;
        this.taskRtId = taskRtId;
        this.taskTypeId = taskTypeId;
        this.accountId = accountId;
        this.currencyIsoCode = currencyIsoCode;
        this.startIndex = startIndex;
        this.casesPerJob = casesPerJob;
    }

    public void execute(QueueableContext qc) {
        Integer toCreate = Math.min(remaining, casesPerJob);

        List<Case> casesToInsert = new List<Case>();
        for (Integer i = 0; i < toCreate; i++) {
            Integer currentNumber = startIndex + i;

            Case c = new Case();
            c.RecordTypeId = caseRtId;
            c.Status = 'Finished';
            c.AccountId = accountId;
            c.CurrencyIsoCode = currencyIsoCode;
            c.DMT_Line__c = lineId;
            c.Description = 'Bulk test case closed tab #' + currentNumber;
            c.DMT_Feature_Id__c = String.valueOf(300000 + currentNumber);
            c.DMT_Related_feature_name__c = 'Bulk Feature ' + currentNumber;
            c.DMT_Passport_Sanction__c = 'approval';
            casesToInsert.add(c);
        }

        Database.SaveResult[] caseResults = Database.insert(casesToInsert, false);

        List<Task> tasksToInsert = new List<Task>();
        Integer okCases = 0;
        Integer koCases = 0;

        for (Integer i = 0; i < caseResults.size(); i++) {
            if (caseResults[i].isSuccess()) {
                okCases++;

                Task t = new Task();
                t.RecordTypeId = taskRtId;
                t.OwnerId = queueId;
                t.WhatId = caseResults[i].getId();
                t.Subject = 'Bulk Closed Task #' + (startIndex + i);
                t.Status = 'Finished';
                t.Description = 'Bulk task for closed lines/opportunities #' + (startIndex + i);
                t.DMT_Task_Type__c = taskTypeId;
                t.DMT_Step_Result__c = 'Yes';
                t.DMT_Committee_Label__c = 'AUTO';
                tasksToInsert.add(t);
            } else {
                koCases++;
                for (Database.Error err : caseResults[i].getErrors()) {
                    System.debug('ERROR CASE [' + (startIndex + i) + ']: ' + err.getMessage());
                }
            }
        }

        Integer okTasks = 0;
        Integer koTasks = 0;

        if (!tasksToInsert.isEmpty()) {
            Database.SaveResult[] taskResults = Database.insert(tasksToInsert, false);

            for (Integer i = 0; i < taskResults.size(); i++) {
                if (taskResults[i].isSuccess()) {
                    okTasks++;
                } else {
                    koTasks++;
                    for (Database.Error err : taskResults[i].getErrors()) {
                        System.debug('ERROR TASK [' + (startIndex + i) + ']: ' + err.getMessage());
                    }
                }
            }
        }

        System.debug('JOB COMPLETADO -> desde ' + startIndex + ' | Cases OK: ' + okCases + ' | Cases KO: ' + koCases + ' | Tasks OK: ' + okTasks + ' | Tasks KO: ' + koTasks);

        Integer newRemaining = remaining - toCreate;
        Integer newStartIndex = startIndex + toCreate;

        if (newRemaining > 0) {
            System.enqueueJob(new DMT_BulkClosedDataCreator(
                newRemaining,
                lineId,
                queueId,
                caseRtId,
                taskRtId,
                taskTypeId,
                accountId,
                currencyIsoCode,
                newStartIndex,
                casesPerJob
            ));
        }
    }
}