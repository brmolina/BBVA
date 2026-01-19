/*
 * Test class
 */
@isTest
public class DES_Batch_updateSubsidiaryFields_TEST {
  /*
   * Test method 1
   */
  @isTest
  public static void methodTest() {
    final DES_UtilTestClass utilTest = new DES_UtilTestClass();
    final Account acc1 = utilTest.createClient();
    insert acc1;
    final Account acc2 = utilTest.createClient();
    insert acc2;
    final Account acc3 = utilTest.createClient();
    acc3.DES_Structure_Type__c = Label.DES_STR_TYPE_Group;
    insert acc3;
    final Account acc4 = utilTest.createClient();
    insert acc4;
    final String idProfile = utilTest.createProfile();
    final User user = utilTest.createUser(idProfile);
    insert user;

    final DES_Subsidiary_Group_Relation__c matrix = utilTest.createSubsidiaryGroupRelation(acc2, acc1);
    insert matrix;

    Test.startTest();
    Id batchJobContactScope = Database.executeBatch(new DES_Batch_updateSubsidiaryFields(), 1);
    System.assertNotEquals(null, batchJobContactScope, 'notnull');
    Test.stopTest();
  }

  /*
   * Test method 2
   */
  @isTest
  public static void methodTest1() {
    final DES_UtilTestClass utilTest = new DES_UtilTestClass();
    final Account acc3 = utilTest.createClient();
    acc3.DES_Structure_Type__c = Label.DES_STR_TYPE_Group;
    insert acc3;
    Test.startTest();
    Id batchJobContactScope = Database.executeBatch(new DES_Batch_updateSubsidiaryFields(), 1);
    System.assertNotEquals(null, batchJobContactScope, 'notnull');
    Test.stopTest();
  }

  /*
   * Test method 3
   */
  @isTest
  public static void methodTest2() {
    final DES_UtilTestClass utilTest = new DES_UtilTestClass();
    final Account acc4 = utilTest.createClient();
    insert acc4;
    Test.startTest();
    Id batchJobContactScope = Database.executeBatch(new DES_Batch_updateSubsidiaryFields(), 1);
    System.assertNotEquals(null, batchJobContactScope, 'notnull');
    Test.stopTest();
  }
}