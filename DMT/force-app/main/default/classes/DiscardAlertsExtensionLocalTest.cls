/**********************************************************************************
* @author       Global Desktop
* @date         05/02/2020
* @description  Test class for DiscardAlertsExtensionLocal
**********************************************************************************/
@isTest
public class DiscardAlertsExtensionLocalTest {
  /**
  * @author Global Desktop
  * @description Method for test
  */
  public static testMethod void testExtension() {
    final DES_UtilTestClass utilClass = new DES_UtilTestClass();
    final User userTest = utilClass.createUser(utilClass.createProfile());
    insert userTest;
    final Account acc = new Account(Name='Test Account');
    insertAccount(acc);
    final List<altm__Commercial_Alert__c> alerts = new List<altm__Commercial_Alert__c>{new altm__Commercial_Alert__c(Name='Test Alert', altm__participant_id__c = acc.Id, altm__owner_access_alert_id__c=userTest.FederationIdentifier)};
    insertAlerts(alerts);
    final ApexPages.StandardSetController controller = new ApexPages.StandardSetController(alerts);
    controller.setSelected(alerts);
    final DiscardAlertsExtensionLocal extension = new DiscardAlertsExtensionLocal(controller);
    system.assertNotEquals(extension, null, 'extensionNull');
  }

  /**
  * @author Global Desktop
  * @description private method for insert
  */
  private static void insertAccount(Account acc) {
    insert acc;
  }

  /**
  * @author Global Desktop
  * @description private method for insert
  */
  private static void insertAlerts(List<altm__Commercial_Alert__c> alerts) {
    insert alerts;
  }
}