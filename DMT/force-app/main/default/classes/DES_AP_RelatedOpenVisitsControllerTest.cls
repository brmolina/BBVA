/**********************************************************************************
* @author       Global Desktop 
* @date         15/10/2019
* @description  DES_AP_RelatedOpenVisitsController Test
* @Revision     
**********************************************************************************/
@isTest
public class DES_AP_RelatedOpenVisitsControllerTest {
	/**
	* @author Global Desktop
	* @description Test
	*/
  	@isTest
  	public static void NextVisitsByFamilyCont() {
	    final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
	   
	    final Account acc1 = utilTestClass.createClient();
	    insert acc1;
        
        final acpl__AP_PeriodConfiguration__c apConfig = utilTestClass.createAPConfig();
        insert apConfig;

        final acpl__Account_Plan_Settings__c apSettings = new acpl__Account_Plan_Settings__c();
        apSettings.acpl__Unlock_when_change_DueDate__c = false;
        insert apSettings;
        
        final acpl__Account_Planning__c accountPlan = utilTestClass.createAccountPlanning(acc1);
        insert accountPlan;
	
	    final dwp_kitv__Visit__c vis1 =  utilTestClass.createVisit(acc1, null);
	    //vis1.solution_name_path_desc__c = 'GTB';
	    insert vis1;
	    
	    Test.StartTest();
        DES_AP_RelatedOpenVisitsController.gtAPAccountId(accountPlan.Id);
	    DES_AP_RelatedOpenVisitsController.getRelatedVisits('2', accountPlan.acpl__participant_id__c);
	    System.assertEquals(true, accountPlan.acpl__participant_id__c == acc1.Id);
	    Test.StopTest();
  }
}