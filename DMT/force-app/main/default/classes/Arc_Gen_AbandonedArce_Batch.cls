/**
* -----------------------------------------------------------------------------------------------
* @name        Arc_Gen_AbandonedArce_Batch
* @author      nerea.ortiz.penalosa.contractor@bbva.com
* @date        2024-06-25
* @group       ARCE
* -----------------------------------------------------------------------------------------------
* @description Class "Arc_Gen_AbandonedArce_Batch" that cancels Arces or notifies Arce related users
*              based on arce__AbandonedArce__mdt configutation
* -----------------------------------------------------------------------------------------------
* @changes
* v1.0         nerea.ortiz.penalosa.contractor@bbva.com
* |2023-04-28  Class creation
*
* v1.1         nerea.ortiz.penalosa.contractor@bbva.com
* |2023-05-10  Batch adapted to several notify metadata
*
* v1.2         nerea.ortiz.penalosa.contractor@bbva.com
* |2023-05-30  Sonar refactor
*
* v1.3         marcos.gimeno.tech@bbva.com
* |2023-06-01  Refactoring, format and business logic modifications
* -----------------------------------------------------------------------------------------------
**/
public with sharing class Arc_Gen_AbandonedArce_Batch implements Database.Batchable<SObject>, Database.Stateful, Schedulable {
    /** @description List of errors that occurred during the batch execution **/
    @TestVisible
    private final List<JobError> jobErrors;
    /** @description List of emails to send **/
    private List<arce__AbandonedArce__mdt> arceMetas;

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Constructor initializes class attributes
    * -----------------------------------------------------------------------------------------------
    * @autor       marcos.gimeno.tech@bbva.com
    * @date        2024-06-25
    * -----------------------------------------------------------------------------------------------
    **/
    public Arc_Gen_AbandonedArce_Batch() {
        this.jobErrors = new List<JobError>();
        this.arceMetas = new List<arce__AbandonedArce__mdt>();
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Method to execute the batch
    * -----------------------------------------------------------------------------------------------
    * @autor       marcos.gimeno.tech@bbva.com
    * @date        2024-06-25
    * @param       SchedulableContext scheduleContext The context of the scheduled job
    * -----------------------------------------------------------------------------------------------
    **/
    public void execute(SchedulableContext scheduleContext) {
        Database.executeBatch(new Arc_Gen_AbandonedArce_Batch());
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Method to start the batch
    * -----------------------------------------------------------------------------------------------
    * @autor       marcos.gimeno.tech@bbva.com
    * @date        2024-06-25
    * @param       context The context of the batch
    * @return      Database.QueryLocator The query locator for the batch
    * -----------------------------------------------------------------------------------------------
    **/
    public Database.QueryLocator start(Database.BatchableContext context) {
        this.arceMetas = Arc_Gen_AbandonedArce_Data.getAbandonedArceMeta();
        return Arc_Gen_AbandonedArce_Data.queryLocatorAbandonedBatch(arceMetas);
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Method to execute the batch
    * -----------------------------------------------------------------------------------------------
    * @autor       marcos.gimeno.tech@bbva.com
    * @date        2024-06-25
    * @param       context The context of the batch
    * @param       List<SObject> scope The scope of the batch
    * -----------------------------------------------------------------------------------------------
    **/
    public void execute(Database.BatchableContext context, List<SObject> scope) {
        if (Arc_Gen_AbandonedArce_Service.isValid(scope)) {
            try {
                final List<arce__Analysis__c> analyses = (List<arce__Analysis__c>) scope;
                new Arc_Gen_AbandonedArce_Service()
                    .setBatchParams(analyses, arceMetas)
                    .processBatch()
                    .updateRecordsAndInsertEvents()
                    .sendEmails();
            } catch (Exception exc) {
                handleJobError(scope, exc);
            }
        }
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Method to finish the batch
    * -----------------------------------------------------------------------------------------------
    * @autor       marcos.gimeno.tech@bbva.com
    * @date        2024-06-25
    * @param       context The context of the batch
    * -----------------------------------------------------------------------------------------------
    **/
    public void finish(Database.BatchableContext context) {
        if (Arc_Gen_AbandonedArce_Service.isValid(jobErrors)) {
            for (JobError jobError : jobErrors) {
                System.debug(LoggingLevel.ERROR, 'Error message: ' + jobError.message);
                System.debug(LoggingLevel.ERROR, 'Records: ' + jobError.records);
            }
        }
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Method to handle the job error
    * -----------------------------------------------------------------------------------------------
    * @autor       marcos.gimeno.tech@bbva.com
    * @date        2024-06-25
    * @param       scope The scope of the batch
    * @param       exc The exception that occurred
    * -----------------------------------------------------------------------------------------------
    **/
    private void handleJobError(List<SObject> scope, Exception exc) {
        final JobError jobError = new JobError();
        jobError.records = scope;
        jobError.message = exc.getMessage();
        jobErrors.add(jobError);
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Inner class to represent a job error
    * -----------------------------------------------------------------------------------------------
    * @autor       marcos.gimeno.tech@bbva.com
    * @date        2024-06-25
    * -----------------------------------------------------------------------------------------------
    **/
    public class JobError {
        /** @description The error message **/
        public String message;
        /** @description The records that caused the error **/
        public List<SObject> records;
    }
}