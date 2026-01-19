/*
* @author Global Desktop
* @description Test de la clase OppsCommercialActivityCont
*/
@isTest
public class OppsCommercialActivityContTest {
	/*
	* @author Global Desktop
	* @description Testeo de la clase OppsCommercialActivityCont
	*/
    @isTest
    public static void oppsCommercialActivityController() {
        final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
        final list<Account> accList = new list<Account>();
        final Account acc1 = utilTestClass.createClient();
        accList.add(acc1);
        final Account acc2 = utilTestClass.createClient();
        accList.add(acc2);
        insert accList;
        System.assertNotEquals(acc1,acc2);
        final Opportunity opp1 = utilTestClass.createOpportunity(acc2);
        opp1.StageName = Label.DES_Closed_Lose;
        opp1.DES_Reasons_Lost__c = 'Pricing';
        opp1.DES_Description_reason_for_lost_deal__c = 'test';
        opp1.opportunity_correct_ind_type__c = true;
        insert opp1;
        final dwp_acmh__Denorm_Account_Opportunity__c oppDenorm = new dwp_acmh__Denorm_Account_Opportunity__c ();
        oppDenorm.DES_Opportunity_Stage_Rollup__c = Label.DES_Closed_Lose;
        oppDenorm.dwp_acmh__AccountId__c = acc1.Id;
        oppDenorm.dwp_acmh__OpportunityId__c = opp1.Id;
        insert oppDenorm;

        Test.StartTest();
        OppsCommercialActivityController.getOppInfo(acc1.Id, 'Todos');
        OppsCommercialActivityController.getOppInfo(acc1.Id, 'Spain');
        Test.StopTest();
    }
}