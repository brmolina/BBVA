/**********************************************************************************
* @author       Global Desktop 
* @date         15/10/2019
* @description  DES_AP_OppSummaryInfoCnt Test
* @Revision     
**********************************************************************************/
@isTest
public class DES_AP_OppSummaryInfoCntTest {

    /* Declarando variable */
    public static final String WONLY = 'WonLastYear';
    /* Declarando variable */
    public static final String LOSTLY = 'LostLastYear';
    /* Declarando variable */
    public static final String OPENLY = 'OpenLastYear';
    /* Declarando variable */
    public static final String WONL4M = 'WonLast4M';
    /* Declarando variable */
    public static final String LOSTL4M = 'LostLast4M';
    /* Declarando variable */
    public static final String CREATEDLY = 'CreatedLastYear';
    /* Declarando variable */
    public static final String CREATEDL4M = 'CreatedLast4M';

    /* Declarando variable */
    public static final String QUERY = 'Query';
    /* Declarando variable */
    public static final String WONCLOSED = 'WonClosed';
    /* Declarando variable */
    public static final String CROSSBORDER = 'CrossBorder';
    /* Declarando variable */
    public static final String TOTALS = 'Totals';
    /* Declarando variable */
    public static final String TABLE = 'Table';
    
    /**
	* @author Global Desktop
	* @description Test
	*/
    @isTest
    public static void accOppTest() {

        final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
        final DES_UtilTestClassAux utilTestClassAux = new DES_UtilTestClassAux();

        final list<Account> accList = new list<Account>();
        final Account acc1 = utilTestClass.createClient();
        accList.add(acc1);
        final Account acc2 = utilTestClass.createClient();
        accList.add(acc2);
        insert accList;

        final acpl__AP_PeriodConfiguration__c apConfig = utilTestClass.createAPConfig();
        insert apConfig;

        final acpl__Account_Plan_Settings__c apSettings = new acpl__Account_Plan_Settings__c();
        apSettings.acpl__Unlock_when_change_DueDate__c = false;
        insert apSettings;

        final list<acpl__Account_Planning__c> accPlanList = new list<acpl__Account_Planning__c>();
        final acpl__Account_Planning__c accountPlan1 = utilTestClass.createAccountPlanning(acc1);
        accPlanList.add(accountPlan1);
        final acpl__Account_Planning__c accountPlan2 = utilTestClass.createAccountPlanning(acc2);
        accPlanList.add(accountPlan2);
        insert accPlanList;

        final list<DES_Group_Analysis__c> gAnalysisList = new list<DES_Group_Analysis__c>();
        final DES_Group_Analysis__c gAnalysis1 = utilTestClassAux.createGroupAnalysis(accountPlan1,acc1);
        gAnalysisList.add(gAnalysis1);
        final DES_Group_Analysis__c gAnalysis2 = utilTestClassAux.createGroupAnalysis(accountPlan2,acc2);
        gAnalysisList.add(gAnalysis2);
        insert gAnalysisList;

        final list<Opportunity> oppList = new list<Opportunity>();

        final Opportunity opp0 = utilTestClass.createOpportunity(acc1);
        opp0.CreatedDate = system.Today();
        opp0.DES_Cross_border__c = true;
        opp0.CloseDate = system.Today().addMonths(-1);
        opp0.StageName = Label.DES_Closed_Won;
        oppList.add(opp0);

        final Opportunity opp1 = utilTestClass.createOpportunity(acc1);
        opp1.CreatedDate = system.Today().addMonths(-2);
        opp1.DES_Cross_border__c = true;
        opp1.CloseDate = system.Today().addMonths(-1);
        opp1.StageName = Label.DES_Closed_Won;
        oppList.add(opp1);

        final Opportunity opp2 = utilTestClass.createOpportunity(acc1);
        opp2.CreatedDate = system.Today().addMonths(-2);
        opp2.DES_Cross_border__c = true;
        opp2.CloseDate = system.Today().addMonths(-12);
        opp2.DES_Description_reason_for_lost_deal__c = 'Lorem';
        opp2.DES_Reasons_Lost__c = 'Pricing';
        opp2.StageName = Label.DES_Closed_Lose;
        oppList.add(opp2);

        final Opportunity opp3 = utilTestClass.createOpportunity(acc1);
        opp3.CreatedDate = system.Today().addMonths(-12);
        opp3.DES_Cross_border__c = true;
        opp3.CloseDate = system.Today().addMonths(-2);
        opp3.StageName = Label.DES_Closed_Won;
        oppList.add(opp3);

        final Opportunity opp4 = utilTestClass.createOpportunity(acc1);
        opp4.CreatedDate = system.Today().addMonths(-12);
        opp4.DES_Cross_border__c = true;
        opp4.CloseDate = system.Today().addMonths(-12);
        opp4.DES_Description_reason_for_lost_deal__c = 'Lorem';
        opp4.DES_Reasons_Lost__c = 'Pricing';
        opp4.StageName = Label.DES_Closed_Lose;
        oppList.add(opp4);

        insert oppList;

        final list<dwp_acmh__Denorm_Account_Opportunity__c> denormOppList = new list<dwp_acmh__Denorm_Account_Opportunity__c>();

        final dwp_acmh__Denorm_Account_Opportunity__c oppDenorm1 = new dwp_acmh__Denorm_Account_Opportunity__c ();
        oppDenorm1.dwp_acmh__AccountId__c = acc1.Id;
        oppDenorm1.dwp_acmh__OpportunityId__c = opp1.Id;
        denormOppList.add(oppDenorm1);

        final dwp_acmh__Denorm_Account_Opportunity__c oppDenorm2 = new dwp_acmh__Denorm_Account_Opportunity__c ();
        oppDenorm2.dwp_acmh__AccountId__c = acc1.Id;
        oppDenorm2.dwp_acmh__OpportunityId__c = opp2.Id;
        denormOppList.add(oppDenorm2);

        final dwp_acmh__Denorm_Account_Opportunity__c oppDenorm3 = new dwp_acmh__Denorm_Account_Opportunity__c ();
        oppDenorm3.dwp_acmh__AccountId__c = acc1.Id;
        oppDenorm3.dwp_acmh__OpportunityId__c = opp3.Id;
        denormOppList.add(oppDenorm3);

        final dwp_acmh__Denorm_Account_Opportunity__c oppDenorm4 = new dwp_acmh__Denorm_Account_Opportunity__c ();
        oppDenorm4.dwp_acmh__AccountId__c = acc1.Id;
        oppDenorm4.dwp_acmh__OpportunityId__c = opp4.Id;
        denormOppList.add(oppDenorm4);


        Test.StartTest();
        insert denormOppList;
        final String result = DES_AP_OppSummaryInfoCnt.getRelatedOpportunities(gAnalysis1.Id, WONLY, QUERY, TOTALS);
        DES_AP_OppSummaryInfoCnt.getRelatedOpportunities(gAnalysis1.Id, LOSTLY, QUERY, TOTALS);
        DES_AP_OppSummaryInfoCnt.getRelatedOpportunities(gAnalysis1.Id, OPENLY, QUERY, TOTALS);
        DES_AP_OppSummaryInfoCnt.getRelatedOpportunities(gAnalysis1.Id, WONL4M, QUERY, TOTALS);
        DES_AP_OppSummaryInfoCnt.getRelatedOpportunities(gAnalysis1.Id, LOSTL4M, QUERY, TOTALS);
        DES_AP_OppSummaryInfoCnt.getRelatedOpportunities(gAnalysis1.Id, CREATEDLY, WONClosed, TOTALS);
        DES_AP_OppSummaryInfoCnt.getRelatedOpportunities(gAnalysis1.Id, CREATEDL4M, CROSSBORDER, TOTALS);
        DES_AP_OppSummaryInfoCnt.getRelatedOpportunities(gAnalysis1.Id, WONLY, QUERY, TABLE);
        DES_AP_OppSummaryInfoCnt.getRelatedOpportunities(gAnalysis1.Id, LOSTLY, QUERY, TABLE);
        DES_AP_OppSummaryInfoCnt.getRelatedOpportunities(gAnalysis1.Id, OPENLY, QUERY, TABLE);
        DES_AP_OppSummaryInfoCnt.getRelatedOpportunities(gAnalysis1.Id, WONL4M, QUERY, TABLE);
        DES_AP_OppSummaryInfoCnt.getRelatedOpportunities(gAnalysis1.Id, LOSTL4M, QUERY, TABLE);
        DES_AP_OppSummaryInfoCnt.getRelatedOpportunities(gAnalysis1.Id, CREATEDLY, WONClosed, TABLE);
        DES_AP_OppSummaryInfoCnt.getRelatedOpportunities(gAnalysis1.Id, CREATEDL4M, CROSSBORDER, TABLE);
        DES_AP_OppSummaryInfoCnt.getRelatedOpportunities(gAnalysis2.Id, WONLY, QUERY, TOTALS);
        DES_AP_OppSummaryInfoCnt.getRelatedOpportunities(gAnalysis2.Id, LOSTLY, QUERY, TOTALS);
        DES_AP_OppSummaryInfoCnt.getRelatedOpportunities(gAnalysis2.Id, OPENLY, QUERY, TOTALS);
        DES_AP_OppSummaryInfoCnt.getRelatedOpportunities(gAnalysis2.Id, WONL4M, QUERY, TOTALS);
        DES_AP_OppSummaryInfoCnt.getRelatedOpportunities(gAnalysis2.Id, LOSTL4M, QUERY, TOTALS);
        DES_AP_OppSummaryInfoCnt.getRelatedOpportunities(gAnalysis2.Id, CREATEDLY, WONClosed, TOTALS);
        DES_AP_OppSummaryInfoCnt.getRelatedOpportunities(gAnalysis2.Id, CREATEDL4M, CROSSBORDER, TOTALS);
        DES_AP_OppSummaryInfoCnt.getRelatedOpportunities(gAnalysis2.Id, WONLY, QUERY, TABLE);
        DES_AP_OppSummaryInfoCnt.getRelatedOpportunities(gAnalysis2.Id, LOSTLY, QUERY, TABLE);
        DES_AP_OppSummaryInfoCnt.getRelatedOpportunities(gAnalysis2.Id, OPENLY, QUERY, TABLE);
        DES_AP_OppSummaryInfoCnt.getRelatedOpportunities(gAnalysis2.Id, WONL4M, QUERY, TABLE);
        DES_AP_OppSummaryInfoCnt.getRelatedOpportunities(gAnalysis2.Id, LOSTL4M, QUERY, TABLE);
        DES_AP_OppSummaryInfoCnt.getRelatedOpportunities(gAnalysis2.Id, CREATEDLY, WONClosed, TABLE);
        DES_AP_OppSummaryInfoCnt.getRelatedOpportunities(gAnalysis2.Id, CREATEDL4M, CROSSBORDER, TABLE);
        System.assert(result != null, 'No opps retrieved');
        Test.StopTest();
    }
}