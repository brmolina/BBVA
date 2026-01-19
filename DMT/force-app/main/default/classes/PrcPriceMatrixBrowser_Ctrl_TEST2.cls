/** ********************************************************************************
 * @author       JSS
 * @date         24/04/2020
 * @description  Clase para testear el controlador PrcPriceMatrixBrowser_Ctrl, Los limetes de salesforce nos han forzado a generar una segunda clase de cobertura
 * @Revision
 ********************************************************************************* */
@isTest
public with sharing class PrcPriceMatrixBrowser_Ctrl_TEST2 {
    @testSetup
    private static void setupTest() {
        PRC_TestUtils utils = new PRC_TestUtils();
    }

    public static testmethod void getStatusWorkflow_test() {
        Opportunity opp = [Select gf_workflow_opportunity_id__c, gf_workflow_oppy_status_type__c
                           From Opportunity
                           LIMIT 1];
        opp.gf_workflow_opportunity_id__c = '275130';
        update opp;

        //START TEST
        Test.startTest();
        String resp = PrcPriceMatrixBrowser_Ctrl.getStatusWorkflow((String) opp.Id);
        Test.stopTest();

        //ASSERTS
        opp = [Select gf_workflow_opportunity_id__c, gf_workflow_oppy_status_type__c
               From Opportunity
               Where id = :opp.Id
               LIMIT 1];
        System.assertEquals('UPDATED', opp.gf_workflow_oppy_status_type__c);
    }

}