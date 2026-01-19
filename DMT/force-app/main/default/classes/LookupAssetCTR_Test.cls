/*
* LookupAssetCTR_Test
*/
@isTest
public with sharing class LookupAssetCTR_Test {

    /*
    * Creación de data
    */
    @testSetup
    static void setupTestData() {
        UserRole rolUser;
        rolUser= new UserRole(DeveloperName = 'MyCustomRole', Name = 'My Role');
		insert rolUser;
        DES_UtilTestClass utilTestClass;
        utilTestClass = new DES_UtilTestClass();
        String profileTest = '';
        profileTest = utilTestClass.createProfile();
        User userTest1;
        userTest1 = utilTestClass.createUser(profileTest);
        userTest1.UserRoleId = rolUser.id;
        insert userTest1;
    }

    /*
    * String
    */
    static final String MENSAJE = 'No se ha encontrado el registro.';
    /*
    * String
    */
    static final String USERSTR = 'User';
    /*
    * String
    */
    static final String NAMESTR = 'Name';
    /*
    * String
    */
    static final String USERNAMESTR = 'User Name';

    /*
    * met0d0RoleTest
    */
    @isTest
    public static void metodoRoleTest() {
        User selUser;
        selUser = [SELECT id, UserRoleId, UserRole.Id FROM User WHERE UserRole.DeveloperName = 'MyCustomRole' limit 1];
        final Asset_Template__c assTemp = SetUpOnBoarding.createAssetTemplate();
        insert assTemp;
        final List<LookupAssetCTR.RecordsData> lstUser = LookupAssetCTR.metodoRole(selUser.id);
        final List<LookupAssetCTR.RecordsData> lstRole = LookupAssetCTR.metodoRole(selUser.UserRole.Id);

        system.assert(!lstUser.isEmpty() && !lstRole.isEmpty(), MENSAJE);
    }

    /*
    * fetchRecordsTestSec
    */
    @isTest
    public static void fetchRecordsTestSec() {
        final DES_UtilTestClass utilTest = new DES_UtilTestClass();
        final Asset_Template__c assTemp = SetUpOnBoarding.createAssetTemplate();
        insert assTemp;
        final String profile = [SELECT Id, Name FROM Profile WHERE Name = 'BBVA Desktop GM Standard'].Id ;
        final User usu = utilTest.createUser(profile);
        insert usu;
        final List<LookupAssetCTR.RecordsData> lstUser = LookupAssetCTR.fetchRecords(USERSTR, NAMESTR, 'secondary', USERNAMESTR, '');
        system.assert(lstUser.isEmpty(), MENSAJE);
    }

    /*
    * fetchRecordsTestPrim
    */
    @isTest
    public static void fetchRecordsTestPrim() {
        final DES_UtilTestClass utilTest = new DES_UtilTestClass();
        final Asset_Template__c assTemp = SetUpOnBoarding.createAssetTemplate();
        insert assTemp;
        final String profile = [SELECT Id, Name FROM Profile WHERE Name = 'BBVA Desktop GM Standard'].Id ;
        final User usu = utilTest.createUser(profile);
        insert usu;
        final List<LookupAssetCTR.RecordsData> lstUser = LookupAssetCTR.fetchRecords(USERSTR, NAMESTR, 'primary', USERNAMESTR, '');
        system.assert(lstUser.isEmpty(), MENSAJE);
    }

    /*
    * fetchRecordsTestEst
    */
    @isTest
    public static void fetchRecordsTestEst() {
        final DES_UtilTestClass utilTest = new DES_UtilTestClass();
        final Asset_Template__c assTemp = SetUpOnBoarding.createAssetTemplate();
        insert assTemp;
        final String profile = [SELECT Id, Name FROM Profile WHERE Name = 'BBVA Desktop GM Standard'].Id ;
        final User usu = utilTest.createUser(profile);
        insert usu;
        final List<LookupAssetCTR.RecordsData> lstUser = LookupAssetCTR.fetchRecords(USERSTR, NAMESTR, 'estandar', USERNAMESTR, '');
        system.assert(!lstUser.isEmpty(), MENSAJE);
    }

    /*
    * fetchRecordsTestVal
    */
    @isTest
    public static void fetchRecordsTestVal() {
        final DES_UtilTestClass utilTest = new DES_UtilTestClass();
        final Asset_Template__c assTemp = SetUpOnBoarding.createAssetTemplate();
        insert assTemp;
        final String profile = [SELECT Id, Name FROM Profile WHERE Name = 'BBVA Desktop GM Standard'].Id ;
        final User usu = utilTest.createUser(profile);
        insert usu;
        final List<LookupAssetCTR.RecordsData> lstUser = LookupAssetCTR.fetchRecords(USERSTR, NAMESTR, 'estandar', USERNAMESTR, usu.Id);
        system.assert(!lstUser.isEmpty(), MENSAJE);
    }
}