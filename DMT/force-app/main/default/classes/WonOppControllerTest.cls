/**
 * @author       Global Desktop
 * @date         07/04/2020
 * @description  Test del botón Won Opportunity de la botonera de la Oportunidad
 */
@isTest
public with sharing class WonOppControllerTest {

  @isTest
  static void testmethodOne() {
    final DES_UtilTestClass utils = new DES_UtilTestClass();
    final Account acc = utils.createClient();
    insert acc;
    final Opportunity opp = utils.createOpportunity(acc);
    opp.opportunity_correct_ind_type__c = true;
    insert opp;
    Test.startTest();
    final Opportunity opptest = WonOppController.gtData(opp.Id);
    system.assert(opptest.opportunity_correct_ind_type__c, 'not true');
    Test.stopTest();
  }

  @isTest
  static void testmethodTwo() {
    Test.startTest();
    try {
      WonOppController.gtData('test');
    } catch(Exception err) {
      system.assertEquals('Script-thrown exception', err.getMessage(), 'no data');
      system.debug('Exception -> '+ err.getMessage());
    }
    Test.stopTest();
  }

  @isTest
  static void testmethodThree() {
    Test.startTest();
    try {
      WonOppController.saveOpportunity('test');
    } catch(Exception err) {
      system.assertEquals('Script-thrown exception', err.getMessage(), 'no data');
      system.debug('Exception -> '+ err.getMessage());
    }
    Test.stopTest();
  }

  @isTest
  static void testmethodFour() {
    final DES_UtilTestClass utils = new DES_UtilTestClass();
    final Account acc = utils.createClient();
    insert acc;
    final Opportunity opp = utils.createOpportunity(acc);
    opp.opportunity_correct_ind_type__c = true;
    insert opp;
    final Product2 product = utils.createProduct(Label.DES_Project_Finance_Advisory);
    insert product;
    final PricebookEntry pricebookEntry = utils.createPricebookEntry(product);
    insert pricebookEntry;
    final String profileTest = utils.createProfile();
    final User userTest = utils.createUser(profileTest);
    insert userTest;

    OpportunityLineItem oppLineItem = utils.createOppLineItem(opp, product, pricebookEntry);
    oppLineItem = utils.updateOppLineItem(oppLineItem, userTest);
    oppLineItem.customer_cib_ind_type__c = 'No';
    insert oppLineItem;

    Test.startTest();
    WonOppController.saveOpportunity(opp.Id);
    final Opportunity opptest = WonOppController.gtData(opp.Id);
    system.assertEquals(Label.DES_Closed_Won, opptest.StageName, 'not won');
    Test.stopTest();
  }

  @isTest
  static void testmethodFive() {
    Test.startTest();
    final Map<String, Decimal> mapCurrencyType = WonOppController.gtCurrencyData();
    system.assert(mapCurrencyType != null, 'mapCurrencyType null');
    Test.stopTest();
  }
}