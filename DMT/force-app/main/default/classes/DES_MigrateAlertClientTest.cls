/**********************************************************************************
* @author       Global Desktop
* @date         05/05/2020
* @description  Test class for DES_MigrateAlertClient
**********************************************************************************/
@isTest
public class DES_MigrateAlertClientTest {

  @TestSetup
  static void testSetup() {
    final DES_UtilTestClass utils = new DES_UtilTestClass();
    final Account acc = utils.createClient();
    acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.DES_RT_NAME_NEW_COMMERCIAL_CLIENT).getRecordTypeId();
    acc.DES_Data_Origin_Intranet__c = true;
    insert acc;
    acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.DES_RT_NAME_SALES_COUNTERPART).getRecordTypeId();
    acc.Client_STAR_ID__c = 'TESTCLIENT-BBVASA';
    update acc;

    final Account acc2 = utils.createClient();
    insert acc2;

    final String profileTest = utils.createProfile();
    final User user1 = utils.createUser(profileTest);
    insert user1;

    final altm__Commercial_Alert__c alert = new altm__Commercial_Alert__c();
    alert.altm__participant_id__c = acc.Id;
    alert.altm__owner_access_alert_id__c = user1.ID_User__c;
    alert.OwnerId = user1.Id;
    insert alert;

    final Counterparty__c counterparty = new Counterparty__c();
    counterparty.participant_id__c = acc2.Id;
    counterparty.star_counterparty_oper_desc__c = 'TESTCLIENT';
    insert counterparty;

  }

  /**
  * Test method 1
  */
  @isTest
  public static void test1() {
    Test.startTest();
      final altm__Commercial_Alert__c iCommercialAlert = [SELECT Id, altm__participant_id__c from altm__Commercial_Alert__c LIMIT 1];
      final Id batchInstanceId2 = Database.executeBatch(new DES_MigrateAlertClient(), 2000);
	    System.assertNotEquals(batchInstanceId2, null,'msg');
    Test.stopTest();
  }

}