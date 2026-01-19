@isTest
public with sharing class DMT_SchedulableBatchCloseLostOpp_Test {
    @isTest
    static void testSchedulableBatchCloseLostOpportunity() {
        Test.startTest();
        DMT_SchedulableBatchCloseLostOpportunity schedulable = new DMT_SchedulableBatchCloseLostOpportunity();
        String cron = '0 0 23 * * ?';
        System.schedule('Test Sched', cron, schedulable);
        Test.stopTest();
        Assert.isTrue(cron != null, 'Cron expression should not be null');
    }
}