@isTest
private class DMT_Opp_Currency_Conversion_Handler_Test {
    
        private static Map<String, Object> createArgs(Map<String, Object> input) {
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> optionsMap = new Map<String, Object>();
        return new Map<String, Object>{
            'input' => input == null ? new Map<String, Object>() : input,
            'output' => outputMap,
            'options' => optionsMap
        };
    }

    private static final List<String> VALID_ACTIONS = new List<String>{
        'convertArrayAmount', 'testTaxo', 'getMinAndMaxDates'
    };

    @isTest
    static void testAllValidActions_LogSuccessfully() {
        
        DMT_Opp_Currency_Conversion_Handler handler = new DMT_Opp_Currency_Conversion_Handler();

        Test.startTest();
        for (String action : VALID_ACTIONS) {
            Map<String, Object> inputMap = new Map<String, Object>{'actionTested' => action};
            Map<String, Object> args = createArgs(inputMap);
            Map<String, Object> outputMapRef = (Map<String, Object>)args.get('output');

            Map<String, Object> resultMap = (Map<String, Object>) handler.call(action, args);

            System.assertNotEquals(null, resultMap, 'Result map should not be null for action: ' + action);
            System.assertEquals(outputMapRef, resultMap, 'Returned map should be the output map instance for action: ' + action);
        }
        Test.stopTest();
    }

    @isTest
    static void testCall_InvalidAction() {
        DMT_Opp_Currency_Conversion_Handler handler = new DMT_Opp_Currency_Conversion_Handler();
        String invalidAction = 'ThisActionDoesNotExist';
        Map<String, Object> inputMap = new Map<String, Object>{ 'someKey' => 'someValue' };
        Map<String, Object> args = createArgs(inputMap);
        Map<String, Object> outputMapRef = (Map<String, Object>)args.get('output');
        Integer originalOutputSize = outputMapRef.size();
        
        Test.startTest();
        Map<String, Object> resultMap = (Map<String, Object>) handler.call(invalidAction, args);
        Test.stopTest();

        System.assertNotEquals(null, resultMap, 'Result should not be null.');
        System.assertEquals(outputMapRef, resultMap, 'Returned map should be the original output map instance.');
    }

    @isTest
    static void testInvokeMethod_CatchesSerializationException() {

        DMT_Opp_Currency_Conversion_Handler handler = new DMT_Opp_Currency_Conversion_Handler();
        String validAction = 'DMT_IP_TestTryCatch';

        Savepoint sp = Database.setSavepoint();

        Map<String, Object> faultyInputMap = new Map<String, Object>{
            'nonSerializable' => sp,
             'actionToTrigger' => validAction
        };
        Map<String, Object> args = createArgs(faultyInputMap);
        Map<String, Object> outputMapRef = (Map<String, Object>)args.get('output');

        Test.startTest();
        Map<String, Object> resultMap = null;
        try {
            resultMap = (Map<String, Object>) handler.call(validAction, args);
        } catch (Exception e) {
             System.assert(false, 'Exception should have been caught and handled within invokeMethod. Got: ' + e.getMessage());
        }
        Test.stopTest();

        System.assertNotEquals(null, resultMap, 'ResultMap should not be null even if serialization failed, catch block should return it.');
        System.assertEquals(outputMapRef, resultMap, 'Returned map should be the output map instance handled by the catch block.');
    }

    @isTest
    static void testInvalidAction_ThrowsException() {
        DMT_Opp_Currency_Conversion_Handler handler = new DMT_Opp_Currency_Conversion_Handler();
        Map<String, Object> args = createArgs(new Map<String, Object>());
        Map<String, Object> output = (Map<String, Object>) args.get('output');

        handler.call('accion_no_valida', args);

        System.assertEquals(true, output.get('error'), 'Se esperaba que se marcara error=true en el mapa de salida');
    }

}