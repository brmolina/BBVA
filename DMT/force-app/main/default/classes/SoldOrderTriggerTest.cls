/*****************************************
Name:           SoldOrderTriggerTest
Description:    Clase de testeo del trigger de Sold Order
                    Este test se encarga de cubrir las siguientes clases:
                      - SoldOrderTrigger.trigger
                      - SoldOrderTriggerHandler.cls
                      - SoldOrderTriggerHelper.cls

********************************************/
@isTest
public with sharing class SoldOrderTriggerTest {
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
      system.assertNotEquals(null, soldOrder.Id, 'TEST ERROR - SOLDORDER NULL');

    }
  }

}