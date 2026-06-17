@isTest
private without sharing class DMT_Opp_Currency_Conversion_Utils_Test {

    // Helper: crea una Opportunity base
    private static Map<Id, Opportunity> loadTestData(){
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        opp.CurrencyIsoCode ='COP';
        update opp;
        DMT_X_Sell__c xsell = DMT_Test_DataFactory.generatexSell(opp);
        xsell.DMT_Currency__c = opp.CurrencyIsoCode;
        update xsell;
        oppMap.put(opp.Id, opp);
        return oppMap;
    }

    // ============================================================
    // scaleNumbers
    // ============================================================
    @isTest
    static void testScaleNumbersHappyPathNestedStructures() {
        Decimal factor = 1000;

        Map<String, Object> input = new Map<String, Object>{
            'intVal'   => 5000,
            'decVal'   => Decimal.valueOf('12345.000'),
            'dblVal'   => (Object) 98765.0,
            'str'      => (Object) 'no-change',
            'list'     => (Object) new List<Object>{ 1000, 2000.0, 'ok' },
            'map'      => (Object) new Map<String, Object>{ 'x' => 1000, 'y' => 'noop' }
        };

        Map<String, Object> out = new Map<String, Object>();
        for (String k : input.keySet()) {
            out.put(k, DMT_Opp_Currency_Conversion_Utils.scaleNumbers(input.get(k), factor));
        }

        System.assertEquals(5, out.get('intVal'), 'The result is 5');
        System.assertEquals(12.345, out.get('decVal'), 'The result is 12.345');
        System.assertEquals(98.765, out.get('dblVal'), 'The result is 98.765');
        System.assertEquals('no-change', out.get('str'), 'The result is no-change');

        List<Object> l = (List<Object>) out.get('list');
        System.assertEquals(1, l.get(0), 'The result is 1');
        System.assertEquals(2, l.get(1), 'The result is 2');
        System.assertEquals('ok', l.get(2), 'The result is ok');

        Map<String, Object> m = (Map<String, Object>) out.get('map');
        System.assertEquals(1, m.get('x'), 'The result is 1');
        System.assertEquals('noop', m.get('y'), 'The result is noop');
    }

    @isTest
    static void testScaleNumbersNullOrZeroFactorNoChange() {
        System.assertEquals(100, DMT_Opp_Currency_Conversion_Utils.scaleNumbers(100, null), 'The result is 100');
        System.assertEquals(100, DMT_Opp_Currency_Conversion_Utils.scaleNumbers(100, 0), 'The result is 100');
    }

    // ============================================================
    // DMT_Array_Amount_Conversion
    // ============================================================

    // Happy path usando la currency de la Opportunity + CMDT
    @isTest
    static void testArrayAmountConversionHappyPathWithOppCurrency() {

        Opportunity opp = loadTestData().values().get(0);
        opp.CurrencyIsoCode = 'COP';
        update opp;

        Map<String, Object> input = new Map<String, Object>{
            'recordId' => opp.Id,
            'action'   => 'output',
            'amount1'  => 1000000, // -> 1
            'nested'   => (Object) new Map<String, Object>{ 'inner' => 2000000 } // -> 2
        };
        Map<String, Object> outMap = new Map<String, Object>();

        Test.startTest();
        Map<String, Object> result = DMT_Opp_Currency_Conversion_Utils.DMT_Array_Amount_Conversion(input, outMap, new Map<String, Object>());
        Test.stopTest();

        System.assert(!result.containsKey('error'), 'The result does not contain error');
        System.assert(!result.containsKey('exceptionList'),  'The result does not contain exception');
        System.assertEquals(opp.Id, result.get('recordId'), 'The recordId is like the opp Id');
        System.assertEquals('output', result.get('action'), 'The action is output');
        System.assertEquals(1, result.get('amount1'),  'The amount1 is 1');

        Map<String, Object> nested = (Map<String, Object>) result.get('nested');
        System.assertEquals(2, nested.get('inner'), 'The result is 2');
    }

    // Negativo: falta recordId => lanza excepción propia

    @isTest
    static void testArrayAmountConversionMissingParamsThrows() {
        Map<String, Object> inMap = new Map<String, Object>{ 'action' => 'output' };
        Test.startTest();
        Map<String, Object> result = DMT_Opp_Currency_Conversion_Utils.DMT_Array_Amount_Conversion(inMap, new Map<String, Object>(), new Map<String, Object>());
        Test.stopTest();
        System.assert(result.containsKey('exceptionList'), 'El resultado debe contener la clave exceptionList');

    }

    // Negativo: sin line items => devuelve claves con null
    @isTest
    static void testGetOpportunityProductsMinMaxWithoutLineItemsReturnsNulls() {
        Opportunity opp = loadTestData().values().get(0);

        Map<String, Object> input = new Map<String, Object>{ 'recordId' => opp.Id };

        Test.startTest();
        Map<String, Object> result = DMT_Opp_Currency_Conversion_Utils.getOpportunityProductsMinAndMaxDates(
            input, new Map<String, Object>(), new Map<String, Object>()
        );
        Test.stopTest();

        System.assert(result.containsKey('minInitialDate'),  'Result contains minInitialDate');
        System.assert(result.containsKey('maxMaturityDate'), 'Result contains maxMaturityDate');
        System.assertEquals(null, result.get('minInitialDate'), 'Result contains minInitialDate');
        System.assertEquals(null, result.get('maxMaturityDate'), 'Result contains maxMaturityDate');
    }

}