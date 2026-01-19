/**********************************************************************************
* @author       Global Desktop 
* @date         15/10/2019
* @description  DES_AP_RelatedOpenOppsController Test
* @Revision     
**********************************************************************************/
@isTest
public class DES_AP_RelatedOpenOppsControllerTest{
    /**
	* @author Global Desktop
	* @description Test
	*/
    @isTest
    public static void getRelatedOpportunitiesTest(){
        final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
        final DES_UtilTestClassAux utilTestClassAux = new DES_UtilTestClassAux();
        
        list<Account> accList = new list<Account>();
        Account acc1 = utilTestClass.createClient();
        accList.add(acc1);
        Account acc2 = utilTestClass.createClient();
        accList.add(acc2);
        insert accList;
        System.assertNotEquals(acc1 ,acc2);
        
        final acpl__AP_PeriodConfiguration__c apConfig = utilTestClass.createAPConfig();
        insert apConfig;

        final acpl__Account_Plan_Settings__c apSettings = new acpl__Account_Plan_Settings__c();
        apSettings.acpl__Unlock_when_change_DueDate__c = false;
        insert apSettings;
        
        final acpl__Account_Planning__c accountPlan = utilTestClass.createAccountPlanning(acc1);
        insert accountPlan;
        
        Opportunity opp1 = utilTestClass.createOpportunity(acc2);
        insert opp1;
        
        dwp_acmh__Denorm_Account_Opportunity__c oppDenorm = new dwp_acmh__Denorm_Account_Opportunity__c ();
        oppDenorm.DES_Opportunity_Stage_Rollup__c = Label.DES_Proposal;
        oppDenorm.dwp_acmh__AccountId__c = acc1.Id;
        oppDenorm.dwp_acmh__OpportunityId__c = opp1.Id;
        insert oppDenorm;

        final DES_Group_Analysis__c gAnalysis = utilTestClassAux.createGroupAnalysis(accountPlan,acc1);
        insert gAnalysis;

        Test.StartTest();
        DES_AP_RelatedOpenOppsController.gtAPAccountId(accountPlan.Id);
        DES_AP_RelatedOpenOppsController.gtGAAccountId(gAnalysis.Id);
        DES_AP_RelatedOpenOppsController.getRelatedOpportunities('2', accountPlan.acpl__participant_id__c,null);
        DES_AP_RelatedOpenOppsController.getRelatedOpportunities('2',gAnalysis.participant_id__c,'WonLast4M');
        DES_AP_RelatedOpenOppsController.getRelatedOpportunities('2',gAnalysis.participant_id__c,'LostLast4M');
        DES_AP_RelatedOpenOppsController.getRelatedOpportunities('2',gAnalysis.participant_id__c,'WonLastYear');
        DES_AP_RelatedOpenOppsController.getRelatedOpportunities('2',gAnalysis.participant_id__c,'LostLastYear');
        DES_AP_RelatedOpenOppsController.getRelatedOpportunities('2',gAnalysis.participant_id__c,'CreatedLast4M');
        DES_AP_RelatedOpenOppsController.getRelatedOpportunities('2',gAnalysis.participant_id__c,'CreatedLastYear');
        System.assertEquals(true, accountPlan.acpl__participant_id__c == acc1.Id);
        Test.StopTest();
    }
}