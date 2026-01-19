/**********************************************************************************
* @author       Global Desktop
* @date         05/02/2020
* @description  Test class for DiscardAlertsCmpCtrl
**********************************************************************************/
@isTest
public class DiscardAlertsCmpCtrlTest {
  /*
  * Sample variable
  */
  final static String SAMPLE = 'Not my client';

  /**
  * Test method 1
  **/
  @isTest
  public static void testPicklistVal() {
    final SObject obj = Schema.getGlobalDescribe().get('altm__Commercial_Alert__c').newSObject();
    final Map <String, String> options = DiscardAlertsCmpCtrl.getselectOptions(obj, 'altm__BBVA_rejection_reason_desc__c');
    system.assertEquals(options.get(SAMPLE), SAMPLE, 'notSample');
  }

  /**
  * Test method 2
  **/
  @isTest
  public static void testUpdateAlerts() {
    final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
    final String idProfile = utilTestClass.createProfile();
    final User userTest = utilTestClass.createUser(idProfile);
    insert userTest;

    final Account acc1 = utilTestClass.createClient();
    insert acc1;
    final altm__Commercial_Alert__c alert1 = utilTestClass.createNewAlert(userTest, userTest, acc1, 3, 'Commercial Task IBF');

    final List<altm__Commercial_Alert__c> alerts = new List<altm__Commercial_Alert__c>();
    alerts.add(alert1);
    insertAlerts(alerts);
    DiscardAlertsCmpCtrl.updateAlerts(alerts.get(0).Id, SAMPLE, 'testcomment');
    final altm__Commercial_Alert__c alert = [SELECT Id, altm__BBVA_rejection_reason_desc__c
                                            FROM altm__Commercial_Alert__c
                                            WHERE Id = :alerts.get(0).Id LIMIT 1];
    system.assertEquals(alert.altm__BBVA_rejection_reason_desc__c, SAMPLE, 'notExpectedReason');
  }

  /**
  * Test method 3
  **/
  @isTest
  public static void testStatus() {
    final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
    final String idProfile = utilTestClass.createProfile();
    final User userTest = utilTestClass.createUser(idProfile);
    insert userTest;
    final User iUserStandard = utilTestClass.createUserWithProfileName('BBVA Desktop GCC Standard', 'testuser+gccstandarduser@test.com');
    iUserStandard.FederationIdentifier = string.valueOf(system.now() - Math.abs(Math.random()*10));
    insert iUserStandard;

    final Account acc1 = utilTestClass.createClient();
    insert acc1;
    final altm__Commercial_Alert__c alert1 = utilTestClass.createNewAlert(userTest, userTest, acc1, 3, 'Commercial Task IBF');
    final altm__Commercial_Alert__c alert2 = utilTestClass.createNewAlert(userTest, userTest, acc1, 3, 'Commercial Task IBF');
    alert2.altm__owner_access_alert_id__c = [SELECT Id, FederationIdentifier FROM User WHERE UserName = 'testuser+gccstandarduser@test.com' LIMIT 1].FederationIdentifier;

    final List<altm__Commercial_Alert__c> alerts = new List<altm__Commercial_Alert__c>();
    alerts.add(alert1);
    alerts.add(alert2);
    insertAlerts(alerts);

    System.runAs(iUserStandard) {
      System.debug('::::::::::UserInfo.getProfileId(): ' + UserInfo.getProfileId());
      final Task iTask = new Task();
      iTask.WhatId = alerts.get(1).Id;
      iTask.OwnerId = iUserStandard.Id;
      iTask.Subject = 'Test task';
      iTask.IsReminderSet = true;
      iTask.ReminderDateTime = System.now().addMinutes(5);
      insert iTask;
    }

    DiscardAlertsCmpCtrl.updateAlerts(alerts.get(0).Id, SAMPLE, 'testcomment');
    final String status = DiscardAlertsCmpCtrl.statusAlert(alerts.get(0).Id);
    system.debug('sta -> ' + status);
    final String status1 = DiscardAlertsCmpCtrl.statusAlert(alerts.get(1).Id);
    system.assertEquals('false//true', status1, 'notDiscarded');
  }

  /**
  * Private method for insert
  **/
  private static void insertAlerts(List<altm__Commercial_Alert__c> alerts) {
    insert alerts;
  }
}