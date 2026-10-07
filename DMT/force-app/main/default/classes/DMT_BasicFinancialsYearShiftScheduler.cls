public without sharing class DMT_BasicFinancialsYearShiftScheduler
    implements Schedulable {

    private static final Integer BATCH_SIZE = 200;

    public void execute(SchedulableContext context) {
        Database.executeBatch(
            new DMT_BasicFinancialsYearShiftBatch('Account'),
            BATCH_SIZE
        );

        Database.executeBatch(
            new DMT_BasicFinancialsYearShiftBatch(
                'DMT_Opportunity_Client__c'
            ),
            BATCH_SIZE
        );
    }
}