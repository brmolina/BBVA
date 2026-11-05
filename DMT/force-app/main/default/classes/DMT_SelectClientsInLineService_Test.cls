@isTest
public with sharing class DMT_SelectClientsInLineService_Test {
    private static final String DEFAULT_PAGE = '1';
    private static final String DEFAULT_PAGE_SIZE = '200';

    @testSetup
    static void setupData() {
        List<iaso__GBL_Rest_Services_Url__c> settingsToInsert = new List<iaso__GBL_Rest_Services_Url__c>{
            DMT_Test_DataFactory.setIasoCustomSetting('DMTO_Endpoint_INT', 'https://service.ok', 'ServicesPartition', false),
            DMT_Test_DataFactory.setIasoCustomSetting('DMT_GrantingTicket', 'https://validation.ok', 'ServicesPartition', false),
            DMT_Test_DataFactory.setIasoCustomSetting('DMT_HPGR_Endpoint', 'https://group-position.ok', 'ServicesPartition', false),
            DMT_Test_DataFactory.setIasoCustomSetting('DMT_HPG_CommonEndPoint', 'https://group-position.ok', 'ServicesPartition', false)
        };
        insert settingsToInsert;

        DMT_Line__c line = DMT_Test_DataFactory.generateTestTreasuryLines();
        Custom_Association__c association = DMT_Test_DataFactory.generateCustomAssociation(line.Id, line.Client__c);
        DMT_Test_DataFactory.generateCustomAssociationClient(association.Id);
    }

    @isTest
    static void loadDatasource_withLine_returnsContextAndSelectedRows() {
        DMT_Line__c line = [
            SELECT Id, Client__c, Client__r.DES_Client_Type__c, Status__c
            FROM DMT_Line__c
            WHERE Status__c = :DMT_Constants.DRAFT
            AND Custom_Association__c != null
            LIMIT 1
        ];

        Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());

        Test.startTest();
        Map<String, Object> response = DMT_SelectClientsInLineService.loadDatasource(line.Id, DMT_Constants.CHAR_Y);
        Test.stopTest();

        Assert.areEqual(line.Client__c, (Id) response.get('accountId'));
        Assert.areEqual(DMT_Constants.DRAFT, (String) response.get('lineStatus'));
        Assert.areEqual(true, (Boolean) response.get('canEditSelection'));
        // Changes been made for CIBGLOBALD-4687
        Assert.areEqual(line.Client__r.DES_Client_Type__c, (String) response.get('clientAccountType'));

        List<Object> priorSelectedRows = (List<Object>) response.get('priorselectedRows');
        Assert.areNotEqual(null, priorSelectedRows, 'Expected selected rows key to be present.');
    }

    // Changes been made for CIBGLOBALD-4687
    @isTest
    static void loadDatasource_customerGlobalModeUsesParentAccount() {
        DMT_Line__c line = [
            SELECT Id, Client__c, Status__c
            FROM DMT_Line__c
            WHERE Status__c = :DMT_Constants.DRAFT
            AND Custom_Association__c != null
            LIMIT 1
        ];
        Account parentAccount = DMT_Test_DataFactory.generateAccount();
        Account subsidiary = DMT_Test_DataFactory.generateSubsidiaryForGroup(
            parentAccount.Id,
            new Map<Schema.SObjectField, Object>{ Account.g_customer_id__c => 'ES0182000999001' }
        );
        line.Client__c = subsidiary.Id;
        update line;

        Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());

        Test.startTest();
        Map<String, Object> response = DMT_SelectClientsInLineService.loadDatasourceForMode(
            line.Id,
            'Y/N',
            'global'
        );
        Test.stopTest();

        Assert.areEqual(subsidiary.Id, (Id) response.get('accountId'));
        Assert.areEqual(parentAccount.Id, (Id) response.get('availableClientsAccountId'));
    }

    @isTest
    static void loadDatasource_nullRecordId_returnsEmptyMap() {
        Test.startTest();
        Map<String, Object> response = DMT_SelectClientsInLineService.loadDatasource(null, null);
        Test.stopTest();

        Assert.areEqual(0, response.size());
    }

    @isTest
    static void getAvailableClientsPage_nullAccount_returnsDefaults() {
        Test.startTest();
        Map<String, Object> pageResult = DMT_SelectClientsInLineService.getAvailableClientsPage(null, null, null, null);
        Test.stopTest();

        Assert.areEqual(Integer.valueOf(DEFAULT_PAGE), (Integer) pageResult.get('page'));
        Assert.areEqual(Integer.valueOf(DEFAULT_PAGE_SIZE), (Integer) pageResult.get('pageSize'));
        Assert.areEqual(0, (Integer) pageResult.get('totalElements'));
        Assert.areEqual(1, (Integer) pageResult.get('totalPages'));
        Assert.areEqual(0, ((List<Object>) pageResult.get('availableClients')).size());
    }

    @isTest
    static void applySelection_clientAndGroup_behavesAsExpected() {
        Map<String, Object> records = new Map<String, Object>{
            'selectedRows' => new List<Object>()
        };

        Map<String, Object> clientRow = new Map<String, Object>{
            'clientType' => DMT_Constants.CLIENT.toLowerCase(),
            'customerId' => 'C1',
            'customerName' => 'Client 1'
        };

        records.put('recentRow', clientRow);

        Test.startTest();
        Map<String, Object> addResult = DMT_SelectClientsInLineService.applySelection(records);
        Map<String, Object> removeResult = DMT_SelectClientsInLineService.applySelection(new Map<String, Object>{
            'selectedRows' => addResult.get('responseRS'),
            'recentRow' => clientRow
        });
        Test.stopTest();

        Assert.areEqual(1, ((List<Object>) addResult.get('responseRS')).size());
        Assert.areEqual(0, ((List<Object>) removeResult.get('responseRS')).size());

        Map<String, Object> groupRow = new Map<String, Object>{
            'clientType' => DMT_Constants.GROUP_CLIENT.toLowerCase(),
            'clients' => new List<Object>{
                new Map<String, Object>{
                    'customerId' => 'C2',
                    'customerName' => 'Client 2'
                },
                new Map<String, Object>{
                    'customerId' => 'C3',
                    'customerName' => 'Client 3'
                }
            }
        };

        Map<String, Object> groupResult = DMT_SelectClientsInLineService.applySelection(new Map<String, Object>{
            'selectedRows' => new List<Object>(),
            'recentRow' => groupRow
        });

        Assert.areEqual(2, ((List<Object>) groupResult.get('responseRS')).size());
    }

    @isTest
    static void applyInputField_updatesMatchingRow() {
        Map<String, Object> records = new Map<String, Object>{
            'selectedRows' => new List<Object>{
                new Map<String, Object>{
                    'customerId' => 'C1',
                    'amount' => null
                }
            }
        };

        Map<String, Object> inputField = new Map<String, Object>{
            'customerId' => 'C1',
            'context' => 'amount',
            'value' => 150
        };

        Test.startTest();
        Map<String, Object> result = DMT_SelectClientsInLineService.applyInputField(records, inputField);
        Test.stopTest();

        List<Object> fullRows = (List<Object>) result.get('fullRows');
        Map<String, Object> row = (Map<String, Object>) fullRows[0];
        Assert.areEqual(150, row.get('amount'));
    }

    @isTest
    static void saveSelection_withDraftLine_savesSuccessfully() {
        DMT_Line__c line = [
            SELECT Id, Client__c, Line_Id__c, CurrencyIsoCode, Custom_Association__c
            FROM DMT_Line__c
            WHERE Status__c = :DMT_Constants.DRAFT
            AND Custom_Association__c != null
            LIMIT 1
        ];

        List<Object> selectedRows = new List<Object>{
            new Map<String, Object>{
                'customerId' => 'ES0182000170441',
                'customerName' => 'GRIFOLS S.A.',
                'countryIfoId' => 'ES',
                'updSmsclInternalRatgType' => 'A',
                'customerCounterpartiesCodesDesc' => 'CP',
                'operationMitigantDesc' => 'ISDA',
                'currentRatingToolDate' => String.valueOf(Date.today()),
                'term' => '6',
                'amount' => '1000',
                'amountFD' => '200',
                'amountDVP' => '300'
            }
        };

        Test.startTest();
        Map<String, Object> result = DMT_SelectClientsInLineService.saveSelection(
            line.Id,
            'ES0182000170441',
            line.CurrencyIsoCode,
            'G20180109100427',
            line.Client__c,
            line.Line_Id__c,
            selectedRows
        );
        Test.stopTest();

        Assert.areEqual(true, (Boolean) result.get('success'));
        Assert.areEqual('OK', (String) result.get('error'));

        Custom_Association_Client__c savedClient = [
            SELECT Id, Alpha_Code_Client__c, DMT_Amount__c, DMT_FDAmount__c, DMT_DVPAmount__c, DMT_Term__c
            FROM Custom_Association_Client__c
            WHERE Alpha_Code_Client__c = 'ES0182000170441'
            AND Custom_Association__c = :line.Custom_Association__c
            LIMIT 1
        ];

        Assert.areNotEqual(null, savedClient.Id, 'Expected selected client to be persisted in line association.');
    }

    // CIBGLOBALD-4811 - Enhancement fix to existing process: a client row that fails to insert rolls back the
    // association already updated in the same save.
    @isTest
    static void saveSelection_FailedStep_RollsBackAssociation() {
        DMT_Line__c line = [
            SELECT Id, Client__c, Line_Id__c, CurrencyIsoCode, Custom_Association__c
            FROM DMT_Line__c
            WHERE Status__c = :DMT_Constants.DRAFT
            AND Custom_Association__c != null
            LIMIT 1
        ];
        String mainHolderBefore = [SELECT g_customer_id__c FROM Custom_Association__c WHERE Id = :line.Custom_Association__c].g_customer_id__c;
        List<Object> selectedRows = new List<Object>{
            new Map<String, Object>{
                'customerId' => 'ES0182000004811',
                'customerName' => 'X'.repeat(300),
                'term' => '6'
            }
        };

        Test.startTest();
        Map<String, Object> result = DMT_SelectClientsInLineService.saveSelection(
            line.Id, 'ES0182000004811', line.CurrencyIsoCode, 'G20180109100427', line.Client__c, line.Line_Id__c, selectedRows
        );
        Test.stopTest();

        Assert.areEqual(false, (Boolean) result.get('success'), 'A client name over the field length fails the insert');
        Assert.areEqual(mainHolderBefore, [SELECT g_customer_id__c FROM Custom_Association__c WHERE Id = :line.Custom_Association__c].g_customer_id__c,
            'The association update made before the failure is rolled back');
    }

    // CIBGLOBALD-4811 - the reopen check of the Line Client tab builds what each action writes and saves nothing:
    // only Lines in Ready to close are checked; without a Ready to close Case nothing reopens; a failing check
    // answers nothing.
    @isTest
    static void previewLineClientSave_ReturnsNothingWithoutCaseAndSavesNothing() {
        DMT_Line__c line = [
            SELECT Id, Client__c, Line_Id__c, CurrencyIsoCode, Custom_Association__c
            FROM DMT_Line__c
            WHERE Status__c = :DMT_Constants.DRAFT
            AND Custom_Association__c != null
            LIMIT 1
        ];
        Integer clientsBefore = [SELECT COUNT() FROM Custom_Association_Client__c WHERE Custom_Association__c = :line.Custom_Association__c];
        String goldenBefore = [SELECT Golden_Code__c FROM DMT_Line__c WHERE Id = :line.Id].Golden_Code__c;
        List<Object> selectedRows = new List<Object>{
            new Map<String, Object>{ 'customerId' => 'ES0182000004811', 'customerName' => 'ZZ 4811', 'term' => '6', 'amount' => '10' }
        };

        Test.startTest();
        List<DMT_ApprovalChangeStep_Handler.FeatureChangeWrapper> notReadyToClose = DMT_SelectClientsInLineService.previewLineClientSave(
            'readytoclose', 'selection', line.Id, 'ES0182000004811', line.CurrencyIsoCode, 'G20180109100427', line.Client__c, line.Line_Id__c, selectedRows, null
        );
        TriggerBypass.setBypass();
        update new DMT_Line__c(Id = line.Id, Status__c = DMT_Constants.READYTOCLOSE);
        TriggerBypass.removeBypass();
        List<DMT_ApprovalChangeStep_Handler.FeatureChangeWrapper> selection = DMT_SelectClientsInLineService.previewLineClientSave(
            'readytoclose', 'selection', line.Id, 'ES0182000004811', line.CurrencyIsoCode, 'G20180109100427', line.Client__c, line.Line_Id__c, selectedRows, null
        );
        List<DMT_ApprovalChangeStep_Handler.FeatureChangeWrapper> golden = DMT_SelectClientsInLineService.previewLineClientSave(
            'readytoclose', 'golden', line.Id, null, null, null, null, null, null, ' G4811 '
        );
        List<DMT_ApprovalChangeStep_Handler.FeatureChangeWrapper> deleteAssociation = DMT_SelectClientsInLineService.previewLineClientSave(
            'readytoclose', 'deleteAssociation', line.Id, null, null, null, null, null, null, null
        );
        List<DMT_ApprovalChangeStep_Handler.FeatureChangeWrapper> unknownAction = DMT_SelectClientsInLineService.previewLineClientSave(
            'readytoclose', 'other', line.Id, null, null, null, null, null, null, null
        );
        List<DMT_ApprovalChangeStep_Handler.FeatureChangeWrapper> failing = DMT_SelectClientsInLineService.previewLineClientSave(
            'readytoclose', 'selection', null, null, null, null, null, null, null, null
        );
        Test.stopTest();

        Assert.isTrue(notReadyToClose.isEmpty(), 'Outside Ready to close nothing reopens');
        Assert.isTrue(selection.isEmpty() && golden.isEmpty() && deleteAssociation.isEmpty(), 'Without a Ready to close Case nothing reopens');
        Assert.isTrue(unknownAction.isEmpty(), 'An unknown action is not checked');
        Assert.isTrue(failing.isEmpty(), 'A failing check returns nothing');
        Assert.areEqual(clientsBefore, [SELECT COUNT() FROM Custom_Association_Client__c WHERE Custom_Association__c = :line.Custom_Association__c], 'The preview saves nothing');
        Assert.areEqual(goldenBefore, [SELECT Golden_Code__c FROM DMT_Line__c WHERE Id = :line.Id].Golden_Code__c, 'The preview saves nothing');
    }

    // Changes been made for CIBGLOBALD-4687
    @isTest
    static void saveGoldenSelection_updatesOnlyGoldenCode() {
        DMT_Line__c line = [
            SELECT Id, Client__c, Custom_Association__c
            FROM DMT_Line__c
            WHERE Status__c = :DMT_Constants.DRAFT
            AND Custom_Association__c != null
            LIMIT 1
        ];

        Test.startTest();
        Map<String, Object> result = DMT_SelectClientsInLineService.saveGoldenSelection(
            line.Id,
            'GOLDEN-CODE-123'
        );
        Test.stopTest();

        DMT_Line__c savedLine = [
            SELECT Client__c, Golden_Code__c, Custom_Association__c
            FROM DMT_Line__c
            WHERE Id = :line.Id
        ];
        Assert.areEqual(true, (Boolean) result.get('success'));
        Assert.areEqual('GOLDEN-CODE-123', savedLine.Golden_Code__c);
        Assert.areEqual(line.Client__c, savedLine.Client__c);
        Assert.areEqual(line.Custom_Association__c, savedLine.Custom_Association__c);
    }

    // Changes been made for CIBGLOBALD-4687
    @isTest
    static void clearGoldenSelection_updatesOnlyGoldenCode() {
        DMT_Line__c line = [
            SELECT Id, Client__c, Custom_Association__c
            FROM DMT_Line__c
            WHERE Status__c = :DMT_Constants.DRAFT
            AND Custom_Association__c != null
            LIMIT 1
        ];
        line.Golden_Code__c = 'GOLDEN-CODE-123';
        update line;

        Test.startTest();
        Map<String, Object> result = DMT_SelectClientsInLineService.clearGoldenSelection(line.Id);
        Test.stopTest();

        DMT_Line__c savedLine = [
            SELECT Client__c, Golden_Code__c, Custom_Association__c
            FROM DMT_Line__c
            WHERE Id = :line.Id
        ];
        Assert.areEqual(true, (Boolean) result.get('success'));
        Assert.areEqual(null, savedLine.Golden_Code__c);
        Assert.areEqual(line.Client__c, savedLine.Client__c);
        Assert.areEqual(line.Custom_Association__c, savedLine.Custom_Association__c);
    }

    @isTest
    static void saveSelection_withNoPermission_returnsError() {
        DMT_Line__c closedWonLine = DMT_Test_DataFactory.generateTestTreasurySingularLines();
        DMT_Line__c line = [
            SELECT Id, Client__c, CurrencyIsoCode, Line_Id__c
            FROM DMT_Line__c
            WHERE Id = :closedWonLine.Id
            LIMIT 1
        ];

        Test.startTest();
        Map<String, Object> result = DMT_SelectClientsInLineService.saveSelection(
            line.Id,
            'ES0182000170441',
            line.CurrencyIsoCode,
            'G20180109100427',
            line.Client__c,
            line.Line_Id__c,
            new List<Object>()
        );
        Test.stopTest();

        Assert.areEqual(false, (Boolean) result.get('success'));
        Assert.isTrue(((String) result.get('error')).contains('cannot be edited'));
    }

    @isTest
    static void loadProductDatasource_nullLine_returnsEmptyMap() {
        Test.startTest();
        Map<String, Object> response = DMT_SelectClientsInLineService.loadProductDatasource(null, '01', null);
        Test.stopTest();

        Assert.areEqual(0, response.size());
    }

    @isTest
    static void loadProductDatasource_withLine_returnsProductContext() {
        DMT_Line__c line = [
            SELECT Id, Client__c, Line_Id__c, Status__c, Custom_Association__c
            FROM DMT_Line__c
            WHERE Status__c = :DMT_Constants.DRAFT
            AND Custom_Association__c != null
            LIMIT 1
        ];

        Custom_Association__c productAssociation = new Custom_Association__c(
            DMT_Line__c = line.Id,
            Group__c = line.Client__c,
            gf_customer_group_id__c = line.Line_Id__c + '_01',
            g_customer_id__c = 'ES0182000170441',
            CurrencyIsoCode = 'EUR'
        );
        insert productAssociation;

        insert new Custom_Association_Client__c(
            Custom_Association__c = productAssociation.Id,
            Alpha_Code_Client__c = 'ES0182000170441',
            g_customer_id__c = 'ES0182000170441',
            gf_customer_group_id__c = productAssociation.gf_customer_group_id__c,
            Name = 'GRIFOLS S.A.',
            CurrencyIsoCode = 'EUR'
        );

        Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());

        Test.startTest();
        Map<String, Object> response = DMT_SelectClientsInLineService.loadProductDatasource(line.Id, '01', null);
        Test.stopTest();

        Assert.areEqual(line.Id, (Id) response.get('lineId'));
        Assert.areEqual(line.Line_Id__c + '_01', (String) response.get('productAssociationExternalId'));
        Assert.areNotEqual(null, response.get('selectedRows'));
        Assert.areNotEqual(null, response.get('availableClients'));
    }

    @isTest
    static void saveProductSelection_createsAndDeletesProductAssociation() {
        DMT_Line__c line = [
            SELECT Id, Client__c, Line_Id__c, CurrencyIsoCode
            FROM DMT_Line__c
            WHERE Status__c = :DMT_Constants.DRAFT
            AND Custom_Association__c != null
            LIMIT 1
        ];

        List<Object> selectedRows = new List<Object>{
            new Map<String, Object>{
                'customerId' => 'ES0182000170441',
                'customerName' => 'GRIFOLS S.A.',
                'countryIfoId' => 'ES',
                'updSmsclInternalRatgType' => 'A',
                'customerCounterpartiesCodesDesc' => 'CP',
                'operationMitigantDesc' => 'ISDA',
                'currentRatingToolDate' => String.valueOf(Date.today()),
                'term' => '6M'
            }
        };

        Test.startTest();
        Map<String, Object> createResult = DMT_SelectClientsInLineService.saveProductSelection(
            line.Id,
            '02',
            'ES0182000170441',
            line.CurrencyIsoCode,
            'G20180109100427',
            line.Client__c,
            selectedRows
        );
        Map<String, Object> deleteResult = DMT_SelectClientsInLineService.saveProductSelection(
            line.Id,
            '02',
            'ES0182000170441',
            line.CurrencyIsoCode,
            'G20180109100427',
            line.Client__c,
            new List<Object>()
        );
        Test.stopTest();

        Assert.areEqual(true, (Boolean) createResult.get('success'));
        Assert.areEqual(true, (Boolean) deleteResult.get('success'));
        Assert.areEqual(
            0,
            [SELECT COUNT() FROM Custom_Association__c WHERE gf_customer_group_id__c = :line.Line_Id__c + '_02']
        );
    }

    @isTest
    static void saveProductSelection_missingPriority_returnsError() {
        DMT_Line__c line = [
            SELECT Id, Client__c, CurrencyIsoCode
            FROM DMT_Line__c
            WHERE Status__c = :DMT_Constants.DRAFT
            AND Custom_Association__c != null
            LIMIT 1
        ];

        Test.startTest();
        Map<String, Object> result = DMT_SelectClientsInLineService.saveProductSelection(
            line.Id,
            null,
            'ES0182000170441',
            line.CurrencyIsoCode,
            'G20180109100427',
            line.Client__c,
            new List<Object>{ new Map<String, Object>{ 'customerId' => 'ES0182000170441' } }
        );
        Test.stopTest();

        Assert.areEqual(false, (Boolean) result.get('success'));
        Assert.areNotEqual(null, result.get('error'));
    }
}