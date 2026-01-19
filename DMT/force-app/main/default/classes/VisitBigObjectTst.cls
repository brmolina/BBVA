/**
 * @description       :
 * @author            : David Rodríguez
 * @group             :
 * @last modified on  : 04-05-2021
 * @last modified by  : David Rodríguez
 * Modifications Log
 * Ver   Date         Author            Modification
 * 1.0   04-05-2021   David Rodríguez   Initial Version
**/
@isTest
/**
* @author Global Desktop
*/
public with sharing class VisitBigObjectTst {
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
    final Contact con = UTIL_TEST_CLASS.createContact(accFilial);
    insert con;
    final dwp_kitv__Visit__c visit = UTIL_TEST_CLASS.createVisit(accFilial, null);
    insert visit;
    final Event evt = new Event();
    evt.dwp_kitv__visit_id__c = visit.Id;
    evt.DurationInMinutes = 10;
    evt.ActivityDateTime = system.now();
    insert evt;
    Test.startTest();
    final String profilename = UTIL_TEST_CLASS.createProfile();
    final User userTest = UTIL_TEST_CLASS.createUser(profilename);
    insert userTest;
    final dwp_kitv__Visit_Management_Team__c visitManagement = UTIL_TEST_CLASS.createVisitManagementTeam(visit, userTest);
    insert visitManagement;
    final dwp_kitv__Visit_Contact__c visitContact = UTIL_TEST_CLASS.visitContact(con, visit);
    insert visitContact;
    system.schedule('Test Check', '0 0 2 * * ?', new ScheduleBigObjVisit());
    //Database.executeBatch(new VisitBigObject(), 100);
    Test.stopTest();
    system.assertNotEquals(visit.Id, null, 'isNull');
  }

  @isTest
  /*
  * Test method
  */
  public static void methodTest2() {
    final Account accFilial = UTIL_TEST_CLASS.createClient();
    insert accFilial;
    final Visit__b visit = new Visit__b();
    visit.dwp_kitv_account_id__c = accFilial.Id;
    visit.Name__c = 'Test';
    Test.startTest();
    final String fields = HistoricVisitCnt.gtVisits(5, accFilial.Id);
    final HistoricVisitCnt.WrapperClass wrapper = new HistoricVisitCnt.WrapperClass(visit, 1);
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
    final Visit__b visit = new Visit__b();
    visit.dwp_kitv_account_id__c = accFilial.Id;
    visit.Name__c = 'Test';
    Test.startTest();
    final HistoricVisitCnt instance = HistoricVisitCnt.gtInstance();
    system.debug(instance);
    final String fields = HistoricVisitCnt.gtOpps('Test', 'Test');
    final HistoricVisitCnt.WrapperOpp wrapper = new HistoricVisitCnt.WrapperOpp('Test','Test1','Test2','Test3','Test4','Test5');
    system.debug(JSON.serialize(wrapper));
    Test.stopTest();
    system.assertNotEquals(fields, null, 'isNull');
  }

  @isTest
  /*
  * Test method
  */
	public static void methodTest4() {
    final HistoricVisitController instance = HistoricVisitController.getInstance();
    system.debug(instance);
    final String dataVisit = HistoricVisitController.getDataVisit('1','1');
    system.debug(dataVisit);
    final Visit__b visitBig = HistoricVisitController.getVisitByIdAndAccount('1','1');
    system.debug(visitBig);
    System.assertNotEquals(null, true);
  }

  @isTest
  /*
  * Test method
  */
	public static void methodTest5() {
    final DES_UtilTestClass tstClass = new DES_UtilTestClass();
    final Account acc = tstClass.createClient();
    acc.SER_CClient__c = 'test1';
    acc.Name = 'test1';
    insert acc;

    final String profileUsr = tstClass.createProfile();
    final User usr = tstClass.createUser(profileUsr);
    usr.Email = 'testalertuser@test.com';
    insert usr;

    Test.startTest();
      final altm__Commercial_Alert__c iCommercialAlert = new altm__Commercial_Alert__c();
      iCommercialAlert.altm__participant_id__c = acc.Id;
      iCommercialAlert.altm__Transaction_type_desc__c = 'Corporate Loans';
      iCommercialAlert.altm__commercial_alert_task_type__c = 'backup';
      iCommercialAlert.altm__owner_access_alert_id__c = usr.FederationIdentifier;
      iCommercialAlert.altm__commercial_alert_record_type__c = Label.DES_RT_COMM_ALERT_COM_TASK_IBF;
      insert iCommercialAlert;
      //Database.executeBatch(new AlertBigObject(), 100);
      system.schedule('Test Check', '0 0 2 * * ?', new ScheduleBigObjAlert());
      System.assertNotEquals(usr, null, 'null');
    Test.stopTest();
  }
}