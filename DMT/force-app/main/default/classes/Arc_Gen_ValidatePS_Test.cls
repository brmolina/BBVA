/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_ValidatePS_Test
* @Author   aleksandar.dinkov.contractor@bbva.com
* @Date     Created: 08/11/2023
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Arc_Gen_ValidatePS_Test
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |08-11-2023 aleksandar.dinkov.contractor@bbva.com
*             Class creation.
* -----------------------------------------------------------------------------------------------
*/
@isTest
public with sharing class Arc_Gen_ValidatePS_Test {
     /**
    * @description String "Response message: " literal
    */
    public static final String RESP_MSG_LIT = 'Response message: ';
    /**
    * --------------------------------------------------------------------------------------
    * @Description Setup method for Arc_Gen_ValidatePS_Test
    * --------------------------------------------------------------------------------------
    * @Author   aleksandar.dinkov.contractor@bbva.com
    * @Date     Created: 08-11-2023
    * --------------------------------------------------------------------------------------
    **/
    @TestSetup
    static void setup() {
        final Account parentAcc = new Account(
            Name = 'parent',
            AccountNumber = 'CIANHNcRT-IUyJra0SA-xY'
        );
        insert parentAcc;

        final Account acc = new Account(
            Name = 'TestAcc',
            AccountNumber = 'CAONlXcCA_uxyJ402AA_xw',
            ParentId = parentAcc.Id
        );
        insert acc;

        final arce__AHA_Extension__c ahaExt = new arce__AHA_Extension__c(
            arce__PS_Successfully_Retrieved__c = true,
            arce__filial_Core__c = false
        );
        insert ahaExt;

        final arce__Analysis__c analysis = new arce__Analysis__c(
            arce__anlys_wkfl_sub_process_type__c = '4',
            arce__rating_prerating_type__c = 'Prerating',
            arce__Group__c = acc.Id,
            arce__is_RTC__c = true
        );
        insert analysis;

        final arce__Account_has_Analysis__c aha = new arce__Account_has_Analysis__c(
            arce__Analysis__c = analysis.Id,
            arce__customer__c = acc.Id,
            arce__participant_name__c = 'CAONlXcCA_uxyJ402AA_xw',
            arce__AHA_Extension__c = ahaExt.Id,
            arce__InReview__c = true
        );
        insert aha;

        final arce__Modifier__c amod = new arce__Modifier__c(
            arce__Account_has_AnalysisId__c = aha.Id
        );
        insert amod;

        final arce__Overlay__c overlay = new arce__Overlay__c(
            arce__Account_has_AnalysisId__c = aha.Id,
            arce__Arc_Gen_PS_Relationship_Id__c = '461',
            arce__Arc_Gen_ParentGroups__c = '{"ES0182009687897":["ES0182009687897"]}'
        );
        insert overlay;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @description callParentSubsidiaryTest
    * --------------------------------------------------------------------------------------
    * @author   aleksandar.dinkov.contractor@bbva.com
    * @Date     Created: 01-08-2023
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    public static void callPSExpiredTest() {
        final arce__Account_has_Analysis__c aha = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        Test.startTest();
        final Arc_Gen_ValidatePS.MessageResponse response = Arc_Gen_ValidatePS.callParentSubsidiary(aha.Id, true);
        System.debug(RESP_MSG_LIT + response.message);
        System.assertEquals('Error', response.status , 'Expected value "Error", instead has: ' + response.status);
        Test.stopTest();
    }

    /**
    * --------------------------------------------------------------------------------------
    * @description callPSDiffTest
    * --------------------------------------------------------------------------------------
    * @author   adrian.caro.next@bbva.com
    * @Date     Created: 2024-01-16
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    public static void callPSDiffTest() {
        final arce__Account_has_Analysis__c aha = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        final arce__Overlay__c ovrl = [SELECT Id,arce__Arc_Gen_PS_Relationship_Id__c FROM arce__Overlay__c LIMIT 1];
        Test.startTest();
        ovrl.arce__Arc_Gen_PS_Relationship_Id__c ='454';
        update ovrl;
        final Arc_Gen_ValidatePS.MessageResponse response = Arc_Gen_ValidatePS.callParentSubsidiary(aha.Id, true);
        System.debug(RESP_MSG_LIT + response.message);
        System.assertEquals('RefreshPS', response.status, RESP_MSG_LIT + response.message);
        Test.stopTest();
    }


    /**
    * --------------------------------------------------------------------------------------
    * @description callPSRelDiffTest
    * --------------------------------------------------------------------------------------
    * @author   aleksandar.dinkov.contractor@bbva.com
    * @Date     Created: 2024-01-16
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    public static void callPSRelDiffTest() {
        final arce__Account_has_Analysis__c aha = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        final arce__AHA_Extension__c ahaExt = [SELECT Id, arce__filial_Core__c FROM arce__AHA_Extension__c LIMIT 1];
        Test.startTest();
        ahaExt.arce__filial_Core__c = true;
        update ahaExt;
        final Arc_Gen_ValidatePS.MessageResponse response = Arc_Gen_ValidatePS.callParentSubsidiary(aha.Id, true);
        System.debug(RESP_MSG_LIT + response.message);
        System.assertEquals('Error', response.status, RESP_MSG_LIT + response.message);
        Test.stopTest();
    }

    /**
    * --------------------------------------------------------------------------------------
    * @description callPSRelDiffTest
    * --------------------------------------------------------------------------------------
    * @author   aleksandar.dinkov.contractor@bbva.com
    * @Date     Created: 2024-01-16
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    public static void validateExpgTest() {
        final arce__Account_has_Analysis__c aha = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        final arce__Overlay__c overlay = [SELECT Id,arce__Arc_Gen_PS_Relationship_Id__c FROM arce__Overlay__c LIMIT 1];
        Test.startTest();
        aha.arce__RAR_rating_tool_id__c = '2021RTC_EXPG';
        overlay.arce__Arc_Gen_IsUTE__c = 'UNSET';
        update overlay;
        update aha;
        final Arc_Gen_ValidatePS.MessageResponse response = Arc_Gen_ValidatePS.callParentSubsidiary(aha.Id, true);
        System.debug(RESP_MSG_LIT + response.message);
        System.assertEquals('RefreshPS', response.status, RESP_MSG_LIT + response.message);
        Test.stopTest();
    }
}