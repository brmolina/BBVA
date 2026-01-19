/**********************************************************************************
* @author      	Global Desktop
* @date         23/11/2019
* @description  Product Analysis table Controller's test class
* @Revision
**********************************************************************************/
@isTest
global class DES_AP_BPProductAnalysis_CTRL_Test {

  /* Gets grid data for the related BP */
  @IsTest
  static void testGetGridDataAndCheck() {
    final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
    final DES_UtilTestClassAux utilTestClassAux = new DES_UtilTestClassAux();
    
    final Account accTest = utilTestClass.createClient();
    insert accTest;
    final acpl__AP_PeriodConfiguration__c apConfig = utilTestClass.createAPConfig();
    insert apConfig;

    final acpl__Account_Plan_Settings__c apSettings = new acpl__Account_Plan_Settings__c();
    apSettings.acpl__Unlock_when_change_DueDate__c = false;
    insert apSettings;

    final acpl__Account_Planning__c accountPlanning = utilTestClass.createAccountPlanning(accTest);
    insert accountPlanning;
    
    final bupl__BusinessPlan__c bpTest = utilTestClassAux.createBusinessPlan(accountPlanning,accTest);
    insert bpTest;

    final bupl__BusinessPlan_Version__c  bpVersion = utilTestClassAux.createBusinessPlanVersion(bpTest);
    insert bpVersion;

    final List<bupl__BusinessPlan_Item__c> liBPItems = new List<bupl__BusinessPlan_Item__c>();
    final bupl__BusinessPlan_Item__c bpItem = utilTestClassAux.createBusinessPlanItemXSell(bpVersion);
    final bupl__BusinessPlan_Item__c bpItem2 = utilTestClassAux.createBusinessPlanItemNormal(bpVersion);
    bpItem2.bupl__gf_business_plan_version_id__c = bpVersion.Id;
    bpItem2.bupl__gf_booking_operation_cntry_id__c = 'Italy';
    bpItem2.bupl__solution_category_id__c = 'GTB';
    bpItem2.bupl__solution_category_desc__c = 'Producto';
    bpItem2.gf_est_ginc_lcl_product_amount__c = 2637166;
    bpItem2.bupl__expected_revenue_amount__c = 2267649;
    bpItem2.other_information_desc__c = 'Comment';
    bpItem2.bbva_share_of_wallet_per__c = 1;
    bpItem2.gf_potencial_level_oppy_type__c = 'High';
    bpItem2.gf_lcl_prdt_sustnbl_oppy_name__c = 'Yes';
    liBPItems.add(bpITem);
    liBPItems.add(bpItem2);
    insert liBPItems;
    
    
    final String profile = utilTestClass.createProfile();
    final User user = utilTestClass.createUser(profile, 'username@test.comm');
    insert user;
    final bupl__AP_Team__c apTeamMember = utilTestClass.createAPTeamMember(user,accountPlanning);
    insert apTeamMember;
    

    Test.startTest();
    String gridData = DES_AP_BPProductAnalysis_CTRL.getGridData('bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__r.bupl__participant_id__c = \''+ accTest.Id + '\'','bupl__gf_booking_operation_cntry_id__c = \'' + bpItem2.bupl__gf_booking_operation_cntry_id__c + '\'','bupl__solution_category_id__c', '', false);
    Test.stopTest();
    System.assert(gridData != null,'Did not gridData Table Data correctly.');
  }

  /* Gets table data for the related BP */
  @IsTest
  static void testGetTableData() {
    final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
    final DES_UtilTestClassAux utilTestClassAux = new DES_UtilTestClassAux();
    
    final Account accTest = utilTestClass.createClient();
    insert accTest;
    final acpl__AP_PeriodConfiguration__c apConfig = utilTestClass.createAPConfig();
    insert apConfig;

    final acpl__Account_Plan_Settings__c apSettings = new acpl__Account_Plan_Settings__c();
    apSettings.acpl__Unlock_when_change_DueDate__c = false;
    insert apSettings;

    final acpl__Account_Planning__c accountPlanning = utilTestClass.createAccountPlanning(accTest);
    insert accountPlanning;
    
    final bupl__BusinessPlan__c bpTest = utilTestClassAux.createBusinessPlan(accountPlanning,accTest);
    insert bpTest;

    final bupl__BusinessPlan_Version__c  bpVersion = utilTestClassAux.createBusinessPlanVersion(bpTest);
    insert bpVersion;

    final List<bupl__BusinessPlan_Item__c> liBPItems = new List<bupl__BusinessPlan_Item__c>();
    final bupl__BusinessPlan_Item__c bpItem = utilTestClassAux.createBusinessPlanItemXSell(bpVersion);
    final bupl__BusinessPlan_Item__c bpItem2 = utilTestClassAux.createBusinessPlanItemNormal(bpVersion);
    liBPItems.add(bpITem);
    liBPItems.add(bpItem2);
    insert liBPItems;
    

    
    final String profile = utilTestClass.createProfile();
    final User user = utilTestClass.createUser(profile, 'username@test.comm');
    insert user;
    final bupl__AP_Team__c apTeamMember = utilTestClass.createAPTeamMember(user,accountPlanning);
    insert apTeamMember;

    Test.startTest();
    String tableData = DES_AP_BPProductAnalysis_CTRL.getTableData('bupl__gf_business_plan_version_id__r.bupl__gf_business_plan_id__r.bupl__participant_id__c = \''+ accTest.Id + '\'','bupl__gf_booking_operation_cntry_id__c = \'' + bpItem2.bupl__gf_booking_operation_cntry_id__c + '\'','bupl__solution_category_id__c', '', false);
    Test.stopTest();

    System.assert(tableData != null,'Did not retrieve Table Data correctly.');
  }

  /* Saves data from inline edit in BP Items */
  @IsTest
  static void testSaveData() {
    final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
    final DES_UtilTestClassAux utilTestClassAux = new DES_UtilTestClassAux();
    
    final Account accTest = utilTestClass.createClient();
    insert accTest;
    final acpl__AP_PeriodConfiguration__c apConfig = utilTestClass.createAPConfig();
    insert apConfig;

    final acpl__Account_Plan_Settings__c apSettings = new acpl__Account_Plan_Settings__c();
    apSettings.acpl__Unlock_when_change_DueDate__c = false;
    insert apSettings;
    
    final acpl__Account_Planning__c accountPlanning = utilTestClass.createAccountPlanning(accTest);
    insert accountPlanning;
    
    final bupl__BusinessPlan__c bpTest = utilTestClassAux.createBusinessPlan(accountPlanning,accTest);
    insert bpTest;

    final bupl__BusinessPlan_Version__c  bpVersion = utilTestClassAux.createBusinessPlanVersion(bpTest);
    insert bpVersion;

    final List<bupl__BusinessPlan_Item__c> liBPItems = new List<bupl__BusinessPlan_Item__c>();
    final bupl__BusinessPlan_Item__c bpItem = utilTestClassAux.createBusinessPlanItemXSell(bpVersion);
    final bupl__BusinessPlan_Item__c bpItem2 = utilTestClassAux.createBusinessPlanItemNormal(bpVersion);
    liBPItems.add(bpITem);
    liBPItems.add(bpItem2);
    insert liBPItems;

    final String profile = utilTestClass.createProfile();
    final User user = utilTestClass.createUser(profile, 'username@test.comm');
    insert user;
    final bupl__AP_Team__c apTeamMember = utilTestClass.createAPTeamMember(user,accountPlanning);
    insert apTeamMember;
    Test.startTest();
    String savedData = DES_AP_BPProductAnalysis_CTRL.saveData(JSON.serialize(liBPItems));
    Test.stopTest();

    System.assert(savedData != null,'Did not saved Business Plan Item\'s Data correctly.');
  }

}