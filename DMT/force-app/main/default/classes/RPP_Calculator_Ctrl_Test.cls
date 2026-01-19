/**
* ────────────────────────────────────────────────────────────────────────────────────
* DPMX_Container_Ctrl_Test
* Test class for RPP_Calculator_Ctrl apex class
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
public class RPP_Calculator_Ctrl_Test {
    @IsTest
    static void testInitialDataValidateOK(){
        RPP_Calculator__c RPPCalculator = RPP_Test_Utils.insertRPPCalculator('RPP Calculator Test 01', false, 0, 0);
        List<RPP_Calculator_Google_Sheet_Log__c> RPPCalculatorGoogleSheetLogList = new List<RPP_Calculator_Google_Sheet_Log__c>();
        RPP_Calculator_Google_Sheet_Log__c RPPCalculatorGoogleSheetLog01 = new RPP_Calculator_Google_Sheet_Log__c();
        RPPCalculatorGoogleSheetLog01.RPP_Calculator__c = RPPCalculator.Id;
        RPPCalculatorGoogleSheetLog01.Data__c = '["TYPE","FIELD01","FIELD02","FIELD03","FIELD04","FIELD05","FIELD06","FIELD07","FIELD08","FIELD09","FIELD10","FIELD11","FIELD12","FIELD13","FIELD14","FIELD15","FIELD16","FIELD17"]';
        RPPCalculatorGoogleSheetLogList.add(RPPCalculatorGoogleSheetLog01);
        RPP_Calculator_Google_Sheet_Log__c RPPCalculatorGoogleSheetLog02 = new RPP_Calculator_Google_Sheet_Log__c();
        RPPCalculatorGoogleSheetLog02.RPP_Calculator__c = RPPCalculator.Id;
        RPPCalculatorGoogleSheetLog02.Data__c = '["CALCULATOR","RPP Calculator Test 01","B12312323","Assignor Test 01"]';
        RPPCalculatorGoogleSheetLogList.add(RPPCalculatorGoogleSheetLog02);
        RPP_Calculator_Google_Sheet_Log__c RPPCalculatorGoogleSheetLog03 = new RPP_Calculator_Google_Sheet_Log__c();
        RPPCalculatorGoogleSheetLog03.RPP_Calculator__c = RPPCalculator.Id;
        RPPCalculatorGoogleSheetLog03.Data__c = '["CONFIG","1.- Cálculo de la First Loss para un rating objetivo","A","50,00%","20","0%","100%","CC-","AA","0%","0%","Sí","100%","Aseguradora A","AA","100.000","40%","1,00"]';
        RPPCalculatorGoogleSheetLogList.add(RPPCalculatorGoogleSheetLog03);
        RPP_Calculator_Google_Sheet_Log__c RPPCalculatorGoogleSheetLog04 = new RPP_Calculator_Google_Sheet_Log__c();
        RPPCalculatorGoogleSheetLog04.RPP_Calculator__c = RPPCalculator.Id;
        RPPCalculatorGoogleSheetLog04.Data__c = '["DEBTOR","8","FR12345678","","Debtor 01","EUR","516.726.895,67","516.726.895,67"]';
        RPPCalculatorGoogleSheetLogList.add(RPPCalculatorGoogleSheetLog04);
        RPP_Calculator_Google_Sheet_Log__c RPPCalculatorGoogleSheetLog05 = new RPP_Calculator_Google_Sheet_Log__c();
        RPPCalculatorGoogleSheetLog05.RPP_Calculator__c = RPPCalculator.Id;
        RPPCalculatorGoogleSheetLog05.Data__c = '["DEBTOR","5","US99933323","959800N60CEGKTATBG12","Debtor 02","USD","430.581.293,96","430.581.293,96"]';
        RPPCalculatorGoogleSheetLogList.add(RPPCalculatorGoogleSheetLog05);
        RPP_Calculator_Google_Sheet_Log__c RPPCalculatorGoogleSheetLog06 = new RPP_Calculator_Google_Sheet_Log__c();
        RPPCalculatorGoogleSheetLog06.RPP_Calculator__c = RPPCalculator.Id;
        RPPCalculatorGoogleSheetLog06.Data__c = '["DEBTOR","","","","Total","EUR","221.512.718,61","221.512.718,61"]';
        RPPCalculatorGoogleSheetLogList.add(RPPCalculatorGoogleSheetLog06);
        insert RPPCalculatorGoogleSheetLogList;
        Test.startTest();
            Map<String, Object> retMap = RPP_Calculator_Ctrl.initialData(RPPCalculator.Id, '');
            System.assertEquals(retMap.get('success'), true,'testInitialDataValidateOK - OK');
        Test.stopTest();
    }
    @IsTest
    static void testInitialDataValidateError01() {
        RPP_Calculator__c RPPCalculator = RPP_Test_Utils.insertRPPCalculator('RPP Calculator Test 01', false, 0, 0);
        List<RPP_Calculator_Google_Sheet_Log__c> RPPCalculatorGoogleSheetLogList = new List<RPP_Calculator_Google_Sheet_Log__c>();
        RPP_Calculator_Google_Sheet_Log__c RPPCalculatorGoogleSheetLog01 = new RPP_Calculator_Google_Sheet_Log__c();
        RPPCalculatorGoogleSheetLog01.RPP_Calculator__c = RPPCalculator.Id;
        RPPCalculatorGoogleSheetLog01.Data__c = '[]';
        RPPCalculatorGoogleSheetLogList.add(RPPCalculatorGoogleSheetLog01);
        insert RPPCalculatorGoogleSheetLogList;
        Test.startTest();
            Map<String, Object> retMap = RPP_Calculator_Ctrl.initialData(RPPCalculator.Id, '');
            System.assertEquals(retMap.get('success'), false,'testInitialDataValidateError01 - OK');
        Test.stopTest();
    }
    @IsTest
    static void testInitialDataValidateError02(){
        RPP_Calculator__c RPPCalculator = RPP_Test_Utils.insertRPPCalculator('RPP Calculator Test 01', false, 0, 0);
        List<RPP_Calculator_Google_Sheet_Log__c> RPPCalculatorGoogleSheetLogList = new List<RPP_Calculator_Google_Sheet_Log__c>();
        RPP_Calculator_Google_Sheet_Log__c RPPCalculatorGoogleSheetLog01 = new RPP_Calculator_Google_Sheet_Log__c();
        RPPCalculatorGoogleSheetLog01.RPP_Calculator__c = RPPCalculator.Id;
        RPPCalculatorGoogleSheetLog01.Data__c = '["TYPE","FIELD01","FIELD02","FIELD03","FIELD04","FIELD05","FIELD06","FIELD07","FIELD08","FIELD09","FIELD10","FIELD11","FIELD12","FIELD13","FIELD14","FIELD15","FIELD16","FIELD17","FIELD18"]';
        RPPCalculatorGoogleSheetLogList.add(RPPCalculatorGoogleSheetLog01);
        RPP_Calculator_Google_Sheet_Log__c RPPCalculatorGoogleSheetLog02 = new RPP_Calculator_Google_Sheet_Log__c();
        RPPCalculatorGoogleSheetLog02.RPP_Calculator__c = RPPCalculator.Id;
        RPPCalculatorGoogleSheetLog02.Data__c = '["CALCULATOR","","",""]';
        RPPCalculatorGoogleSheetLogList.add(RPPCalculatorGoogleSheetLog02);
        RPP_Calculator_Google_Sheet_Log__c RPPCalculatorGoogleSheetLog03 = new RPP_Calculator_Google_Sheet_Log__c();
        RPPCalculatorGoogleSheetLog03.RPP_Calculator__c = RPPCalculator.Id;
        RPPCalculatorGoogleSheetLog03.Data__c = '["CONFIG","","","","","","","","","","","","","","","","",""]';
        RPPCalculatorGoogleSheetLogList.add(RPPCalculatorGoogleSheetLog03);
        RPP_Calculator_Google_Sheet_Log__c RPPCalculatorGoogleSheetLog04 = new RPP_Calculator_Google_Sheet_Log__c();
        RPPCalculatorGoogleSheetLog04.RPP_Calculator__c = RPPCalculator.Id;
        RPPCalculatorGoogleSheetLog04.Data__c = '["DEBTOR","","","","","","",""]';
        RPPCalculatorGoogleSheetLogList.add(RPPCalculatorGoogleSheetLog04);
        RPP_Calculator_Google_Sheet_Log__c RPPCalculatorGoogleSheetLog05 = new RPP_Calculator_Google_Sheet_Log__c();
        RPPCalculatorGoogleSheetLog05.RPP_Calculator__c = RPPCalculator.Id;
        RPPCalculatorGoogleSheetLog05.Data__c = '["DEBTOR","X","US9XXXXXXXXX9933323","XX959800N60CEGKTATBG12","Debtor 02","XXX","XX","XX"]';
        RPPCalculatorGoogleSheetLogList.add(RPPCalculatorGoogleSheetLog05);
        RPP_Calculator_Google_Sheet_Log__c RPPCalculatorGoogleSheetLog06 = new RPP_Calculator_Google_Sheet_Log__c();
        RPPCalculatorGoogleSheetLog06.RPP_Calculator__c = RPPCalculator.Id;
        RPPCalculatorGoogleSheetLog06.Data__c = '["XXXXX","","","","Total","EUR","221.512.718,61","221.512.718,61"]';
        RPPCalculatorGoogleSheetLogList.add(RPPCalculatorGoogleSheetLog06);
        insert RPPCalculatorGoogleSheetLogList;
        Test.startTest();
            Map<String, Object> retMap = RPP_Calculator_Ctrl.initialData(RPPCalculator.Id, '');
            System.assertEquals(retMap.get('success'), false,'testInitialDataValidateError02 - OK');
        Test.stopTest();
    }
    @IsTest
    static void testInitialDataValidateError03(){
        RPP_Calculator__c RPPCalculator = RPP_Test_Utils.insertRPPCalculator('RPP Calculator Test 01', false, 0, 0);
        List<RPP_Calculator_Google_Sheet_Log__c> RPPCalculatorGoogleSheetLogList = new List<RPP_Calculator_Google_Sheet_Log__c>();
        RPP_Calculator_Google_Sheet_Log__c RPPCalculatorGoogleSheetLog01 = new RPP_Calculator_Google_Sheet_Log__c();
        RPPCalculatorGoogleSheetLog01.RPP_Calculator__c = RPPCalculator.Id;
        RPPCalculatorGoogleSheetLog01.Data__c = '["TYPE","FIELD01","FIELD02","FIELD03","FIELD04","FIELD05","FIELD06","FIELD07","FIELD08","FIELD09","FIELD10","FIELD11","FIELD12","FIELD13","FIELD14","FIELD15","FIELD16","FIELD17"]';
        RPPCalculatorGoogleSheetLogList.add(RPPCalculatorGoogleSheetLog01);
        RPP_Calculator_Google_Sheet_Log__c RPPCalculatorGoogleSheetLog02 = new RPP_Calculator_Google_Sheet_Log__c();
        RPPCalculatorGoogleSheetLog02.RPP_Calculator__c = RPPCalculator.Id;
        RPPCalculatorGoogleSheetLog02.Data__c = '["CALCULATOR"]';
        RPPCalculatorGoogleSheetLogList.add(RPPCalculatorGoogleSheetLog02);
        RPP_Calculator_Google_Sheet_Log__c RPPCalculatorGoogleSheetLog03 = new RPP_Calculator_Google_Sheet_Log__c();
        RPPCalculatorGoogleSheetLog03.RPP_Calculator__c = RPPCalculator.Id;
        RPPCalculatorGoogleSheetLog03.Data__c = '["CONFIG"]';
        RPPCalculatorGoogleSheetLogList.add(RPPCalculatorGoogleSheetLog03);
        RPP_Calculator_Google_Sheet_Log__c RPPCalculatorGoogleSheetLog04 = new RPP_Calculator_Google_Sheet_Log__c();
        RPPCalculatorGoogleSheetLog04.RPP_Calculator__c = RPPCalculator.Id;
        RPPCalculatorGoogleSheetLog04.Data__c = '["DEBTOR"]';
        RPPCalculatorGoogleSheetLogList.add(RPPCalculatorGoogleSheetLog04);
        insert RPPCalculatorGoogleSheetLogList;
        Test.startTest();
            Map<String, Object> retMap = RPP_Calculator_Ctrl.initialData(RPPCalculator.Id, '');
            System.assertEquals(retMap.get('success'), false,'testInitialDataValidateError03 - OK');
        Test.stopTest();
    }
    @IsTest
    static void testInitialDataValidateError04(){
        RPP_Calculator__c RPPCalculator = RPP_Test_Utils.insertRPPCalculator('RPP Calculator Test 01', false, 0, 0);
        List<RPP_Calculator_Google_Sheet_Log__c> RPPCalculatorGoogleSheetLogList = new List<RPP_Calculator_Google_Sheet_Log__c>();
        RPP_Calculator_Google_Sheet_Log__c RPPCalculatorGoogleSheetLog01 = new RPP_Calculator_Google_Sheet_Log__c();
        RPPCalculatorGoogleSheetLog01.RPP_Calculator__c = RPPCalculator.Id;
        RPPCalculatorGoogleSheetLog01.Data__c = '["TYPE","FIELD01","FIELD02","FIELD03","FIELD04","FIELD05","FIELD06","FIELD07","FIELD08","FIELD09","FIELD10","FIELD11","FIELD12","FIELD13","FIELD14","FIELD15","FIELD16","FIELD17"]';
        RPPCalculatorGoogleSheetLogList.add(RPPCalculatorGoogleSheetLog01);
        RPP_Calculator_Google_Sheet_Log__c RPPCalculatorGoogleSheetLog02 = new RPP_Calculator_Google_Sheet_Log__c();
        RPPCalculatorGoogleSheetLog02.RPP_Calculator__c = RPPCalculator.Id;
        RPPCalculatorGoogleSheetLog02.Data__c = '["CALCULATOR","RPP Calculator Test 01","B12312323XXXXXXXXXXXXXXXXX","Assignor Test 01"]';
        RPPCalculatorGoogleSheetLogList.add(RPPCalculatorGoogleSheetLog02);
        RPP_Calculator_Google_Sheet_Log__c RPPCalculatorGoogleSheetLog03 = new RPP_Calculator_Google_Sheet_Log__c();
        RPPCalculatorGoogleSheetLog03.RPP_Calculator__c = RPPCalculator.Id;
        RPPCalculatorGoogleSheetLog03.Data__c = '["CONFIG","3.- Cálculo de la First Loss para un rating objetivo","X","X50,00%","X20","X0%","X100%","XCC-","XAA","X0%","X0%","XSí","X100%","Aseguradora A","XAA","X100.000","X40%","X1,00"]';
        RPPCalculatorGoogleSheetLogList.add(RPPCalculatorGoogleSheetLog03);
        RPP_Calculator_Google_Sheet_Log__c RPPCalculatorGoogleSheetLog04 = new RPP_Calculator_Google_Sheet_Log__c();
        RPPCalculatorGoogleSheetLog04.RPP_Calculator__c = RPPCalculator.Id;
        RPPCalculatorGoogleSheetLog04.Data__c = '["DEBTOR","8","XXXXXXXXXXXFR12345678","","Debtor 01","XEUR","X516.726.895,67","X516.726.895,67"]';
        RPPCalculatorGoogleSheetLogList.add(RPPCalculatorGoogleSheetLog04);
        RPP_Calculator_Google_Sheet_Log__c RPPCalculatorGoogleSheetLog05 = new RPP_Calculator_Google_Sheet_Log__c();
        RPPCalculatorGoogleSheetLog05.RPP_Calculator__c = RPPCalculator.Id;
        RPPCalculatorGoogleSheetLog05.Data__c = '["DEBTOR","5","US99933323","959800N60CEGKTATBG12"]';
        RPPCalculatorGoogleSheetLogList.add(RPPCalculatorGoogleSheetLog05);
        RPP_Calculator_Google_Sheet_Log__c RPPCalculatorGoogleSheetLog06 = new RPP_Calculator_Google_Sheet_Log__c();
        RPPCalculatorGoogleSheetLog06.RPP_Calculator__c = RPPCalculator.Id;
        RPPCalculatorGoogleSheetLog06.Data__c = '["DEBTOR","","","","Total"]';
        RPPCalculatorGoogleSheetLogList.add(RPPCalculatorGoogleSheetLog06);
        insert RPPCalculatorGoogleSheetLogList;
        Test.startTest();
            Map<String, Object> retMap = RPP_Calculator_Ctrl.initialData(RPPCalculator.Id, '');
            System.assertEquals(retMap.get('success'), false,'testInitialDataValidateError04 - OK');
        Test.stopTest();
    }
    @IsTest
    static void testInitialDataValidated01() {
        RPP_Calculator__c RPPCalculator = RPP_Test_Utils.insertRPPCalculator('RPP Calculator Test 01', true, 3, 3);
        RPP_Calculator_Simulation__c RPPCalculatorSimulation = [SELECT Id FROM RPP_Calculator_Simulation__c WHERE Source_RPP_Calculator__c = :RPPCalculator.Id LIMIT 1];
        RPPCalculatorSimulation.Simulated__c = true;
        RPPCalculatorSimulation.Final_Simulation__c = true;
        update RPPCalculatorSimulation;
        RPP_Calculator_Debtor__c RPPCalculatorDebtor = new RPP_Calculator_Debtor__c();
        RPPCalculatorDebtor.RPP_Calculator__c = RPPCalculator.Id;
        RPPCalculatorDebtor.Obligor_Debtor__c = 'Total';
        insert RPPCalculatorDebtor;
        Test.startTest();
            Map<String, Object> retMap = RPP_Calculator_Ctrl.initialData(RPPCalculator.Id, RPPCalculatorSimulation.Id);
            System.assertEquals(retMap.get('success'), true,'testInitialDataValidated01 - OK');
        Test.stopTest();
    }
    @IsTest
    static void testInitialDataValidated02() {
        RPP_Calculator__c RPPCalculator = RPP_Test_Utils.insertRPPCalculator('RPP Calculator Test 01', true, 3, 3);
        Test.startTest();
            Map<String, Object> retMap = RPP_Calculator_Ctrl.initialData(RPPCalculator.Id, null);
            System.assertEquals(retMap.get('success'), true,'testInitialDataValidated02 - OK');
        Test.stopTest();
    }
    @IsTest
    static void testGetRatings() {
        RPP_Calculator__c RPPCalculator = RPP_Test_Utils.insertRPPCalculator('RPP Calculator Test 01', true, 3, 0);
        Test.startTest();
            Map<String, Object> retMap = RPP_Calculator_Ctrl.getRatings(RPPCalculator.Id);
            System.assertEquals(retMap.get('success'), false,'testGetRatings - OK');
        Test.stopTest();
    }
    @IsTest
    static void testGgetSimulationData() {
        RPP_Calculator__c RPPCalculator = RPP_Test_Utils.insertRPPCalculator('RPP Calculator Test 01', true, 3, 0);
        Test.startTest();
            Map<String, Object> retMap1 = RPP_Calculator_Ctrl.getRatings(RPPCalculator.Id);
            RPP_Calculator_Simulation__c RPPCalculatorSimulation = [SELECT Id FROM RPP_Calculator_Simulation__c WHERE Source_RPP_Calculator__c = :RPPCalculator.Id];
            Map<String, Object> retMap2 = RPP_Calculator_Ctrl.getSimulationData(RPPCalculatorSimulation.Id);
            System.assertEquals(retMap2.get('canSimulate'), true,'testGgetSimulationData - OK');
        Test.stopTest();
    }
    @IsTest
    static void testGetFinalData() {
        RPP_Calculator__c RPPCalculator = RPP_Test_Utils.insertRPPCalculator('RPP Calculator Test 01', true, 3, 3);
        RPP_Calculator_Simulation__c RPPCalculatorSimulation = [SELECT Id FROM RPP_Calculator_Simulation__c WHERE Source_RPP_Calculator__c = :RPPCalculator.Id LIMIT 1];
        Test.startTest();
            Map<String, Object> retMap = RPP_Calculator_Ctrl.getFinalData(RPPCalculatorSimulation.Id);
            System.assertEquals(retMap.get('success'), false,'testGetFinalData - OK');
        Test.stopTest();
    }
    @IsTest
    static void testSetFinalSimulation01() {
        RPP_Calculator__c RPPCalculator = RPP_Test_Utils.insertRPPCalculator('RPP Calculator Test 01', true, 3, 3);
        RPP_Calculator_Simulation__c RPPCalculatorSimulation = [SELECT Id, Name FROM RPP_Calculator_Simulation__c WHERE Source_RPP_Calculator__c = :RPPCalculator.Id LIMIT 1];
        Test.startTest();
            Map<String, Object> retMap = RPP_Calculator_Ctrl.setFinalSimulation(RPPCalculatorSimulation.Id, RPPCalculatorSimulation.Name, RPPCalculator.Id);
            System.assertEquals(retMap.get('success'), true,'testSetFinalSimulation01 - OK');
        Test.stopTest();
    }
    @IsTest
    static void testSetFinalSimulation02() {
        RPP_Calculator__c RPPCalculator = RPP_Test_Utils.insertRPPCalculator('RPP Calculator Test 01', true, 3, 3);
        RPP_Calculator_Simulation__c RPPCalculatorSimulation = [SELECT Id, Name FROM RPP_Calculator_Simulation__c WHERE Source_RPP_Calculator__c = :RPPCalculator.Id LIMIT 1];
        RPPCalculatorSimulation.Final_Simulation__c = true;
        update RPPCalculatorSimulation;
        Test.startTest();
            Map<String, Object> retMap = RPP_Calculator_Ctrl.setFinalSimulation(RPPCalculatorSimulation.Id, RPPCalculatorSimulation.Name, RPPCalculator.Id);
            System.assertEquals(retMap.get('success'), false,'testSetFinalSimulation02 - OK');
        Test.stopTest();
    }
}