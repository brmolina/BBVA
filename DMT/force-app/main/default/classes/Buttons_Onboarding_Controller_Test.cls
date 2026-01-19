/*
*Buttons_Onboarding_Controller_Test
*/
@isTest
@SuppressWarnings('sf:TooManyMethods')
public with sharing class Buttons_Onboarding_Controller_Test {

    /*
    * String
    */
    static final String MENSAJE = 'No se actualiza.';
    /*
    * String
    */
    static final String VALIDATE = 'Validate';
    /*
    * String
    */
    static final String ERR = 'error';
    /*
    * String
    */
    static final String ERRUSNAME = 'ErrorUserName';
    /*
    * String
    */
    static final String PRODUCTO = 'producto';
    /*
    * String
    */
    static final String AAA = 'AAA';
    /*
    * String
    */
    static final String YES = 'Yes';

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
    *reviewTest
    */
    @isTest
    public static void reviewTest() {
        UserRole rol;
        rol = [SELECT id FROM UserRole limit 1];
        Boolean test = false;
        Asset_Template__c assTemp;
        assTemp = SetUpOnBoarding.createAssetTemplate();
        assTemp.Secondary_Sales_Id__c = rol.id;
        insert assTemp;
        Asset_Product__c prod;
        prod = SetUpOnBoarding.createAssetProduct(assTemp.Id);
        insert prod;
        final String resp = Buttons_Onboarding_Controller.review(assTemp.Id);
        if(resp != ERR) {
            test = true;
        }
        system.assert(test, 'No se ha actualizado el estado.');
    }

    /*
    *product
    */
    @isTest
    public static void productTest() {
        UserRole rol;
        rol = [SELECT id FROM UserRole limit 1];
        Boolean test = false;
        Asset_Template__c assTemp;
        assTemp = SetUpOnBoarding.createAssetTemplate();
        assTemp.Secondary_Sales_Id__c = rol.id;
        insert assTemp;
        final String resp = Buttons_Onboarding_Controller.implement(assTemp.Id);
        if(resp == PRODUCTO) {
            test = true;
        }
        system.assert(test, 'No se ha actualizado el estado.');
    }

    /*
    *reviewTest USERNAME
    */
    @isTest
    public static void reviewTestUserName() {
        UserRole rol;
        rol = [SELECT id FROM UserRole limit 1];
        Boolean test = false;
        Asset_Template__c assTemp;
        assTemp = SetUpOnBoarding.createAssetTemplate();
        assTemp.Secondary_Sales_Id__c = rol.id;
        insert assTemp;
        Asset_Product__c prod;
        prod = SetUpOnBoarding.createAssetProduct(assTemp.Id);
        prod.Platform__c = 'Bloomberg';
        prod.User_Name_FI__c = 'All pending users';
        insert prod;
        final String resp = Buttons_Onboarding_Controller.review(assTemp.Id);
        if(resp == ERRUSNAME) {
            test = true;
        }
        system.assert(test, 'No se ha actualizado el estado.');
    }


    /*
    *implementTest
    */
    @isTest
    public static void implementTest() {
        Asset_Template__c assTemp;
        assTemp = SetUpOnBoarding.createAssetTemplate();
        assTemp.Secondary_Sales_Id__c = UserInfo.getUserRoleId();
        insert assTemp;
        Asset_Product__c prod;
        prod = SetUpOnBoarding.createAssetProduct(assTemp.Id);
        insert prod;
        Buttons_Onboarding_Controller.getInstance();
        system.assert(!String.isBlank(Buttons_Onboarding_Controller.implement(assTemp.Id)), MENSAJE);
    }

    /*
    *implementTest
    */
    @isTest
    public static void implementAllTest() {
        DES_UtilTestClass utilTest;
        utilTest = new DES_UtilTestClass();
        Account acc;
        acc = utilTest.createClient();
        insert acc;
        RecordType rdAsset;
        rdAsset = [SELECT id FROM RecordType WHERE DeveloperName = 'FX_Asset' LIMIT 1];

        Asset_Template__c assTemp;
        assTemp = SetUpOnBoarding.createAssetTemplate();
        assTemp.Onboarding_Type__c = 'Reject Fund';
        assTemp.Asset_Class__c = 'FX';
        assTemp.Client__c = acc.id;
        assTemp.Star_Code__c = '123';
        assTemp.Secondary_Sales_Id__c = UserInfo.getUserRoleId();
        assTemp.Status__c = 'Wrong Data';
        assTemp.RecordTypeId = rdAsset.id;
        insert assTemp;
        Asset_Product__c prod;
        prod = SetUpOnBoarding.createAssetProduct(assTemp.Id);
        prod.Platform__c = 'FxALL';
        prod.Star_Code__c = 'AAAA';
        insert prod;
        Buttons_Onboarding_Controller.getInstance();

        system.assert(String.isBlank(Buttons_Onboarding_Controller.implement(assTemp.Id)), MENSAJE);
    }

    /*
    *implementTest
    */
    @isTest
    public static void implementMarkitTest() {
        DES_UtilTestClass utilTest;
        utilTest = new DES_UtilTestClass();
        Account acc;
        acc = utilTest.createClient();
        insert acc;
        RecordType rdAsset;
        rdAsset = [SELECT id FROM RecordType WHERE DeveloperName = 'IRS_Asset' LIMIT 1];

        Asset_Template__c assTemp;
        assTemp = SetUpOnBoarding.createAssetTemplateFull(acc.Id, UserInfo.getUserId(), UserInfo.getProfileId(), 'sad');
        assTemp.Onboarding_Type__c = 'New Client';
        assTemp.Asset_Class__c = 'IRS';
        assTemp.RecordTypeId = rdAsset.id;
        insert assTemp;
        Asset_Product__c prod;
        prod = SetUpOnBoarding.createAssetProduct(assTemp.Id);
        prod.Client_Name_on_Platform__c = 'a';
        prod.User_Name_FI__c = 'a';
        prod.User_UUID_if_bloomberg__c = 'a';
        prod.Facility__c = 'SEF';
        prod.Clearing_House__c = 'CME';
        prod.View_only__c = 'YES';
        prod.Is_the_client_direct_or_indirect_member__c = 'Direct';
        prod.Does_the_client_confirm_via_Markitwire__c = YES;
        prod.Set_up_of_Drop_Copy__c = 'Not needed';
        prod.Client_Markitwire_BIC__c = 'a';
        prod.Do_we_have_Markitwire_permissions__c = 'No';
        prod.Is_the_STP_Markitwire_Murex_in_place__c = YES;
        prod.Platform__c = 'Tradeweb';
        prod.Product__c = 'New';
        insert prod;
        Buttons_Onboarding_Controller.getInstance();
        prod.Do_we_have_Markitwire_permissions__c = YES;
        prod.Is_the_STP_Markitwire_Murex_in_place__c = 'No';
        update prod;
        prod.Do_we_have_Markitwire_permissions__c = YES;
        prod.Is_the_STP_Markitwire_Murex_in_place__c = YES;
        prod.Does_the_client_confirm_via_Markitwire__c = 'No';
        update prod;

        system.assertEquals(Buttons_Onboarding_Controller.implement(assTemp.Id), 'ErrorMarkitWire', MENSAJE);
    }

    /*
    *generarNotificaciones
    */
    @isTest
    public static void generarNotificaciones() {


        WrongDataFlow.RegistriesForms regis;
        regis = new WrongDataFlow.RegistriesForms();
        regis.form = 'aa';
        regis.text = 'aa';

        WrongDataFlow.generarNotificaciones('aaa', 'aaa');
        WrongDataFlow.notifyFlow(new List<WrongDataFlow.RegistriesForms>{regis});

        system.assertEquals(regis.form, 'aa', MENSAJE);
    }

    /*
    *completeTest
    */
    @isTest
    public static void completeTest() {
        Asset_Template__c assTemp;
        assTemp = SetUpOnBoarding.createAssetTemplate();
        assTemp.Onboarding_Type__c = 'New Product';
        assTemp.Status__c = 'Implement';
        assTemp.Secondary_Sales_Id__c = UserInfo.getUserRoleId();
        insert assTemp;
        Asset_Product__c prod;
        prod = SetUpOnBoarding.createAssetProduct(assTemp.Id);
        insert prod;

        system.assert(!Buttons_Onboarding_Controller.complete(assTemp.Id), MENSAJE);
    }

    /*
    *validateExcluirTest
    */
    @isTest
    public static void validateExcluirTest() {
        Asset_Template__c assTemp;
        assTemp = SetUpOnBoarding.createAssetTemplate();
        assTemp.Onboarding_Type__c = 'New Product';
        assTemp.Status__c = 'Review';
        assTemp.Secondary_Sales_Id__c = UserInfo.getUserRoleId();
        insert assTemp;
        Asset_Product__c prod;
        prod = SetUpOnBoarding.createAssetProduct(assTemp.Id);
        insert prod;

        system.assert(!String.isBlank(Buttons_Onboarding_Controller.validate(assTemp.Id)), MENSAJE);
    }

    /*
    *validateTest
    */
    @isTest
    public static void validateTest() {
        DES_UtilTestClass utilTest;
        utilTest = new DES_UtilTestClass();
        Account acc;
        acc = utilTest.createClient();
        insert acc;
        String perfil;
        perfil = utilTest.createProfile();
        User usu;
        usu = utilTest.createUser(perfil);
        insert usu;
        Asset_Template__c assTemp;
        assTemp = SetUpOnBoarding.createAssetTemplateFull(acc.Id, usu.Id, perfil, 'sad');
        insert assTemp;
        Asset_Product__c prod;
        prod = SetUpOnBoarding.createAssetProductFull(assTemp.Id);
        insert prod;
        String campos;
        campos = Buttons_Onboarding_Controller.validate(assTemp.Id);
        System.debug('TEST CAMPOS----------------------> '+campos);
        system.assert(String.isBlank(campos), MENSAJE);
    }

    /*
    *validateTestUserName
    */
    @isTest
    public static void validateUsts() {
        DES_UtilTestClass utilTest;
        utilTest = new DES_UtilTestClass();
        Account acc;
        acc = utilTest.createClient();
        insert acc;
        String perfil;
        perfil = utilTest.createProfile();
        User usu;
        usu = utilTest.createUser(perfil);
        insert usu;
        Asset_Template__c assTemp;
        assTemp = SetUpOnBoarding.createAssetTemplateFull(acc.Id, usu.Id, perfil, 'sad');
        insert assTemp;
        Asset_Product__c prod;
        prod = SetUpOnBoarding.createAssetProductFull(assTemp.Id);
        prod.User_Name_FI__c = 'All pending users';
        insert prod;
        String campos;
        campos = Buttons_Onboarding_Controller.validate(assTemp.Id);
        System.debug('TEST CAMPOS----------------------> '+campos);
        system.assertEquals(campos, 'ErrorUserName', MENSAJE);
    }

    /*
    *approveTest
    */
    @isTest
    public static void approveTest() {
        Asset_Template__c assTemp;
        assTemp = SetUpOnBoarding.createAssetTemplate();
        assTemp.Onboarding_Type__c = 'New Client';
        assTemp.Status__c = VALIDATE;
        assTemp.Secondary_Sales_Id__c = UserInfo.getUserRoleId();
        insert assTemp;
        Buttons_Onboarding_Controller.approve(assTemp.Id);
        final Asset_Template__c temp = [SELECT Id, Status__c FROM Asset_Template__c WHERE Id =: assTemp.Id LIMIT 1];

        system.assertEquals(temp.Status__c,'Implement', MENSAJE);
    }

    /*
    *approveTraderTest
    */
    @isTest
    public static void approveTraderTest() {
        DES_UtilTestClass utilTest;
        utilTest = new DES_UtilTestClass();
        String profile;
        profile = utilTest.createProfile();
        User usu;
        usu = utilTest.createUser(profile);
        insert usu;
        Asset_Template__c assTemp;
        assTemp = SetUpOnBoarding.createAssetTemplate();
        assTemp.Status__c = VALIDATE;
        insert assTemp;
        Asset_Product__c prod;
        prod = SetUpOnBoarding.createAssetProduct(assTemp.Id);
        prod.Trader_Approver__c = usu.Id;
        insert prod;
        Buttons_Onboarding_Controller.approveTrader(assTemp.Id);
        final Asset_Template__c temp = [SELECT Id, Status__c FROM Asset_Template__c WHERE Id =: assTemp.Id LIMIT 1];

        system.assertEquals(temp.Status__c,'Implement', MENSAJE);
    }

    /*
    *approveTraderFaltaTest
    */
    @isTest
    public static void approveTraderFaltaTest() {
        DES_UtilTestClass utilTest;
        utilTest = new DES_UtilTestClass();
        String profile;
        profile = utilTest.createProfile();
        User usu;
        usu = utilTest.createUser(profile);
        insert usu;
        Asset_Template__c assTemp;
        assTemp = SetUpOnBoarding.createAssetTemplate();
        assTemp.Status__c = VALIDATE;
        insert assTemp;
        Asset_Product__c prod;
        prod = SetUpOnBoarding.createAssetProduct(assTemp.Id);
        insert prod;
        Buttons_Onboarding_Controller.approveTrader(assTemp.Id);
        final Asset_Template__c temp = [SELECT Id, Status__c FROM Asset_Template__c WHERE Id =: assTemp.Id LIMIT 1];

        system.assertEquals(temp.Status__c, VALIDATE, MENSAJE);
    }

    /*
    *rejectTraderTest
    */
    @isTest
    public static void rejectTraderTest() {
        Asset_Template__c assTemp;
        assTemp = SetUpOnBoarding.createAssetTemplate();
        assTemp.Status__c = VALIDATE;
        insert assTemp;
        Buttons_Onboarding_Controller.rejectTrader(assTemp.Id);
        final Asset_Template__c temp = [SELECT Id, Trader_Resolution_Date__c, Status__c FROM Asset_Template__c WHERE Id =: assTemp.Id LIMIT 1];

        system.assert(temp.Trader_Resolution_Date__c != null, MENSAJE);
    }

    /*
    *rejectTraderTest
    */
    @isTest
    public static void rejectClientTest() {
        Asset_Template__c assTemp;
        assTemp = SetUpOnBoarding.createAssetTemplate();
        insert assTemp;
        Buttons_Onboarding_Controller.rejectClient(assTemp.Id, assTemp);
        final Asset_Template__c temp = [SELECT Id, Trader_Resolution_Date__c, Status__c FROM Asset_Template__c WHERE Id =: assTemp.Id LIMIT 1];

        system.assertEquals(temp.Status__c, 'Client Rejected', MENSAJE);
    }


}