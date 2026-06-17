/**********************************************************************************
* @author       Global Desktop
* @date         22/12/2020
* @description  Test class for LocalClientSelectCont
**********************************************************************************/
@isTest
public class LocalClientSelectContTst {
  /*
  * TEST2VAR
  */
  public static final String TESTVAR = 'test1';

  /**
  * Test one
  */
  @isTest
  static void testOne() {
    final DES_UtilTestClass tstClass = new DES_UtilTestClass();
    final Account acc = tstClass.createClient();
    acc.g_customer_id__c = TESTVAR;
    acc.Name = TESTVAR;
    insert acc;

    final List<Local_Client__c> listLocales = new List<Local_Client__c>();
    final Local_Client__c lclient1 = new Local_Client__c();
    lclient1.Cib_Client__c = acc.Id;
    lclient1.unique_id__c = 'Test';
    lclient1.country_id__c = 'ES';
    listLocales.add(lclient1);

    final Local_Client__c lclient2 = new Local_Client__c();
    lclient2.Cib_Client__c = acc.Id;
    lclient2.unique_id__c = 'Test2';
    lclient2.country_id__c = 'PE';
    listLocales.add(lclient2);

    final Local_Client__c lclient3 = new Local_Client__c();
    lclient3.Cib_Client__c = acc.Id;
    lclient3.unique_id__c = 'Test3';
    lclient3.country_id__c = 'MX';
    listLocales.add(lclient3);

    final Local_Client__c lclient4 = new Local_Client__c();
    lclient4.Cib_Client__c = acc.Id;
    lclient4.unique_id__c = 'Test4';
    lclient4.country_id__c = 'AR';
    listLocales.add(lclient4);

    final Local_Client__c lclient5 = new Local_Client__c();
    lclient5.Cib_Client__c = acc.Id;
    lclient5.unique_id__c = 'Test5';
    lclient5.country_id__c = 'CH';
    listLocales.add(lclient5);

    final Local_Client__c lclient6 = new Local_Client__c();
    lclient6.Cib_Client__c = acc.Id;
    lclient6.unique_id__c = 'Test6';
    lclient6.country_id__c = 'CO';
    listLocales.add(lclient6);

    final Local_Client__c lclient7 = new Local_Client__c();
    lclient7.Cib_Client__c = acc.Id;
    lclient7.unique_id__c = 'Test7';
    lclient7.country_id__c = 'PY';
    listLocales.add(lclient7);
    insert listLocales;

    final LocalClientSelectCont instance = LocalClientSelectCont.gtInstance();
    final String countries = LocalClientSelectCont.gtLocalCountries(TESTVAR);
    final String lclients = LocalClientSelectCont.gtLocalClients('test1','ES');
    system.debug(instance);
    system.debug(lclients);

    System.assertNotEquals(null, countries, 'msg');

  }

  /**
  * Test two
  */
  @isTest
  static void testTwo() {
    final DES_UtilTestClass tstClass = new DES_UtilTestClass();
    final Account acc = tstClass.createClient();
    acc.g_customer_id__c = TESTVAR;
    acc.Name = TESTVAR;
    insert acc;

    final Local_Client__c lclient1 = new Local_Client__c();
    lclient1.Cib_Client__c = acc.Id;
    lclient1.country_id__c = 'ES';
    insert lclient1;

    final Local_Client__c lclient2 = new Local_Client__c();
    lclient2.Cib_Client__c = acc.Id;
    lclient2.country_id__c = 'PE';
    lclient2.participant_name__c = 'Test';
    insert lclient2;

    lclient1.participant_name__c = 'Test1';
    update lclient1;

    lclient2.participant_name__c = 'Test3';
    update lclient2;

    final LocalClientHandler lclientHandler = LocalClientHandler.gtInstance();
    system.debug(lclientHandler);

    final Local_Client__c lclientaux = [SELECT participant_name__c from Local_Client__c WHERE participant_name__c = 'Test3' LIMIT 1];
    system.assertEquals('Test3', lclientaux.participant_name__c, 'notupdated');

  }

  /**
  * Test three
  */
  @isTest
  static void testThree() {
    final DES_UtilTestClass tstClass = new DES_UtilTestClass();
    final Account acc = tstClass.createClient();
    acc.g_customer_id__c = TESTVAR;
    acc.Name = TESTVAR;
    insert acc;

    final Local_Client__c lclient1 = new Local_Client__c();
    lclient1.Cib_Client__c = acc.Id;
    lclient1.country_id__c = 'ES';
    lclient1.participant_name__c = 'Test';
    lclient1.unique_id__c = 'Test';
    lclient1.Name = 'TestName';
    insert lclient1;

    Database.executeBatch(new LocalClientNameBatch(), 1);

    System.assertNotEquals(null, lclient1, 'notnull');

  }

  /**
  * Test four
  */
  @isTest
  static void testFour() {
    final DES_UtilTestClass tstClass = new DES_UtilTestClass();
    final Account acc = tstClass.createClient();
    acc.g_customer_id__c = TESTVAR;
    acc.Name = TESTVAR;
    insert acc;

    final Local_Client__c lclient1 = new Local_Client__c();
    lclient1.Cib_Client__c = acc.Id;
    lclient1.country_id__c = 'ES';
    lclient1.participant_name__c = 'Test';
    lclient1.unique_id__c = 'Test';
    lclient1.Name = 'TestName';
    lclient1.entity_id__c = '0182';
    insert lclient1;

    final List<Id> localIds = new List<Id>();
    localIds.add(lclient1.Id);

    final DES_Arc_Account_Locator locator = new DES_Arc_Account_Locator();
    final arce.Arc_Gen_ServiceAndSaveResponse result = DES_Arc_Account_Locator.createGroup(null);
    //final arce.Arc_Gen_ServiceAndSaveResponse result1 = DES_Arc_Account_Locator.accountUpdate(null);
    //system.debug(result + ' ' + result1);
    final Map<Id, arce.Arc_Gen_Account_Wrapper> wrapper = locator.getAccountInfoById(localIds);
    System.assertNotEquals(null, wrapper.get(lclient1.Id), 'notnull');

  }

  /**
  * Test five
  */
  @isTest
  static void testFive() {
    final DES_UtilTestClass tstClass = new DES_UtilTestClass();
    final Account acc = tstClass.createClient();
    acc.g_customer_id__c = TESTVAR;
    acc.Name = TESTVAR;
    insert acc;

    final Local_Client__c lclient1 = new Local_Client__c();
    lclient1.Cib_Client__c = acc.Id;
    lclient1.country_id__c = 'ES';
    lclient1.participant_name__c = 'Test';
    lclient1.unique_id__c = 'Test';
    lclient1.Name = 'TestName';
    lclient1.entity_id__c = '0182';
    insert lclient1;

    Local_Client__c lClientAux = [
      SELECT Id, Alpha_Code__c, participant_name__c
      FROM Local_Client__c
      WHERE ID = :lclient1.Id
      LIMIT 1
    ];

    final List<String> localIds = new List<String>();
    localIds.add(lClientAux.Alpha_Code__c);

    final DES_Arc_Account_Locator locator = new DES_Arc_Account_Locator();
    final Map<String, arce.Arc_Gen_Account_Wrapper> wrapper = locator.getAccountByAccNumber(localIds);
    final List<Id> fixedSearchResults = new List<Id>();
    fixedSearchResults.add(lClientAux.Id);
    Test.setFixedSearchResults(fixedSearchResults);
    final List<arce.Arc_Gen_Account_Wrapper> listWrapper = locator.accountsForLookup(lClientAux.participant_name__c);
    system.debug(listWrapper);
    System.assertNotEquals(null, wrapper.get(lClientAux.Alpha_Code__c), 'notnull');
  }
}