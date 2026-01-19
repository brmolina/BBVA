/**
* @author GlobalDesktop
*/
@isTest
public class AlertsPotentialActivityController_test {
  /*
  * RTYPE variable
  */
  final static String RTYPE = 'Commercial Task IBF';
    @isTest
    /*
    * MEthod 1
    */
    public static void methodOne() {
        final List<User> lUser = new List<User>();
        final List<altm__Commercial_Alert__c> lComAlert = new List<altm__Commercial_Alert__c>();
        final List<DES_Denorm_AccountAlert__c> lAccAlert = new List<DES_Denorm_AccountAlert__c>();
        final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();

        final Account acc = utilTestClass.createClient();
        insert acc;

        final User user1 = utilTestClass.createUser(utilTestClass.createProfile(), 'user1@bbva.com');
        lUser.add(user1);
        final User user2 = utilTestClass.createUser(utilTestClass.createProfile(), 'user2@bbva.com');
        lUser.add(user2);

        insert lUser;

        Test.startTest();
        final altm__Commercial_Alert__c alert1 = utilTestClass.createNewAlert(user1, user2, acc, 5, RTYPE);
        alert1.altm__alert_stage_type__c='Pending';
        lComAlert.add(alert1);
        final altm__Commercial_Alert__c alert2 = utilTestClass.createNewAlert(user1, user2, acc, 8, RTYPE);
        alert2.altm__alert_stage_type__c='Pending';
        lComAlert.add(alert2);
        final altm__Commercial_Alert__c alert3 = utilTestClass.createNewAlert(user1, user2, acc, 10, RTYPE);
        alert3.altm__alert_stage_type__c='Pending';
        alert3.altm__Rejection_reason_desc__c='The alert was matured, its end date was 1';
        lComAlert.add(alert3);

        insert lComAlert;
        Test.stopTest();

        final DES_Denorm_AccountAlert__c accAlert1 = new DES_Denorm_AccountAlert__c();
        accAlert1.commercial_alert_id__c=alert1.id;
        accAlert1.participant_id__c=acc.id;
        lAccAlert.add(accAlert1);
        final DES_Denorm_AccountAlert__c accAlert2 = new DES_Denorm_AccountAlert__c();
        accAlert2.commercial_alert_id__c=alert2.id;
        accAlert2.participant_id__c=acc.id;
        lAccAlert.add(accAlert2);
        final DES_Denorm_AccountAlert__c accAlert3 = new DES_Denorm_AccountAlert__c();
        accAlert3.commercial_alert_id__c=alert3.id;
        accAlert3.participant_id__c=acc.id;
        lAccAlert.add(accAlert3);

        insert lAccAlert;

        AlertsPotentialActivityController.gtInstance();
        AlertsPotentialActivityController.getAlertInfo(acc.id);
        System.assertEquals(accAlert1.commercial_alert_id__c,alert1.id,'msgAlert');
    }
}