/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_Custom_Field_Controller_Test
* @Author   aleksandar.dinkov.contractor@bbva.com 
* @Date     Created: 2023-07-10
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description: Arc_Gen_Custom_Field_Controller_Test
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2023-07-10       aleksandar.dinkov.contractor@bbva.com            Class creation.
* ------------------------------------------------------------------------------------------------
*/
@isTest
public with sharing class Arc_Gen_Custom_Field_Controller_Test {
    /**
    * --------------------------------------------------------------------------------------
    * @Description Setup method for Arc_Gen_Custom_Field_Controller_Test
    * --------------------------------------------------------------------------------------
    * @Author   aleksandar.dinkov.contractor@bbva.com
    * @Date     Created: 2023-07-10
    * --------------------------------------------------------------------------------------
    **/
    @TestSetup
    static void setup() {
        final Account acc = new Account(
            Name = 'TestAcc',
            AccountNumber = 'CAONlXcCA_uxyJ402AA_xw'
        );
        insert acc;

        final arce__AHA_Extension__c ahaExt = new arce__AHA_Extension__c(
            arce__Undrawn_debt_Currency__c = 'MXD',
            arce__Undrawn_debt_Unit_Type__c = 'THOUS'
        );
        insert ahaExt;

        final arce__Analysis__c analysis = new arce__Analysis__c(
            arce__anlys_wkfl_sub_process_type__c = '4',
            arce__rating_prerating_type__c = 'Prerating',
            arce__Group__c = acc.Id
        );
        insert analysis;

        final arce__Account_has_Analysis__c aha = new arce__Account_has_Analysis__c(
            arce__Analysis__c = analysis.Id,
            arce__customer__c = acc.Id,
            arce__participant_name__c = 'CAONlXcCA_uxyJ402AA_xw',
            arce__AHA_Extension__c = ahaExt.Id,
            arce__InReview__c = true,
            arce__FR_Unit_Type__c = 'THOUS'
        );
        insert aha;

        final arce__Modifier__c amod = new arce__Modifier__c(
            arce__Account_has_AnalysisId__c = aha.Id
        );
        insert amod;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @description getAhaFieldValueTest
    * --------------------------------------------------------------------------------------
    * @author   aleksandar.dinkov.contractor@bbva.com
    * @Date     Created: 2023-07-10
    * @param    String recordId
    * @param    String fieldName
    * @param    String objectName
    * @return   String
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    public static void getAhaFieldValueTest() {
        final arce__Account_has_Analysis__c aha = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        Test.startTest();
        final String value = Arc_Gen_Custom_Field_Controller.getFieldValue(aha.Id, 'arce__FR_Unit_Type__c', 'arce__Account_has_Analysis__c');
        System.assertEquals('THOUS', value, 'Expected value THOUS, instead has: ' + value);
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @description getAhaExtFieldValueTest
    * --------------------------------------------------------------------------------------
    * @author   aleksandar.dinkov.contractor@bbva.com
    * @Date     Created: 2023-07-10
    * @param    String recordId
    * @param    String fieldName
    * @param    String objectName
    * @return   String
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    public static void getAhaExtFieldValueTest() {
        final arce__Account_has_Analysis__c aha = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        Test.startTest();
        final String value = Arc_Gen_Custom_Field_Controller.getFieldValue(aha.Id, 'arce__Undrawn_debt_Currency__c', 'arce__AHA_Extension__c');
        System.assertEquals('MXD', value, 'Expected value MXD, instead has: ' + value);
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @description getModFieldValueTest
    * --------------------------------------------------------------------------------------
    * @author   aleksandar.dinkov.contractor@bbva.com
    * @Date     Created: 2023-07-10
    * @param    String recordId
    * @param    String fieldName
    * @param    String objectName
    * @return   String
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    public static void getModFieldValueTest() {
        final arce__Account_has_Analysis__c aha = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        Test.startTest();
        final String value = Arc_Gen_Custom_Field_Controller.getFieldValue(aha.Id, 'arce__Account_has_AnalysisId__c', 'arce__Modifier__c');
        System.assertEquals(aha.Id, value, 'Expected value ' + aha.Id + ', instead has: ' + value);
        Test.stopTest();
    }
}