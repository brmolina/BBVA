/*
 * @author	Global Desktop
 * @Description	Clase de test para la clase VisitTerritoryBatchTest
 *
 */
@isTest
public class VisitTerritoryBatchTest {
	/*
	 * 	@author	Global Desktop
	 * 	@Description	Method que testea el batch y las clases VisitTerritoryBatch
	 *
	 **/
    @isTest
    static void batchTestMultiValues() {
        final List<User> listUserToInsert = new List<User>();
        final DES_UtilTestClass testClass = new DES_UtilTestClass();
    	  final String idProfile = testClass.createProfile();
        final User userTest = testClass.createUser(idProfile);
        userTest.gf_user_auth_level_name__c = 'Confidential Information';
        userTest.gf_user_work_country_desc__c = 'ES;AR;BE';
        userTest.gf_user_work_segment_desc__c = 'Corporate;Institutional Client';
        userTest.gf_user_work_product_desc__c = 'codeC;codeDCM;codeR';
        listUserToInsert.add(userTest);
        insert listUserToInsert;
        final Account acc = testClass.createClient();
        insert acc;
        final List<dwp_kitv__Visit__c> listVisits = new List<dwp_kitv__Visit__c>();
        final dwp_kitv__Visit__c visitNew = testClass.createVisit(acc, null);
        visitNew.gf_visit_users_products_desc__c = 'codeC;codeDCM';
        visitNew.dwp_kitv__country_name__c = 'ES';
        listVisits.add(visitNew);
        insert listVisits;
        final Id batchInstanceId = Database.executeBatch(new VisitTerritoryBatch(), 8);
        system.assertNotEquals(batchInstanceId, null, 'batchInstanceId NULL');

    }
    /*
	 * 	@author	Global Desktop
	 * 	@Description	Method que testea el batch y las clases VisitTerritoryBatch
	 *
	 **/
    @isTest
    static void batchTestSingleValue() {
        final List<User> listUserToInsert = new List<User>();
        final DES_UtilTestClass testClass = new DES_UtilTestClass();
    	  final String idProfile = testClass.createProfile();
        final User userTest2 = testClass.createUser(idProfile);
        userTest2.gf_user_auth_level_name__c = 'Not Applicable';
        userTest2.gf_user_work_country_desc__c = 'ES';
        userTest2.gf_user_work_segment_desc__c = 'Corporate';
        userTest2.gf_user_work_product_desc__c = 'codeC';
        listUserToInsert.add(userTest2);
        insert listUserToInsert;
        final Account acc = testClass.createClient();
        insert acc;
        final List<dwp_kitv__Visit__c> listVisits = new List<dwp_kitv__Visit__c>();
        final dwp_kitv__Visit__c visitNew = testClass.createVisit(acc, null);
        visitNew.gf_visit_users_products_desc__c = 'codeC';
        visitNew.dwp_kitv__country_name__c = 'ES';
        listVisits.add(visitNew);
        insert listVisits;
        final Id batchInstanceId = Database.executeBatch(new VisitTerritoryBatch(), 8);
        system.assertNotEquals(batchInstanceId, null, 'batchInstanceId NULL');

    }

}