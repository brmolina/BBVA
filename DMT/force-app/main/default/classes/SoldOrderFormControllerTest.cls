/*****************************************
Name:           SoldOrderFormControllerTest
Description:    Clase de testeo de la clase SoldOrderFormController

********************************************/
@isTest
public with sharing class SoldOrderFormControllerTest {
  
  /*
   *  @author Global Desktop
   *
  **/
  @isTest
  static void testTrigger() {
    final DES_UtilTestClass testClass = new DES_UtilTestClass();
    final String idProfile = testClass.createProfile();
    final User userTest = testClass.createUser(idProfile);
    insert userTest;
    final Account acc = testClass.createClient();
    insert acc;
    final Product2 prod1 = testClass.createProduct(Label.DES_Mergers_Acquisitions);
    insert prod1;
    final PricebookEntry pBookEntry1 = testClass.createPricebookEntry(prod1);
    insert pBookEntry1;
    final Opportunity opp1 = testClass.createOpportunity(acc);
    insert opp1;

    final list<OpportunityLineItem> oppliList = new list<OpportunityLineItem>();
    OpportunityLineItem oppLineItem;
    oppLineItem = testClass.createOppLineItem(opp1, prod1, pBookEntry1);
    oppliList.add(oppLineItem);
    insert oppliList;
    system.runAs(userTest) {
      Test.startTest();
      final Sold_Order__c soldOrder = testClass.createSoldOrder(opp1.Id, acc.Id, 'EUR');
      insert soldOrder;
      soldOrder.Currency__c = 'ARS';
      update soldOrder;
      Test.stopTest();
      final String currISOCODE1 = SoldOrderFormController.obtainOppCurrency(opp1.Id);
      //final String currISOCODE2 = SoldOrderFormController.obtainOppCurrency(opp1.Id + 'FALLA');
      system.debug('::::: currISOCODE1: ' + currISOCODE1);
      //system.debug('::::: currISOCODE2: ' + currISOCODE2);
      system.assertNotEquals(null, soldOrder.Id, 'TEST ERROR - SOLDORDER NULL');

    }
  }
  /*
   *  @author Global Desktop
   *
  **/
  @isTest
  static void testObtainBBVAParticipationPer() {
    final DES_UtilTestClass testClass = new DES_UtilTestClass();
    final String idProfile = testClass.createProfile();
    final User userTest = testClass.createUser(idProfile);
    insert userTest;
    final Account acc = testClass.createClient();
    insert acc;
    final Product2 prod1 = testClass.createProduct(Label.DES_Mergers_Acquisitions);
    insert prod1;
    final PricebookEntry pBookEntry1 = testClass.createPricebookEntry(prod1);
    insert pBookEntry1;
    final Opportunity opp1 = testClass.createOpportunity(acc);
    insert opp1;

    final list<OpportunityLineItem> oppliList = new list<OpportunityLineItem>();
    OpportunityLineItem oppLineItem = testClass.createOppLineItem(opp1, prod1, pBookEntry1);
    oppLineItem.bbva_participation_per__c = 14;
    oppliList.add(oppLineItem);
    insert oppliList;

    system.runAs(userTest) {
      Decimal bbvaParticipationPer = SoldOrderFormController.obtainBBVAParticipationPer(opp1.Id);
    
      system.assertEquals(14, bbvaParticipationPer, 'TEST ERROR - bbvaParticipationPer debe ser 14');
  }
}

}