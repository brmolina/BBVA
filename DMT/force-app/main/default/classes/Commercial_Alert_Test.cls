/**********************************************************************************
* @author       Global Desktop
* @date         05/02/2020
* @description  Test class for Commercial_Alert_Test
**********************************************************************************/
@isTest
public class Commercial_Alert_Test {
  /*
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
      final altm__Commercial_Alert__c iCommercialAlert = new altm__Commercial_Alert__c();
      iCommercialAlert.altm__participant_id__c = [SELECT Id FROM Account WHERE Name = 'test1' LIMIT 1].Id;
      iCommercialAlert.altm__Transaction_type_desc__c = 'Corporate Loans';
      iCommercialAlert.altm__commercial_alert_task_type__c = 'backup';
      iCommercialAlert.altm__owner_access_alert_id__c = [SELECT Id, FederationIdentifier FROM User WHERE Email = 'testalertuser@test.com' LIMIT 1].FederationIdentifier;
      iCommercialAlert.altm__commercial_alert_record_type__c = Label.DES_RT_COMM_ALERT_COM_TASK_IBF;
      insert iCommercialAlert;

      final altm__Commercial_Alert__c alert = [SELECT Id, Group_Name__c FROM altm__Commercial_Alert__c WHERE Id = :iCommercialAlert.Id LIMIT 1];
      system.assertEquals(TEST2VAR, alert.Group_Name__c, 'not group');

      delete iCommercialAlert;
    Test.stopTest();
  }

  /**
  * Test method 2
  */
  @isTest
  public static void test2() {
    Test.startTest();
      final altm__Commercial_Alert__c iCommercialAlert = new altm__Commercial_Alert__c();
      iCommercialAlert.altm__participant_id__c = [SELECT Id FROM Account WHERE Name = 'test1' LIMIT 1].Id;
      iCommercialAlert.altm__owner_access_alert_id__c = [SELECT Id, FederationIdentifier FROM User WHERE Email = 'testalertuser@test.com' LIMIT 1].FederationIdentifier;
      iCommercialAlert.altm__commercial_alert_record_type__c = Label.DES_RT_COMM_ALERT_COM_TASK_GM;
      insert iCommercialAlert;

      final altm__Commercial_Alert__c alert = [SELECT Id, Group_Name__c FROM altm__Commercial_Alert__c WHERE Id = :iCommercialAlert.Id LIMIT 1];
      system.assertEquals(TEST2VAR, alert.Group_Name__c, 'not group');

      iCommercialAlert.altm__Transaction_type_desc__c = 'Corporate Loans';
      iCommercialAlert.altm__commercial_alert_task_type__c = 'backup';
      iCommercialAlert.altm__alert_stage_type__c = '';
      upsert iCommercialAlert;
    Test.stopTest();
  }

  /**
  * Test method 3
  */
  @isTest
  public static void test3() {
      final DES_UtilTestClass tstClass = new DES_UtilTestClass();
      final String profileUsr = tstClass.createProfile();

      final List<User> listUser = new List<User>();
      final User usr2 = tstClass.createUser(profileUsr);
      listUser.add(usr2);

      final User iUserGCC = tstClass.createUserWithProfileName('BBVA Desktop GCC Standard', 'iUserGCC@bbvatest.test');
      iUserGCC.ID_User__c = 'iUserGCC';
      iUserGCC.FederationIdentifier = 'iUserGCC';
      iUserGCC.CommunityNickname = 'iUserGCC@bbvatest.test';
      listUser.add(iUserGCC);
      insert listUser;

      final Account acc3 = tstClass.createClient();
      acc3.SER_CClient__c = 'test3';
      acc3.Name = 'test3';
      insert acc3;
      System.debug('::::::::::acc3: ' + acc3);

      final DES_Subsidiary_Group_Relation__c matrix = new DES_Subsidiary_Group_Relation__c();
      matrix.participant_child_id__c = acc3.Id;
      matrix.participant_parent_id__c = [SELECT Id FROM Account WHERE Name = :TEST2VAR LIMIT 1].Id;
      matrix.main_subsidiary_ind_type__c = true;
      insert matrix;

      final DES_BBVA_Management_team__c iBBVATeam3 = tstClass.createBBVAManagementTeamMember(usr2, acc3);
      insert iBBVATeam3;
      Test.startTest();
      final altm__Commercial_Alert__c iCommercialAlert = new altm__Commercial_Alert__c();
      iCommercialAlert.altm__participant_id__c = [SELECT Id FROM Account WHERE Name = 'test1' LIMIT 1].Id;
      iCommercialAlert.altm__owner_access_alert_id__c = [SELECT Id, FederationIdentifier FROM User WHERE Email = 'testalertuser@test.com' LIMIT 1].FederationIdentifier;
      iCommercialAlert.altm__commercial_alert_record_type__c = Label.DES_RT_COMM_ALERT_COM_TASK_GTB;
      iCommercialAlert.participant_name__c = 'test1';
      iCommercialAlert.sf_no_db_user_id__c = [SELECT Id, FederationIdentifier FROM User WHERE Email = 'testalertuser@test.com' LIMIT 1].FederationIdentifier;
      insert iCommercialAlert;
      System.debug('::::::::::iCommercialAlert.altm__participant_id__c: ' + iCommercialAlert.altm__participant_id__c);

      iCommercialAlert.altm__owner_access_alert_id__c = usr2.FederationIdentifier;
      iCommercialAlert.sf_no_db_user_id__c = usr2.FederationIdentifier;
      iCommercialAlert.altm__participant_id__c = acc3.Id;
      iCommercialAlert.participant_name__c = 'test3';
      update iCommercialAlert;
      Test.stopTest();
      final altm__Commercial_Alert__c alert = [SELECT Id, Group_Name__c FROM altm__Commercial_Alert__c WHERE Id = :iCommercialAlert.Id LIMIT 1];
      System.debug('::::::::::alert.Group_Name__c: ' + alert.Group_Name__c);
      system.assertEquals(TEST2VAR, alert.Group_Name__c, 'not group');

      delete iBBVATeam3;
      final DES_BBVA_Management_team__c iBBVATeamNew = tstClass.createBBVAManagementTeamMember(iUserGCC, acc3);
      iBBVATeamNew.DES_Member_Role__c = Label.DES_ROLE_GLOBAL_BANKER;
      iBBVATeamNew.DES_Local_Banker_Country__c = 'ES';
      insert iBBVATeamNew;
  }

  /**
  * Test method 4
  */
  @isTest
  public static void test4() {
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

      // final BATCH_DeleteAlertTeam iBatch2 = new BATCH_DeleteAlertTeam();
      final Map<Id, List<String>> mapAccUserIdTeam = new Map<Id, List<String>>();
      mapAccUserIdTeam.put(iAccount.Id, new List<String> {iUser.Id});
      BATCH_DeleteAlertTeam.runJobForParticularRecords(mapAccUserIdTeam);
      // Database.executeBatch(iBatch2, 100);

      final Map<Id, List<String>> mapAccUserIdShare = new Map<Id, List<String>>();
      mapAccUserIdShare.put(iAccount.Id, new List<String> {iUser.Id});
      BATCH_DeleteAlertShare.runJobForParticularRecords(mapAccUserIdShare);
      // Database.executeBatch(iBatch3, 100);

      final List<altm__Commercial_Alert__Share> listComAlertShare = [SELECT Id FROM altm__Commercial_Alert__Share WHERE ParentId =: iCommercialAlert.Id AND UserOrGroupId = :iUser.Id];
      System.assertEquals(0, listComAlertShare.size(), 'Test fail');
    Test.stopTest();
  }
}