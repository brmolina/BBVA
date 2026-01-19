/**
------------------------------------------------------------------------------------------------
@Name     KPI_DetailTableController_Test
@Author   Global Hub
@Date     Created: 2023-09-11
------------------------------------------------------------------------------------------------
@Description Test class for KPI_DetailTableController_Test
------------------------------------------------------------------------------------------------
@Changes
| 2023-09-11 ivan.garces.contractor@bbva.com
            Class Creation
-----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('PMD.CyclomaticComplexity, PMD.CognitiveComplexity, sf:TooManyMethods, PMD.ExcessiveParameterList, sf:NPathComplexity, PMD.ApexCRUDViolation, PMD.NcssTypeCount, PMD.EmptyStatementBlock, PMD.NcssMethodCount, PMD.AvoidDeeplyNestedIfStmts, PMD.StdCyclomaticComplexity, PMD.ApexSOQLInjection, PMD.FormalParameterNamingConventions, PMD.ExcessiveClassLength , PMD.ExcessivePublicCount, PMD.AvoidGlobalModifier, PMD.UnusedLocalVariable, PMD.ApexAssertionsShouldIncludeMessage, PMD.IfStmtsMustUseBraces, PMD.IfElseStmtsMustUseBraces')
@isTest
public with sharing class KPI_DetailTableController_Test {
    /**
    @description
    @author Global Hub | 2023-09-07
    */
    @isTest
    static void refreshObligationTest() {
        Test.startTest();
        final KPI_Obligation_Wrapper kpiCatalogue = KPI_DetailTableController.refreshObligation('randomCatalog1', 'randomCatalog1', 'randomCatalog1');
        system.assert(kpiCatalogue.success, 'Not the same');
        Test.stopTest();
    }

    /**
    @description
    @author Global Hub | 2023-09-07
    */
    @isTest
    static void getCatalogTest() {
        Test.startTest();
        final Map<String, Object> kpiCatalogue = KPI_DetailTableController.getCatalog('randomCatalog');
        system.assert((boolean) kpiCatalogue.get('success'), 'Not the same');
        Test.stopTest();
    }

    /**
    @description
    @author Global Hub | 2023-09-07
    */
    @isTest
    static void postObligationTest() {
        Test.startTest();
        final Map<String, Object> kpiCatalogue = KPI_DetailTableController.postObligation('randomCatalog');
        system.assert((boolean) kpiCatalogue.get('success'), 'Not the same');
        Test.stopTest();
    }

    /**
    @description
    @author Global Hub | 2023-09-07
    */
    @isTest
    static void putObligationTest() {
        Test.startTest();
        final Map<String, Object> kpiCatalogue = KPI_DetailTableController.putObligation('randomCatalog');
        system.assert((boolean) kpiCatalogue.get('success'), 'Not the same');
        Test.stopTest();
    }

    /**
    @description
    @author Global Hub | 2023-09-07
    */
    @isTest
    static void deleteObligationTest() {
        Test.startTest();
        final Map<String, Object> kpiCatalogue = KPI_DetailTableController.deleteObligation('randomCatalog');
        system.assert((boolean) kpiCatalogue.get('success'), 'Not the same');
        Test.stopTest();
    }
}