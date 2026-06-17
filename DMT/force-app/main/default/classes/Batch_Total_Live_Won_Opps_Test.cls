/***********************************************************************************************
 Name:            DES_Booking_Batch_Handler_Test
 Description:     Test Class for DES_Booking_Batch_Handler, its schedulable and handler

 Version        Date            Author            Summary of changes
 ------------------------------------------------------------------------------------------------
 1.0            24/03/2020      Global Desktop    Class creation

 ***********************************************************************************************/
@isTest
public class Batch_Total_Live_Won_Opps_Test{
    /**
     * Met0d0 test
     */
    @isTest
    public static void des_BatchOppTMInMigrationOppTest(){
        final DES_UtilTestClass utilClass = new DES_UtilTestClass();
        final CIB_User_Org__c userSettings = utilClass.createCustomSetting();
        insert userSettings;
        List<Account> accs = new List<Account>();
        Account acc = utilClass.createClient();
        acc.DES_Country_Client__c = 'ES';
        accs.add(acc);
        Account acc2 = utilClass.createClient();
        acc2.DES_Country_Client__c = 'ES';
        accs.add(acc2);

        insert accs;
        final Opportunity opp1 = utilClass.createOpportunity(acc);
        //opp1.StageName = Label.DES_Closed_Lose;
        insert opp1;
        final AMH_Denorm_Account_Opportunity__c oppDenorm = new AMH_Denorm_Account_Opportunity__c();
        //oppDenorm.DES_Opportunity_Stage_Rollup__c = Label.DES_Closed_Lose;
        oppDenorm.AMH_AccountId__c = acc.Id;
        oppDenorm.AMH_OpportunityId__c = opp1.Id;
        insert oppDenorm;
        Test.startTest();
        final Id batchInstanceId = Database.executeBatch(new Batch_Total_Live_Won_Opps(), 1);
        System.assertNotEquals(batchInstanceId, Null, 'Hay respuesta');
        Test.stopTest();
    }

}