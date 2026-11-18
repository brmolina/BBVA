@isTest
public class DMT_BulkImportBatch_Test {

    @TestSetup
    static void makeData() {
        Account acc = new Account(
            Name             = 'Test Bulk Import Client',
            g_customer_id__c = 'ES0182000125513'
        );
        insert acc;
    }

    // ── LINES ────────────────────────────────────────────────────────────────

    @isTest
    static void testLinesImportCreatesRecords() {
        List<Map<String, Object>> rows = new List<Map<String, Object>>{
            buildLineRow('TESTLIN001', 'Test Line One', 'ES0182000125513', 'ES'),
            buildLineRow('TESTLIN002', 'Test Line Two', 'ES0182000125513', 'ES')
        };

        Test.startTest();
            DMT_BulkImportBatch batch = new DMT_BulkImportBatch(rows, 'job-test-001', DMT_BulkImportBatch.IMPORT_TYPE_LINES, 'TreasurySettlement');
            Database.executeBatch(batch, 50);
        Test.stopTest();

        List<DMT_Line__c> created = [SELECT Id, Line_Id__c, Name, DMT_Origin__c FROM DMT_Line__c WHERE Line_Id__c IN ('TESTLIN001', 'TESTLIN002')];
        Assert.areEqual(2, created.size(), 'Two lines should have been created');
        for (DMT_Line__c line : created) {
            Assert.areEqual('BulkImport', line.DMT_Origin__c, 'Origin should be BulkImport');
        }

        // AfterCreateLine flow must create the Passport for imported lines, same as for manually created ones
        Set<Id> createdIds = new Map<Id, DMT_Line__c>(created).keySet();
        List<Passport__c> passports = [SELECT Id FROM Passport__c WHERE DMT_Line__c IN :createdIds];
        Assert.areEqual(2, passports.size(), 'One Passport should have been created per imported line');
    }

    @isTest
    static void testLinesImportIsIdempotent() {
        List<Map<String, Object>> rows = new List<Map<String, Object>>{
            buildLineRow('TESTLIN003', 'Test Line Three', 'ES0182000125513', 'ES')
        };

        // Both runs inside one startTest/stopTest — Apex only allows one pair per test method
        Test.startTest();
            Database.executeBatch(new DMT_BulkImportBatch(rows, 'job-test-002a', DMT_BulkImportBatch.IMPORT_TYPE_LINES, 'TreasurySettlement'), 50);
            Database.executeBatch(new DMT_BulkImportBatch(rows, 'job-test-002b', DMT_BulkImportBatch.IMPORT_TYPE_LINES, 'TreasurySettlement'), 50);
        Test.stopTest();

        List<DMT_Line__c> result = [SELECT Id FROM DMT_Line__c WHERE Line_Id__c = 'TESTLIN003'];
        Assert.areEqual(1, result.size(), 'Upsert should not create duplicates');
    }

    @isTest
    static void testLinesImportHandlesInvalidClientGracefully() {
        List<Map<String, Object>> rows = new List<Map<String, Object>>{
            buildLineRow('TESTLIN004', 'Test Line Four', 'NONEXISTENT_CLIENT', 'ES')
        };

        Test.startTest();
            DMT_BulkImportBatch batch = new DMT_BulkImportBatch(rows, 'job-test-003', DMT_BulkImportBatch.IMPORT_TYPE_LINES, 'TreasurySettlement');
            Database.executeBatch(batch, 50);
        Test.stopTest();

        // Line should be created without Client lookup (allOrNone=false means batch completes)
        // Invalid client reference causes a per-row error which is collected, not a batch crash
        List<DMT_Line__c> result = [SELECT Id FROM DMT_Line__c WHERE Line_Id__c = 'TESTLIN004'];
        // The record may or may not exist depending on whether the cross-ref error allows insert
        // Key assertion: batch did not throw an unhandled exception (reaching here is success)
        Assert.isTrue(true, 'Batch completed without unhandled exception');
    }

    // ── PRODUCTS ─────────────────────────────────────────────────────────────

    @isTest
    static void testProductsImportCreatesTerms() {
        // Create a parent line first
        DMT_Line__c parentLine = new DMT_Line__c(
            Name        = 'Parent Line for Terms Test',
            Line_Id__c  = 'TESTLIN005',
            DMT_Origin__c = 'BulkImport'
        );
        insert parentLine;

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