global without sharing class TXNM_ScheduleBatchProcess
    implements Schedulable,
               Database.Batchable<SObject>,
               Database.AllowsCallouts,
               Database.Stateful {

    // Global counter across the whole batch run
    Integer jobIndex = 0;

    // ---- Schedulable ----
    global void execute(SchedulableContext sc) {
        // Always run with scope size = 1
        Database.executeBatch(this, 1);
    }

    // ---- Batchable ----
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Id, DeveloperName, MasterLabel, Taxonomy_code__c, Objects_and_fields__c ' +
            'FROM TXNM_Taxonomy_mapping__mdt ' +
            'WITH SECURITY_ENFORCED' + (Test.isRunningTest() ? ' LIMIT 1 ' : '')
        );
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        // Scope size is enforced to 1, but handle generically.
        for (sObject eachMdta : scope) {
            TXNM_Taxonomy_mapping__mdt mdtaRecord = (TXNM_Taxonomy_mapping__mdt) eachMdta;
            String taxonomyCode = mdtaRecord.Taxonomy_code__c;

            try {
                // Increment global job index for each record processed
                jobIndex++;
                Integer offsetMinutes = jobIndex * 10; // 5 minutes between each scheduled job

                Datetime runTime = Datetime.now().addMinutes(offsetMinutes);
                String cron = buildCronForDatetime(runTime);

                String jobName = 'TXNM_ScheduleSingleProcess_' +
                                 taxonomyCode + '_' +
                                 String.valueOf(Datetime.now().getTime());

                TXNM_ScheduleSingleProcess singleProcess = new TXNM_ScheduleSingleProcess();
                singleProcess.taxonomyCode = taxonomyCode;
                singleProcess.mdta = (TXNM_Taxonomy_mapping__mdt) eachMdta; // safer to store Id, re-query later

                System.schedule(jobName, cron, singleProcess);

            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR,
                    'TXNM_ScheduleBatchProcess scheduling error for code ' + taxonomyCode +
                    ' (mapping=' + mdtaRecord.DeveloperName + '): ' + e.getMessage());
            }
        }
    }

    global void finish(Database.BatchableContext bc) {
        System.debug(LoggingLevel.INFO,
            'TXNM_ScheduleBatchProcess finished. Jobs scheduled: ' + jobIndex);
    }

    // Helper: build a CRON expression for a given Datetime
    private static String buildCronForDatetime(Datetime dt) {
        // Format: second minute hour dayOfMonth month ? year
        return String.format('{0} {1} {2} {3} {4} ? {5}',
            new List<String>{
                String.valueOf(dt.second()),
                String.valueOf(dt.minute()),
                String.valueOf(dt.hour()),
                String.valueOf(dt.day()),
                String.valueOf(dt.month()),
                String.valueOf(dt.year())
            }
        );
    }
}