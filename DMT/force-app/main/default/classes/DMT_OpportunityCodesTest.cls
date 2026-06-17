@isTest
public with sharing class DMT_OpportunityCodesTest {

    @TestSetup
    static void makeData(){
        List<iaso__GBL_Rest_Services_Url__c> settingsToInsert = new List<iaso__GBL_Rest_Services_Url__c>();

        settingsToInsert.add(DMT_Test_DataFactory.setIasoCustomSetting('DMTO_Endpoint_INT','https://service.ok', 'ServicesPartition', false));
        settingsToInsert.add(DMT_Test_DataFactory.setIasoCustomSetting('DMT_GrantingTicket','https://validation.ok', 'ServicesPartition', false));

        // Perform one single DML
        //insert settingsToInsert;
        // Inserta respetando permisos del Systema actual
        Database.insert(settingsToInsert, AccessLevel.SYSTEM_MODE);
    }

    @isTest
    static void testGetOpportunityCodeByFlow() {
        // Crear un mock de la respuesta HTTP simulada
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());

        // Preparar el input del flow
        List<String> flowInput = new List<String>{'KDCO', 'LIN', 'ES'};
        List<List<String>> inputWrapper = new List<List<String>>{flowInput};

        // Llamar al método y verificar la salida
        List<String> result = DMT_OpportunityCodes.getOpportunityCodeByFlow(inputWrapper);

        // Validar que el resultado contiene el valor esperado
        System.assertNotEquals(null, result,'Not null');
        Test.stopTest();
    }

    @isTest
    static void testGetOpportunityCode() {
        // Crear un mock de la respuesta HTTP simulada
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());

        // Preparar el request de entrada
        Map<String, Object> request = new Map<String, Object>{
            'origin' => 'KDCO',
            'operationType' => 'LIN',
            'entific' => 'ES'
        };

        // Llamar al método y verificar la salida
        DMT_OpportunityCodes.Wrapper result = DMT_OpportunityCodes.getOpportunityCode(request);

        // Validar que el wrapper devuelto tiene datos y es exitoso
        System.assertNotEquals(null, result,'Not null');
        System.assert(result.success, 'El método debe devolver éxito');
        Test.stopTest();
    }
}