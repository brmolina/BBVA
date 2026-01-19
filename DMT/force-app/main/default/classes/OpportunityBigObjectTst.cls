@isTest
/**
* @author Global Desktop
*/
public with sharing class OpportunityBigObjectTst {
  /*
  * @description Clase auxiliar tests
  */
  private final static DES_UtilTestClass UTIL_TEST_CLASS = new DES_UtilTestClass();
  @isTest
  /*
  * Test method
  */
  public static void methodTest1() {
    final Account accFilial = UTIL_TEST_CLASS.createClient();
    insert accFilial;
    final Opportunity opp = UTIL_TEST_CLASS.createOpportunity(accFilial);
    insert opp;
    final String profilename = UTIL_TEST_CLASS.createProfile();
    final User userTest = UTIL_TEST_CLASS.createUser(profilename);
    insert userTest;
    final DES_Opportunity_Management_member__c memb = UTIL_TEST_CLASS.createOppManagementMember(userTest, opp);
    insert memb;
    final Product2 prod = UTIL_TEST_CLASS.createProduct('Corporate Loans');
    insert prod;
    final PricebookEntry entry = UTIL_TEST_CLASS.createPricebookEntry(prod);
    insert entry;
    final OpportunityLineItem oli = UTIL_TEST_CLASS.createOppLineItem(opp, prod, entry);
    insert oli;
    Test.startTest();
    system.schedule('Test Check', '0 0 2 * * ?', new ScheduleBigObjOpp());
    //Database.executeBatch(new OpportunityBigObject(), 100);
    Test.stopTest();
    system.assertNotEquals(opp.Id, null, 'isNull');
  }

  @isTest
  /*
  * Test method
  */
  public static void methodTest2() {
    final Account accFilial = UTIL_TEST_CLASS.createClient();
    insert accFilial;
    final Opportunity__b opp = new Opportunity__b();
    opp.AccountId__c = accFilial.Id;
    opp.Name__c = 'Test';
    opp.StageName__c = 'Closed Won';
    opp.DES_Booking_Geography__c = 'ES';
    opp.DES_Expected_Probability__c = 100;
    Test.startTest();
    final String fields = HistoricOppsCnt.getOpps(5, accFilial.Id);
    final HistoricOppsCnt.WrapperClass wrapper = new HistoricOppsCnt.WrapperClass(opp, 'España',1);
    system.debug(JSON.serialize(wrapper));
    Test.stopTest();
    system.assertNotEquals(fields, null, 'isNull');
  }

  @isTest
  /*
  * Test method
  */
  public static void methodTest3() {
    final Account accFilial = UTIL_TEST_CLASS.createClient();
    insert accFilial;
    final Opportunity opp = UTIL_TEST_CLASS.createOpportunity(accFilial);
    insert opp;
    final String profilename = UTIL_TEST_CLASS.createProfile();
    final User userTest = UTIL_TEST_CLASS.createUser(profilename);
    insert userTest;
    final DES_Opportunity_Management_member__c memb = UTIL_TEST_CLASS.createOppManagementMember(userTest, opp);
    insert memb;
    final Product2 prod = UTIL_TEST_CLASS.createProduct('Corporate Loans');
    insert prod;
    final PricebookEntry entry = UTIL_TEST_CLASS.createPricebookEntry(prod);
    insert entry;
    final OpportunityLineItem oli = UTIL_TEST_CLASS.createOppLineItem(opp, prod, entry);
    insert oli;
    final Set<Id> oppsIds = new Set<Id>();
    oppsIds.add(opp.Id);
    Test.startTest();
    Database.executeBatch(new OpportunityLineBigObject(oppsIds), 100);
    final HistoricOppsCnt instance = HistoricOppsCnt.gtInstance();
    system.debug(instance);
    final String fields = HistoricOppsCnt.getProducts(opp.Id);
    Test.stopTest();
    system.assertNotEquals(fields, null, 'isNull');
  }
}