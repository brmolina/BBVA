@isTest
/*
 *  Global Desktop
 *
 */
public class Batch_UpdateSub_Total_Won_Test {
/*
   * Test method 1
   */
  @isTest
  public static void methodTest() {
    final DES_UtilTestClass utilClass = new DES_UtilTestClass();
    final Profile prof = [select Id FROM Profile WHERE Name = 'BBVA Desktop GTB Business Development' LIMIT 1];
    final User userTest = utilClass.createUser(prof.Id);
    insert userTest;
    final CIB_User_Org__c userSettings = utilClass.createCustomSetting();
    insert userSettings;
    system.runAs(userTest) {
    	final list<Account> listAcc = new list<Account>();
    	final Account acc1 = utilClass.createClient();
        acc1.DES_Structure_Type__c = Label.DES_STR_TYPE_Group;
        listAcc.add(acc1);    
        final Account acc2 = utilClass.createClient();
        listAcc.add(acc2);
        final Account acc3 = utilClass.createClient();
        acc3.DES_Structure_Type__c = Label.DES_STR_TYPE_Group;
        listAcc.add(acc3);
        final Account acc4 = utilClass.createClient();
        listAcc.add(acc4);
        insert listAcc;
        final DES_Subsidiary_Group_Relation__c matrix = utilClass.createSubsidiaryGroupRelation(acc2, acc1);
        insert matrix;
        final Opportunity opp1 = utilClass.createOpportunity(acc1);
        insert opp1;
        final dwp_acmh__Denorm_Account_Opportunity__c oppDenorm = new dwp_acmh__Denorm_Account_Opportunity__c ();
        oppDenorm.dwp_acmh__AccountId__c = acc1.Id;
        oppDenorm.dwp_acmh__OpportunityId__c = opp1.Id;
        insert oppDenorm;
      }


    Test.startTest();
    Id batchJobContactScope = Database.executeBatch(new Batch_UpdateSubsidiary_Total_Won_opps(), 1);
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
    Id batchJobContactScope = Database.executeBatch(new Batch_UpdateSubsidiary_Total_Won_opps(), 1);
    System.assertNotEquals(null, batchJobContactScope, 'notnull');
    Test.stopTest();
  }
}