/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_Projection_Service_Test
* @Author   aleksandar.dinkov.contractor@bbva.com
* @Date     Created: 21/05/2023
* @Group    ARCE
* @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
* @Last Modified On   : 03-05-2025
* @Description Arc_Gen_Projection_Service_Test
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
*/
@isTest
public with sharing class Arc_Gen_Projection_Service_Test { 
    /**
    * @description makeData
    * @author aleksandar.dinkov.contractor@bbva.com
    **/
    @TestSetup
    static void makeData() {
        Arc_UtilitysDataTest_tst.setupAcccounts();
        final Map<String, arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{ 'G000001', 'C000001' });
        final arce.Arc_Gen_Account_Wrapper fath = groupAccWrapper.get('G000001');
        final arce.Arc_Gen_Account_Wrapper kid = groupAccWrapper.get('C000001'); 
        final arce__Analysis__c analysis = Arc_UtilitysDataTest_tst.crearArceAnalysis('Test Analysis', null, fath.accId);
        insert analysis;
        final arce__Sector__c sect = Arc_UtilitysDataTest_tst.crearSector('Executive Summ', '500', 'ExecSumm', null);
        insert sect;
        final arce__rating__c rating = new arce__rating__c();
        insert rating; 
        final arce__Financial_Statements__c ffss = new arce__Financial_Statements__c(
            arce__ffss_valid_type__c = '1',
            arce__ffss_valid_for_rating_type__c = '1',
            arce__financial_statement_id__c = '0000000000000000012345',
            arce__rating_id__c = rating.Id
        );
        insert ffss;
        final arce__Account_has_Analysis__c accHasAnalysis = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(sect.Id, analysis.Id, kid.accId, '1');
        accHasAnalysis.arce__ffss_for_rating_id__c = ffss.Id;
        insert accHasAnalysis;
        final List<String> scenariosList = new List<String>{ 'Base Case', 'Up', 'Down' };
        final List<arce__Projection__c> projectionsList = new List<arce__Projection__c>();
        for (String var : scenariosList) {
            final arce__Projection__c proj = new arce__Projection__c(
                arce__Scenario_Type__c = var,
                arce__Account_has_Analysis__c = accHasAnalysis.Id,
                arce__Projection_Id__c = '0000000000000000000123',
                arce__Statement_Currency__c = UserInfo.getDefaultCurrency(),
                arce__FinancialStatement_Type__c = 'CONSOLIDATED',
                arce__Period_StartDate__c = '01-01-2021',
                arce__Period_EndDate__c = '31-12-2021',
                arce__Projection_Type__c = 'Projection'
            );
            projectionsList.add(proj);
        }
        insert projectionsList;
    }

    /**
    * @description callBaseProjectionTest
    * @author aleksandar.dinkov.contractor@bbva.com
    **/
    @isTest
    public static void callBaseProjectionTest() {
        Test.startTest();
        final arce__Account_has_Analysis__c aha = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        final arce.Arc_Gen_Projection_ServiceWrapper srvWrapper = Arc_Gen_Projection_Service.callProjection('Base Case', aha.Id, new Set<String>{ '0000000000000000012345' }, null);
        System.assertEquals(0, srvWrapper.messageList.size(), 'Expected errors 0, instead has: ' + srvWrapper.messageList.size());
        Test.stopTest(); 
    }

    /**
    * @description callModProjectionTest
    * @author aleksandar.dinkov.contractor@bbva.com
    **/
    @isTest
    public static void callModProjectionTest() {
        Test.startTest();
        final arce__Account_has_Analysis__c aha = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        final arce.Arc_Gen_Projection_ServiceWrapper srvWrapper = Arc_Gen_Projection_Service.callProjection('Up', aha.Id, null, null); 
        System.assertEquals(0, srvWrapper.messageList.size(), 'Expected errors 0, instead has: ' + srvWrapper.messageList.size());
        Test.stopTest();
    }

    /**
    * @description callProjectionRatingTest
    * @author aleksandar.dinkov.contractor@bbva.com
    **/
    @isTest
    public static void callProjectionRatingTest() {
        Test.startTest();
        final arce__Account_has_Analysis__c aha = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        final arce__Projection__c projection = [SELECT Id FROM arce__Projection__c LIMIT 1];
        Arc_Gen_Projection_Service.callProjectionRating(aha.Id, projection.Id);
        final arce__Projection__c afterProjection = [SELECT Id, arce__Simulation_Long_Scale_Value__c, arce__Simulation_Short_Scale_Value__c, arce__Simulation_Score__c FROM arce__Projection__c WHERE Id = :projection.Id LIMIT 1];
        System.assertEquals('BBB+1', afterProjection.arce__Simulation_Long_Scale_Value__c, 'Expected value: BBB+1, instead has ' + afterProjection.arce__Simulation_Long_Scale_Value__c);
        Test.stopTest();
    }

}