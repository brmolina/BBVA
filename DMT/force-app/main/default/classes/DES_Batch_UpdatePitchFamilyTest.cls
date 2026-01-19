/********************************************************************************************
Name:             DES_Batch_UpdatePitchFamilyTest
Description:      Test de la clase DES_Batch_UpdatePitchFamily

Version        Date            Author            Summary of changes
---------------------------------------------------------------------------------------------
0.1            23/01/2020      Global Desktop    Test de la clase DES_Batch_UpdatePitchFamilyTest
*********************************************************************************************/
@isTest
public with sharing class DES_Batch_UpdatePitchFamilyTest {

    /**
	* @author Global Desktop
	* @description Method 1 Test
	*/
    @isTest
    public static void updateFamilyTest() {
    	final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
    	final Account acc1 = utilTestClass.createClient();
        final pith__Pitch__c pitchTest = new pith__Pitch__c();
        pitchTest.pith__participant_id__c = acc1.Id;
        pitchTest.pith__solution_category_name__c = 'IBF';
        pitchTest.pith__solution_name_path_desc__c = 'Corporate Loans';
        insert pitchTest;
        Test.startTest();
        final Id batchInstanceId = Database.executeBatch(new DES_Batch_UpdatePitchFamily(), 100);
        system.debug(batchInstanceId);
        System.assertNotEquals(pitchTest, null, 'Not  equeals');
        Test.stopTest();
    }

}