/**
  * @File Name          : Arc_Gen_ScheduleInSan_Controller_Test.cls
  * @Description        :
  * @Author             : luisarturo.parra.contractor@bbva.com
  * @Group              :
  * @Last Modified By   : luisruben.quinto.munoz@bbva.com
  * @Last Modified On   : 27/8/2019 17:58:58
  * @Modification Log   :
  *==============================================================================
  * Ver         Date                     Author                 Modification
  *==============================================================================
  * 1.0    5/7/2019 12:50:32   luisarturo.parra.contractor@bbva.com     Initial Version
  * 1.1    27/8/2019 13:04:49  luisruben.quinto.munoz@bbva.com          deletes reference to arce__Id__c
  * 1.2    23/09/2020          saimassimilianno.jordana.contractor@bbva.com Added arce. namespace to all classes that are now in the arce-dependencies package
  * 1.3    02/02/2021 17:12:00 luisdavid.rivera.ortiz@bbva.com          Eliminated unused fields
  * 1.4    18/02/2021          joseluis.garcia4.contractor@bbva.com     Fix tests for action persistence service.
  * 1.5    16/07/2021          juanignacio.hita.contractor@bbva.com	    Adds true value in In_Review field for aha group
  **/
@isTest
public class Arc_Gen_ScheduleInSanction_Con_Test {

  @TestSetup
  static void setup() {
    Arc_UtilitysDataTest_tst.setupAcccounts();
    final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{'G000001'});
    final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get('G000001');
    arce__Analysis__c arceobj = new arce__Analysis__c();
    arceobj.Name = 'arce__Analysisobj';
    arceobj.arce__analysis_customer_relation_type__c = '01';
    arceobj.CurrencyIsoCode = 'EUR';
    arceobj.arce__Group__c = groupAccount.accId;
    arceobj.arce__Stage__c = '1';
    arceobj.arce__wf_status_id__c = '02';
    arceobj.arce__bbva_committees_type__c = '2';
    arceobj.arce__anlys_wkfl_sub_process_type__c = arce.Arc_Gen_Constants.SUBPROCESS_NEW;
    insert arceobj;
    arce__Analysis__c arceobj2 = new arce__Analysis__c();
    arceobj2.Name = 'arce__Analysisobj';
    arceobj2.arce__analysis_customer_relation_type__c = '01';
    arceobj2.CurrencyIsoCode = 'EUR';
    arceobj2.arce__Group__c = groupAccount.accId;
    arceobj2.arce__Stage__c = '1';
    arceobj2.arce__wf_status_id__c = '05';
    arceobj2.arce__bbva_committees_type__c = '2';
    arceobj2.arce__anlys_wkfl_sub_process_type__c = arce.Arc_Gen_Constants.SUBPROCESS_NEW;
    insert arceobj2;
    final List<arce__Analysis__c> anData = [select id, arce__Group__c, arce__wf_status_id__c FROM arce__Analysis__c LIMIT 2];
    final arce__Account_has_Analysis__c ahaToInsert = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(null, anData[0].Id, anData[0].arce__Group__c, null);
    ahaToInsert.arce__group_asset_header_type__c = arce.Arc_Gen_Constants.GROUP_ASSET_HEADER_TYPE_HEADER;
    ahaToInsert.arce__InReview__c = true;
    final arce__Account_has_Analysis__c ahaToInsert2 = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(null, anData[1].Id, anData[1].arce__Group__c, null);
    ahaToInsert2.arce__group_asset_header_type__c = arce.Arc_Gen_Constants.GROUP_ASSET_HEADER_TYPE_HEADER;
    ahaToInsert2.arce__InReview__c = true;
    insert ahaToInsert;
    insert ahaToInsert2;
  }
  /**
  * @Method:      test for method update committtee OK
  * @Description: testing method.
  */
  @isTest
  public static void testUpdateCommittee() {
    List<arce__Account_has_Analysis__c> ahaToInsert = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 2];
    Test.startTest();
    Arc_Gen_ScheduleInSanction_Controller.updateCommittee('1', ahaToInsert[0].Id, 'TEST');
    Arc_Gen_ScheduleInSanction_Controller.updateCommittee('1', ahaToInsert[1].Id, 'TEST');
    try {
      Arc_Gen_ScheduleInSanction_Controller.updateCommittee(null, null, null);
    } catch (Exception ex) {
      System.assert(ex.getMessage().contains('Script'), 'Script-thrown exception');
    }
    Test.stopTest();
  }
  /**
  * @Method:      test for method constructor controller
  * @Description: testing method.
  */
  @isTest static void testContructorData() {
    Test.startTest();
    final Arc_Gen_ScheduleInSanction_Controller data = new Arc_Gen_ScheduleInSanction_Controller();
    System.assertEquals(data, data, 'The test to void contructor was successfull');
    Test.stopTest();
  }
  /**
  * @Method:      test for method constructor service
  * @Description: testing method.
  */
  @isTest static void testContructorServiceData() {
    Test.startTest();
    final Arc_Gen_ScheduleInSanction_Service data = new Arc_Gen_ScheduleInSanction_Service();
    System.assertEquals(data, data, 'The test to void contructor was successfull');
    Test.stopTest();
  }
  /**
  * @Method:      test for method initDelegation
  * @Description: testing method.
  */
  @isTest static void testInitDelegationOK() {
    arce__Account_has_Analysis__c ahaToInsert = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
    Test.startTest();
    final String ret = Arc_Gen_ScheduleInSanction_Controller.initDelegation(ahaToInsert.Id);
    final Arc_Gen_Delegation_Wrapper wrapperRet = (Arc_Gen_Delegation_Wrapper) JSON.deserialize((String) ret, Arc_Gen_Delegation_Wrapper.class);
    System.assertEquals(wrapperRet.codStatus, 200, 'init delegation test');
    try {
      Arc_Gen_ScheduleInSanction_Controller.initDelegation(null);
    } catch (Exception ex) {
      System.assert(ex.getMessage().contains('Script'), 'Script-thrown exception');
    }
    Test.stopTest();
  }
}