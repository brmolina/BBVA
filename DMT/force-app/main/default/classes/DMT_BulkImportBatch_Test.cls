@isTest
public class DMT_BulkImportBatch_Test {

    // CIBGLOBALD-4851 - test data through DMT_UtilTestClass (DMT test architecture)
    private static final DMT_UtilTestClass DMT_UTIL = new DMT_UtilTestClass();
    private static final String CUSTOMER_CODE = 'ES0182000125513';
    private static final String GROUP_CODE    = 'G0TEST4851GROUP';

    @TestSetup
    static void makeData() {
        // CIBGLOBALD-4851 - a subsidiary (customer code) and a group (group code), one insert
        insert new List<Account>{
            DMT_UTIL.buildAccount(new Map<Schema.SObjectField, Object>{
                Account.Name => 'Test Bulk Import Client', Account.g_customer_id__c => CUSTOMER_CODE, Account.DES_Group_Code__c => null
            }),
            DMT_UTIL.buildAccount(new Map<Schema.SObjectField, Object>{
                Account.Name => 'Test Bulk Import Group', Account.DES_Group_Code__c => GROUP_CODE, Account.g_customer_id__c => null
            })
        };
    }

    // ── LINES ────────────────────────────────────────────────────────────────

    @isTest
    static void testLinesImportCreatesRecords() {
        List<Map<String, Object>> rows = new List<Map<String, Object>>{
            buildLineRow('TESTLIN001', 'Test Line One', CUSTOMER_CODE, 'ES'),
            buildLineRow('TESTLIN002', 'Test Line Two', CUSTOMER_CODE, 'ES')
        };

        Test.startTest();
            DMT_BulkImportBatch batch = new DMT_BulkImportBatch(rows, 'job-test-001', DMT_BulkImportBatch.IMPORT_TYPE_LINES, 'TreasurySettlement');
            Database.executeBatch(batch, 50);
        Test.stopTest();

        List<DMT_Line__c> created = [SELECT Id, Line_Id__c, Name, DMT_Origin__c, Status__c, Client__r.g_customer_id__c FROM DMT_Line__c WHERE Line_Id__c IN ('TESTLIN001', 'TESTLIN002')]; // CIBGLOBALD-4851
        Assert.areEqual(2, created.size(), 'Two lines should have been created');
        for (DMT_Line__c line : created) {
            Assert.areEqual('BulkImport', line.DMT_Origin__c, 'Origin should be BulkImport');
            Assert.areEqual('Draft', line.Status__c, 'New lines are created in Draft'); // CIBGLOBALD-4851
            Assert.areEqual(CUSTOMER_CODE, line.Client__r.g_customer_id__c, 'Client resolved from the customer code'); // CIBGLOBALD-4851
        }

        // AfterCreateLine flow must create the Passport for imported lines, same as for manually created ones
        Set<Id> createdIds = new Map<Id, DMT_Line__c>(created).keySet();
        List<Passport__c> passports = [SELECT Id FROM Passport__c WHERE DMT_Line__c IN :createdIds];
        Assert.areEqual(2, passports.size(), 'One Passport should have been created per imported line');
    }

    @isTest
    static void testLinesImportIsIdempotent() {
        List<Map<String, Object>> rows = new List<Map<String, Object>>{
            buildLineRow('TESTLIN003', 'Test Line Three', CUSTOMER_CODE, 'ES')
        };

        // Both runs inside one startTest/stopTest — Apex only allows one pair per test method
        Test.startTest();
            Database.executeBatch(new DMT_BulkImportBatch(rows, 'job-test-002a', DMT_BulkImportBatch.IMPORT_TYPE_LINES, 'TreasurySettlement'), 50);
            Database.executeBatch(new DMT_BulkImportBatch(rows, 'job-test-002b', DMT_BulkImportBatch.IMPORT_TYPE_LINES, 'TreasurySettlement'), 50);
        Test.stopTest();

        List<DMT_Line__c> result = [SELECT Id FROM DMT_Line__c WHERE Line_Id__c = 'TESTLIN003'];
        Assert.areEqual(1, result.size(), 'Upsert should not create duplicates');
    }

    // CIBGLOBALD-4851 - a client code that is neither a customer nor a group code rejects the row (was: line saved without client)
    @isTest
    static void testLinesImportRejectsUnknownClient() {
        List<Map<String, Object>> rows = new List<Map<String, Object>>{
            buildLineRow('TESTLIN004', 'Test Line Four', 'NONEXISTENT_CLIENT', 'ES')
        };

        Test.startTest();
            Database.executeBatch(new DMT_BulkImportBatch(rows, 'job-test-003', DMT_BulkImportBatch.IMPORT_TYPE_LINES, 'TreasurySettlement'), 50);
        Test.stopTest();

        Assert.areEqual(0, [SELECT COUNT() FROM DMT_Line__c WHERE Line_Id__c = 'TESTLIN004'], 'A line whose client is not found must not be created');
    }

    // CIBGLOBALD-4851 - Client_Code__c can be a group code
    @isTest
    static void testLinesImportResolvesGroupCode() {
        List<Map<String, Object>> rows = new List<Map<String, Object>>{
            buildLineRow('TESTLIN006', 'Test Line Group', GROUP_CODE.toLowerCase(), 'ES')
        };

        Test.startTest();
            Database.executeBatch(new DMT_BulkImportBatch(rows, 'job-test-006', DMT_BulkImportBatch.IMPORT_TYPE_LINES, 'TreasurySettlement'), 50);
        Test.stopTest();

        DMT_Line__c line = [SELECT Client__r.DES_Group_Code__c FROM DMT_Line__c WHERE Line_Id__c = 'TESTLIN006'];
        Assert.areEqual(GROUP_CODE, line.Client__r.DES_Group_Code__c, 'Client resolved from the group code, case-insensitive');
    }

    // CIBGLOBALD-4851 - a new line needs Client_Code__c
    @isTest
    static void testLinesImportRejectsNewLineWithoutClientCode() {
        Map<String, Object> row = buildLineRow('TESTLIN007', 'Test Line No Client', CUSTOMER_CODE, 'ES');
        row.remove('Client_Code__c');

        Test.startTest();
            Database.executeBatch(new DMT_BulkImportBatch(new List<Map<String, Object>>{ row }, 'job-test-007', DMT_BulkImportBatch.IMPORT_TYPE_LINES, 'TreasurySettlement'), 50);
        Test.stopTest();

        Assert.areEqual(0, [SELECT COUNT() FROM DMT_Line__c WHERE Line_Id__c = 'TESTLIN007'], 'A new line without client code must not be created');
    }

    // CIBGLOBALD-4851 - existing line: a column not in the file is not touched, a blank cell clears the field,
    // the status is kept, and no client code is needed
    @isTest
    static void testLinesImportExistingLineOnlyWritesPresentColumns() {
        DMT_UTIL.createLineRecord(new Map<Schema.SObjectField, Object>{
            DMT_Line__c.Name => 'Existing Line', DMT_Line__c.Line_Id__c => 'TESTLIN008',
            DMT_Line__c.Status__c => 'Draft', DMT_Line__c.DMT_Comments__c => 'Keep me',
            DMT_Line__c.g_line_status_type__c => 'PR',
            DMT_Line__c.First_Breakclause__c => '365', DMT_Line__c.Breakclause_Frequency__c => '365' // CIBGLOBALD-4851
        });
        Map<String, Object> row = new Map<String, Object>{
            'Line_Id__c'            => 'TESTLIN008',
            'Name'                  => 'Existing Line Renamed',
            'g_line_status_type__c' => '',
            'First_Breakclause__c'  => '', // CIBGLOBALD-4851
            'Breakclause_Frequency__c' => '' // CIBGLOBALD-4851
        };

        Test.startTest();
            Database.executeBatch(new DMT_BulkImportBatch(new List<Map<String, Object>>{ row }, 'job-test-008', DMT_BulkImportBatch.IMPORT_TYPE_LINES, 'TreasurySettlement'), 50);
        Test.stopTest();

        DMT_Line__c line = [SELECT Name, DMT_Comments__c, g_line_status_type__c, Status__c, First_Breakclause__c, Breakclause_Frequency__c // CIBGLOBALD-4851
                            FROM DMT_Line__c WHERE Line_Id__c = 'TESTLIN008'];
        // CIBGLOBALD-4851 - blank break clause cells keep the values in Salesforce
        Assert.areEqual('365', line.First_Breakclause__c, 'A blank First_Breakclause__c keeps the value');
        Assert.areEqual('365', line.Breakclause_Frequency__c, 'A blank Breakclause_Frequency__c keeps the value');
        Assert.areEqual('Existing Line Renamed', line.Name, 'A column in the file is written');
        Assert.areEqual('Keep me', line.DMT_Comments__c, 'A column not in the file is not touched');
        Assert.isNull(line.g_line_status_type__c, 'A blank cell clears the field');
        Assert.areEqual('Draft', line.Status__c, 'An existing line keeps its status');
    }

    // CIBGLOBALD-4851 - Treasury Lines file values typed from the field describe; an invalid value rejects the row
    @isTest
    static void testLinesImportTypesTreasuryColumns() {
        Map<String, Object> valid = buildLineRow('TESTLIN009', 'Test Line Typed', CUSTOMER_CODE, 'ES');
        valid.putAll(new Map<String, Object>{
            'Start_Date__c' => '01/11/2026', 'Golden_Code__c' => 'A03642968', 'FD_Amount__c' => '1500000.50',
            'DvP_Amount__c' => '750000,00', 'Waiver__c' => 'TRUE', 'DMT_Client_Use__c' => 'Es string, puedes poner lo que quieras',
            'DMT_ID_User__c' => 'NOTAUSER', 'RecordType:RecordType:Name' => 'Treasury Line', 'DMT_Origin__c' => 'IFIt'
        });
        Map<String, Object> invalid = buildLineRow('TESTLIN010', 'Test Line Bad Date', CUSTOMER_CODE, 'ES');
        invalid.put('End_Date__c', 'next year');

        Test.startTest();
            Database.executeBatch(new DMT_BulkImportBatch(new List<Map<String, Object>>{ valid, invalid }, 'job-test-009', DMT_BulkImportBatch.IMPORT_TYPE_LINES, 'TreasurySettlement'), 50);
        Test.stopTest();

        DMT_Line__c line = [SELECT Start_Date__c, Golden_Code__c, FD_Amount__c, DvP_Amount__c, Waiver__c, DMT_Client_Use__c, DMT_Origin__c
                            FROM DMT_Line__c WHERE Line_Id__c = 'TESTLIN009'];
        Assert.areEqual(Date.newInstance(2026, 11, 1), line.Start_Date__c, 'dd/mm/yyyy date');
        Assert.areEqual('A03642968', line.Golden_Code__c, 'Golden code saved');
        Assert.areEqual(1500000.50, line.FD_Amount__c, 'Decimal with a point');
        Assert.areEqual(750000.00, line.DvP_Amount__c, 'Decimal with a comma');
        Assert.isTrue(line.Waiver__c, 'Checkbox TRUE');
        Assert.areEqual('Es string, puedes poner lo que quieras', line.DMT_Client_Use__c, 'Text with a comma');
        Assert.areEqual('BulkImport', line.DMT_Origin__c, 'Origin is always BulkImport');
        Assert.areEqual(0, [SELECT COUNT() FROM DMT_Line__c WHERE Line_Id__c = 'TESTLIN010'], 'An invalid date rejects the row');
    }

    // ── PRODUCTS ─────────────────────────────────────────────────────────────

    @isTest
    static void testProductsImportCreatesTerms() {
        // Create a parent line first
        DMT_UTIL.createLineRecord(new Map<Schema.SObjectField, Object>{ // CIBGLOBALD-4851
            DMT_Line__c.Name          => 'Parent Line for Terms Test',
            DMT_Line__c.Line_Id__c    => 'TESTLIN005',
            DMT_Line__c.DMT_Origin__c => 'BulkImport'
        });

        List<Map<String, Object>> rows = new List<Map<String, Object>>{
            buildTermRow('TESTLIN005', 'TESTLIN005-TERM01', 'Test Term One'),
            buildTermRow('TESTLIN005', 'TESTLIN005-TERM02', 'Test Term Two')
        };

        Test.startTest();
            DMT_BulkImportBatch batch = new DMT_BulkImportBatch(rows, 'job-test-004', DMT_BulkImportBatch.IMPORT_TYPE_PRODUCTS, 'TreasurySettlement');
            Database.executeBatch(batch, 50);
        Test.stopTest();

        List<DMT_Risk_Line_Term__c> terms = [
            SELECT Id, DMT_RiskLineTermId__c
            FROM DMT_Risk_Line_Term__c
            WHERE DMT_RiskLineTermId__c IN ('TESTLIN005-TERM01', 'TESTLIN005-TERM02')
        ];
        Assert.areEqual(2, terms.size(), 'Two risk line terms should have been created');
    }

    @isTest
    static void testEmptyRowsCompleteWithoutError() {
        Test.startTest();
            DMT_BulkImportBatch batch = new DMT_BulkImportBatch(
                new List<Map<String, Object>>(),
                'job-test-005',
                DMT_BulkImportBatch.IMPORT_TYPE_LINES,
                'TreasurySettlement'
            );
            Database.executeBatch(batch, 50);
        Test.stopTest();

        Assert.isTrue(true, 'Empty batch should complete without error');
    }

    // ── Helpers ──────────────────────────────────────────────────────────────

    // Row maps are the payload the LWC sends (one per file row), not records: built by hand on purpose.
    private static Map<String, Object> buildLineRow(String lineId, String name, String clientCode, String geo) {
        return new Map<String, Object>{
            'Line_Id__c'                        => lineId,
            'Name'                              => name,
            'Client_Code__c'                    => clientCode,
            'Booking_Geography__c'              => geo,
            'Start_Date__c'                     => '2026-01-01',
            'End_Date__c'                       => '2027-01-01',
            'CurrencyIsoCode'                   => 'EUR',
            'DMT_LastLevelId__c'                => '20200',
            'g_risk_level_clsfn_type__c'        => 'L',
            'g_line_status_type__c'             => 'CW',
            'owner User id_user__c'             => '',
            'DMT_Risk_Line_Term__c DMT_Amount__c' => '1000000.0',
            'g_global_product_family_id__c'     => '',
            'g_global_product_subfamily_id__c'  => '',
            'g_global_product_category_id__c'   => '',
            'g_gbl_product_subcategory_id__c'   => '',
            'g_global_product_id__c'            => ''
        };
    }

    private static Map<String, Object> buildTermRow(String lineId, String termId, String name) {
        return new Map<String, Object>{
            'Line_Id__c'                                => lineId,
            'DMT_RiskLineTermId__c'                     => termId,
            'Name'                                      => name,
            'DMT_Risk_Line_Term__c DMT_Init_Term__c'    => '2026-01-01',
            'DMT_Risk_Line_Term__c DMT_End_Term__c'     => '2027-01-01',
            'DMT_Risk_Line_Term__c DMT_Amount__c'       => '500000.0',
            'CurrencyIsoCode'                           => 'EUR',
            'DMT_LastLevelId__c'                        => '20200',
            'g_global_product_family_id__c'             => '1000000000',
            'g_global_product_subfamily_id__c'          => '1011000000',
            'g_global_product_category_id__c'           => '',
            'g_gbl_product_subcategory_id__c'           => '',
            'g_global_product_id__c'                    => '',
            'g_amortization_type__c'                    => '',
            'gf_inscol_months_grace_number__c'          => '',
            'gf_payment_frequency__c'                   => '',
            'owner User id_user__c'                     => ''
        };
    }
}
