/**********************************************************************************
* @author       Global Desktop
* @date         05/02/2020
* @description  Test class for Batch_Insert_Comm_Alert_Manual_Sharing
**********************************************************************************/
@isTest
public with sharing class Batch_Insert_Comm_Alert_Manual_Shar_Test {
  /**
  * TEST2VAR
  */
  public static final String TEST2VAR = 'test2';

  /**
  * Test setup
  */
  @TestSetup
  static void testSetup() {
    final DES_UtilTestClass tstClass = new DES_UtilTestClass();
    final Account acc = tstClass.createClient();
    acc.SER_CClient__c = 'test1';
    acc.Name = 'test1';
    insert acc;

    final Account acc2 = tstClass.createClient();
    acc2.SER_CClient__c = TEST2VAR;
    acc2.Name = TEST2VAR;
    insert acc2;

    final String profileUsr = tstClass.createProfile();
    final User usr = tstClass.createUser(profileUsr);
    usr.Email = 'testalertuser@test.com';
    insert usr;

    final DES_BBVA_Management_team__c iBBVATeam = tstClass.createBBVAManagementTeamMember(usr, acc);
    insert iBBVATeam;

    final DES_BBVA_Management_team__c iBBVATeam2 = tstClass.createBBVAManagementTeamMember(usr, acc2);
    insert iBBVATeam2;

    final DES_Subsidiary_Group_Relation__c matrix = new DES_Subsidiary_Group_Relation__c();
    matrix.participant_child_id__c = acc.Id;
    matrix.participant_parent_id__c = acc2.Id;
    matrix.main_subsidiary_ind_type__c = true;
    insert matrix;
  }

  /**
  * Test method 1
  */
  @isTest
  public static void test1() {
    Test.startTest();
      final Account iAccount = [SELECT Id FROM Account WHERE Name = 'test1' LIMIT 1];

      final altm__Commercial_Alert__c iCommercialAlert = new altm__Commercial_Alert__c();
      iCommercialAlert.altm__participant_id__c = iAccount.Id;
      iCommercialAlert.altm__Transaction_type_desc__c = 'Corporate Loans';
      iCommercialAlert.altm__commercial_alert_task_type__c = 'backup';
      iCommercialAlert.altm__owner_access_alert_id__c = [SELECT Id, FederationIdentifier FROM User WHERE Email = 'testalertuser@test.com' LIMIT 1].FederationIdentifier;
      iCommercialAlert.altm__commercial_alert_record_type__c = Label.DES_RT_COMM_ALERT_COM_TASK_IBF;
      insert iCommercialAlert;

      final DES_UtilTestClass iUtilTestClass = new DES_UtilTestClass();
      final String iProfile = iUtilTestClass.createProfile();
      final User iUser = iUtilTestClass.createUser(iProfile);
      iUser.Email = 'testalertuser+1@test.com';
      insert iUser;

      final DES_BBVA_Management_team__c iBBVATeam = iUtilTestClass.createBBVAManagementTeamMember(iUser, iAccount);
      insert iBBVATeam;

      final Map<Id, List<String>> mapAccUserIdTeam = new Map<Id, List<String>>();
      mapAccUserIdTeam.put(iAccount.Id, new List<String> {iUser.Id});
      BATCH_DeleteAlertTeam.runJobForParticularRecords(mapAccUserIdTeam);

      final Map<Id, List<String>> mapAccUserIdShare = new Map<Id, List<String>>();
      mapAccUserIdShare.put(iAccount.Id, new List<String> {iUser.Id});
      BATCH_DeleteAlertShare.runJobForParticularRecords(mapAccUserIdShare);
      system.assertNotEquals(null, iBBVATeam, 'null');
    Test.stopTest();
  }

  /**
  * Test method 2
  */
  @isTest
  public static void test2() {
    Test.startTest();
      final Account iAccount = [SELECT Id FROM Account WHERE Name = 'test1' LIMIT 1];

      final altm__Commercial_Alert__c iCommercialAlert = new altm__Commercial_Alert__c();
      iCommercialAlert.altm__participant_id__c = iAccount.Id;
      iCommercialAlert.altm__Transaction_type_desc__c = 'Corporate Loans';
      iCommercialAlert.altm__commercial_alert_task_type__c = 'backup';
      iCommercialAlert.altm__owner_access_alert_id__c = [SELECT Id, FederationIdentifier FROM User WHERE Email = 'testalertuser@test.com' LIMIT 1].FederationIdentifier;
      iCommercialAlert.altm__commercial_alert_record_type__c = Label.DES_RT_COMM_ALERT_COM_TASK_IBF;
      insert iCommercialAlert;

      final DES_UtilTestClass iUtilTestClass = new DES_UtilTestClass();
      final String iProfile = iUtilTestClass.createProfile();
      final User iUser = iUtilTestClass.createUser(iProfile);
      iUser.Email = 'testalertuser+1@test.com';
      insert iUser;

      final DES_BBVA_Management_team__c iBBVATeam = iUtilTestClass.createBBVAManagementTeamMember(iUser, iAccount);
      iBBVATeam.copy_record_approval_type__c = false;
      insert iBBVATeam;

      final Batch_Insert_Comm_Alert_Manual_Sharing iBatch2 = new Batch_Insert_Comm_Alert_Manual_Sharing();
      final Id batchId = Database.executeBatch(iBatch2, 100);
      system.assertNotEquals(null, batchId, 'null');

    Test.stopTest();
  }
}