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
            SELECT Id, Client__c, Status__c
            FROM DMT_Line__c
            WHERE Status__c = :DMT_Constants.DRAFT
            AND Custom_Association__c != null
            LIMIT 1
        ];

        Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());

        Test.startTest();
        Map<String, Object> response = DMT_SelectClientsInLineService.loadDatasource(line.Id, DMT_Constants.CHAR_Y);
        Test.stopTest();

        System.assertEquals(line.Client__c, (Id) response.get('accountId'));
        System.assertEquals(DMT_Constants.DRAFT, (String) response.get('lineStatus'));
        System.assertEquals(true, (Boolean) response.get('canEditSelection'));

        List<Object> priorSelectedRows = (List<Object>) response.get('priorselectedRows');
        System.assertNotEquals(null, priorSelectedRows, 'Expected selected rows key to be present.');
    }

    @isTest
    static void loadDatasource_nullRecordId_returnsEmptyMap() {
        Test.startTest();
        Map<String, Object> response = DMT_SelectClientsInLineService.loadDatasource(null, null);
        Test.stopTest();

        System.assertEquals(0, response.size());
    }

    @isTest
    static void getAvailableClientsPage_nullAccount_returnsDefaults() {
        Test.startTest();
        Map<String, Object> pageResult = DMT_SelectClientsInLineService.getAvailableClientsPage(null, null, null, null);
        Test.stopTest();

        System.assertEquals(Integer.valueOf(DEFAULT_PAGE), (Integer) pageResult.get('page'));
        System.assertEquals(Integer.valueOf(DEFAULT_PAGE_SIZE), (Integer) pageResult.get('pageSize'));
        System.assertEquals(0, (Integer) pageResult.get('totalElements'));
        System.assertEquals(1, (Integer) pageResult.get('totalPages'));
        System.assertEquals(0, ((List<Object>) pageResult.get('availableClients')).size());
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

        System.assertEquals(1, ((List<Object>) addResult.get('responseRS')).size());
        System.assertEquals(0, ((List<Object>) removeResult.get('responseRS')).size());

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

        System.assertEquals(2, ((List<Object>) groupResult.get('responseRS')).size());
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
        System.assertEquals(150, row.get('amount'));
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

        System.assertEquals(true, (Boolean) result.get('success'));
        System.assertEquals('OK', (String) result.get('error'));

        Custom_Association_Client__c savedClient = [
            SELECT Id, Alpha_Code_Client__c, DMT_Amount__c, DMT_FDAmount__c, DMT_DVPAmount__c, DMT_Term__c
            FROM Custom_Association_Client__c
            WHERE Alpha_Code_Client__c = 'ES0182000170441'
            AND Custom_Association__c = :line.Custom_Association__c
            LIMIT 1
        ];

        System.assertNotEquals(null, savedClient.Id, 'Expected selected client to be persisted in line association.');
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

        System.assertEquals(false, (Boolean) result.get('success'));
        System.assert(((String) result.get('error')).contains('cannot be edited'));
    }

    @isTest
    static void loadProductDatasource_nullLine_returnsEmptyMap() {
        Test.startTest();
        Map<String, Object> response = DMT_SelectClientsInLineService.loadProductDatasource(null, '01', null);
        Test.stopTest();

        System.assertEquals(0, response.size());
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

        System.assertEquals(line.Id, (Id) response.get('lineId'));
        System.assertEquals(line.Line_Id__c + '_01', (String) response.get('productAssociationExternalId'));
        System.assertNotEquals(null, response.get('selectedRows'));
        System.assertNotEquals(null, response.get('availableClients'));
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

        System.assertEquals(true, (Boolean) createResult.get('success'));
        System.assertEquals(true, (Boolean) deleteResult.get('success'));
        System.assertEquals(
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

        System.assertEquals(false, (Boolean) result.get('success'));
        System.assertNotEquals(null, result.get('error'));
    }
}