/***********************************************************************************************
Name:            DES_Booking_Batch_Handler_Test
Description:     Test Class for DES_Booking_Batch_Handler, its schedulable and handler

Version        Date            Author            Summary of changes
------------------------------------------------------------------------------------------------
1.0            24/03/2020      Global Desktop    Class creation

***********************************************************************************************/
@isTest
public class Batch_Total_Live_Won_Opps_Test {
    /**
    * Met0d0 test
    */
    @isTest
    public static void des_BatchOppTMInMigrationOppTest() {
        final DES_UtilTestClass utilClass = new DES_UtilTestClass();
        final Profile prof = [select Id FROM Profile WHERE Name = 'BBVA Desktop GTB Business Development' LIMIT 1];
        final User userTest = utilClass.createUser(prof.Id);
        insert userTest;
        final CIB_User_Org__c userSettings = utilClass.createCustomSetting();
        insert userSettings;
        system.runAs(userTest) {
            final list<Account> listAcc = new list<Account>();
            final Account acc = utilClass.createClient();
            listAcc.add(acc);
            final Account acc2 = utilClass.createClient();
            listAcc.add(acc2);
            insert listAcc;
            final Opportunity opp1 = utilClass.createOpportunity(acc);
            //opp1.StageName = Label.DES_Closed_Lose;
            insert opp1;
            final dwp_acmh__Denorm_Account_Opportunity__c oppDenorm = new dwp_acmh__Denorm_Account_Opportunity__c ();
            //oppDenorm.DES_Opportunity_Stage_Rollup__c = Label.DES_Closed_Lose;
            oppDenorm.dwp_acmh__AccountId__c = acc.Id;
            oppDenorm.dwp_acmh__OpportunityId__c = opp1.Id;
            insert oppDenorm;
        }
		Test.startTest();
        final Id batchInstanceId = Database.executeBatch(new Batch_Total_Live_Won_Opps(), 1);
        System.assertNotEquals(batchInstanceId, Null, 'Hay respuesta');
        Test.stopTest();
    }

}