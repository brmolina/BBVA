/*
* @author Global Desktop
* @name AlertsRelatedListCntTest
* @description Test de la clase apex AlertsRelatedListCnt
*/
@isTest
public class AlertsRelatedListCntTest {

	/**
	* @author Global Desktop
	* @description Test de la clase AlertsRelatedListCnt
	*/
 	@IsTest
	public static void testMethod1() {
		/*Instancia de la clase DES_UtilTestClass*/
		final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();

		final String idProfile = utilTestClass.createProfile();

        final User userTest = utilTestClass.createUser(idProfile);
        insert userTest;

		final Account acc = utilTestClass.createClient();
		insert acc;

		final altm__Commercial_Alert__c alert1 = utilTestClass.createNewAlert(userTest, userTest, acc, 3, 'Commercial Task IBF');
        insert alert1;

        DES_Denorm_AccountAlert__c denAlert1 = new DES_Denorm_AccountAlert__c();
        denAlert1.commercial_alert_id__c = alert1.Id;
        denAlert1.participant_id__c = acc.Id;
        insert denAlert1;

        Test.StartTest();
        AlertsRelatedListCnt.relatedAlerts('5',acc.Id, 'All');
        AlertsRelatedListCnt.relatedAlerts('5',acc.Id, 'GTB');
        system.assertEquals(alert1.altm__commercial_alert_record_type__c,'Commercial Task IBF','Correcto');
        Test.StopTest();
	}

}