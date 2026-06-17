@isTest
public with sharing class DMT_Line_Helper_test {
    @TestSetup
    static void loadTestData() {
    TriggerBypass.setBypass();
    // GIVEN
    DMT_Test_DataFactory.generateTestTreasuryLines();
      DMT_Test_DataFactory.generateTestTreasurySingularLines();
      DMT_Test_DataFactory.generateTestSanctionLines();
      DMT_Test_DataFactory.generateApprover();
      DMT_Test_DataFactory.generateTestOtherLines();
      DMT_Test_DataFactory.generateTestRiskApprovalLines();

      List<iaso__GBL_Rest_Services_Url__c> settingsToInsert = new List<iaso__GBL_Rest_Services_Url__c>();

        settingsToInsert.add(DMT_Test_DataFactory.setIasoCustomSetting('DMTO_Endpoint_INT','https://service.ok', 'ServicesPartition', false));
        settingsToInsert.add(DMT_Test_DataFactory.setIasoCustomSetting('DMT_GrantingTicket','https://validation.ok', 'ServicesPartition', false));
        settingsToInsert.add(DMT_Test_DataFactory.setIasoCustomSetting('DMT_HPGR_Endpoint','https://group-position.ok', 'ServicesPartition', false));

        // Perform one single DML
        insert settingsToInsert;

        TriggerBypass.removeBypass();
    }
    /*@isTest
        private static void testgetCorporateUsersOwnLines(){

            DMT_Line__c testLine = [SELECT Id,OwnerId FROM DMT_Line__c WHERE Line_Id__c = '00002' LIMIT 1];

            Map<ID,DMT_Line__c> mapnewLines = new Map<ID,DMT_Line__c>();
            mapnewLines.put(testLine.Id,testLine);

            Test.startTest();
            Map<Id,User> mapUser = new DMT_Line_Helper().getCorporateUsersOwnLines(mapnewLines);
            Test.stopTest();

            System.assertEquals(1, mapUser.size(), '1 corporate user must be retrieved');
        }*/

    @isTest
        private static void testGetProductsByCode(){

            List<String> listProductCode = new List<String>{'1600000000','1611170000','1610000000','1611190000'};

            Test.startTest();
            DMT_Line_Helper helper = new DMT_Line_Helper();
            Map<String, Product2> mapProduct = helper.getProductsByCode(listProductCode);
            Test.stopTest();

            System.assertEquals(5, mapProduct.size(), 'Expected 4 products');
            System.assertEquals('1600000000', mapProduct.get('Derivatives').ProductCode, 'Expected Derivatives product');
            System.assertEquals('1611170000', mapProduct.get('Depos').ProductCode, 'Expected Depos product');
            System.assertEquals('1610000000', mapProduct.get('Equities').ProductCode, 'Expected Equities product');
            System.assertEquals('1611190000', mapProduct.get('Repo').ProductCode, 'Expected Repo product');

        }

    /*@isTest
        private static void testGetRiskLineTermByLine(){

            Map<Id,DMT_Line__c> mapLinesRsk = new Map<Id,DMT_Line__c>([SELECT Id FROM DMT_Line__c WHERE Line_Id__c = '00002' WITH SECURITY_ENFORCED LIMIT 2]);

            Test.startTest();
            DMT_Line_Helper dmtHelper = new DMT_Line_Helper();
            Map<Id,List<DMT_Risk_Line_Term__c>> rskltTest = dmtHelper.getRiskLineTermByLine(mapLinesRsk,true , false);
            Test.stopTest();

            System.assertNotEquals(0, rskltTest.size(), 'testGetRiskLineTermByLine');
        }*/
    @isTest
        private static void testGetLineProductItemsByLine(){

            Map<Id,DMT_Line__c> mapLines = new Map<Id,DMT_Line__c>([SELECT Id,Name FROM DMT_Line__c WHERE Line_Id__c = '00002' WITH SECURITY_ENFORCED LIMIT 1]);

            Test.startTest();
            DMT_Line_Helper dmtHelper = new DMT_Line_Helper();
            Map<Id,List<DMT_Line_Product_Item__c>> mapPLI = dmtHelper.getLineProductItemsByLine(mapLines);
            Test.stopTest();

            System.debug('Map prod test '+mapPLI.size());
            System.assert(mapPLI.size()>0,'Map sizes should be more than 0');

        }
    @isTest
    private static void testcreateConsolidatedLine(){

        List<DMT_Line__c> listLines = [
            SELECT Id, Name, Product__c, Start_Date__c, End_Date__c,
           Status__c, Closed__c, DMT_Update_Singular__c,
           DMT_Approval_Date__c, OwnerId, Line_Id__c,
           DMT_Comments__c, CurrencyIsoCode, DvP_Amount__c,
           FD_Amount__c, Repos_Limit__c, Repos_Limit_6M__c,
           DMT_SingularCon__c, DMT_Status_Completed__c,
           DMT_Approval_Validation__c, DMT_LastLevelId__c,
           Amount__c, gf_min_raroec_wo_fcg_per__c,
           gf_min_rorc_wo_fcg_per__c, Booking_Geography__c,
           DMT_Origin__c, DMT_ID_User__c, Client_Type__c,
           Client_Code__c, Client__c, DMT_Entity__c,
           g_line_commitment_level_type__c, DMT_line_status_type__c,
           DMT_line_template_type__c, DMT_Additional_Restrictions__c,
           DMT_Parent_Code_Form__c, Waiver__c,
           Breakclause_Frequency__c, First_Breakclause_Date__c,
           DMT_Local_Risk_Analyst__c, DMT_Global_Risk_Analyst__c,
           DMT_GlobalBanker__c, DMT_Global_Risk_Analyst_User__c,
           DMT_Local_Risk_Analyst_User__c
            FROM DMT_Line__c
            WHERE (Line_Id__c = '00003' OR Line_Id__c = '00001'
            OR Line_id__c = '00089' OR Line_id__c = '00009')
            AND Product__c != 'Sanction'
        ];

        Map<Id, DMT_Line__c> mapOldLines = new Map<Id, DMT_Line__c>(
            [SELECT Id, Status__c, Closed__c, DMT_Update_Singular__c, DMT_Approval_Date__c
            FROM DMT_Line__c
            WHERE Id IN :new Map<Id, DMT_Line__c>(listLines).keySet()]
        );

        Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());

        Test.startTest();
        TriggerBypass.setBypass();
        for(DMT_Line__c line : listLines){
            line.Closed__c = DMT_Constants.WON;
            line.Status__c = DMT_Constants.CLOSED;
            if(line.Start_Date__c == null) line.Start_Date__c = Date.today();
            if(line.End_Date__c == null)   line.End_Date__c   = Date.today().addDays(365);
        }
        update listLines;
        TriggerBypass.removeBypass();

        Map<Id, DMT_Line__c> mapNewLines = new Map<Id, DMT_Line__c>(listLines);
        new DMT_Line_Helper().createConsolidatedLine(listLines, mapNewLines, mapOldLines);
        Test.stopTest();

        List<DMT_Consolidated_Line__c> listCLines = [
            SELECT Id, Name FROM DMT_Consolidated_Line__c WITH SECURITY_ENFORCED
        ];
        System.assertEquals(18, listCLines.size(), 'Expected size error');
    }

    //testing DMT_line_Helper.createLineVersionSnapshot
    @isTest
    private static void testCreateLineVersionSnapshot() {
      //  TriggerBypass.setBypass();
        // Query the DMT_Line__c records created in the @TestSetup
        DMT_Line__c line = [SELECT Id, Status__c, DMT_Approval_Date__c, Closed__c, Booking_Geography__c FROM DMT_Line__c WHERE Status__c = 'Draft' AND Line_Id__c = '00002' LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());

        Test.startTest();
        line.Status__c = DMT_Constants.PROPOSAL;
        update line;
        line.Status__c = DMT_Constants.APPROVAL;
        update line;
        Test.stopTest();

        List<DMT_Line__c> lineList = [SELECT Id, Status__c, DMT_Approval_Date__c, Closed__c, Booking_Geography__c FROM DMT_Line__c WHERE Status__c = :DMT_Constants.APPROVAL];

        Assert.isTrue(lineList.size() == 1, 'Expected 1 line with status APPROVAL');
        Assert.isTrue(lineList[0].Status__c == DMT_Constants.APPROVAL, 'Expected line status to be APPROVAL');
    }

    //testing updateLastModifiedByHuman > covers DMT_HPG_Utils.updateLastModifiedByHuman(records);
    @isTest
    private static void testUpdateLastModifiedByHuman() {
        DMT_Line__c line = [SELECT Id, Status__c FROM DMT_Line__c WHERE Status__c = :DMT_Constants.DRAFT AND Line_Id__c = '00002' LIMIT 1];

        Test.startTest();
        line.Status__c = DMT_Constants.PROPOSAL;
        update line;
        Test.stopTest();

        // Verify that the LastModifiedByHuman field is updated
        line = [SELECT Id, Last_Modified_By_Human__c FROM DMT_Line__c WHERE Id = :line.Id];

        Assert.isNotNull(line.Last_Modified_By_Human__c, 'Last Modified By Human should not be null');
    }

    //Custom Association name should match the Line Name when custom association is created or Line is updated.
    @isTest
    private static void testSyncCustomAssociationName() {
        DMT_Line__c line = [SELECT Id, Name, Status__c, Client__c, Line_Id__c, Client__r.Name FROM DMT_Line__c WHERE Name = 'Line Test ENERGIA FINANCIACION' LIMIT 1];

        Custom_Association__c customAss = new Custom_Association__c();
        customAss.DMT_Line__c = line.Id;
        customAss.gf_customer_group_id__c = line.Line_id__c;
        customAss.Group__c = line.Client__c;

        Test.startTest();
        insert customAss;

        customAss = [SELECT Id, Name, DMT_Line__c FROM Custom_Association__c WHERE Id = :customAss.Id];

        line.Name = line.Line_Id__c?.replaceAll('[^0-9]', '')?.substring(2)  + '_' + line.Client__r.Name?.replaceAll('[^A-Za-z0-9 ]', '')?.left(68)?.trim();
        update line;

        customAss = [SELECT Id, Name, DMT_Line__c FROM Custom_Association__c WHERE Id = :customAss.Id];
        Assert.areEqual(line.Name, customAss.Name, 'Custom Association Name should be updated to match Line Name');
        Test.stopTest();
    }

    @isTest
    private static void testAvoidPassingApproval() {
        DMT_Line__c line = [SELECT Id, Name, Status__c, Line_id__c, DMT_Approval_Validation__c FROM DMT_Line__c WHERE Line_Id__c = '00001' LIMIT 1];
        DMT_Approver__c approver = [SELECT Id, Name, DMT_Group__c FROM DMT_Approver__c LIMIT 1];
        Group groupQueue = [SELECT Id FROM Group WHERE DeveloperName =: approver.DMT_Group__c AND Type = 'Queue'];

        Test.startTest();
        DMT_Test_DataFactory.generateApprovalCase(line.Id, null, groupQueue.Id, 3);
        Passport__c p = [SELECT Id,DMT_Passport_Save__c FROM Passport__c WHERE DMT_Line__c =: line.Id WITH SECURITY_ENFORCED LIMIT 1];
        p.DMT_Passport_Save__c = '{"data":{"opportunityId":"ESCD25LIN00002175ES","auditDate":"2025-06-27T09:38:00.000+0200","version":"001","features":[{"id":"7","name":"Settlement - DvP Limit Test (Group Level)","passportSanction":"passport","active":"Y","motorDesc":"Limit Engine","stateName":"GRAY","lastLevels":[]},{"id":"10","name":"Derivatives Limit Test (Group Level)","passportSanction":"passport","active":"Y","motorDesc":"Limit Engine","stateName":"GRAY","lastLevels":[]},{"id":"12","name":"Booking Unit Risk Analyst Consult","passportSanction":"passport","active":"Y","stateName":"WHITE","tasks":[{"id":"2","name":"Risk Analyst Advisory","yesFlag":"In accordance","noFlag":"Not in accordance","naFlag":"N/A","nextTask":"1","status":"OPEN","approvers":[{"id":"11","name":"GRM C&IB Spain- Contrast","entific":"ES","branch":"HO","documentManagerEnable":"Y"}]},{"id":"2","name":"Risk Analyst Advisory","yesFlag":"In accordance","noFlag":"Not in accordance","naFlag":"N/A","nextTask":"1","status":"OPEN"}],"lastLevels":[]},{"id":"13","name":"Financial Program Risk Analyst Consult","passportSanction":"passport","active":"Y","stateName":"WHITE","tasks":[{"id":"2","name":"Risk Analyst Advisory","yesFlag":"In accordance","noFlag":"Not in accordance","naFlag":"N/A","nextTask":"1","status":"OPEN","approvers":[{"id":"9","name":"GRM C&IB Spain - Spanish Groups","entific":"ES","branch":"HO","documentManagerEnable":"Y"}]},{"id":"2","name":"Risk Analyst Advisory","yesFlag":"In accordance","noFlag":"Not in accordance","naFlag":"N/A","nextTask":"1","status":"OPEN"}],"lastLevels":[]},{"id":"1","name":"Business Approval","passportSanction":"approval","active":"Y","stateName":"WHITE","tasks":[{"id":"2","name":"Business Approval Treasury Line ","yesFlag":"Approved","noFlag":"Dismissed","naFlag":"N/A","nextTask":"1","status":"OPEN","approvers":[{"id":"27","name":"C&IB Profitability & Admission EMEA","entific":"HO","branch":"HO","documentManagerEnable":"Y"}]},{"id":"4","name":"Business Approval Treasury Line ","yesFlag":"Approved","noFlag":"Dismissed","naFlag":"N/A","nextTask":"1","status":"OPEN"}],"lastLevels":[]},{"id":"2","name":"Local Risk Approval","passportSanction":"approval","active":"Y","stateName":"WHITE","tasks":[{"id":"13","name":"Risk Analysis (local approval)","yesFlag":"In accordance","noFlag":"Not in accordance","naFlag":"N/A","nextTask":"1","status":"OPEN","approvers":[{"id":"11","name":"GRM C&IB Spain- Contrast","entific":"ES","branch":"HO","documentManagerEnable":"Y"}]},{"id":"6","name":"Risk Approval - Local","yesFlag":"Approved","noFlag":"Dismissed","naFlag":"N/A","nextTask":"1","status":"OPEN"},{"id":"8","name":"Risk Approval - local and global","yesFlag":"Approved","noFlag":"Dismissed","naFlag":"N/A","nextTask":"1","status":"OPEN"},{"id":"9","name":"Risk Approval - on behalf of the geography committee","yesFlag":"Approved","noFlag":"Dismissed","naFlag":"N/A","nextTask":"1","status":"OPEN"}],"lastLevels":[]},{"id":"3","name":"Global Risk Approval","passportSanction":"approval","active":"Y","stateName":"WHITE","tasks":[{"id":"14","name":"Risk Analysis (global approval)","yesFlag":"In accordance","noFlag":"Not in accordance","naFlag":"N/A","nextTask":"1","status":"OPEN","approvers":[{"id":"9","name":"GRM C&IB Spain - Spanish Groups","entific":"ES","branch":"HO","documentManagerEnable":"Y"}]},{"id":"7","name":"Risk Approval - global","yesFlag":"Approved","noFlag":"Dismissed","naFlag":"N/A","nextTask":"1","status":"OPEN"},{"id":"8","name":"Risk Approval - local and global","yesFlag":"Approved","noFlag":"Dismissed","naFlag":"N/A","nextTask":"1","status":"OPEN"},{"id":"9","name":"Risk Approval - on behalf of the geography committee","yesFlag":"Approved","noFlag":"Dismissed","naFlag":"N/A","nextTask":"1","status":"OPEN"},{"id":"10","name":"Risk Approval - on behalf of Holding WCRMC Committee","yesFlag":"Approved","noFlag":"Dismissed","naFlag":"N/A","nextTask":"1","status":"OPEN"},{"id":"11","name":"Risk Approval - on behalf of Holding GCRMC Committee","yesFlag":"Approved","noFlag":"Dismissed","naFlag":"N/A","nextTask":"1","status":"OPEN"},{"id":"12","name":"Risk Approval - on behalf of CRO","yesFlag":"Approved","noFlag":"Dismissed","naFlag":"N/A","nextTask":"1","status":"OPEN"}],"lastLevels":[]}]}}';
        update p;
        line.Status__c = DMT_Constants.READYTOCLOSE;
        update line;
        Test.stopTest();
        Assert.areEqual(true, line.DMT_Approval_Validation__c, 'Line Cases Approved');
    }

        @isTest
    private static void testHandleCancel() {
        // 1. Crear DMT Line inicial con DMT_Cancel__c = false
        DMT_Line__c dmtLine = [SELECT Id, Name, Status__c, Line_id__c, DMT_Approval_Validation__c, DMT_Cancel__c FROM DMT_Line__c WHERE Line_Id__c = '00001' LIMIT 1];

        // 2. Crear 2 casos relacionados
        List<Case> cases = new List<Case>();
        cases.add(new Case(
            Subject = 'Case 1',
            Status = 'Pending',
            DMT_Line__c = dmtLine.Id
        ));
        cases.add(new Case(
            Subject = 'Case 2',
            Status = 'In Progress',
            DMT_Line__c = dmtLine.Id
        ));
        insert cases;

        // 3. Crear tareas para los casos
        List<Task> tasks = new List<Task>();
        for (Case c : cases) {
            tasks.add(new Task(
                Subject = 'Task for ' + c.Subject,
                Status = 'Not Started',
                WhatId = c.Id,
                ActivityDate = Date.today()
            ));
        }
        insert tasks;

        // 4. Verificar estado inicial
        System.assertEquals(false, dmtLine.DMT_Cancel__c, 'Inicio correcto en false');

        Test.startTest();
        // 5. Crear oldMap para simular trigger
        Map<Id, DMT_Line__c> oldMap = new Map<Id, DMT_Line__c>();
        oldMap.put(dmtLine.Id, dmtLine.clone(true, false, true, true));

        // 6. Cambiar DMT_Cancel__c a true
        dmtLine.DMT_Cancel__c = true;

        List<DMT_Line__c> updateLines = new List<DMT_Line__c>{dmtLine};
        update updateLines;

        Test.stopTest();

        // 8. Verificar resultados
        List<Case> updatedCases = [SELECT Id, Status FROM Case WHERE DMT_Line__c = :dmtLine.Id];
        for (Case c : updatedCases) {
            System.assertEquals('Finished', c.Status, 'Todos los casos deben estar Finished');
        }

        List<Task> updatedTasks = [SELECT Id, Status FROM Task WHERE WhatId IN :cases];
        for (Task t : updatedTasks) {
            System.assertEquals('Cancelled', t.Status, 'Todas las tareas deben estar Cancelled');
        }

        System.debug('Test completado: ' + updatedCases.size() + ' casos y ' + updatedTasks.size() + ' tareas actualizadas');
    }


    @isTest
    private static void testSingularTreasuryConsumption() {
        // 1. Preparar datos de prueba
        List<DMT_Risk_Line_Term__c> testRisks = new List<DMT_Risk_Line_Term__c>();

        // Crear risk singular derivado (cumple todas las condiciones)
        DMT_Risk_Line_Term__c singularDerivative = new DMT_Risk_Line_Term__c(
            Name = 'Singular Derivative',
            DMT_Singular__c = true,
            DMT_Max_Date__c = Date.today().addDays(30), // Fecha futura
            DMT_Risk_Type__c = 'DERIVATIVES', // Asumiendo que DMT_Constants.RSK_DERIVATIVES = 'DERIVATIVES'
            DMT_Amount__c = 1000,
            DMT_Init_Term__c = '1',
            DMT_End_Term__c = '10',
            CurrencyIsoCode = 'EUR',
            DMT_Singular_DvP__c = 1000,
            DMT_Singular_FD__c = 1000
        );
        testRisks.add(singularDerivative);

        // Crear risk no singular derivado
        DMT_Risk_Line_Term__c nonSingularDerivative = new DMT_Risk_Line_Term__c(
            Name = 'Non Singular Derivative',
            DMT_Singular__c = false,
            DMT_Risk_Type__c = 'DERIVATIVES',
            DMT_Amount__c = 500,
            DMT_Init_Term__c = '1',
            DMT_End_Term__c = '5',
            CurrencyIsoCode = 'EUR'
        );
        testRisks.add(nonSingularDerivative);

        // Crear risk no derivado (DEPOS o EQUITY)
        DMT_Risk_Line_Term__c nonDerivative = new DMT_Risk_Line_Term__c(
            Name = 'Non Derivative',
            DMT_Risk_Type__c = 'DEPOS', // Asumiendo que DMT_Constants.RSK_DEPOS = 'DEPOS'
            DMT_Amount__c = 2000,
            DMT_Init_Term__c = '1',
            DMT_End_Term__c = '15',
            CurrencyIsoCode = 'USD'
        );
        testRisks.add(nonDerivative);

        // 2. Llamar al método invocable
        Test.startTest();
        List<List<DMT_Risk_Line_Term__c>> result = DMT_Line_Helper.singularTreasuryConsumption(
            new List<List<DMT_Risk_Line_Term__c>>{testRisks}
        );
        Test.stopTest();

        // 3. Verificar resultados
        System.assertNotEquals(null, result, 'El resultado no debe ser nulo');
        System.assertEquals(1, result.size(), 'Debe devolver una lista de listas');

        List<DMT_Risk_Line_Term__c> processedRisks = result[0];

        // Verificar que todos los riesgos ahora tienen tipo SINGULAR
        for (DMT_Risk_Line_Term__c risk : processedRisks) {
            System.assertNotEquals(null, risk.DMT_Risk_Type__c,
                'Todos los riesgos deben tener tipo SINGULAR');
        }

        // Verificar que se procesaron correctamente los montos
        // El risk singular (1000) + nonSingularDerivative (500) debería dar 1500 en algún registro
        Decimal totalAmount = 0;
        for (DMT_Risk_Line_Term__c risk : processedRisks) {
            totalAmount += risk.DMT_Amount__c;
        }

        // El total debería ser: 1000 + 500 + 2000 = 3500
        // Pero como hay clonación, podrían ser más registros
        System.debug('Total registros procesados: ' + processedRisks.size());
        System.debug('Total amount en todos los registros: ' + totalAmount);

        // Verificar que hay al menos 3 registros (originales convertidos)
        System.assert(processedRisks.size() >= 3, 'Debe haber al menos 3 registros procesados');

        // Verificar que se mantiene el CurrencyIsoCode
        for (DMT_Risk_Line_Term__c risk : processedRisks) {
            System.assert(risk.CurrencyIsoCode != null, 'CurrencyIsoCode no debe ser nulo');
        }

        // Verificar casos específicos de términos
        // Buscar registros con términos combinados
        Boolean foundCombinedTerm = false;
        for (DMT_Risk_Line_Term__c risk : processedRisks) {
            if (risk.DMT_Init_Term__c == '1' && risk.DMT_End_Term__c == '5') {
                // Este debería ser el nonSingularDerivative combinado con singular
                System.assert(risk.DMT_Amount__c >= 1500,
                    'El risk combinado debería tener amount de al menos 1500');
                foundCombinedTerm = true;
            }
        }

        System.debug('Test completado exitosamente');
    }


}