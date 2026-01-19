/*
* Test Class
*/
@isTest
public class Batch_completeNBCRegOpp_test {

    /*
    * Test method for DES_Batch_Update_ActiveContact
    */
    @isTest
    public static void testBatch() {
        final DES_UtilTestClass testClass = new DES_UtilTestClass();
        final Account acc = testClass.createClient();
        insert acc;
        final Opportunity opp3 = testClass.createOpportunity(acc);
        opp3.DES_Booking_Geography__c = 'Compass';
        insert opp3;
        final Id batchInstanceId = Database.executeBatch(new Batch_completeNBCRegOpp(), 1);
        system.debug('>>>>> id BATCH JO: ' + batchInstanceId);
        system.assertNotEquals(batchInstanceId, null, 'msg1');
    }
    /*
    * Test method for DES_Batch_Update_ActiveContact
    */
    @isTest
    public static void testBatch1() {
        final DES_UtilTestClass testClass = new DES_UtilTestClass();
        final Account acc = testClass.createClient();
        insert acc;
        final Opportunity opp1 = testClass.createOpportunity(acc);
        opp1.DES_Booking_Geography__c = 'AR';
        insert opp1;
        final Id batchInstanceId = Database.executeBatch(new Batch_completeNBCRegOpp(), 1);
        system.debug('>>>>> id BATCH JO: ' + batchInstanceId);
        system.assertNotEquals(batchInstanceId, null, 'msg1');
    }
    /*
    * Test method for DES_Batch_Update_ActiveContact
    */
    @isTest
    public static void testBatch2() {
        final DES_UtilTestClass testClass = new DES_UtilTestClass();
        final Account acc = testClass.createClient();
        insert acc;
        final Opportunity opp2 = testClass.createOpportunity(acc);
        opp2.DES_Booking_Geography__c = 'FR';
        insert opp2;
        final Id batchInstanceId = Database.executeBatch(new Batch_completeNBCRegOpp(), 1);
        system.debug('>>>>> id BATCH JO: ' + batchInstanceId);
        system.assertNotEquals(batchInstanceId, null, 'msg2');
    }
}