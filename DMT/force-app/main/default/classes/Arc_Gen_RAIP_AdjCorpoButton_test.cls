/**
  * @Description        : Test class of Arc_Gen_RAIP_AdjCorpoButton_controller & Arc_Gen_RAIP_AdjCorpoButton_service
  * @Author             : juanignacio.hita.contractor@bbva.com
  * @Group              : ARCE
  * @Last Modified By   : juanignacio.hita.contractor@bbva.com
  * @Last Modified On   : 28/04/2022 10:00:00
  * @Modification Log   :
  *==============================================================================
  * Ver         Date                     Author                       Modification
  *==============================================================================
  * 1.0      28/04/2022      juanignacio.hita.contractor@bbva.com     Initial Version
  **/
@isTest
public with sharing class Arc_Gen_RAIP_AdjCorpoButton_test {
  /**
  * @Description: String with external id of test group
  */
  static final string GROUP_ID = 'G000001';
  /**
  * @Description: String with external id of test subsidiary
  */
  static final string SUBSIDIARY_ID = 'C000001';
  /*
  * @Description: Name of the sector
  */
  static final String SECTOR_NAME = '1';

  /**
  * @Method:      method that creates the data to use in the test.
  * @Description: testing method.
  */
  @testSetup static void setup() {
    Arc_UtilitysDataTest_tst.setupAcccounts();
    final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{GROUP_ID,SUBSIDIARY_ID});
    final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get(GROUP_ID);
    final arce.Arc_Gen_Account_Wrapper childAccount = groupAccWrapper.get(SUBSIDIARY_ID);

    final arce__Sector__c newSector = arc_UtilitysDataTest_tst.crearSector('Generic', '100;300;400', SECTOR_NAME, null);
    insert newSector;

    final arce__Analysis__c newArce = Arc_UtilitysDataTest_tst.crearArceAnalysis('Arce Analysis', null, groupAccount.accId);
    newArce.arce__anlys_wkfl_sub_process_type__c = arce.Arc_Gen_Constants.SUBPROCESS_NEW;
    newArce.arce__Stage__c = '1';
    newArce.arce__Temporal_status__c = false;
    newArce.arce__analysis_customer_relation_type__c = '01';
    newArce.arce__Group__c = groupAccount.accId;
    insert newArce;

    final arce__Account_has_Analysis__c newAnalysis = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(newSector.id, newArce.Id, groupAccount.accId, SECTOR_NAME);
    newAnalysis.arce__Analysis__c = newArce.Id;
    newAnalysis.arce__Customer__c = groupAccount.accId;
    insert newAnalysis;

    final arce__Account_has_Analysis__c newAnalysis2 = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(newSector.id, newArce.Id, childAccount.accId, SECTOR_NAME);
    newAnalysis2.arce__group_asset_header_type__c = '2';
    newAnalysis2.arce__InReview__c = true;
    newAnalysis2.arce__path__c = 'MAC';
    insert newAnalysis2;

    final UrlsArce__c urlArce1 = new UrlsArce__c(Name = 'OrgUrlRunAway', url__c = 'https://www.bbva.es/');
    insert urlArce1;
    final UrlsArce__c urlArce2 = new UrlsArce__c(Name = 'VfUrlRunAway', url__c = 'https://www.bbva.es/');
    insert urlArce2;
  }

  /**
  * @Method:  Test configLocalUrlOrg method with expected result OK
  * @Description: testing method
  */
  @isTest
  static void testConfigLocalUrlOrgOK() {
    Test.startTest();
      final arce__Account_has_Analysis__c aha = [SELECT Id, Name FROM arce__Account_has_Analysis__c LIMIT 1];
      final Map<String, Object> mapObj = Arc_Gen_RAIP_AdjCorpoButton_Controller.configLocalUrlOrg(aha.Id);
      final Arc_Gen_RatingAsIndepProcess_service.RunWayURLConfig urlConfigs = (Arc_Gen_RatingAsIndepProcess_service.RunWayURLConfig) mapObj.get('runWayURLConfig');
      System.assertEquals('https://www.bbva.es/', urlConfigs.orgURL, 'Url found');
    Test.stopTest();
  }

  /**
  * @Method:  Test configLocalUrlOrg method with expected result KO
  * @Description: testing method
  */
  @isTest
  static void testConfigLocalUrlOrgKO() {
    Test.startTest();
      try {
        final arce__Analysis__c analysis = [SELECT Id, Name FROM arce__Analysis__c LIMIT 1];
        Arc_Gen_RAIP_AdjCorpoButton_Controller.configLocalUrlOrg(analysis.Id);
      } catch (Exception ex) {
        System.assertEquals('Script-thrown exception', ex.getMessage(), 'Script message');
      }
    Test.stopTest();
  }

  /**
  * @Method:  Test handleRedirect method with expected result OK
  * @Description: testing method
  */
  @isTest
  static void testHandleRedirectOK() {
    Test.startTest();
      final arce__Account_has_Analysis__c aha = [SELECT Id, Name FROM arce__Account_has_Analysis__c LIMIT 1];
      final Boolean retVal = Arc_Gen_RAIP_AdjCorpoButton_Controller.handleRedirect(aha.Id);
      System.assert(true, retVal);
    Test.stopTest();
  }

  /**
  * @Method:  Test handleRedirect method with expected result KO
  * @Description: testing method
  */
  @isTest
  static void testHandleRedirectKO() {
    Test.startTest();
      try {
        final arce__Analysis__c analysis = [SELECT Id, Name FROM arce__Analysis__c LIMIT 1];
        Arc_Gen_RAIP_AdjCorpoButton_Controller.handleRedirect(analysis.Id);
      } catch (Exception ex) {
        System.assertEquals('Script-thrown exception', ex.getMessage(), 'Script message');
      }
    Test.stopTest();
  }

}