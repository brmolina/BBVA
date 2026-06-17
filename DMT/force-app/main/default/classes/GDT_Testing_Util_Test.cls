/**
* ------------------------------------------------------------------------------------------------
* @Name     GDT_Testing_Util_Test
* @Author   BBVA Developers
* @Date     Created: 2020-06-30
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description test class for GDT_Testing_Util_Test
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2022-06-30 BBVA Developers.
*              Class creation.
* ------------------------------------------------------------------------------------------------
*/
@SuppressWarnings('PMD.ExcessiveParameterList,sf:TooManyMethods,PMD.ExcessivePublicCount')
@isTest
public with sharing class GDT_Testing_Util_Test {
    /**
        * @description salesforce Id to use in test class
    **/
    static String idTest;
    /**
        * @description testSetup
        * @author ARCE TEAM
    **/ 
    @TestSetup
    static void testSetup() {
        final arce__Analysis__c analisis = GDT_Testing_Util.createAnalisis();
        insert analisis;
        idTest = analisis.Id;
    }
    /**
    * @description createAnalisis method test
    * @author alberto.martinez.carrero.contractor@bbva.com | 30-06-2022
    **/
    @isTest 
    public static void createAnalisisTest() {
        Test.startTest();
            final arce__Analysis__c arceAn = GDT_Testing_Util.createAnalisis();
            System.assert(arceAn != null, 'Assert: Error in createAnalisisTest');
        Test.stopTest();
    }
    /**
    * @description createAccountHasAnalisis method test
    * @author alberto.martinez.carrero.contractor@bbva.com | 30-06-2022
    **/
    @isTest
    public static void createAccountHasAnalisisTest() {
        Test.startTest();
            final arce__Account_has_Analysis__c aha = GDT_Testing_Util.createAccountHasAnalisis(idTest);
            System.assert(aha != null, 'Assert: Error in createAccountHasAnalisisTest');
        Test.stopTest();
    }
}