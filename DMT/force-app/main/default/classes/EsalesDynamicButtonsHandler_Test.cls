/*
* Test methods
*/
@isTest
public with sharing class EsalesDynamicButtonsHandler_Test {
    /*
    * Test method for getDynamicButtonStatus
    */
    @isTest
    public static void getDynamicButtonStatusTest() {
        Asset_Template__c temp;
        temp = SetUpOnBoarding.createAssetTemplate();
        insert temp;
        EsalesDynamicButtonsHandler esalesClass;
        esalesClass = new EsalesDynamicButtonsHandler();
        Set<String> buttons;
        buttons = esalesClass.getDynamicButtonStatus(temp.Id,'Asset_Template__c');
        system.assert(!buttons.isEmpty(), 'La lista está vacía');
    }

    /*
    * Test method for getDynamicButtonStatus
    */
    @isTest
    public static void getDynamicButtonStatusTest2() {
        Asset_Template__c temp;
        temp = SetUpOnBoarding.createAssetTemplate();
        temp.Onboarding_Type__c = 'New Client';
        insert temp;
        EsalesDynamicButtonsHandler esalesClass;
        esalesClass = new EsalesDynamicButtonsHandler();
        Set<String> buttons;
        buttons = esalesClass.getDynamicButtonStatus(temp.Id,'Asset_Template__c');
        system.assert(!buttons.isEmpty(), 'La lista está vacía');
    }

    /*
    * Test method for rolImplement
    */
    @isTest
    public static void rolImplementTest() {
        DES_UtilTestClass utilTest;
        utilTest = new DES_UtilTestClass();
        String profile;
        profile = utilTest.createProfile();
        User usu;
        usu = utilTest.createUser(profile);
        insert usu;
        EsalesDynamicButtonsHandler esalesClass;
        esalesClass = new EsalesDynamicButtonsHandler();
        final Boolean test = esalesClass.rolImplement('GLOBAL MARKETS E-COMMERCE');
        system.debug(test);
        system.assert(usu.Id != null, 'No se ha creado el usuario');
    }

    /*
    * Test method for comprobarAprove
    */
    @isTest
    public static void comprobarAproveTest() {
        Asset_Template__c temp;
        temp = SetUpOnBoarding.createAssetTemplate();
        insert temp;
        Asset_Product__c prod;
        prod = SetUpOnBoarding.createAssetProduct(temp.Id);
        system.debug(prod);
        final Boolean test = EsalesDynamicButtonsHandler.comprobarAprove(temp.Id);
        system.assert(!test, 'El usuario pertenece al grupo');
    }

    /*
    * Test method for completedButtonsTest
    */
    @isTest
    public static void completedButtonsTest() {
        Asset_Template__c temp;
        temp = SetUpOnBoarding.createAssetTemplate();
        temp.Status__c = 'Implement';
        insert temp;
        EsalesDynamicButtonsHandler esalesClass;
        esalesClass = new EsalesDynamicButtonsHandler();
        Set<String> buttons;
        buttons = esalesClass.getDynamicButtonStatus(temp.Id,'Asset_Template__c');
        system.assert(buttons.contains('Complete'), 'No se ve complete');
    }
}