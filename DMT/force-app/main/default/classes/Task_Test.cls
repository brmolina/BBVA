/**********************************************************************************
* @author       Global Desktop
* @date         25/03/2020
* @description  Test  para el objeto Task
**********************************************************************************/
@isTest
public class Task_Test {
  /**
  * TEST1VAR
  */
  public static final String TEST1VAR = 'test1';
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
    acc.g_customer_id__c = TEST1VAR;
    acc.Name = TEST1VAR;
    acc.DES_Tier__c = '00000020';
    insert acc;

    final Account acc2 = tstClass.createClient();
    acc2.g_customer_id__c = TEST2VAR;
    acc2.Name = TEST2VAR;
    acc2.DES_Tier__c = '00000020';
    insert acc2;

    final String profileUsr = tstClass.createProfile();
    final User usr = tstClass.createUser(profileUsr);
    usr.Email = 'testalertuser@test.com';
    insert usr;

    final User iUserStandard = tstClass.createUserWithProfileName('BBVA Desktop GCC Standard', 'testuser+gccstandarduser@test.com');
    insert iUserStandard;

    final List<DES_BBVA_Management_team__c> listBBVATeam = new List<DES_BBVA_Management_team__c>();
    final DES_BBVA_Management_team__c iBBVATeam = tstClass.createBBVAManagementTeamMember(usr, acc);
    listBBVATeam.add(iBBVATeam);
    final DES_BBVA_Management_team__c iBBVATeam2 = tstClass.createBBVAManagementTeamMember(usr, acc2);
    listBBVATeam.add(iBBVATeam2);
    final DES_BBVA_Management_team__c iBBVATeam3 = tstClass.createBBVAManagementTeamMember(iUserStandard, acc);
    listBBVATeam.add(iBBVATeam3);
    final DES_BBVA_Management_team__c iBBVATeam4 = tstClass.createBBVAManagementTeamMember(iUserStandard, acc2);
    listBBVATeam.add(iBBVATeam4);
    insert listBBVATeam;

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
    final User iUserStandard = [SELECT Id FROM User WHERE UserName = 'testuser+gccstandarduser@test.com' LIMIT 1];

    Test.startTest();
      final altm__Commercial_Alert__c iCommercialAlert = new altm__Commercial_Alert__c();
      iCommercialAlert.altm__participant_id__c = [SELECT Id FROM Account WHERE Name = :TEST1VAR LIMIT 1].Id;
      iCommercialAlert.altm__owner_access_alert_id__c = [SELECT Id, FederationIdentifier FROM User WHERE Email = 'testalertuser@test.com' LIMIT 1].FederationIdentifier;
      iCommercialAlert.altm__commercial_alert_record_type__c = Label.DES_RT_COMM_ALERT_COM_TASK_GM;
      insert iCommercialAlert;

      System.runAs(iUserStandard) {
        System.debug('::::::::::UserInfo.getProfileId(): ' + UserInfo.getProfileId());
        final Task iTask = new Task();
        iTask.WhatId = iCommercialAlert.Id;
        iTask.OwnerId = iUserStandard.Id;
        iTask.Subject = 'Test task';
        iTask.IsReminderSet = true;
        iTask.ReminderDateTime = System.now().addMinutes(5);
        insert iTask;

        final altm__Commercial_Alert__c iCommAlertManaged = [SELECT Id, altm__alert_stage_type__c FROM altm__Commercial_Alert__c LIMIT 1];
        System.assertEquals(iCommAlertManaged.altm__alert_stage_type__c, Label.COMMERCIAL_ALERT_STATUS_MANAGED, 'The alert has not managed');
      }
    Test.stopTest();
  }
}