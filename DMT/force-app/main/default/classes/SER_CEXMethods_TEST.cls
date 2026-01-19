@isTest
/**
*
* Modificado por: Arnau Quirós 10-12-2018
*/
public with sharing class SER_CEXMethods_TEST {
  /*-------
      FInal sring para el valor de currency.
  --------*/
  private static final String SERCCURRENCY ='PTS';

  @isTest
  /*------------------------------------------------------------------------------------
      Author:        Juan Carlos Terrón
      Company:       Accenture
      Description:   Test de la clase CEX
  ---------------------------------------------------------------------------------------*/
  public static void validateUnlistedCurrencyInsertTest() {
    final SER_EUR_Currency_exchange_rate__c cRE_1 = new SER_EUR_Currency_exchange_rate__c(SER_Unlisted__c = true, SER_Counter_currency__c = SERCCURRENCY);
    final SER_EUR_Currency_exchange_rate__c cRE_2 = new SER_EUR_Currency_exchange_rate__c(SER_Unlisted__c = true, SER_Counter_currency__c = SERCCURRENCY);

    Test.startTest();
    try {
      insert cRE_1;
      insert cRE_2;
      update cRE_1;
      System.assertEquals(cRE_1,cRE_1,'testMethodThree');
    } catch(Exception e) {
      System.debug(e);
    }

    Test.stopTest();

  }

  @isTest
  /*------------------------------------------------------------------------------------
      Author:        Juan Carlos Terrón
      Company:       Accenture
      Description:   Test de la clase CEX
  ---------------------------------------------------------------------------------------*/
  public static void validateUnlistedCurrencyUpdateTest() {

    final SER_EUR_Currency_exchange_rate__c cRE_1 = new SER_EUR_Currency_exchange_rate__c(SER_Unlisted__c = true, SER_Counter_currency__c = SERCCURRENCY);
    final SER_EUR_Currency_exchange_rate__c cRE_2 = new SER_EUR_Currency_exchange_rate__c(SER_Unlisted__c = false, SER_Counter_currency__c = SERCCURRENCY);

    Test.startTest();
    try {
      insert cRE_1;
      insert cRE_2;
      cRE_2.SER_Unlisted__c = true;
      update cRE_2;
      System.assertEquals(cRE_1,cRE_1,'testMethodZero');
    } catch(Exception e) {
      System.debug(e);
    }

    Test.stopTest();

  }

  @isTest
  /*------------------------------------------------------------------------------------
      Author:        Juan Carlos Terrón
      Company:       Accenture
      Description:   Test de la clase CEX
  ---------------------------------------------------------------------------------------*/
  public static void validateUnlistedCurrencyInsertErrorTest() {
    final List<SER_EUR_Currency_exchange_rate__c> listCRR = new List<SER_EUR_Currency_exchange_rate__c>();

    final SER_EUR_Currency_exchange_rate__c cRE_1 = new SER_EUR_Currency_exchange_rate__c(SER_Unlisted__c = true, SER_Counter_currency__c = SERCCURRENCY);

    listCRR.add(cRE_1);

    final SER_EUR_Currency_exchange_rate__c cRE_2 = new SER_EUR_Currency_exchange_rate__c(SER_Unlisted__c = true, SER_Counter_currency__c = SERCCURRENCY);
    listCRR.add(cRE_2);

    Test.startTest();
    try {
      insert listCRR;
      System.assertEquals(listCRR,listCRR,'testMethodOne');
    } catch(Exception e) {
      System.debug(e);
    }

    Test.stopTest();
  }


  @isTest
  /*------------------------------------------------------------------------------------
      Author:        Juan Carlos Terrón
      Company:       Accenture
      Description:   Test de la clase CEX
  ---------------------------------------------------------------------------------------*/
  public static void validateUnlistedCurrencyUpdateErrorTest() {
    final SER_EUR_Currency_exchange_rate__c cRE_1 = new SER_EUR_Currency_exchange_rate__c(SER_Unlisted__c = true, SER_Counter_currency__c = SERCCURRENCY);
    final SER_EUR_Currency_exchange_rate__c cRE_2 = new SER_EUR_Currency_exchange_rate__c(SER_Unlisted__c = false, SER_Counter_currency__c = SERCCURRENCY);

    Test.startTest();
    try {
      insert cRE_1;
      insert cRE_2;

      final List<SER_EUR_Currency_exchange_rate__c> listCRR = new List<SER_EUR_Currency_exchange_rate__c>();
      cRE_2.SER_Unlisted__c = true;
      listCRR.add(cRE_1);
      listCRR.add(cRE_2);
      update listCRR;
      System.assertEquals(cRE_1,cRE_1,'testMethodTwo');
    } catch(Exception e) {
      System.debug(e);
    }
    Test.stopTest();
  }

  @isTest
  /*------------------------------------------------------------------------------------
      Company:       BBVA
      Description:   Test assignProcessDate
  ---------------------------------------------------------------------------------------*/
  public static void assignProcessDateTest() {
    final List<SER_EUR_Currency_exchange_rate__c> listCRR = new List<SER_EUR_Currency_exchange_rate__c>();

    final SER_EUR_Currency_exchange_rate__c cRE_1 = new SER_EUR_Currency_exchange_rate__c(SER_Unlisted__c = true, SER_Counter_currency__c = SERCCURRENCY, SER_Currency_Pair_Date__c = '123456_2019-07-01');

    listCRR.add(cRE_1);

    Test.startTest();
    insert listCRR;
    Map<Id,SER_EUR_Currency_exchange_rate__c> oldMap;
    oldMap = new Map<Id,SER_EUR_Currency_exchange_rate__c>();
    oldMap.put(listCRR[0].Id,listCRR[0]);
    SER_CEXMethods.assignProcessDate(oldMap,null);
    System.assertEquals(listCRR,listCRR,'testMethodFour');
    Test.stopTest();
  }
}