/**********************************************************************************
* @author       Global Desktop 
* @date         22/07/2019
* @description  Clase de test de Group Analysis
* @Revision     
**********************************************************************************/
@isTest
public class DES_GroupAnalysisHandlerTest {
    
    /*
    * @author       Global Desktop                 
    * @Description	updateGAlookupInAP test
    */
    @IsTest
    static void updateGAlookupInAPTest() {
      final DES_UtilTestClass utils = new DES_UtilTestClass();
      final DES_UtilTestClassAux utilsAux = new DES_UtilTestClassAux();

      //Creación cuenta
      final Account account = utils.createClient();
      insert account;

      final acpl__AP_PeriodConfiguration__c apConfig = utils.createAPConfig();
      insert apConfig;

      final acpl__AP_Period__c apPeriod = utils.createAPPeriod();
      apPeriod.acpl__gf_ap_edit_start_date__c = date.Today()+1;
      insert apPeriod;

      final acpl__Account_Plan_Settings__c apSettings = new acpl__Account_Plan_Settings__c();
      apSettings.acpl__Unlock_when_change_DueDate__c = false;
      insert apSettings;

      //Creación del account planning
      final acpl__Account_Planning__c accountPlanning = utils.createAccountPlanning(account);
      insert accountPlanning;

      final DES_Group_Analysis__c groupAnalysis = utilsAux.createGroupAnalysis(accountPlanning, account);

      Test.startTest();
          insert groupAnalysis;
      Test.stopTest();
      final List<acpl__Account_Planning__c> apList = [SELECT gf_participant_analysis_id__c FROM acpl__Account_Planning__c WHERE gf_participant_analysis_id__c = :groupAnalysis.Id];
      System.assert(!apList.isEmpty(), 'Group Analysis lookup not filled');
    }

    /*
    * @author       Global Desktop                 
    * @Description  updateGAlookupInAP test2
    */
    @IsTest
    static void updateGAlookupInAPTest2() {
      final DES_UtilTestClass utils = new DES_UtilTestClass();
      final DES_UtilTestClassAux utilsAux = new DES_UtilTestClassAux();

      //Creación cuenta
      final Account account = utils.createClient();
      insert account;

      final acpl__AP_PeriodConfiguration__c apConfig = utils.createAPConfig();
      insert apConfig;

      final acpl__AP_Period__c apPeriod = utils.createAPPeriod();
      apPeriod.acpl__gf_ap_edit_start_date__c = date.Today()+1;
      insert apPeriod;

      final acpl__Account_Plan_Settings__c apSettings = new acpl__Account_Plan_Settings__c();
      apSettings.acpl__Unlock_when_change_DueDate__c = false;
      insert apSettings;

      //Creación del account planning
      final acpl__Account_Planning__c accountPlanning = utils.createAccountPlanning(account);
      insert accountPlanning;

      accountPlanning.acpl__gf_ap_indvi_lock_edit_ind_type__c=false;
      update accountPlanning;

      final DES_Group_Analysis__c groupAnalysis = utilsAux.createGroupAnalysis(accountPlanning, account);

      Test.startTest();
          insert groupAnalysis;
      Test.stopTest();
      final List<acpl__Account_Planning__c> apList = [SELECT gf_participant_analysis_id__c FROM acpl__Account_Planning__c WHERE gf_participant_analysis_id__c = :groupAnalysis.Id];
      System.assert(!apList.isEmpty(), 'Group Analysis lookup not filled');
    }
}