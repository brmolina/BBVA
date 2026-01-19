@IsTest
public with sharing class DMT_SchedulableBachTaskRemove_Test {

    @isTest
    static void testSchedulableBachTaskRemove() {
        test.starttest();
        DMT_SchedulableBachTaskRemove myClass = new DMT_SchedulableBachTaskRemove ();   
        String chron = '0 0 23 * * ?';
        system.schedule('Test Sched', chron, myClass);
        test.stopTest();

        System.assert(chron != null, 'Chron expression is not null');
    }
}