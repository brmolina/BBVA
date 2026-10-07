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

            Assert.areEqual(1, mapUser.size(), '1 corporate user must be retrieved');
        }*/

    @isTest
        private static void testGetProductsByCode(){

            List<String> listProductCode = new List<String>{'1600000000','1611170000','1610000000','1611190000'};

            Test.startTest();
            DMT_Line_Helper helper = new DMT_Line_Helper();
            Map<String, Product2> mapProduct = helper.getProductsByCode(listProductCode);
            Test.stopTest();

            Assert.areEqual(5, mapProduct.size(), 'Expected 4 products');
            Assert.areEqual('1600000000', mapProduct.get('Derivatives').ProductCode, 'Expected Derivatives product');
            Assert.areEqual('1611170000', mapProduct.get('Depos').ProductCode, 'Expected Depos product');
            Assert.areEqual('1610000000', mapProduct.get('Equities').ProductCode, 'Expected Equities product');
            Assert.areEqual('1611190000', mapProduct.get('Repos').ProductCode, 'Expected Repo product');

        }

    /*@isTest
        private static void testGetRiskLineTermByLine(){

            Map<Id,DMT_Line__c> mapLinesRsk = new Map<Id,DMT_Line__c>([SELECT Id FROM DMT_Line__c WHERE Line_Id__c = '00002' WITH SECURITY_ENFORCED LIMIT 2]);

            Test.startTest();
            DMT_Line_Helper dmtHelper = new DMT_Line_Helper();
            Map<Id,List<DMT_Risk_Line_Term__c>> rskltTest = dmtHelper.getRiskLineTermByLine(mapLinesRsk,true , false);
            Test.stopTest();

            Assert.areNotEqual(0, rskltTest.size(), 'testGetRiskLineTermByLine');
        }*/
    @isTest
        private static void testGetLineProductItemsByLine(){

            Map<Id,DMT_Line__c> mapLines = new Map<Id,DMT_Line__c>([SELECT Id,Name FROM DMT_Line__c WHERE Line_Id__c = '00002' WITH SECURITY_ENFORCED LIMIT 1]);

            Test.startTest();
            DMT_Line_Helper dmtHelper = new DMT_Line_Helper();
            Map<Id,List<DMT_Line_Product_Item__c>> mapPLI = dmtHelper.getLineProductItemsByLine(mapLines);
            Test.stopTest();

            System.debug('Map prod test '+mapPLI.size());
            Assert.isTrue(mapPLI.size()>0,'Map sizes should be more than 0');

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
        Assert.areEqual(18, listCLines.size(), 'Expected size error');
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
        Assert.areEqual(false, dmtLine.DMT_Cancel__c, 'Inicio correcto en false');

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
            Assert.areEqual('Finished', c.Status, 'Todos los casos deben estar Finished');
        }

        List<Task> updatedTasks = [SELECT Id, Status FROM Task WHERE WhatId IN :cases];
        for (Task t : updatedTasks) {
            Assert.areEqual('Cancelled', t.Status, 'Todas las tareas deben estar Cancelled');
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
            CurrencyIsoCode = 'EUR'
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
        Assert.areNotEqual(null, result, 'El resultado no debe ser nulo');
        Assert.areEqual(1, result.size(), 'Debe devolver una lista de listas');

        List<DMT_Risk_Line_Term__c> processedRisks = result[0];

        // Verificar que todos los riesgos ahora tienen tipo SINGULAR
        for (DMT_Risk_Line_Term__c risk : processedRisks) {
            Assert.areNotEqual(null, risk.DMT_Risk_Type__c,
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
        Assert.isTrue(processedRisks.size() >= 3, 'Debe haber al menos 3 registros procesados');

        // Verificar que se mantiene el CurrencyIsoCode
        for (DMT_Risk_Line_Term__c risk : processedRisks) {
            Assert.isTrue(risk.CurrencyIsoCode != null, 'CurrencyIsoCode no debe ser nulo');
        }

        // Verificar casos específicos de términos
        // Buscar registros con términos combinados
        Boolean foundCombinedTerm = false;
        for (DMT_Risk_Line_Term__c risk : processedRisks) {
            if (risk.DMT_Init_Term__c == '1' && risk.DMT_End_Term__c == '5') {
                // Este debería ser el nonSingularDerivative combinado con singular
                Assert.isTrue(risk.DMT_Amount__c >= 1500,
                    'El risk combinado debería tener amount de al menos 1500');
                foundCombinedTerm = true;
            }
        }

        System.debug('Test completado exitosamente');
    }

    @isTest
    public static void testBlockReadyToCloseWithProspectInMultiholder() {
        Id prospectGroupRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect_Group').getRecordTypeId();
        Id prospectSubsidiaryRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect_Subsidiary').getRecordTypeId();
        Id customerRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();
        // Escenario 1: Account principal (Customer) - Debería pasar validación inicial
        Account mainAccount = new Account(
            Name = 'Main Client Account Line',
            g_customer_id__c = 'ES0000000000011',
            RecordTypeId = customerRtId
        );
        insert mainAccount;        
        // Escenario 2: Prospect_Subsidiary en multiholder - Este causará el bloqueo
        Account prospectSubsidiary = new Account(
            Name = 'Prospect Subsidiary in Multiholder Line',
            g_customer_id__c = 'ES0000000000012',
            DES_ID_Fiscal__c = 'x1234',
            RecordTypeId = prospectSubsidiaryRtId
        );
        insert prospectSubsidiary;        
        // Escenario 3: Account regular en multiholder - NO causará bloqueo
        Account regularAccount = new Account(
            Name = 'Regular Account in Multiholder Line',
            g_customer_id__c = 'ES0000000000013',
            RecordTypeId = customerRtId
        );
        insert regularAccount;        
        // Line 1: Con main account Customer y Prospect_Subsidiary en multiholder - SE BLOQUEA
        DMT_Line__c line1 = new DMT_Line__c(
            Name = 'Test Line 1 - Should Block',
            Client__c = mainAccount.Id,
            Status__c = DMT_Constants.READYTOCLOSE
        );        
        // Line 2: Con main account Customer y regular account en multiholder - NO SE BLOQUEA
        DMT_Line__c line2 = new DMT_Line__c(
            Name = 'Test Line 2 - Should Pass',
            Client__c = mainAccount.Id,
            Status__c = DMT_Constants.READYTOCLOSE
        );        
        // Line 3: Sin multiholder - NO SE BLOQUEA (cubre early return cuando customAssociations está vacío)
        DMT_Line__c line3 = new DMT_Line__c(
            Name = 'Test Line 3 - No Multiholder',
            Client__c = mainAccount.Id,
            Status__c = DMT_Constants.READYTOCLOSE
        );        
        insert new List<DMT_Line__c>{line1, line2, line3};        
        // Crear Custom_Association__c para line1 y line2
        Custom_Association__c ca1 = new Custom_Association__c(
            DMT_Line__c = line1.Id,
            gf_customer_group_id__c = 'ESCD26OPP00002938ES',
            g_customer_id__c = 'ES0000000000011'
        );        
        Custom_Association__c ca2 = new Custom_Association__c(
            DMT_Line__c = line2.Id,
            gf_customer_group_id__c = 'ESCD26OPP00002788ES',
            g_customer_id__c = 'ES0000000000011'
        );        
        insert new List<Custom_Association__c>{ca1, ca2};        
        // Crear Custom_Association_Client__c apuntando a Prospect_Subsidiary para line1
        Custom_Association_Client__c cac1 = new Custom_Association_Client__c(
            Custom_Association__c = ca1.Id,
            Alpha_Code_Client__c = prospectSubsidiary.g_customer_id__c
        );        
        // Crear Custom_Association_Client__c apuntando a regular account para line2
        Custom_Association_Client__c cac2 = new Custom_Association_Client__c(
            Custom_Association__c = ca2.Id,
            Alpha_Code_Client__c = regularAccount.g_customer_id__c
        );        
        insert new List<Custom_Association_Client__c>{cac1, cac2};        
        Test.startTest();        
        // Intentar cambiar line1 a Closed Won - DEBE BLOQUEARSE
        line1.Status__c = DMT_Constants.CLOSED;
        line1.Closed__c = DMT_Constants.WON;
        Boolean line1Blocked = false;
        String line1ErrorMessage = '';
        try {
            update line1;
        } catch (DmlException e) {
            line1Blocked = true;
            line1ErrorMessage = e.getMessage();
        }        
        // Intentar cambiar line2 a Closed Won - NO DEBE BLOQUEARSE
        line2.Status__c = DMT_Constants.CLOSED;
        line2.Closed__c = DMT_Constants.WON;
        Boolean line2Blocked = false;
        try {
            update line2;
        } catch (DmlException e) {
            line2Blocked = true;
        }        
        // Intentar cambiar line3 a Closed Won - NO DEBE BLOQUEARSE (no tiene multiholder)
        line3.Status__c = DMT_Constants.CLOSED;
        line3.Closed__c = DMT_Constants.WON;
        Boolean line3Blocked = false;
        try {
            update line3;
        } catch (DmlException e) {
            line3Blocked = true;
        }        
        Test.stopTest();        
        Assert.isTrue(line1Blocked, 'Line1 should be blocked - has Prospect_Subsidiary in multiholder');
        Assert.isFalse(line2Blocked, 'Line2 should NOT be blocked - has regular account in multiholder');
        Assert.isFalse(line3Blocked, 'Line3 should NOT be blocked - has no multiholder');
    }

    @isTest
    public static void testCheckProspectInLine() {
        Id prospectGroupRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect_Group').getRecordTypeId();
        Id prospectSubsidiaryRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect_Subsidiary').getRecordTypeId();
        Id customerRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();
        Id sanctionRtId = Schema.SObjectType.DMT_Line__c.getRecordTypeInfosByDeveloperName().get('Sanction')?.getRecordTypeId();
        Id dmtOppRtId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('DMT_Opportunity').getRecordTypeId();
        
        // Crear Prospect Group
        Account prospectGroup = new Account(
            Name = 'Test Prospect Group Badge',
            g_customer_id__c = 'ES0000000000021',
            RecordTypeId = prospectGroupRtId
        );
        insert prospectGroup;
        
        // Crear Prospect Subsidiary
        Account prospectSub = new Account(
            Name = 'Test Prospect Subsidiary Badge',
            g_customer_id__c = 'ES0000000000022',
            DES_ID_Fiscal__c = 'x5678',
            RecordTypeId = prospectSubsidiaryRtId
        );
        insert prospectSub;
        
        // Crear Account normal
        Account normalAccount = new Account(
            Name = 'Normal Account Badge',
            g_customer_id__c = 'ES0000000000023',
            RecordTypeId = customerRtId
        );
        insert normalAccount;
        
        // Crear Opportunity con Prospect en multiholder
        Opportunity oppWithProspect = new Opportunity(
            Name = 'Test Opp With Prospect',
            AccountId = normalAccount.Id,
            RecordTypeId = dmtOppRtId,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert oppWithProspect;
        
        // Crear DMT_Opportunity_Client__c apuntando a Prospect
        DMT_Opportunity_Client__c oppClient = new DMT_Opportunity_Client__c(
            DMT_MDE_Opportunity__c = oppWithProspect.Id,
            Alpha_Code_Client__c = prospectSub.g_customer_id__c
        );
        insert oppClient;
        
        // Line 1: Con Prospect Group como cliente directo
        DMT_Line__c lineProspectGroup = new DMT_Line__c(
            Name = 'Line Prospect Group Badge',
            Client__c = prospectGroup.Id,
            Status__c = 'Draft'
        );
        
        // Line 2: Con Prospect Subsidiary como cliente directo
        DMT_Line__c lineProspectSub = new DMT_Line__c(
            Name = 'Line Prospect Sub Badge',
            Client__c = prospectSub.Id,
            Status__c = 'Draft'
        );
        
        // Line 3: Con cuenta normal - sin Prospect
        DMT_Line__c lineNormal = new DMT_Line__c(
            Name = 'Line Normal Badge',
            Client__c = normalAccount.Id,
            Status__c = 'Draft'
        );
        
        // Line 4: Sanction vinculada a Opportunity con Prospect
        DMT_Line__c sanctionWithProspect = new DMT_Line__c(
            Name = 'Sanction With Prospect Badge',
            RecordTypeId = sanctionRtId,
            DMT_Opportunity__c = oppWithProspect.Id,
            Status__c = 'Draft'
        );
        
        insert new List<DMT_Line__c>{lineProspectGroup, lineProspectSub, lineNormal, sanctionWithProspect};
        
        Test.startTest();
        
        // Test 1: Line con Prospect Group
        List<Boolean> result1 = DMT_Line_Helper.checkProspectInLine(new List<Id>{lineProspectGroup.Id});
        Assert.areEqual(1, result1.size(), 'Should return one result');
        Assert.areEqual(true, result1[0], 'Should return true for Prospect Group');
        
        // Test 2: Line con Prospect Subsidiary
        List<Boolean> result2 = DMT_Line_Helper.checkProspectInLine(new List<Id>{lineProspectSub.Id});
        Assert.areEqual(1, result2.size(), 'Should return one result');
        Assert.areEqual(true, result2[0], 'Should return true for Prospect Subsidiary');
        
        // Test 3: Line sin Prospect
        List<Boolean> result3 = DMT_Line_Helper.checkProspectInLine(new List<Id>{lineNormal.Id});
        Assert.areEqual(1, result3.size(), 'Should return one result');
        Assert.areEqual(false, result3[0], 'Should return false for normal account');
                
        // Test 4: Lista vacía
        List<Boolean> result5 = DMT_Line_Helper.checkProspectInLine(new List<Id>());
        Assert.areEqual(1, result5.size(), 'Should return one result');
        Assert.areEqual(false, result5[0], 'Should return false for empty list');
        
        // Test 5: Lista null
        List<Boolean> result6 = DMT_Line_Helper.checkProspectInLine(null);
        Assert.areEqual(1, result6.size(), 'Should return one result');
        Assert.areEqual(false, result6[0], 'Should return false for null list');
        
        Test.stopTest();
    }
    // Minimal, valid DMT_Line__c insert (Draft status) so enqueueRecalculateApprovals' internal
    // SOQL query has a real Client__r relationship to resolve. The RTC/CW transition itself is
    // simulated purely in-memory (never via a second DML) to avoid DMT_Line__c's approval-workflow
    // validation rules, which are out of scope for this unit-level test of the new method.
    private static DMT_Line__c insertRecalculateApprovalsTestLine(Id recordTypeId, String lineIdCode, Id clientId) {
        DMT_Line__c line = new DMT_Line__c(
            Name = 'Recalculate Approvals Test Line',
            Status__c = DMT_Constants.DRAFT,
            Client__c = clientId,
            Line_Id__c = lineIdCode,
            DMT_Origin__c = 'AMIWEB',
            g_line_status_type__c = 'AP',
            Booking_Geography__c = 'ES',
            DMT_Client_Entific__c = 'ES',
            RecordTypeId = recordTypeId,
            Client_Code__c = 'ES0000000000099'
        );
        insert line;
        return line;
    }

    @isTest
    private static void testEnqueueRecalculateApprovals_TreasuryLineReadyToClose_EnqueuesWithoutOpportunityId() {
        Id treasurySettlementRTId = Schema.SObjectType.DMT_Line__c.getRecordTypeInfosByDeveloperName().get('TreasurySettlement').getRecordTypeId();

        Account acc = new Account(Name = 'RTC Group Account', DES_Group_Code__c = 'GRP-RTC-001');
        insert acc;

        TriggerBypass.setBypass();
        DMT_Line__c line = insertRecalculateApprovalsTestLine(treasurySettlementRTId, 'RTC-TL-001', acc.Id);
        TriggerBypass.removeBypass();

        DMT_Line__c newLine = new DMT_Line__c(Id = line.Id, RecordTypeId = treasurySettlementRTId, Status__c = DMT_Constants.READYTOCLOSE, Closed__c = null, Line_Id__c = 'RTC-TL-001', DMT_ID_User__c = 'U001');
        DMT_Line__c oldLine = new DMT_Line__c(Id = line.Id, RecordTypeId = treasurySettlementRTId, Status__c = DMT_Constants.APPROVAL, Closed__c = null);

        Test.startTest();
        new DMT_Line_Helper().enqueueRecalculateApprovals(new List<DMT_Line__c>{newLine}, new Map<Id, DMT_Line__c>{line.Id => oldLine});
        Test.stopTest();

        Assert.areEqual(1, DMT_AsyncOrchestrator.payloadBuffer.size(), 'Expected exactly one enqueued payload');
        Assert.isTrue(DMT_AsyncOrchestrator.payloadBuffer[0] instanceof DMT_ConsumptionReassignPayload, 'Expected a DMT_ConsumptionReassignPayload');
        DMT_ConsumptionReassignPayload payload = (DMT_ConsumptionReassignPayload) DMT_AsyncOrchestrator.payloadBuffer[0];
        Assert.areEqual('GRP-RTC-001', payload.inputMap.get('groupId'), 'groupId should resolve from the client account');
        Assert.isFalse(payload.inputMap.containsKey('opportunityId'), 'opportunityId is never valid for Treasury/OtherProducts lines - they have no related Opportunity');
    }

    @isTest
    private static void testEnqueueRecalculateApprovals_OtherProductsLineClosedWon_EnqueuesWithoutOpportunityId() {
        Id otherProductsRTId = Schema.SObjectType.DMT_Line__c.getRecordTypeInfosByDeveloperName().get('OtherProducts').getRecordTypeId();

        Account acc = new Account(Name = 'CW Group Account', DES_Group_Code__c = 'GRP-CW-001');
        insert acc;

        TriggerBypass.setBypass();
        DMT_Line__c line = insertRecalculateApprovalsTestLine(otherProductsRTId, 'CW-OL-001', acc.Id);
        TriggerBypass.removeBypass();

        DMT_Line__c newLine = new DMT_Line__c(Id = line.Id, RecordTypeId = otherProductsRTId, Status__c = DMT_Constants.CLOSED, Closed__c = DMT_Constants.WON, Line_Id__c = 'CW-OL-001', DMT_ID_User__c = 'U002');
        DMT_Line__c oldLine = new DMT_Line__c(Id = line.Id, RecordTypeId = otherProductsRTId, Status__c = DMT_Constants.APPROVAL, Closed__c = null);

        Test.startTest();
        new DMT_Line_Helper().enqueueRecalculateApprovals(new List<DMT_Line__c>{newLine}, new Map<Id, DMT_Line__c>{line.Id => oldLine});
        Test.stopTest();

        Assert.areEqual(1, DMT_AsyncOrchestrator.payloadBuffer.size(), 'Expected exactly one enqueued payload');
        DMT_ConsumptionReassignPayload payload = (DMT_ConsumptionReassignPayload) DMT_AsyncOrchestrator.payloadBuffer[0];
        Assert.areEqual('GRP-CW-001', payload.inputMap.get('groupId'), 'groupId should resolve from the client account');
        Assert.isFalse(payload.inputMap.containsKey('opportunityId'), 'opportunityId should NOT be included on Closed Won');
    }

    @isTest
    private static void testEnqueueRecalculateApprovals_SanctionRecordType_DoesNotEnqueue() {
        Id sanctionRTId = Schema.SObjectType.DMT_Line__c.getRecordTypeInfosByDeveloperName().get('Sanction').getRecordTypeId();

        Account acc = new Account(Name = 'Sanction Group Account', DES_Group_Code__c = 'GRP-SANC-001');
        insert acc;

        TriggerBypass.setBypass();
        DMT_Line__c line = insertRecalculateApprovalsTestLine(sanctionRTId, 'SANC-001', acc.Id);
        TriggerBypass.removeBypass();

        DMT_Line__c newLine = new DMT_Line__c(Id = line.Id, RecordTypeId = sanctionRTId, Status__c = DMT_Constants.READYTOCLOSE, Closed__c = null, Line_Id__c = 'SANC-001');
        DMT_Line__c oldLine = new DMT_Line__c(Id = line.Id, RecordTypeId = sanctionRTId, Status__c = DMT_Constants.APPROVAL, Closed__c = null);

        Test.startTest();
        new DMT_Line_Helper().enqueueRecalculateApprovals(new List<DMT_Line__c>{newLine}, new Map<Id, DMT_Line__c>{line.Id => oldLine});
        Test.stopTest();

        Assert.areEqual(0, DMT_AsyncOrchestrator.payloadBuffer.size(), 'Sanction lines must stay on their existing dedicated pipeline, not this new one');
    }

    @isTest
    private static void testEnqueueRecalculateApprovals_NoQualifyingTransition_DoesNotEnqueue() {
        Id treasurySettlementRTId = Schema.SObjectType.DMT_Line__c.getRecordTypeInfosByDeveloperName().get('TreasurySettlement').getRecordTypeId();

        Account acc = new Account(Name = 'No Transition Account', DES_Group_Code__c = 'GRP-NOOP-001');
        insert acc;

        TriggerBypass.setBypass();
        DMT_Line__c line = insertRecalculateApprovalsTestLine(treasurySettlementRTId, 'NOOP-TL-001', acc.Id);
        TriggerBypass.removeBypass();

        DMT_Line__c newLine = new DMT_Line__c(Id = line.Id, RecordTypeId = treasurySettlementRTId, Status__c = DMT_Constants.PROPOSAL, Closed__c = null, Line_Id__c = 'NOOP-TL-001');
        DMT_Line__c oldLine = new DMT_Line__c(Id = line.Id, RecordTypeId = treasurySettlementRTId, Status__c = DMT_Constants.DRAFT, Closed__c = null);

        Test.startTest();
        new DMT_Line_Helper().enqueueRecalculateApprovals(new List<DMT_Line__c>{newLine}, new Map<Id, DMT_Line__c>{line.Id => oldLine});
        Test.stopTest();

        Assert.areEqual(0, DMT_AsyncOrchestrator.payloadBuffer.size(), 'A non RTC/CW status change must not enqueue a callout');
    }

    @isTest
    private static void testEnqueueRecalculateApprovals_BlankGroupId_SkipsNonFatally() {
        Id treasurySettlementRTId = Schema.SObjectType.DMT_Line__c.getRecordTypeInfosByDeveloperName().get('TreasurySettlement').getRecordTypeId();

        // No DES_Group_Code__c set on purpose, so groupId resolution comes back blank.
        Account acc = new Account(Name = 'Blank Group Code Account');
        insert acc;

        TriggerBypass.setBypass();
        DMT_Line__c line = insertRecalculateApprovalsTestLine(treasurySettlementRTId, 'BLANK-TL-001', acc.Id);
        TriggerBypass.removeBypass();

        DMT_Line__c newLine = new DMT_Line__c(Id = line.Id, RecordTypeId = treasurySettlementRTId, Status__c = DMT_Constants.READYTOCLOSE, Closed__c = null, Line_Id__c = 'BLANK-TL-001');
        DMT_Line__c oldLine = new DMT_Line__c(Id = line.Id, RecordTypeId = treasurySettlementRTId, Status__c = DMT_Constants.APPROVAL, Closed__c = null);

        Test.startTest();
        new DMT_Line_Helper().enqueueRecalculateApprovals(new List<DMT_Line__c>{newLine}, new Map<Id, DMT_Line__c>{line.Id => oldLine});
        Test.stopTest();

        for (DMT_AsyncPayload payload : DMT_AsyncOrchestrator.payloadBuffer) {
            Assert.isFalse(payload instanceof DMT_ConsumptionReassignPayload, 'A line with an unresolvable groupId must not enqueue a callout');
        }
    }
    @IsTest
    private static void testCloseFatherExpiresPreviousGroupTreasuryLine() {
        List<DMT_Line__c> lines = [
            SELECT Id, Line_Id__c, Product__c, DMT_line_template_type__c,
                Client_Type__c, Client_Code__c, Status__c, Closed__c,
                Start_Date__c, End_Date__c, DMT_Parent_Line__c
            FROM DMT_Line__c
            WHERE Line_Id__c IN ('00001', '00002')
        ];

        Map<String, DMT_Line__c> linesByCode = new Map<String, DMT_Line__c>();
        for (DMT_Line__c line : lines) {
            linesByCode.put(line.Line_Id__c, line);
        }

        DMT_Line__c previousLine = linesByCode.get('00001');
        DMT_Line__c triggeringLine = linesByCode.get('00002');

        Assert.areNotEqual(null, previousLine, 'Previous Treasury line is required');
        Assert.areNotEqual(null, triggeringLine, 'Triggering Treasury line is required');

        Date triggeringStartDate = Date.newInstance(2024, 12, 1);

        TriggerBypass.setBypass();
        try {
            previousLine.Client_Code__c = 'TEST-GROUP-4327';
            previousLine.Status__c = DMT_Constants.CLOSED;
            previousLine.Closed__c = DMT_Constants.WON;
            previousLine.Start_Date__c = Date.newInstance(2024, 1, 1);
            previousLine.End_Date__c = Date.newInstance(2024, 12, 31);
            previousLine.DMT_Parent_Line__c = null;
            update previousLine;

            DMT_Line__c oldTriggeringLine =
                triggeringLine.clone(true, true, false, false);

            triggeringLine.Client_Code__c = 'TEST-GROUP-4327';
            triggeringLine.Status__c = DMT_Constants.CLOSED;
            triggeringLine.Closed__c = DMT_Constants.WON;
            triggeringLine.Start_Date__c = triggeringStartDate;
            triggeringLine.End_Date__c = Date.newInstance(2025, 12, 31);
            triggeringLine.DMT_Parent_Line__c = null;

            Test.startTest();
            new DMT_Line_Helper().closeFather(
                new List<DMT_Line__c>{ triggeringLine },
                new Map<Id, DMT_Line__c>{
                    triggeringLine.Id => oldTriggeringLine
                }
            );
            Test.stopTest();
        } finally {
            TriggerBypass.removeBypass();
        }

        previousLine = [
            SELECT Start_Date__c, End_Date__c
            FROM DMT_Line__c
            WHERE Id = :previousLine.Id
        ];

        Assert.areEqual(
            triggeringStartDate.addDays(-1),
            previousLine.End_Date__c,
            'The previous active Treasury line must expire one day before the new line starts'
        );
    }

    // CIBGLOBALD-3779 - covers syncApprovalTermAndEndDate(): Term set with End Date blank
    // computes End Date from Start Date + Term, for both the Risk Approval and Business Approval
    // field trios.
    @isTest
    private static void testSyncApprovalTermAndEndDate_TermComputesEndDate() {
        DMT_Line__c line = [SELECT Id FROM DMT_Line__c WHERE Line_Id__c = '00003' LIMIT 1];
        line.Start_Date__c = Date.newInstance(2026, 1, 15);
        line.End_Date__c = null;
        line.DMT_Risk_Approval_Term__c = 6;

        Test.startTest();
        new DMT_Line_Helper().syncApprovalTermAndEndDate(new List<DMT_Line__c>{ line }, null);
        Test.stopTest();

        Assert.areEqual(
            Date.newInstance(2026, 7, 15),
            line.End_Date__c,
            'End_Date__c should be Start_Date__c + the 6-month Risk Approval Term'
        );
    }

    // CIBGLOBALD-3779 - covers syncApprovalTermAndEndDate(): both dates set with Term blank
    // computes Term from the date pair.
    @isTest
    private static void testSyncApprovalTermAndEndDate_DatesComputeTerm() {
        DMT_Line__c line = [SELECT Id FROM DMT_Line__c WHERE Line_Id__c = '00003' LIMIT 1];
        line.Start_Date__c = Date.newInstance(2026, 1, 15);
        line.End_Date__c = Date.newInstance(2026, 4, 15);
        line.DMT_Risk_Approval_Term__c = null;

        Test.startTest();
        new DMT_Line_Helper().syncApprovalTermAndEndDate(new List<DMT_Line__c>{ line }, null);
        Test.stopTest();

        Assert.areEqual(
            3,
            line.DMT_Risk_Approval_Term__c.intValue(),
            'DMT_Risk_Approval_Term__c should be the 3 whole months between Start_Date__c and End_Date__c'
        );
    }

    // CIBGLOBALD-3779 - covers syncApprovalTermAndEndDate() doing nothing when Start Date is
    // blank, since there is nothing to compute an End Date from.
    @isTest
    private static void testSyncApprovalTermAndEndDate_NoStartDateDoesNothing() {
        DMT_Line__c line = [SELECT Id FROM DMT_Line__c WHERE Line_Id__c = '00003' LIMIT 1];
        line.Start_Date__c = null;
        line.End_Date__c = null;
        line.DMT_Risk_Approval_Term__c = 6;

        Test.startTest();
        new DMT_Line_Helper().syncApprovalTermAndEndDate(new List<DMT_Line__c>{ line }, null);
        Test.stopTest();

        Assert.isNull(line.End_Date__c, 'End_Date__c should stay null when Start_Date__c is blank');
    }

    // CIBGLOBALD-3779 - covers syncApprovalTermAndEndDate() backfilling Term from an existing
    // date pair even when neither date changed in this save (a plain re-save with no field
    // changes) - confirmed against real org data that this did NOT happen before the
    // syncTermAndEndDate fix that dropped the datesChanged gate on this branch.
    @isTest
    private static void testSyncApprovalTermAndEndDate_NoOpResaveStillComputesTerm() {
        DMT_Line__c line = [SELECT Id FROM DMT_Line__c WHERE Line_Id__c = '00003' LIMIT 1];
        line.Start_Date__c = Date.newInstance(2026, 8, 1);
        line.End_Date__c = Date.newInstance(2026, 11, 1);
        line.DMT_Risk_Approval_Term__c = null;

        DMT_Line__c oldLine = line.clone(true, true, false, false);

        Test.startTest();
        new DMT_Line_Helper().syncApprovalTermAndEndDate(
            new List<DMT_Line__c>{ line },
            new Map<Id, DMT_Line__c>{ line.Id => oldLine }
        );
        Test.stopTest();

        Assert.areEqual(
            3,
            line.DMT_Risk_Approval_Term__c.intValue(),
            'DMT_Risk_Approval_Term__c should be backfilled from the unchanged Start/End date pair on a no-op re-save'
        );
    }
}