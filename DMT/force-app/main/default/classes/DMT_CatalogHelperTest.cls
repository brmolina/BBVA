/**
 * @Name     DMT_CatalogHelperTest
 * @Description Test class for DMT_CatalogHelper.
 *              Covers getAllTaxonomyCatalogValues, getTaxonomyCatalogValuesByCode,
 *              cache behaviour, ordering (alphabetic and numeric), and edge cases.
 */
@isTest
public with sharing class DMT_CatalogHelperTest {

    // ═══════════════════════════════════════════════════════════════════════════
    // Test Setup
    // ═══════════════════════════════════════════════════════════════════════════

    @TestSetup
    static void setupTestData() {
        // Insert active taxonomy values for every catalog code present in
        // CATALOG_FIELD_MAPPING so all paths in DMT_CatalogHelper are reachable.
        List<DMT_Taxonomy_Values__c> records = new List<DMT_Taxonomy_Values__c>();
        Long ts = System.now().getTime();

        // ── C264 — Currencies (label = value = DMT_Value__c, orderBy DMT_Value__c ASC)
        // Alphabetic order: EUR < USD
        records.add(makeTaxonomy('C264', 'USD', 'USD', 'C264_USD_' + ts, null));
        records.add(makeTaxonomy('C264', 'EUR', 'EUR', 'C264_EUR_' + ts, null));

        // ── C245 — Countries (label = DMT_Name_EN__c, value = DMT_Value__c, orderBy DMT_Name_EN__c ASC)
        // Alphabetic order: Italy < Spain
        records.add(makeTaxonomy('C245', 'Spain', 'ES', 'C245_ES_' + ts, null));
        records.add(makeTaxonomy('C245', 'Italy', 'IT', 'C245_IT_' + ts, null));

        // ── C204 — Ratings (label = DMT_Name_EN__c, orderBy gf_catalog_atrb_val1_name_c__c textNumeric ASC)
        // gf_catalog_atrb_val1_name_c__c holds the numeric sort position: AAA=1, AA+=2, A=3
        records.add(makeTaxonomyNumeric('C204', 'A',   'C204_A_'  + ts, 'C204_KA_'  + ts, '3'));
        records.add(makeTaxonomyNumeric('C204', 'AAA', 'C204_AAA_' + ts, 'C204_KAAA_' + ts, '1'));
        records.add(makeTaxonomyNumeric('C204', 'AA+', 'C204_AAP_' + ts, 'C204_KAAP_' + ts, '2'));

        // ── E895 — Guarantee types (label = DMT_Name_EN__c, orderBy DMT_Name_EN__c ASC)
        // Alphabetic order: Others > Others < Others > Standby Letter of Credit < Others > Surety guarantee
        records.add(makeTaxonomy('E895', 'Others > Surety guarantee',           'E895_SG_'  + ts, 'E895_KSG_'  + ts, null));
        records.add(makeTaxonomy('E895', 'Others > Others',                     'E895_OT_'  + ts, 'E895_KOT_'  + ts, null));
        records.add(makeTaxonomy('E895', 'Others > Standby Letter of Credit',   'E895_SLC_' + ts, 'E895_KSLC_' + ts, null));

        // ── C009 — Counterparty types (orderBy gf_catalog_atrb_val1_name_c__c textNumeric ASC)
        // Corporates - Corporates = 1 ; Fin Inst - Corporates = 2
        records.add(makeTaxonomyNumeric('C009', 'Fin Inst - Corporates',    'C009_FI_'  + ts, 'C009_KFI_'  + ts, '2'));
        records.add(makeTaxonomyNumeric('C009', 'Corporates - Corporates',  'C009_CC_'  + ts, 'C009_KCC_'  + ts, '1'));

        // ── D971 — Generic (orderBy DMT_Name_EN__c ASC)
        // Alphabetic order: Bond < Loan
        records.add(makeTaxonomy('D971', 'Loan', 'D971_LN_' + ts, 'D971_KLN_' + ts, null));
        records.add(makeTaxonomy('D971', 'Bond', 'D971_BD_' + ts, 'D971_KBD_' + ts, null));

        insert records;
    }

    // ─── Builder helpers ──────────────────────────────────────────────────────

    private static DMT_Taxonomy_Values__c makeTaxonomy(
        String catalog, String nameEN, String value, String key, String numericAttr
    ) {
        return new DMT_Taxonomy_Values__c(
            DMT_Catalog__c     = catalog,
            DMT_Name__c        = nameEN,
            DMT_Name_EN__c     = nameEN,
            DMT_Value__c       = value,
            DMT_External_Id__c = key,
            DMT_Key__c         = key,
            DMT_Active__c      = true,
            CurrencyIsoCode    = 'EUR'
        );
    }

    private static DMT_Taxonomy_Values__c makeTaxonomyNumeric(
        String catalog, String nameEN, String value, String key, String numericAttr
    ) {
        DMT_Taxonomy_Values__c rec = makeTaxonomy(catalog, nameEN, value, key, numericAttr);
        rec.gf_catalog_atrb_val1_name_c__c = numericAttr;
        return rec;
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // getAllTaxonomyCatalogValues
    // ═══════════════════════════════════════════════════════════════════════════

    @isTest
    static void testGetAllTaxonomyCatalogValues_returnsAllCodes() {
        Test.startTest();
        Map<String, List<Map<String, String>>> result = DMT_CatalogHelper.getAllTaxonomyCatalogValues();
        Test.stopTest();

        System.assert(result != null, 'Result should not be null');
        System.assert(result.containsKey('C264'), 'Should contain C264 (currencies)');
        System.assert(result.containsKey('C245'), 'Should contain C245 (countries)');
        System.assert(result.containsKey('C204'), 'Should contain C204 (ratings)');
        System.assert(result.containsKey('E895'), 'Should contain E895 (guarantee types)');
        System.assert(result.containsKey('C009'), 'Should contain C009 (counterparty types)');
        System.assert(result.containsKey('D971'), 'Should contain D971');
    }

    @isTest
    static void testGetAllTaxonomyCatalogValues_eachEntryHasLabelAndValue() {
        Test.startTest();
        Map<String, List<Map<String, String>>> result = DMT_CatalogHelper.getAllTaxonomyCatalogValues();
        Test.stopTest();

        for (String code : result.keySet()) {
            for (Map<String, String> entry : result.get(code)) {
                System.assert(entry.containsKey('label'), 'Entry for ' + code + ' must have label key');
                System.assert(entry.containsKey('value'), 'Entry for ' + code + ' must have value key');
            }
        }
    }

    @isTest
    static void testGetAllTaxonomyCatalogValues_alphabeticOrderingC245() {
        Test.startTest();
        Map<String, List<Map<String, String>>> result = DMT_CatalogHelper.getAllTaxonomyCatalogValues();
        Test.stopTest();

        List<Map<String, String>> c245 = result.get('C245');
        System.assert(c245 != null && c245.size() >= 2, 'C245 should have at least 2 entries');
        // 'Italy' < 'Spain' alphabetically
        System.assertEquals('Italy', c245[0].get('label'), 'C245 first entry should be Italy');
        System.assertEquals('Spain', c245[1].get('label'), 'C245 second entry should be Spain');
    }

    @isTest
    static void testGetAllTaxonomyCatalogValues_numericOrderingC204() {
        Test.startTest();
        Map<String, List<Map<String, String>>> result = DMT_CatalogHelper.getAllTaxonomyCatalogValues();
        Test.stopTest();

        List<Map<String, String>> c204 = result.get('C204');
        System.assert(c204 != null && c204.size() >= 3, 'C204 should have at least 3 entries');
        // Numeric sort position: AAA=1, AA+=2, A=3
        System.assertEquals('AAA', c204[0].get('label'), 'C204[0] should be AAA (pos 1)');
        System.assertEquals('AA+', c204[1].get('label'), 'C204[1] should be AA+ (pos 2)');
        System.assertEquals('A',   c204[2].get('label'), 'C204[2] should be A (pos 3)');
    }

    @isTest
    static void testGetAllTaxonomyCatalogValues_numericOrderingC009() {
        Test.startTest();
        Map<String, List<Map<String, String>>> result = DMT_CatalogHelper.getAllTaxonomyCatalogValues();
        Test.stopTest();

        List<Map<String, String>> c009 = result.get('C009');
        System.assert(c009 != null && c009.size() >= 2, 'C009 should have at least 2 entries');
        // Numeric sort position: Corporates - Corporates=1, Fin Inst - Corporates=2
        System.assertEquals('Corporates - Corporates', c009[0].get('label'), 'C009[0] should be Corporates - Corporates (pos 1)');
        System.assertEquals('Fin Inst - Corporates',   c009[1].get('label'), 'C009[1] should be Fin Inst - Corporates (pos 2)');
    }

    @isTest
    static void testGetAllTaxonomyCatalogValues_cacheReturnsSameInstance() {
        Test.startTest();
        Map<String, List<Map<String, String>>> first  = DMT_CatalogHelper.getAllTaxonomyCatalogValues();
        Map<String, List<Map<String, String>>> second = DMT_CatalogHelper.getAllTaxonomyCatalogValues();
        Test.stopTest();

        System.assert(first === second, 'Second call should return the cached instance');
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // getTaxonomyCatalogValuesByCode
    // ═══════════════════════════════════════════════════════════════════════════

    @isTest
    static void testGetByCode_validCode_returnsValues() {
        Test.startTest();
        List<Map<String, String>> result = DMT_CatalogHelper.getTaxonomyCatalogValuesByCode('E895');
        Test.stopTest();

        System.assert(result != null, 'Result for E895 should not be null');
        System.assert(!result.isEmpty(), 'Result for E895 should not be empty');
        for (Map<String, String> entry : result) {
            System.assert(entry.containsKey('label'), 'Entry must have label');
            System.assert(entry.containsKey('value'), 'Entry must have value');
        }
        // Alphabetic order: Others > Others < Others > Standby Letter of Credit < Others > Surety guarantee
        System.assertEquals('Others > Others',                   result[0].get('label'), 'E895[0] should be Others > Others');
        System.assertEquals('Others > Standby Letter of Credit', result[1].get('label'), 'E895[1] should be Others > Standby Letter of Credit');
        System.assertEquals('Others > Surety guarantee',         result[2].get('label'), 'E895[2] should be Others > Surety guarantee');
    }

    @isTest
    static void testGetByCode_validCode_alphabeticOrder() {
        Test.startTest();
        List<Map<String, String>> result = DMT_CatalogHelper.getTaxonomyCatalogValuesByCode('D971');
        Test.stopTest();

        System.assert(result != null && result.size() >= 2, 'D971 should have at least 2 entries');
        // 'Bond' < 'Loan' alphabetically
        System.assertEquals('Bond', result[0].get('label'), 'D971[0] should be Bond');
        System.assertEquals('Loan', result[1].get('label'), 'D971[1] should be Loan');
    }

    @isTest
    static void testGetByCode_unknownCode_returnsNull() {
        Test.startTest();
        List<Map<String, String>> result = DMT_CatalogHelper.getTaxonomyCatalogValuesByCode('ZZZZ');
        Test.stopTest();

        System.assertEquals(null, result, 'Unknown catalog code should return null');
    }

    @isTest
    static void testGetByCode_blankCode_returnsNull() {
        Test.startTest();
        List<Map<String, String>> resultEmpty = DMT_CatalogHelper.getTaxonomyCatalogValuesByCode('');
        List<Map<String, String>> resultNull  = DMT_CatalogHelper.getTaxonomyCatalogValuesByCode(null);
        Test.stopTest();

        System.assertEquals(null, resultEmpty, 'Blank code should return null');
        System.assertEquals(null, resultNull,  'Null code should return null');
    }

    @isTest
    static void testGetByCode_cacheIsUsedOnSecondCall() {
        Test.startTest();
        List<Map<String, String>> first  = DMT_CatalogHelper.getTaxonomyCatalogValuesByCode('C245');
        List<Map<String, String>> second = DMT_CatalogHelper.getTaxonomyCatalogValuesByCode('C245');
        Test.stopTest();

        System.assert(first === second, 'Second call for C245 should return the cached list');
    }

    @isTest
    static void testGetByCode_cacheSharedWithGetAll() {
        // Prime the full-catalog cache first, then retrieve by code — should
        // hit cacheMap populated by getAllTaxonomyCatalogValues.
        Test.startTest();
        DMT_CatalogHelper.getAllTaxonomyCatalogValues();
        List<Map<String, String>> byCode = DMT_CatalogHelper.getTaxonomyCatalogValuesByCode('C264');
        Test.stopTest();

        System.assert(byCode != null, 'C264 should be found in cache after getAllTaxonomyCatalogValues');
        System.assert(!byCode.isEmpty(), 'C264 cache entry should not be empty');
    }
}