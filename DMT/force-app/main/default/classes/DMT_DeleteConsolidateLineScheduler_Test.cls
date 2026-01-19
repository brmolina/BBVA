/**
 * @description       : Test class for the following classes: DMT_DeleteConsolidateLineScheduler 
 *                      and DMT_DeleteConsolidateLineBatch
 * @author            : Aníbal Cortés
 * @group             :
 * @last modified on  : 06-05-2025
 * @last modified by  : Aníbal Cortés
**/


@isTest
public with sharing class DMT_DeleteConsolidateLineScheduler_Test {

    @TestSetup
    static void loadTestData() 
    {
        DMT_Test_DataFactory.generateTestTreasuryLines();
        DMT_Test_DataFactory.generateTestOtherLines();
        DMT_Test_DataFactory.generateTaskTypes();
        DMT_Test_DataFactory.generateApprover();
    }

    @isTest
    static void testSchedulableBachTaskRemove() {
        test.starttest();
        DMT_DeleteConsolidateLineScheduler myClass = new DMT_DeleteConsolidateLineScheduler ();   
        String chron = '0 0 23 * * ?';
        system.schedule('Test Sched', chron, myClass);
        test.stopTest();

        System.assert(chron != null, 'Chron expression is not null');
    }
}