@isTest
public class DES_DenormalizeAlertsSchedulableTest {
  @IsTest
  public static void DES_DenormalizeAlertsSchedulableTest(){
    final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();

    final String idProfile = utilTestClass.createProfile();
    final User userTest = utilTestClass.createUser(idProfile);
    insert userTest;

    final Account acc1 = utilTestClass.createClient();
    insert acc1;

    final altm__Commercial_Alert__c alert1 = utilTestClass.createNewAlert(userTest, userTest, acc1, 3, 'Commercial Task IBF');
    insert alert1;

    Test.startTest();
      final String jobId = system.schedule('Test Check', '0 0 2 * * ?', new DES_DenormalizeAlertsSchedulable());
      system.debug('jobId ' +jobId);
    Test.stopTest();

    new DES_DenormalizeAlertsUtils().clear();
    new DES_DenormalizeAlertsUtils().clear(alert1.Id);
    new DES_DenormalizeAlertsUtils().restore(alert1.Id);

    final List <DES_Denorm_AccountAlert__c> listDenormAlert = [SELECT Id FROM DES_Denorm_AccountAlert__c WHERE participant_id__c = :acc1.Id /*AND commercial_alert_id__c = :alert1.Id*/];

    System.assert(!listDenormAlert.isEmpty());

  }
}