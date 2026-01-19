/***********************************************************************************************
Name:            DES_AP_BPAccessHandler_CTRL_Test
Description:     Test Class for DES_AP_BPAccessHandler_CTRL class
***********************************************************************************************/
@isTest
public class DES_AP_BPAccessHandler_CTRL_Test {

   
        /* Get totals sections for the Account related to the AP */
    @IsTest
    static void testGetSections() {
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
        List<String> bpSections = DES_AP_BPAccessHandler_CTRL.getCountriesBP(accountPlanning.Id, false);
        Test.stopTest();

        System.assert(!bpSections.isEmpty(),'Did not retrieve Sections correctly.');
    }
    /**
    * DES_AP_BPAccessHandler_CTRL.userHasAccess test
    */
    @IsTest
    public static void userHasAccessTest() {
        final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
        final DES_UtilTestClassAux utilTestClassAux = new DES_UtilTestClassAux();
        
        final Account acc = utilTestClass.createClient();
        insert acc;
        
        final acpl__AP_PeriodConfiguration__c apConfig = utilTestClass.createAPConfig();
        insert apConfig;

        final acpl__Account_Plan_Settings__c apSettings = new acpl__Account_Plan_Settings__c();
        apSettings.acpl__Unlock_when_change_DueDate__c = false;
        insert apSettings;

        final acpl__Account_Planning__c accountPlanning = utilTestClass.createAccountPlanning(acc);
        insert accountPlanning;

        final String profile = utilTestClass.createProfile();
        final User user =  utilTestClass.createUser(profile, 'username@test.comm');
        insert user;

        final bupl__AP_Team__c apTeamMember = utilTestClass.createAPTeamMember(user, accountPlanning);
        insert apTeamMember;

        final bupl__BusinessPlan__c businessPlan = utilTestClassAux.createBusinessPlan(accountPlanning, acc);
        insert businessPlan;

        final bupl__BusinessPlan_Version__c bpVersion = utilTestClassAux.createBusinessPlanVersion(businessPlan);
        insert bpVersion;

        final bupl__BusinessPlan_Item__c bpItem = utilTestClassAux.createBusinessPlanItemNormal(bpVersion);
        insert bpItem;

        System.runAs(user) {
            Test.startTest();
            final Boolean hasAccess = DES_AP_BPAccessHandler_CTRL.userHasAccess(accountPlanning.Id);
            Test.stopTest();
            System.assert(hasAccess,'User has not access to the Account Planning.');
        }
    }

    /**
    * DES_AP_BPAccessHandler_CTRL.userHasEditPermission and userHasEditPermission test
    */
    @IsTest
    public static void userHasEditPermissionTest() {
        final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
        final DES_UtilTestClassAux utilTestClassAux = new DES_UtilTestClassAux();
        
        final Account acc = utilTestClass.createClient();
        insert acc;

        final acpl__AP_PeriodConfiguration__c apConfig = utilTestClass.createAPConfig();
        insert apConfig;

        final acpl__Account_Plan_Settings__c apSettings = new acpl__Account_Plan_Settings__c();
        apSettings.acpl__Unlock_when_change_DueDate__c = false;
        insert apSettings;
        
        final acpl__Account_Planning__c accountPlanning = utilTestClass.createAccountPlanning(acc);
        insert accountPlanning;

        final String profile = utilTestClass.createProfile();
        final User user =  utilTestClass.createUser(profile, 'username@test.comm');
        insert user;

        final bupl__AP_Team__c apTeamMember = utilTestClass.createAPTeamMember(user, accountPlanning);
        insert apTeamMember;

        final bupl__BusinessPlan__c businessPlan = utilTestClassAux.createBusinessPlan(accountPlanning, acc);
        insert businessPlan;

        final bupl__BusinessPlan_Version__c bpVersion = utilTestClassAux.createBusinessPlanVersion(businessPlan);
        insert bpVersion;

        final bupl__BusinessPlan_Item__c bpItem = utilTestClassAux.createBusinessPlanItemNormal(bpVersion);
        insert bpItem;

        System.runAs(user) {
            Test.startTest();
            final Boolean hasAccess = DES_AP_BPAccessHandler_CTRL.userHasEditPermission(accountPlanning.Id, '');
            DES_AP_BPAccessHandler_CTRL.userHasEditPermission(accountPlanning.Id, bpVersion.Id);
            Test.stopTest();
            System.assertNotEquals(hasAccess, null);
        }
    }

}