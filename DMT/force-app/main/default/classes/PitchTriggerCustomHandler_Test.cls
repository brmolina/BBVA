/********************************************************************************************
Name:            PitchTriggerCustomHandler_Test
Description:     Test de PitchTriggerCustom
Test Class:      

Version        Date            Author            Summary of changes
---------------------------------------------------------------------------------------------
1              13/11/2019      Global Desktop    Class creation    
*********************************************************************************************/
@isTest
public class PitchTriggerCustomHandler_Test {

    /**
	* Test method for PitchTriggerCustomHandler class
	*/
    @isTest
    public static void testChangeRecordType() {
        final DES_UtilTestClass iUtilClass = new DES_UtilTestClass();

		//RecordTypes de cuenta.
		final Id rtGROUP = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.DES_STR_TYPE_Group).getRecordTypeId();
		final Id rtFILIAL = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.DES_RT_Subsidiary).getRecordTypeId();

		//Declaración de las cuentas
		final List<Account> listAccount = new List<Account>();
		final Account iAccount = iUtilClass.createClient();
    	iAccount.Name = 'Grupo_A_ES';
    	iAccount.DES_BBVA_Segmentation__c = 'B';
    	iAccount.DES_Structure_Type__c = 'Group';
    	iAccount.DES_Country_Client__c = 'ES';
		iAccount.recordTypeId = rtGROUP;
		iAccount.DES_Segment__c = '00005'; // Corporate
		listAccount.add(iAccount);
    	final Account iAccountMatrix = iUtilClass.createClient();
    	iAccountMatrix.Name = 'Matriz_A_ES';
    	iAccountMatrix.DES_BBVA_Segmentation__c = 'B';
    	iAccountMatrix.DES_Structure_Type__c = 'Subsidiary';
    	iAccountMatrix.DES_Entity_Hierarchy__c = 'S';
    	iAccountMatrix.DES_Main_Parent__c = iAccount.Id;
    	iAccountMatrix.DES_Country_Client__c = 'ES';
		iAccountMatrix.recordTypeId = rtFILIAL;
		listAccount.add(iAccountMatrix);
		insert listAccount;
        
        System.debug('::::::::Label.DES_Corporate_Loans: ' + Label.DES_Corporate_Loans);
        System.debug('::::::::iAccountMatrix.Id: ' + iAccountMatrix.Id);
        final pith__Pitch__c iPitch = new pith__Pitch__c();
        iPitch.gf_filter_type_participant_id__c = iAccountMatrix.Id;
        iPitch.pith__country_name__c = 'Spain';
        iPitch.pith__solution_category_name__c = 'GF';
        iPitch.pith__solution_name_path_desc__c = Label.DES_Corporate_Loans;
        iPitch.pith__gf_recent_pitch_type__c = true;
        insert iPitch;
        
        Test.startTest();
        final PitchTriggerCustomHandler pitchHandler = new PitchTriggerCustomHandler();
        final List<pith__Pitch__c> listPitch = new List<pith__Pitch__c>();
        listPitch.add(iPitch);
        pitchHandler.changeRecordType(listPitch);
        
        final pith__Pitch__c iPitchRT = [SELECT Id, RecordTypeId FROM pith__Pitch__c LIMIT 1];
        System.assertEquals(
            Schema.SObjectType.pith__Pitch__c.getRecordTypeInfosByName().get(System.Label.PitchRecordLayout).getRecordTypeId(),
            iPitch.RecordTypeId,
            'Pitch RT is not equal to Pitch record layout'
        );
        Test.stopTest();
    }
}