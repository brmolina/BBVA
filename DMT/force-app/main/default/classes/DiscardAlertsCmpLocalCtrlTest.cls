/**********************************************************************************
* @author       Global Desktop
* @date         05/02/2020
* @description  Test class for DiscardAlertsCmpLocalCtrl
**********************************************************************************/
@isTest
public class DiscardAlertsCmpLocalCtrlTest {
  /*
  * Sample variable
  */
  final static String SAMPLE = 'Sample';

  /**
  * Test method 1
  */
  @isTest
  public static void testPicklistVal() {
    final SObject obj = Schema.getGlobalDescribe().get('altm__Commercial_Alert__c').newSObject();
    final Map <String, String> options = DiscardAlertsCmpLocalCtrl.getselectOptions(obj, 'altm__BBVA_rejection_reason_desc__c');
    system.assertEquals(options.get(SAMPLE), null, 'notSample');
  }

  /**
  * Test method 2
  */
  @isTest
  public static void testUpdateAlerts() {
      final DES_UtilTestClass utilClass = new DES_UtilTestClass();
      final Profile prof = [SELECT Id FROM Profile WHERE Name='BBVA Desktop GCC Standard'];
      final User userTest = utilClass.createUser(prof.Id);
      insert userTest;
      System.runAs(userTest) {
        final Account acc = new Account(Name='Test Account');
        insertAccount(acc);
        final List<altm__Commercial_Alert__c> alerts = new List<altm__Commercial_Alert__c>{new altm__Commercial_Alert__c(Name='Test Alert', altm__participant_id__c = acc.Id, altm__owner_access_alert_id__c=userTest.FederationIdentifier)};
        insertAlerts(alerts);
        System.debug('alerts.get(0).altm__alert_stage_type__c -> ' + alerts.get(0).altm__alert_stage_type__c);
        final Set<Id> setIds = new Set<Id>();
        setIds.add(alerts.get(0).Id);
        final String serial = JSON.serialize(setIds);
        DiscardAlertsCmpLocalCtrl.updateAlerts(serial, 'Others', 'testcomment');
        final altm__Commercial_Alert__c alert = [SELECT Id, altm__BBVA_rejection_reason_desc__c
                                            FROM altm__Commercial_Alert__c
                                            WHERE Id = :alerts.get(0).Id LIMIT 1];
    	system.assertEquals(alert.altm__BBVA_rejection_reason_desc__c, 'Others', 'notExpectedReason');
    }
  }

  /**
  * Private method for insert
  **/
  private static void insertAccount(Account acc) {
    insert acc;
  }

  /**
  * Private method for insert
  **/
  private static void insertAlerts(List<altm__Commercial_Alert__c> alerts) {
    insert alerts;
  }
}