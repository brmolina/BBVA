/**
------------------------------------------------------------------------------------------------
@Name     KPI_FinantialCustomers_Wrapper_Test
@Author   Global Hub
@Date     Created: 2023-09-11
------------------------------------------------------------------------------------------------
@Description Test class for KPI_FinantialCustomers_Wrapper_Test
------------------------------------------------------------------------------------------------
@Changes
| 2023-09-11 ivan.garces.contractor@bbva.com
            Class Creation
-----------------------------------------------------------------------------------------------
*/
@SuppressWarnings('PMD.CyclomaticComplexity, PMD.CognitiveComplexity, sf:TooManyMethods, PMD.ExcessiveParameterList, sf:NPathComplexity, PMD.ApexCRUDViolation, PMD.NcssTypeCount, PMD.EmptyStatementBlock, PMD.NcssMethodCount, PMD.AvoidDeeplyNestedIfStmts, PMD.StdCyclomaticComplexity, PMD.ApexSOQLInjection, PMD.FormalParameterNamingConventions, PMD.ExcessiveClassLength , PMD.ExcessivePublicCount, PMD.AvoidGlobalModifier, PMD.UnusedLocalVariable, PMD.ApexAssertionsShouldIncludeMessage, PMD.IfStmtsMustUseBraces, PMD.IfElseStmtsMustUseBraces')
@isTest
public with sharing class KPI_FinantialCustomers_Wrapper_Test {
    /**
    @description
    @author Global Hub | 2023-09-07
    */
    @isTest
    static void refreshObligationTest() {
        Test.startTest();
        final String testStr = 'test';
        final Integer testInt = 10;
        final Double testDou = 10;

        final KPI_FinantialCustomers_Wrapper wrap = new KPI_FinantialCustomers_Wrapper();
        wrap.data = new List<KPI_FinantialCustomers_Wrapper.Data>();
        wrap.success = true;
        wrap.message = 'test';
        wrap.pagination = new KPI_FinantialCustomers_Wrapper.Pagination();

        final KPI_FinantialCustomers_Wrapper.Data data = new KPI_FinantialCustomers_Wrapper.Data();
        data.code = testStr;
        data.name = testStr;
        data.clientGroup = new KPI_FinantialCustomers_Wrapper.ClientGroup();
        data.managerId = testStr;
        data.country = new KPI_FinantialCustomers_Wrapper.Country();
        data.contracts = new List<KPI_FinantialCustomers_Wrapper.Contracts>();

        final KPI_FinantialCustomers_Wrapper.Pagination pag = new KPI_FinantialCustomers_Wrapper.Pagination();
        pag.links = new KPI_FinantialCustomers_Wrapper.Links();
        pag.page = testInt;
        pag.totalPage = testInt;
        pag.totalElements = testInt;
        pag.pageSize = testInt;

        final KPI_FinantialCustomers_Wrapper.Contracts con = new KPI_FinantialCustomers_Wrapper.Contracts();
        con.id = testStr;
        con.codeLocal = testStr;
        con.nameOriginSystem = testStr;
        con.entity = new KPI_FinantialCustomers_Wrapper.Entity();
        con.country = new KPI_FinantialCustomers_Wrapper.Country();
        con.codeOfficeBooking = testStr;
        con.initialDate = testStr;
        con.expirationDate = testStr;
        con.sustainabilityDate = testStr;
        con.businessArea = new KPI_FinantialCustomers_Wrapper.BusinessArea();
        con.product = new KPI_FinantialCustomers_Wrapper.Product();
        con.validYears = testInt;
        con.initialMainAmount = testDou;
        con.productCurrency = testStr;
        con.sustainabilityFamily = new KPI_FinantialCustomers_Wrapper.SustainabilityFamily();
        con.operationIndicatorType = true;
        con.dataValue = new KPI_FinantialCustomers_Wrapper.DataValue();
        con.agencyIndicatorType = true;
        con.project = new KPI_FinantialCustomers_Wrapper.Project();
        con.tranch = new KPI_FinantialCustomers_Wrapper.Tranch();

        final KPI_FinantialCustomers_Wrapper.BusinessArea buss = new KPI_FinantialCustomers_Wrapper.BusinessArea();
        buss.id = testStr;
        buss.description = testStr;

        final KPI_FinantialCustomers_Wrapper.Entity ent = new KPI_FinantialCustomers_Wrapper.Entity();
        ent.id = testStr;

        final KPI_FinantialCustomers_Wrapper.Product prod = new KPI_FinantialCustomers_Wrapper.Product();
        prod.id = testStr;
        prod.description = testStr;

        final KPI_FinantialCustomers_Wrapper.Country count = new KPI_FinantialCustomers_Wrapper.Country();
        count.id = testStr;
        count.description = testStr;

        final KPI_FinantialCustomers_Wrapper.Sector sect = new KPI_FinantialCustomers_Wrapper.Sector();
        sect.id = testStr;
        sect.description = testStr;

        final KPI_FinantialCustomers_Wrapper.Activity act = new KPI_FinantialCustomers_Wrapper.Activity();
        act.id = testStr;
        act.description = testStr;

        final KPI_FinantialCustomers_Wrapper.Segment seg = new KPI_FinantialCustomers_Wrapper.Segment();
        seg.id = testStr;
        seg.description = testStr;
        seg.subSegment = new KPI_FinantialCustomers_Wrapper.SubSegment();

        final KPI_FinantialCustomers_Wrapper.SubSegment ss = new KPI_FinantialCustomers_Wrapper.SubSegment();
        ss.id = testStr;
        ss.description = testStr;

        final KPI_FinantialCustomers_Wrapper.Tranch tran = new KPI_FinantialCustomers_Wrapper.Tranch();
        tran.id = testStr;
        tran.description = testStr;

        final KPI_FinantialCustomers_Wrapper.Links link = new KPI_FinantialCustomers_Wrapper.Links();
        link.first = testStr;
        link.last = testStr;
        link.previous = testStr;
        link.next = testStr;

        final KPI_FinantialCustomers_Wrapper.DataValue val = new KPI_FinantialCustomers_Wrapper.DataValue();
        val.variation = testDou;
        val.value = testDou;

        final KPI_FinantialCustomers_Wrapper.Project proj = new KPI_FinantialCustomers_Wrapper.Project();
        proj.id = testStr;

        final KPI_FinantialCustomers_Wrapper.SustainabilityFamily sfam = new KPI_FinantialCustomers_Wrapper.SustainabilityFamily();
        sfam.id = testStr;
        sfam.sustainableCoordinator = testStr;
        sfam.feeSustainableCoordinator = testDou;
        sfam.sustainabilyAgentId = testStr;
        sfam.description = testStr;
        sfam.sustainabilityCategory = new KPI_FinantialCustomers_Wrapper.SustainabilityCategory();

        final KPI_FinantialCustomers_Wrapper.ClientGroup clG = new KPI_FinantialCustomers_Wrapper.ClientGroup();
        clG.id = testStr;
        clG.description = testStr;
        clG.country = new KPI_FinantialCustomers_Wrapper.Country();
        clG.sector = new KPI_FinantialCustomers_Wrapper.Sector();
        clG.segment = new KPI_FinantialCustomers_Wrapper.Segment();
        clG.activity = new KPI_FinantialCustomers_Wrapper.Activity();
        System.assert(clG != null, 'object is null');
        Test.stopTest();
    }
}