/**
* ------------------------------------------------------------------------------------------------
* @Name     GDT_Arc_Gen_Hierarchy_Controller_Test
* @Author   amunguia.contractor@bbva.com
* @Date     Created: 12/04/2022
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Class method for GDT_Arc_Gen_Hierarchy_Controller
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |12-04-2022 amunguia.contractor@bbva.com
*             Class creation.
* -----------------------------------------------------------------------------------------------
*/
@isTest
public with sharing class GDT_Arc_Gen_Hierarchy_Controller_Test {
    /**
    * @description makeData
    * @author amunguia.contractor@bbva.com | 04-13-2022
    **/
    @TestSetup
    static void makeData() {
        final Account acc = new Account();
        acc.Name = 'TestAcc';
        acc.AccountNumber = 'CAONlXcCA_uxyJ402AA_xw';
        insert acc;
        final arce__Analysis__c analisis = GDT_Testing_Util.createAnalisis();
        analisis.arce__anlys_wkfl_sub_process_type__c = '4';
        analisis.arce__rating_prerating_type__c = 'Rating';
        analisis.arce__wf_status_id__c = '11';
        insert analisis;
        final arce__Account_has_Analysis__c aha = GDT_Testing_Util.createAccountHasAnalisis(analisis.Id);
        aha.arce__Customer__c = acc.id;
        aha.arce__InReview__c = true;
        insert aha;
    }
    /**
    * @description test method
    * @author amunguia.contractor@bbva.com | 04-13-2022
    **/
    @isTest
    public static void buildDynamicColumnsTest() {
        Test.startTest();
        final String result = GDT_Arc_Gen_Hierarchy_Controller.buildDynamicColumns();
        Test.stopTest();
        System.assert(result.contains('accNumber'), 'Error buildDynamicColumns');
    }
}