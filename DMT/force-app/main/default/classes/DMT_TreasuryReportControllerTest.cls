@IsTest
public class DMT_TreasuryReportControllerTest {
    
    @TestSetup
    static void setupTestData() {
        // Crear datos de metadata personalizada para DMT_Operational_Restrictions__mdt
        // Nota: En tests, no podemos insertar metadata personalizada, así que mockearemos las queries
        
        // Crear datos de taxonomía
        List<DMT_Taxonomy_values__c> taxoValues = new List<DMT_Taxonomy_values__c>();
        taxoValues.add(new DMT_Taxonomy_values__c(
            DMT_Catalog__c = 'C162',
            DMT_Value__c = 'TAXO001',
            DMT_Name_EN__c = 'Taxonomy Value 1 EN'
        ));
        taxoValues.add(new DMT_Taxonomy_values__c(
            DMT_Catalog__c = 'B444',
            DMT_Value__c = 'TAXO002',
            DMT_Name_EN__c = 'Taxonomy Value 2 EN'
        ));
        taxoValues.add(new DMT_Taxonomy_values__c(
            DMT_Catalog__c = 'C162',
            DMT_Value__c = '100100',
            DMT_Name_EN__c = 'Last Level 100100'
        ));
        taxoValues.add(new DMT_Taxonomy_values__c(
            DMT_Catalog__c = 'B444',
            DMT_Value__c = 'RISK001',
            DMT_Name_EN__c = 'Risk Type 1'
        ));
        insert taxoValues;
        
        // Crear Accounts
        List<Account> accounts = new List<Account>();
        Account acc1 = new Account(
            Name = 'Test Account 1',
            DES_Group_Code__c = 'GROUP001',
            DES_AGGR_Sector__c = 'TAXO001',
            g_customer_id__c = 'CUST001',
            DES_ID_Fiscal__c = 'FISC001',
            // participant_name__c = 'Participant 1',
            DES_Rating_Int__c = 'AA'
        );
        accounts.add(acc1);
        
        Account acc2 = new Account(
            Name = 'Test Account 2',
            DES_AGGR_Sector__c = 'TAXO002',
            g_customer_id__c = 'CUST002',
            DES_ID_Fiscal__c = 'FISC002',
            DES_Rating_Int__c = 'BB',
            DES_Structure_Type__c = 'Subsidiary'
        );
        accounts.add(acc2);
        insert accounts;

        acc2.DES_Main_Parent__c = acc1.Id;
        acc2.business_group_id__c = acc1.Id;

        update acc2;
        
        // Crear DMT Lines
        List<DMT_Line__c> dmtLines = new List<DMT_Line__c>();
        DMT_Line__c line1 = new DMT_Line__c(
            Client__c = acc2.Id,
            CurrencyIsoCode = 'USD',
            Client_Code__c = 'CUST002',
            Booking_Geography__c = 'CO',
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addDays(365),
            Line_ID__c = 'LINE001',
            Status__c = 'Closed',
            Closed__c = 'Won'
        );
        dmtLines.add(line1);
        
        DMT_Line__c line2 = new DMT_Line__c(
            Client__c = acc2.Id,
            CurrencyIsoCode = 'EUR',
            Client_Code__c = 'CUST002',
            Booking_Geography__c = 'AR',
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addDays(730),
            Line_ID__c = 'LINE002',
            Status__c = 'Closed',
            Closed__c = 'Won'
        );
        dmtLines.add(line2);
        insert dmtLines;
        
        // Crear DMT Consolidated Lines
        List<DMT_Consolidated_Line__c> consolidatedLines = new List<DMT_Consolidated_Line__c>();
        DMT_Consolidated_Line__c cons1 = new DMT_Consolidated_Line__c(
            Line_ID__c = 'LINE001',
            gf_group_line_id__c =  'LINE001',
            g_limit_last_level_type__c = '100100',
            gf_period_from_line_day_number__c = null, // N/A to N/A
            gf_clsfn_risk_type_internal_id__c = '100100',
            gf_condition_line_amount__c = 100000,
            g_line_status_type__c = 'CW',
            g_entific_id__c = 'CO',
            gf_group_priority_line_id__c = '01'
        );
        consolidatedLines.add(cons1);
        
        DMT_Consolidated_Line__c cons2 = new DMT_Consolidated_Line__c(
            Line_ID__c = 'LINE001',
            gf_group_line_id__c =  'LINE001',
            g_limit_last_level_type__c = '100100',
            g_expert_criteria_risk_type__c = 'IRSW',
            gf_period_from_line_day_number__c = 0, // 0 Days to 3 Years
            gf_clsfn_risk_type_internal_id__c = '100100',
            gf_condition_line_amount__c = 200000,
            g_line_status_type__c = 'CW',
            g_entific_id__c = 'CO',
            gf_group_priority_line_id__c = '01'
        );
        consolidatedLines.add(cons2);
        
        DMT_Consolidated_Line__c cons3 = new DMT_Consolidated_Line__c(
            Line_ID__c = 'LINE002',
            gf_group_line_id__c =  'LINE001',
            g_limit_last_level_type__c = '100200',
            g_expert_criteria_risk_type__c = 'FOEX',
            gf_period_from_line_day_number__c = 1095, // 3 Years (3*365)
            gf_clsfn_risk_type_internal_id__c = '100200',
            gf_condition_line_amount__c = 300000,
            g_line_status_type__c = 'CW',
            g_entific_id__c = 'AR',
            gf_group_priority_line_id__c = '01'
        );
        consolidatedLines.add(cons3);
        insert consolidatedLines;
    }
    
    @IsTest
    static void testGetDMTData() {
        // Test principal - verificar que el método retorna datos correctamente
        Test.startTest();
        List<DMT_TreasuryReportController.GroupWrapper> result = DMT_TreasuryReportController.getDMTData();
        Test.stopTest();
        
        // Verificaciones
        System.assertNotEquals(null, result, 'El resultado no debería ser nulo');
        System.assert(!result.isEmpty(), 'Debería haber al menos un grupo');
        
        // Verificar estructura del primer grupo
        DMT_TreasuryReportController.GroupWrapper firstGroup = result[0];system.debug('firstGroup ' +firstGroup);
        System.assertNotEquals(null, firstGroup.groupCode, 'El groupCode no debería ser nulo');
        System.assert(!firstGroup.clients.isEmpty(), 'Debería haber al menos un cliente en el grupo');
        
        // Verificar estructura del primer cliente
        DMT_TreasuryReportController.ClientWrapper firstClient = firstGroup.clients[0];
        System.assertNotEquals(null, firstClient.accountName, 'El accountName no debería ser nulo');
        System.assert(!firstClient.lines.isEmpty(), 'Debería haber al menos una línea en el cliente');
        
        // Verificar estructura de la primera línea
        DMT_TreasuryReportController.LineWrapper firstLine = firstClient.lines[0];
        System.assertNotEquals(null, firstLine.lineId, 'El lineId no debería ser nulo');
        System.assert(!firstLine.risks.isEmpty(), 'Debería haber al menos un risk en la línea');
        
        // Verificar estructura del primer risk
        DMT_TreasuryReportController.RiskWrapper firstRisk = firstLine.risks[0];
        System.assertNotEquals(null, firstRisk.lastLevelId, 'El lastLevelId no debería ser nulo');
    }
    
    @IsTest
    static void testGroupByLastLevel() {
        // Preparar datos de prueba
        List<DMT_Consolidated_Line__c> testLines = new List<DMT_Consolidated_Line__c>();
        DMT_Consolidated_Line__c line1 = new DMT_Consolidated_Line__c(g_limit_last_level_type__c = '100100');
        DMT_Consolidated_Line__c line2 = new DMT_Consolidated_Line__c(g_limit_last_level_type__c = '100100');
        DMT_Consolidated_Line__c line3 = new DMT_Consolidated_Line__c(g_limit_last_level_type__c = '100200');
        testLines.add(line1);
        testLines.add(line2);
        testLines.add(line3);
        
        Test.startTest();
        Map<String, List<DMT_Consolidated_Line__c>> result = DMT_TreasuryReportController.groupByLastLevel(testLines);
        Test.stopTest();
        
        System.assertEquals(2, result.size(), 'Debería haber 2 grupos por lastLevelId');
        System.assertEquals(2, result.get('100100').size(), 'Debería haber 2 líneas con lastLevelId 100100');
        System.assertEquals(1, result.get('100200').size(), 'Debería haber 1 línea con lastLevelId 100200');
    }
    
    @IsTest
    static void testProcessRiskData() {
        // Preparar datos de prueba
        String lastLevelId = '100100';
        List<DMT_Consolidated_Line__c> testLines = new List<DMT_Consolidated_Line__c>();
        
        DMT_Consolidated_Line__c line1 = new DMT_Consolidated_Line__c(
            gf_clsfn_risk_type_internal_id__c = 'RISK001',
            gf_period_from_line_day_number__c = null,
            gf_condition_line_amount__c = 100000
        );
        
        DMT_Consolidated_Line__c line2 = new DMT_Consolidated_Line__c(
            g_expert_criteria_risk_type__c = 'PROD001',
            gf_clsfn_risk_type_internal_id__c = 'RISK001',
            gf_period_from_line_day_number__c = 0,
            gf_condition_line_amount__c = 200000
        );

        DMT_Consolidated_Line__c line3 = new DMT_Consolidated_Line__c(
            g_expert_criteria_risk_type__c = 'PROD002',
            gf_clsfn_risk_type_internal_id__c = 'RISK001',
            gf_period_from_line_day_number__c = 0,
            gf_condition_line_amount__c = 300000
        );
        
        testLines.add(line1);
        testLines.add(line2);
        testLines.add(line3);
        
        // Mock de los maps
        Map<String, String> productLabelMap = new Map<String, String>{
            'PROD001' => 'Product 1',
            'PROD002' => 'Product 2'
        };
        
        Map<String, String> taxoMap = new Map<String, String>{
            '100100' => 'Last Level 100100',
            'RISK001' => 'Risk Type 1'
        };
        
        Test.startTest();
        DMT_TreasuryReportController.RiskWrapper result = DMT_TreasuryReportController.processRiskData(
            lastLevelId, testLines, productLabelMap, taxoMap
        );
        Test.stopTest();
        
        // Verificaciones
        System.assertEquals('Last Level 100100', result.lastLevelId, 'LastLevelId debería estar mapeado correctamente');
        System.assertEquals('Risk Type 1', result.typeOfRisk, 'Type of Risk debería estar mapeado correctamente');
        System.assert(result.product.contains('Product 1') && result.product.contains('Product 2'), 
                     'Product debería contener ambos productos');
        System.assertEquals('100000', result.naToNa, 'naToNa debería tener el valor correcto');
    }
    
    @IsTest
    static void testGetPeriodField() {
        Test.startTest();
        // Test para periodo nulo
        String result1 = DMT_TreasuryReportController.getPeriodField(null);
        System.assertEquals('naToNa', result1, 'Periodo nulo debería mapear a naToNa');
        
        // Test para periodo 0
        String result2 = DMT_TreasuryReportController.getPeriodField(0);
        System.assertEquals('zeroDaysTo3Years', result2, 'Periodo 0 debería mapear a zeroDaysTo3Years');
        
        // Test para periodo 3 años (3*365)
        String result3 = DMT_TreasuryReportController.getPeriodField(1095);
        System.assertEquals('threeYearsTo5Years', result3, 'Periodo 1095 debería mapear a threeYearsTo5Years');
        
        // Test para periodo 5 años (5*365)
        String result4 = DMT_TreasuryReportController.getPeriodField(1825);
        System.assertEquals('fiveYearsTo8Years', result4, 'Periodo 1825 debería mapear a fiveYearsTo8Years');
        
        // Test para periodo 8 años (8*365)
        String result5 = DMT_TreasuryReportController.getPeriodField(2920);
        System.assertEquals('eightYearsTo10Years', result5, 'Periodo 2920 debería mapear a eightYearsTo10Years');
        
        // Test para periodo no reconocido
        String result6 = DMT_TreasuryReportController.getPeriodField(9999);
        System.assertEquals(null, result6, 'Periodo no reconocido debería retornar null');
        Test.stopTest();
    }
    
    @IsTest
    static void testEmptyDataScenario() {
        // Eliminar datos existentes para probar escenario vacío
        delete [SELECT Id FROM DMT_Consolidated_Line__c];
        delete [SELECT Id FROM DMT_Line__c];
        delete [SELECT Id FROM Account];
        delete [SELECT Id FROM DMT_Taxonomy_values__c];
        
        Test.startTest();
        List<DMT_TreasuryReportController.GroupWrapper> result = DMT_TreasuryReportController.getDMTData();
        Test.stopTest();
        
        // Verificar que no hay excepción y retorna lista vacía
        System.assertNotEquals(null, result, 'El resultado no debería ser nulo incluso con datos vacíos');
        System.assertEquals(true, result.isEmpty(), 'Debería retornar lista vacía cuando no hay datos');
    }
    
    @IsTest
    static void testWrapperClasses() {
        // Test para verificar que las clases wrapper se pueden instanciar correctamente
        Test.startTest();
        
        // GroupWrapper
        DMT_TreasuryReportController.GroupWrapper groupWrapper = new DMT_TreasuryReportController.GroupWrapper();
        groupWrapper.groupCode = 'Test Group';
        groupWrapper.clients = new List<DMT_TreasuryReportController.ClientWrapper>();
        groupWrapper.totalRows = 1;
        
        // ClientWrapper
        DMT_TreasuryReportController.ClientWrapper clientWrapper = new DMT_TreasuryReportController.ClientWrapper();
        clientWrapper.accountName = 'Test Client';
        clientWrapper.sector = 'Test Sector';
        clientWrapper.customerId = 'TEST001';
        clientWrapper.fiscalId = 'FISC001';
        clientWrapper.rating = 'AA';
        clientWrapper.lines = new List<DMT_TreasuryReportController.LineWrapper>();
        clientWrapper.totalRows = 1;
        
        // LineWrapper
        DMT_TreasuryReportController.LineWrapper lineWrapper = new DMT_TreasuryReportController.LineWrapper();
        lineWrapper.lineId = 'LINE001';
        lineWrapper.dmtLineId = '001xx000001AAAAA';
        lineWrapper.currencyIsoCode = 'USD';
        lineWrapper.bookingGeography = 'CO';
        lineWrapper.startDate = Date.today();
        lineWrapper.endDate = Date.today().addDays(365);
        lineWrapper.status = 'Active';
        lineWrapper.risks = new List<DMT_TreasuryReportController.RiskWrapper>();
        lineWrapper.totalRows = 1;
        
        // RiskWrapper
        DMT_TreasuryReportController.RiskWrapper riskWrapper = new DMT_TreasuryReportController.RiskWrapper();
        riskWrapper.lastLevelId = '100100';
        riskWrapper.typeOfRisk = 'Market Risk';
        riskWrapper.product = 'FX Forward';
        riskWrapper.naToNa = '100000';
        riskWrapper.zeroDaysTo3Years = '200000';
        riskWrapper.threeYearsTo5Years = '300000';
        riskWrapper.fiveYearsTo8Years = '400000';
        riskWrapper.eightYearsTo10Years = '500000';
        
        Test.stopTest();
        
        // Verificar que los objetos se crearon correctamente
        System.assertEquals('Test Group', groupWrapper.groupCode);
        System.assertEquals('Test Client', clientWrapper.accountName);
        System.assertEquals('LINE001', lineWrapper.lineId);
        System.assertEquals('Market Risk', riskWrapper.typeOfRisk);
    }
}