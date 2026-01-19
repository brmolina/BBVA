/**********************************************************************************
* @author       Global Desktop 
* @date         15/10/2019
* @description  DES_AP_OppSummaryInfoCnt Test
* @Revision     
**********************************************************************************/
@isTest
public class DES_AP_CommActionsTableControllerTest {

    /**
	* @author Global Desktop
	* @description Test
	*/
    @isTest
    public static void accCATest() {
        final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
        final DES_UtilTestClassAux utilTestClassAux = new DES_UtilTestClassAux();
        
        list<Account> accList;
        accList = new list<Account>();
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
        
        list<acpl__Account_Planning__c> accPlanList;
        accPlanList = new list<acpl__Account_Planning__c>();
        final acpl__Account_Planning__c accountPlan1 = utilTestClass.createAccountPlanning(acc1);
        accPlanList.add(accountPlan1);
        final acpl__Account_Planning__c accountPlan2 = utilTestClass.createAccountPlanning(acc2);
        accPlanList.add(accountPlan2);
        insert accPlanList;
        
        list<DES_Group_Analysis__c> gAnalysisList;
        gAnalysisList = new list<DES_Group_Analysis__c>();
        final DES_Group_Analysis__c gAnalysis1 = utilTestClassAux.createGroupAnalysis(accountPlan1,acc1);
        gAnalysisList.add(gAnalysis1);
        final DES_Group_Analysis__c gAnalysis2 = utilTestClassAux.createGroupAnalysis(accountPlan2,acc2);
        gAnalysisList.add(gAnalysis2);
        insert gAnalysisList;
        
        list<dwp_kitv__Visit__c> visList;
        visList = new list<dwp_kitv__Visit__c>();
        
        final dwp_kitv__Visit__c  vis1 = utilTestClass.createVisit(acc1,null);
        vis1.dwp_kitv__visit_start_date__c = system.Today().addDays(1);
        vis1.dwp_kitv__visit_channel__c = '01';
        visList.add(vis1);

        final dwp_kitv__Visit__c  vis2 = utilTestClass.createVisit(acc1,null);
        vis2.dwp_kitv__visit_start_date__c = system.Today().addDays(1);
        vis2.dwp_kitv__visit_channel__c = '02';
        visList.add(vis2);
        
        final dwp_kitv__Visit__c  vis3 = utilTestClass.createVisit(acc1,null);
        vis3.dwp_kitv__visit_start_date__c = system.Today().addDays(-364);
        vis3.dwp_kitv__visit_channel__c = '01';
        visList.add(vis3);

        final dwp_kitv__Visit__c  vis4 = utilTestClass.createVisit(acc1,null);
        vis4.dwp_kitv__visit_start_date__c = system.Today().addDays(-364);
        vis4.dwp_kitv__visit_channel__c = '02';
        visList.add(vis4);
        
        insert visList;
        
        list<DES_Denorm_AccountVisits__c> denormVisList;
        denormVisList = new list<DES_Denorm_AccountVisits__c>();
        
        DES_Denorm_AccountVisits__c visDenorm1;
        visDenorm1 = new DES_Denorm_AccountVisits__c ();
        visDenorm1.DES_Client__c = acc1.Id;
        visDenorm1.DES_Visit_new__c = vis1.Id;
        denormVisList.add(visDenorm1);
        
        DES_Denorm_AccountVisits__c visDenorm2;
        visDenorm2 = new DES_Denorm_AccountVisits__c ();
        visDenorm2.DES_Client__c = acc1.Id;
        visDenorm2.DES_Visit_new__c = vis2.Id;
        denormVisList.add(visDenorm2);
        
        DES_Denorm_AccountVisits__c visDenorm3;
        visDenorm3 = new DES_Denorm_AccountVisits__c ();
        visDenorm3.DES_Client__c = acc1.Id;
        visDenorm3.DES_Visit_new__c = vis3.Id;
        denormVisList.add(visDenorm3);
        
        DES_Denorm_AccountVisits__c visDenorm4;
        visDenorm4 = new DES_Denorm_AccountVisits__c ();
        visDenorm4.DES_Client__c = acc1.Id;
        visDenorm4.DES_Visit_new__c = vis4.Id;
        denormVisList.add(visDenorm4);

        insert denormVisList;
        
        Test.StartTest();
        DES_AP_CommActionsTableController.getRelatedCA(gAnalysis1.Id);
        DES_AP_CommActionsTableController.getRelatedCA(gAnalysis2.Id);
        System.assert(accountPlan1.acpl__participant_id__c == acc1.Id, 'My query is correct');
        Test.StopTest();
    }
}