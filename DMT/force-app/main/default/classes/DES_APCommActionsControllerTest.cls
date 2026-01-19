/**********************************************************************************
* @author       Accenture
* @date         01/10/2019
* @description  Clase test de DES_APCommActionsController
* @Revision
**********************************************************************************/
@isTest
public class DES_APCommActionsControllerTest {
    
    /*
    * @author Global Desktop
    * @description DES_APCommActionsController test method
    */
    @isTest
    public static void getDataTest() {
        final DES_UtilTestClass utils = new DES_UtilTestClass();
        final DES_UtilTestClassAux utilsAux = new DES_UtilTestClassAux();
        
        final Account account = utils.createClient();
        insert account;
        
        final dwp_kitv__Visit__c visit1 = utils.createVisit(account, null);
        visit1.dwp_kitv__visit_channel__c = '01';
        visit1.dwp_kitv__visit_status_type__c = '01';
        
        final dwp_kitv__Visit__c visit2 = utils.createVisit(account, null);
        visit2.dwp_kitv__visit_channel__c = '01';
        visit2.dwp_kitv__visit_status_type__c = '01';
        
        final dwp_kitv__Visit__c visit3 = utils.createVisit(account, null);
        visit3.dwp_kitv__visit_channel__c = '02';
        visit3.dwp_kitv__visit_status_type__c = '02';
        
        List<dwp_kitv__Visit__c> visitList;
        visitList = new List <dwp_kitv__Visit__c>();
        visitList.add(visit1);
        visitList.add(visit2);
        visitList.add(visit3);
        insert visitList;
        
        final DES_Denorm_AccountVisits__c denormVisitList1 = utils.createDenVisit(account, visit1);
        final DES_Denorm_AccountVisits__c denormVisitList2 = utils.createDenVisit(account, visit2);
        final DES_Denorm_AccountVisits__c denormVisitList3 = utils.createDenVisit(account, visit3);
        List<DES_Denorm_AccountVisits__c> denormVisitList; 
        denormVisitList = new List <DES_Denorm_AccountVisits__c>();
        denormVisitList.add(denormVisitList1);
        denormVisitList.add(denormVisitList2);
        denormVisitList.add(denormVisitList3);
        insert denormVisitList;
        
        final acpl__AP_PeriodConfiguration__c apConfig = utils.createAPConfig();
        insert apConfig;
        
        final acpl__AP_Period__c apPeriod = utils.createAPPeriod();
        apPeriod.acpl__gf_ap_edit_start_date__c = date.Today()+1;
        insert apPeriod;

        final acpl__Account_Plan_Settings__c apSettings = new acpl__Account_Plan_Settings__c();
        apSettings.acpl__Unlock_when_change_DueDate__c = false;
        insert apSettings;

        final acpl__Account_Planning__c accountPlanning = utils.createAccountPlanning(account);
        insert accountPlanning;
        
        final DES_Group_Analysis__c groupAnalysis = utilsAux.createGroupAnalysis(accountPlanning, account);
        insert groupAnalysis;
        
        Test.startTest();
        DES_APCommActionsController.getData(groupAnalysis.Id, 'Status');
        DES_APCommActionsController.getData(groupAnalysis.Id, 'Type');
        final String result = DES_APCommActionsController.getTableData(groupAnalysis.Id);
        Test.stopTest();
        System.assert(result != null, 'Data not created.');
    }
}