/**
* ────────────────────────────────────────────────────────────────────────────────────
* DPMX_Container_Ctrl_Test
* Test class for RPP_CalculatorModify_Ctrl apex class
* ────────────────────────────────────────────────────────────────────────────────────
* @author      Cosme Alcázar <cosme.alcazar.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2023-05-08
* @modified
* @systemLayer Test
* ────────────────────────────────────────────────────────────────────────────────────
* @changes
*
* ────────────────────────────────────────────────────────────────────────────────────
*/
@IsTest
public class RPP_CalculatorModify_Ctrl_Test {
    @IsTest
    static void testInitialData() {
        RPP_Calculator__c RPPCalculator = RPP_Test_Utils.insertRPPCalculator('RPP Calculator Test 01', true,3,3);
        RPP_Calculator_Simulation__c RPPCalculatorSimulation = [SELECT Id FROM RPP_Calculator_Simulation__c WHERE Source_RPP_Calculator__c = :RPPCalculator.Id LIMIT 1];
        Test.startTest();
            Map<String, Object> retMap = RPP_CalculatorModify_Ctrl.initialData(RPPCalculatorSimulation.Id);
            List<RPP_Calculator_Simulation_Debtor__c> RPPCalculatorSimDebtors = (List<RPP_Calculator_Simulation_Debtor__c>)retMap.get('RPPCalculatorSimDebtors');
            System.assertEquals(RPPCalculatorSimDebtors.size(), 3,'testInitialData - OK');
        Test.stopTest();
    }
    @IsTest
    static void testModifyData01() {
        RPP_Calculator__c RPPCalculator = RPP_Test_Utils.insertRPPCalculator('RPP Calculator Test 01', true,3,3);
        List<RPP_Calculator_Simulation__c> RPPCalculatorSimulation = [SELECT Id, Internal_Rating__c, External_Rating__c FROM RPP_Calculator_Simulation__c WHERE Source_RPP_Calculator__c = :RPPCalculator.Id LIMIT 1];
        Test.startTest();
            Map<String, Object> retMap1 = RPP_CalculatorModify_Ctrl.initialData(RPPCalculatorSimulation[0].Id);
            List<RPP_Calculator_Simulation_Debtor__c> RPPCalculatorSimDebtors = (List<RPP_Calculator_Simulation_Debtor__c>)retMap1.get('RPPCalculatorSimDebtors');
            Map<Id,RPP_Calculator_Simulation_Debtor__c> RPPCalculatorSimDebtorsMap = (Map<Id,RPP_Calculator_Simulation_Debtor__c>)retMap1.get('RPPCalculatorSimDebtorsMap');
            Map<String, Object> retMap2 = RPP_CalculatorModify_Ctrl.modifyData(RPPCalculatorSimulation, RPPCalculatorSimDebtors, RPPCalculatorSimDebtorsMap);
            System.assertEquals(retMap2.get('success'), false,'testModifyData01 - OK');
        Test.stopTest();
    }
    @IsTest
    static void testModifyData02() {
        RPP_Calculator__c RPPCalculator = RPP_Test_Utils.insertRPPCalculator('RPP Calculator Test 01', true,3,3);
        List<RPP_Calculator_Simulation__c> RPPCalculatorSimulation = [SELECT Id, Internal_Rating__c, External_Rating__c FROM RPP_Calculator_Simulation__c WHERE Source_RPP_Calculator__c = :RPPCalculator.Id LIMIT 1];
        RPPCalculatorSimulation[0].Internal_Rating__c = 'CCC';
        RPPCalculatorSimulation[0].External_Rating__c = 'CCC';
        Test.startTest();
            Map<String, Object> retMap1 = RPP_CalculatorModify_Ctrl.initialData(RPPCalculatorSimulation[0].Id);
            List<RPP_Calculator_Simulation_Debtor__c> RPPCalculatorSimDebtors = (List<RPP_Calculator_Simulation_Debtor__c>)retMap1.get('RPPCalculatorSimDebtors');
            Map<Id,RPP_Calculator_Simulation_Debtor__c> RPPCalculatorSimDebtorsMap = (Map<Id,RPP_Calculator_Simulation_Debtor__c>)retMap1.get('RPPCalculatorSimDebtorsMap');
            List<RPP_Calculator_Simulation_Debtor__c> RPPCalculatorSimDebtorsModified = new List<RPP_Calculator_Simulation_Debtor__c>();
            for (RPP_Calculator_Simulation_Debtor__c RPPCalculatorSimDebtor : RPPCalculatorSimDebtors) {
                RPP_Calculator_Simulation_Debtor__c RPPCalculatorSimDebtorNew = new RPP_Calculator_Simulation_Debtor__c();
                RPPCalculatorSimDebtorNew.Number__c = RPPCalculatorSimDebtor.Number__c;
                RPPCalculatorSimDebtorNew.Insurer_Internal_Rating__c = '9';
                RPPCalculatorSimDebtorNew.Obligor_Debtor__c = RPPCalculatorSimDebtor.Obligor_Debtor__c;
                RPPCalculatorSimDebtorNew.Total_Amount_EUR__c = RPPCalculatorSimDebtor.Total_Amount_EUR__c;
                RPPCalculatorSimDebtorNew.Authorised_Limit_EUR__c = RPPCalculatorSimDebtor.Authorised_Limit_EUR__c;
                RPPCalculatorSimDebtorNew.Percentage__c = RPPCalculatorSimDebtor.Percentage__c;
                RPPCalculatorSimDebtorNew.Internal_Rating__c = 'B';
                RPPCalculatorSimDebtorNew.External_Rating__c = 'C';
                RPPCalculatorSimDebtorNew.Id = RPPCalculatorSimDebtor.Id;
                RPPCalculatorSimDebtorsModified.add(RPPCalculatorSimDebtorNew);
            }
            Map<String, Object> retMap2 = RPP_CalculatorModify_Ctrl.modifyData(RPPCalculatorSimulation,RPPCalculatorSimDebtorsModified, RPPCalculatorSimDebtorsMap);
            System.assertEquals(retMap2.get('success'), true,'testModifyData02 - OK');
        Test.stopTest();
    }
}