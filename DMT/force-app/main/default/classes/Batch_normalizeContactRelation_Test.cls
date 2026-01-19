/*
* Test Class
*/
@isTest
public class Batch_normalizeContactRelation_Test {

    /*
    * Test method for DES_Batch_Update_ActiveContact
    */
    @isTest
    public static void testBatch() {

        final DES_UtilTestClass testClass = new DES_UtilTestClass();
        final Account acc = testClass.createClient();
        insert acc;
        final Account acc2 = testClass.createClient();
        insert acc2;
        final dwp_acmh__GBL_Account_Relationship__c relation = testClass.createAccRelationship(acc2, acc);
        insert relation;
        final Contact con = testClass.createContact(acc);
        insert con;
        final AccountContactRelation contactrelation = [SELECT Id, contactId, accountId from AccountContactRelation where contactId = :con.Id and accountId = :acc2.Id LIMIT 1];
        delete contactrelation;
        final Id batchInstanceId = Database.executeBatch(new Batch_normalizeContactRelation(), 1);
        system.assertNotEquals(batchInstanceId, null, 'msg');
    }
}