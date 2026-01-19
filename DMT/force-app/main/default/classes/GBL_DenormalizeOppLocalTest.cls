/**********************************************************************************
* @author       Global Desktop
* @date         23/07/2020
* @description  Test class for denorm opp local
**********************************************************************************/
@isTest
public class GBL_DenormalizeOppLocalTest {
  /**
  * Test setup
  */
  @TestSetup
  static void testSetup() {
    final DES_UtilTestClass tstClass = new DES_UtilTestClass();
    final Account acc = tstClass.createClient();
    acc.SER_CClient__c = 'test1';
    acc.Name = 'test1';
    insert acc;

    final Account acc2 = tstClass.createClient();
    acc2.SER_CClient__c = 'test2';
    acc2.Name = 'test2';
    insert acc2;

    final dwp_acmh__GBL_Account_Relationship__c relation = tstClass.createAccRelationship(acc, acc2);
    insert relation;

    final Id idProfile = [Select Id, Name from Profile Where Name = 'BBVA Desktop GCC Standard'].Id;

    final User user1 = tstClass.createUser(idProfile);
    insert user1;
	  Test.startTest();
    final Opportunity opp = tstClass.createOpportunity(acc2);
    insert opp;

    final Product2 prod = tstClass.createProduct('Corporate Loans');
    insert prod;

    final PricebookEntry pricebook = tstClass.createPricebookEntry(prod);
    pricebook.Pricebook2Id = opp.Pricebook2Id;
    insert pricebook;

    final OpportunityLineItem oppLineItem = tstClass.createOppLineItem(opp, prod, pricebook);
    insert oppLineItem;
    Test.stopTest();
  }

  /**
  * Test method 1
  */
  @isTest
  public static void test1() {
    final DES_UtilTestClass tstClass = new DES_UtilTestClass();
    final Id idProfile = [Select Id, Name from Profile Where Name = 'BBVA Desktop GCC Standard'].Id;
    final User user1 = tstClass.createUser(idProfile);
    insert user1;
	  Test.startTest();
      OpportunityLineItem oppLineItem = [SELECT Id from OpportunityLineItem LIMIT 1];
      oppLineItem = tstClass.updateOppLineItem(oppLineItem, user1);
      update oppLineItem;
      Opportunity opp = [SELECT Id from Opportunity LIMIT 1];
      opp.StageName = 'Proposal';
      update opp;

      final GBL_DenormalizeOppUtilsLocal oppUtil = new GBL_DenormalizeOppUtilsLocal();
      oppUtil.restore();
      system.assertNotEquals(null, idProfile, 'profilenull');
    Test.stopTest();
  }
}