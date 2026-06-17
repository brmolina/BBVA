/**********************************************************************************
* @author       Global Desktop
* @date         12/04/2020
* @description  Test for batch Migration alert
**********************************************************************************/
@isTest
public with sharing class DES_AlertMigrationTest {

  /*
  * Commercial alert String
  */
  final static String TESTSTRING = 'Test';

  /*
  * Setup test
  */
  @testSetup
  static void setup() {
    final CIB_Bypass__c byPass = CIB_Bypass__c.getInstance();
    byPass.CIB_Skip_Commercial_Alert_trigger__c = true;
    insert byPass;
    final DES_UtilTestClass utils = new DES_UtilTestClass();
    final String profile = utils.createProfile();
    final User iUserStandard = utils.createUserWithProfileName('BBVA Desktop GCC Standard', 'testuser+gccstandarduser@test.com');
    insert iUserStandard;
    final User user1 = utils.createUser(profile, 'testtest0@test.com');
    user1.Email += '1';
    insert user1;

    final Account acc = utils.createClient();
    acc.g_customer_id__c = 'test1';
    acc.Name = 'test1';
    acc.DES_Tier__c = '00000020'; //CIB-Platinum
    insert acc;
    final Opportunity opp = utils.createOpportunity(acc);
    insert opp;
    final DES_BBVA_Management_team__c iBBVATeam3 = utils.createBBVAManagementTeamMember(iUserStandard, acc);
    insert iBBVATeam3;

    final List<almd__Commercial_Alert__c> alerts = new List<almd__Commercial_Alert__c>();
    final almd__Commercial_Alert__c alertOld1 = utils.createAlert(user1, iUserStandard, acc, 1, 'Commercial Task GF');
    final almd__Commercial_Alert__c alertOld2 = utils.createAlert(user1, iUserStandard, acc, 2, 'Commercial Task GTB');
    alerts.add(alertOld1);
    alerts.add(alertOld2);
    insert alerts;
    final List<altm__Commercial_Alert__c> alertsNew = new List<altm__Commercial_Alert__c>();
    final altm__Commercial_Alert__c alertNew1 = utils.createNewAlert(user1, iUserStandard, acc, 1, 'Commercial Task');
    final altm__Commercial_Alert__c alertNew2 = utils.createNewAlert(user1, iUserStandard, acc, 2, 'Commercial Task');
    alertNew1.altm__commercial_alert_id__c = alertOld1.almd__commercial_alert_id__c;
    alertNew2.altm__commercial_alert_id__c = alertOld2.almd__commercial_alert_id__c;
    alertsNew.add(alertNew1);
    alertsNew.add(alertNew2);
    insert alertsNew;
  }

  /*
  * testMethodOne test
  */
  @isTest
  private static void testMethodOne() {
    final List<almd__Commercial_Alert__c> alertsUpdt = [
      SELECT id, almd__client_process_accepted_type__c, almd__mandatory_visit_type__c, almd__execution_indicator_type__c,
      almd__alert_stage_type__c, almd__alert_sub_stage_type__c
      FROM almd__Commercial_Alert__c LIMIT 200
    ];
    Test.startTest();
    alertsUpdt.get(0).almd__client_process_accepted_type__c = true;
    update alertsUpdt.get(0);
		final Id batchInstanceId2 = Database.executeBatch(new DES_AlertMigration(), 2000);
		system.debug('>>>>> id BATCH JO: ' + batchInstanceId2);
		System.assertNotEquals(batchInstanceId2, null);
		Test.stopTest();
  }

  /*
  * testMethodTwo test
  */
 /*  @isTest
  private static void testMethodTwo() {
    final DES_UtilTestClass utils = new DES_UtilTestClass();
    //final User user1 = [SELECT Id from User LIMIT 1];
    final User iUserStandard = [SELECT Id FROM User WHERE UserName = 'testuser+gccstandarduser@test.com' LIMIT 1];
    system.runAs(iUserStandard) {
      final almd__Commercial_Alert__c alertOld2 = [SELECT Id FROM almd__Commercial_Alert__c WHERE almd__commercial_alert_id__c = 'Id2' LIMIT 1];
      //final Opportunity opp = utils.createOpportunity(acc);
      final Opportunity opp = [SELECT Id,almd__commercial_alert_id__c,StageName, opportunity_correct_ind_type__c  FROM Opportunity WHERE Account.Name  = 'test1' LIMIT 1];
      opp.almd__commercial_alert_id__c = alertOld2.Id;
      update opp;
      final Product2 prod = utils.createProduct('Corporate Loans');
      insert prod; 
      final PricebookEntry entry = utils.createPricebookEntry(prod);
      insert entry;
      OpportunityLineItem oli = utils.createOppLineItem(opp, prod, entry);
      oli = utils.updateOppLineItem(oli, null);
      insert oli;
      opp.StageName = 'Closed Won';
      opp.opportunity_correct_ind_type__c = true;
      update opp;
      alertOld2.almd__execution_indicator_type__c = TESTSTRING;
      alertOld2.almd__mandatory_visit_type__c = 'No';
      alertOld2.almd__alert_stage_type__c = Label.DES_CLOSED;
      alertOld2.almd__alert_sub_stage_type__c = 'Won';
      Test.startTest();
      update alertOld2;
    }
    final Id batchInstanceId2 = Database.executeBatch(new DES_AlertMigration(), 2);
    system.debug('batch2 ' + batchInstanceId2);
    Test.stopTest();
    final altm__Commercial_Alert__c alertOld3 = [SELECT Id, altm__alert_stage_type__c FROM altm__Commercial_Alert__c WHERE altm__commercial_alert_id__c = 'Id2' LIMIT 1];
    system.debug('alertOld3.altm__alert_stage_type__c ' + alertOld3.altm__alert_stage_type__c);
    System.assertEquals(alertOld3.altm__alert_stage_type__c, Label.COMMERCIAL_ALERT_STATUS_MANAGED, 'NotManaged');
  } */

  /*
  * testMethodThree test
  */
  @isTest
  private static void testMethodThree() {
    final DES_UtilTestClass utils = new DES_UtilTestClass();
    final Account acc = [SELECT Id FROM Account WHERE Name = 'test1' LIMIT 1];
    final User iUserStandard = [SELECT Id FROM User WHERE UserName = 'testuser+gccstandarduser@test.com' LIMIT 1];
    system.runAs(iUserStandard) {
      final List<almd__Commercial_Alert__c> alertsOld = [
        SELECT Id, almd__client_process_accepted_type__c, almd__execution_indicator_type__c, almd__mandatory_visit_type__c,
        almd__alert_stage_type__c, almd__alert_sub_stage_type__c, almd__commercial_alert_id__c
        FROM almd__Commercial_Alert__c WHERE almd__commercial_alert_id__c IN ('Id1','Id2')];
      Test.startTest();
      final Opportunity opp = utils.createOpportunity(acc);
      opp.almd__commercial_alert_id__c = alertsOld.get(1).Id;
      insert opp;
      final dwp_kitv__Visit__c visit = utils.createVisit(acc, null);
      visit.almd__commercial_alert_id__c = alertsOld.get(1).Id;
      insert visit;
      alertsOld.get(0).almd__client_process_accepted_type__c = true;
      alertsOld.get(0).almd__execution_indicator_type__c = TESTSTRING;
      alertsOld.get(0).almd__mandatory_visit_type__c = 'No';
      alertsOld.get(0).almd__alert_stage_type__c = 'In progress';
      alertsOld.get(0).almd__alert_sub_stage_type__c = 'Client accepted';
      alertsOld.get(1).almd__client_process_accepted_type__c = true;
      alertsOld.get(1).almd__execution_indicator_type__c = TESTSTRING;
      alertsOld.get(1).almd__mandatory_visit_type__c = 'No';
      alertsOld.get(1).almd__alert_stage_type__c = 'In progress';
      alertsOld.get(1).almd__alert_sub_stage_type__c = 'Client accepted';
      update alertsOld;
    }
    final Id batchInstanceId2 = Database.executeBatch(new DES_AlertMigration(), 2000);
    system.debug('batchIns ' + batchInstanceId2);
    Test.stopTest();
    final altm__Commercial_Alert__c alertOld3 = [SELECT Id, altm__alert_stage_type__c FROM altm__Commercial_Alert__c WHERE altm__commercial_alert_id__c = 'Id1' LIMIT 1];
    system.debug('alertOld3.altm__alert_stage_type__c ' + alertOld3.altm__alert_stage_type__c);
    System.assertEquals(alertOld3.altm__alert_stage_type__c, Label.COMMERCIAL_ALERT_STATUS_PENDING, 'NotPending');
  }

  /*
  * testMethodFour test
  */
  @isTest
  private static void testMethodFour() {
    final User iUserStandard = [SELECT Id FROM User WHERE UserName = 'testuser+gccstandarduser@test.com' LIMIT 1];
    system.runAs(iUserStandard) {
      final List<almd__Commercial_Alert__c> alertsOld = [
        SELECT Id, almd__client_process_accepted_type__c, almd__execution_indicator_type__c, almd__mandatory_visit_type__c,
        almd__alert_stage_type__c, almd__alert_sub_stage_type__c, almd__commercial_alert_id__c
        FROM almd__Commercial_Alert__c WHERE almd__commercial_alert_id__c IN ('Id1','Id2')];
      Test.startTest();
      alertsOld.get(0).almd__client_process_accepted_type__c = true;
      alertsOld.get(0).almd__execution_indicator_type__c = TESTSTRING;
      alertsOld.get(0).almd__mandatory_visit_type__c = 'No';
      alertsOld.get(0).almd__alert_stage_type__c = Label.DES_CLOSED;
      alertsOld.get(0).almd__alert_sub_stage_type__c = Label.COMMERCIAL_ALERT_STATUS_DISCARDED;
      alertsOld.get(0).almd__Rejection_reason_desc__c = 'The alert was matured, its end date was 1/1/1970';
      alertsOld.get(1).almd__client_process_accepted_type__c = true;
      alertsOld.get(1).almd__execution_indicator_type__c = TESTSTRING;
      alertsOld.get(1).almd__mandatory_visit_type__c = 'No';
      alertsOld.get(1).almd__alert_stage_type__c = Label.DES_CLOSED;
      alertsOld.get(1).almd__alert_sub_stage_type__c = Label.COMMERCIAL_ALERT_STATUS_DISCARDED;
      alertsOld.get(1).almd__Rejection_reason_desc__c = 'The alert was matured, its end date was 1/1/2020';
      update alertsOld;
    }
    final Id batchInstanceId2 = Database.executeBatch(new DES_AlertMigration(), 2000);
    system.debug('batchInstanceId2 ' + batchInstanceId2);
    Test.stopTest();
    final altm__Commercial_Alert__c alertOld3 = [SELECT Id, altm__alert_stage_type__c FROM altm__Commercial_Alert__c WHERE altm__commercial_alert_id__c = 'Id1' LIMIT 1];
    system.debug('alertOld3.altm__alert_stage_type__c ' + alertOld3.altm__alert_stage_type__c);
    System.assertEquals(alertOld3.altm__alert_stage_type__c, Label.COMMERCIAL_ALERT_STATUS_DISABLED, 'NotDisabled');
  }

  /*
  * testMethodFive test
  */
  @isTest
  private static void testMethodFive() {
    final User iUserStandard = [SELECT Id FROM User WHERE UserName = 'testuser+gccstandarduser@test.com' LIMIT 1];
    system.runAs(iUserStandard) {
      final List<almd__Commercial_Alert__c> alertsOld = [
        SELECT Id, almd__client_process_accepted_type__c, almd__execution_indicator_type__c, almd__mandatory_visit_type__c,
        almd__alert_stage_type__c, almd__alert_sub_stage_type__c, almd__commercial_alert_id__c
        FROM almd__Commercial_Alert__c WHERE almd__commercial_alert_id__c IN ('Id1','Id2')];
      Test.startTest();
      alertsOld.get(0).almd__client_process_accepted_type__c = true;
      alertsOld.get(0).almd__execution_indicator_type__c = TESTSTRING;
      alertsOld.get(0).almd__mandatory_visit_type__c = 'No';
      alertsOld.get(0).almd__alert_stage_type__c = Label.DES_CLOSED;
      alertsOld.get(0).almd__alert_sub_stage_type__c = Label.COMMERCIAL_ALERT_STATUS_DISCARDED;
      alertsOld.get(0).almd__BBVA_rejection_reason_desc__c = 'Risk not approved';
      alertsOld.get(0).almd__Others_rejection_reason_desc__c = 'Others';
      alertsOld.get(0).almd__Client_rejection_reason_desc__c = 'Deal';
      alertsOld.get(1).almd__client_process_accepted_type__c = true;
      alertsOld.get(1).almd__execution_indicator_type__c = TESTSTRING;
      alertsOld.get(1).almd__mandatory_visit_type__c = 'No';
      alertsOld.get(1).almd__alert_stage_type__c = Label.DES_CLOSED;
      alertsOld.get(1).almd__alert_sub_stage_type__c = Label.COMMERCIAL_ALERT_STATUS_DISCARDED;
      alertsOld.get(1).almd__BBVA_rejection_reason_desc__c = 'Pricing';
      alertsOld.get(1).almd__Others_rejection_reason_desc__c = 'Others';
      alertsOld.get(1).almd__Client_rejection_reason_desc__c = 'Deal';
      update alertsOld;
    }
    final Id batchInstanceId2 = Database.executeBatch(new DES_AlertMigration(), 2000);
    system.debug('batch ' + batchInstanceId2);
    Test.stopTest();
    final altm__Commercial_Alert__c alertOld3 = [SELECT Id, altm__alert_stage_type__c, altm__BBVA_rejection_reason_desc__c FROM altm__Commercial_Alert__c WHERE altm__commercial_alert_id__c = 'Id1' LIMIT 1];
    system.debug('alertOld3.altm__BBVA_rejection_reason_desc__c ' + alertOld3.altm__BBVA_rejection_reason_desc__c);
    System.assertEquals(alertOld3.altm__BBVA_rejection_reason_desc__c, 'No possible action - Risk limitation', 'NotRisk');
  }

  /*
  * testMethodSix test
  */
  @isTest
  private static void testMethodSix() {
    final User iUserStandard = [SELECT Id FROM User WHERE UserName = 'testuser+gccstandarduser@test.com' LIMIT 1];
    system.runAs(iUserStandard) {
      final List<almd__Commercial_Alert__c> alertsOld = [
        SELECT Id, almd__client_process_accepted_type__c, almd__execution_indicator_type__c, almd__mandatory_visit_type__c,
        almd__alert_stage_type__c, almd__alert_sub_stage_type__c, almd__commercial_alert_id__c
        FROM almd__Commercial_Alert__c WHERE almd__commercial_alert_id__c IN ('Id1','Id2')];
      Test.startTest();
      alertsOld.get(0).almd__client_process_accepted_type__c = true;
      alertsOld.get(0).almd__execution_indicator_type__c = TESTSTRING;
      alertsOld.get(0).almd__mandatory_visit_type__c = 'No';
      alertsOld.get(0).almd__alert_stage_type__c = Label.DES_CLOSED;
      alertsOld.get(0).almd__alert_sub_stage_type__c = Label.COMMERCIAL_ALERT_STATUS_DISCARDED;
      alertsOld.get(0).almd__BBVA_rejection_reason_desc__c = 'Missed Deadline';
      alertsOld.get(0).almd__Client_rejection_reason_desc__c = 'Deal';
      alertsOld.get(1).almd__client_process_accepted_type__c = true;
      alertsOld.get(1).almd__execution_indicator_type__c = TESTSTRING;
      alertsOld.get(1).almd__mandatory_visit_type__c = 'No';
      alertsOld.get(1).almd__alert_stage_type__c = Label.DES_CLOSED;
      alertsOld.get(1).almd__alert_sub_stage_type__c = Label.COMMERCIAL_ALERT_STATUS_DISCARDED;
      alertsOld.get(1).almd__BBVA_rejection_reason_desc__c = 'Client withdrawn';
      alertsOld.get(1).almd__Others_rejection_reason_desc__c = 'Others';
      update alertsOld;
    }
    final Id batchInstanceId2 = Database.executeBatch(new DES_AlertMigration(), 2000);
    system.debug('btchInst2 ' + batchInstanceId2);
    Test.stopTest();
    final altm__Commercial_Alert__c alertOld3 = [SELECT Id, altm__alert_stage_type__c, altm__BBVA_rejection_reason_desc__c FROM altm__Commercial_Alert__c WHERE altm__commercial_alert_id__c = 'Id1' LIMIT 1];
    system.debug('alertOld3.altm__BBVA_rejection_reason_desc__c ' + alertOld3.altm__BBVA_rejection_reason_desc__c);
    System.assertEquals(alertOld3.altm__BBVA_rejection_reason_desc__c, 'Too late / Deal Missed', 'NotLate');
  }

    /*
  * testMethodSeven test
  */
  @isTest
  private static void testMethodSeven() {
    final DES_UtilTestClass utils = new DES_UtilTestClass();
    final Account acc = [SELECT Id FROM Account WHERE Name = 'test1' LIMIT 1];

    final List<User> users = new List<User>([SELECT Id, UserName, ID_User__c, Email FROM User WHERE UserName = 'testuser+gccstandarduser@test.com' OR Email = 'useremail@test.comm1' ORDER BY Email ASC LIMIT 2]);
    system.debug('eh0 ' + users.get(0).Email);
    system.debug('eh1 ' + users.get(1).Email);
    final User iUserStandard = users.get(0);
    final User user1 = users.get(1);
    final almd__Commercial_Alert__c alertOld4 = utils.createAlert(user1, iUserStandard, acc, 3, 'Commercial Task GTB');
    alertOld4.almd__commercial_alert_end_date__c = Date.newInstance(1970, 1, 1);
    insert alertOld4;
    final altm__Commercial_Alert__c alertNew3 = utils.createNewAlert(user1, iUserStandard, acc, 3, 'Commercial Task');
    alertNew3.altm__commercial_alert_id__c = alertOld4.almd__commercial_alert_id__c;
    insert alertNew3;

    system.runAs(iUserStandard) {
      final List<almd__Commercial_Alert__c> alertsOld = [
        SELECT Id, almd__client_process_accepted_type__c, almd__execution_indicator_type__c, almd__mandatory_visit_type__c,
        almd__alert_stage_type__c, almd__alert_sub_stage_type__c, almd__commercial_alert_id__c, almd__commercial_alert_end_date__c
        FROM almd__Commercial_Alert__c WHERE almd__commercial_alert_id__c IN ('Id3','Id2')];
      Test.startTest();
      alertsOld.get(0).almd__client_process_accepted_type__c = true;
      alertsOld.get(0).almd__execution_indicator_type__c = TESTSTRING;
      alertsOld.get(0).almd__mandatory_visit_type__c = 'No';
      alertsOld.get(0).almd__alert_stage_type__c = Label.DES_CLOSED;
      alertsOld.get(0).almd__alert_sub_stage_type__c = Label.COMMERCIAL_ALERT_STATUS_DISCARDED;
      alertsOld.get(1).almd__client_process_accepted_type__c = true;
      alertsOld.get(1).almd__execution_indicator_type__c = TESTSTRING;
      alertsOld.get(1).almd__mandatory_visit_type__c = 'No';
      alertsOld.get(1).almd__alert_stage_type__c = Label.DES_CLOSED;
      alertsOld.get(1).almd__alert_sub_stage_type__c = Label.COMMERCIAL_ALERT_STATUS_DISCARDED;
      alertsOld.get(1).almd__Rejection_reason_desc__c = TESTSTRING;
      update alertsOld;
    }
    final Id batchInstanceId2 = Database.executeBatch(new DES_AlertMigration(), 2000);
    system.debug('batchInstanceId2 ' + batchInstanceId2);
    Test.stopTest();
    final altm__Commercial_Alert__c alertOld3 = [SELECT Id, altm__alert_stage_type__c FROM altm__Commercial_Alert__c WHERE altm__commercial_alert_id__c = 'Id3' LIMIT 1];
    System.assertEquals(alertOld3.altm__alert_stage_type__c, Label.COMMERCIAL_ALERT_STATUS_DISABLED, 'NotDisabled');
  }
}