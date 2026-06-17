@isTest
private without sharing class DMT_Currency_Conversion_Utils_Test {

    private static final String TARGET_CURRENCY_CODE = 'COP';
    private static final String OTHER_CURRENCY_CODE = 'CAD';
    private static final Decimal COP_CONVERSION_FACTOR = 1000000;

    private static Map<Id, DMT_Line__c> createTestLines() {
        List<DMT_Line__c> linesToInsert = new List<DMT_Line__c>{
            new DMT_Line__c(Name = 'Test Line COP', CurrencyIsoCode = TARGET_CURRENCY_CODE),
            new DMT_Line__c(Name = 'Test Line USD', CurrencyIsoCode = 'USD'),
            new DMT_Line__c(Name = 'Test Line USD', CurrencyIsoCode = 'CAD'),
            new DMT_Line__c(Name = 'Test Line No CC', CurrencyIsoCode = null)
        };
        insert linesToInsert;
        Map<Id, DMT_Line__c> lineMap = new Map<Id, DMT_Line__c>();
        for (DMT_Line__c line : linesToInsert) {
            lineMap.put(line.Id, line);
        }
        return lineMap;
    }

    // conversión INPUT single variable
    @isTest
    static void testConversionInput() {
        Map<Id, DMT_Line__c> lines = createTestLines();
        Id lineIdCOP = getLineIdByCurrency(lines, TARGET_CURRENCY_CODE);

        Map<String, Object> inputMap = new Map<String, Object>{
            'recordId' => lineIdCOP, 'action' => 'input', 'amount' => 10, 'otherField' => 'test'
        };
        Map<String, Object> outMap = new Map<String, Object>();
        Test.startTest();
        Map<String, Object> result = DMT_Currency_Conversion_Utils.DMT_Single_Amount_Conversion(inputMap, outMap, null);
        Test.stopTest();

        System.assertEquals(10 * COP_CONVERSION_FACTOR, result.get('amount'), 'The result is 10 * COP_CONVERSION_FACTOR');
        System.assertEquals('test', result.get('otherField'), 'The result is test');
        System.assertEquals(null, result.get('error'), 'The result is null');
    }

    // conversión OUTPUT single variable
    @isTest
    static void testConversionOutput() {
        Map<Id, DMT_Line__c> lines = createTestLines();
        Id lineIdCOP = getLineIdByCurrency(lines, TARGET_CURRENCY_CODE);

        Map<String, Object> inputMap = new Map<String, Object>{
            'recordId' => lineIdCOP, 'action' => 'output', 'amount' => 76000.0
        };
        Map<String, Object> outMap = new Map<String, Object>();
        Test.startTest();
        Map<String, Object> result = DMT_Currency_Conversion_Utils.DMT_Single_Amount_Conversion(inputMap, outMap, null);
        Test.stopTest();

        System.assertEquals(76000.0 / COP_CONVERSION_FACTOR, ((Decimal)result.get('amount')).setScale(5), 'The result is 76000.0 / COP_CONVERSION_FACTOR');
        System.assertEquals(null, result.get('error'), 'The result is null');
    }

    // conversion single variable OUTPUT Missing parameters
    @isTest
    static void testConversionOutputMissingParameters() {
        // Preparar entrada sin recordId ni action para forzar la excepción
        Map<String, Object> inputMap = new Map<String, Object>{
            'someKey' => 'someValue' // cualquier clave irrelevante
        };
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Test.startTest();
        DMT_Currency_Conversion_Utils.DMT_Single_Amount_Conversion(inputMap, outputMap, options);
        Test.stopTest();

        System.assert(outputMap.containsKey('error'), 'Debe contener la clave "error" en caso de excepción');
        System.assert(outputMap.get('error') != null, 'El mensaje de error no debe ser nulo');
        System.assertEquals(inputMap.get('someKey'), outputMap.get('someKey'), 'Debe copiar las claves del input al output');
    }

    //Test de conversión de una línea con moneda diferente a COP
    @isTest
    static void testConversionInputNoCop() {
        Map<Id, DMT_Line__c> lines = createTestLines();
        Id lineIdCAD = getLineIdByCurrency(lines, OTHER_CURRENCY_CODE);

        Map<String, Object> inputMap = new Map<String, Object>{
            'recordId' => lineIdCAD, 'action' => 'input', 'amount' => 10, 'otherField' => 'test'
        };
        Map<String, Object> outMap = new Map<String, Object>();
        Test.startTest();
        Map<String, Object> result = DMT_Currency_Conversion_Utils.DMT_Single_Amount_Conversion(inputMap, outMap, null);
        Test.stopTest();

        System.assertEquals(10, result.get('amount'), 'The result is 10');
        System.assertEquals('test', result.get('otherField'), 'The result is test');
    }


    // Faltan parámetros, prueba en caso de que no se pasen los parámetros requeridos
    @isTest
    static void testMissingParameters() {
        Map<String, Object> inputMap = new Map<String, Object>{'amount' => 100};
        Map<String, Object> outMap = new Map<String, Object>();
        Test.startTest();
        Map<String, Object> result = DMT_Currency_Conversion_Utils.DMT_Single_Amount_Conversion(inputMap, outMap, null);
        Test.stopTest();
        // Verificamos que se haya agregado una lista de excepciones
        System.assert(result.containsKey('exceptionList'), 'El resultado debe contener la clave exceptionList');
    }

    // Prueba si se pasa una accion no válida
    @isTest
    static void testUnrecognizedAction() {
        Map<Id, DMT_Line__c> lines = createTestLines();
        Id lineIdCOP = getLineIdByCurrency(lines, TARGET_CURRENCY_CODE);

        Map<String, Object> inputMap = new Map<String, Object>{
            'recordId' => lineIdCOP, 'action' => 'accion_mala', 'amount' => 10.0
        };
        Map<String, Object> outMap = new Map<String, Object>();
        Test.startTest();
        Map<String, Object> result = DMT_Currency_Conversion_Utils.DMT_Single_Amount_Conversion(inputMap, outMap, null);
         Test.stopTest();
        // Verificamos que se haya agregado una lista de excepciones
        System.assert(result.containsKey('exceptionList'), 'El resultado debe contener la clave exceptionList');
    }

    //Prueba si se pasa un valor no numérico
    @isTest
static void testConversionInvalidNumericValue() {

    Map<Id, DMT_Line__c> lines = createTestLines();
    Id lineIdCOP = getLineIdByCurrency(lines, TARGET_CURRENCY_CODE);

    Map<String, Object> inputMap = new Map<String, Object>{
        'recordId' => lineIdCOP, 'action' => 'input', 'amount' => 'abc'
    };

    Map<String, Object> outputMap = new Map<String, Object>();
    Map<String, Object> options = new Map<String, Object>();

    Test.startTest();
    Map<String, Object> result = DMT_Currency_Conversion_Utils.DMT_Single_Amount_Conversion(inputMap, outputMap, options);
    Test.stopTest();

    // Si no es un valor numerico, se espera que la conversión no se realice
    System.assertEquals('abc', result.get('amount'), 'The result is abc');
}


    // Utilidad para obtener Id de línea por moneda
    private static Id getLineIdByCurrency(Map<Id, DMT_Line__c> lines, String currencyCode) {
        for (DMT_Line__c line : lines.values()) {
            if (line.CurrencyIsoCode == currencyCode) {
                return line.Id;
            }
        }
        return null;
    }

    @isTest
static void testListAmountConversion() {
    List<Id> lineIds = new List<Id>();

    // Crea y guarda líneas de prueba
    List<DMT_Line__c> lines = new List<DMT_Line__c>{
        new DMT_Line__c(Name = 'Line 1', CurrencyIsoCode = 'USD'),
        new DMT_Line__c(Name = 'Line 2', CurrencyIsoCode = 'COP')
    };
    insert lines;

    for (DMT_Line__c line : lines) {
        lineIds.add(line.Id);
    }

    Map<String, Object> inputMap = new Map<String, Object>{
        'recordIds' => lineIds,
        'action' => 'convert'
    };
    Map<String, Object> outputMap = new Map<String, Object>();
    Map<String, Object> options = new Map<String, Object>();

    Test.startTest();
    Map<String, Object> result = DMT_Currency_Conversion_Utils.DMT_List_Amount_Conversion(inputMap, outputMap, options);
    Test.stopTest();//revisar
     System.assert(result.containsKey('exceptionList'), 'El resultado debe contener la clave exceptionList');
}

@isTest
static void testListInputConversionSuccess() {

    Map<Id, DMT_Line__c> lines = createTestLines();
    Id lineIdCOP = getLineIdByCurrency(lines, TARGET_CURRENCY_CODE);

    List<Object> originalList = new List<Object>{
        new Map<String, Object>{'line' => lineIdCOP, 'amount' => 10, 'description' => 'Item COP'}
    };

    Map<String, Object> inputMap = new Map<String, Object>{
        'action' => 'input',
        'list' => originalList
    };
    Map<String, Object> outMap = new Map<String, Object>();

    Test.startTest();
    Map<String, Object> result = DMT_Currency_Conversion_Utils.DMT_List_Amount_Conversion(inputMap, outMap, new Map<String, Object>());
    Test.stopTest();

    List<Object> resultList = (List<Object>) result.get('list');
    System.assertEquals(1, resultList.size(), 'Debe retornar la lista');
    Map<String, Object> item = (Map<String, Object>) resultList[0];
    System.assertEquals(10000000, item.get('amount'), 'El amount convertido no es correcto');
}

@isTest
static void testListOutputConversionSuccess() {

    Map<Id, DMT_Line__c> lines = createTestLines();
    Id lineIdCOP = getLineIdByCurrency(lines, TARGET_CURRENCY_CODE);

    List<Object> originalList = new List<Object>{
        new Map<String, Object>{'line' => lineIdCOP, 'amount' => 10000000, 'description' => 'Item COP'}
    };

    Map<String, Object> inputMap = new Map<String, Object>{
        'action' => 'output',
        'list' => originalList
    };
    Map<String, Object> outMap = new Map<String, Object>();

    Test.startTest();
    Map<String, Object> result = DMT_Currency_Conversion_Utils.DMT_List_Amount_Conversion(inputMap, outMap, new Map<String, Object>());
    Test.stopTest();

    List<Object> resultList = (List<Object>) result.get('list');
    System.assertEquals(1, resultList.size(), 'Debe retornar la lista');
    Map<String, Object> item = (Map<String, Object>) resultList[0];
    System.assertEquals(10, item.get('amount'), 'El amount convertido no es correcto');
}

@isTest
static void testListOutputConversionSuccessLowAmount() {

    Map<Id, DMT_Line__c> lines = createTestLines();
    Id lineIdCOP = getLineIdByCurrency(lines, TARGET_CURRENCY_CODE);

    List<Object> originalList = new List<Object>{
        new Map<String, Object>{'line' => lineIdCOP, 'amount' => 1000, 'description' => 'Item COP'}
    };

    Map<String, Object> inputMap = new Map<String, Object>{
        'action' => 'output',
        'list' => originalList
    };
    Map<String, Object> outMap = new Map<String, Object>();

    Test.startTest();
    Map<String, Object> result = DMT_Currency_Conversion_Utils.DMT_List_Amount_Conversion(inputMap, outMap, new Map<String, Object>());
    Test.stopTest();

    List<Object> resultList = (List<Object>) result.get('list');
    System.assertEquals(1, resultList.size(), 'Debe retornar la lista');
    Map<String, Object> item = (Map<String, Object>) resultList[0];
    System.assertEquals(1000, item.get('amount'), 'No debe convertir porque el valor es muy bajo');
}

@isTest
static void testListOutputConversionNoAction() {

    Map<Id, DMT_Line__c> lines = createTestLines();
    Id lineIdCOP = getLineIdByCurrency(lines, TARGET_CURRENCY_CODE);

    List<Object> originalList = new List<Object>{
        new Map<String, Object>{'line' => lineIdCOP, 'amount' => 10000000, 'description' => 'Item COP'}
    };

    Map<String, Object> inputMap = new Map<String, Object>{
        'list' => originalList
    };
    Map<String, Object> outMap = new Map<String, Object>();

    Test.startTest();
    Map<String, Object> result = DMT_Currency_Conversion_Utils.DMT_List_Amount_Conversion(inputMap, outMap, new Map<String, Object>());
    Test.stopTest();
    System.assert(result.containsKey('exceptionList'), 'El resultado debe contener la clave exceptionList');
}

@isTest
    static void testRiskTermInputConversionSuccess() {

        Map<Id, DMT_Line__c> lines = createTestLines();
        Id lineIdCOP = getLineIdByCurrency(lines, TARGET_CURRENCY_CODE);

        Map<String, Object> riskLineTerm = new Map<String, Object>{
            'TermInput' => new List<Object>{
                new Map<String, Object>{'line' => lineIdCOP, 'amount' => 10}
            }
        };
        Map<String, Object> inputMap = new Map<String, Object>{
            'action' => 'input',
            'RiskLineTerm' => riskLineTerm
        };
        Map<String, Object> outMap = new Map<String, Object>();

        Test.startTest();
        Map<String, Object> result = DMT_Currency_Conversion_Utils.DMT_Risk_Term_Conversion(inputMap, outMap, new Map<String, Object>());
        Test.stopTest();

        Map<String, Object> riskLineTermResult = (Map<String, Object>) result.get('RiskLineTerm');
        System.assertNotEquals(null, riskLineTermResult, 'RiskLineTerm no debe ser null');
        List<Object> termInputList = (List<Object>) riskLineTermResult.get('TermInput');
        System.assertEquals(1, termInputList.size(), 'Debe haber un solo item en TermInput');
        Map<String, Object> item = (Map<String, Object>) termInputList[0];
        System.assertEquals(10000000, item.get('amount'), 'El amount convertido no es correcto');
    }

    @isTest
    static void testRiskTermOutputConversionSuccess() {

        Map<Id, DMT_Line__c> lines = createTestLines();
        Id lineIdCOP = getLineIdByCurrency(lines, TARGET_CURRENCY_CODE);

        Map<String, Object> riskLineTerm = new Map<String, Object>{
            'TermInput' => new List<Object>{
                new Map<String, Object>{'line' => lineIdCOP, 'amount' => 10000000}
            }
        };
        Map<String, Object> inputMap = new Map<String, Object>{
            'action' => 'output',
            'RiskLineTerm' => riskLineTerm
        };
        Map<String, Object> outMap = new Map<String, Object>();

        Test.startTest();
        Map<String, Object> result = DMT_Currency_Conversion_Utils.DMT_Risk_Term_Conversion(inputMap, outMap, new Map<String, Object>());
        Test.stopTest();
        Map<String, Object> riskLineTermResult = (Map<String, Object>) result.get('RiskLineTerm');
        System.assertNotEquals(null, riskLineTermResult, 'RiskLineTerm no debe ser null');
        List<Object> termInputList = (List<Object>) riskLineTermResult.get('TermInput');
        System.assertEquals(1, termInputList.size(), 'Debe haber un solo item en TermInput');
        Map<String, Object> item = (Map<String, Object>) termInputList[0];
        System.assertEquals(10, item.get('amount'), 'El amount convertido no es correcto');

         System.debug('testRiskTerm_OutputConversion_Success:' + result);
    }


    @isTest
    static void testRiskTermOutputConversionMissingParameters() {

        Map<Id, DMT_Line__c> lines = createTestLines();
        Id lineIdCOP = getLineIdByCurrency(lines, TARGET_CURRENCY_CODE);

        Map<String, Object> riskLineTerm = new Map<String, Object>{
            'TermInput' => new List<Object>{
                new Map<String, Object>{'line' => lineIdCOP, 'amount' => 10000000}
            }
        };
        Map<String, Object> inputMap = new Map<String, Object>{
            'RiskLineTerm' => riskLineTerm
        };
        Map<String, Object> outMap = new Map<String, Object>();

        Test.startTest();
        Map<String, Object> result = DMT_Currency_Conversion_Utils.DMT_Risk_Term_Conversion(inputMap, outMap, new Map<String, Object>());
        Test.stopTest();
        System.assert(result.containsKey('exceptionList'), 'El resultado debe contener la clave exceptionList');
    }

    @isTest
    static void testRiskTermOutputConversionNoRiskLineTerm() {

        Map<Id, DMT_Line__c> lines = createTestLines();
        Id lineIdCOP = getLineIdByCurrency(lines, TARGET_CURRENCY_CODE);

        Map<String, Object> riskLineTerm = new Map<String, Object>{
            'TermInput' => new List<Object>{
                new Map<String, Object>{'line' => lineIdCOP, 'amount' => 10000000}
            }
        };
        Map<String, Object> inputMap = new Map<String, Object>{
            'action' => 'output'
        };

        Map<String, Object> outMap = new Map<String, Object>();

        Test.startTest();
        Map<String, Object> result = DMT_Currency_Conversion_Utils.DMT_Risk_Term_Conversion(inputMap, outMap, new Map<String, Object>());
        Test.stopTest();
        System.assert(result.containsKey('exceptionList'), 'El resultado debe contener la clave exceptionList');
    }

    @isTest
    static void testDMTCurrencyAmountFormatWithMask() {

        Decimal testAmount = 1234567.89;

        Map<String, Object> inputMap = new Map<String, Object>{
            'testAmount' => testAmount,
            'mask' => '#.###,00'
        };

        Map<String, Object> outMap = new Map<String, Object>();

        Test.startTest();
        Map<String, Object> result = DMT_Currency_Conversion_Utils.DMT_Currency_Amount_Format(inputMap, outMap, new Map<String, Object>());
        Test.stopTest();
        System.assertEquals('1.234.567,89', result.get('testAmount'), 'The result is 1.234.567,89');
    }

     @isTest
    static void testDMTCurrencyAmountFormatNoMask() {

        Decimal testAmount = 1234567.89;

        Map<String, Object> inputMap = new Map<String, Object>{
            'testAmount' => testAmount
        };

        Map<String, Object> outMap = new Map<String, Object>();

        Test.startTest();
        Map<String, Object> result = DMT_Currency_Conversion_Utils.DMT_Currency_Amount_Format(inputMap, outMap, new Map<String, Object>());
        Test.stopTest();
        System.assert(result.containsKey('testAmount'), 'El resultado debe contener la variable a enmascarar');
    }

    static void testDMTCurrencyAmountFormatInvalidAmount() {

        Map<String, Object> inputMap = new Map<String, Object>{
            'testAmount' => 'abc',
            'mask' => '#.###,00'
        };

        Map<String, Object> outMap = new Map<String, Object>();

        Test.startTest();
        Map<String, Object> result = DMT_Currency_Conversion_Utils.DMT_Currency_Amount_Format(inputMap, outMap, new Map<String, Object>());
        Test.stopTest();
        System.assert(result.containsKey('testAmount'), 'El resultado debe contener la variable a enmascarar');
    }

    static void testDMTCurrencyAmountFormatInvalidMask() {

        Decimal testAmount = 1234567.89;

        Map<String, Object> inputMap = new Map<String, Object>{
            'testAmount' => testAmount,
            'mask' => '#.##.##.##'
        };

        Map<String, Object> outMap = new Map<String, Object>();

        Test.startTest();
        Map<String, Object> result = DMT_Currency_Conversion_Utils.DMT_Currency_Amount_Format(inputMap, outMap, new Map<String, Object>());
        Test.stopTest();

        System.debug('TEST:'+JSON.serialize(result));
        System.assertEquals('Error al formatear los montos', outMap.get('error'), 'Debe marcar error en caso de excepción');
    }

    @isTest
    static void testReplaceAllNodesRecursive() {
        Map<String, Object> source = new Map<String, Object>{
            'targetKey' => 'oldValue',
            'nested' => new Map<String, Object>{
                'targetKey' => 'oldValue'
            }
        };

        String keyToReplace = 'targetKey';
        Object newValue = 'newValue';

        DMT_Currency_Conversion_Utils.replaceAllNodesRecursive(source, keyToReplace, newValue);

        System.assertEquals('newValue', source.get('targetKey'), 'The result is newValue');
        System.assertEquals('newValue', ((Map<String, Object>)source.get('nested')).get('targetKey'), 'The result is newValue');
    }

    @isTest
    static void testDMTReplaceNodeInObject() {
        Map<String, Object> json = new Map<String, Object>{
            'nodeToReplace' => 'oldValue',
            'otherField' => 'keepThis'
        };

        Map<String, Object> input = new Map<String, Object>{
            'originalJson' => json.clone(),
            'nodeToReplace' => 'nodeToReplace',
            'replacementNode' => 'newValue'
        };

        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Test.startTest();
        Map<String, Object> result = DMT_Currency_Conversion_Utils.DMT_Replace_Node_In_Object(input, output, options);
        Test.stopTest();

        System.assertNotEquals(null, result, 'El resultado no debe ser null');
        System.assert(result.containsKey('result'), 'Debe contener la clave "result"');
        Map<String, Object> replaced = (Map<String, Object>)result.get('result');
        System.assertEquals('newValue', replaced.get('nodeToReplace'), 'El nodo debe haber sido reemplazado');
        System.assertEquals('keepThis', replaced.get('otherField'), 'Otros campos no deben verse afectados');
    }

    @isTest
    static void testDMTReplaceNodeInObjectException() {

        Map<String, Object> json = new Map<String, Object>{
            'nodeToReplace' => 'oldValue',
            'otherField' => 'keepThis'
        };

        Map<String, Object> input = new Map<String, Object>{
            'nodeToReplace' => 'nodeToReplace',
            'replacementNode' => 'newValue'
        };

        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Test.startTest();
        Map<String, Object> result = DMT_Currency_Conversion_Utils.DMT_Replace_Node_In_Object(input, output, options);
        Test.stopTest();

         System.assertEquals('Error en reemplazando el nodo', output.get('error'), 'Debe marcar error en caso de excepción');
    }

    @isTest
    static void testDMTListConvertCurrencyFieldsInListInput() {

        Map<Id, DMT_Line__c> lines = createTestLines();
        Id recordId = getLineIdByCurrency(lines, TARGET_CURRENCY_CODE); // COP por defecto

        Map<String, Object> record = new Map<String, Object>{
            'amount' => 15
        };

        List<Object> recordList = new List<Object>{ record };

        Map<String, Object> input = new Map<String, Object>{
            'list' => recordList,
            'action' => 'input',
            'recordId' => recordId,
            'fieldsToConvert' => 'amount'
        };

        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Test.startTest();
        Map<String, Object> result = DMT_Currency_Conversion_Utils.DMT_List_convertCurrencyFieldsInList(input, output, options);
        Test.stopTest();

        System.assertNotEquals(null, result, 'El resultado no debe ser null');
        System.assert(result.containsKey('list'), 'El resultado debe contener la clave "list"');

        List<Object> resultList = (List<Object>) result.get('list');
        System.assertEquals(1, resultList.size(), 'Debe haber un registro convertido');

        Map<String, Object> converted = (Map<String, Object>) resultList[0];
        System.assertEquals(15 * COP_CONVERSION_FACTOR, converted.get('amount'), 'El campo "amount" debe estar convertido correctamente');
    }

    @isTest
    static void testDMTListConvertCurrencyFieldsInListOutput() {

        Map<Id, DMT_Line__c> lines = createTestLines();
        Id recordId = getLineIdByCurrency(lines, TARGET_CURRENCY_CODE); // COP por defecto

        Map<String, Object> record = new Map<String, Object>{
            'amount' => 15000000
        };

        List<Object> recordList = new List<Object>{ record };

        Map<String, Object> input = new Map<String, Object>{
            'list' => recordList,
            'action' => 'output',
            'recordId' => recordId,
            'fieldsToConvert' => 'amount'
        };

        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Test.startTest();
        Map<String, Object> result = DMT_Currency_Conversion_Utils.DMT_List_convertCurrencyFieldsInList(input, output, options);
        Test.stopTest();

        System.assertNotEquals(null, result, 'El resultado no debe ser null');
        System.assert(result.containsKey('list'), 'El resultado debe contener la clave "list"');

        List<Object> resultList = (List<Object>) result.get('list');
        System.assertEquals(1, resultList.size(), 'Debe haber un registro convertido');

        Map<String, Object> converted = (Map<String, Object>) resultList[0];
        System.assertEquals(15000000 / COP_CONVERSION_FACTOR, converted.get('amount'), 'El campo "amount" debe estar convertido correctamente');
    }

    @isTest
    static void testDMTListConvertCurrencyFieldsInListException() {

        Map<Id, DMT_Line__c> lines = createTestLines();
        Id recordId = getLineIdByCurrency(lines, TARGET_CURRENCY_CODE); // COP por defecto

        Map<String, Object> record = new Map<String, Object>{
            'amount' => 123
        };

        List<Object> recordList = new List<Object>{ record };

        Map<String, Object> input = new Map<String, Object>{
            'list' => recordList,
            'recordId' => recordId,
            'fieldsToConvert' => 'amount'
        };

        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Test.startTest();
        Map<String, Object> result = DMT_Currency_Conversion_Utils.DMT_List_convertCurrencyFieldsInList(input, output, options);
        Test.stopTest();

        System.assertEquals('Error en la conversión', output.get('error'), 'Debe marcar error en caso de excepción');
    }

    @isTest
    static void testDMTListConvertCurrencyFieldsInListOutputWithRatio() {

        Map<Id, DMT_Line__c> lines = createTestLines();
        Id recordId = getLineIdByCurrency(lines, TARGET_CURRENCY_CODE);

        Map<String, Object> item = new Map<String, Object>{
            'amount' => 100000
        };

        List<Object> recordList = new List<Object>{ item };

        Map<String, Object> input = new Map<String, Object>{
            'list' => recordList,
            'recordId' => recordId,
            'fieldsToConvert' => 'amount'
        };

        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Test.startTest();
        Map<String, Object> result = DMT_Currency_Conversion_Utils.DMT_List_convertCurrencyFieldsInList(input, output, options);
        Test.stopTest();

        List<Object> resultList = (List<Object>) result.get('list');
        System.debug('TEST:' + resultList);
        Decimal converted = (Decimal)((Map<String, Object>)resultList[0]).get('amount');
        System.debug('TEST2:' + converted);
        System.assertEquals(100000, converted, 'Debe dividir correctamente el valor');
    }

    // format scientific notation number method
    @isTest
    static void testFormatAmountScientificNotation() {
        Map<Id, DMT_Line__c> lines = createTestLines();
        Id lineIdCOP = getLineIdByCurrency(lines, TARGET_CURRENCY_CODE);

        Map<String, Object> inputMap = new Map<String, Object>{
            'recordId' => lineIdCOP, 'action' => 'input', 'amount' => 10, 'otherField' => 'test', 'arguments' => new List<String>{'1.2345678E7'}
        };
        Map<String, Object> outMap = new Map<String, Object>();
        Test.startTest();
        Map<String, Object> result = DMT_Currency_Conversion_Utils.formatAmountScientificNotation(inputMap, outMap, null);
        Test.stopTest();
        System.debug('result '+result);
        System.assertEquals(12345678, result.get('result'), 'The result is 12345678');
        System.assertEquals(null, result.get('error'), 'The result is null');
    }

    // --- Multiple Amount Conversion: acción INPUT (multiplica) ---
@isTest
static void testMultipleAmountConversionInputSuccess() {
    // Campos a convertir: dos numéricos y uno no numérico (debe copiarse tal cual)
    Map<String, Object> inputMap = new Map<String, Object>{
        'action'   => 'input',
        'currency' => TARGET_CURRENCY_CODE,
        'list'     => 'amountA;amountB;nonNumeric',
        'amountA'  => 10,
        'amountB'  => 5,
        'nonNumeric' => 'keep'
    };
    Map<String, Object> outMap   = new Map<String, Object>();
    Map<String, Object> options  = new Map<String, Object>();

    Test.startTest();
    Map<String, Object> result = DMT_Currency_Conversion_Utils.DMT_Multiple_Amount_Conversion(inputMap, outMap, options);
    Test.stopTest();

    System.assertEquals(10 * COP_CONVERSION_FACTOR, result.get('amountA'), 'The result is 10 * COP_CONVERSION_FACTOR');
    System.assertEquals( 5 * COP_CONVERSION_FACTOR, result.get('amountB'), 'The result is 5 * COP_CONVERSION_FACTOR');
    System.assertEquals('keep', result.get('nonNumeric'), 'Los valores no numéricos deben copiarse sin convertir');
    System.assertEquals(null, result.get('error'), 'The result is null');
}

// --- Multiple Amount Conversion: acción OUTPUT (divide) ---
@isTest
static void testMultipleAmountConversionOutputSuccess() {
    Decimal a = 123;
    Decimal b = 7;

    Map<String, Object> inputMap = new Map<String, Object>{
        'action'   => 'output',
        'currency' => TARGET_CURRENCY_CODE,
        'list'     => 'amountA;amountB',
        'amountA'  => a,
        'amountB'  => b
    };
    Map<String, Object> outMap   = new Map<String, Object>();
    Map<String, Object> options  = new Map<String, Object>();

    Test.startTest();
    Map<String, Object> result = DMT_Currency_Conversion_Utils.DMT_Multiple_Amount_Conversion(inputMap, outMap, options);
    Test.stopTest();

    System.assertEquals(a / COP_CONVERSION_FACTOR, result.get('amountA'), 'The result is a / COP_CONVERSION_FACTOR');
    System.assertEquals(b / COP_CONVERSION_FACTOR, result.get('amountB'), 'The result is b / COP_CONVERSION_FACTOR');
    System.assertEquals(null, result.get('error'), 'The result is null');
}

// --- Multiple Amount Conversion: manejo de excepciones ---
@isTest
static void testMultipleAmountConversionException() {
    // No enviamos currency ni object ni recordId para forzar error
    Map<String, Object> inputMap = new Map<String, Object>{
        'action' => 'input',
        'list'   => 'amountA;amountB', // Campos que supuestamente debería convertir
        'amountA' => 100,
        'amountB' => 50
    };
    Map<String, Object> outMap   = new Map<String, Object>();
    Map<String, Object> options  = new Map<String, Object>();

    Test.startTest();
    Map<String, Object> result = DMT_Currency_Conversion_Utils.DMT_Multiple_Amount_Conversion(inputMap, outMap, options);
    Test.stopTest();

    // Validamos que haya devuelto un error
    System.assertEquals(true, result.containsKey('error'), 'Debe existir la clave error');
    System.assertNotEquals(null, result.get('error'), 'El mensaje de error no debe ser nulo');

    // Además, si devuelve una lista de excepciones, también la validamos
    if (result.containsKey('exceptionList')) {
        List<Object> exceptions = (List<Object>) result.get('exceptionList');
        System.assert(!exceptions.isEmpty(), 'La lista de excepciones no debe estar vacía');
    }
}

@isTest
static void testDMTCurrencyAmountFormatExceptionNullInput() {
    // Forzamos excepción pasando inputMap = null
    Map<String, Object> inputMap = null;
    Map<String, Object> outMap   = new Map<String, Object>();
    Map<String, Object> options  = new Map<String, Object>();

    Boolean threw = false;
    try {
        Test.startTest();
        DMT_Currency_Conversion_Utils.DMT_Currency_Amount_Format(inputMap, outMap, options);
        Test.stopTest();
    } catch (Exception e) {
        threw = true;
        System.assertNotEquals(null, e, 'Debe capturarse una excepción');
    }
    System.assert(threw, 'El método debe lanzar excepción cuando inputMap es null');
}

// --- Cubre rama DMT_Line__c y lectura de CurrencyIsoCode ---
@isTest
static void testMultipleAmountGetCurrencyFromDMTLine() {
    DMT_Line__c line = new DMT_Line__c(Name = 'Line COP', CurrencyIsoCode = TARGET_CURRENCY_CODE);
    insert line;

    Map<String, Object> inputMap = new Map<String, Object>{
        'action'   => 'input',
        'object'   => 'DMT_Line__c',
        'recordId' => line.Id,
        'list'     => 'amountA;amountB',
        'amountA'  => 10,
        'amountB'  => 5
    };
    Map<String, Object> outMap   = new Map<String, Object>();
    Map<String, Object> options  = new Map<String, Object>();

    Test.startTest();
    Map<String, Object> result = DMT_Currency_Conversion_Utils.DMT_Multiple_Amount_Conversion(inputMap, outMap, options);
    Test.stopTest();

    System.assertEquals(10 * COP_CONVERSION_FACTOR, result.get('amountA'), 'The result is 10 * COP_CONVERSION_FACTOR');
    System.assertEquals( 5 * COP_CONVERSION_FACTOR, result.get('amountB'), 'The result is 5 * COP_CONVERSION_FACTOR');
}

// --- Cubre el throw (objeto no soportado) ---
// @isTest
// static void testMultipleAmount_GetCurrency_Object_Not_Supported() {
//     Map<String, Object> inputMap = new Map<String, Object>{
//         'action'   => 'input',
//         'object'   => 'Account',  // No soportado
//         'recordId' => UserInfo.getUserId(),
//         'list'     => 'amount',
//         'amount'   => 50
//     };
//     Map<String, Object> outMap   = new Map<String, Object>();
//     Map<String, Object> options  = new Map<String, Object>();

//     Test.startTest();
//     Boolean thrown = false;
//     try {
//         DMT_Currency_Conversion_Utils.DMT_Multiple_Amount_Conversion(inputMap, outMap, options);
//     } catch (DMT_Currency_Conversion_Utils.DTM_Currency_Exception e) {
//         thrown = true;
//         System.assert(e.getMessage().contains('object not supported'));
//     }
//     Test.stopTest();

//     System.assert(thrown, 'Debe lanzar DTM_Currency_Exception');
// }

}