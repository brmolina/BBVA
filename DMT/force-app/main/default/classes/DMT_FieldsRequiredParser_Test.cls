/**
 * @description Unit tests for DMT_FieldsRequiredParser.
 * @author BBVA DMT
 * @date 2026-07-20
 */
@isTest
private class DMT_FieldsRequiredParser_Test {

    @isTest
    static void testParseNullOrBlankReturnsEmptyMap() {
        Test.startTest();
        Map<String, List<String>> resultNull = DMT_FieldsRequiredParser.parse(null);
        Map<String, List<String>> resultBlank = DMT_FieldsRequiredParser.parse('   ');
        Test.stopTest();

        System.assertEquals(0, resultNull.size(), 'Null message should return an empty map');
        System.assertEquals(0, resultBlank.size(), 'Blank message should return an empty map');
    }

    @isTest
    static void testParseGroupsFieldsByTab() {
        String message = 'opportunity.xsells.currencyId, products[01].businessArea, ' +
            'products[01].amortization.payments.financeType, products[01].amortization.payments.paymentDate, ' +
            'products[01].amortization.interest.rate, opportunity.xsells.year, ' +
            'products[01].mitigants.mitigantId, products[01].mitigants.mitigantType, ' +
            'products[01].tenor.startDate, opportunity.description';

        Test.startTest();
        Map<String, List<String>> result = DMT_FieldsRequiredParser.parse(message);
        Test.stopTest();

        System.assert(result.containsKey('Opportunity - XSells'), 'Should map xsells fields to their own tab');
        System.assertEquals(new List<String>{ 'currencyId', 'year' }, result.get('Opportunity - XSells'));

        System.assert(result.containsKey('Opportunity'), 'Should map generic opportunity fields');
        System.assertEquals(new List<String>{ 'description' }, result.get('Opportunity'));

        System.assert(result.containsKey('Products - Business'));
        System.assertEquals(new List<String>{ 'businessArea' }, result.get('Products - Business'));

        System.assert(result.containsKey('Products - Amortization - Payments'));
        System.assertEquals(new List<String>{ 'financeType', 'paymentDate' }, result.get('Products - Amortization - Payments'));

        System.assert(result.containsKey('Products - Amortization - Interest'));
        System.assertEquals(new List<String>{ 'rate' }, result.get('Products - Amortization - Interest'));

        System.assert(result.containsKey('Products - Mitigants'));
        System.assertEquals(new List<String>{ 'mitigantId', 'mitigantType' }, result.get('Products - Mitigants'));

        System.assert(result.containsKey('Products - Tenor'));
        System.assertEquals(new List<String>{ 'startDate' }, result.get('Products - Tenor'));
    }

    @isTest
    static void testParseHandlesMultipleProductIndexesAndDuplicates() {
        String message = 'products[01].mitigants.mitigantId, products[02].mitigants.mitigantId, products[10].mitigants.mitigantId';

        Test.startTest();
        Map<String, List<String>> result = DMT_FieldsRequiredParser.parse(message);
        Test.stopTest();

        System.assertEquals(1, result.size(), 'All product indexes should normalize to the same tab');
        System.assertEquals(1, result.get('Products - Mitigants').size(), 'Duplicate field names within the same tab should be collapsed');
    }

    @isTest
    static void testParseUnmappedFieldGoesToOtherTab() {
        String message = 'someUnknownRoot.someField';

        Test.startTest();
        Map<String, List<String>> result = DMT_FieldsRequiredParser.parse(message);
        Test.stopTest();

        System.assert(result.containsKey('Other'), 'Unmapped fields should fall back to the Other tab');
        System.assertEquals(new List<String>{ 'someField' }, result.get('Other'));
    }
}