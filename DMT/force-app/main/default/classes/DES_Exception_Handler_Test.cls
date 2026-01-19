@isTest
private class DES_Exception_Handler_Test {

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
        'DMT_IP_TestTryCatch', 'CustomAssociationCreation', 'DMT_SAVE_CLIENT',
        'DMT_IP_GetOppClient', 'DMTLoadClientGroup', 'DMT_IP_SetOppClient',
        'DMT_IP_SetOppClient_Update', 'DealManagementRenewLine', 'DMT_conditionsCloseCase',
        'ApprovalStepLoad', 'addProductsRisk', 'DMT_IP_GetLinePassport',
        'ApprovalChangeStep', 'adminApproverMember', 'CustomAssociationTable',
        'launchDealManagement', 'DMT_IP_GetPickListLimit', 'getResponseSimulate',
        'selectClientInLIne', 'createProductsLine', 'CreateRiskLineTerm',
        'CreateDealInterveners', 'initDealManagement', 'DMTGetClientGroupInfo',
        'DMT_IP_GetRiskLineForm', 'DMT_IP_SetRiskLineForm', 'DMT_IP_GetRiskLineTerm'
    };

    @isTest
    static void testAllValidActions_LogSuccessfully() {
        DES_Exception_Handler handler = new DES_Exception_Handler();

        Test.startTest();
        for (String action : VALID_ACTIONS) {
            Map<String, Object> inputMap = new Map<String, Object>{'actionTested' => action};
            Map<String, Object> args = createArgs(inputMap);
            Map<String, Object> outputMapRef = (Map<String, Object>)args.get('output');

            Map<String, Object> resultMap = (Map<String, Object>) handler.call(action, args);

            System.assertNotEquals(null, resultMap, 'Result map should not be null for action: ' + action);
            System.assert(resultMap.containsKey('logged'), 'Result map must contain "logged" key for action: ' + action);
            System.assertEquals(true, resultMap.get('logged'), 'The "logged" key should be true for action: ' + action);
            System.assertEquals(outputMapRef, resultMap, 'Returned map should be the output map instance for action: ' + action);
            System.assertEquals(1, resultMap.size(), 'Output map should only contain the "logged" key for action: ' + action);
        }
        Test.stopTest();
    }

    @isTest
    static void testCall_InvalidAction_DoesNotLog() {
        DES_Exception_Handler handler = new DES_Exception_Handler();
        String invalidAction = 'ThisActionDoesNotExist';
        Map<String, Object> inputMap = new Map<String, Object>{ 'someKey' => 'someValue' };
        Map<String, Object> args = createArgs(inputMap);
        Map<String, Object> outputMapRef = (Map<String, Object>)args.get('output');
        Integer originalOutputSize = outputMapRef.size();

        Test.startTest();
        Map<String, Object> resultMap = (Map<String, Object>) handler.call(invalidAction, args);
        Test.stopTest();

        System.assertNotEquals(null, resultMap, 'Result should not be null.');
        System.assertEquals(false, resultMap.containsKey('logged'), 'Result map should NOT contain "logged" key for an invalid action.');
        System.assertEquals(outputMapRef, resultMap, 'Returned map should be the original output map instance.');
        System.assertEquals(originalOutputSize, resultMap.size(), 'Output map size should remain unchanged.');
    }

    @isTest
    static void testInvokeMethod_CatchesSerializationException() {
        DES_Exception_Handler handler = new DES_Exception_Handler();
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
        System.assert(resultMap.containsKey('logged'), 'Result map must contain "logged" key because the catch block should have added it.');
        System.assertEquals(true, resultMap.get('logged'), 'The "logged" key added by the catch block should be true.');
        System.assertEquals(outputMapRef, resultMap, 'Returned map should be the output map instance handled by the catch block.');
         System.assertEquals(1, resultMap.size(), 'Output map should only contain the "logged" key added by the catch block.');
    }

    @isTest
    static void testLogException_StaticMethod_HandlesInternalException() {
        String processName = 'TestStaticCall';
        Map<String, Object> inputMap = new Map<String, Object>{
            'inputKey' => 'inputValue',
            'nested' => new Map<String, Object>{'inner' => 1}
        };
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> optionsMap = new Map<String, Object>();

        Test.startTest();
        Map<String, Object> result = DES_Exception_Handler.logException(processName, inputMap, outputMap, optionsMap);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null.');
        System.assertEquals(true, result.get('logged'), 'Static method call should result in logged=true after catching internal exception.');
        System.assertEquals(outputMap, result, 'Returned map should be the output map instance passed.');
    }

     @isTest
    static void testInnerExceptionClasses() {
         DES_Exception_Handler.ProcessIntegrationException piEx = new DES_Exception_Handler.ProcessIntegrationException('Test PI');
         DES_Exception_Handler.MissingFieldsException mfEx = new DES_Exception_Handler.MissingFieldsException();

         System.assertNotEquals(null, piEx);
         System.assertNotEquals(null, mfEx);
     }
}