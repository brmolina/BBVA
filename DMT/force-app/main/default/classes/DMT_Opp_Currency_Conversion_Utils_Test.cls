@isTest
private class DMT_Opp_Currency_Conversion_Utils_Test {

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
    static void test_scaleNumbers_happyPath_nestedStructures() {
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

        System.assertEquals(5, out.get('intVal'));
        System.assertEquals(12.345, out.get('decVal'));
        System.assertEquals(98.765, out.get('dblVal'));
        System.assertEquals('no-change', out.get('str'));

        List<Object> l = (List<Object>) out.get('list');
        System.assertEquals(1, l.get(0));
        System.assertEquals(2, l.get(1));
        System.assertEquals('ok', l.get(2));

        Map<String, Object> m = (Map<String, Object>) out.get('map');
        System.assertEquals(1, m.get('x'));
        System.assertEquals('noop', m.get('y'));
    }

    @isTest
    static void test_scaleNumbers_nullOrZeroFactor_noChange() {
        System.assertEquals(100, DMT_Opp_Currency_Conversion_Utils.scaleNumbers(100, null));
        System.assertEquals(100, DMT_Opp_Currency_Conversion_Utils.scaleNumbers(100, 0));
    }

    // ============================================================
    // DMT_Array_Amount_Conversion
    // ============================================================

    // Happy path usando la currency de la Opportunity + CMDT
    @isTest
    static void test_ArrayAmountConversion_happyPath_withOppCurrency() {

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

        System.assert(!result.containsKey('error'));
        System.assert(!result.containsKey('exceptionList'));
        System.assertEquals(opp.Id, result.get('recordId'));
        System.assertEquals('output', result.get('action'));
        System.assertEquals(1, result.get('amount1'));

        Map<String, Object> nested = (Map<String, Object>) result.get('nested');
        System.assertEquals(2, nested.get('inner'));
    }

    // Negativo: falta recordId => lanza excepción propia
    
    @isTest
    static void test_ArrayAmountConversion_missingParams_throws() {
        Map<String, Object> inMap = new Map<String, Object>{ 'action' => 'output' };
        Test.startTest();
        Map<String, Object> result = DMT_Opp_Currency_Conversion_Utils.DMT_Array_Amount_Conversion(inMap, new Map<String, Object>(), new Map<String, Object>());
        Test.stopTest();
        System.assert(result.containsKey('exceptionList'), 'El resultado debe contener la clave exceptionList');

    }
    
    // Negativo: sin line items => devuelve claves con null
    @isTest
    static void test_getOpportunityProductsMinMax_withoutLineItems_returnsNulls() {
        Opportunity opp = loadTestData().values().get(0);

        Map<String, Object> input = new Map<String, Object>{ 'recordId' => opp.Id };

        Test.startTest();
        Map<String, Object> result = DMT_Opp_Currency_Conversion_Utils.getOpportunityProductsMinAndMaxDates(
            input, new Map<String, Object>(), new Map<String, Object>()
        );
        Test.stopTest();

        System.assert(result.containsKey('minInitialDate'));
        System.assert(result.containsKey('maxMaturityDate'));
        System.assertEquals(null, result.get('minInitialDate'));
        System.assertEquals(null, result.get('maxMaturityDate'));
    }

}