/*
* Asset_Controller Test
*/
@isTest
public with sharing class Asset_Controller_Test {

    /*
    * Creación de data
    */
    @testSetup
    static void setupTestData() {
        UserRole rolUser;
        rolUser = new UserRole(DeveloperName = 'MyCustomRole', Name = 'My Role');
		insert rolUser;
    }
    /*
    * Get FieldSet for Asset Header Test
    */
    @isTest
    public static void getFieldSetFromTemplateTest () {
        List<TemplateVF_Controller.FieldSetMemberWrapperClass> test;
        test = Asset_controller.getFieldSetFromTemplate();
        system.assert(!test.isEmpty(), 'La lista está vacía');
    }

    /*
    * Get FieldSet for Asset Header Test
    */
    @isTest
    public static void getAssetTypeTest() {
        Asset_Template__c template;
        template = SetUpOnBoarding.createAssetTemplate();
        insert template;
        system.assert(Asset_controller.getAssetType(template.Id), 'No hay ningún registro con las condiciones esperadas');
    }

    /*
    * Get FieldSet for Asset Header Test
    */
    @isTest
    public static void getFieldsFormTest() {
        Asset_Template__c template;
        template = SetUpOnBoarding.createAssetTemplate();
        insert template;
        List<TemplateVF_Controller.FieldSetMemberWrapperClass> test;
        test = Asset_controller.getFieldsForm(template.Id, false);
        system.assert(!test.isEmpty(), 'La lista está vacía');
    }

    /*
    * Get FieldSet for Asset Header Test
    */
    @isTest
    public static void getPrimarySalesTest() {
        DES_UtilTestClass utilTestClass;
        utilTestClass = new DES_UtilTestClass();
        Asset_Template__c template;
        template = SetUpOnBoarding.createAssetTemplate();
        String profileTest = '';
        profileTest = utilTestClass.createProfile();
        User userTest1;
        userTest1 = utilTestClass.createUser(profileTest);
        insert userTest1;
        template.Primary_Sales__c = userTest1.Id;
        template.Secondary_Sales_Id__c = UserInfo.getUserRoleId();
        insert template;
        List<String> test;
        test = Asset_controller.getPrimarySales(template.Id);
        system.assert(!test.isEmpty(), 'La lista está vacía');
    }

    /*
    * Get FieldSet for Asset Header Test
    */
    @isTest
    public static void updateValuesTest() {
        DES_UtilTestClass utilTestClass;
        utilTestClass = new DES_UtilTestClass();
        Asset_Template__c template;
        template = SetUpOnBoarding.createAssetTemplate();
        String profileTest = '';
        profileTest = utilTestClass.createProfile();
        User userTest1;
        userTest1 = utilTestClass.createUser(profileTest);
        insert userTest1;
        template.Primary_Sales__c = userTest1.Id;
        template.Secondary_Sales_Id__c = UserInfo.getUserRoleId();
        insert template;
        template.Description__c = 'test';
        Asset_controller.updateValues(template.Id,template);
        Asset_Template__c template2;
        template2 = [SELECT Id, Description__c FROM Asset_Template__c WHERE Id =: template.Id LIMIT 1];
        system.assert(template2.Description__c != null, 'Se ha modificado');
    }

    /*
    * Get FieldSet for Asset Header Test
    */
    @isTest
    public static void updateAssetTest () {
        Boolean test = false;
        DES_UtilTestClass utilTestClass;
        utilTestClass = new DES_UtilTestClass();
        String profileTest = '';
        profileTest = utilTestClass.createProfile();
        User userTest1;
        userTest1 = utilTestClass.createUser(profileTest);
        insert userTest1;
        UserRole rol;
        rol = [SELECT id FROM UserRole limit 1];
        Asset_Template__c template;
        template = SetUpOnBoarding.createAssetTemplate();
        template.Primary_Sales__c = userTest1.Id;
        template.Onboarding_Type__c = 'New Client';
        template.Secondary_Sales_Id__c = rol.id;
        insert template;
        Asset_Template__c template3;
        template3 = SetUpOnBoarding.createAssetTemplate();
        template3.Onboarding_Type__c = 'New Product';
        template3.Secondary_Sales_Id__c = rol.id;
        insert template3;
        Asset_controller.updateAsset(template);
        Asset_controller.updateAsset(template3);
        Asset_Template__c template2;
        template2 = [SELECT Id, Secondary_Sales_Id__c FROM Asset_Template__c WHERE Id =: template.Id LIMIT 1];
        Asset_Template__c template4;
        template4 = [SELECT Id, Secondary_Sales_Id__c FROM Asset_Template__c WHERE Id =: template3.Id LIMIT 1];
        if(template2.Secondary_Sales_Id__c == null && template4.Secondary_Sales_Id__c != null) {
            test = true;
        }
        system.assert(test, 'No se ha modificado');
    }

    /*
    * Get FieldSet for Asset Header Test
    */
    @isTest
    public static void updateAssetTestPlat () {
        UserRole rol;
        rol = [SELECT id FROM UserRole limit 1];
        Boolean test = false;
        DES_UtilTestClass utilTestClass;
        utilTestClass = new DES_UtilTestClass();
        String profileTest = '';
        profileTest = utilTestClass.createProfile();
        User userTest1;
        userTest1 = utilTestClass.createUser(profileTest);
        insert userTest1;
        Asset_Template__c template;
        template = SetUpOnBoarding.createAssetTemplate();
        template.Primary_Sales__c = userTest1.Id;
        template.Onboarding_Type__c = 'Platform Addition';
        template.Secondary_Sales_Id__c = rol.id;
        insert template;
        Asset_Template__c template3;
        template3 = SetUpOnBoarding.createAssetTemplate();
        template3.Onboarding_Type__c = 'Platform Addition';
        template3.Secondary_Sales_Id__c = rol.id;
        insert template3;
        Asset_controller.updateAsset(template);
        Asset_controller.updateAsset(template3);
        Asset_Template__c template2;
        template2 = [SELECT Id, Secondary_Sales_Id__c FROM Asset_Template__c WHERE Id =: template.Id LIMIT 1];
        Asset_Template__c template4;
        template4 = [SELECT Id, Secondary_Sales_Id__c FROM Asset_Template__c WHERE Id =: template3.Id LIMIT 1];
        if(template2.Secondary_Sales_Id__c == null && template4.Secondary_Sales_Id__c != null) {
            test = true;
        }
        system.assert(test, 'No se ha modificado');
    }

}