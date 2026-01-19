/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 11-30-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
private class UserAmbitUpdate_test {

    @testSetup
    static void testSetup() {
        user testUser = TestFactory.createUser('Hector','BBVA Desktop ARCE');
        testUser.gf_user_operation_ambit_name__c = 'Arce - ambit - test';
        update testUser;
    }

	@isTest static void testTriggerUo() {
        Test.startTest();
		UO_Management__c testUo = new UO_Management__c();
        testUo.name = 'test';
        testUo.Ambit__c = 'Arce - ambit - test';
        insert testUo;
        System.assertEquals(testUo.Ambit__c, 'Arce - ambit - test');
        Test.stopTest();
	}

}