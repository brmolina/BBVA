@isTest
public class DMT_CurrencyConversionServiceTest {
    @testSetup
    static void setupData() {
        // Crear la línea de prueba
        DMT_Line__c testLine = DMT_Test_DataFactory.generateTestTreasuryLines();
        testLine.Name = 'Test Line';
        testLine.Amount__c = 10000;
        testLine.CurrencyIsoCode = 'COP';
        update testLine;
    }

    @isTest
    static void testConvertProductList_withAmount() {
        // Recuperar el registro insertado en @testSetup
        DMT_Line__c line = [
            SELECT Id, Name, Amount__c, CurrencyIsoCode 
            FROM DMT_Line__c 
            WHERE Name = 'Test Line' 
            LIMIT 1
        ];

        // Construir el wrapper y lista de entrada
        DMT_CurrencyConversionService.ProductWrapper pw = new DMT_CurrencyConversionService.ProductWrapper();
        pw.Id = line.Id;
        pw.name = 'Loan';
        pw.currencyIsoCode = line.CurrencyIsoCode;
        pw.currencyLabel = 'Millions';
        pw.isSelected = true;
        pw.line = line.Id;
        pw.amount = line.Amount__c;

        List<Object> rawList = new List<Object>{ pw };

        Test.startTest();
            List<DMT_CurrencyConversionService.ProductWrapper> result = DMT_CurrencyConversionService.convertProductList(rawList);
        Test.stopTest();

        // Verificaciones
        System.assertNotEquals(null, result, 'El resultado no debe ser nulo');
        System.assertEquals(1, result.size(), 'Debe devolver exactamente un elemento');
        DMT_CurrencyConversionService.ProductWrapper outPw = result[0];
        System.assertEquals(line.Id, outPw.line, 'El campo line debe coincidir con el Id de la línea de prueba');
        System.assertNotEquals(null, outPw.amount, 'El monto convertido no debe ser nulo');
    }

    @isTest
    static void testConvertProductList_withoutAmount() {
        // Construir un wrapper sin monto para validar el flujo alternativo
        DMT_CurrencyConversionService.ProductWrapper pwNoAmt = new DMT_CurrencyConversionService.ProductWrapper();
        pwNoAmt.Id = null;
        pwNoAmt.name = 'Sin Monto';
        pwNoAmt.currencyIsoCode = 'COP';
        pwNoAmt.currencyLabel = 'Millions';
        pwNoAmt.isSelected = false;
        pwNoAmt.line = null;
        pwNoAmt.amount = null;

        List<Object> rawList = new List<Object>{ pwNoAmt };

        Test.startTest();
            List<DMT_CurrencyConversionService.ProductWrapper> resultNoAmt = DMT_CurrencyConversionService.convertProductList(rawList);
        Test.stopTest();

        // Verificaciones
        System.assertNotEquals(null, resultNoAmt, 'El resultado no debe ser nulo');
        System.assertEquals(1, resultNoAmt.size(), 'Debe devolver exactamente un elemento');
        System.assertEquals(null, resultNoAmt[0].amount, 'El monto debe permanecer nulo cuando input.amount es nulo');
    }

    @isTest
    static void test_DMT_convertProductList_basic() {
        // Preparar datos de entrada simulados
        DMT_Line__c line = [
            SELECT Id, Amount__c, CurrencyIsoCode
            FROM DMT_Line__c
            WHERE Name = 'Test Line'
            LIMIT 1
        ];

        Map<String, Object> productMap = new Map<String, Object>{
        'line' => line.Id,
        'name' => 'Loan',
        'currencyIsoCode' => line.CurrencyIsoCode,
        'currencyLabel' => '',
        'isSelected' => true,
        'amount' => line.Amount__c
        };

        List<Object> rawList = new List<Object>{ productMap };

        Map<String, Object> inputMap = new Map<String, Object>{
            'list' => rawList
        };       
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Test.startTest();
        DMT_CurrencyConversionService.DMT_convertProductList(inputMap, outMap, options);
        Test.stopTest();

        // Verificar resultados esperados
        System.assert(outMap.containsKey('list'), 'Debe incluir la lista convertida');
}

    @isTest
    static void test_DMT_convertProductList_basic_noList() {

        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Test.startTest();
        DMT_CurrencyConversionService.DMT_convertProductList(inputMap, outMap, options);
        Test.stopTest();

        // Verificar resultados esperados
        System.assert(outMap.containsKey('error'), 'Debe incluir un mensaje de error');
}

@isTest
    static void test_DMT_convertProductList_sanction() {
        // Preparar datos de entrada simulados
        DMT_Line__c line = [
            SELECT Id, Amount__c, CurrencyIsoCode
            FROM DMT_Line__c
            WHERE Name = 'Test Line'
            LIMIT 1
        ];

        Map<String, Object> productMap = new Map<String, Object>{
        'lineRisk' => line.Id,
        'name' => 'Loan',
        'CurrencyIsoCode' => 'COP',
        'currencyLabel' => 'Millions',
        'isSelected' => true,
        'amount' => 5000000
        };

        List<Object> rawList = new List<Object>{ productMap };

        Map<String, Object> inputMap = new Map<String, Object>{
            'list' => rawList
        };       
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Test.startTest();
        DMT_CurrencyConversionService.DMT_convertProductListSanctions(inputMap, outMap, options);
        Test.stopTest();

        // Verificar resultados esperados
        System.assert(outMap.containsKey('list'), 'Debe incluir la lista convertida');
}

}