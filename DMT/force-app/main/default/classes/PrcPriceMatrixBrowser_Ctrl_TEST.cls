/** ********************************************************************************
* @author       JSS
* @date         24/04/2020
* @description  Clase para testear el controlador PrcPriceMatrixBrowser_Ctrl Los limetes de salesforce nos han forzado a generar una segunda clase de cobertura
* @Revision
********************************************************************************* */
@isTest
public class PrcPriceMatrixBrowser_Ctrl_TEST {
    
    
     public static testmethod void callWsRegisterAmiweb_test() {       
         //INSERT DATA NEEDED
         PRC_TestUtils utils = new PRC_TestUtils();
         //START TEST
         
        	String resp = PrcPriceMatrixBrowser_Ctrl.callWsRegisterAmiweb((String) utils.opp.Id, utils.priceFullResponse, utils.selectedPrice);
         

         //ASSERTS -- se podrían añadir más asserts de OppLineItem
         Opportunity opp = [Select gf_amiweb_opportunity_id__c, gf_proposal_id__c From Opportunity Where id = :utils.opp.Id LIMIT 1];
         System.assertNotEquals(null, opp.gf_amiweb_opportunity_id__c);
         System.assertNotEquals(null, opp.gf_proposal_id__c);
     }
    
    
     public static testmethod void callWsRegisterWorkflow_test() {
         //INSERT DATA NEEDED
         PRC_TestUtils utils = new PRC_TestUtils();
         
         //START TEST
         
        	String resp = PrcPriceMatrixBrowser_Ctrl.callWsRegisterWorkflow((String) utils.opp.Id);
         

         //ASSERTS
         Opportunity opp = [Select gf_workflow_opportunity_id__c, gf_workflow_oppy_status_type__c From Opportunity Where id = :utils.opp.Id LIMIT 1];
         System.assertNotEquals(null, opp.gf_workflow_opportunity_id__c);
         System.assertNotEquals(null, opp.gf_workflow_oppy_status_type__c);
     }
    
    
    

}