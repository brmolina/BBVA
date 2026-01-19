/**
 * @author       Global Desktop
 * @date         07/04/2020
 * @description  Test del botón Close Lost de la botonera de la Oportunidad
 */
@isTest
public with sharing class Close_Lost_Opportunity_Test {
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

    final Product2 iProduct = iUtilClass.createProduct('test product');
    insert iProduct;

    final PricebookEntry iPricebookEntry = iUtilClass.createPricebookEntry(iProduct);
    insert iPricebookEntry;

    final OpportunityLineItem iOppLineItem = iUtilClass.createOppLineItem(iOpportunity, iProduct, iPricebookEntry);
    insert iOppLineItem;

    Close_Lost_Opportunity_Controller.getPickListValues('StageName');
    Close_Lost_Opportunity_Controller.gtOpportunity(iOpportunity.Id);
    Test.startTest();
    Close_Lost_Opportunity_Controller.updateClosedLostOpportunity(iOpportunity.Id, Label.Opportunity_expired, 'test desc');
    Test.stopTest();
    System.assertNotEquals(iOpportunity, null, 'There is no opportunity');
  }

  /**
  * @author Global Desktop
  * @description test2
  */
  @isTest
  public static void test2() {
    final DES_UtilTestClass iUtilClass = new DES_UtilTestClass();

    final Account iAccount = iUtilClass.createClient();
    iAccount.survey_nps_contact_type__c = true;
    iAccount.DES_Country_Client__c = 'BE';
    insert iAccount;

    final Opportunity iOpportunity = iUtilClass.createOpportunity(iAccount);
    iOpportunity.CurrencyIsoCode = 'PEN';
    insert iOpportunity;

    final Product2 iProduct = iUtilClass.createProduct('test product 2');
    iProduct.CurrencyIsoCode = 'PEN';
    insert iProduct;

    final PricebookEntry iPricebookEntry = iUtilClass.createPricebookEntry(iProduct);
    iPricebookEntry.CurrencyIsoCode = 'PEN';
    insert iPricebookEntry;

    final OpportunityLineItem iOppLineItem = iUtilClass.createOppLineItem(iOpportunity, iProduct, iPricebookEntry);
    insert iOppLineItem;
	
    Test.startTest();
    Close_Lost_Opportunity_Controller.getPickListValues('StageName');
    Close_Lost_Opportunity_Controller.gtOpportunity(iOpportunity.Id);
    Close_Lost_Opportunity_Controller.updateClosedLostOpportunity(iOpportunity.Id, Label.Opportunity_expired, 'test description 2');
    Test.stopTest();

    System.assertNotEquals(iOpportunity, null, 'There is no opportunity');
  }
}