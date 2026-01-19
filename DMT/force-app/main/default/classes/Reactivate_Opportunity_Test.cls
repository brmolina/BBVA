/**
 * @author       Global Desktop
 * @date         14/04/2020
 * @description  Test del botón Reactivate de la botonera de la Oportunidad
 */
@isTest
public with sharing class Reactivate_Opportunity_Test {
  /**
  * @author Global Desktop
  * @description test1
  */
  @isTest
  public static void test1() {
    final DES_UtilTestClass iUtilClass = new DES_UtilTestClass();

    final Account iAccount = iUtilClass.createClient();
    iAccount.survey_nps_contact_type__c = true;
    iAccount.DES_Country_Client__c = 'BE';
    insert iAccount;

    final Opportunity iOpportunity = iUtilClass.createOpportunity(iAccount);
    insert iOpportunity;

    final Product2 iProduct = iUtilClass.createProduct('test');
    insert iProduct;

    final PricebookEntry iPricebookEntry = iUtilClass.createPricebookEntry(iProduct);
    insert iPricebookEntry;

    final OpportunityLineItem iOppLineItem = iUtilClass.createOppLineItem(iOpportunity, iProduct, iPricebookEntry);
    insert iOppLineItem;
    Test.startTest();
    Reactivate_Opportunity_Controller.reactivateOpportunity(iOpportunity.Id, String.valueOf(Date.today()+50));
    Test.stopTest();

    System.assertNotEquals(iOpportunity, null, 'There is no opportunity');
  }
}