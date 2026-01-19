/*
 * @author	Global Desktop
 * @Description	Clase de test para las clases UserToTerritoryBatch, UserTerritorySharing
 *
 */
@isTest
public class UserToTerritoryBatchTest {
	/*
	 * 	@author	Global Desktop
	 * 	@Description	Method que testea el batch y las clases UserToTerritoryBatch, UserTerritorySharing
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
        final Id batchInstanceId = Database.executeBatch(new UserToTerritoryBatch(), 8);
        system.assertNotEquals(batchInstanceId, null, 'batchInstanceId NULL');

    }
    /*
	 * 	@author	Global Desktop
	 * 	@Description	Method que testea el batch y las clases UserToTerritoryBatch, UserTerritorySharing
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
        final Id batchInstanceId = Database.executeBatch(new UserToTerritoryBatch(), 8);
        system.assertNotEquals(batchInstanceId, null, 'batchInstanceId NULL');

    }

}